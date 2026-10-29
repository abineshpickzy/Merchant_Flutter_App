import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:bayfay_merchant_flutter/core/constants/app_constants.dart';
import 'package:bayfay_merchant_flutter/core/storage/local_storage_service.dart';

/// Immutable state capturing all app-wide permissions and GPS hardware state.
class AppPermissionState {
  final bool isFirstTime;
  final bool isChecking;
  final PermissionStatus cameraStatus;
  final PermissionStatus mediaStatus;
  final PermissionStatus locationStatus;
  final PermissionStatus notificationStatus;
  final bool isLocationServiceEnabled;
  final List<Permission> permanentlyDeniedList;

  const AppPermissionState({
    this.isFirstTime = true,
    this.isChecking = false,
    this.cameraStatus = PermissionStatus.denied,
    this.mediaStatus = PermissionStatus.denied,
    this.locationStatus = PermissionStatus.denied,
    this.notificationStatus = PermissionStatus.denied,
    this.isLocationServiceEnabled = true,
    this.permanentlyDeniedList = const [],
  });

  bool get areAllGranted =>
      cameraStatus.isGranted &&
      mediaStatus.isGranted &&
      locationStatus.isGranted &&
      notificationStatus.isGranted &&
      isLocationServiceEnabled;

  bool get hasPermanentlyDenied => permanentlyDeniedList.isNotEmpty;

  bool get isGpsOff => !isLocationServiceEnabled;

  AppPermissionState copyWith({
    bool? isFirstTime,
    bool? isChecking,
    PermissionStatus? cameraStatus,
    PermissionStatus? mediaStatus,
    PermissionStatus? locationStatus,
    PermissionStatus? notificationStatus,
    bool? isLocationServiceEnabled,
    List<Permission>? permanentlyDeniedList,
  }) {
    return AppPermissionState(
      isFirstTime: isFirstTime ?? this.isFirstTime,
      isChecking: isChecking ?? this.isChecking,
      cameraStatus: cameraStatus ?? this.cameraStatus,
      mediaStatus: mediaStatus ?? this.mediaStatus,
      locationStatus: locationStatus ?? this.locationStatus,
      notificationStatus: notificationStatus ?? this.notificationStatus,
      isLocationServiceEnabled:
          isLocationServiceEnabled ?? this.isLocationServiceEnabled,
      permanentlyDeniedList:
          permanentlyDeniedList ?? this.permanentlyDeniedList,
    );
  }
}

final permissionNotifierProvider =
    StateNotifierProvider<PermissionNotifier, AppPermissionState>((ref) {
  final localStorage = ref.watch(localStorageServiceProvider);
  return PermissionNotifier(localStorage);
});

class PermissionNotifier extends StateNotifier<AppPermissionState> {
  final LocalStorageService _localStorage;

  PermissionNotifier(this._localStorage) : super(const AppPermissionState()) {
    initCheck();
  }

  /// Initial check distinguishing first-time app launch from subsequent launches.
  Future<void> initCheck() async {
    state = state.copyWith(isChecking: true);
    final completed =
        _localStorage.getBool(AppConstants.permissionOnboardingCompletedKey) ==
            true;

    if (!completed) {
      // First-time app launch: silently inspect current status without prompting OS dialogs
      final camera = await _safeCheck(Permission.camera);
      final media = await _checkMediaStatus();
      final location = await _safeCheck(Permission.location);
      final notification = await _safeCheck(Permission.notification);
      final isGpsOn = await _safeCheckLocationService();
      if (!mounted) return;

      state = AppPermissionState(
        isFirstTime: true,
        isChecking: false,
        cameraStatus: camera,
        mediaStatus: media,
        locationStatus: location,
        notificationStatus: notification,
        isLocationServiceEnabled: isGpsOn,
        permanentlyDeniedList: const [],
      );
    } else {
      // Subsequent launches: silent check for all permissions and GPS status
      await recheckPermissions();
    }
  }

