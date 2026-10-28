// Model for Additional Settings (1:1 with Android AdditionalSettingsReq & SettingDelivery)

class ShopTimingSlot {
  final String startTime;
  final String endTime;

  const ShopTimingSlot({required this.startTime, required this.endTime});

  ShopTimingSlot copyWith({String? startTime, String? endTime}) {
    return ShopTimingSlot(
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }

  Map<String, dynamic> toJson() => {
        'start_time': startTime,
        'end_time': endTime,
      };
}

class AdditionalSettingsState {
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final String? successMessage;
  final double packagePrice;
  final int pricingType; // 1 = INR, 2 = Percentage
  final int? minLimit;
  final bool agencyResponsibility;
  final bool allowAutoOpenClose;
  final bool isAutomaticShopTiming;
  final List<ShopTimingSlot> timingSlots;

  const AdditionalSettingsState({
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.successMessage,
    this.packagePrice = 0.0,
    this.pricingType = 2, // default % (Percentage) per Android
    this.minLimit,
    this.agencyResponsibility = false,
    this.allowAutoOpenClose = true,
    this.isAutomaticShopTiming = false,
    this.timingSlots = const [],
  });

  AdditionalSettingsState copyWith({
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    String? successMessage,
    double? packagePrice,
    int? pricingType,
    int? minLimit,
    bool? agencyResponsibility,
    bool? allowAutoOpenClose,
    bool? isAutomaticShopTiming,
    List<ShopTimingSlot>? timingSlots,
  }) {
    return AdditionalSettingsState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
      successMessage: successMessage,
      packagePrice: packagePrice ?? this.packagePrice,
      pricingType: pricingType ?? this.pricingType,
      minLimit: minLimit ?? this.minLimit,
      agencyResponsibility: agencyResponsibility ?? this.agencyResponsibility,
      allowAutoOpenClose: allowAutoOpenClose ?? this.allowAutoOpenClose,
      isAutomaticShopTiming:
          isAutomaticShopTiming ?? this.isAutomaticShopTiming,
      timingSlots: timingSlots ?? this.timingSlots,
    );
  }
}
