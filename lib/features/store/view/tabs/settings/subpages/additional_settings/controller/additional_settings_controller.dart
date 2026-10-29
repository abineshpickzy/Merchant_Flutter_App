import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayfay_merchant_flutter/features/dashboard/model/store_model.dart';
import '../model/additional_settings_model.dart';
import '../repository/additional_settings_repository.dart';

final additionalSettingsControllerProvider = StateNotifierProvider.autoDispose
    .family<AdditionalSettingsController, AdditionalSettingsState, StoreModel>(
  (ref, store) {
    final repo = ref.read(additionalSettingsRepositoryProvider);
    return AdditionalSettingsController(repo: repo, store: store);
  },
);

class AdditionalSettingsController
    extends StateNotifier<AdditionalSettingsState> {
  final AdditionalSettingsRepository _repo;
  final StoreModel _store;

  AdditionalSettingsController({
    required AdditionalSettingsRepository repo,
    required StoreModel store,
  })  : _repo = repo,
        _store = store,
        super(const AdditionalSettingsState()) {
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final res = await _repo.getAdditionalSettings(
      shopId: _store.id,
      categoryId: _store.categoryId,
    );

    if (!mounted) return;

    if (res == null) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load additional settings',
      );
      return;
    }

    state = state.copyWith(
      isLoading: false,
      packagePrice: res.packagePrice,
      pricingType: res.pricingType,
      minLimit: res.minLimit,
      agencyResponsibility: res.agencyResponsibility,
      allowAutoOpenClose: res.allowAutoOpenClose,
      isAutomaticShopTiming: res.isAutomatic,
      timingSlots: res.timingSlots.isNotEmpty
          ? res.timingSlots
          : (res.isAutomatic
              ? [const ShopTimingSlot(startTime: '', endTime: '')]
              : []),
    );
  }

  void setPricingType(int type) {
    state = state.copyWith(pricingType: type);
  }

  void setPackagePrice(double price) {
    state = state.copyWith(packagePrice: price);
  }

  void setMinLimit(int? limit) {
    state = state.copyWith(minLimit: limit);
  }

  void setAgencyResponsibility(bool val) {
    state = state.copyWith(agencyResponsibility: val);
  }

  void setAutomaticShopTiming(bool val) {
    var slots = List<ShopTimingSlot>.from(state.timingSlots);
    if (val && slots.isEmpty) {
      slots.add(const ShopTimingSlot(startTime: '', endTime: ''));
    }
    state = state.copyWith(
      isAutomaticShopTiming: val,
      timingSlots: slots,
    );
  }

  bool addTimeSlot() {
    for (final slot in state.timingSlots) {
      if (slot.startTime.isEmpty || slot.endTime.isEmpty) {
        return false;
      }
    }
    final slots = List<ShopTimingSlot>.from(state.timingSlots)
      ..add(const ShopTimingSlot(startTime: '', endTime: ''));
    state = state.copyWith(timingSlots: slots);
    return true;
  }

  void removeTimeSlot(int index) {
    if (index >= 0 && index < state.timingSlots.length) {
      final slots = List<ShopTimingSlot>.from(state.timingSlots)..removeAt(index);
      state = state.copyWith(timingSlots: slots);
    }
  }

  void updateTimeSlot(int index, {String? startTime, String? endTime}) {
    if (index >= 0 && index < state.timingSlots.length) {
      final slots = List<ShopTimingSlot>.from(state.timingSlots);
      slots[index] = slots[index].copyWith(
        startTime: startTime,
        endTime: endTime,
      );
      state = state.copyWith(timingSlots: slots);
    }
  }

  Future<({bool success, String message})> saveSettings() async {
    if (state.packagePrice <= 0 && !state.agencyResponsibility) {
      return (success: false, message: 'Please enter package price');
    }

    if (state.isAutomaticShopTiming) {
      for (final slot in state.timingSlots) {
        if (slot.startTime.isEmpty || slot.endTime.isEmpty) {
          return (
            success: false,
            message: 'Enter Shop Open / Close Time for all slots'
          );
        }
      }
    }

    state = state.copyWith(isSaving: true, errorMessage: null);

    final res = await _repo.saveAdditionalSettings(
      shopId: _store.id,
      categoryId: _store.categoryId,
      packagePrice: state.packagePrice,
      pricingType: state.pricingType,
      minLimit: state.minLimit,
      agencyResponsibility: state.agencyResponsibility,
      isAutomatic: state.isAutomaticShopTiming,
      timingSlots: state.timingSlots,
    );

    if (!mounted) return (success: false, message: '');
    state = state.copyWith(isSaving: false);

    if (res.success) {
      state = state.copyWith(successMessage: res.message);
    } else {
      state = state.copyWith(errorMessage: res.message);
    }

    return (success: res.success, message: res.message);
  }
}
