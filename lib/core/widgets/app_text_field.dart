import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bayfay_merchant_flutter/app/theme/app_colors.dart';
import '../constants/app_constants.dart';
import '../constants/app_strings.dart';

/// Reusable application text input field with standardized styling,
/// built-in password visibility toggle, and convenience constructors.
class AppTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final Widget? prefix;
  final String? prefixText;
  final bool obscureText;
  final bool isPassword;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final FocusNode? focusNode;
  final int maxLines;
  final int? maxLength;
  final TextCapitalization textCapitalization;
  final BoxConstraints? prefixIconConstraints;
  final bool isBrandStyle;
  final EdgeInsetsGeometry? contentPadding;
  final AutovalidateMode autovalidateMode;

  const AppTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.prefix,
    this.prefixText,
    this.obscureText = false,
    this.isPassword = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.inputFormatters,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.focusNode,
    this.maxLines = 1,
    this.maxLength,
    this.textCapitalization = TextCapitalization.none,
    this.prefixIconConstraints,
    this.isBrandStyle = false,
    this.contentPadding,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
  });

  /// Preconfigured text field matching Android auth form styling
  /// (4px radius, brandInputBorder, 13px ProductSans normal text, 12px hint).
  factory AppTextField.brand({
    Key? key,
    TextEditingController? controller,
    String? hintText,
    String? labelText,
    String? errorText,
    bool isPassword = false,
    bool obscureText = false,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    FormFieldValidator<String>? validator,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onFieldSubmitted,
    List<TextInputFormatter>? inputFormatters,
    bool enabled = true,
    FocusNode? focusNode,
    int maxLines = 1,
    int? maxLength,
    TextCapitalization textCapitalization = TextCapitalization.none,
    Widget? suffixIcon,
    Widget? prefixIcon,
    EdgeInsetsGeometry? contentPadding,
    AutovalidateMode autovalidateMode = AutovalidateMode.onUserInteraction,
  }) {
    return AppTextField(
      key: key,
      controller: controller,
      hintText: hintText,
      labelText: labelText,
      errorText: errorText,
      isPassword: isPassword,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      inputFormatters: inputFormatters,
      enabled: enabled,
      focusNode: focusNode,
      maxLines: maxLines,
      maxLength: maxLength,
      textCapitalization: textCapitalization,
      suffixIcon: suffixIcon,
      prefixIcon: prefixIcon,
      isBrandStyle: true,
      contentPadding: contentPadding ??
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      autovalidateMode: autovalidateMode,
    );
  }

  /// Preconfigured text field for Email input
  factory AppTextField.email({
    Key? key,
    TextEditingController? controller,
    String? labelText,
    String? hintText,
    TextInputAction textInputAction = TextInputAction.next,
    FormFieldValidator<String>? validator,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onFieldSubmitted,
    bool enabled = true,
    FocusNode? focusNode,
    AutovalidateMode autovalidateMode = AutovalidateMode.onUserInteraction,
  }) {
    return AppTextField(
      key: key,
      controller: controller,
      labelText: labelText ?? AppStrings.emailLabel,
      hintText: hintText ?? AppStrings.emailHint,
      prefixIcon: const Icon(Icons.email_outlined),
      keyboardType: TextInputType.emailAddress,
      textInputAction: textInputAction,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      enabled: enabled,
      focusNode: focusNode,
      autovalidateMode: autovalidateMode,
    );
  }

  /// Preconfigured text field for Password input with built-in show/hide toggle
  factory AppTextField.password({
    Key? key,
    TextEditingController? controller,
    String? labelText,
    String? hintText,
    TextInputAction textInputAction = TextInputAction.done,
    FormFieldValidator<String>? validator,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onFieldSubmitted,
    bool enabled = true,
    FocusNode? focusNode,
    AutovalidateMode autovalidateMode = AutovalidateMode.onUserInteraction,
  }) {
    return AppTextField(
      key: key,
      controller: controller,
      labelText: labelText ?? AppStrings.passwordLabel,
      hintText: hintText ?? AppStrings.passwordHint,
      prefixIcon: const Icon(Icons.lock_outline),
      isPassword: true,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: textInputAction,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      enabled: enabled,
      focusNode: focusNode,
      autovalidateMode: autovalidateMode,
    );
  }

  /// Preconfigured text field for Phone Number input with country code badge
  factory AppTextField.phone({
    Key? key,
    TextEditingController? controller,
    String? labelText,
    String? hintText,
    String countryCode = AppStrings.countryCodeIndia,
    TextInputAction textInputAction = TextInputAction.next,
    FormFieldValidator<String>? validator,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onFieldSubmitted,
    bool enabled = true,
    FocusNode? focusNode,
    int maxLength = 10,
    AutovalidateMode autovalidateMode = AutovalidateMode.onUserInteraction,
  }) {
    return AppTextField(
      key: key,
      controller: controller,
      labelText: labelText ?? AppStrings.mobileNumberLabel,
      hintText: hintText ?? AppStrings.mobileNumberHint,
      keyboardType: TextInputType.phone,
      textInputAction: textInputAction,
      enabled: enabled,
      focusNode: focusNode,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      autovalidateMode: autovalidateMode,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(maxLength),
      ],
      prefixIcon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        margin: const EdgeInsets.only(right: 8),
        alignment: Alignment.center,
        width: 65,
        child: Text(
          countryCode,
          style: const TextStyle(
            fontFamily: AppFonts.productSans,
            fontWeight: FontWeight.normal,
            fontSize: 15,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 60, maxHeight: 40),
    );
  }

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscured;

  @override
  void initState() {
    super.initState();
    _obscured = widget.isPassword || widget.obscureText;
  }

  void _toggleObscurity() {
    setState(() {
      _obscured = !_obscured;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget? effectiveSuffixIcon = widget.suffixIcon;

    if (widget.isPassword) {
      effectiveSuffixIcon = IconButton(
        icon: Icon(
          widget.isBrandStyle
              ? (_obscured
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined)
              : (_obscured ? Icons.visibility_off : Icons.visibility),
          size: widget.isBrandStyle ? 18 : 22,
          color: widget.isBrandStyle
              ? Colors.grey.shade600
              : AppColors.textSecondary,
        ),
        onPressed: widget.enabled ? _toggleObscurity : null,
      );
    }

    final effectiveStyle = widget.isBrandStyle
        ? const TextStyle(
            fontFamily: AppFonts.productSans,
            fontSize: 13,
            fontWeight: FontWeight.normal,
            color: AppColors.brandInputText,
          )
        : const TextStyle(
            fontFamily: AppFonts.productSans,
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: AppColors.textPrimary,
          );

    final effectiveDecoration = widget.isBrandStyle
        ? InputDecoration(
            labelText: widget.labelText,
            hintText: widget.hintText,
            helperText: widget.helperText,
            errorText: widget.errorText,
            prefixIcon: widget.prefixIcon,
            suffixIcon: effectiveSuffixIcon,
            prefix: widget.prefix,
            prefixText: widget.prefixText,
            prefixIconConstraints: widget.prefixIconConstraints,
            counterText: '',
            filled: true,
            fillColor: Colors.white,
            hintStyle: const TextStyle(
              fontFamily: AppFonts.productSans,
              fontSize: 12,
              color: Color(0xFFBDBDBD),
              fontWeight: FontWeight.normal,
            ),
            contentPadding: widget.contentPadding ??
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: AppColors.brandInputBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: AppColors.brandInputBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: AppColors.brandBlue, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: AppColors.error, width: 1.5),
            ),
          )
        : InputDecoration(
            labelText: widget.labelText,
            hintText: widget.hintText,
            helperText: widget.helperText,
            errorText: widget.errorText,
            prefixIcon: widget.prefixIcon,
            suffixIcon: effectiveSuffixIcon,
            prefix: widget.prefix,
            prefixText: widget.prefixText,
            prefixIconConstraints: widget.prefixIconConstraints,
            contentPadding: widget.contentPadding,
          );

    return TextFormField(
      controller: widget.controller,
      autovalidateMode: widget.autovalidateMode,
      obscureText: _obscured,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      style: effectiveStyle,
      validator: widget.validator,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onFieldSubmitted,
      inputFormatters: widget.inputFormatters,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      autofocus: widget.autofocus,
      focusNode: widget.focusNode,
      maxLines: widget.maxLines,
      maxLength: widget.maxLength,
      buildCounter: widget.isBrandStyle
          ? (context, {required currentLength, required isFocused, maxLength}) => null
          : null,
      textCapitalization: widget.textCapitalization,
      decoration: effectiveDecoration,
    );
  }
}
