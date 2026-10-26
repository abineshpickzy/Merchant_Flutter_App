import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayfay_merchant_flutter/core/network/api_client.dart';
import 'package:bayfay_merchant_flutter/core/network/api_endpoints.dart';
import '../model/register_request.dart';
import '../model/register_response.dart';

final registerRepositoryProvider = Provider<RegisterRepository>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return RegisterRepository(apiClient);
});

class RegisterRepository {
  final ApiClient _apiClient;

  const RegisterRepository(this._apiClient);

  /// Step 1: Verify sign up details and trigger SMS OTP
  /// Matching ApiService.callSignUpVerify -> POST auth/signup/verify
  Future<String> verifySignUp(SignUpVerifyRequest request) async {
    final response = await _apiClient.post(
      ApiEndpoints.signupVerify,
      data: request.toJson(),
      requiresAuth: false,
    );

    if (response.data is Map<String, dynamic>) {
      final map = response.data as Map<String, dynamic>;
      final success = map['success'] as bool? ?? false;
      final message = map['message'] as String? ?? 'OTP sent to mobile number';
      if (!success && map['error'] != null) {
        throw Exception(map['error']);
      }
      return message;
    }
    return 'Verification code sent successfully';
  }

  /// Step 2: Submit OTP, details, and password to complete registration
  /// Matching ApiService.callMerchantSignUp -> POST auth/signup
  Future<RegisterResponse> completeSignUp(SignUpCompleteRequest request) async {
    final response = await _apiClient.post(
      ApiEndpoints.signup,
      data: request.toJson(),
      requiresAuth: false,
    );

    if (response.data is Map<String, dynamic>) {
      return RegisterResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } else {
      throw Exception('Invalid response format received from auth/signup');
    }
  }

  /// One-shot registration support
  Future<RegisterResponse> register(RegisterRequest request) async {
    final response = await _apiClient.post(
      ApiEndpoints.signup,
      data: request.toJson(),
      requiresAuth: false,
    );

    if (response.data is Map<String, dynamic>) {
      return RegisterResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } else {
      throw Exception('Invalid response format received from auth/signup');
    }
  }
}
