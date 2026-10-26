import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

/// State of device Location Services (GPS) and current position.
@immutable
class LocationServiceState {
  final bool isGpsEnabled;
  final bool isChecking;
  final Position? currentPosition;
  final String? errorMessage;

  const LocationServiceState({
    this.isGpsEnabled = true,
    this.isChecking = false,
    this.currentPosition,
    this.errorMessage,
  });

  LocationServiceState copyWith({
    bool? isGpsEnabled,
    bool? isChecking,
    Position? currentPosition,
    String? errorMessage,
  }) {
    return LocationServiceState(
      isGpsEnabled: isGpsEnabled ?? this.isGpsEnabled,
      isChecking: isChecking ?? this.isChecking,
      currentPosition: currentPosition ?? this.currentPosition,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

final locationServiceProvider =
    StateNotifierProvider<LocationServiceNotifier, LocationServiceState>((ref) {
  return LocationServiceNotifier();
});

class LocationServiceNotifier extends StateNotifier<LocationServiceState> {
  bool _isPrompting = false;
  bool _userDeclinedThisSession = false;

  LocationServiceNotifier() : super(const LocationServiceState()) {
    checkServiceStatus();
  }

  /// Silently checks if device Location Services (GPS) are turned ON.
  Future<bool> checkServiceStatus() async {
    try {
      final isEnabled = await Geolocator.isLocationServiceEnabled();
      if (isEnabled) {
        // Reset declined state once GPS is enabled
        _userDeclinedThisSession = false;
      }
      state = state.copyWith(isGpsEnabled: isEnabled);
      return isEnabled;
    } catch (_) {
      return state.isGpsEnabled;
    }
  }

  /// Checks if Location is OFF and immediately triggers the native Google Location Accuracy
  /// system dialog ("Turn on / No, thanks" popup) via Geolocator.getCurrentPosition.
  ///
  /// On subsequent launches and resumes, does NOT re-request OS permissions.
  /// Gracefully catches LocationServiceDisabledException without infinite prompt loops.
  Future<bool> checkAndPromptLocationService({bool force = false}) async {
    if (_isPrompting) return state.isGpsEnabled;

    try {
      final isEnabled = await Geolocator.isLocationServiceEnabled();
      if (isEnabled) {
        _userDeclinedThisSession = false;
        state = state.copyWith(isGpsEnabled: true, isChecking: false);
        return true;
      }

      // If the user already tapped "No, thanks" in this session, do not loop on resume
      if (_userDeclinedThisSession && !force) {
        state = state.copyWith(isGpsEnabled: false, isChecking: false);
        return false;
      }

      // Check location permission status without re-prompting OS dialogs on subsequent launches
      final hasPermission = await Permission.location.isGranted ||
          await Permission.locationWhenInUse.isGranted;
      if (!hasPermission) {
        state = state.copyWith(isGpsEnabled: false, isChecking: false);
        return false;
      }

      _isPrompting = true;
      state = state.copyWith(isChecking: true, errorMessage: null);

      // Calling getCurrentPosition with high accuracy triggers Google Play Services
      // ResolvableApiException in-place system dialog ("To continue, turn on device location...").
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final nowEnabled = await Geolocator.isLocationServiceEnabled();
      if (nowEnabled) {
        _userDeclinedThisSession = false;
      }
      state = state.copyWith(
        isGpsEnabled: nowEnabled,
        isChecking: false,
        currentPosition: position,
      );
      return nowEnabled;
    } on LocationServiceDisabledException {
      // User dismissed the native dialog or tapped "No, thanks"
      _userDeclinedThisSession = true;
      state = state.copyWith(isGpsEnabled: false, isChecking: false);
      return false;
    } catch (e) {
      final nowEnabled =
          await Geolocator.isLocationServiceEnabled().catchError((_) => false);
      if (nowEnabled) {
        _userDeclinedThisSession = false;
      }
      state = state.copyWith(
        isGpsEnabled: nowEnabled,
        isChecking: false,
        errorMessage: e.toString(),
      );
      return nowEnabled;
    } finally {
      _isPrompting = false;
    }
  }

  /// Resets user decline flag so the dialog can be prompted again on explicit demand.
  void resetDeclineState() {
    _userDeclinedThisSession = false;
  }

  /// Opens device location settings screen (GPS source settings)
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Fetches the active device coordinates.
  /// If GPS is enabled and permission is granted, returns the Position.
  /// Falls back gracefully to last known position on timeout.
  Future<Position?> getCurrentLocation() async {
    try {
      final isEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isEnabled) {
        state = state.copyWith(isGpsEnabled: false);
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );

      state = state.copyWith(
        isGpsEnabled: true,
        currentPosition: position,
      );
      return position;
    } catch (_) {
      try {
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          state = state.copyWith(currentPosition: lastKnown);
        }
        return lastKnown;
      } catch (_) {
        return null;
      }
    }
  }
}

