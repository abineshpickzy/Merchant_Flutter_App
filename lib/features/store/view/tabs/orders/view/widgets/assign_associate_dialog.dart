import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:bayfay_merchant_flutter/app/theme/app_colors.dart';
import 'package:bayfay_merchant_flutter/core/widgets/widgets.dart';
import '../../controller/orders_controller.dart';
import '../../model/order_model.dart';

/// Modal dialog for manually assigning / reassigning a delivery assistant or enabling Auto-Assign queue
/// Matches Android assign_order_alert.xml
class AssignAssociateDialog extends ConsumerStatefulWidget {
  final OrderModel order;
  final String shopId;
  final String categoryId;
  final OrderStatus currentStatus;

  const AssignAssociateDialog({
    super.key,
    required this.order,
    required this.shopId,
    required this.categoryId,
    this.currentStatus = OrderStatus.processing,
  });

  static Future<bool?> show(
    BuildContext context, {
    required OrderModel order,
    required String shopId,
    required String categoryId,
    OrderStatus currentStatus = OrderStatus.processing,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AssignAssociateDialog(
        order: order,
        shopId: shopId,
        categoryId: categoryId,
        currentStatus: currentStatus,
      ),
    );
  }

  @override
  ConsumerState<AssignAssociateDialog> createState() =>
      _AssignAssociateDialogState();
}

class _AssignAssociateDialogState extends ConsumerState<AssignAssociateDialog> {
  String? _selectedAssistantId;
  bool _autoAssign = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedAssistantId = widget.order.assistantInfo?.assistantId;
  }

  Future<void> _handleAssign(String expectedTime) async {
    if (!_autoAssign &&
        (_selectedAssistantId == null || _selectedAssistantId!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a delivery assistant or enable Auto Assign',
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final OrderActionResult res;
    if (_autoAssign) {
      res = await ref
          .read(orderActionControllerProvider.notifier)
          .autoAssignOrder(
            shopId: widget.shopId,
            categoryId: widget.categoryId,
            orderId: widget.order.id,
            expectedDeliveryTime: expectedTime,
            currentStatus: widget.currentStatus,
          );
    } else {
      res = await ref
          .read(orderActionControllerProvider.notifier)
          .assignAssistant(
            shopId: widget.shopId,
            categoryId: widget.categoryId,
            orderId: widget.order.id,
            assistantId: _selectedAssistantId!,
            currentStatus: widget.currentStatus,
          );
    }

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (res.success) {
        AppSnackBar.showSuccess(
          context,
          res.message.isNotEmpty
              ? res.message
              : (_autoAssign
                  ? 'Order added to delivery queue'
                  : 'Delivery associate assigned'),
        );
        Navigator.of(context).pop(true);
      } else {
        AppSnackBar.showError(
          context,
          res.message.isNotEmpty ? res.message : 'Failed to assign assistant',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final expectedTime = widget.order.expectedTime.isNotEmpty
        ? widget.order.expectedTime
        : DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: Colors.white,
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Toolbar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFFF7F8FA),
                border: Border(bottom: BorderSide(color: AppColors.divider)),
              ),
              child: Row(
                children: [
                  const Text(
                    'Assign Delivery Assistant',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black87),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
            ),

            // Auto-assign Checkbox
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: CheckboxListTile(
                value: _autoAssign,
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text(
                  'Auto Assign Delivery Associate (Queue)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                onChanged: (v) {
                  setState(() {
                    _autoAssign = v ?? false;
                    if (_autoAssign) {
                      _selectedAssistantId = null;
                    }
                  });
                },
              ),
            ),

            const Divider(height: 1, color: AppColors.divider),

            // Associates list
            Expanded(
              child: Consumer(
                builder: (context, ref, _) {
                  final assistantsAsync = ref.watch(
                    activeDeliveryAssistantsProvider((
                      orderId: widget.order.id,
                      expectedDeliveryTime: expectedTime,
                    )),
                  );

                  return assistantsAsync.when(
                    loading: () => const Center(
                      child: LoadingIndicator(size: 32),
                    ),
                    error: (_, _) => _buildNoAssociates(),
                    data: (assistants) {
                      if (assistants.isEmpty) {
                        return _buildNoAssociates();
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.all(14),
                        itemCount: assistants.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final assistant = assistants[index];
                          final isSelected =
                              !_autoAssign && _selectedAssistantId == assistant.id;

                          return InkWell(
                            onTap: () => setState(() {
                              _autoAssign = false;
                              _selectedAssistantId = assistant.id;
                            }),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primaryLight
                                        .withValues(alpha: 0.25)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.border,
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Radio<String>(
                                    value: assistant.id,
                                    groupValue:
                                        _autoAssign ? null : _selectedAssistantId,
                                    activeColor: AppColors.primary,
                                    onChanged: (val) => setState(() {
                                      _autoAssign = false;
                                      _selectedAssistantId = val;
                                    }),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          assistant.fullName,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${assistant.distance.toStringAsFixed(2)} km from Shop | ${assistant.orders} active orders',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: assistant.isInService
                                          ? AppColors.success
                                              .withValues(alpha: 0.15)
                                          : AppColors.error
                                              .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      assistant.isInService
                                          ? 'In Service'
                                          : 'Idle',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: assistant.isInService
                                            ? AppColors.success
                                            : AppColors.error,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),

            // Bottom Buttons
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: Color(0xFFFAFAFA),
                border: Border(top: BorderSide(color: AppColors.divider)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: AppButton.outline(
                      onPressed: () => Navigator.of(context).pop(false),
                      text: 'Close',
                      color: AppColors.textSecondary,
                      borderColor: AppColors.border,
                      height: 40,
                      borderRadius: 8,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton.primary(
                      onPressed: _isSubmitting
                          ? null
                          : () => _handleAssign(expectedTime),
                      text: _isSubmitting ? 'Saving...' : 'Save',
                      height: 40,
                      borderRadius: 8,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoAssociates() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.delivery_dining_outlined,
              size: 40,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 8),
            const Text(
              'Currently No Delivery Associate Available',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