  /// First launch direct sequential native OS permission request flow:
  /// 1. Camera -> 2. Photos/Media -> 3. Location
  /// Directly calls the system OS prompts without any intermediate UI dialogs,
  /// strictly checking status first to avoid redundant prompts if already granted.
  /// As soon as the user grants Location permission, triggers the native OS / Google Location Accuracy
  /// dialog to automatically switch the device's Location Service (GPS) ON.
  Future<void> requestFirstLaunchPermissions() async {
    state = state.copyWith(isChecking: true);

    // 1. Camera - check status first
    final camera = await _requestIfNotGranted(Permission.camera);

    // 2. Photos / Media - check status first
    final media = await _requestMediaIfNotGranted();

    // 3. Location - check status first
    final location = await _requestIfNotGranted(Permission.location);

    // Check if location permission is granted (Precise or Approximate)
    bool isLocationGranted = location.isGranted;
    if (!isLocationGranted) {
      try {
        final geoPerm = await Geolocator.checkPermission();
        isLocationGranted = geoPerm == LocationPermission.whileInUse ||
            geoPerm == LocationPermission.always;
      } catch (_) {}
    }

    bool isGpsOn = await _safeCheckLocationService();

    // Zomato-style flow: Upon clicking "Allow" on Location Permission,
    // if GPS is OFF, immediately trigger Google Play Services Location Accuracy dialog
    // ("For a better experience, your device will need to use Location Accuracy")
    // allowing the user to tap "Turn on" and enable GPS in-place.
    if (isLocationGranted && !isGpsOn) {
      try {
        await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 10),
          ),
        );
        isGpsOn = await _safeCheckLocationService();
      } on LocationServiceDisabledException {
        debugPrint('ℹ️ [FirstLaunch] User tapped No thanks on Location Accuracy prompt');
        isGpsOn = await _safeCheckLocationService();
      } catch (e) {
        debugPrint('ℹ️ [FirstLaunch] Location service prompt error: $e');
        isGpsOn = await _safeCheckLocationService();
      }
    }

    // 4. Request Push Notification permission on startup (Android 13+ / iOS)
    // Handled gracefully without blocking app progression if denied
    final notification = await _requestIfNotGranted(Permission.notification);

    // Mark onboarding completed in local storage so first launch flow runs only once
    await _localStorage.setBool(
      AppConstants.permissionOnboardingCompletedKey,
      true,
    );

    final permanentlyDenied = <Permission>[];
    if (camera.isPermanentlyDenied) permanentlyDenied.add(Permission.camera);
    if (media.isPermanentlyDenied) permanentlyDenied.add(Permission.photos);
    if (location.isPermanentlyDenied) permanentlyDenied.add(Permission.location);
    if (notification.isPermanentlyDenied) {
      permanentlyDenied.add(Permission.notification);
    }

    if (!mounted) return;

    state = AppPermissionState(
      isFirstTime: false,
      isChecking: false,
      cameraStatus: camera,
      mediaStatus: media,
      locationStatus: location,
      notificationStatus: notification,
      isLocationServiceEnabled: isGpsOn,
      permanentlyDeniedList: permanentlyDenied,
    );
  }

  /// Helper to request a permission only if not already granted.
  Future<PermissionStatus> _requestIfNotGranted(Permission permission) async {
    final status = await _safeCheck(permission);
    if (status.isGranted) return status;
    try {
      return await permission.request();
    } catch (_) {
      return PermissionStatus.denied;
    }
  }

  /// Helper to request media/photo permission only if not already granted.
  Future<PermissionStatus> _requestMediaIfNotGranted() async {
    final status = await _checkMediaStatus();
    if (status.isGranted) return status;
    return _requestMediaPermission();
  }

  /// Alias for [requestFirstLaunchPermissions].
  Future<void> requestFirstTimePermissions() => requestFirstLaunchPermissions();

  /// Requests push notification permission on-demand and updates state.
  Future<PermissionStatus> requestNotificationPermission() async {
    final status = await _requestIfNotGranted(Permission.notification);
    if (!mounted) return status;
    state = state.copyWith(notificationStatus: status);
    return status;
  }

  /// Silently checks if device Location Services (GPS) are turned ON via Geolocator.
  /// Updates [isLocationServiceEnabled] in state and returns the current status.
  Future<bool> checkLocationService() async {
    final isGpsOn = await _safeCheckLocationService();
    if (!mounted) return isGpsOn;
    if (state.isLocationServiceEnabled != isGpsOn) {
      state = state.copyWith(isLocationServiceEnabled: isGpsOn);
    }
    return isGpsOn;
  }

  /// Synchronously updates [isLocationServiceEnabled] in state.
  void updateLocationServiceStatus(bool isEnabled) {
    if (!mounted) return;
    if (state.isLocationServiceEnabled != isEnabled) {
      state = state.copyWith(isLocationServiceEnabled: isEnabled);
    }
  }

  /// Re-evaluates all permission statuses silently without triggering prompts.
  /// Used for subsequent app launches or when resuming from device settings.
  Future<void> recheckPermissions() async {
    final camera = await _safeCheck(Permission.camera);
    final media = await _checkMediaStatus();
    final location = await _safeCheck(Permission.location);
    final notification = await _safeCheck(Permission.notification);
    final isGpsOn = await _safeCheckLocationService();

    final permanentlyDenied = <Permission>[];
    if (camera.isPermanentlyDenied) permanentlyDenied.add(Permission.camera);
    if (media.isPermanentlyDenied) permanentlyDenied.add(Permission.photos);
    if (location.isPermanentlyDenied) permanentlyDenied.add(Permission.location);
    if (notification.isPermanentlyDenied) {
      permanentlyDenied.add(Permission.notification);
    }

    if (!mounted) return;

    state = state.copyWith(
      isFirstTime: false,
      isChecking: false,
      cameraStatus: camera,
      mediaStatus: media,
      locationStatus: location,
      notificationStatus: notification,
      isLocationServiceEnabled: isGpsOn,
      permanentlyDeniedList: permanentlyDenied,
    );
  }

  /// Opens the device settings page for permanently denied permissions.
  Future<bool> openAppSettingsPage() async {
    return openAppSettings();
  }

  /// Opens device location / GPS settings (Zomato-style).
  Future<bool> openLocationSettingsPage() async {
    return Geolocator.openLocationSettings();
  }

  Future<PermissionStatus> _safeCheck(Permission permission) async {
    try {
      return await permission.status;
    } catch (_) {
      return PermissionStatus.denied;
    }
  }

  Future<bool> _safeCheckLocationService() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (_) {
      return true;
    }
  }

  Future<PermissionStatus> _checkMediaStatus() async {
    try {
      if (!kIsWeb && Platform.isAndroid) {
        final photos = await Permission.photos.status;
        if (photos.isGranted) return photos;
        final storage = await Permission.storage.status;
        if (storage.isGranted) return storage;
        if (photos.isPermanentlyDenied || storage.isPermanentlyDenied) {
          return PermissionStatus.permanentlyDenied;
        }
        return photos;
      }
      return await Permission.photos.status;
    } catch (_) {
      return PermissionStatus.denied;
    }
  }

  Future<PermissionStatus> _requestMediaPermission() async {
    try {
      if (!kIsWeb && Platform.isAndroid) {
        final photos = await Permission.photos.request();
        if (photos.isGranted) return photos;
        return await Permission.storage.request();
      }
      return await Permission.photos.request();
    } catch (_) {
      return PermissionStatus.denied;
    }
  }
}
