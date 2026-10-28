import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayfay_merchant_flutter/core/widgets/widgets.dart';
import '../../controller/orders_controller.dart';
import '../../model/order_model.dart';
import '../replacement/replacement_reason_screen.dart';
import '../widgets/accept_order_dialog.dart';
import '../widgets/cancel_order_dialog.dart';
import '../widgets/customer_info_dialogs.dart';
import '../widgets/order_card_parts.dart';
import '../widgets/order_product_info_screen.dart';

/// New Order Details Screen matching Android OrderDetailFragment (order_details_fragment.xml + NewOrderDetailsAdapter.java)
class NewOrderDetailsScreen extends ConsumerWidget {
  final OrderModel order;
  final String shopId;
  final String categoryId;

  const NewOrderDetailsScreen({
    super.key,
    required this.order,
    required this.shopId,
    required this.categoryId,
  });

  bool get _hasNoteOrAttachment => order.hasCustomerNotes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsArg = (
      orderId: order.id,
      shopId: shopId,
      categoryId: categoryId,
      isEscalated: order.hasEscalation,
    );
    final productsAsync = ref.watch(orderProductsProvider(productsArg));
    final isOnline = order.paymentType.toLowerCase().contains('online');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor: const Color(0xFFF5F5F5),
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF333333)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            order.hasEscalation ? 'Replacement/Undelivered' : order.orderId,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Top Order Summary Card (order_details_fragment.xml lines 41-225)
          Container(
            margin: const EdgeInsets.fromLTRB(10, 5, 10, 0),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: const Color(0xFFDADADA), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OrderAvatar(order: order),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 8,
                        children: [
                          Text(
                            order.customerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                         
                          OrderIdLabel(order: order),
                         
                          // Delivery Method + | + Tip on same row (order_details_fragment.xml lines 102-123)
                          Row(
                            children: [
                              Flexible(
                                child: RichText(
                                  text: TextSpan(
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black,
                                    ),
                                    children: [
                                      const TextSpan(
                                        text: 'Delivery Method : ',
                                      ),
                                      TextSpan(
                                        text: order.deliveryType,
                                        style: const TextStyle(
                                          color: Color(0xFF4BA7EE),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (order.tipAmount > 0) ...[
                                Container(
                                  width: 1,
                                  height: 15,
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 6),
                                  color: const Color(0xFFE0E0E0),
                                ),
                                Text(
                                  'Tip : \u20B9${order.tipAmount}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ],
                          ),
                         
                          // CP Delivery time in #4BA7EE (OrderDetailFragment.java line 258)
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black,
                              ),
                              children: [
                                const TextSpan(text: 'CP Delivery time : '),
                                TextSpan(
                                  text: order.preferredTime.isNotEmpty
                                      ? order.preferredTime
                                      : 'Immediate',
                                  style: const TextStyle(
                                    color: Color(0xFF4BA7EE),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!order.hasEscalation) ...[
                           
                            Text(
                              'Total purchased amount : \u20B9${order.amount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black,
                              ),
                            ),
                          ],
                         
                          Text(
                            'Payment Status : ${order.paymentType}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!order.isSelfPickup)
                      OrderDistanceIndicator(distance: order.distance),
                  ],
                ),
                const SizedBox(height: 10),
                // Action Buttons Row (Refund / Cancel or Escalate / Accept / Note)
                Row(
                  children: [
                    if (order.hasEscalation && isOnline) ...[
                      Expanded(
                        child: _DetailActionBtn(
                          label: 'Refund',
                          backgroundColor: const Color(0xFFEE0000),
                          textColor: Colors.white,
                          borderColor: const Color(0xFFEE0000),
                          onTap: () {
                            final prods = productsAsync.valueOrNull ?? const [];
                            double refundTotal = order.amount;
                            if (prods.isNotEmpty) {
                              refundTotal = prods.fold(
                                0.0,
                                (sum, p) => sum + p.escalatedTotalPrice,
                              );
                            }
                            CustomerInfoDialogs.showRefundDialog(
                              context,
                              refundAmount: refundTotal,
                              onConfirm: (initiateAfterReturn) async {
                                final res = await ref
                                    .read(
                                        orderActionControllerProvider.notifier)
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
                                    Navigator.of(context).pop(true);
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
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: _DetailActionBtn(
                        label: order.hasEscalation ? 'Escalate' : 'Cancel',
                        onTap: () async {
                          if (order.hasEscalation) {
                            CustomerInfoDialogs.showEscalateWholeOrderDialog(
                              context,
                              onConfirm: () async {
                                final res = await ref
                                    .read(
                                        orderActionControllerProvider.notifier)
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
                                    Navigator.of(context).pop(true);
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
                          } else {
                            final cancelled = await showDialog<bool>(
                              context: context,
                              builder: (_) => CancelOrderDialog(
                                order: order,
                                shopId: shopId,
                                categoryId: categoryId,
                              ),
                            );
                            if (cancelled == true && context.mounted) {
                              Navigator.of(context).pop(true);
                            }
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _DetailActionBtn(
                        label: 'Accept',
                        backgroundColor: const Color(0xFF0275D8),
                        textColor: Colors.white,
                        borderColor: const Color(0xFF0275D8),
                        onTap: () async {
                          final accepted = await showDialog<bool>(
                            context: context,
                            builder: (_) => AcceptOrderDialog(
                              order: order,
                              shopId: shopId,
                              categoryId: categoryId,
                            ),
                          );
                          if (accepted == true && context.mounted) {
                            ref.read(orderStatusTabProvider.notifier).state =
                                OrderStatus.processing;
                            Navigator.of(context).pop(true);
                          }
                        },
                      ),
                    ),
                    if (_hasNoteOrAttachment) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: _DetailActionBtn(
                          label: 'Note',
                          onTap: () =>
                              CustomerInfoDialogs.showNotes(context, order),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Product Details Card (order_details_fragment.xml lines 229-266)
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(10, 5, 10, 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: const Color(0xFFDADADA), width: 1),
              ),
              child: productsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(
                  child: Text(
                    'Failed to load products: $err',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
                data: (products) {
                  // OrderDetailFragment.java lines 435-447: sum of escalatedQty (when escalated) or qty
                  final totalProductsCount = products.fold<int>(
                    0,
                    (sum, p) =>
                        sum +
                        (order.hasEscalation && p.escalatedQty > 0
                            ? p.escalatedQty
                            : p.quantity),
                  );

                  return Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Product Details',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            'Total Products : $totalProductsCount',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.separated(
                          itemCount: products.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final p = products[index];
                            return _NewOrderProductTile(
                              order: order,
                              product: p,
                              shopId: shopId,
                              categoryId: categoryId,
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailActionBtn extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;
  final VoidCallback onTap;

  const _DetailActionBtn({
    required this.label,
    this.backgroundColor = Colors.white,
    this.textColor = Colors.black,
    this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: borderColor ?? Colors.grey.shade400),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

/// Product item row matching Android NewOrderDetailsAdapter (adapter_new_order_fagment1.xml)
class _NewOrderProductTile extends ConsumerWidget {
  final OrderModel order;
  final OrderProductItem product;
  final String shopId;
  final String categoryId;

  const _NewOrderProductTile({
    required this.order,
    required this.product,
    required this.shopId,
    required this.categoryId,
  });

  /// Escalation status label, color, and Reason visibility matching NewOrderDetailsAdapter.java lines 92-155
  ({String label, Color color, bool showReason}) _escalationInfo() {
    const red = Color(0xFFF23B3B);
    const green = Color(0xFF63C900);

    switch (product.escalationStatus) {
      case 1: // ESCALATION_CLIENT
        if (product.verifyStatus == 2) {
          return (label: 'Undelivered', color: red, showReason: true);
        }
        if (product.verifyStatus == 3) {
          return (label: 'Replacement', color: red, showReason: true);
        }
        return (label: '', color: red, showReason: true);
      case 2: // ESCALATION_MERCHANT
        return (label: 'Escalated', color: red, showReason: true);
      case 3: // ESCALATION_ACCEPTED_CLIENT
        return (label: 'Closed', color: green, showReason: false);
      case 4: // ESCALATION_ACCEPTED_MERCHANT
        return (label: 'Accepted', color: green, showReason: true);
      case 5: // ESCALATION_REFUND_REQUEST
        return (label: 'Refund request', color: red, showReason: false);
      case 6: // ESCALATION_REFUND_INITIATE
        return (label: 'Refund initiate', color: red, showReason: false);
      case 7: // ESCALATION_CLOSE
        return (label: 'Closed', color: red, showReason: false);
      case 8: // ESCALATION_TEMPLATE_ACCEPT
        return (label: 'Closed', color: green, showReason: false);
      default:
        if (product.verifyStatus == 2) {
          return (label: 'Undelivered', color: red, showReason: true);
        }
        if (product.verifyStatus == 3) {
          return (label: 'Replacement', color: red, showReason: true);
        }
        return (label: '', color: red, showReason: false);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qtyDisplay =
        order.hasEscalation && product.escalatedQty > 0
            ? product.escalatedQty
            : product.quantity;
    final esc = _escalationInfo();

    return Container(
      margin: const EdgeInsets.only(top: 5),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFFBCE8F1), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image (60x60 matching adapter_new_order_fagment1.xml)
          OrderProductImageWidget(
            imageUrl: product.image,
            width: 60,
            height: 60,
          ),
          const SizedBox(width: 10),
          // Middle details (weight 0.65)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                if (product.manufacturer.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    product.manufacturer,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Colors.black),
                  ),
                ],
                const SizedBox(height: 3),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        product.unit,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            const TextStyle(fontSize: 12, color: Colors.black),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 15,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      color: Colors.black,
                    ),
                    Text(
                      'Qty : $qtyDisplay',
                      style: const TextStyle(fontSize: 12, color: Colors.black),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                // Net price matching NewOrderDetailsAdapter.java line 62 ("₹ " + netPrice)
                Text(
                  '\u20B9 ${product.netPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black,
                  ),
                ),
                // Manufacture & Expiry 2-column row matching adapter_new_order_fagment1.xml lines 107-170
                OrderMfdExpLabelsRow(mfdExp: product.mfdExp),
              ],
            ),
          ),
          const SizedBox(width: 6),
          // Right side controls (info + escalation status + Reason) matching NewOrderDetailsAdapter.java lines 69-84 & 92-155
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              InkWell(
                onTap: () => OrderProductInfoScreen.open(
                  context,
                  product: product,
                  shopId: shopId,
                  categoryId: categoryId,
                ),
                child: Container(
                  width: 48,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'info',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              if (order.hasEscalation && esc.label.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  esc.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: esc.color,
                  ),
                ),
              ],
              if (order.hasEscalation && esc.showReason) ...[
                const SizedBox(height: 8),
                InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ReplacementReasonScreen(
                          order: order,
                          product: product,
                          shopId: shopId,
                          categoryId: categoryId,
                          showActionControls: true,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEE0000),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Reason',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
