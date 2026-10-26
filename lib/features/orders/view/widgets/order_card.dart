import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayfay_merchant_flutter/app/theme/app_colors.dart';
import 'package:bayfay_merchant_flutter/core/constants/app_strings.dart';
import 'package:bayfay_merchant_flutter/core/widgets/widgets.dart';
import '../../controller/orders_controller.dart';
import '../../model/order_model.dart';
import 'cancel_order_dialog.dart';
import 'order_details_modal.dart';

/// Card widget representing a single merchant order with customer metadata,
/// price breakdown, and contextual actions (Accept, Cancel, Ready, View Details).
class OrderCard extends ConsumerStatefulWidget {
  final OrderModel order;
  final String shopId;
  final String categoryId;

  const OrderCard({
    super.key,
    required this.order,
    required this.shopId,
    required this.categoryId,
  });

  @override
  ConsumerState<OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends ConsumerState<OrderCard> {
  bool _isActionInProgress = false;

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.newOrder:
        return AppColors.info;
      case OrderStatus.processing:
        return AppColors.warning;
      case OrderStatus.ready:
        return AppColors.primary;
      case OrderStatus.onTheWay:
        return Colors.deepPurple;
      case OrderStatus.delivered:
        return AppColors.success;
      case OrderStatus.cancelled:
        return AppColors.error;
      case OrderStatus.replaceRefund:
        return AppColors.warning;
    }
  }

    Future<void> _handleAccept() async {
    if (_isActionInProgress) return;

    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
    );
    if (time == null || !mounted) return;

    final expected = DateTime(date.year, date.month, date.day, time.hour, time.minute);

    setState(() => _isActionInProgress = true);

    final success = await ref
        .read(orderActionControllerProvider.notifier)
        .acceptOrder(
          shopId: widget.shopId,
          categoryId: widget.categoryId,
          orderId: widget.order.id,
          expectedTime: expected.toUtc().toIso8601String(),
        );

    if (mounted) {
      setState(() => _isActionInProgress = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? AppStrings.orderAcceptedSuccess
                : AppStrings.failedToAcceptOrder,
          ),
          backgroundColor: success ? AppColors.success : AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleCancel() async {
    if (_isActionInProgress) return;

    final reason = await CancelOrderDialog.show(
      context,
      orderId: widget.order.orderId,
    );

    if (reason != null && mounted) {
      setState(() => _isActionInProgress = true);
      final success = await ref
          .read(orderActionControllerProvider.notifier)
          .cancelOrder(
            shopId: widget.shopId,
            orderId: widget.order.id,
            reason: reason,
            categoryId: widget.categoryId,
          );

      if (mounted) {
        setState(() => _isActionInProgress = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? AppStrings.orderCancelledSuccess
                  : AppStrings.failedToCancelOrder,
            ),
            backgroundColor: success ? AppColors.success : AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleMarkReady() async {
    if (_isActionInProgress) return;
    setState(() => _isActionInProgress = true);

    final success = await ref
        .read(orderActionControllerProvider.notifier)
        .markReadyToShip(
          shopId: widget.shopId,
          orderId: widget.order.id,
          categoryId: widget.categoryId,
        );

    if (mounted) {
      setState(() => _isActionInProgress = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? AppStrings.orderReadySuccess : AppStrings.failedToUpdateOrder,
          ),
          backgroundColor: success ? AppColors.success : AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(widget.order.status);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.border.withValues(alpha: 0.8)),
      ),
      child: InkWell(
        onTap: () => OrderDetailsModal.show(context, widget.order, widget.shopId, widget.categoryId),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Row: Order ID, Status Pill, Timestamp
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.receipt_long, color: statusColor, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.order.orderId,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            widget.order.orderedAt,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.order.status.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Divider(color: AppColors.divider, height: 1),
              ),

              // 2. Customer & Address Details
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.background,
                    child: const Icon(Icons.person_outline, color: AppColors.textSecondary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.order.customerName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (widget.order.customerMobile.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2.0),
                            child: Row(
                              children: [
                                const Icon(Icons.phone_outlined, size: 13, color: AppColors.textMuted),
                                const SizedBox(width: 4),
                                Text(
                                  widget.order.customerMobile,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textMuted),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                widget.order.customerAddress,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 3. Meta Badges: Delivery Mode & Payment Mode
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.border, width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.delivery_dining_outlined, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          widget.order.deliveryType,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.border, width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.payment_outlined, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          widget.order.paymentType,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Amount
                  Text(
                    '₹${widget.order.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),

              // 4. Action Buttons based on status
              if (_buildActions(context) != null) ...[
                const SizedBox(height: 14),
                _buildActions(context)!,
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget? _buildActions(BuildContext context) {
    if (_isActionInProgress) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: LoadingIndicator(size: 24, strokeWidth: 2.5),
        ),
      );
    }

    switch (widget.order.status) {
      case OrderStatus.newOrder:
        return Row(
          children: [
            Expanded(
              child: AppButton.outline(
                onPressed: _handleCancel,
                text: AppStrings.cancelOrderAction,
                color: AppColors.error,
                height: 40,
                borderRadius: 10,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppButton.primary(
                onPressed: _handleAccept,
                text: AppStrings.acceptOrderAction,
                height: 40,
                borderRadius: 10,
              ),
            ),
          ],
        );

      case OrderStatus.processing:
        return Row(
          children: [
            Expanded(
              child: AppButton.outline(
                onPressed: _handleCancel,
                text: AppStrings.cancelOrderAction,
                color: AppColors.error,
                height: 40,
                borderRadius: 10,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppButton(
                onPressed: _handleMarkReady,
                text: AppStrings.markReadyAction,
                backgroundColor: AppColors.warning,
                height: 40,
                borderRadius: 10,
              ),
            ),
          ],
        );

      case OrderStatus.ready:
      case OrderStatus.onTheWay:
      case OrderStatus.delivered:
      case OrderStatus.replaceRefund:
      case OrderStatus.cancelled:
        return Row(
          children: [
            Expanded(
              child: AppButton.outline(
                onPressed: () =>OrderDetailsModal.show(context, widget.order, widget.shopId, widget.categoryId),
                icon: const Icon(Icons.visibility_outlined, size: 16),
                text: AppStrings.viewOrderDetails,
                color: AppColors.textPrimary,
                borderColor: AppColors.border,
                height: 40,
                borderRadius: 10,
              ),
            ),
          ],
        );
    }
  }
}
