import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  const storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
  return SecureStorageService(storage);
});

class SecureStorageService {
  final FlutterSecureStorage _storage;

  const SecureStorageService(this._storage);

  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }

  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }

  // Token Helpers
  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
    String? accessSchema,
    String? refreshSchema,
  }) async {
    await write(AppConstants.accessTokenKey, accessToken);
    if (accessSchema != null) {
      await write(AppConstants.accessSchemaKey, accessSchema);
    }
    if (refreshToken != null) {
      await write(AppConstants.refreshTokenKey, refreshToken);
    }
    if (refreshSchema != null) {
      await write(AppConstants.refreshSchemaKey, refreshSchema);
    }
  }

  Future<String?> getAccessToken() async {
    return await read(AppConstants.accessTokenKey);
  }

  Future<String> getAccessSchema() async {
    return await read(AppConstants.accessSchemaKey) ?? 'Bearer';
  }

  Future<String?> getRefreshToken() async {
    return await read(AppConstants.refreshTokenKey);
  }

  Future<String> getRefreshSchema() async {
    return await read(AppConstants.refreshSchemaKey) ?? 'Bearer';
  }

  Future<void> saveDeviceToken(String token) async {
    await write(AppConstants.deviceTokenKey, token);
  }

  Future<String?> getDeviceToken() async {
    return await read(AppConstants.deviceTokenKey);
  }

  Future<void> clearTokens() async {
    await delete(AppConstants.accessTokenKey);
    await delete(AppConstants.accessSchemaKey);
    await delete(AppConstants.refreshTokenKey);
    await delete(AppConstants.refreshSchemaKey);
    await delete(AppConstants.userProfileKey);
    await delete(AppConstants.activeShopIdKey);
  }
}
