import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:bayfay_merchant_flutter/app/providers/auth_state_provider.dart';
import 'package:bayfay_merchant_flutter/core/constants/app_strings.dart';
import 'package:bayfay_merchant_flutter/core/storage/secure_storage_service.dart';
import '../repository/login_repository.dart';

final loginControllerProvider =
    AutoDisposeAsyncNotifierProvider<LoginController, void>(() {
  return LoginController();
});

class LoginController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    // Initial idle state
  }

  /// Authenticates merchant via Email or Mobile Number dynamically
  Future<bool> login({
    required String emailOrMobile,
    required String password,
  }) async {
    final cleanInput = emailOrMobile.trim();

    // Validation
    if (cleanInput.isEmpty) {
      state = AsyncError(
        AppStrings.enterEmailOrMobile,
        StackTrace.current,
      );
      return false;
    }

    if (cleanInput.contains('@')) {
      // Validate email pattern
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(cleanInput)) {
        state = AsyncError(
          AppStrings.enterValidEmail,
          StackTrace.current,
        );
        return false;
      }
    } else {
      // Validate phone number
      final cleanMobile = cleanInput.replaceAll(RegExp(r'\D'), '');
      if (cleanMobile.length != 10) {
        state = AsyncError(
          AppStrings.enterValidMobile,
          StackTrace.current,
        );
        return false;
      }
    }

    if (password.trim().isEmpty) {
      state = AsyncError(AppStrings.enterPassword, StackTrace.current);
      return false;
    }

    state = const AsyncLoading();

    try {
      // 1. Check if device Location Services (GPS) are turned ON
      bool isGpsOn = false;
      try {
        isGpsOn = await Geolocator.isLocationServiceEnabled();
      } catch (e) {
        debugPrint('⚠️ [Login] Unable to check location service status: $e');
      }

      if (!isGpsOn) {
        try {
          await Geolocator.openLocationSettings();
        } catch (_) {}
        state = const AsyncData(null);
        return false;
      }

      // 2. Check location permissions
      try {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            state = AsyncError(
              AppStrings.locationPermissionRequired,
              StackTrace.current,
            );
            return false;
          }
        }

        if (permission == LocationPermission.deniedForever) {
          await Geolocator.openAppSettings();
          state = AsyncError(
            AppStrings.locationPermissionRequired,
            StackTrace.current,
          );
          return false;
        }
      } catch (e) {
        debugPrint('⚠️ [Login] Location permission check error: $e');
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

      final repository = ref.read(loginRepositoryProvider);
      final secureStorage = ref.read(secureStorageServiceProvider);
      final fcmToken = await secureStorage.getDeviceToken();
      debugPrint('ℹ️ [Login] Retrieved FCM Token from SecureStorage: $fcmToken');
      debugPrint('ℹ️ [Login] Sending Coordinates: [$longitude, $latitude]');

      final response = await repository.login(
        emailOrMobile: cleanInput,
        password: password,
        latitude: latitude,
        longitude: longitude,
        deviceToken: fcmToken,
      );

      if (!response.success) {
        state = AsyncError(response.message, StackTrace.current);
        return false;
      }

      // Update application-level centralized auth state
      await ref.read(authStateProvider.notifier).setAuthenticated(
            token: response.tokens.accessToken,
            refreshToken: response.tokens.refreshToken,
            profile: response.profile,
          );

      state = const AsyncData(null);
      return true;
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
      return false;
    }
  }
}
