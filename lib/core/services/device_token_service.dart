import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_constants.dart';
import '../storage/local_storage_service.dart';
import '../storage/secure_storage_service.dart';

final deviceTokenServiceProvider = Provider<DeviceTokenService>((ref) {
  final localStorage = ref.watch(localStorageServiceProvider);
  final secureStorage = ref.watch(secureStorageServiceProvider);
  return DeviceTokenService(localStorage, secureStorage);
});

/// Riverpod provider exposing the device/FCM token asynchronously
final deviceTokenProvider = FutureProvider<String>((ref) async {
  final service = ref.watch(deviceTokenServiceProvider);
  return service.initAndFetchToken();
});

class DeviceTokenService {
  final LocalStorageService _localStorage;
  final SecureStorageService _secureStorage;
  String? _cachedToken;

  DeviceTokenService(this._localStorage, this._secureStorage) {
    _cachedToken = _localStorage.getString(AppConstants.deviceTokenKey);
  }

  /// Returns cached token if available, or null
  String? get currentToken =>
      _cachedToken ?? _localStorage.getString(AppConstants.deviceTokenKey);

  /// Device Type integer matching backend requirements:
  /// 1 = iOS, 2 = Android (default), 3 = Web/Other
  int get deviceType {
    try {
      if (kIsWeb) return 3;
      if (Platform.isIOS) return 1;
      if (Platform.isAndroid) return 2;
    } catch (_) {}
    return 2;
  }

  /// Initializes Firebase (if available), retrieves the FCM token,
  /// or falls back to device hardware ID (matching Android's ANDROID_ID),
  /// and caches it in local storage.
  Future<String> initAndFetchToken() async {
    // If we already have a cached token in memory, return it
    if (_cachedToken != null && _cachedToken!.isNotEmpty) {
      debugPrint('[DeviceToken] Using existing cached token: $_cachedToken');
    }

    String? token;

    // 1. Attempt to get FCM token via FirebaseMessaging
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      final messaging = FirebaseMessaging.instance;

      // Request notification permissions where appropriate (iOS / Web)
      if (!kIsWeb && Platform.isIOS) {
        await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      token = await messaging.getToken();

      if (token != null && token.trim().isNotEmpty) {
        debugPrint('[FCM] Token retrieved successfully: $token');
        await _saveToken(token.trim());
        _setupTokenRefreshListener();
        return token.trim();
      }
    } catch (e) {
      debugPrint('[FCM] Notice: Firebase Messaging initialization/token fetch skipped: $e');
    }

    // 2. Check if a valid token is already saved in SharedPreferences
    final savedToken = _localStorage.getString(AppConstants.deviceTokenKey);
    if (savedToken != null && savedToken.trim().isNotEmpty) {
      _cachedToken = savedToken.trim();
      debugPrint('[DeviceToken] Using saved device token from local storage: $_cachedToken');
      return _cachedToken!;
    }

    // 3. Fallback: retrieve device hardware ID (matches Android's Settings.Secure.ANDROID_ID)
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (!kIsWeb && Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        final androidId = androidInfo.id;
        if (androidId.isNotEmpty) {
          debugPrint('[DeviceToken] Using Android ID as fallback token: $androidId');
          await _saveToken(androidId);
          return androidId;
        }
      } else if (!kIsWeb && Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        final identifier = iosInfo.identifierForVendor;
        if (identifier != null && identifier.isNotEmpty) {
          debugPrint('[DeviceToken] Using iOS identifierForVendor as fallback token: $identifier');
          await _saveToken(identifier);
          return identifier;
        }
      }
    } catch (e) {
      debugPrint('[DeviceToken] Notice: DeviceInfo fallback failed: $e');
    }

    // 4. Ultimate fallback: generate a persistent pseudo-unique device ID
    final fallbackId = 'device_${DateTime.now().millisecondsSinceEpoch}';
    debugPrint('[DeviceToken] Generated fallback device identifier: $fallbackId');
    await _saveToken(fallbackId);
    return fallbackId;
  }

  void _setupTokenRefreshListener() {
    try {
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        if (newToken.trim().isNotEmpty) {
          debugPrint('[FCM] Token refreshed: $newToken');
          _saveToken(newToken.trim());
        }
      });
    } catch (_) {}
  }

  Future<void> _saveToken(String token) async {
    _cachedToken = token;
    await Future.wait([
      _localStorage.setString(AppConstants.deviceTokenKey, token),
      _secureStorage.saveDeviceToken(token),
    ]);
  }
}
