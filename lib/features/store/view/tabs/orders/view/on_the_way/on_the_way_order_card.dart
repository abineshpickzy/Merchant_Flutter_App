import 'package:flutter/material.dart';
import '../../model/order_model.dart';
import '../widgets/cancel_order_dialog.dart';
import '../widgets/customer_info_dialogs.dart';
import '../widgets/order_card_parts.dart';
import 'on_the_way_details_screen.dart';

/// Card for the On the way tab (OntheWayAdapter + adapter_ontheway.xml in the Android app).
class OnTheWayOrderCard extends StatelessWidget {
  final OrderModel order;
  final String shopId;
  final String categoryId;

  const OnTheWayOrderCard({
    super.key,
    required this.order,
    required this.shopId,
    required this.categoryId,
  });

  @override
  Widget build(BuildContext context) {
    final escalated = order.isEscalatedOrder;

    return OrderCardFrame(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OnTheWayDetailsScreen(
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
                    order.tipAmount > 0
                        ? 'Amount : \u20B9${order.amount.toStringAsFixed(2)}  |  Tip: \u20B9${order.tipAmount}'
                        : 'Amount : \u20B9${order.amount.toStringAsFixed(2)}',
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
                      const Text(
                        'On the way',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0275D8),
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
            if (!escalated)
              OrderOutlineButton(
                label: 'Cancel',
                onTap: () => CancelOrderDialog.show(
                  context,
                  order: order,
                  shopId: shopId,
                  categoryId: categoryId,
                  currentStatus: order.status,
                ),
              ),
            OrderOutlineButton(
              label: 'Contact Customer',
              onTap: () => CustomerInfoDialogs.showContact(
                context,
                order,
                shopId: shopId,
              ),
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
