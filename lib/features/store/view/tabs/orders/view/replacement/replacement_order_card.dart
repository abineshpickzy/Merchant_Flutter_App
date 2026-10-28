import 'package:flutter/material.dart';
import '../../model/order_model.dart';
import '../widgets/customer_info_dialogs.dart';
import '../widgets/order_card_parts.dart';
import 'replacement_details_screen.dart';

/// Card for the Replace/Refund tab (ReplacementAdapter + adapter_replacement.xml in the Android app).
class ReplacementOrderCard extends StatelessWidget {
  final OrderModel order;
  final String shopId;
  final String categoryId;

  const ReplacementOrderCard({
    super.key,
    required this.order,
    required this.shopId,
    required this.categoryId,
  });

  @override
  Widget build(BuildContext context) {
    final statusLabel = order.refundRequestInitiate
        ? 'Refund Request'
        : 'Replacement/Undelivered Request';

    return OrderCardFrame(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ReplacementDetailsScreen(
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
                  Text(
                    'Amount : Rs ${order.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black,
                      fontFamily: 'ProductSans',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'Payment Status : ${order.paymentType}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black,
                            fontFamily: 'Roboto',
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          statusLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: kOrderRed,
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
        OrderButtonsRow(
          children: [
            OrderOutlineButton(
              label: 'Contact Customer',
              onTap: () =>
                  CustomerInfoDialogs.showSimplePhoneContact(context, order),
            ),
            OrderOutlineButton(
              label: 'Address',
              onTap: () => CustomerInfoDialogs.showAddress(context, order),
            ),
          ],
        ),
      ],
    );
  }
}
