import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayfay_merchant_flutter/core/widgets/app_snackbar.dart';
import '../../controller/orders_controller.dart';
import '../../model/order_model.dart';
import '../packaging/packaging_details_screen.dart';
import '../widgets/assign_associate_dialog.dart';
import '../widgets/customer_info_dialogs.dart';
import '../widgets/order_card_parts.dart';
import '../widgets/order_info_screen.dart';

/// Dispatched Order Details Screen matching Android DispatchDetailsFragment (fragment_dispatch_details.xml)
class DispatchedDetailsScreen extends ConsumerStatefulWidget {
  final OrderModel order;
  final String shopId;
  final String categoryId;

  const DispatchedDetailsScreen({
    super.key,
    required this.order,
    required this.shopId,
    required this.categoryId,
  });

  @override
  ConsumerState<DispatchedDetailsScreen> createState() =>
      _DispatchedDetailsScreenState();
}

class _DispatchedDetailsScreenState
    extends ConsumerState<DispatchedDetailsScreen> {
  bool _isAssignedLocally = false;

  void _showAssignConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 45,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: const BoxDecoration(
                color: Color(0xFFF2F2F2),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'BayFay - Alert',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(ctx).pop(),
                    child: const Icon(Icons.close, size: 20),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE0E0E0)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
              child: Column(
                children: [
                  const Text(
                    'Are you sure you want to manually assign the order to delivery associate?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 100,
                        height: 34,
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFBDBDBD)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          child: const Text(
                            'No',
                            style: TextStyle(color: Colors.black, fontSize: 13),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 100,
                        height: 34,
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.of(ctx).pop();
                            final assigned = await AssignAssociateDialog.show(
                              context,
                              order: widget.order,
                              shopId: widget.shopId,
                              categoryId: widget.categoryId,
                              currentStatus: OrderStatus.ready,
                            );
                            if (assigned == true && mounted) {
                              setState(() {
                                _isAssignedLocally = true;
                              });
                              ref.invalidate(
                                orderInDeliveryQueueProvider(widget.order.id),
                              );
                              ref.invalidate(ordersListProvider);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0288D1),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          child: const Text(
                            'Yes',
                            style: TextStyle(fontSize: 13),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final shopId = widget.shopId;
    final categoryId = widget.categoryId;

    final productsArg = (
      orderId: order.id,
      shopId: shopId,
      categoryId: categoryId,
      isEscalated: order.isEscalatedOrder,
    );
    final productsAsync = ref.watch(orderProductsProvider(productsArg));
    final inQueueAsync = ref.watch(orderInDeliveryQueueProvider(order.id));
    final inQueue = inQueueAsync.valueOrNull ?? false;

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
            order.isEscalatedOrder ? 'Replacement/Undelivered' : order.orderId,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          actions: [
            if (!order.isEscalatedOrder)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: InkWell(
                  onTap: () => CustomerInfoDialogs.showInvoicePopup(
                    context,
                    order: order,
                    ref: ref,
                  ),
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
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
          // Top Customer & Action Card
          Container(
            margin: const EdgeInsets.fromLTRB(10, 5, 10, 0),
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
                      child: _SubActionBtn(
                        label: 'Order Details',
                        onTap: () async {
                          final res = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (_) => OrderInfoScreen(
                                order: order,
                                shopId: shopId,
                                categoryId: categoryId,
                                statusLabel: 'Dispatched',
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
                        child: _SubActionBtn(
                          label: 'Customer Notes',
                          onTap: () =>
                              CustomerInfoDialogs.showNotes(context, order),
                        ),
                      ),
                    ],
                    if (order.hasAssignedAssistant && !order.isSelfPickup) ...[
                      const SizedBox(width: 6),
                      Expanded(
                        child: _SubActionBtn(
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

          // Product Details List
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

          // Bottom Action Buttons matching Android fragment_dispatch_details.xml: Side-by-side in a Row
          // (sample_btn_bg2 for Assign, sample_btn_bg2 for Start Shipping)
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: Row(
              children: [
                if (!order.isSelfPickup && !order.hasAssignedAssistant) ...[
                  Expanded(
                    child: InkWell(
                      onTap: _isAssignedLocally
                          ? null
                          : () => _showAssignConfirmationDialog(context),
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _isAssignedLocally
                              ? const Color(0xFFE0E0E0)
                              : inQueue
                                  ? const Color(0xFF52B153)
                                  : const Color(0xFF0288D1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _isAssignedLocally
                              ? 'Assigned'
                              : inQueue
                                  ? 'Order in the Delivery Queue'
                                  : 'Assign to Associate',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _isAssignedLocally
                                ? Colors.black
                                : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: InkWell(
                    onTap: () => _handleStartShipping(context, ref),
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0288D1), // Matching Android sample_btn_bg2 (#0288D1)
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Click here to Start Shipping',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleStartShipping(BuildContext context, WidgetRef ref) {
    final order = widget.order;
    final shopId = widget.shopId;
    final categoryId = widget.categoryId;

    final isCod = order.paymentType.toLowerCase().contains('cash') ||
        order.paymentType.toLowerCase().contains('cod');

    if (order.isSelfPickup) {
      final msg = isCod && !order.isEscalatedOrder
          ? 'This is a Self-Pickup Cash on Delivery order (₹${order.amount.toStringAsFixed(2)}). Confirm cash collected and order handed over to customer?'
          : 'Kindly confirm that the customer has picked up the order.';
      CustomerInfoDialogs.showCommonTwoButtonsAlert(
        context,
        title: 'Alert',
        message: msg,
        negativeText: 'Cancel',
        positiveText: 'Confirm',
        onConfirm: () async {
          final res = await ref
              .read(orderActionControllerProvider.notifier)
              .deliverOrder(
                shopId: shopId,
                categoryId: categoryId,
                orderId: order.id,
                currentStatus: OrderStatus.ready,
              );
          if (context.mounted) {
            if (res.success) {
              AppSnackBar.showSuccess(
                context,
                res.message.isNotEmpty
                    ? res.message
                    : 'Order delivered successfully',
              );
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
      return;
    }

    CustomerInfoDialogs.showCommonTwoButtonsAlert(
      context,
      title: 'Alert',
      message: 'Kindly confirm package on the move',
      negativeText: 'Cancel',
      positiveText: 'Confirmed',
      onConfirm: () async {
        final res = await ref
            .read(orderActionControllerProvider.notifier)
            .shipOrder(
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
                  : 'Order package on the move',
            );
            ref.read(orderStatusTabProvider.notifier).state =
                OrderStatus.onTheWay;
            Navigator.of(context).pop(true);
          } else {
            AppSnackBar.showError(
              context,
              res.message.isNotEmpty
                  ? res.message
                  : 'Failed to start shipping',
            );
          }
        }
      },
    );
  }
}

class _SubActionBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SubActionBtn({
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
