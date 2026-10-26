import '../constants/app_strings.dart';

abstract final class AppValidators {
  static String? validateEmailOrMobile(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.enterEmailOrMobile;
    }
    final text = value.trim();
    if (text.contains('@')) {
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(text)) {
        return AppStrings.enterValidEmail;
      }
    } else {
      final digits = text.replaceAll(RegExp(r'\D'), '');
      if (digits.length != 10) {
        return AppStrings.enterValidMobile;
      }
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.mobileRequired;
    }
    final clean = value.replaceAll(RegExp(r'\D'), '');
    if (clean.length != 10) {
      return AppStrings.mobileDigitsRequired;
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.enterPassword;
    }
    if (value.length < 6) {
      return AppStrings.passwordMinLength;
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.emailRequired;
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return AppStrings.enterValidEmail;
    }
    return null;
  }

  static String? validateFirstName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.firstNameRequired;
    }
    return null;
  }

  static String? validateLastName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.lastNameRequired;
    }
    return null;
  }

  static String? validateMobile(String? value) => validatePhone(value);

  static String? validateRequired(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return fieldName != null ? '$fieldName is required' : AppStrings.fieldRequired;
    }
    return null;
  }

  static String? validateOtp(String? value, [int length = 6]) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.otpRequired;
    }
    if (value.trim().length != length) {
      return 'OTP must be $length digits';
    }
    return null;
  }
}
