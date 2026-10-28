import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayfay_merchant_flutter/app/theme/app_colors.dart';
import 'package:bayfay_merchant_flutter/core/widgets/widgets.dart';
import '../../controller/orders_controller.dart';
import '../../model/order_model.dart';

/// Modal dialog allowing the merchant to select or specify an order cancellation reason.
/// Strictly connects to backend cancel reasons and ApiService.callOrderCancelNewApi
class CancelOrderDialog extends ConsumerStatefulWidget {
  final OrderModel order;
  final String shopId;
  final String categoryId;
  final OrderStatus currentStatus;

  const CancelOrderDialog({
    super.key,
    required this.order,
    required this.shopId,
    required this.categoryId,
    this.currentStatus = OrderStatus.newOrder,
  });

  static Future<bool?> show(
    BuildContext context, {
    required OrderModel order,
    required String shopId,
    required String categoryId,
    OrderStatus currentStatus = OrderStatus.newOrder,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CancelOrderDialog(
        order: order,
        shopId: shopId,
        categoryId: categoryId,
        currentStatus: currentStatus,
      ),
    );
  }

  @override
  ConsumerState<CancelOrderDialog> createState() => _CancelOrderDialogState();
}

class _CancelOrderDialogState extends ConsumerState<CancelOrderDialog> {
  static const List<String> _defaultReasons = [
    'Out of stock',
    'Store is currently busy',
    'Customer requested cancellation',
    'Unable to deliver to customer location',
    'Other reason',
  ];

  late String _selectedReason;
  final TextEditingController _customReasonController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedReason = _defaultReasons.first;
  }

  @override
  void dispose() {
    _customReasonController.dispose();
    super.dispose();
  }

  Future<void> _handleConfirm() async {
    if (_isSubmitting) return;

    final reason = _selectedReason;
    final message = _customReasonController.text.trim();

    setState(() => _isSubmitting = true);

    final res = await ref
        .read(orderActionControllerProvider.notifier)
        .cancelOrder(
          shopId: widget.shopId,
          categoryId: widget.categoryId,
          orderId: widget.order.orderId.isNotEmpty
              ? widget.order.orderId
              : widget.order.id,
          reason: reason,
          message: message,
          currentStatus: widget.currentStatus,
        );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (res.success) {
        AppSnackBar.showSuccess(
          context,
          res.message.isNotEmpty ? res.message : 'Order cancelled successfully',
        );
        Navigator.of(context).pop(true);
      } else {
        AppSnackBar.showError(
          context,
          res.message.isNotEmpty ? res.message : 'Failed to cancel order',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reasonsAsync = ref.watch(cancelReasonsProvider);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      title: const Text(
        'Are you sure you want to cancel this order?',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            reasonsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(12.0),
                  child: LoadingIndicator(size: 24),
                ),
              ),
              error: (_, __) => _buildReasonsList(_defaultReasons),
              data: (apiReasons) {
                final list = apiReasons.isNotEmpty
                    ? apiReasons.map((e) => e.title).toList()
                    : _defaultReasons;
                return _buildReasonsList(list);
              },
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _customReasonController,
              minLines: 3,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Enter your Reason here.',
                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9E9E9E)),
                contentPadding: const EdgeInsets.all(10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: Color(0xFFD1D1D1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: Color(0xFFD1D1D1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: Color(0xFF0275D8)),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                minimumSize: const Size(80, 32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2),
                  side: const BorderSide(color: Color(0xFF0275D8)),
                ),
              ),
              child: const Text(
                'Close',
                style: TextStyle(
                  color: Color(0xFF0275D8),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 10),
            TextButton(
              onPressed: _isSubmitting ? null : _handleConfirm,
              style: TextButton.styleFrom(
                minimumSize: const Size(100, 32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2),
                  side: const BorderSide(color: Color(0xFFF44336)),
                ),
              ),
              child: Text(
                _isSubmitting ? 'Cancelling...' : 'Cancel Order',
                style: const TextStyle(
                  color: Color(0xFFF44336),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReasonsList(List<String> reasons) {
    if (!reasons.contains(_selectedReason) && reasons.isNotEmpty) {
      _selectedReason = reasons.first;
    }

    return Column(
      children: reasons.map((reason) {
        return RadioListTile<String>(
          value: reason,
          groupValue: _selectedReason,
          contentPadding: EdgeInsets.zero,
          dense: true,
          activeColor: AppColors.error,
          title: Text(
            reason,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          onChanged: (val) {
            if (val != null) {
              setState(() => _selectedReason = val);
            }
          },
        );
      }).toList(),
    );
  }
}
