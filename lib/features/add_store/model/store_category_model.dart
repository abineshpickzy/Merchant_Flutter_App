import 'package:equatable/equatable.dart';

/// Represents one entry in the `GET merchant/category/{id}` → `categories[]` array.
/// Matches `CategoryTypeResponse.Categories` from Android.
class StoreCategoryModel extends Equatable {
  final String id;
  final String displayName;
  final bool replacementAccepted;
  final int replacementDays;
  final bool refundAccepted;
  final int refundDays;
  final int? maxDeliveryRadius;
  final bool? isCod;
  final bool? isOnlinePayment;
  final bool isOtherDeliverySupported;

  const StoreCategoryModel({
    required this.id,
    required this.displayName,
    this.replacementAccepted = true,
    this.replacementDays = 1,
    this.refundAccepted = true,
    this.refundDays = 1,
    this.maxDeliveryRadius,
    this.isCod,
    this.isOnlinePayment,
    this.isOtherDeliverySupported = true,
  });

  factory StoreCategoryModel.fromJson(Map<String, dynamic> json) {
    final settings = json['settings'] as Map<String, dynamic>?;
    final general = settings?['general'] as Map<String, dynamic>?;

    final rep = general?['replacement'] as Map<String, dynamic>?;
    final ref = general?['refund'] as Map<String, dynamic>?;
    final delivery = general?['delivery'] as Map<String, dynamic>?;
    final local = delivery?['local'] as Map<String, dynamic>?;
    final other = delivery?['other'] as Map<String, dynamic>?;

    final repAccepted = rep?['is_accepted'] as bool? ?? true;
    final repDays = (rep?['days'] as num?)?.toInt() ?? 1;

    final refAccepted = ref?['is_accepted'] as bool? ?? true;
    final refDays = (ref?['days'] as num?)?.toInt() ?? 1;

    final radius = (local?['radius'] as num?)?.toInt();
    final isCod = local?['is_cod'] as bool?;
    final isOnlinePayment = local?['is_online_payment'] as bool?;
    final isOtherDeliveryEnabled = other?['is_enabled'] as bool? ?? true;

    return StoreCategoryModel(
      id: json['_id'] as String? ?? '',
      displayName: json['display_name'] as String? ?? json['name'] as String? ?? '',
      replacementAccepted: repAccepted,
      replacementDays: repDays,
      refundAccepted: refAccepted,
      refundDays: refDays,
      maxDeliveryRadius: radius,
      isCod: isCod,
      isOnlinePayment: isOnlinePayment,
      isOtherDeliverySupported: isOtherDeliveryEnabled,
    );
  }

  /// Calculates duration options using the legacy Android loop algorithm:
  /// for (int i = 1; i < 4; i++) { days += baseDays * i; ... }
  /// followed by 3 Months (90), 6 Months (180), 1 Year (365).
  static Map<int, String> computeDurationOptions(int baseDays) {
    if (baseDays <= 0) return {};
    final Map<int, String> options = {};
    int days = 0;
    for (int i = 1; i < 4; i++) {
      days += baseDays * i;
      if (days == 30) {
        options[days] = '1 Month';
      } else if (days == 1) {
        options[days] = '1 Day';
      } else {
        options[days] = '$days Days';
      }
    }
    options[90] = '3 Months';
    options[180] = '6 Months';
    options[365] = '1 Year';
    return options;
  }

  @override
  List<Object?> get props => [
        id,
        displayName,
        replacementAccepted,
        replacementDays,
        refundAccepted,
        refundDays,
        maxDeliveryRadius,
        isCod,
        isOnlinePayment,
        isOtherDeliverySupported,
      ];
}
