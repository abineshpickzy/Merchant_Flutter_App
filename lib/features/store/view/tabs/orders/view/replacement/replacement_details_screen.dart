import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayfay_merchant_flutter/core/widgets/widgets.dart';
import '../../controller/orders_controller.dart';
import '../../model/order_model.dart';
import '../widgets/customer_info_dialogs.dart';
import '../widgets/mfd_exp_dialog.dart';
import '../widgets/order_card_parts.dart';
import '../widgets/order_product_info_screen.dart';
import 'replacement_reason_screen.dart';

/// Replace/Refund Order Details Screen matching Android ReplacementDetailsFragment (fragment_delivery_details.xml + ReplacementDetailAdapter.java)
class ReplacementDetailsScreen extends ConsumerWidget {
  final OrderModel order;
  final String shopId;
  final String categoryId;

  const ReplacementDetailsScreen({
    super.key,
    required this.order,
    required this.shopId,
    required this.categoryId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsArg = (
      orderId: order.id,
      shopId: shopId,
      categoryId: categoryId,
      isEscalated: true,
    );
    final productsAsync = ref.watch(orderProductsProvider(productsArg));

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
          title: const Text(
            'Replacement/Undelivered',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Top Summary Card (fragment_delivery_details.xml + ReplacementDetailsFragment.java lines 163-225)
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
                          const SizedBox(height: 2),
                          OrderIdLabel(order: order),
                          const SizedBox(height: 2),
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black,
                              ),
                              children: [
                                const TextSpan(text: 'Delivery Method : '),
                                TextSpan(
                                  text: order.deliveryType,
                                  style: const TextStyle(
                                    color: Color(0xFF4BA7EE),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),
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
                          const SizedBox(height: 2),
                          Text(
                            'Total purchased amount : Rs ${order.amount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 2),
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
                const SizedBox(height: 6),
                const Center(
                  child: Text(
                    '! Received replacement request from the customer',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF23B3B),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Product Details Card
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
                    'Failed to load escalated products: $err',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
                data: (products) {
                  // ReplacementDetailsFragment.java lines 234-240: sum of escalatedQty
                  final totalProductsCount = products.fold<int>(
                    0,
                    (sum, p) =>
                        sum + (p.escalatedQty > 0 ? p.escalatedQty : p.quantity),
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
                            return _ReplacementProductRow(
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

/// Product item row matching Android ReplacementDetailAdapter (adapter_replacement_details.xml)
class _ReplacementProductRow extends ConsumerWidget {
  final OrderModel order;
  final OrderProductItem product;
  final String shopId;
  final String categoryId;

  const _ReplacementProductRow({
    required this.order,
    required this.product,
    required this.shopId,
    required this.categoryId,
  });

  /// Escalation status info matching ReplacementDetailAdapter.java lines 81-161
  ({
    String label,
    Color color,
    bool showReason,
    bool showRefund,
    bool showInfo,
    bool showCheckIcon,
  }) _statusInfo() {
    const red = Color(0xFFF23B3B);
    const green = Color(0xFF63C900);

    switch (product.escalationStatus) {
      case 1: // ESCALATION_CLIENT
        final lbl = product.verifyStatus == 2
            ? 'Undelivered'
            : (product.verifyStatus == 3 ? 'Replacement' : 'Escalated');
        return (
          label: lbl,
          color: red,
          showReason: true,
          showRefund: false,
          showInfo: true,
          showCheckIcon: false,
        );
      case 2: // ESCALATION_MERCHANT
        return (
          label: 'Escalated',
          color: red,
          showReason: true,
          showRefund: false,
          showInfo: true,
          showCheckIcon: false,
        );
      case 3: // ESCALATION_ACCEPTED_CLIENT
        return (
          label: 'Closed',
          color: green,
          showReason: false,
          showRefund: false,
          showInfo: true,
          showCheckIcon: false,
        );
      case 4: // ESCALATION_ACCEPTED_MERCHANT
        return (
          label: 'Accepted',
          color: green,
          showReason: true,
          showRefund: false,
          showInfo: true,
          showCheckIcon: false,
        );
      case 5: // ESCALATION_REFUND_REQUEST
        return (
          label: 'Refund requested',
          color: red,
          showReason: false,
          showRefund: true,
          showInfo: true,
          showCheckIcon: false,
        );
      case 6: // ESCALATION_REFUND_INITIATE
        return (
          label: 'Refund initiated',
          color: red,
          showReason: false,
          showRefund: false,
          showInfo: true,
          showCheckIcon: false,
        );
      case 7: // ESCALATION_CLOSE
        return (
          label: 'Closed',
          color: red,
          showReason: false,
          showRefund: false,
          showInfo: true,
          showCheckIcon: false,
        );
      case 8: // ESCALATION_TEMPLATE_ACCEPT
        return (
          label: 'Closed',
          color: green,
          showReason: false,
          showRefund: false,
          showInfo: true,
          showCheckIcon: false,
        );
      default:
        return (
          label: 'Delivered',
          color: green,
          showReason: false,
          showRefund: false,
          showInfo: false,
          showCheckIcon: true,
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qtyDisplay = product.escalatedQty > 0
        ? product.escalatedQty
        : product.quantity;
    final status = _statusInfo();
    final mfdExp = product.mfdExp;
    final hasMoreDates = mfdExp != null && mfdExp.dates.length > 1;

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
          OrderProductImageWidget(
            imageUrl: product.image,
            width: 60,
            height: 60,
          ),
          const SizedBox(width: 10),
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
                  const SizedBox(height: 2),
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
                // Net price matching ReplacementDetailAdapter.java line 60
                Text(
                  '\u20B9 ${product.netPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black,
                  ),
                ),
                OrderMfdExpLabelsRow(
                  mfdExp: mfdExp,
                  useDeliveryLabelStyle: true,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (status.showInfo)
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
                      'Info',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              if (status.label.isNotEmpty) ...[
                if (status.showInfo) const SizedBox(height: 6),
                Text(
                  status.label,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: status.color,
                  ),
                ),
              ],
              if (status.showCheckIcon) ...[
                const SizedBox(height: 4),
                const Icon(
                  Icons.check_circle,
                  size: 18,
                  color: Color(0xFF63C900),
                ),
              ],
              if (status.showReason) ...[
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
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
              if (status.showRefund) ...[
                const SizedBox(height: 8),
                InkWell(
                  onTap: () {
                    CustomerInfoDialogs.showRefundDialog(
                      context,
                      refundAmount: product.escalatedTotalPrice,
                      onConfirm: (_) async {
                        final res = await ref
                            .read(orderActionControllerProvider.notifier)
                            .refundEscalatedProduct(
                              shopId: shopId,
                              categoryId: categoryId,
                              orderId: order.id,
                              productId: product.id,
                              isRequest: false,
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
                      'Refund',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
              if (hasMoreDates) ...[
                const SizedBox(height: 6),
                InkWell(
                  onTap: () =>
                      MfdExpDialog.showMoreDatesPopup(context, product),
                  child: Container(
                    width: 48,
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'More',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
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
