import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:bayfay_merchant_flutter/app/providers/auth_state_provider.dart';
import 'package:bayfay_merchant_flutter/core/constants/app_strings.dart';
import 'package:bayfay_merchant_flutter/core/storage/secure_storage_service.dart';
import '../model/register_request.dart';
import '../repository/register_repository.dart';

final registerControllerProvider =
    AutoDisposeAsyncNotifierProvider<RegisterController, void>(() {
  return RegisterController();
});

class RegisterController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    // Idle initial state
  }

  /// Step 1: Initiate Sign Up & send verification OTP (StoreSignUpActivity)
  Future<bool> initiateSignUp({
    required String firstName,
    required String lastName,
    required String email,
    required String mobileNumber,
    int dialingCode = 91,
  }) async {
    final cleanMobile = mobileNumber.replaceAll(RegExp(r'\D'), '');

    if (firstName.trim().isEmpty) {
      state = AsyncError(AppStrings.firstNameRequired, StackTrace.current);
      return false;
    }
    if (lastName.trim().isEmpty) {
      state = AsyncError(AppStrings.lastNameRequired, StackTrace.current);
      return false;
    }
    if (cleanMobile.length != 10) {
      state = AsyncError(AppStrings.enterValidMobile, StackTrace.current);
      return false;
    }
    if (email.trim().isEmpty || !email.contains('@')) {
      state = AsyncError(AppStrings.enterValidEmail, StackTrace.current);
      return false;
    }

    state = const AsyncLoading();

    try {
      // Check if device Location Services (GPS) are turned ON
      bool isGpsOn = false;
      try {
        isGpsOn = await Geolocator.isLocationServiceEnabled();
      } catch (e) {
        debugPrint('⚠️ [Register] Unable to check location service status: $e');
      }

      if (!isGpsOn) {
        try {
          await Geolocator.openLocationSettings();
        } catch (_) {}
        state = AsyncError(
          AppStrings.locationRequiredForRegister,
          StackTrace.current,
        );
        return false;
      }

      final repository = ref.read(registerRepositoryProvider);
      final request = SignUpVerifyRequest(
        email: email.trim(),
        dialingCode: dialingCode,
        mobileNumber: int.parse(cleanMobile),
      );

      await repository.verifySignUp(request);
      state = const AsyncData(null);
      return true;
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
      return false;
    }
  }

  /// Step 2: Complete Sign Up with OTP & Password (StoreVerificationActivity)
  Future<bool> completeVerification({
    required String firstName,
    required String lastName,
    required String email,
    required String mobileNumber,
    required String otp,
    required String password,
    int dialingCode = 91,
  }) async {
    final cleanMobile = mobileNumber.replaceAll(RegExp(r'\D'), '');
    final cleanOtp = otp.replaceAll(RegExp(r'\D'), '');

    if (cleanOtp.length < 4) {
      state = AsyncError(AppStrings.otpRequired, StackTrace.current);
      return false;
    }
    if (password.length < 6) {
      state = AsyncError(AppStrings.passwordMinLength, StackTrace.current);
      return false;
    }

    state = const AsyncLoading();

    try {
      // 1. Check if device Location Services (GPS) are turned ON
      bool isGpsOn = false;
      try {
        isGpsOn = await Geolocator.isLocationServiceEnabled();
      } catch (e) {
        debugPrint('⚠️ [RegisterVerify] Unable to check location service status: $e');
      }

      if (!isGpsOn) {
        try {
          await Geolocator.openLocationSettings();
        } catch (_) {}
        state = AsyncError(
          AppStrings.locationRequiredForRegister,
          StackTrace.current,
        );
        return false;
      }

      // 2. Check location permissions
      try {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            state = AsyncError(
              AppStrings.locationPermissionRequiredForRegister,
              StackTrace.current,
            );
            return false;
          }
        }

        if (permission == LocationPermission.deniedForever) {
          await Geolocator.openAppSettings();
          state = AsyncError(
            AppStrings.locationPermissionRequiredForRegister,
            StackTrace.current,
          );
          return false;
        }
      } catch (e) {
        debugPrint('⚠️ [RegisterVerify] Location permission check error: $e');
      }

      // 3. Fetch active coordinates
      double latitude = 0.0;
      double longitude = 0.0;
      try {
        LocationSettings locationSettings;
        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
          locationSettings = AndroidSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 5),
            forceLocationManager: true,
          );
        } else {
          locationSettings = const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 5),
          );
        }
        final position = await Geolocator.getCurrentPosition(
          locationSettings: locationSettings,
        );
        latitude = position.latitude;
        longitude = position.longitude;
      } catch (_) {
        try {
          final lastKnown = await Geolocator.getLastKnownPosition();
          if (lastKnown != null) {
            latitude = lastKnown.latitude;
            longitude = lastKnown.longitude;
          }
        } catch (_) {}
      }

      final repository = ref.read(registerRepositoryProvider);
      final secureStorage = ref.read(secureStorageServiceProvider);
      final fcmToken = await secureStorage.getDeviceToken();
      debugPrint('ℹ️ [RegisterVerify] Retrieved FCM Token: $fcmToken');
      debugPrint('ℹ️ [RegisterVerify] Sending Coordinates: [$longitude, $latitude]');

      final request = SignUpCompleteRequest(
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        email: email.trim(),
        dialingCode: dialingCode,
        mobileNumber: int.parse(cleanMobile),
        otp: int.parse(cleanOtp),
        password: password,
        latitude: latitude,
        longitude: longitude,
        deviceToken: fcmToken,
      );

      final response = await repository.completeSignUp(request);

      if (!response.success) {
        state = AsyncError(response.message, StackTrace.current);
        return false;
      }

      // Automatically store session and transition to AuthAuthenticated
      if (response.tokens?.accessToken != null &&
          response.tokens!.accessToken.isNotEmpty) {
        await ref.read(authStateProvider.notifier).setAuthenticated(
              token: response.tokens!.accessToken,
              refreshToken: response.tokens?.refreshToken,
              profile: response.profile,
            );
      }

      state = const AsyncData(null);
      return true;
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
      return false;
    }
  }

  /// Resend OTP for signup
  Future<bool> resendSignUpOtp({
    required String email,
    required String mobileNumber,
    int dialingCode = 91,
  }) async {
    final cleanMobile = mobileNumber.replaceAll(RegExp(r'\D'), '');
    try {
      final repository = ref.read(registerRepositoryProvider);
      final request = SignUpVerifyRequest(
        email: email.trim(),
        dialingCode: dialingCode,
        mobileNumber: int.parse(cleanMobile),
      );
      await repository.verifySignUp(request);
      return true;
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
      return false;
    }
  }

  /// One-shot registration support
  Future<bool> register({
    required String firstName,
    required String lastName,
    required String email,
    int dialingCode = 91,
    required String mobileNumber,
    required String password,
    required String storeName,
  }) async {
    final cleanMobile = mobileNumber.replaceAll(RegExp(r'\D'), '');

    if (firstName.trim().isEmpty) {
      state = AsyncError(AppStrings.firstNameRequired, StackTrace.current);
      return false;
    }
    if (cleanMobile.length != 10) {
      state = AsyncError(AppStrings.enterValidMobile, StackTrace.current);
      return false;
    }
    if (email.trim().isEmpty || !email.contains('@')) {
      state = AsyncError(AppStrings.enterValidEmail, StackTrace.current);
      return false;
    }
    if (password.length < 6) {
      state = AsyncError(AppStrings.passwordMinLength, StackTrace.current);
      return false;
    }

    state = const AsyncLoading();

    try {
      // 1. Check if device Location Services (GPS) are turned ON
      bool isGpsOn = false;
      try {
        isGpsOn = await Geolocator.isLocationServiceEnabled();
      } catch (e) {
        debugPrint('⚠️ [RegisterOneShot] Unable to check location service status: $e');
      }

      if (!isGpsOn) {
        try {
          await Geolocator.openLocationSettings();
        } catch (_) {}
        state = AsyncError(
          AppStrings.locationRequiredForRegister,
          StackTrace.current,
        );
        return false;
      }

      // 2. Check location permissions
      try {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            state = AsyncError(
              AppStrings.locationPermissionRequiredForRegister,
              StackTrace.current,
            );
            return false;
          }
        }

        if (permission == LocationPermission.deniedForever) {
          await Geolocator.openAppSettings();
          state = AsyncError(
            AppStrings.locationPermissionRequiredForRegister,
            StackTrace.current,
          );
          return false;
        }
      } catch (e) {
        debugPrint('⚠️ [RegisterOneShot] Location permission check error: $e');
      }

      // 3. Fetch active coordinates
      double latitude = 0.0;
      double longitude = 0.0;
      try {
        LocationSettings locationSettings;
        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
          locationSettings = AndroidSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 5),
            forceLocationManager: true,
          );
        } else {
          locationSettings = const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 5),
          );
        }
        final position = await Geolocator.getCurrentPosition(
          locationSettings: locationSettings,
        );
        latitude = position.latitude;
        longitude = position.longitude;
      } catch (_) {
        try {
          final lastKnown = await Geolocator.getLastKnownPosition();
          if (lastKnown != null) {
            latitude = lastKnown.latitude;
            longitude = lastKnown.longitude;
          }
        } catch (_) {}
      }

      final repository = ref.read(registerRepositoryProvider);
      final secureStorage = ref.read(secureStorageServiceProvider);
      final fcmToken = await secureStorage.getDeviceToken();

      final request = RegisterRequest(
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        email: email.trim(),
        dialingCode: dialingCode,
        mobileNumber: int.parse(cleanMobile),
        password: password,
        storeName: storeName.trim(),
        latitude: latitude,
        longitude: longitude,
        deviceToken: fcmToken,
      );

      final response = await repository.register(request);

      if (!response.success) {
        state = AsyncError(response.message, StackTrace.current);
        return false;
      }

      state = const AsyncData(null);
      return true;
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
      return false;
    }
  }
}
