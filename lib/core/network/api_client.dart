import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_constants.dart';
import '../constants/app_strings.dart';
import '../errors/exceptions.dart';
import 'api_endpoints.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/logging_interceptor.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref);
});

class ApiClient {
  late final Dio _dio;

  ApiClient(Ref ref, [Dio? dio]) {
    _dio = dio ??
        Dio(
          BaseOptions(
            baseUrl: ApiEndpoints.baseUrl,
            connectTimeout: AppConstants.connectTimeout,
            receiveTimeout: AppConstants.receiveTimeout,
            sendTimeout: AppConstants.sendTimeout,
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
          ),
        );

    _dio.interceptors.addAll([
      AuthInterceptor(ref),
      if (kDebugMode) LoggingInterceptor(),
    ]);
  }

  // Exposed Dio instance if needed for special configurations
  Dio get dio => _dio;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    bool requiresAuth = true,
  }) async {
    try {
      final opts = _mergeAuthOption(options, requiresAuth);
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: opts,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    bool requiresAuth = true,
  }) async {
    try {
      final opts = _mergeAuthOption(options, requiresAuth);
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: opts,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    bool requiresAuth = true,
  }) async {
    try {
      final opts = _mergeAuthOption(options, requiresAuth);
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: opts,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    bool requiresAuth = true,
  }) async {
    try {
      final opts = _mergeAuthOption(options, requiresAuth);
      return await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: opts,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    bool requiresAuth = true,
  }) async {
    try {
      final opts = _mergeAuthOption(options, requiresAuth);
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: opts,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Options _mergeAuthOption(Options? options, bool requiresAuth) {
    final opts = options ?? Options();
    opts.extra = Map<String, dynamic>.from(opts.extra ?? {});
    opts.extra!['requiresAuth'] = requiresAuth;
    return opts;
  }

  AppException _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return const NetworkException(AppStrings.connectionTimeout);

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final data = error.response?.data;
        String errorMessage = AppStrings.serverError;

        if (data is Map<String, dynamic> && data.containsKey('message')) {
          errorMessage = data['message'].toString();
        } else if (data is String && data.isNotEmpty) {
          errorMessage = data;
        }

        switch (statusCode) {
          case HttpStatus.unauthorized:
            return UnauthorizedException(errorMessage, statusCode);
          case HttpStatus.forbidden:
            return ForbiddenException(errorMessage, statusCode);
          case HttpStatus.notFound:
            return NotFoundException(errorMessage, statusCode);
          default:
            return ServerException(errorMessage, statusCode);
        }

      case DioExceptionType.cancel:
        return const ServerException(AppStrings.requestCancelled);

      case DioExceptionType.badCertificate:
        return const ServerException(AppStrings.sslValidationFailed);

      case DioExceptionType.unknown:
      default:
        if (error.error is SocketException) {
          return const NetworkException(AppStrings.noInternetConnection);
        }
        return ServerException(error.message ?? AppStrings.unknownNetworkError);
    }
  }
}
