import 'package:flutter/material.dart';
import '../../model/order_model.dart';
import '../widgets/order_card_parts.dart';
import 'cancelled_details_screen.dart';

/// Card for the Cancelled tab (CancelAdapter + adapter_cancel.xml in the Android app).
class CancelledOrderCard extends StatelessWidget {
  final OrderModel order;
  final String shopId;
  final String categoryId;

  const CancelledOrderCard({
    super.key,
    required this.order,
    required this.shopId,
    required this.categoryId,
  });

  @override
  Widget build(BuildContext context) {
    final statusDisplay = order.orderStatusText.isNotEmpty
        ? order.orderStatusText
        : 'Cancelled';

    return OrderCardFrame(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CancelledDetailsScreen(
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
                          'Amount : Rs ${order.amount.toStringAsFixed(2)}',
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'Payment Status : ${order.paymentType}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black,
                            fontFamily: 'Roboto',
                          ),
                        ),
                      ),
                      Flexible(
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.black,
                            ),
                            children: [
                              const TextSpan(text: 'Cancelled at : '),
                              TextSpan(
                                text: order.cancelledTimestampFormatted,
                                style: const TextStyle(
                                  color: Color(0xFF0275D8),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
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
