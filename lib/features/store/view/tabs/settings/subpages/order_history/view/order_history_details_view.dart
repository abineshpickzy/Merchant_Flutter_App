import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayfay_merchant_flutter/core/network/api_endpoints.dart';
import 'package:bayfay_merchant_flutter/features/dashboard/model/store_model.dart';
import 'package:bayfay_merchant_flutter/features/store/view/tabs/orders/controller/orders_controller.dart';
import 'package:bayfay_merchant_flutter/features/store/view/tabs/orders/model/order_model.dart';
import 'package:bayfay_merchant_flutter/features/store/view/widgets/store_tab_app_bar.dart';
import '../model/order_history_model.dart';

/// Full Order History Details View
/// 1:1 Parity with Android `OrderHistoryDetailsFragment.java` & `fragment_delivery_details.xml`
class OrderHistoryDetailsView extends ConsumerWidget {
  final OrderHistoryItem order;
  final StoreModel store;

  const OrderHistoryDetailsView({
    super.key,
    required this.order,
    required this.store,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = order.isEscalatedOrder
        ? 'Replacement/Undelivered'
        : (order.orderId.isNotEmpty ? order.orderId : 'Order Details');

    final productsAsync = ref.watch(
      orderProductsProvider((
        orderId: order.id,
        shopId: order.storeId.isNotEmpty ? order.storeId : store.id,
        categoryId:
            order.categoryId.isNotEmpty ? order.categoryId : (store.categoryId ?? ''),
        isEscalated: order.isEscalatedOrder,
      )),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: StoreTabAppBar(
        title: title,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF616161)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Card 1: Customer & Order Summary Card ───────────────────────
            _buildOrderSummaryCard(context),

            const SizedBox(height: 10),

            // ── Card 2: Product Details Card ───────────────────────────────
            _buildProductDetailsCard(context, ref, productsAsync),
          ],
        ),
      ),
    );
  }

  /// Card 1: Matching Android `order_product_details_bg` in `fragment_delivery_details.xml`
  Widget _buildOrderSummaryCard(BuildContext context) {
    final shopType = order.isPrivate
        ? '(Private)'
        : (order.categoryType.isNotEmpty ? '(${order.categoryType})' : '');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Customer Avatar
              CircleAvatar(
                radius: 26,
                backgroundColor: const Color(0xFFEEEEEE),
                backgroundImage: order.customer != null &&
                        order.customer!.image.isNotEmpty
                    ? NetworkImage(order.customer!.getAvatarUrl(''))
                    : null,
                child: order.customer == null || order.customer!.image.isEmpty
                    ? Text(
                        order.customer?.name.isNotEmpty == true
                            ? order.customer!.name[0].toUpperCase()
                            : 'C',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF757575),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),

              // Customer & Order Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.customer?.name ?? 'Customer',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Order ID + Shop Category in Blue
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF424242),
                        ),
                        children: [
                          const TextSpan(text: 'Order Id : '),
                          TextSpan(
                            text: '${order.orderId} ',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          if (shopType.isNotEmpty)
                            TextSpan(
                              text: shopType,
                              style: const TextStyle(
                                color: Color(0xFF0275D8),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Delivery Method in Blue
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF424242),
                        ),
                        children: [
                          const TextSpan(text: 'Delivery Method : '),
                          TextSpan(
                            text: order.deliveryType.isNotEmpty
                                ? order.deliveryType
                                : 'Shop Delivery',
                            style: const TextStyle(
                              color: Color(0xFF0275D8),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Customer Preference Delivery Time
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF424242),
                        ),
                        children: [
                          const TextSpan(text: 'CP Delivery time : '),
                          TextSpan(
                            text: order.customerPreferenceTime.isNotEmpty
                                ? order.customerPreferenceTime
                                : 'Immediate',
                            style: const TextStyle(
                              color: Color(0xFF0275D8),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Total purchased amount + Tip
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                        children: [
                          TextSpan(
                            text:
                                'Total purchased amount : ₹${order.amount.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          if (order.tipAmount > 0)
                            TextSpan(
                              text: ' | Tip : ₹${order.tipAmount}',
                              style: const TextStyle(
                                color: Color(0xFF2E7D32),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Payment Mode
                    if (order.paymentType.isNotEmpty)
                      Text(
                        'Payment Status : ${order.paymentType}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF424242),
                        ),
                      ),
                  ],
                ),
              ),

              // Distance Badge on top right
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 22,
                    color: Color(0xFF2196F3),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${order.distance.toStringAsFixed(1)} km',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF616161),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const Divider(height: 18, color: Color(0xFFEEEEEE)),

          // Status & Delivery Timestamp matching Android btn_delivery_time
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  order.statusInfo.timestampLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF0275D8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              // Customer Rating Bar
              if (order.rating > 0)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Rating: ',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF757575),
                      ),
                    ),
                    Row(
                      children: List.generate(5, (starIdx) {
                        return Icon(
                          starIdx < order.rating
                              ? Icons.star
                              : Icons.star_border,
                          size: 14,
                          color: const Color(0xFFFFB300),
                        );
                      }),
                    ),
                  ],
                ),
            ],
          ),

          // Customer Unverified Warning (Android status == 5)
          if (order.status == 5) ...[
            const SizedBox(height: 6),
            const Text(
              '! One or more items not verified by the customer',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFFEE0000),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Card 2: Product Details List matching Android `adapter_delivery_details.xml`
  Widget _buildProductDetailsCard(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<OrderProductItem>> productsAsync,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          productsAsync.when(
            data: (products) {
              final totalCount =
                  products.fold<int>(0, (sum, item) => sum + item.quantity);
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Product Details',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    'Total Products : $totalCount',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              );
            },
            loading: () => const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Product Details',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  'Loading...',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            error: (_, __) => const Row(
              children: [
                Text(
                  'Product Details',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 18, color: Color(0xFFEEEEEE)),

          // Product List Area
          productsAsync.when(
            data: (products) {
              if (products.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'No products found in this order',
                      style: TextStyle(fontSize: 12, color: Color(0xFF757575)),
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: products.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 16, color: Color(0xFFF0F0F0)),
                itemBuilder: (context, index) {
                  final item = products[index];
                  return _buildProductRow(item);
                },
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF2196F3),
                ),
              ),
            ),
            error: (err, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Column(
                  children: [
                    Text(
                      'Failed to load products: $err',
                      style: const TextStyle(fontSize: 12, color: Colors.red),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(orderProductsProvider),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Single Product Item Row matching Android `adapter_delivery_details.xml`
  Widget _buildProductRow(OrderProductItem product) {
    final imageUrl = product.image != null && product.image!.isNotEmpty
        ? ApiEndpoints.productImageUrl(product.image!)
        : null;

    final isReplacement = product.verifyStatus == 3;
    final priceStr = isReplacement
        ? '- ₹${product.netPrice.toStringAsFixed(2)}'
        : '₹ ${product.netPrice.toStringAsFixed(2)}';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product Thumbnail
        Container(
          width: 55,
          height: 55,
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
          ),
          clipBehavior: Clip.antiAlias,
          child: imageUrl != null
              ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.inventory_2_outlined,
                    size: 26,
                    color: Color(0xFFBDBDBD),
                  ),
                )
              : const Icon(
                  Icons.inventory_2_outlined,
                  size: 26,
                  color: Color(0xFFBDBDBD),
                ),
        ),
        const SizedBox(width: 12),

        // Product Information
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Name
              Text(
                product.productName,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              // Manufacturer / Detail
              if (product.manufacturer.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  product.manufacturer,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF757575),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 4),

              // Unit & Qty & Price Row
              Row(
                children: [
                  if (product.unit.isNotEmpty) ...[
                    Text(
                      product.unit,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF616161),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Text(
                    'Qty : ${product.quantity}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    priceStr,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isReplacement
                          ? const Color(0xFFF23B3B)
                          : Colors.black87,
                    ),
                  ),
                ],
              ),

              // Manufacturing & Expiry Dates (if present)
              if (product.mfdExp != null) ...[
                const SizedBox(height: 4),
                if (product.mfdExp!.type > 1)
                  Text(
                    product.mfdExp!.type == 3 ? 'Unknown' : 'Not Applicable',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFFF23B3B),
                      fontWeight: FontWeight.w500,
                    ),
                  )
                else if (product.mfdExp!.dates.isNotEmpty)
                  Row(
                    children: [
                      if (product.mfdExp!.dates.first.mfgDateFormatted.isNotEmpty)
                        Text(
                          'MFD: ${product.mfdExp!.dates.first.mfgDateFormatted}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFFF23B3B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      if (product.mfdExp!.dates.first.mfgDateFormatted.isNotEmpty &&
                          product.mfdExp!.dates.first.expDateFormatted.isNotEmpty)
                        const SizedBox(width: 8),
                      if (product.mfdExp!.dates.first.expDateFormatted.isNotEmpty)
                        Text(
                          'EXP: ${product.mfdExp!.dates.first.expDateFormatted}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF2E7D32),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
              ],

              const SizedBox(height: 6),

              // Verification Status Badge matching Android switch(products.getVerify_status())
              _buildVerificationBadge(product.verifyStatus),
            ],
          ),
        ),
      ],
    );
  }

  /// Verification badge matching Android `OrderHistoryDetailsAdapter.java`
  Widget _buildVerificationBadge(int status) {
    switch (status) {
      case 1: // VERIFY_STATUS_DELIVERY
        return const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 14, color: Color(0xFF4CAF50)),
            SizedBox(width: 4),
            Text(
              'Customer Verified',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF4CAF50),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      case 2: // VERIFY_STATUS_UNDELIVERY
        return const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cancel, size: 14, color: Color(0xFFE53935)),
            SizedBox(width: 4),
            Text(
              'Undelivered request',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFFE53935),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      case 3: // VERIFY_STATUS_REPLACEMENT
        return const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.autorenew, size: 14, color: Color(0xFFFB8C00)),
            SizedBox(width: 4),
            Text(
              'Replacement request',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFFFB8C00),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      default:
        return const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cancel, size: 14, color: Color(0xFFE53935)),
            SizedBox(width: 4),
            Text(
              'Customer not verified',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFFE53935),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
    }
  }
}
