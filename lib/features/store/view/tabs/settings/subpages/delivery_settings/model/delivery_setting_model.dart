// Model for Store Delivery Configuration (1:1 with Android SettingDelivery & SettingUpdateRequest)

class DeliverySettingOption {
  final int days;
  final String label;

  const DeliverySettingOption({required this.days, required this.label});
}

List<DeliverySettingOption> getDeliveryDaysOptions(int selectedDays) {
  final baseList = <int>[
    0,
    1,
    2,
    3,
    4,
    5,
    7,
    10,
    14,
    15,
    21,
    30,
    60,
    90,
    180,
    365,
  ];
  final set = Set<int>.from(baseList);
  if (selectedDays >= 0) {
    set.add(selectedDays);
  }
  final sorted = set.toList()..sort();
  return sorted.map((d) {
    if (d == 0) return const DeliverySettingOption(days: 0, label: 'None');
    if (d % 365 == 0) {
      final years = d ~/ 365;
      return DeliverySettingOption(
          days: d, label: '$years ${years == 1 ? 'Year' : 'Years'}');
    }
    if (d % 30 == 0) {
      final months = d ~/ 30;
      return DeliverySettingOption(
          days: d, label: '$months ${months == 1 ? 'Month' : 'Months'}');
    }
    return DeliverySettingOption(days: d, label: '$d Days');
  }).toList();
}

class DeliveryConfigData {
  final int replacementDays;
  final int refundDays;
  final int maxRadius;
  final int currentRadius;
  final String fromTime;
  final String toTime;
  final List<int> localDeliveryTypes; // 1 = Shop, 2 = Agency, 3 = Self pickup
  final int deliveryFee;
  final int deliveryFeeLimit;
  final int perKmFee;
  final bool deliveryFeeSubscription;
  final bool isLimitApplied;
  final bool isCodEnabled;
  final String codLimitType; // "any" or "limit"
  final int codLimit;
  final bool isOnlinePaymentEnabled;
  final List<String> availability; // ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
  final bool isOtherLocationEnabled;
  final bool isOtherLocked;
  final List<int> otherDeliveryTypes;
  final int otherDeliveryFee;
  final int otherDeliveryFeeLimit;
  final bool isPrivateEnabled;
  final bool isWholesale;

  const DeliveryConfigData({
    this.replacementDays = 7,
    this.refundDays = 7,
    this.maxRadius = 10,
    this.currentRadius = 5,
    this.fromTime = '09:00',
    this.toTime = '21:00',
    this.localDeliveryTypes = const [1],
    this.deliveryFee = 0,
    this.deliveryFeeLimit = 0,
    this.perKmFee = 0,
    this.deliveryFeeSubscription = false,
    this.isLimitApplied = false,
    this.isCodEnabled = true,
    this.codLimitType = 'any',
    this.codLimit = 0,
    this.isOnlinePaymentEnabled = true,
    this.availability = const ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'],
    this.isOtherLocationEnabled = false,
    this.isOtherLocked = false,
    this.otherDeliveryTypes = const [1],
    this.otherDeliveryFee = 0,
    this.otherDeliveryFeeLimit = 0,
    this.isPrivateEnabled = false,
    this.isWholesale = false,
  });

  factory DeliveryConfigData.fromJson(Map<String, dynamic> json) {
    final settings = json['settings'] as Map<String, dynamic>? ?? {};
    final delivery = json['delivery'] as Map<String, dynamic>? ?? {};
    final local = delivery['local'] as Map<String, dynamic>? ?? {};
    final other = delivery['other'] as Map<String, dynamic>? ?? {};
    final replacement = json['replacement'] as Map<String, dynamic>? ?? {};
    final refund = json['refund'] as Map<String, dynamic>? ?? {};

    final settingsDelivery = settings['delivery'] as Map<String, dynamic>? ?? {};
    final settingsLocal = settingsDelivery['local'] as Map<String, dynamic>? ?? {};
    final maxRad = (settingsLocal['radius'] as num?)?.toInt() ?? 10;

    final avail = json['availability'] as List<dynamic>?;
    final availList = avail != null
        ? avail.map((e) => e.toString().toUpperCase()).toList()
        : <String>['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];

    final localTypes = (local['type'] as List<dynamic>?)
            ?.map((e) => (e as num).toInt())
            .toList() ??
        [1];

    final otherTypes = (other['type'] as List<dynamic>?)
            ?.map((e) => (e as num).toInt())
            .toList() ??
        [1];

    final privShop = json['private_shop'] as Map<String, dynamic>?;

    final replDays = (replacement['days'] as num?)?.toInt() ??
        (json['replacement_days'] as num?)?.toInt() ??
        (json['replacementDays'] as num?)?.toInt() ??
        0;

    final refDays = (refund['days'] as num?)?.toInt() ??
        (json['refund_days'] as num?)?.toInt() ??
        (json['refundDays'] as num?)?.toInt() ??
        0;

    return DeliveryConfigData(
      replacementDays: replDays,
      refundDays: refDays,
      maxRadius: maxRad > 0 ? maxRad : 10,
      currentRadius: (local['radius'] as num?)?.toInt() ?? 5,
      fromTime: local['from']?.toString() ?? '09:00',
      toTime: local['to']?.toString() ?? '21:00',
      localDeliveryTypes: localTypes,
      deliveryFee: (local['fee'] as num?)?.toInt() ?? 0,
      deliveryFeeLimit: (local['fee_limit'] as num?)?.toInt() ?? 0,
      perKmFee: (local['per_km_fee'] as num?)?.toInt() ?? 0,
      deliveryFeeSubscription: local['delivery_fee_subscription'] == true,
      isLimitApplied: local['limit_applied'] == true,
      isCodEnabled: local['is_cod'] != false,
      codLimitType: local['is_cod_limit_type']?.toString().toLowerCase() ?? 'any',
      codLimit: (local['is_cod_limit'] as num?)?.toInt() ?? 0,
      isOnlinePaymentEnabled: local['is_online_payment'] != false,
      availability: availList,
      isOtherLocationEnabled: other['is_enabled'] == true,
      isOtherLocked: other['is_locked'] == true,
      otherDeliveryTypes: otherTypes,
      otherDeliveryFee: (other['fee'] as num?)?.toInt() ?? 0,
      otherDeliveryFeeLimit: (other['fee_limit'] as num?)?.toInt() ?? 0,
      isPrivateEnabled: privShop?['is_enabled'] == true,
      isWholesale: json['is_wholesale'] == true,
    );
  }
}

class StoreDeliverySettingState {
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final String? successMessage;
  final int replacementDays;
  final int refundDays;
  final int maxRadius;
  final int currentRadius;
  final String fromTime;
  final String toTime;
  final List<int> localDeliveryTypes;
  final int deliveryFee;
  final int deliveryFeeLimit;
  final int perKmFee;
  final bool deliveryFeeSubscription;
  final bool isLimitApplied;
  final bool isCodEnabled;
  final String codLimitType; // "any" or "limit"
  final int codLimit;
  final bool isOnlinePaymentEnabled;
  final List<String> availability;
  final bool isOtherLocationEnabled;
  final bool isOtherLocked;
  final List<int> otherDeliveryTypes;
  final int otherDeliveryFee;
  final int otherDeliveryFeeLimit;
  final bool isPrivateEnabled;
  final bool isWholesale;
  final bool hasEditPrivilege;

