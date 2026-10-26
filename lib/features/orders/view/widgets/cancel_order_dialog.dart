import 'package:flutter/material.dart';
import 'package:bayfay_merchant_flutter/app/theme/app_colors.dart';
import 'package:bayfay_merchant_flutter/core/constants/app_strings.dart';

import 'package:bayfay_merchant_flutter/core/widgets/widgets.dart';

/// Modal dialog allowing the merchant to select or specify an order cancellation reason.
class CancelOrderDialog extends StatefulWidget {
  final String orderId;

  const CancelOrderDialog({super.key, required this.orderId});

  static Future<String?> show(BuildContext context, {required String orderId}) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CancelOrderDialog(orderId: orderId),
    );
  }

  @override
  State<CancelOrderDialog> createState() => _CancelOrderDialogState();
}

class _CancelOrderDialogState extends State<CancelOrderDialog> {
  final List<String> _reasons = [
    AppStrings.cancelReasonOutOfStock,
    AppStrings.cancelReasonStoreBusy,
    AppStrings.cancelReasonCustomerRequest,
    AppStrings.cancelReasonOther,
  ];

  late String _selectedReason;
  final TextEditingController _customReasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedReason = _reasons.first;
  }

  @override
  void dispose() {
    _customReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOther = _selectedReason == AppStrings.cancelReasonOther;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      title: Row(
        children: [
          const Icon(Icons.cancel_outlined, color: AppColors.error, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${AppStrings.cancelOrderAction} ${widget.orderId}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              AppStrings.cancelReasonPrompt,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            ...List.generate(_reasons.length, (index) {
              final reason = _reasons[index];
              return RadioListTile<String>(
                value: reason,
                groupValue: _selectedReason,
                contentPadding: EdgeInsets.zero,
                dense: true,
                activeColor: AppColors.primary,
                title: Text(
                  reason,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedReason = val);
                  }
                },
              );
            }),
            if (isOther) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _customReasonController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: AppStrings.describeCancelReason,
                  hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text(
            AppStrings.keepOrder,
            style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
          ),
        ),
        AppButton.danger(
          text: AppStrings.confirmCancel,
          width: 140,
          height: 40,
          borderRadius: 8,
          onPressed: () {
            String finalReason = _selectedReason;
            if (isOther && _customReasonController.text.trim().isNotEmpty) {
              finalReason = _customReasonController.text.trim();
            }
            Navigator.of(context).pop(finalReason);
          },
        ),
      ],
    );
  }
}
