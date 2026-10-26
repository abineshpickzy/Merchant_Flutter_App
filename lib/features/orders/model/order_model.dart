import 'package:equatable/equatable.dart';

enum OrderStatus {
  newOrder,
  processing,
  ready,
  onTheWay,
  delivered,
  cancelled,
  replaceRefund;

  String get label {
    switch (this) {
      case OrderStatus.newOrder:
        return 'New Order';
      case OrderStatus.processing:
        return 'Packaging';
      case OrderStatus.ready:
        return 'Dispatched';
      case OrderStatus.onTheWay:
        return 'On The Way';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.replaceRefund:
        return 'Replace/Refund';
    }
  }
}

class OrderModel extends Equatable {
  final String id;
  final String orderId;
  final double amount;
  final String customerName;
  final String customerMobile;
  final String customerAddress;
  final String deliveryType;
  final String paymentType;
  final String orderedAt;
  final OrderStatus status;
  final bool isWholesale;
  final String? notes;

  const OrderModel({
    required this.id,
    required this.orderId,
    required this.amount,
    required this.customerName,
    required this.customerMobile,
    required this.customerAddress,
    required this.deliveryType,
    required this.paymentType,
    required this.orderedAt,
    this.status = OrderStatus.newOrder,
    this.isWholesale = false,
    this.notes,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json, [OrderStatus? status]) {
    // Parse customer name & mobile
    String name = 'Customer';
    String mobile = '';
    if (json['customer'] is Map<String, dynamic>) {
      final cust = json['customer'] as Map<String, dynamic>;
      name = cust['name'] as String? ?? 'Customer';
      if (cust['mobile'] is Map<String, dynamic>) {
        final m = cust['mobile'] as Map<String, dynamic>;
        mobile = '${m['number'] ?? ''}';
      } else if (cust['mobile'] != null) {
        mobile = '${cust['mobile']}';
      }
    }

    // Parse address
    String addressStr = 'Store Pickup / Local Delivery';
    if (json['address'] is Map<String, dynamic>) {
      final addr = json['address'] as Map<String, dynamic>;
      addressStr = addr['post_address'] as String? ??
          addr['address'] as String? ??
          addr['name'] as String? ??
          addressStr;
    }

    double parseAmount(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    return OrderModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      orderId: json['order_id'] as String? ?? '#${json['_id']?.toString().substring(0, 6) ?? 'ORD'}',
      amount: parseAmount(json['amount'] ?? json['total_amount']),
      customerName: name,
      customerMobile: mobile,
      customerAddress: addressStr,
      deliveryType: json['delivery_type'] as String? ?? 'Home Delivery',
      paymentType: json['payment_type'] as String? ?? 'COD',
      orderedAt: json['ordered'] as String? ?? json['date'] as String? ?? 'Today',
      status: status ?? OrderStatus.newOrder,
      isWholesale: json['is_wholesale'] as bool? ?? false,
      notes: json['notes'] is String
          ? json['notes'] as String
          : json['notes'] is Map<String, dynamic>
              ? (json['notes']['notes'] as String?)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'order_id': orderId,
      'amount': amount,
      'customer': {
        'name': customerName,
        'mobile': {'number': customerMobile},
      },
      'address': {'post_address': customerAddress},
      'delivery_type': deliveryType,
      'payment_type': paymentType,
      'ordered': orderedAt,
      'is_wholesale': isWholesale,
    };
  }

  @override
  List<Object?> get props => [
        id,
        orderId,
        amount,
        customerName,
        customerMobile,
        customerAddress,
        deliveryType,
        paymentType,
        orderedAt,
        status,
        isWholesale,
      ];
}

class OrderProductItem extends Equatable {
  final String id;
  final String productName;
  final int quantity;
  final double netPrice;
  final String unit;
  final String? image;

  const OrderProductItem({
    required this.id,
    required this.productName,
    required this.quantity,
    required this.netPrice,
    this.unit = 'unit',
    this.image,
  });

  factory OrderProductItem.fromJson(Map<String, dynamic> json) {
    String? imgUrl;
    if (json['image'] is Map<String, dynamic>) {
      imgUrl = json['image']['image'] as String? ?? json['image']['thumbnail'] as String?;
    } else if (json['image'] is String) {
      imgUrl = json['image'] as String;
    }

    double parsePrice(dynamic p) {
      if (p == null) return 0.0;
      if (p is num) return p.toDouble();
      return double.tryParse(p.toString()) ?? 0.0;
    }

    return OrderProductItem(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      productName: json['product_name'] as String? ?? 'Product',
      quantity: (json['qty'] as num?)?.toInt() ?? 1,
      netPrice: parsePrice(json['net_price'] ?? json['price']),
      unit: json['unit'] as String? ?? 'unit',
      image: imgUrl,
    );
  }

  String get name => productName;
  double get totalPrice => netPrice * quantity;
  String? get imageUrl => image;

  @override
  List<Object?> get props => [id, productName, quantity, netPrice, unit, image];
}

class OrderCountsModel extends Equatable {
  final int newOrders;
  final int acceptedOrders;
  final int readyToShipOrders;
  final int shippingOrders;
  final int deliveredOrders;
  final int cancelledOrders;
  final int escalatedOrders;

  const OrderCountsModel({
    this.newOrders = 0,
    this.acceptedOrders = 0,
    this.readyToShipOrders = 0,
    this.shippingOrders = 0,
    this.deliveredOrders = 0,
    this.cancelledOrders = 0,
    this.escalatedOrders = 0,
  });

  factory OrderCountsModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    return OrderCountsModel(
      newOrders: (data['newOrders'] as num?)?.toInt() ?? 0,
      acceptedOrders: (data['acceptedOrders'] as num?)?.toInt() ?? 0,
      readyToShipOrders:
          ((data['readyToShipOrders'] ?? data['dispatchedOrders']) as num?)
                  ?.toInt() ??
              0,
      shippingOrders: (data['shippingOrders'] as num?)?.toInt() ?? 0,
      deliveredOrders: (data['deliveredOrders'] as num?)?.toInt() ?? 0,
      cancelledOrders: (data['cancelledOrders'] as num?)?.toInt() ?? 0,
      escalatedOrders: (data['escalatedOrders'] as num?)?.toInt() ?? 0,
    );
  }

  int get dispatchedOrders => readyToShipOrders;
  int get totalPending => newOrders + acceptedOrders + readyToShipOrders + shippingOrders;

  int getCountForStatus(OrderStatus status) {
    switch (status) {
      case OrderStatus.newOrder:
        return newOrders;
      case OrderStatus.processing:
        return acceptedOrders;
      case OrderStatus.ready:
        return readyToShipOrders;
      case OrderStatus.onTheWay:
        return shippingOrders;
      case OrderStatus.delivered:
        return deliveredOrders;
      case OrderStatus.cancelled:
        return cancelledOrders;
      case OrderStatus.replaceRefund:
        return escalatedOrders;
    }
  }

  @override
  List<Object?> get props => [
        newOrders,
        acceptedOrders,
        readyToShipOrders,
        shippingOrders,
        deliveredOrders,
        cancelledOrders,
      ];
}
