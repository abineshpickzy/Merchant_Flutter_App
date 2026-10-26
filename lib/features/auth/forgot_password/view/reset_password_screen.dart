import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bayfay_merchant_flutter/app/router/app_routes.dart';
import 'package:bayfay_merchant_flutter/app/theme/app_colors.dart';
import 'package:bayfay_merchant_flutter/core/constants/app_constants.dart';
import 'package:bayfay_merchant_flutter/core/constants/app_strings.dart';
import 'package:bayfay_merchant_flutter/core/validators/app_validators.dart';
import 'package:bayfay_merchant_flutter/core/widgets/app_button.dart';
import 'package:bayfay_merchant_flutter/core/widgets/app_snackbar.dart';
import 'package:bayfay_merchant_flutter/core/widgets/app_text_field.dart';
import 'package:bayfay_merchant_flutter/core/widgets/app_toolbar.dart';
import '../controller/forgot_password_controller.dart';

/// Reset Password screen matching Android's ResetPasswordActivity & activity_reset_password.xml.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String mobileNumber;

  const ResetPasswordScreen({
    super.key,
    required this.mobileNumber,
  });

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _otpError;
  String? _passwordError;
  String? _confirmPasswordError;

  int _resendCooldown = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    _otpController.addListener(_clearAllErrorsOnTyping);
    _passwordController.addListener(_clearAllErrorsOnTyping);
    _confirmPasswordController.addListener(_clearAllErrorsOnTyping);
  }

  void _clearAllErrorsOnTyping() {
    if (_otpError != null ||
        _passwordError != null ||
        _confirmPasswordError != null) {
      setState(() {
        _otpError = null;
        _passwordError = null;
        _confirmPasswordError = null;
      });
    }
  }

  void _startResendTimer() {
    setState(() => _resendCooldown = 30);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown > 0) {
        setState(() => _resendCooldown--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _otpController.removeListener(_clearAllErrorsOnTyping);
    _passwordController.removeListener(_clearAllErrorsOnTyping);
    _confirmPasswordController.removeListener(_clearAllErrorsOnTyping);
    _timer?.cancel();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onResendOtpPressed() async {
    if (_resendCooldown > 0) return;

    final success = await ref
        .read(forgotPasswordControllerProvider.notifier)
        .sendOtp(mobileNumber: widget.mobileNumber);

    if (success && mounted) {
      AppSnackBar.showSuccess(context, AppStrings.otpResentSuccess);
      _startResendTimer();
    }
  }

  void _onUpdatePasswordPressed() async {
    // Sequential Validation: validate fields one by one.
    // Step 1: Check OTP
    final otpText = _otpController.text.trim();
    if (otpText.isEmpty) {
      setState(() {
        _otpError = AppStrings.enterOtp;
        _passwordError = null;
        _confirmPasswordError = null;
      });
      return;
    } else if (otpText.length < 4) {
      setState(() {
        _otpError = AppStrings.enterValidVerificationCode;
        _passwordError = null;
        _confirmPasswordError = null;
      });
      return;
    }

    // Step 2: Check Password (only after valid OTP is entered)
    final passwordText = _passwordController.text;
    final passwordError = AppValidators.validatePassword(passwordText);
    if (passwordError != null) {
      setState(() {
        _otpError = null;
        _passwordError = passwordError;
        _confirmPasswordError = null;
      });
      return;
    }

    // Step 3: Check Confirm Password (only after valid OTP and Password are entered)
    final confirmPasswordText = _confirmPasswordController.text;
    if (confirmPasswordText.isEmpty) {
      setState(() {
        _otpError = null;
        _passwordError = null;
        _confirmPasswordError = AppStrings.confirmPasswordRequired;
      });
      return;
    } else if (confirmPasswordText != passwordText) {
      setState(() {
        _otpError = null;
        _passwordError = null;
        _confirmPasswordError = AppStrings.passwordsDoNotMatch;
      });
      return;
    }

    // All fields are valid
    setState(() {
      _otpError = null;
      _passwordError = null;
      _confirmPasswordError = null;
    });

    final success = await ref
        .read(forgotPasswordControllerProvider.notifier)
        .resetPassword(
          mobileNumber: widget.mobileNumber,
          otp: _otpController.text,
          newPassword: _passwordController.text,
          confirmPassword: _confirmPasswordController.text,
        );

    if (success && mounted) {
      AppSnackBar.showSuccess(context, AppStrings.passwordResetSuccess);
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(forgotPasswordControllerProvider);
    final isLoading = state.isLoading;

    ref.listen<AsyncValue<void>>(
      forgotPasswordControllerProvider,
      (previous, next) {
        if (next is AsyncError) {
          AppSnackBar.showError(context, next.error);
        }
      },
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const AppToolbar(
        title: AppStrings.resetPasswordTitle,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.disabled,
                child: Container(
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.brandCardBorder, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Field 1: Enter your OTP (matching Android txt_otp & edit_otp)
                      const Text(
                        AppStrings.enterOtpLabel,
                        style: TextStyle(
                          fontFamily: AppFonts.nunito,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.brandInputText,
                        ),
                      ),
                      const SizedBox(height: 6),
                      AppTextField.brand(
                        controller: _otpController,
                        enabled: !isLoading,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        hintText: AppStrings.enterOtpHint,
                        autovalidateMode: AutovalidateMode.disabled,
                        errorText: _otpError,
                        onChanged: (_) => _clearAllErrorsOnTyping(),
                      ),
                      const SizedBox(height: 8),

                      // Resend OTP button (matching Android txt_resend)
                      Align(
                        alignment: Alignment.centerRight,
                        child: InkWell(
                          onTap: (_resendCooldown == 0 && !isLoading)
                              ? _onResendOtpPressed
                              : null,
                          child: Text(
                            _resendCooldown > 0
                                ? '${AppStrings.resendOtp} (${_resendCooldown}s)'
                                : AppStrings.resendOtp,
                            style: TextStyle(
                              fontFamily: AppFonts.nunito,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _resendCooldown > 0
                                  ? Colors.grey
                                  : AppColors.brandBlue,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Field 2: New Password (matching Android txt_enter_password & edit_password)
                      const Text(
                        AppStrings.enterPasswordLabel,
                        style: TextStyle(
                          fontFamily: AppFonts.nunito,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.brandInputText,
                        ),
                      ),
                      const SizedBox(height: 6),
                      AppTextField.brand(
                        controller: _passwordController,
                        enabled: !isLoading,
                        isPassword: true,
                        textInputAction: TextInputAction.next,
                        hintText: AppStrings.newPasswordHint,
                        autovalidateMode: AutovalidateMode.disabled,
                        errorText: _passwordError,
                        onChanged: (_) => _clearAllErrorsOnTyping(),
                      ),
                      const SizedBox(height: 16),

                      // Field 3: Confirm Password (matching Android txt_confirm_password & edit_confirm_password)
                      const Text(
                        AppStrings.confirmPasswordLabel,
                        style: TextStyle(
                          fontFamily: AppFonts.nunito,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.brandInputText,
                        ),
                      ),
                      const SizedBox(height: 6),
                      AppTextField.brand(
                        controller: _confirmPasswordController,
                        enabled: !isLoading,
                        isPassword: true,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _onUpdatePasswordPressed(),
                        hintText: AppStrings.confirmPasswordHint,
                        autovalidateMode: AutovalidateMode.disabled,
                        errorText: _confirmPasswordError,
                        onChanged: (_) => _clearAllErrorsOnTyping(),
                      ),
                      const SizedBox(height: 26),

                      // Submit Button: Next (Lime Green: @color/login_btn)
                      AppButton.lime(
                        height: 46,
                        borderRadius: 4,
                        text: AppStrings.next,
                        isLoading: isLoading,
                        onPressed: _onUpdatePasswordPressed,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
