import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayfay_merchant_flutter/core/widgets/widgets.dart';
import '../../controller/orders_controller.dart';
import '../../model/order_model.dart';
import '../widgets/accept_order_dialog.dart';
import '../widgets/cancel_order_dialog.dart';
import '../widgets/customer_info_dialogs.dart';
import '../widgets/order_card_parts.dart';
import 'new_order_details_screen.dart';

const _kPrefBgYellow = Color(0xFFFFF785);
const _kPrefBorderOrange = Color(0xFFFF9800);
const _kPrefBgRed = Color(0xFFFEC4C2);
const _kPrefBorderRed = Color(0xFFF44336);
const _kPrefBgGreen = Color(0xFFE1F8D9);
const _kPrefBorderGreen = Color(0xFF1D800E);
const _kViolet = Color(0xFF673AB7);

/// Card for the New Orders tab (single_new_order.xml in the old app).
class NewOrderCard extends ConsumerWidget {
  final OrderModel order;
  final String shopId;
  final String categoryId;

  const NewOrderCard({
    super.key,
    required this.order,
    required this.shopId,
    required this.categoryId,
  });

  ({Color bg, Color border}) _prefColors() {
    if (order.isSelfPickup) {
      return (bg: _kPrefBgGreen, border: _kPrefBorderGreen);
    }
    if (order.preferredTime.toLowerCase().contains('mins') ||
        order.preferredTime.toLowerCase().contains('immediate')) {
      return (bg: _kPrefBgRed, border: _kPrefBorderRed);
    }
    return (bg: _kPrefBgYellow, border: _kPrefBorderOrange);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = _prefColors();
    final isOnline = order.paymentType.toLowerCase().contains('online');

    return OrderCardFrame(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => NewOrderDetailsScreen(
              order: order,
              shopId: shopId,
              categoryId: categoryId,
            ),
          ),
        );
      },
      children: [
        OrderCardTopRow(order: order),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OrderAvatar(order: order),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Text(
                    order.customerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontFamily: 'Nunito',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Flexible(child: OrderIdLabel(order: order)),
                      if (!order.hasEscalation) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 1,
                          height: 22,
                          color: kOrderCardBorder,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '\u20B9${order.amount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            fontFamily: 'ProductSans',
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (order.tipAmount > 0) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Delivery Tip : \u20B9${order.tipAmount}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFE57373),
                        fontFamily: 'ProductSans',
                      ),
                    ),
                  ],
                  if (order.isSelfPickup ||
                      order.preferredTime.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _buildPreferredBox(colors),
                  ],
                  const SizedBox(height: 10),
                  OrderStatusText(
                    label: order.hasEscalation
                        ? 'Replacement/Undelivered'
                        : 'New Order',
                    color: order.hasEscalation ? kOrderRed : kOrderGreen,
                  ),
                  if (order.contactLessDelivery) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDE7F6),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: _kViolet.withValues(alpha: 0.4),
                        ),
                      ),
                      child: const Text(
                        'Contact Less Delivery',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _kViolet,
                          fontFamily: 'ProductSans',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 2, top: 16),
              child: Icon(
                Icons.chevron_right,
                size: 20,
                color: Colors.black.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        if (order.hasEscalation)
          OrderButtonsRow(
            children: [
              if (isOnline)
                OrderRefundButton(
                  label: 'Refund',
                  onTap: () {
                    CustomerInfoDialogs.showRefundDialog(
                      context,
                      refundAmount: order.amount,
                      onConfirm: (initiateAfterReturn) async {
                        final res = await ref
                            .read(orderActionControllerProvider.notifier)
                            .refundOrder(
                              shopId: shopId,
                              categoryId: categoryId,
                              orderId: order.id,
                              isRequest: initiateAfterReturn,
                            );
                        if (context.mounted) {
                          if (res.success) {
                            AppSnackBar.showSuccess(
                              context,
                              res.message.isNotEmpty
                                  ? res.message
                                  : 'Refund processed successfully',
                            );
                          } else {
                            AppSnackBar.showError(
                              context,
                              res.message.isNotEmpty
                                  ? res.message
                                  : 'Failed to process refund',
                            );
                          }
                        }
                        return res.success;
                      },
                    );
                  },
                ),
              OrderOutlineButton(
                label: 'Escalate',
                onTap: () {
                  CustomerInfoDialogs.showEscalateWholeOrderDialog(
                    context,
                    onConfirm: () async {
                      final res = await ref
                          .read(orderActionControllerProvider.notifier)
                          .escalateOrder(
                            shopId: shopId,
                            categoryId: categoryId,
                            orderId: order.id,
                          );
                      if (context.mounted) {
                        if (res.success) {
                          AppSnackBar.showSuccess(
                            context,
                            res.message.isNotEmpty
                                ? res.message
                                : 'Order escalated successfully',
                          );
                        } else {
                          AppSnackBar.showError(
                            context,
                            res.message.isNotEmpty
                                ? res.message
                                : 'Failed to escalate order',
                          );
                        }
                      }
                      return res.success;
                    },
                  );
                },
              ),
              OrderSolidButton(
                label: 'Accept',
                onTap: () => AcceptOrderDialog.show(
                  context,
                  order: order,
                  shopId: shopId,
                  categoryId: categoryId,
                ),
              ),
            ],
          )
        else
          OrderButtonsRow(
            children: [
              OrderOutlineButton(
                label: 'Cancel',
                onTap: () => CancelOrderDialog.show(
                  context,
                  order: order,
                  shopId: shopId,
                  categoryId: categoryId,
                  currentStatus: order.status,
                ),
              ),
              OrderSolidButton(
                label: 'Accept',
                onTap: () => AcceptOrderDialog.show(
                  context,
                  order: order,
                  shopId: shopId,
                  categoryId: categoryId,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildPreferredBox(({Color bg, Color border}) colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: colors.border, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Delivery Preferred:',
            style: TextStyle(
              fontSize: 13,
              color: Colors.black,
              fontFamily: 'ProductSans',
            ),
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  order.preferredTime.isNotEmpty ? order.preferredTime : '30 to 55 mins',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontFamily: 'ProductSans',
                  ),
                ),
                if (order.isSelfPickup)
                  const Text(
                    '(Self pickup)',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE53935),
                      fontFamily: 'Nunito',
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
