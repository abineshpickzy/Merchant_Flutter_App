import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controller/orders_controller.dart';
import '../../model/order_model.dart';
import '../replacement/replacement_reason_screen.dart';
import '../widgets/customer_info_dialogs.dart';
import '../widgets/mfd_exp_dialog.dart';
import '../widgets/order_card_parts.dart';
import '../widgets/order_product_info_screen.dart';

/// Delivered Order Details Screen matching Android DeliveryDetailsFragment (fragment_delivery_details.xml + DeliveryDetailsAdapter.java)
class DeliveredDetailsScreen extends ConsumerWidget {
  final OrderModel order;
  final String shopId;
  final String categoryId;

  const DeliveredDetailsScreen({
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
    final isNotVerified =
        order.orderStatusText.toLowerCase().contains('not verified');

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
          // Top Order Summary Card (fragment_delivery_details.xml lines 52-300)
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
                          if (!order.isEscalatedOrder) ...[
                            const SizedBox(height: 2),
                            Text(
                              order.tipAmount > 0
                                  ? 'Total purchased amount : \u20B9${order.amount.toStringAsFixed(2)} |  Tip: \u20B9${order.tipAmount}'
                                  : 'Total purchased amount : \u20B9${order.amount.toStringAsFixed(2)}',
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
                                const TextSpan(text: 'Delivered on : '),
                                TextSpan(
                                  text: order.deliveredAtFormatted,
                                  style: const TextStyle(
                                    color: Color(0xFF0275D8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Text(
                                'Customer Rating :',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: List.generate(5, (i) {
                                  return Icon(
                                    i < order.rating
                                        ? Icons.star
                                        : Icons.star_border,
                                    size: 16,
                                    color: const Color(0xFFFFB300),
                                  );
                                }),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (!order.isSelfPickup)
                      OrderDistanceIndicator(distance: order.distance),
                  ],
                ),
                if (isNotVerified) ...[
                  const SizedBox(height: 6),
                  const Center(
                    child: Text(
                      '! One or more items not verified by the customer',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF23B3B),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Product Details Card (fragment_delivery_details.xml lines 302-339)
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
                  // DeliveryDetailsFragment.java lines 262-268: sum of qty
                  final totalProductsCount = products.fold<int>(
                    0,
                    (sum, p) => sum + p.quantity,
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
                            return _DeliveredProductRow(
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

/// Product item row matching Android DeliveryDetailsAdapter (adapter_delivery_details.xml)
class _DeliveredProductRow extends StatelessWidget {
  final OrderModel order;
  final OrderProductItem product;
  final String shopId;
  final String categoryId;

  const _DeliveredProductRow({
    required this.order,
    required this.product,
    required this.shopId,
    required this.categoryId,
  });

  @override
  Widget build(BuildContext context) {
    final mfdExp = product.mfdExp;
    final hasMoreDates = mfdExp != null && mfdExp.dates.length > 1;
    final showMoreInfoBtn =
        product.verifyStatus == 2 || product.verifyStatus == 3;

    // Verification status text & icon matching Android DeliveryDetailsAdapter.java lines 97-133
    final String statusText;
    final String statusIconAsset;
    final Color statusTextColor;

    switch (product.verifyStatus) {
      case 1: // VERIFY_STATUS_DELIVERY
        statusText = 'Customer Verified';
        statusIconAsset = 'assets/images/ic_green_checked.webp';
        statusTextColor = const Color(0xFF52B153);
        break;
      case 2: // VERIFY_STATUS_UNDELIVERY
        statusText = 'Undelivered request';
        statusIconAsset = 'assets/images/ic_red_close.webp';
        statusTextColor = const Color(0xFFF23B3B);
        break;
      case 3: // VERIFY_STATUS_REPLACEMENT
        statusText = 'Replacement request';
        statusIconAsset = 'assets/images/ic_replacement_icon.webp';
        statusTextColor = const Color(0xFFF23B3B);
        break;
      default:
        statusText = 'Customer not verified';
        statusIconAsset = 'assets/images/ic_red_close.webp';
        statusTextColor = const Color(0xFFF23B3B);
        break;
    }

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
                      'Qty : ${product.quantity}',
                      style: const TextStyle(fontSize: 12, color: Colors.black),
                    ),
                  ],
                ),
                // Net price matching DeliveryDetailsAdapter.java lines 62 & 126
                if (!order.isEscalatedOrder) ...[
                  const SizedBox(height: 3),
                  Text(
                    product.verifyStatus == 3
                        ? ' Rs -${product.netPrice.toStringAsFixed(2)}'
                        : '\u20B9 ${product.netPrice.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: product.verifyStatus == 3
                          ? const Color(0xFFF23B3B)
                          : Colors.black,
                    ),
                  ),
                ],
                OrderMfdExpLabelsRow(
                  mfdExp: mfdExp,
                  useDeliveryLabelStyle: true,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          // Right column: Status Text + Icon + Info button + More matching adapter_delivery_details.xml
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                statusText,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: statusTextColor,
                ),
              ),
              const SizedBox(height: 8),
              Image.asset(
                statusIconAsset,
                width: 22,
                height: 22,
                errorBuilder: (_, __, ___) => Icon(
                  product.verifyStatus == 1
                      ? Icons.check_circle
                      : product.verifyStatus == 3
                          ? Icons.swap_horiz
                          : Icons.cancel,
                  color: statusTextColor,
                  size: 22,
                ),
              ),
              // Info button matching Android DeliveryDetailsAdapter.java lines 107-135 (only visible for replacement requests)
              if (product.verifyStatus == 3) ...[
                const SizedBox(height: 8),
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
                        color: Color(0xFF0275D8),
                      ),
                    ),
                  ),
                ),
              ],
              if (showMoreInfoBtn) ...[
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
                          showActionControls: false,
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
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'More info',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
              if (hasMoreDates) ...[
                const SizedBox(height: 8),
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