  const StoreDeliverySettingState({
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.successMessage,
    this.replacementDays = 7,
    this.refundDays = 7,
    this.maxRadius = 10,
    this.currentRadius = 5,
    this.fromTime = '09:00',
    this.toTime = '21:00',
    this.localDeliveryTypes = const [1],
    this.deliveryFee = 0,
    this.deliveryFeeLimit = 0,
    this.perKmFee = 0,
    this.deliveryFeeSubscription = false,
    this.isLimitApplied = false,
    this.isCodEnabled = true,
    this.codLimitType = 'any',
    this.codLimit = 0,
    this.isOnlinePaymentEnabled = true,
    this.availability = const ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'],
    this.isOtherLocationEnabled = false,
    this.isOtherLocked = false,
    this.otherDeliveryTypes = const [1],
    this.otherDeliveryFee = 0,
    this.otherDeliveryFeeLimit = 0,
    this.isPrivateEnabled = false,
    this.isWholesale = false,
    this.hasEditPrivilege = true,
  });

  StoreDeliverySettingState copyWith({
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    String? successMessage,
    int? replacementDays,
    int? refundDays,
    int? maxRadius,
    int? currentRadius,
    String? fromTime,
    String? toTime,
    List<int>? localDeliveryTypes,
    int? deliveryFee,
    int? deliveryFeeLimit,
    int? perKmFee,
    bool? deliveryFeeSubscription,
    bool? isLimitApplied,
    bool? isCodEnabled,
    String? codLimitType,
    int? codLimit,
    bool? isOnlinePaymentEnabled,
    List<String>? availability,
    bool? isOtherLocationEnabled,
    bool? isOtherLocked,
    List<int>? otherDeliveryTypes,
    int? otherDeliveryFee,
    int? otherDeliveryFeeLimit,
    bool? isPrivateEnabled,
    bool? isWholesale,
    bool? hasEditPrivilege,
  }) {
    return StoreDeliverySettingState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
      successMessage: successMessage,
      replacementDays: replacementDays ?? this.replacementDays,
      refundDays: refundDays ?? this.refundDays,
      maxRadius: maxRadius ?? this.maxRadius,
      currentRadius: currentRadius ?? this.currentRadius,
      fromTime: fromTime ?? this.fromTime,
      toTime: toTime ?? this.toTime,
      localDeliveryTypes: localDeliveryTypes ?? this.localDeliveryTypes,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      deliveryFeeLimit: deliveryFeeLimit ?? this.deliveryFeeLimit,
      perKmFee: perKmFee ?? this.perKmFee,
      deliveryFeeSubscription:
          deliveryFeeSubscription ?? this.deliveryFeeSubscription,
      isLimitApplied: isLimitApplied ?? this.isLimitApplied,
      isCodEnabled: isCodEnabled ?? this.isCodEnabled,
      codLimitType: codLimitType ?? this.codLimitType,
      codLimit: codLimit ?? this.codLimit,
      isOnlinePaymentEnabled:
          isOnlinePaymentEnabled ?? this.isOnlinePaymentEnabled,
      availability: availability ?? this.availability,
      isOtherLocationEnabled:
          isOtherLocationEnabled ?? this.isOtherLocationEnabled,
      isOtherLocked: isOtherLocked ?? this.isOtherLocked,
      otherDeliveryTypes: otherDeliveryTypes ?? this.otherDeliveryTypes,
      otherDeliveryFee: otherDeliveryFee ?? this.otherDeliveryFee,
      otherDeliveryFeeLimit:
          otherDeliveryFeeLimit ?? this.otherDeliveryFeeLimit,
      isPrivateEnabled: isPrivateEnabled ?? this.isPrivateEnabled,
      isWholesale: isWholesale ?? this.isWholesale,
      hasEditPrivilege: hasEditPrivilege ?? this.hasEditPrivilege,
    );
  }
}
