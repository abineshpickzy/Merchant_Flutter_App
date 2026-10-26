import 'package:equatable/equatable.dart';

/// Base Failure representation for UI consumption.
abstract class Failure extends Equatable {
  final String message;
  final int? statusCode;

  const Failure(this.message, [this.statusCode]);

  @override
  List<Object?> get props => [message, statusCode];

  @override
  String toString() => message;

  /// Full technical representation for logging/debugging.
  String toDebugString() => '$runtimeType(message: $message, code: $statusCode)';
}

class ServerFailure extends Failure {
  const ServerFailure(super.message, [super.statusCode]);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection. Please verify your network.']);
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.message = 'Session expired. Please log in again.', super.statusCode = 401]);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Failed to load local data.']);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'An unexpected error occurred. Please try again.']);
}
