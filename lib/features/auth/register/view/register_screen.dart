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
import 'package:bayfay_merchant_flutter/core/widgets/app_text_field.dart';
import 'package:bayfay_merchant_flutter/core/widgets/app_toolbar.dart';
import '../controller/register_controller.dart';

/// Merchant Registration Step 1 matching Android's StoreSignUpActivity & merchant_signup.xml.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _mobileFocusNode = FocusNode();

  String? _firstNameError;
  String? _lastNameError;
  String? _emailError;
  String? _mobileError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _firstNameController.addListener(_clearAllErrorsOnTyping);
    _lastNameController.addListener(_clearAllErrorsOnTyping);
    _emailController.addListener(_clearAllErrorsOnTyping);
    _mobileController.addListener(_clearAllErrorsOnTyping);
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
    if (_firstNameError != null ||
        _lastNameError != null ||
        _emailError != null ||
        _mobileError != null) {
      setState(() {
        _firstNameError = null;
        _lastNameError = null;
        _emailError = null;
        _mobileError = null;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _firstNameController.removeListener(_clearAllErrorsOnTyping);
    _lastNameController.removeListener(_clearAllErrorsOnTyping);
    _emailController.removeListener(_clearAllErrorsOnTyping);
    _mobileController.removeListener(_clearAllErrorsOnTyping);
    _mobileFocusNode.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  void _onNextPressed() async {
    // Validate only upon clicking 'Next'
    final firstNameError =
        AppValidators.validateFirstName(_firstNameController.text);
    final lastNameError =
        AppValidators.validateLastName(_lastNameController.text);
    final emailError = AppValidators.validateEmail(_emailController.text);
    final mobileError =
        AppValidators.validateMobile(_mobileController.text);

    setState(() {
      _firstNameError = firstNameError;
      _lastNameError = lastNameError;
      _emailError = emailError;
      _mobileError = mobileError;
    });

    final hasError = firstNameError != null ||
        lastNameError != null ||
        emailError != null ||
        mobileError != null;

    if (hasError) return;

    final success = await ref
        .read(registerControllerProvider.notifier)
        .initiateSignUp(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim(),
          mobileNumber: _mobileController.text.trim(),
        );

    if (success && mounted) {
      AppSnackBar.showSuccess(context, AppStrings.otpSentSuccess);

      context.push(
        AppRoutes.registerVerify,
        extra: {
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'email': _emailController.text.trim(),
          'mobileNumber': _mobileController.text.trim(),
        },
      );
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
                      // Field 1: First Name (matching Android txt_first_name & edit_first_name)
                      const Text(
                        AppStrings.firstNameLabel,
                        style: TextStyle(
                          fontFamily: AppFonts.productSans,
                          fontSize: 13,
                          fontWeight: FontWeight.normal,
                          color: AppColors.brandInputText,
                        ),
                      ),
                      const SizedBox(height: 6),
                      AppTextField.brand(
                        controller: _firstNameController,
                        enabled: !isLoading,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        hintText: AppStrings.firstNameHint,
                        errorText: _firstNameError,
                        autovalidateMode: AutovalidateMode.disabled,
                        onChanged: (_) => _clearAllErrorsOnTyping(),
                      ),
                      const SizedBox(height: 16),

                      // Field 2: Last Name (matching Android txt_last_name & edit_last_name)
                      const Text(
                        AppStrings.lastNameLabel,
                        style: TextStyle(
                          fontFamily: AppFonts.nunito,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.brandInputText,
                        ),
                      ),
                      const SizedBox(height: 6),
                      AppTextField.brand(
                        controller: _lastNameController,
                        enabled: !isLoading,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        hintText: AppStrings.lastNameHint,
                        errorText: _lastNameError,
                        autovalidateMode: AutovalidateMode.disabled,
                        onChanged: (_) => _clearAllErrorsOnTyping(),
                      ),
                      const SizedBox(height: 16),

                      // Field 3: Email Id (matching Android email_id & edt_email_Id)
                      const Text(
                        AppStrings.enterYourEmailId,
                        style: TextStyle(
                          fontFamily: AppFonts.nunito,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.brandInputText,
                        ),
                      ),
                      const SizedBox(height: 6),
                      AppTextField.brand(
                        controller: _emailController,
                        enabled: !isLoading,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        hintText: AppStrings.emailHint,
                        errorText: _emailError,
                        autovalidateMode: AutovalidateMode.disabled,
                        onChanged: (_) => _clearAllErrorsOnTyping(),
                      ),
                      const SizedBox(height: 16),

                      // Field 4: Mobile Number with +91 Prefix Row (matching Android mobile_number & rel_mobile)
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
                        onSubmitted: (_) => _onNextPressed(),
                      ),
                      const SizedBox(height: 26),

                      // Next Button: (Lime Green: @color/login_btn)
                      AppButton.lime(
                        height: 46,
                        borderRadius: 4,
                        text: AppStrings.next,
                        isLoading: isLoading,
                        onPressed: _onNextPressed,
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
