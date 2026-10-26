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
import '../controller/register_controller.dart';

/// Merchant Registration Step 2 matching Android's StoreVerificationActivity & merchant_signup_1.xml.
class RegisterVerifyScreen extends ConsumerStatefulWidget {
  final String firstName;
  final String lastName;
  final String email;
  final String mobileNumber;

  const RegisterVerifyScreen({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.mobileNumber,
  });

  @override
  ConsumerState<RegisterVerifyScreen> createState() =>
      _RegisterVerifyScreenState();
}

class _RegisterVerifyScreenState extends ConsumerState<RegisterVerifyScreen>
    with WidgetsBindingObserver {
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
    WidgetsBinding.instance.addObserver(this);
    _startResendTimer();
    _otpController.addListener(_clearAllErrorsOnTyping);
    _passwordController.addListener(_clearAllErrorsOnTyping);
    _confirmPasswordController.addListener(_clearAllErrorsOnTyping);
  }

  /// When the user returns to the app from Location Settings, reset any stale
  /// GPS error state so the next Next tap triggers a fresh GPS check and the
  /// SnackBar fires correctly on the new state transition.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final currentState = ref.read(registerControllerProvider);
      if (currentState is AsyncError) {
        ref.invalidate(registerControllerProvider);
      }
    }
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
    WidgetsBinding.instance.removeObserver(this);
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

    final success =
        await ref.read(registerControllerProvider.notifier).resendSignUpOtp(
              email: widget.email,
              mobileNumber: widget.mobileNumber,
            );

    if (success && mounted) {
      AppSnackBar.showSuccess(context, AppStrings.otpResentSuccess);
      _startResendTimer();
    }
  }

  void _onVerifyPressed() async {
    // Sequential Validation: validate fields strictly one by one upon clicking Next.
    // Step 1: Check OTP
    final otpText = _otpController.text.trim();
    if (otpText.isEmpty) {
      setState(() {
        _otpError = AppStrings.enterOtp;
        _passwordError = null;
        _confirmPasswordError = null;
      });
      return;
    } else if (otpText.length < 6) {
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
        .read(registerControllerProvider.notifier)
        .completeVerification(
          firstName: widget.firstName,
          lastName: widget.lastName,
          email: widget.email,
          mobileNumber: widget.mobileNumber,
          otp: _otpController.text.trim(),
          password: _passwordController.text,
        );

    if (success && mounted) {
      AppSnackBar.showSuccess(context, AppStrings.accountCreatedSuccess);
      context.go(AppRoutes.dashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    final registerState = ref.watch(registerControllerProvider);
    final isLoading = registerState.isLoading;

    ref.listen<AsyncValue<void>>(
      registerControllerProvider,
      (previous, next) {
        if (next is AsyncError) {
          AppSnackBar.showError(context, next.error);
        }
      },
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const AppToolbar(
        title: AppStrings.signup,
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
                      // Field 1: SMS Verification Code (matching Android mobile_number)
                      const Text(
                        AppStrings.smsVerificationLabel,
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
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        hintText: AppStrings.enter6DigitOtpHint,
                        errorText: _otpError,
                        autovalidateMode: AutovalidateMode.disabled,
                        onChanged: (_) => _clearAllErrorsOnTyping(),
                      ),

                      // Resend OTP Link (matching Android txt_resend)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _resendCooldown == 0 && !isLoading ? _onResendOtpPressed : null,
                          child: Text(
                            _resendCooldown > 0 ? '${AppStrings.resendOtp} (${_resendCooldown}s)' : AppStrings.resendOtp,
                            style: TextStyle(
                              fontFamily: AppFonts.nunito,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _resendCooldown > 0 ? Colors.grey : AppColors.brandBlue,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Field 2: New Password (matching Android new_pwd & edt_new_pwd)
                      const Text(
                        AppStrings.newPasswordLabel,
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
                        errorText: _passwordError,
                        autovalidateMode: AutovalidateMode.disabled,
                        onChanged: (_) => _clearAllErrorsOnTyping(),
                      ),
                      const SizedBox(height: 16),

                      // Field 3: Confirm Password
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
                        onFieldSubmitted: (_) => _onVerifyPressed(),
                        hintText: AppStrings.reenterPasswordHint,
                        errorText: _confirmPasswordError,
                        autovalidateMode: AutovalidateMode.disabled,
                        onChanged: (_) => _clearAllErrorsOnTyping(),
                      ),
                      const SizedBox(height: 26),

                      // Next Button: (Lime Green: @color/login_btn)
                      AppButton.lime(
                        height: 46,
                        borderRadius: 4,
                        text: AppStrings.next,
                        isLoading: isLoading,
                        onPressed: _onVerifyPressed,
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
