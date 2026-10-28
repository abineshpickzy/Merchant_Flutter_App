import 'package:flutter/foundation.dart';

/// Filter selection matching Android StoreBillingFragment (Today, Last 7 Days, Last 30 Days, Custom)
enum BillingFilterType {
  today,
  sevenDays,
  thirtyDays,
  custom,
}

/// Offer information matching Android BillingResponse.Offer
@immutable
class BillingOffer {
  final double offerAmount;
  final bool isOfferApplied;
  final int offerType; // 1 = Cashback, 2 = Discount
  final bool isBayfayOffer;

  const BillingOffer({
    this.offerAmount = 0.0,
    this.isOfferApplied = false,
    this.offerType = 0,
    this.isBayfayOffer = false,
  });

  factory BillingOffer.fromJson(Map<String, dynamic> json) {
    return BillingOffer(
      offerAmount: (json['offerAmount'] as num?)?.toDouble() ?? 0.0,
      isOfferApplied: json['is_offer_applied'] as bool? ?? false,
      offerType: (json['offer_type'] as num?)?.toInt() ?? 0,
      isBayfayOffer: json['is_bayfay_offer'] as bool? ?? false,
    );
  }
}

/// Order transaction detail matching Android BillingResponse.Transaction
@immutable
class BillingTransactionDetail {
  final String id;
  final int type; // 1 = Credit, 2 = Debit
  final int status; // 1 = Pending, 2 = Settled / Credited / Debited
  final double value;
  final double serviceFee;
  final double paymentFee;
  final String expectedAt;
  final String submittedAt;
  final String settledAt;

  const BillingTransactionDetail({
    this.id = '',
    this.type = 1,
    this.status = 1,
    this.value = 0.0,
    this.serviceFee = 0.0,
    this.paymentFee = 0.0,
    this.expectedAt = '',
    this.submittedAt = '',
    this.settledAt = '',
  });

  factory BillingTransactionDetail.fromJson(Map<String, dynamic> json) {
    return BillingTransactionDetail(
      id: json['id']?.toString() ?? '',
      type: (json['type'] as num?)?.toInt() ?? 1,
      status: (json['status'] as num?)?.toInt() ?? 1,
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      serviceFee: (json['service_fee'] as num?)?.toDouble() ?? 0.0,
      paymentFee: (json['payment_fee'] as num?)?.toDouble() ?? 0.0,
      expectedAt: json['expected_at']?.toString() ?? '',
      submittedAt: json['submitted_at']?.toString() ?? '',
      settledAt: json['settled_at']?.toString() ?? '',
    );
  }
}

/// Order data in billing transaction matching Android BillingResponse.Order
@immutable
class BillingOrder {
  final String id;
  final double amount;
  final double serviceFee;
  final int? tipAmount;
  final String paymentType;
  final String orderedAt;
  final String deliveredAt;
  final BillingOffer? offer;
  final BillingTransactionDetail transaction;

  const BillingOrder({
    required this.id,
    this.amount = 0.0,
    this.serviceFee = 0.0,
    this.tipAmount,
    this.paymentType = '',
    this.orderedAt = '',
    this.deliveredAt = '',
    this.offer,
    required this.transaction,
  });

  factory BillingOrder.fromJson(Map<String, dynamic> json) {
    return BillingOrder(
      id: json['id']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      serviceFee: (json['service_fee'] as num?)?.toDouble() ?? 0.0,
      tipAmount: (json['tip_amount'] as num?)?.toInt(),
      paymentType: json['payment_type']?.toString() ?? '',
      orderedAt: json['ordered_at']?.toString() ?? '',
      deliveredAt: json['delivered_at']?.toString() ?? '',
      offer: json['offer'] is Map<String, dynamic>
          ? BillingOffer.fromJson(json['offer'] as Map<String, dynamic>)
          : null,
      transaction: json['transaction'] is Map<String, dynamic>
          ? BillingTransactionDetail.fromJson(json['transaction'] as Map<String, dynamic>)
          : const BillingTransactionDetail(),
    );
  }
}

