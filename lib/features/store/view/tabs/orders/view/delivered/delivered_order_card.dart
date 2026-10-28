import 'package:flutter/material.dart';
import '../../model/order_model.dart';
import '../widgets/order_card_parts.dart';
import 'delivered_details_screen.dart';

/// Card for the Delivered tab (DeliveryAdapter + adapter_delivery.xml in the Android app).
class DeliveredOrderCard extends StatelessWidget {
  final OrderModel order;
  final String shopId;
  final String categoryId;

  const DeliveredOrderCard({
    super.key,
    required this.order,
    required this.shopId,
    required this.categoryId,
  });

  @override
  Widget build(BuildContext context) {
    final statusDisplay = order.orderStatusText.isNotEmpty
        ? order.orderStatusText
        : 'Delivered';

    return OrderCardFrame(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DeliveredDetailsScreen(
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
                  const SizedBox(height: 6),
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
                  const SizedBox(height: 6),
                  OrderIdLabel(order: order),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          order.tipAmount > 0
                              ? 'Amount : \u20B9${order.amount.toStringAsFixed(2)}  |  Tip: \u20B9${order.tipAmount}'
                              : 'Amount : \u20B9${order.amount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black,
                            fontFamily: 'ProductSans',
                          ),
                        ),
                      ),
                      OrderStatusText(
                        label: statusDisplay,
                        color: kOrderRed,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Payment Status : ${order.paymentType}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black,
                      fontFamily: 'Roboto',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.black,
                            ),
                            children: [
                              const TextSpan(text: 'Delivered on : '),
                              TextSpan(
                                text: order.deliveredAtFormatted,
                                style: const TextStyle(
                                  color: Color(0xFF0275D8),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Customer Rating :',
                            style: TextStyle(fontSize: 11, color: Colors.black),
                          ),
                          const SizedBox(width: 4),
                          ...List.generate(5, (i) {
                            return Icon(
                              i < order.rating
                                  ? Icons.star
                                  : Icons.star_border,
                              size: 14,
                              color: const Color(0xFFFFB300),
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
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
      ],
    );
  }
}
