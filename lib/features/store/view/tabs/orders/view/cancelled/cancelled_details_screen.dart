import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controller/orders_controller.dart';
import '../../model/order_model.dart';
import '../packaging/packaging_details_screen.dart';
import '../widgets/order_card_parts.dart';

/// Cancelled Order Details Screen matching Android CancelDetailsFragment (fragment_delivery_details.xml + CancelDetailAdapter.java)
class CancelledDetailsScreen extends ConsumerWidget {
  final OrderModel order;
  final String shopId;
  final String categoryId;

  const CancelledDetailsScreen({
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
    final statusDisplay = order.orderStatusText.isNotEmpty
        ? order.orderStatusText
        : 'Cancelled';

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
        ),
      ),
      body: Column(
        children: [
          // Top Order Summary Card
          Container(
            margin: const EdgeInsets.fromLTRB(10, 5, 10, 0),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: const Color(0xFFDADADA), width: 1),
            ),
            child: Row(
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
                      if (!order.isEscalatedOrder) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Total purchased amount : Rs ${order.amount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black,
                          ),
                        ),
                      ],
                      const SizedBox(height: 2),
                      Text(
                        'Payment Status : ${order.paymentType}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black,
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
                            const TextSpan(text: 'Status : '),
                            TextSpan(
                              text: statusDisplay,
                              style: const TextStyle(
                                color: Color(0xFFF23B3B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (!order.isSelfPickup)
                  OrderDistanceIndicator(distance: order.distance),
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
                              isCancelled: true,
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
        ],
      ),
    );
  }
}
