import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayfay_merchant_flutter/core/constants/app_strings.dart';
import '../model/forgot_password_request.dart';
import '../repository/forgot_password_repository.dart';

final forgotPasswordControllerProvider =
    AutoDisposeAsyncNotifierProvider<ForgotPasswordController, void>(() {
  return ForgotPasswordController();
});

class ForgotPasswordController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    // Idle initial state
  }

  Future<bool> sendOtp({
    required String mobileNumber,
    int dialingCode = 91,
  }) async {
    final cleanMobile = mobileNumber.replaceAll(RegExp(r'\D'), '');

    if (cleanMobile.length != 10) {
      state = AsyncError(AppStrings.enterValidMobile, StackTrace.current);
      return false;
    }

    state = const AsyncLoading();

    try {
      final repository = ref.read(forgotPasswordRepositoryProvider);
      final request = ForgotPasswordRequest(
        dialingCode: dialingCode,
        mobileNumber: int.parse(cleanMobile),
      );

      await repository.sendForgotPasswordOtp(request);
      state = const AsyncData(null);
      return true;
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
      return false;
    }
  }

  Future<bool> resetPassword({
    required String mobileNumber,
    required String otp,
    required String newPassword,
    required String confirmPassword,
    int dialingCode = 91,
  }) async {
    final cleanMobile = mobileNumber.replaceAll(RegExp(r'\D'), '');
    final cleanOtp = otp.replaceAll(RegExp(r'\D'), '');

    if (cleanMobile.length != 10) {
      state = AsyncError(AppStrings.enterValidMobile, StackTrace.current);
      return false;
    }
    if (cleanOtp.length < 4) {
      state = AsyncError(AppStrings.otpRequired, StackTrace.current);
      return false;
    }
    if (newPassword.length < 6) {
      state = AsyncError(AppStrings.passwordMinLength, StackTrace.current);
      return false;
    }
    if (newPassword != confirmPassword) {
      state = AsyncError(AppStrings.passwordsDoNotMatch, StackTrace.current);
      return false;
    }

    state = const AsyncLoading();

    try {
      final repository = ref.read(forgotPasswordRepositoryProvider);
      final request = ResetPasswordRequest(
        dialingCode: dialingCode,
        mobileNumber: int.parse(cleanMobile),
        otp: int.parse(cleanOtp),
        password: newPassword,
      );

      await repository.resetPassword(request);
      state = const AsyncData(null);
      return true;
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
      return false;
    }
  }
}
