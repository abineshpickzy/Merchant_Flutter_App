import 'package:flutter/material.dart';
import 'package:bayfay_merchant_flutter/app/theme/app_colors.dart';
import 'package:bayfay_merchant_flutter/core/constants/app_constants.dart';
import 'package:bayfay_merchant_flutter/core/constants/app_strings.dart';
import 'package:bayfay_merchant_flutter/core/widgets/app_button.dart';

/// Clean dialog shown when a required permission is permanently denied.
/// Provides a direct action button to open device app settings.
class PermissionPermanentlyDeniedDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onOpenSettings;
  final VoidCallback? onCancel;

  const PermissionPermanentlyDeniedDialog({
    super.key,
    this.title = AppStrings.permissionPermanentlyDeniedTitle,
    this.message = AppStrings.permissionPermanentlyDeniedSubtitle,
    required this.onOpenSettings,
    this.onCancel,
  });

  /// Displays the dialog modally.
  static Future<void> show(
    BuildContext context, {
    String title = AppStrings.permissionPermanentlyDeniedTitle,
    String message = AppStrings.permissionPermanentlyDeniedSubtitle,
    required VoidCallback onOpenSettings,
    VoidCallback? onCancel,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => PermissionPermanentlyDeniedDialog(
        title: title,
        message: message,
        onOpenSettings: () {
          Navigator.of(ctx).pop();
          onOpenSettings();
        },
        onCancel: () {
          Navigator.of(ctx).pop();
          onCancel?.call();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.settings_suggest_outlined,
                color: Colors.amber.shade800,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: AppFonts.nunito,
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.brandInputText,
              ),
            ),
            const SizedBox(height: 8),

            // Description
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: AppFonts.productSans,
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 24),

            // Action: Open App Settings
            AppButton.primary(
              text: AppStrings.openAppSettingsAction,
              height: 46,
              borderRadius: 8,
              onPressed: onOpenSettings,
            ),

            if (onCancel != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: onCancel,
                child: const Text(
                  AppStrings.cancel,
                  style: TextStyle(
                    fontFamily: AppFonts.nunito,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
