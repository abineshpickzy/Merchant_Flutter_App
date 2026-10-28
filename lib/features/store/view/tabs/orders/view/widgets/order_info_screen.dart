import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../model/order_model.dart';
import 'cancel_order_dialog.dart';
import 'customer_info_dialogs.dart';
import 'order_card_parts.dart';

/// Full-screen Order Info Screen matching Android PackageOrderDetailsFragment (customer_ordered_detail_layout.xml)
class OrderInfoScreen extends ConsumerWidget {
  final OrderModel order;
  final String shopId;
  final String categoryId;
  final String statusLabel;

  const OrderInfoScreen({
    super.key,
    required this.order,
    required this.shopId,
    required this.categoryId,
    this.statusLabel = 'New Order',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toolbarTitle =
        order.isEscalatedOrder ? 'Escalated Order' : order.orderId;
    final displayStatus = order.isEscalatedOrder
        ? 'Replacement/Undelivered'
        : statusLabel;
    final statusColor = order.isEscalatedOrder
        ? const Color(0xFFEE0000)
        : (statusLabel == 'On the way'
            ? const Color(0xFF0275D8)
            : const Color(0xFF52B153));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(45),
        child: AppBar(
          backgroundColor: const Color(0xFFF2F2F2),
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF333333)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            toolbarTitle,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.fromLTRB(10, 8, 10, 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: const Color(0xFFDADADA), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Avatar + Name & Order ID + Distance & Map Icon
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OrderAvatar(order: order),
                  const SizedBox(width: 16),
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (!order.isSelfPickup)
                        OrderDistanceIndicator(distance: order.distance),
                      const SizedBox(height: 6),
                      if (!order.isSelfPickup)
                        InkWell(
                          onTap: () async {
                            final lat = order.address?.latitude;
                            final lng = order.address?.longitude;
                            if (lat != null && lng != null) {
                              final uri = Uri.parse(
                                'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
                              );
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(
                                  uri,
                                  mode: LaunchMode.externalApplication,
                                );
                              }
                            } else {
                              CustomerInfoDialogs.showAddress(context, order);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFFE0E0E0),
                              ),
                            ),
                            child: const Icon(
                              Icons.map_outlined,
                              size: 20,
                              color: Color(0xFF0275D8),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Amount
              if (!order.isEscalatedOrder) ...[
                const Text(
                  'Amount :',
                  style: TextStyle(fontSize: 13, color: Color(0xFF333333)),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${order.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0275D8),
                  ),
                ),
                const Divider(height: 12, color: Color(0xFFE0E0E0)),
              ],

              // Tip Amount
              if (order.tipAmount > 0) ...[
                const Text(
                  'Tip Amount :',
                  style: TextStyle(fontSize: 13, color: Color(0xFF333333)),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${order.tipAmount}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFF9800),
                  ),
                ),
                const Divider(height: 12, color: Color(0xFFE0E0E0)),
              ],

              // Payment
              const Text(
                'Payment :',
                style: TextStyle(fontSize: 13, color: Color(0xFF333333)),
              ),
              const SizedBox(height: 4),
              Text(
                order.paymentType,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF52B153),
                ),
              ),
              const Divider(height: 12, color: Color(0xFFE0E0E0)),

              // Customer Expected Delivery Time
              const Text(
                'Customer Expected Delivery Time :',
                style: TextStyle(fontSize: 13, color: Color(0xFF333333)),
              ),
              const SizedBox(height: 4),
              Text(
                order.preferredTime.isNotEmpty
                    ? order.preferredTime
                    : 'Immediate',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFEE0000),
                ),
              ),
              const Divider(height: 12, color: Color(0xFFE0E0E0)),

              // Delivery Mode (PackageOrderDetailsFragment.java lines 285-290)
              const Text(
                'Delivery Mode :',
                style: TextStyle(fontSize: 13, color: Color(0xFF333333)),
              ),
              const SizedBox(height: 4),
              Text(
                '${order.deliveryType}${order.contactLessDelivery ? ' | Contact Less Delivery' : ''}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0275D8),
                ),
              ),
              const Divider(height: 12, color: Color(0xFFE0E0E0)),

              // Shop Expected Delivery Time (PackageOrderDetailsFragment.java lines 305-309)
              const Text(
                'Shop Expected Delivery Time:',
                style: TextStyle(fontSize: 13, color: Color(0xFF333333)),
              ),
              const SizedBox(height: 4),
              Text(
                order.expectedTimeFormatted.isNotEmpty
                    ? order.expectedTimeFormatted
                    : '-',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF7B1FA2),
                ),
              ),
              const Divider(height: 12, color: Color(0xFFE0E0E0)),

              // Status
              const Text(
                'Status :',
                style: TextStyle(fontSize: 13, color: Color(0xFF333333)),
              ),
              const SizedBox(height: 4),
              Text(
                displayStatus,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
              const Divider(height: 12, color: Color(0xFFE0E0E0)),

              const SizedBox(height: 12),

              // Customer Notes Button (@drawable/customer_notes_bg: solid #D4F8AD, stroke #4CAF50, drawableEnd ic_attach_file)
              if (order.hasCustomerNotes) ...[
                _FullWidthInfoActionBtn(
                  label: 'Customer Notes',
                  trailingIcon: Icons.attach_file,
                  backgroundColor: const Color(0xFFD4F8AD),
                  borderColor: const Color(0xFF4CAF50),
                  onTap: () => CustomerInfoDialogs.showNotes(context, order),
                ),
                const SizedBox(height: 10),
              ],

              // Contact Customer Button (@drawable/contact_customer_bg: solid #C0EAFD, stroke #0275D8)
              _FullWidthInfoActionBtn(
                label: 'Contact Customer',
                backgroundColor: const Color(0xFFC0EAFD),
                borderColor: const Color(0xFF0275D8),
                onTap: () => CustomerInfoDialogs.showContact(
                  context,
                  order,
                  shopId: shopId,
                ),
              ),
              const SizedBox(height: 10),

              // Address Button (@drawable/address_bg: solid #E5D1FF, stroke #673AB7)
              _FullWidthInfoActionBtn(
                label: 'Address',
                backgroundColor: const Color(0xFFE5D1FF),
                borderColor: const Color(0xFF673AB7),
                onTap: () => CustomerInfoDialogs.showAddress(context, order),
              ),

              // Send Cancel Request Button (@drawable/send_cancel_req_bg: solid #FFABB2, stroke #E91E63)
              if (!order.isEscalatedOrder) ...[
                const SizedBox(height: 10),
                _FullWidthInfoActionBtn(
                  label: 'Send Cancel Request',
                  backgroundColor: const Color(0xFFFFABB2),
                  borderColor: const Color(0xFFE91E63),
                  onTap: () async {
                    final cancelled = await showDialog<bool>(
                      context: context,
                      builder: (_) => CancelOrderDialog(
                        order: order,
                        shopId: shopId,
                        categoryId: categoryId,
                      ),
                    );
                    if (cancelled == true && context.mounted) {
                      Navigator.of(context).pop(true);
                    }
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FullWidthInfoActionBtn extends StatelessWidget {
  final String label;
  final IconData? trailingIcon;
  final Color backgroundColor;
  final Color borderColor;
  final VoidCallback onTap;

  const _FullWidthInfoActionBtn({
    required this.label,
    this.trailingIcon,
    required this.backgroundColor,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 36),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            if (trailingIcon != null) ...[
              const SizedBox(width: 6),
              Icon(trailingIcon, size: 16, color: Colors.black87),
            ],
          ],
        ),
      ),
    );
  }
}
