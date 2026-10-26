import 'dart:convert';
import 'package:crypto/crypto.dart';

String _hashMd5(String password) {
  if (RegExp(r'^[a-fA-F0-9]{32}$').hasMatch(password)) {
    return password;
  }
  return md5.convert(utf8.encode(password)).toString();
}

/// Request model for sending Forgot Password OTP
/// Matching ForgetPasswordActivity.java -> POST auth/forgotpassword/verify
class ForgotPasswordRequest {
  final int dialingCode;
  final int mobileNumber;

  const ForgotPasswordRequest({
    this.dialingCode = 91,
    required this.mobileNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'mobile': {
        'dialing_code': dialingCode,
        'number': mobileNumber,
      },
    };
  }
}

/// Request model for resetting password with OTP
/// Matching ResetPasswordActivity.java -> POST auth/resetpassword
class ResetPasswordRequest {
  final int dialingCode;
  final int mobileNumber;
  final int otp;
  final String password;

  const ResetPasswordRequest({
    this.dialingCode = 91,
    required this.mobileNumber,
    required this.otp,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'mobile': {
        'dialing_code': dialingCode,
        'number': mobileNumber,
      },
      'otp': otp,
      'password': _hashMd5(password),
    };
  }
}
