import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayfay_merchant_flutter/core/widgets/app_snackbar.dart';
import '../../controller/orders_controller.dart';
import '../../model/order_model.dart';
import '../packaging/packaging_details_screen.dart';
import '../widgets/customer_info_dialogs.dart';
import '../widgets/order_card_parts.dart';
import '../widgets/order_info_screen.dart';

/// On The Way Order Details Screen matching Android OntheWayDetailsFragment (fragment_on_the_way_details.xml)
class OnTheWayDetailsScreen extends ConsumerWidget {
  final OrderModel order;
  final String shopId;
  final String categoryId;

  const OnTheWayDetailsScreen({
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
      isEscalated: order.isEscalatedOrder,
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
          title: Text(
            order.isEscalatedOrder ? 'Escalated Order' : order.orderId,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: InkWell(
                onTap: () => _handleDeliverOrder(context, ref),
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0275D8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Deliver',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            if (!order.isEscalatedOrder)
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 8, 8),
                child: InkWell(
                  onTap: () => CustomerInfoDialogs.showInvoicePopup(
                    context,
                    order: order,
                    ref: ref,
                  ),
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0275D8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Invoice',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          // "Delivery in Progress" banner matching Android fragment_on_the_way_details.xml
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 4),
            alignment: Alignment.center,
            child: const Text(
              'Delivery in Progress',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0275D8),
              ),
            ),
          ),

          // Top Customer & Action Card
          Container(
            margin: const EdgeInsets.fromLTRB(10, 2, 10, 0),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: const Color(0xFFDADADA), width: 1),
            ),
            child: Column(
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
                          const SizedBox(height: 4),
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
                          const SizedBox(height: 4),
                          OrderIdLabel(order: order),
                        ],
                      ),
                    ),
                    if (!order.isSelfPickup)
                      OrderDistanceIndicator(distance: order.distance),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _OnTheWaySubBtn(
                        label: 'Order Details',
                        onTap: () async {
                          final res = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (_) => OrderInfoScreen(
                                order: order,
                                shopId: shopId,
                                categoryId: categoryId,
                                statusLabel: 'On the way',
                              ),
                            ),
                          );
                          if (res == true && context.mounted) {
                            Navigator.of(context).pop(true);
                          }
                        },
                      ),
                    ),
                    if (order.hasCustomerNotes) ...[
                      const SizedBox(width: 6),
                      Expanded(
                        child: _OnTheWaySubBtn(
                          label: 'Customer Notes',
                          onTap: () =>
                              CustomerInfoDialogs.showNotes(context, order),
                        ),
                      ),
                    ],
                    if (order.hasAssignedAssistant && !order.isSelfPickup) ...[
                      const SizedBox(width: 6),
                      Expanded(
                        child: _OnTheWaySubBtn(
                          label: 'Delivery Info',
                          onTap: () =>
                              CustomerInfoDialogs.showDeliveryPersonInfo(
                                context,
                                order: order,
                              ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Product Details Card
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(10, 5, 10, 8),
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
                  final totalProductsCount = products.fold<int>(
                    0,
                    (sum, p) =>
                        sum +
                        (order.isEscalatedOrder && p.escalatedQty > 0
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
                            return PackagingProductRowWidget(
                              product: p,
                              orderId: order.id,
                              shopId: shopId,
                              categoryId: categoryId,
                              isEscalatedOrder: order.isEscalatedOrder,
                              showCheckIndicator: false,
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

          // Bottom "Click here to Deliver Order" Button
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: InkWell(
              onTap: () => _handleDeliverOrder(context, ref),
              child: Container(
                width: double.infinity,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF0275D8),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Click here to Deliver Order',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleDeliverOrder(BuildContext context, WidgetRef ref) {
    // Matching Android OntheWayDetailsFragment.java lines 411-419 & showDeliveryConfirmationDialog / showDeliveryConfirmationDialogWithCash
    final isOnlineOrPaid = order.paymentType.isNotEmpty &&
        !order.paymentType.toLowerCase().contains('cash') &&
        !order.paymentType.toLowerCase().contains('cod');

    final String message;
    final String positiveLabel;
    final String negativeLabel;

    if (isOnlineOrPaid || order.isEscalatedOrder) {
      message = 'Do you want to deliver this order?';
      positiveLabel = 'Yes';
      negativeLabel = 'No';
    } else {
      message =
          'Total Billing amount ${order.amount.toStringAsFixed(2)} \n Kindly confirm customer received the package and collect the amount.';
      positiveLabel = 'Collected';
      negativeLabel = 'Cancel';
    }

    CustomerInfoDialogs.showCommonTwoButtonsAlert(
      context,
      title: 'Alert',
      message: message,
      negativeText: negativeLabel,
      positiveText: positiveLabel,
      onConfirm: () async {
        final res = await ref
            .read(orderActionControllerProvider.notifier)
            .deliverOrder(
              shopId: shopId,
              categoryId: categoryId,
              orderId: order.id,
              currentStatus: OrderStatus.onTheWay,
            );
        if (context.mounted) {
          if (res.success) {
            AppSnackBar.showSuccess(
              context,
              res.message.isNotEmpty
                  ? res.message
                  : 'Order delivered successfully',
            );
            ref.read(orderStatusTabProvider.notifier).state =
                OrderStatus.delivered;
            Navigator.of(context).pop(true);
          } else {
            AppSnackBar.showError(
              context,
              res.message.isNotEmpty
                  ? res.message
                  : 'Failed to deliver order',
            );
          }
        }
      },
    );
  }
}

class _OnTheWaySubBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _OnTheWaySubBtn({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.grey.shade400),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
      ),
    );
  }
}
