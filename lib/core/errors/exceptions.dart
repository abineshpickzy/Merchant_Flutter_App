/// Base class for all application exceptions.
abstract class AppException implements Exception {
  final String message;
  final int? statusCode;

  const AppException(this.message, [this.statusCode]);

  @override
  String toString() => message;

  /// Full technical representation for logging/debugging.
  String toDebugString() => '$runtimeType: $message (code: $statusCode)';
}

/// Thrown when server returns non-200 responses.
class ServerException extends AppException {
  const ServerException(super.message, [super.statusCode]);
}

/// Thrown when device has no network connection or request times out.
class NetworkException extends AppException {
  const NetworkException([super.message = 'Network connection failed. Please check your internet.']);
}

/// Thrown when unauthorized (401).
class UnauthorizedException extends AppException {
  const UnauthorizedException([super.message = 'Session expired or unauthorized. Please log in again.', super.statusCode = 401]);
}

/// Thrown on 403 Forbidden.
class ForbiddenException extends AppException {
  const ForbiddenException([super.message = 'Access forbidden.', super.statusCode = 403]);
}

/// Thrown on 404 Not Found.
class NotFoundException extends AppException {
  const NotFoundException([super.message = 'Requested resource was not found.', super.statusCode = 404]);
}

/// Thrown when local cache/storage operation fails.
class CacheException extends AppException {
  const CacheException([super.message = 'Local cache error occurred.']);
}
