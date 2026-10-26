import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayfay_merchant_flutter/core/network/api_client.dart';
import 'package:bayfay_merchant_flutter/core/network/api_endpoints.dart';
import '../model/forgot_password_request.dart';

final forgotPasswordRepositoryProvider =
    Provider<ForgotPasswordRepository>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return ForgotPasswordRepository(apiClient);
});

class ForgotPasswordRepository {
  final ApiClient _apiClient;

  const ForgotPasswordRepository(this._apiClient);

  /// Step 1: Send OTP to mobile for password reset
  /// Matching ApiService.callGetOTPForgot -> POST auth/forgotpassword/verify
  Future<String> sendForgotPasswordOtp(ForgotPasswordRequest request) async {
    final response = await _apiClient.post(
      ApiEndpoints.forgotPasswordVerify,
      data: request.toJson(),
      requiresAuth: false,
    );

    if (response.data is Map<String, dynamic>) {
      final map = response.data as Map<String, dynamic>;
      final success = map['success'] as bool? ?? false;
      final message = map['message'] as String? ?? 'OTP sent successfully';
      if (!success && map['error'] != null) {
        throw Exception(map['error']);
      }
      return message;
    }
    return 'OTP sent successfully';
  }

  /// Step 2: Submit new password with OTP
  /// Matching ApiService.callUpdateNewPassword -> POST auth/resetpassword
  Future<String> resetPassword(ResetPasswordRequest request) async {
    final response = await _apiClient.post(
      ApiEndpoints.resetPassword,
      data: request.toJson(),
      requiresAuth: false,
    );

    if (response.data is Map<String, dynamic>) {
      final map = response.data as Map<String, dynamic>;
      final success = map['success'] as bool? ?? false;
      final message =
          map['message'] as String? ?? 'Password updated successfully';
      if (!success && map['error'] != null) {
        throw Exception(map['error']);
      }
      return message;
    }
    return 'Password updated successfully';
  }
}
