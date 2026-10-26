import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayfay_merchant_flutter/core/errors/exceptions.dart';
import 'package:bayfay_merchant_flutter/core/network/api_client.dart';
import 'package:bayfay_merchant_flutter/core/network/api_endpoints.dart';
import 'package:bayfay_merchant_flutter/core/storage/secure_storage_service.dart';
import '../model/login_request.dart';
import '../model/login_response.dart';

final loginRepositoryProvider = Provider<LoginRepository>((ref) {
  final apiClient = ref.read(apiClientProvider);
  final storage = ref.read(secureStorageServiceProvider);
  return LoginRepository(apiClient, storage);
});

class LoginRepository {
  final ApiClient _apiClient;
  final SecureStorageService _storage;

  const LoginRepository(this._apiClient, this._storage);

  /// Authenticate merchant dynamically via Email or Mobile Number
  /// Calls POST auth/email or POST auth/mobile based on input
  Future<LoginResponse> login({
    required String emailOrMobile,
    required String password,
    double latitude = 0.0,
    double longitude = 0.0,
    String? deviceToken,
    int? deviceType,
  }) async {
    final effectiveToken = (deviceToken != null && deviceToken.isNotEmpty)
        ? deviceToken
        : await _storage.getDeviceToken();

    final request = LoginRequest.fromInput(
      emailOrMobile: emailOrMobile,
      password: password,
      latitude: latitude,
      longitude: longitude,
      deviceToken: effectiveToken,
      deviceType: deviceType,
    );

    // Dynamically choose endpoint: auth/email or auth/mobile
    final endpoint = ApiEndpoints.authDynamic(request.type);

    final response = await _apiClient.post(
      endpoint,
      data: request.toJson(),
      requiresAuth: false,
    );

    if (response.data is Map<String, dynamic>) {
      final loginResponse = LoginResponse.fromJson(
        response.data as Map<String, dynamic>,
      );

      // Save tokens in secure storage
      if (loginResponse.tokens.accessToken.isNotEmpty) {
        await _storage.saveTokens(
          accessToken: loginResponse.tokens.accessToken,
          refreshToken: loginResponse.tokens.refreshToken,
          accessSchema: loginResponse.tokens.accessSchema,
          refreshSchema: loginResponse.tokens.refreshSchema,
        );
      }

      return loginResponse;
    } else {
      throw ServerException('Invalid response format received from $endpoint');
    }
  }

  /// Replicates Android's ApiClient.getInterfaceRefresh().callRefreshToken()
  /// Calls POST auth/refresh with Header Authorization: `<refreshSchema>` `<refreshToken>`
  Future<LoginResponse> refreshToken() async {
    final refreshToken = await _storage.getRefreshToken();
    final refreshSchema = await _storage.getRefreshSchema();

    if (refreshToken == null || refreshToken.isEmpty) {
      throw const UnauthorizedException('No refresh token available');
    }

    final response = await _apiClient.post(
      ApiEndpoints.refreshToken,
      requiresAuth: false,
      options: Options(
        headers: {
          'Authorization': '$refreshSchema $refreshToken',
        },
      ),
    );

    if (response.data is Map<String, dynamic>) {
      final loginResponse = LoginResponse.fromJson(
        response.data as Map<String, dynamic>,
      );

      if (loginResponse.tokens.accessToken.isNotEmpty) {
        await _storage.saveTokens(
          accessToken: loginResponse.tokens.accessToken,
          refreshToken: loginResponse.tokens.refreshToken,
          accessSchema: loginResponse.tokens.accessSchema,
          refreshSchema: loginResponse.tokens.refreshSchema,
        );
      }

      return loginResponse;
    } else {
      throw const ServerException('Invalid response received from auth/refresh');
    }
  }

  Future<void> logout() async {
    try {
      await _apiClient.post(
        ApiEndpoints.logout,
        requiresAuth: true,
      );
    } catch (_) {
      // Allow local logout to proceed
    } finally {
      await _storage.clearTokens();
    }
  }
}
