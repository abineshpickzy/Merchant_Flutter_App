import 'package:equatable/equatable.dart';

class RefundItemInfo extends Equatable {
  final int id;
  final num amount;
  final int orderCount;

  const RefundItemInfo({
    this.id = 0,
    this.amount = 0,
    this.orderCount = 0,
  });

  factory RefundItemInfo.fromJson(Map<String, dynamic> json, String amountKey) {
    int parseInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    num parseNum(dynamic v) {
      if (v is num) return v;
      if (v is String) return num.tryParse(v) ?? 0;
      return 0;
    }

    return RefundItemInfo(
      id: parseInt(json['_id']),
      amount: parseNum(json[amountKey]),
      orderCount: parseInt(json['order_count']),
    );
  }

  @override
  List<Object?> get props => [id, amount, orderCount];
}

/// Data model encapsulating refund, cancellation, and escalation details from `POST overview/refund`.
class RefundOverviewModel extends Equatable {
  final List<RefundItemInfo> cancelledInfo;
  final List<RefundItemInfo> refundedInfo;
  final List<RefundItemInfo> escalationInfo;

  const RefundOverviewModel({
    this.cancelledInfo = const [],
    this.refundedInfo = const [],
    this.escalationInfo = const [],
  });

  factory RefundOverviewModel.fromJson(Map<String, dynamic> json) {
    List<RefundItemInfo> parseList(dynamic raw, String amountKey) {
      if (raw is List) {
        return raw
            .whereType<Map<String, dynamic>>()
            .map((item) {
              try {
                return RefundItemInfo.fromJson(item, amountKey);
              } catch (_) {
                return const RefundItemInfo();
              }
            })
            .toList();
      }
      return [];
    }

    return RefundOverviewModel(
      cancelledInfo: parseList(json['cancelledInfo'], 'cancelled_amount'),
      refundedInfo: parseList(json['refundedInfo'], 'refunded_amount'),
      escalationInfo: parseList(json['escalationInfo'], 'escalated_amount'),
    );
  }

  num get totalCancelledAmount =>
      cancelledInfo.fold(0, (sum, item) => sum + item.amount);
  int get totalCancelledCount =>
      cancelledInfo.fold(0, (sum, item) => sum + item.orderCount);

  num get totalRefundedAmount =>
      refundedInfo.fold(0, (sum, item) => sum + item.amount);
  int get totalRefundedCount =>
      refundedInfo.fold(0, (sum, item) => sum + item.orderCount);

  num get totalEscalatedAmount =>
      escalationInfo.fold(0, (sum, item) => sum + item.amount);
  int get totalEscalatedCount =>
      escalationInfo.fold(0, (sum, item) => sum + item.orderCount);

  @override
  List<Object?> get props => [cancelledInfo, refundedInfo, escalationInfo];
}