/// Shop data in billing transaction matching Android BillingResponse.Shop
@immutable
class BillingShop {
  final String name;
  final String location;
  final String? privateIcon;
  final String? categoryIcon;

  const BillingShop({
    this.name = '',
    this.location = '',
    this.privateIcon,
    this.categoryIcon,
  });

  factory BillingShop.fromJson(Map<String, dynamic> json) {
    return BillingShop(
      name: json['name']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      privateIcon: (json['private_icon'] ?? json['privateIcon'])?.toString(),
      categoryIcon: (json['category_icon'] ?? json['categoryIcon'] ?? json['category_image'] ?? json['image'])?.toString(),
    );
  }

  /// Resolves the authenticated category/shop image URL matching Android BaseActivity.loadCategoryImage
  String getImageUrl(String baseUrl) {
    final file = (privateIcon != null && privateIcon!.isNotEmpty)
        ? privateIcon
        : categoryIcon;
    if (file == null || file.isEmpty) return '';

    final clean = file.replaceAll('file:///', '').trim();
    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      return clean;
    }

    final normalizedBaseUrl = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    return '${normalizedBaseUrl}merchant/category/image?width=200&height=200&file=$clean';
  }
}

/// Single transaction item matching Android BillingResponse.Transactions
@immutable
class BillingTransaction {
  final String id;
  final BillingShop shop;
  final BillingOrder order;

  const BillingTransaction({
    required this.id,
    required this.shop,
    required this.order,
  });

  factory BillingTransaction.fromJson(Map<String, dynamic> json) {
    return BillingTransaction(
      id: json['_id']?.toString() ?? '',
      shop: json['shop'] is Map<String, dynamic>
          ? BillingShop.fromJson(json['shop'] as Map<String, dynamic>)
          : const BillingShop(),
      order: json['order'] is Map<String, dynamic>
          ? BillingOrder.fromJson(json['order'] as Map<String, dynamic>)
          : const BillingOrder(id: '', transaction: BillingTransactionDetail()),
    );
  }
}

/// Accounts summary metrics model matching Android TransactionDetails.Data
@immutable
class BillingSummaryModel {
  final double balance;
  final double debitsSettled;
  final double debitsPending;
  final double creditsSettled;
  final double creditsPending;
  final int orderCount;

  const BillingSummaryModel({
    this.balance = 0.0,
    this.debitsSettled = 0.0,
    this.debitsPending = 0.0,
    this.creditsSettled = 0.0,
    this.creditsPending = 0.0,
    this.orderCount = 0,
  });

  factory BillingSummaryModel.fromJson(Map<String, dynamic> json) {
    final debits = json['debits'] as Map<String, dynamic>?;
    final credits = json['credits'] as Map<String, dynamic>?;

    return BillingSummaryModel(
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      debitsSettled: (debits?['settled'] as num?)?.toDouble() ?? 0.0,
      debitsPending: (debits?['pending'] as num?)?.toDouble() ?? 0.0,
      creditsSettled: (credits?['settled'] as num?)?.toDouble() ?? 0.0,
      creditsPending: (credits?['pending'] as num?)?.toDouble() ?? 0.0,
      orderCount: (credits?['order_count'] as num?)?.toInt() ?? 0,
    );
  }
}

/// UI State for Billing Tab Screen
@immutable
class BillingState {
  final BillingFilterType filterType;
  final DateTime fromDate;
  final DateTime toDate;
  final List<BillingTransaction> transactions;
  final BillingSummaryModel? summary;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int skip;
  final String? error;

  const BillingState({
    required this.filterType,
    required this.fromDate,
    required this.toDate,
    this.transactions = const [],
    this.summary,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.skip = 0,
    this.error,
  });

  BillingState copyWith({
    BillingFilterType? filterType,
    DateTime? fromDate,
    DateTime? toDate,
    List<BillingTransaction>? transactions,
    BillingSummaryModel? summary,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? skip,
    String? error,
  }) {
    return BillingState(
      filterType: filterType ?? this.filterType,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      transactions: transactions ?? this.transactions,
      summary: summary ?? this.summary,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      skip: skip ?? this.skip,
      error: error,
    );
  }
}
