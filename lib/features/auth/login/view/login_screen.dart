import 'package:flutter/material.dart';
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
import '../controller/login_controller.dart';

/// Login screen matching Android's LoginActivity.java & activity_login.xml.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _identifierError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _identifierController.addListener(_clearAllErrorsOnTyping);
    _passwordController.addListener(_clearAllErrorsOnTyping);
  }

  /// When the user returns to the app from Location Settings, reset any stale
  /// GPS error state so the next Login tap triggers a fresh GPS check and the
  /// SnackBar fires correctly on the new state transition.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final currentState = ref.read(loginControllerProvider);
      if (currentState is AsyncError) {
        ref.invalidate(loginControllerProvider);
      }
    }
  }

  void _clearAllErrorsOnTyping() {
    if (_identifierError != null || _passwordError != null) {
      setState(() {
        _identifierError = null;
        _passwordError = null;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _identifierController.removeListener(_clearAllErrorsOnTyping);
    _passwordController.removeListener(_clearAllErrorsOnTyping);
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLoginPressed() {
    // Manual Trigger: validate only upon clicking Login
    final identifierError =
        AppValidators.validateEmailOrMobile(_identifierController.text);
    final passwordError =
        AppValidators.validatePassword(_passwordController.text);

    // Reset on Next/Submit: re-validates all fields
    setState(() {
      _identifierError = identifierError;
      _passwordError = passwordError;
    });

    if (identifierError != null || passwordError != null) {
      return;
    }

    ref.read(loginControllerProvider.notifier).login(
          emailOrMobile: _identifierController.text.trim(),
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginControllerProvider);
    final isLoading = loginState.isLoading;

    ref.listen<AsyncValue<void>>(loginControllerProvider, (previous, next) {
      if (next is AsyncError) {
        AppSnackBar.showError(context, next.error);
      } else if (previous?.isLoading == true && next is AsyncData) {
        context.go(AppRoutes.dashboard);
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.brandInputText, size: 20),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.welcome);
            }
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
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
                      // Card Header: "Login" (matching Android login_header)
                      const Text(
                        AppStrings.login,
                        style: TextStyle(
                          fontFamily: AppFonts.nunito,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.brandInputText,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Label: "Email or Mobile Number" (matching Android email_or_mno)
                      const Text(
                        AppStrings.emailOrMobileLabel,
                        style: TextStyle(
                          fontFamily: AppFonts.nunito,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.brandInputText,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Field: login_edt
                      AppTextField.brand(
                        controller: _identifierController,
                        enabled: !isLoading,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        hintText: AppStrings.emailOrMobileHint,
                        errorText: _identifierError,
                        autovalidateMode: AutovalidateMode.disabled,
                        onChanged: (_) => _clearAllErrorsOnTyping(),
                      ),
                      const SizedBox(height: 18),

                      // Label Row: "Password" and "Forgot Password?"
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            AppStrings.passwordLabel,
                            style: TextStyle(
                              fontFamily: AppFonts.nunito,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.brandInputText,
                            ),
                          ),
                          InkWell(
                            onTap: isLoading ? null : () => context.push(AppRoutes.forgotPassword),
                            child: const Text(
                              AppStrings.forgotPasswordAction,
                              style: TextStyle(
                                fontFamily: AppFonts.nunito,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.brandInputText,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Field: pwd_edt
                      AppTextField.brand(
                        controller: _passwordController,
                        enabled: !isLoading,
                        isPassword: true,
                        textInputAction: TextInputAction.done,
                        hintText: AppStrings.passwordHint,
                        errorText: _passwordError,
                        autovalidateMode: AutovalidateMode.disabled,
                        onChanged: (_) => _clearAllErrorsOnTyping(),
                        onFieldSubmitted: (_) => _onLoginPressed(),
                      ),
                      const SizedBox(height: 24),

                      // Primary Button: "Merchant Login" (Blue: @drawable/blue_btn_bg)
                      AppButton.primary(
                        height: 48,
                        borderRadius: 4,
                        text: AppStrings.merchantLogin,
                        isLoading: isLoading,
                        loadingText: AppStrings.loggingOn,
                        onPressed: _onLoginPressed,
                      ),
                      const SizedBox(height: 28),

                      // Divider Row: "What new ?" (matching Android textView3)
                      Row(
                        children: [
                          const Expanded(child: Divider(color: Colors.black12, thickness: 1)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0),
                            child: Text(
                              AppStrings.whatsNewText,
                              style: TextStyle(
                                fontFamily: AppFonts.nunito,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                          const Expanded(child: Divider(color: Colors.black12, thickness: 1)),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Secondary Button: "Sign Up" (Lime Green: @drawable/sign_up_btn_bg)
                      AppButton.lime(
                        height: 48,
                        borderRadius: 4,
                        text: AppStrings.signup,
                        onPressed: isLoading ? null : () => context.push(AppRoutes.register),
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
