import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';

/// Helper to hash password with MD5 matching legacy Android app
String hashPasswordMd5(String password) {
  if (RegExp(r'^[a-fA-F0-9]{32}$').hasMatch(password)) {
    return password;
  }
  return md5.convert(utf8.encode(password)).toString();
}

/// Step 1: Initial Signup details verification request (StoreSignUpActivity)
/// Endpoint: POST auth/signup/verify
class SignUpVerifyRequest {
  final String email;
  final int dialingCode;
  final int mobileNumber;

  const SignUpVerifyRequest({
    required this.email,
    this.dialingCode = 91,
    required this.mobileNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'mobile': {
        'dialing_code': dialingCode,
        'number': mobileNumber,
      },
    };
  }
}

/// Step 2: Final Verification and Account Creation (StoreVerificationActivity)
/// Endpoint: POST auth/signup
class SignUpCompleteRequest {
  final String firstName;
  final String lastName;
  final String email;
  final int dialingCode;
  final int mobileNumber;
  final int otp;
  final String password;
  final double latitude;
  final double longitude;
  final String? deviceToken;
  final int? deviceType;

  const SignUpCompleteRequest({
    required this.firstName,
    required this.lastName,
    required this.email,
    this.dialingCode = 91,
    required this.mobileNumber,
    required this.otp,
    required this.password,
    this.latitude = 13.0473748,
    this.longitude = 79.9288071,
    this.deviceToken,
    this.deviceType,
  });

  Map<String, dynamic> toJson() {
    int detectedDeviceType = 2; // Default Android
    try {
      if (Platform.isIOS) {
        detectedDeviceType = 1;
      }
    } catch (_) {}

    return {
      'first_name': firstName,
      'last_name': lastName,
      'email': {'id': email},
      'mobile': {
        'dialing_code': dialingCode,
        'number': mobileNumber,
      },
      'otp': otp,
      'password': hashPasswordMd5(password),
      'current_location': {
        'coordinates': [longitude, latitude],
        'type': 'Point',
      },
      'device_details': {
        'token': deviceToken ?? '',
        'type': deviceType ?? detectedDeviceType,
      },
    };
  }
}

/// Backwards compatibility wrapper for one-shot registration
class RegisterRequest {
  final String firstName;
  final String lastName;
  final String email;
  final int dialingCode;
  final int mobileNumber;
  final String password;
  final String? storeName;
  final double latitude;
  final double longitude;
  final String? deviceToken;
  final int? deviceType;

  const RegisterRequest({
    required this.firstName,
    required this.lastName,
    required this.email,
    this.dialingCode = 91,
    required this.mobileNumber,
    required this.password,
    this.storeName,
    this.latitude = 13.0473748,
    this.longitude = 79.9288071,
    this.deviceToken,
    this.deviceType,
  });

  static String hashPassword(String password) => hashPasswordMd5(password);

  Map<String, dynamic> toJson() {
    int detectedDeviceType = 2;
    try {
      if (Platform.isIOS) {
        detectedDeviceType = 1;
      }
    } catch (_) {}

    return {
      'first_name': firstName,
      'last_name': lastName,
      'email': {'id': email},
      'mobile': {
        'dialing_code': dialingCode,
        'number': mobileNumber,
      },
      'password': hashPasswordMd5(password),
      if (storeName != null && storeName!.isNotEmpty)
        'wsbuyer': {'display_name': storeName},
      'current_location': {
        'coordinates': [longitude, latitude],
        'type': 'Point',
      },
      'device_details': {
        'token': deviceToken ?? '',
        'type': deviceType ?? detectedDeviceType,
      },
    };
  }
}
