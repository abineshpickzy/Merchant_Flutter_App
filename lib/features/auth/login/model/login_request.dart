import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';

class LoginRequest {
  final String? email;
  final int? dialingCode;
  final int? mobileNumber;
  final String password;
  final double latitude;
  final double longitude;
  final String? deviceToken;
  final int? deviceType;

  const LoginRequest({
    this.email,
    this.dialingCode = 91,
    this.mobileNumber,
    required this.password,
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.deviceToken,
    this.deviceType,
  });

  /// Factory constructor matching Android's verifyLogin(emailOrMobilNo, password)
  factory LoginRequest.fromInput({
    required String emailOrMobile,
    required String password,
    double latitude = 0.0,
    double longitude = 0.0,
    String? deviceToken,
    int? deviceType,
  }) {
    final cleanInput = emailOrMobile.trim();
    if (cleanInput.contains('@')) {
      return LoginRequest(
        email: cleanInput,
        password: password,
        latitude: latitude,
        longitude: longitude,
        deviceToken: deviceToken,
        deviceType: deviceType,
      );
    } else {
      final numberOnly = cleanInput.replaceAll(RegExp(r'\D'), '');
      return LoginRequest(
        dialingCode: 91,
        mobileNumber: int.tryParse(numberOnly) ?? 0,
        password: password,
        latitude: latitude,
        longitude: longitude,
        deviceToken: deviceToken,
        deviceType: deviceType,
      );
    }
  }

  bool get isEmail => email != null && email!.isNotEmpty;

  /// Returns 'email' or 'mobile' to dynamically route to auth/{type}
  String get type => isEmail ? 'email' : 'mobile';

  static String hashPassword(String password) {
    if (RegExp(r'^[a-fA-F0-9]{32}$').hasMatch(password)) {
      return password;
    }
    return md5.convert(utf8.encode(password)).toString();
  }

  Map<String, dynamic> toJson() {
    int detectedDeviceType = 2; // Android default
    try {
      if (Platform.isIOS) {
        detectedDeviceType = 1;
      }
    } catch (_) {}

    final json = <String, dynamic>{
      'current_location': {
        'coordinates': [longitude, latitude],
        'type': 'Point',
      },
      'device_details': {
        'token': deviceToken ?? '',
        'type': deviceType ?? detectedDeviceType,
      },
      'password': hashPassword(password),
    };

    if (isEmail) {
      json['email'] = email;
    } else {
      json['mobile'] = {
        'dialing_code': dialingCode ?? 91,
        'number': mobileNumber ?? 0,
      };
    }

    return json;
  }
}
