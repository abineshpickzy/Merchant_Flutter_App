import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bayfay_merchant_flutter/app/router/app_routes.dart';
import 'package:bayfay_merchant_flutter/app/theme/app_colors.dart';
import 'package:bayfay_merchant_flutter/core/constants/app_constants.dart';
import 'package:bayfay_merchant_flutter/core/constants/app_strings.dart';
import 'package:bayfay_merchant_flutter/core/validators/app_validators.dart';
import 'package:bayfay_merchant_flutter/core/widgets/app_button.dart';
import 'package:bayfay_merchant_flutter/core/widgets/app_phone_field.dart';
import 'package:bayfay_merchant_flutter/core/widgets/app_snackbar.dart';
import 'package:bayfay_merchant_flutter/core/widgets/app_toolbar.dart';
import '../controller/forgot_password_controller.dart';

/// Forgot Password screen matching Android's ForgetPasswordActivity & activity_forget_password.xml.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();
  final _mobileFocusNode = FocusNode();
  String? _mobileError;

  @override
  void initState() {
    super.initState();
    _mobileController.addListener(_clearAllErrorsOnTyping);
  }

  void _clearAllErrorsOnTyping() {
    if (_mobileError != null) {
      setState(() => _mobileError = null);
    }
  }

  @override
  void dispose() {
    _mobileController.removeListener(_clearAllErrorsOnTyping);
    _mobileFocusNode.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  void _onGetOtpPressed() async {
    final mobileError = AppValidators.validateMobile(_mobileController.text);
    setState(() => _mobileError = mobileError);

    if (mobileError != null) return;

    final mobile = _mobileController.text.trim();
    final success = await ref
        .read(forgotPasswordControllerProvider.notifier)
        .sendOtp(mobileNumber: mobile);

    if (success && mounted) {
      AppSnackBar.showSuccess(context, AppStrings.otpSentSuccess);

      context.push(
        AppRoutes.resetPassword,
        extra: {'mobileNumber': mobile},
      );
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
        title: AppStrings.forgotPasswordTitle,
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
                      // Field: Enter your mobile number (matching Android txt_email_or_mobile)
                      const Text(
                        AppStrings.enterYourMobileNumber,
                        style: TextStyle(
                          fontFamily: AppFonts.nunito,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.brandInputText,
                        ),
                      ),
                      const SizedBox(height: 6),
                      AppPhoneField(
                        controller: _mobileController,
                        focusNode: _mobileFocusNode,
                        enabled: !isLoading,
                        hintText: AppStrings.mobileHint10Digit,
                        errorText: _mobileError,
                        autovalidateMode: AutovalidateMode.disabled,
                        onChanged: (_) => _clearAllErrorsOnTyping(),
                        onSubmitted: (_) => _onGetOtpPressed(),
                      ),
                      const SizedBox(height: 26),

                      // Next Button: (Lime Green: @color/login_btn)
                      AppButton.lime(
                        height: 46,
                        borderRadius: 4,
                        text: AppStrings.next,
                        isLoading: isLoading,
                        onPressed: _onGetOtpPressed,
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
