import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayfay_merchant_flutter/core/network/api_endpoints.dart';
import '../../controller/orders_controller.dart';
import '../../model/order_model.dart';

const kOrderBlue = Color(0xFF0275D8);
const kOrderCardBorder = Color(0xFFDADADA);
const kOrderToolText = Color(0xFF616161);
const kOrderKmText = Color(0xFF212121);
const kOrderRed = Color(0xFFF44336);
const kOrderGreen = Color(0xFF4CAF50);
const kOrderAvatarBorder = Color(0xFFE7E7E7);
const kOrderCategoryBlue = Color(0xFF4BA7EE);

/// Outer card with border and tap area. Every status card uses this.
class OrderCardFrame extends StatelessWidget {
  final VoidCallback onTap;
  final List<Widget> children;

  const OrderCardFrame({
    super.key,
    required this.onTap,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(5, 5, 5, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: kOrderCardBorder, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(5),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(5),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ),
      ),
    );
  }
}

/// "Order placed at" text and distance in the top right.
class OrderCardTopRow extends StatelessWidget {
  final OrderModel order;

  const OrderCardTopRow({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final ts = (order.hasEscalation &&
            order.verifiedAt != null &&
            order.verifiedAt!.isNotEmpty)
        ? order.verifiedAtFormatted
        : order.orderedAtFormatted;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
            child: Text(
              'Order placed at : $ts',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                color: kOrderToolText,
                fontFamily: 'ProductSans',
              ),
            ),
          ),
        ),
        if (!order.isSelfPickup)
          OrderDistanceIndicator(distance: order.distance),
      ],
    );
  }
}

/// Distance indicator with `loc_from_to.webp` icon + km text
class OrderDistanceIndicator extends StatelessWidget {
  final double distance;

  const OrderDistanceIndicator({super.key, required this.distance});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/loc_from_to.webp',
          width: 60,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const Icon(
            Icons.route_outlined,
            size: 20,
            color: kOrderBlue,
          ),
        ),
        Text(
          distance > 0 ? '${distance.toStringAsFixed(2)} km' : '0.0 km',
          style: const TextStyle(
            fontSize: 10,
            color: kOrderKmText,
            fontFamily: 'ProductSans',
          ),
        ),
      ],
    );
  }
}

class OrderAvatar extends StatelessWidget {
  final OrderModel order;

  const OrderAvatar({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return OrderAvatarWidget(
      imageUrl: order.customerImage,
      isWholesale: order.isWholesale,
    );
  }
}

/// Reusable circular customer avatar widget resolving filename via ApiEndpoints.customerImageUrl
/// and attaching Authorization header (matching BaseActivity.loadCustomerImage & loadWholeSaleCustomerImage).
class OrderAvatarWidget extends ConsumerWidget {
  final String? imageUrl;
  final bool isWholesale;
  final double size;

  const OrderAvatarWidget({
    super.key,
    this.imageUrl,
    this.isWholesale = false,
    this.size = 50,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final img = imageUrl?.trim();
    final resolvedUrl = (img != null && img.isNotEmpty)
        ? (img.startsWith('http://') || img.startsWith('https://')
            ? img
            : ApiEndpoints.customerImageUrl(img, isWholesale: isWholesale))
        : null;
    final headersAsync = ref.watch(orderAuthHeadersProvider);
    final headers = headersAsync.valueOrNull;

    return Container(
      width: size,
      height: size,
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: kOrderAvatarBorder, width: 0.5),
      ),
      child: ClipOval(
        child: resolvedUrl != null && headers != null
            ? Image.network(
                resolvedUrl,
                headers: headers,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Image.asset(
                  'assets/images/empty_profile.png',
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                ),
              )
            : Image.asset(
                'assets/images/empty_profile.png',
                width: size,
                height: size,
                fit: BoxFit.cover,
              ),
      ),
    );
  }
}

/// Reusable authenticated network product image widget matching BaseActivity.loadProductImage / loadInventoryImage
class OrderProductImageWidget extends ConsumerWidget {
  final String? imageUrl;
  final double width;
  final double height;
  final BoxFit fit;
  final bool isInventory;
  final bool isEscalated;
  final bool isNote;

  const OrderProductImageWidget({
    super.key,
    this.imageUrl,
    this.width = 60,
    this.height = 60,
    this.fit = BoxFit.contain,
    this.isInventory = false,
    this.isEscalated = false,
    this.isNote = false,
  });

