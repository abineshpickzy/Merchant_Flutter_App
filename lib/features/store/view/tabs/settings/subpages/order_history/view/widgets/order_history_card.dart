import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayfay_merchant_flutter/core/network/api_endpoints.dart';
import 'package:bayfay_merchant_flutter/features/dashboard/controller/dashboard_controller.dart';
import '../../model/order_history_model.dart';

/// Single order history card matching Android adapter_delivery.xml
class OrderHistoryCard extends ConsumerWidget {
  final OrderHistoryItem order;
  final VoidCallback onTap;

  const OrderHistoryCard({
    super.key,
    required this.order,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authHeaderAsync = ref.watch(authHeaderProvider);
    final authHeaders = authHeaderAsync.valueOrNull ?? {};
    final baseUrl = authHeaders['baseUrl'] ?? ApiEndpoints.baseUrl;
    final avatarUrl = order.customer?.getAvatarUrl(baseUrl) ?? '';
    final statusData = order.statusInfo;

    final shopTypeLabel = order.isPrivate
        ? '(Private)'
        : (order.categoryType.isNotEmpty ? '(${order.categoryType})' : '');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            offset: const Offset(0, 1),
            blurRadius: 3,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Timestamp and Distance
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      order.ordered.isNotEmpty
                          ? 'Order placed at : ${order.ordered}'
                          : 'Order placed',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF757575),
                      ),
                    ),
                    if (order.distance > 0)
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 12, color: Color(0xFF2196F3)),
                          const SizedBox(width: 2),
                          Text(
                            '${order.distance.toStringAsFixed(1)} km',
                            style: const TextStyle(fontSize: 10, color: Color(0xFF757575)),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 6),

                // Main Info Row: Avatar + Details
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Customer 48x48 Circular Avatar
                    ClipOval(
                      child: Container(
                        width: 48,
                        height: 48,
                        color: Colors.grey.shade100,
                        child: avatarUrl.isNotEmpty
                            ? Image.network(
                                avatarUrl,
                                headers: authHeaders,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.person,
                                  size: 28,
                                  color: Color(0xFFBDBDBD),
                                ),
                              )
                            : const Icon(
                                Icons.person,
                                size: 28,
                                color: Color(0xFFBDBDBD),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Order Details Column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Customer Name
                          Text(
                            order.customer?.name.isNotEmpty == true
                                ? order.customer!.name
                                : 'Customer',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),

                          // Order ID + Shop Type Badge
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Order Id : ${order.orderId} ',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.black87,
                                  ),
                                ),
                                if (shopTypeLabel.isNotEmpty)
                                  TextSpan(
                                    text: shopTypeLabel,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF4BA7EE),
                                    ),
                                  ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),

                          // Purchase Amount
                          Text(
                            'Purchase Amount : ₹${order.amount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),

                          // Payment Mode & Status Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Payment: ${order.paymentType.isNotEmpty ? order.paymentType : "COD"}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF616161),
                                ),
                              ),
                              // Status Text
                              Text(
                                statusData.label,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(statusData.colorHex),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 6),
                    const Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: Color(0xFFBDBDBD),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
