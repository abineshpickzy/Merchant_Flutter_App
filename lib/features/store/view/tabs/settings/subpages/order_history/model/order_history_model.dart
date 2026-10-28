import 'package:bayfay_merchant_flutter/core/network/api_endpoints.dart';

enum OrderHistoryFilterType {
  today,
  sevenDays,
  thirtyDays,
  custom,
}

class OrderHistoryCustomer {
  final String name;
  final String image;
  final String mobileNumber;

  const OrderHistoryCustomer({
    this.name = '',
    this.image = '',
    this.mobileNumber = '',
  });

  factory OrderHistoryCustomer.fromJson(Map<String, dynamic> json) {
    String phone = '';
    if (json['mobile'] is Map<String, dynamic>) {
      final mob = json['mobile'] as Map<String, dynamic>;
      phone = (mob['number'] ?? '').toString();
    }
    return OrderHistoryCustomer(
      name: (json['name'] ?? '').toString(),
      image: (json['image'] ?? '').toString(),
      mobileNumber: phone,
    );
  }

  String getAvatarUrl(String baseUrl) {
    if (image.isEmpty) return '';
    return ApiEndpoints.customerImageUrl(image);
  }
}

class OrderHistoryItem {
  final String id;
  final String orderId;
  final String categoryId;
  final String storeId;
  final int status;
  final bool isPrivate;
  final bool isEscalatedOrder;
  final String paymentType;
  final String deliveryType;
  final String categoryType;
  final double amount;
  final int tipAmount;
  final double distance;
  final int rating;
  final String ordered;
  final String accepted;
  final String readyToShip;
  final String shipping;
  final String delivered;
  final String verified;
  final String cancelled;
  final String rejected;
  final OrderHistoryCustomer? customer;

  const OrderHistoryItem({
    this.id = '',
    this.orderId = '',
    this.categoryId = '',
    this.storeId = '',
    this.status = 0,
    this.isPrivate = false,
    this.isEscalatedOrder = false,
    this.paymentType = '',
    this.deliveryType = '',
    this.categoryType = '',
    this.amount = 0.0,
    this.tipAmount = 0,
    this.distance = 0.0,
    this.rating = 0,
    this.ordered = '',
    this.accepted = '',
    this.readyToShip = '',
    this.shipping = '',
    this.delivered = '',
    this.verified = '',
    this.cancelled = '',
    this.rejected = '',
    this.customer,
  });

  factory OrderHistoryItem.fromJson(Map<String, dynamic> json) {
    return OrderHistoryItem(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      orderId: (json['order_id'] ?? json['orderId'] ?? '').toString(),
      categoryId: (json['category_id'] ?? '').toString(),
      storeId: (json['store_id'] ?? '').toString(),
      status: (json['status'] as num?)?.toInt() ?? 0,
      isPrivate: json['is_private'] == true,
      isEscalatedOrder: json['is_escalated_order'] == true,
      paymentType: (json['payment_type'] ?? '').toString(),
      deliveryType: (json['delivery_type'] ?? '').toString(),
      categoryType: (json['category_type'] ?? '').toString(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      tipAmount: (json['tip_amount'] as num?)?.toInt() ?? 0,
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      ordered: (json['ordered'] ?? '').toString(),
      accepted: (json['accepted'] ?? '').toString(),
      readyToShip: (json['ready_to_ship'] ?? '').toString(),
      shipping: (json['shipping'] ?? '').toString(),
      delivered: (json['delivered'] ?? '').toString(),
      verified: (json['verified'] ?? '').toString(),
      cancelled: (json['cancelled'] ?? '').toString(),
      rejected: (json['rejected'] ?? '').toString(),
      customer: json['customer'] is Map<String, dynamic>
          ? OrderHistoryCustomer.fromJson(json['customer'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Status display label and color matching Android OrderHistoryAdapter
  ({String label, int colorHex, String timestampLabel}) get statusInfo {
    switch (status) {
      case 1:
        return (label: 'New Order', colorHex: 0xFF64C6F8, timestampLabel: 'Ordered at: $ordered');
      case 2:
        return (label: 'Packaging', colorHex: 0xFF64C6F8, timestampLabel: 'Packaged at: $accepted');
      case 3:
        return (label: 'Dispatched', colorHex: 0xFF64C6F8, timestampLabel: 'Dispatched at: $readyToShip');
      case 4:
        return (label: 'On the way', colorHex: 0xFF64C6F8, timestampLabel: 'Shipping at: $shipping');
      case 5:
        return (label: 'Not Verified', colorHex: 0xFF64C6F8, timestampLabel: 'Delivered at: $delivered');
      case 6:
        return (label: 'Verified', colorHex: 0xFF4CAF50, timestampLabel: 'Delivered at: $verified');
      case 7:
        return (label: 'Cancelled by customer', colorHex: 0xFFEE0000, timestampLabel: 'Cancelled at: $cancelled');
      case 8:
        return (label: 'Rejected by shop', colorHex: 0xFFEE0000, timestampLabel: 'Rejected at: $rejected');
      case 9:
        return (label: 'Denied by admin', colorHex: 0xFFEE0000, timestampLabel: 'Denied at: $cancelled');
      default:
        return (label: 'Order', colorHex: 0xFF757575, timestampLabel: ordered);
    }
  }
}

class OrderHistoryState {
  final bool isLoading;
  final bool isLoadingMore;
  final List<OrderHistoryItem> orders;
  final int totalCount;
  final OrderHistoryFilterType activeFilter;
  final DateTime fromDate;
  final DateTime toDate;
  final String? errorMessage;

  const OrderHistoryState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.orders = const [],
    this.totalCount = 0,
    this.activeFilter = OrderHistoryFilterType.today,
    required this.fromDate,
    required this.toDate,
    this.errorMessage,
  });

  OrderHistoryState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    List<OrderHistoryItem>? orders,
    int? totalCount,
    OrderHistoryFilterType? activeFilter,
    DateTime? fromDate,
    DateTime? toDate,
    String? errorMessage,
    bool clearError = false,
  }) {
    return OrderHistoryState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      orders: orders ?? this.orders,
      totalCount: totalCount ?? this.totalCount,
      activeFilter: activeFilter ?? this.activeFilter,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