  String? _resolveUrl() {
    final img = imageUrl?.trim();
    if (img == null || img.isEmpty) return null;
    if (img.startsWith('http://') || img.startsWith('https://')) return img;
    if (isNote) return ApiEndpoints.orderNoteImageUrl(img);
    if (isEscalated) return ApiEndpoints.escalatedImageUrl(img);
    if (isInventory) return ApiEndpoints.inventoryImageUrl(img);
    return ApiEndpoints.productImageUrl(img);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resolvedUrl = _resolveUrl();
    final headersAsync = ref.watch(orderAuthHeadersProvider);
    final headers = headersAsync.valueOrNull;

    return SizedBox(
      width: width,
      height: height,
      child: resolvedUrl != null && headers != null
          ? Image.network(
              resolvedUrl,
              headers: headers,
              width: width,
              height: height,
              fit: fit,
              errorBuilder: (_, _, _) => _buildFallback(),
            )
          : _buildFallback(),
    );
  }

  Widget _buildFallback() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Icon(
        Icons.inventory_2_outlined,
        size: 28,
        color: Colors.grey,
      ),
    );
  }
}

/// Exact 2-column Manufacture & Expiry date layout matching Android adapter_new_order_fagment1.xml & PackageDetailAdapter.java
class OrderMfdExpLabelsRow extends StatelessWidget {
  final MfdExpInfo? mfdExp;
  final bool useDeliveryLabelStyle;

  const OrderMfdExpLabelsRow({
    super.key,
    required this.mfdExp,
    this.useDeliveryLabelStyle = false,
  });

  @override
  Widget build(BuildContext context) {
    if (mfdExp == null) {
      return const SizedBox.shrink();
    }

    String mfgValue = '';
    String expValue = '';
    Color mfgColor = const Color(0xFFF23B3B);
    Color expColor = const Color(0xFF63C900);

    if (mfdExp!.type == 3) {
      mfgValue = 'Unknown';
      expValue = 'Unknown';
      expColor = const Color(0xFFF23B3B);
    } else if (mfdExp!.type == 2) {
      mfgValue = 'Not Applicable';
      expValue = 'Not Applicable';
      expColor = const Color(0xFFF23B3B);
    } else if (mfdExp!.dates.isNotEmpty) {
      mfgValue = mfdExp!.dates.first.mfgDateFormatted;
      expValue = mfdExp!.dates.first.expDateFormatted;
    }

    if (mfgValue.isEmpty && expValue.isEmpty) {
      return const SizedBox.shrink();
    }

    final mfgLabel = useDeliveryLabelStyle ? 'Manufacture date:' : 'Manufacture :';
    final expLabel = useDeliveryLabelStyle ? 'Expiry date :' : 'Expiry :';

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                mfgLabel,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF757575),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                expLabel,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF757575),
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mfgValue,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: mfgColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  expValue,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: expColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "Order Id : XXX (Private)"
class OrderIdLabel extends StatelessWidget {
  final OrderModel order;

  const OrderIdLabel({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final category = order.isPrivate
        ? 'Private'
        : order.categoryType.isNotEmpty
            ? order.categoryType
            : '';
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 12,
          color: Colors.black,
          fontFamily: 'ProductSans',
        ),
        children: [
          TextSpan(text: 'Order Id : ${order.orderId}'),
          if (category.isNotEmpty)
            TextSpan(
              text: ' ($category)',
              style: const TextStyle(color: kOrderCategoryBlue),
            ),
        ],
      ),
    );
  }
}

/// Status : where only the value is coloured.
class OrderStatusText extends StatelessWidget {
  final String label;
  final Color color;

  const OrderStatusText({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: 'Status : ',
        style: const TextStyle(
          fontSize: 13,
          color: kOrderToolText,
          fontFamily: 'Nunito',
        ),
        children: [
          TextSpan(
            text: label,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}

class OrderButtonsRow extends StatelessWidget {
  final List<Widget> children;

  const OrderButtonsRow({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 4),
      child: Row(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(child: children[i]),
          ],
        ],
      ),
    );
  }
}

class OrderOutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const OrderOutlineButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: kOrderBlue, width: 1),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black,
            fontFamily: 'ProductSans',
          ),
        ),
      ),
    );
  }
}

class OrderSolidButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const OrderSolidButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: kOrderBlue,
          borderRadius: BorderRadius.circular(2),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white,
            fontFamily: 'ProductSans',
          ),
        ),
      ),
    );
  }
}

class OrderRefundButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const OrderRefundButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFFF0000),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white,
            fontFamily: 'ProductSans',
          ),
        ),
      ),
    );
  }
}
