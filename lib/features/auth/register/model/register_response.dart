import 'package:equatable/equatable.dart';
import '../../login/model/login_response.dart';

class RegisterResponse extends Equatable {
  final bool success;
  final String message;
  final MerchantProfile? profile;
  final AuthTokens? tokens;

  const RegisterResponse({
    required this.success,
    required this.message,
    this.profile,
    this.tokens,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    final success = json['success'] as bool? ?? true;
    final message = json['message'] as String? ?? '';

    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    MerchantProfile? profile;
    if (data['merchant_profile'] is Map<String, dynamic>) {
      profile = MerchantProfile.fromJson(
        data['merchant_profile'] as Map<String, dynamic>,
      );
    }

    AuthTokens? tokens;
    if (data['auth_token'] is Map<String, dynamic>) {
      tokens = AuthTokens.fromJson(data['auth_token'] as Map<String, dynamic>);
    }

    return RegisterResponse(
      success: success,
      message: message,
      profile: profile,
      tokens: tokens,
    );
  }

  @override
  List<Object?> get props => [success, message, profile, tokens];
}
