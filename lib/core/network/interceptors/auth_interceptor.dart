import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayfay_merchant_flutter/app/providers/auth_state_provider.dart';
import 'package:bayfay_merchant_flutter/core/storage/secure_storage_service.dart';

class AuthInterceptor extends Interceptor {
  final Ref _ref;

  AuthInterceptor(this._ref);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Check if request allows unauthenticated access (e.g. login, forgot password)
    final requiresAuth = options.extra['requiresAuth'] ?? true;

    if (requiresAuth) {
      final storage = _ref.read(secureStorageServiceProvider);
      final token = await storage.getAccessToken();
      final schema = await storage.getAccessSchema();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = '$schema $token';
      }
    }

    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final path = err.requestOptions.path;
    final isAuthEndpoint = path.contains('auth/login') ||
        path.contains('auth/refresh') ||
        path.contains('auth/email') ||
        path.contains('auth/mobile');

    final responseData = err.response?.data?.toString() ?? '';
    final isInvalidTokenError = responseData.contains('Invalid Access-token') ||
        responseData.contains('Authentication failed') ||
        err.message?.contains('Invalid Access-token') == true ||
        err.message?.contains('Authentication failed') == true;

    final isUnauthorized = err.response?.statusCode == 401 || isInvalidTokenError;

    if (isUnauthorized && !isAuthEndpoint) {
      // Attempt token refresh on session expiration
      final refreshed =
          await _ref.read(authStateProvider.notifier).refreshToken();
      if (refreshed) {
        try {
          final storage = _ref.read(secureStorageServiceProvider);
          final newToken = await storage.getAccessToken();
          final schema = await storage.getAccessSchema();

          final requestOptions = err.requestOptions;
          requestOptions.headers['Authorization'] = '$schema $newToken';

          final dio = Dio();
          final response = await dio.fetch(requestOptions);
          return handler.resolve(response);
        } catch (_) {
          await _ref.read(authStateProvider.notifier).setSessionExpired();
        }
      } else {
        // Refresh failed or invalid token: set session expired
        await _ref.read(authStateProvider.notifier).setSessionExpired();
      }
    }
    handler.next(err);
  }
}
