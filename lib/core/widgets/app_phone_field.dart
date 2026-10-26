import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bayfay_merchant_flutter/app/theme/app_colors.dart';
import 'package:bayfay_merchant_flutter/core/constants/app_constants.dart';
import 'package:bayfay_merchant_flutter/core/constants/app_strings.dart';

/// Reusable mobile number field with +91 country badge, reactive border styling,
/// and inline error validation matching Android's StoreSignUpActivity / ForgetPasswordActivity.
class AppPhoneField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool enabled;
  final String? hintText;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final AutovalidateMode autovalidateMode;
  final String? errorText;

  const AppPhoneField({
    super.key,
    required this.controller,
    this.focusNode,
    this.enabled = true,
    this.hintText,
    this.onSubmitted,
    this.onChanged,
    this.validator,
    this.autovalidateMode = AutovalidateMode.disabled,
    this.errorText,
  });

  @override
  State<AppPhoneField> createState() => _AppPhoneFieldState();
}

class _AppPhoneFieldState extends State<AppPhoneField> {
  late FocusNode _focusNode;
  bool _isInternalFocusNode = false;
  final _fieldKey = GlobalKey<FormFieldState<String>>();

  @override
  void initState() {
    super.initState();
    if (widget.focusNode == null) {
      _focusNode = FocusNode();
      _isInternalFocusNode = true;
    } else {
      _focusNode = widget.focusNode!;
    }
    _focusNode.addListener(_onFocusChange);
    widget.controller.addListener(_onControllerChange);
  }

  void _onFocusChange() {
    if (mounted) setState(() {});
  }

  void _onControllerChange() {
    if (_fieldKey.currentState != null &&
        _fieldKey.currentState!.value != widget.controller.text) {
      _fieldKey.currentState!.didChange(widget.controller.text);
    }
  }

  @override
  void didUpdateWidget(AppPhoneField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChange);
      widget.controller.addListener(_onControllerChange);
    }
    if (oldWidget.focusNode != widget.focusNode) {
      if (_isInternalFocusNode) {
        _focusNode.removeListener(_onFocusChange);
        _focusNode.dispose();
      }
      if (widget.focusNode == null) {
        _focusNode = FocusNode();
        _isInternalFocusNode = true;
      } else {
        _focusNode = widget.focusNode!;
        _isInternalFocusNode = false;
      }
      _focusNode.addListener(_onFocusChange);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    widget.controller.removeListener(_onControllerChange);
    if (_isInternalFocusNode) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      key: _fieldKey,
      initialValue: widget.controller.text,
      autovalidateMode: widget.autovalidateMode,
      validator: widget.validator != null
          ? (value) => widget.validator!(value ?? widget.controller.text)
          : null,
      builder: (formState) {
        final hasFocus = _focusNode.hasFocus;
        final effectiveError = widget.errorText ?? formState.errorText;
        final hasError = effectiveError != null && effectiveError.isNotEmpty;
        final borderColor = hasError
            ? AppColors.error
            : (hasFocus ? AppColors.brandBlue : AppColors.brandInputBorder);
        final borderWidth = (hasFocus || hasError) ? 1.5 : 1.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: borderColor, width: borderWidth),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: double.infinity,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(color: borderColor, width: borderWidth),
                      ),
                    ),
                    child: const Text(
                      AppStrings.countryCodeIndia,
                      style: TextStyle(
                        fontFamily: AppFonts.productSans,
                        fontSize: 13,
                        fontWeight: FontWeight.normal,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _focusNode,
                      enabled: widget.enabled,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      onSubmitted: widget.onSubmitted,
                      maxLength: 10,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(
                        fontFamily: AppFonts.productSans,
                        fontSize: 13,
                        fontWeight: FontWeight.normal,
                        color: AppColors.brandInputText,
                      ),
                      onChanged: (val) {
                        formState.didChange(val);
                        widget.onChanged?.call(val);
                      },
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: widget.hintText ?? AppStrings.mobileHint10Digit,
                        hintStyle: const TextStyle(
                          fontFamily: AppFonts.productSans,
                          fontSize: 12,
                          color: Color(0xFFBDBDBD),
                          fontWeight: FontWeight.normal,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                        isDense: true,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        filled: false,
                        fillColor: Colors.transparent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (hasError) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  effectiveError,
                  style: const TextStyle(
                    fontFamily: AppFonts.productSans,
                    fontSize: 12,
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
