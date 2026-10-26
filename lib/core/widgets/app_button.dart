import 'package:flutter/material.dart';
import 'package:bayfay_merchant_flutter/app/theme/app_colors.dart';
import 'package:bayfay_merchant_flutter/core/constants/app_constants.dart';
import 'loading_indicator.dart';

/// Button visual variants for the merchant application.
enum AppButtonVariant { primary, lime, outline, danger }

/// Reusable application button supporting brand color variants, disabled states,
/// and integrated [LoadingIndicator].
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final String? loadingText;
  final Widget? icon;
  final double height;
  final double? width;
  final double borderRadius;
  final TextStyle? textStyle;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.loadingText,
    this.icon,
    this.height = 48,
    this.width,
    this.borderRadius = 4,
    this.textStyle,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
  });

  /// Blue brand button (matching Android @drawable/blue_btn_bg / @color/logo)
  factory AppButton.primary({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    bool isLoading = false,
    String? loadingText,
    Widget? icon,
    double height = 48,
    double? width,
    double borderRadius = 4,
    TextStyle? textStyle,
  }) {
    return AppButton(
      key: key,
      text: text,
      onPressed: onPressed,
      variant: AppButtonVariant.primary,
      isLoading: isLoading,
      loadingText: loadingText,
      icon: icon,
      height: height,
      width: width,
      borderRadius: borderRadius,
      textStyle: textStyle,
    );
  }

  /// Lime green brand button (matching Android @drawable/sign_up_btn_bg / @color/login_btn)
  factory AppButton.lime({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    bool isLoading = false,
    String? loadingText,
    Widget? icon,
    double height = 46,
    double? width,
    double borderRadius = 4,
    TextStyle? textStyle,
  }) {
    return AppButton(
      key: key,
      text: text,
      onPressed: onPressed,
      variant: AppButtonVariant.lime,
      isLoading: isLoading,
      loadingText: loadingText,
      icon: icon,
      height: height,
      width: width,
      borderRadius: borderRadius,
      textStyle: textStyle,
    );
  }

  /// Outlined button with customizable border/accent color
  factory AppButton.outline({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    bool isLoading = false,
    Widget? icon,
    double height = 44,
    double? width,
    double borderRadius = 8,
    Color? color,
    Color? borderColor,
    TextStyle? textStyle,
  }) {
    return AppButton(
      key: key,
      text: text,
      onPressed: onPressed,
      variant: AppButtonVariant.outline,
      isLoading: isLoading,
      icon: icon,
      height: height,
      width: width,
      borderRadius: borderRadius,
      foregroundColor: color,
      borderColor: borderColor,
      textStyle: textStyle,
    );
  }

  /// Danger/Destructive button (e.g., logout, cancel)
  factory AppButton.danger({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    bool isLoading = false,
    Widget? icon,
    double height = 44,
    double? width,
    double borderRadius = 8,
    TextStyle? textStyle,
  }) {
    return AppButton(
      key: key,
      text: text,
      onPressed: onPressed,
      variant: AppButtonVariant.danger,
      isLoading: isLoading,
      icon: icon,
      height: height,
      width: width,
      borderRadius: borderRadius,
      textStyle: textStyle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveEnabled = !isLoading && onPressed != null;

    Color bg;
    Color fg;
    Color? resolvedBorderColor;

    switch (variant) {
      case AppButtonVariant.primary:
        bg = backgroundColor ?? AppColors.brandBlue;
        fg = foregroundColor ?? Colors.white;
        resolvedBorderColor = borderColor;
        break;
      case AppButtonVariant.lime:
        bg = backgroundColor ?? AppColors.brandLime;
        fg = foregroundColor ?? Colors.white;
        resolvedBorderColor = borderColor;
        break;
      case AppButtonVariant.outline:
        bg = backgroundColor ?? Colors.transparent;
        fg = foregroundColor ?? AppColors.primary;
        resolvedBorderColor = borderColor ?? foregroundColor ?? AppColors.primary;
        break;
      case AppButtonVariant.danger:
        bg = backgroundColor ?? AppColors.error;
        fg = foregroundColor ?? Colors.white;
        resolvedBorderColor = borderColor;
        break;
    }

    final effectiveTextStyle = TextStyle(
      fontFamily: AppFonts.nunito,
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: fg,
    ).merge(textStyle);

    Widget content;
    if (isLoading) {
      if (loadingText != null && loadingText!.isNotEmpty) {
        content = Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LoadingIndicator(size: 18, color: fg, strokeWidth: 2),
            const SizedBox(width: 10),
            Text(loadingText!, style: effectiveTextStyle),
          ],
        );
      } else {
        content = LoadingIndicator(size: 20, color: fg, strokeWidth: 2);
      }
    } else if (icon != null) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon!,
          const SizedBox(width: 8),
          Text(text, style: effectiveTextStyle),
        ],
      );
    } else {
      content = Text(text, style: effectiveTextStyle, textAlign: TextAlign.center);
    }

    final buttonWidget = ElevatedButton(
      onPressed: effectiveEnabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        disabledBackgroundColor: bg.withValues(alpha: 0.7),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: resolvedBorderColor != null
              ? BorderSide(color: resolvedBorderColor, width: 1)
              : BorderSide.none,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      child: content,
    );

    return SizedBox(
      height: height,
      width: width ?? double.infinity,
      child: buttonWidget,
    );
  }
}

/// Reusable pill-shaped action button with fully rounded curved stadium design.
class PillActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color textColor;
  final FontWeight fontWeight;
  final double height;
  final EdgeInsetsGeometry padding;
  final double fontSize;

  const PillActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.backgroundColor,
    this.textColor = Colors.white,
    this.fontWeight = FontWeight.w600,
    this.height = 32.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 14),
    this.fontSize = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: TextButton(
        style: TextButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          padding: padding,
          shape: const StadiumBorder(),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
