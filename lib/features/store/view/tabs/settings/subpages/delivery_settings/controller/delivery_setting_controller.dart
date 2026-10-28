import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayfay_merchant_flutter/features/dashboard/model/store_model.dart';
import '../model/delivery_setting_model.dart';
import '../repository/delivery_setting_repository.dart';

final storeDeliverySettingControllerProvider = StateNotifierProvider.autoDispose
    .family<StoreDeliverySettingController, StoreDeliverySettingState,
        StoreModel>((ref, store) {
  final repo = ref.read(storeDeliverySettingRepositoryProvider);
  return StoreDeliverySettingController(repo: repo, store: store);
});

class StoreDeliverySettingController
    extends StateNotifier<StoreDeliverySettingState> {
  final StoreDeliverySettingRepository _repo;
  final StoreModel _store;

  StoreDeliverySettingController({
    required StoreDeliverySettingRepository repo,
    required StoreModel store,
  })  : _repo = repo,
        _store = store,
        super(const StoreDeliverySettingState()) {
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final config = await _repo.getDeliveryConfig(
      shopId: _store.id,
      categoryId: _store.categoryId,
    );

    if (config == null) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load delivery settings',
      );
      return;
    }

    state = state.copyWith(
      isLoading: false,
      replacementDays: config.replacementDays,
      refundDays: config.refundDays,
      maxRadius: config.maxRadius,
      currentRadius: config.currentRadius,
      fromTime: config.fromTime,
      toTime: config.toTime,
      localDeliveryTypes: config.localDeliveryTypes,
      deliveryFee: config.deliveryFee,
      deliveryFeeLimit: config.deliveryFeeLimit,
      perKmFee: config.perKmFee,
      deliveryFeeSubscription: config.deliveryFeeSubscription,
      isLimitApplied: config.isLimitApplied,
      isCodEnabled: config.isCodEnabled,
      codLimitType: config.codLimitType,
      codLimit: config.codLimit,
      isOnlinePaymentEnabled: config.isOnlinePaymentEnabled,
      availability: config.availability,
      isOtherLocationEnabled: config.isOtherLocationEnabled,
      isOtherLocked: config.isOtherLocked,
      otherDeliveryTypes: config.otherDeliveryTypes,
      otherDeliveryFee: config.otherDeliveryFee,
      otherDeliveryFeeLimit: config.otherDeliveryFeeLimit,
      isPrivateEnabled: config.isPrivateEnabled,
      isWholesale: config.isWholesale,
    );
  }

  void setReplacementDays(int days) {
    state = state.copyWith(replacementDays: days);
  }

  void setRefundDays(int days) {
    state = state.copyWith(refundDays: days);
  }

  void setCurrentRadius(int radius) {
    state = state.copyWith(currentRadius: radius);
  }

  void setFromTime(String time) {
    state = state.copyWith(fromTime: time);
  }

  void setToTime(String time) {
    state = state.copyWith(toTime: time);
  }

  void toggleLocalDeliveryType(int type) {
    final current = List<int>.from(state.localDeliveryTypes);
    if (current.contains(type)) {
      if (current.length > 1) {
        current.remove(type);
      }
    } else {
      current.add(type);
    }
    state = state.copyWith(localDeliveryTypes: current);
  }

  void setDeliveryFee(int fee) {
    state = state.copyWith(deliveryFee: fee);
  }

  void setDeliveryFeeLimit(int limit) {
    state = state.copyWith(deliveryFeeLimit: limit);
  }

  void setPerKmFee(int fee) {
    state = state.copyWith(perKmFee: fee);
  }

  void setDeliveryFeeSubscription(bool val) {
    state = state.copyWith(deliveryFeeSubscription: val);
  }

  void setIsLimitApplied(bool val) {
    state = state.copyWith(isLimitApplied: val);
  }

  bool setCodEnabled(bool enabled) {
    if (!enabled && !state.isOnlinePaymentEnabled) {
      return false; // Error: both cannot be turned off
    }
    state = state.copyWith(isCodEnabled: enabled);
    return true;
  }

  void setCodLimitType(String type) {
    state = state.copyWith(codLimitType: type);
  }

  void setCodLimit(int limit) {
    state = state.copyWith(codLimit: limit);
  }

  bool setOnlinePaymentEnabled(bool enabled) {
    if (!enabled && !state.isCodEnabled) {
      return false; // Error: both cannot be turned off
    }
    state = state.copyWith(isOnlinePaymentEnabled: enabled);
    return true;
  }

  void toggleAvailabilityDay(String day) {
    final current = List<String>.from(state.availability);
    if (current.contains(day)) {
      if (current.length > 1) {
        current.remove(day);
      }
    } else {
      current.add(day);
    }
    state = state.copyWith(availability: current);
  }

  void setOtherLocationEnabled(bool val) {
    state = state.copyWith(isOtherLocationEnabled: val);
  }

  void toggleOtherDeliveryType(int type) {
    final current = List<int>.from(state.otherDeliveryTypes);
    if (current.contains(type)) {
      if (current.length > 1) {
        current.remove(type);
      }
    } else {
      current.add(type);
    }
    state = state.copyWith(otherDeliveryTypes: current);
  }

  void setOtherDeliveryFee(int fee) {
    state = state.copyWith(otherDeliveryFee: fee);
  }

  void setOtherDeliveryFeeLimit(int limit) {
    state = state.copyWith(otherDeliveryFeeLimit: limit);
  }

  void setPrivateEnabled(bool val) {
    state = state.copyWith(isPrivateEnabled: val);
  }

  /// Save delivery configuration matching Android sendDataToServer
  Future<({bool success, String message})> saveDeliveryConfig() async {
    if (!state.isCodEnabled && !state.isOnlinePaymentEnabled) {
      return (
        success: false,
        message: 'Both cash on delivery and online payment cannot be turned off'
      );
    }

    if (state.localDeliveryTypes.isEmpty) {
      return (
        success: false,
        message: 'Please check delivery type in nearby locations'
      );
    }

    if (state.availability.isEmpty) {
      return (
        success: false,
        message: 'Please select shop availability'
      );
    }

    if (state.isOtherLocationEnabled) {
      if (state.otherDeliveryTypes.isEmpty) {
        return (
          success: false,
          message: 'Please select delivery type in other locations'
        );
      }
      if (state.otherDeliveryFee > 0 && state.otherDeliveryFeeLimit == 0) {
        return (
          success: false,
          message: 'Please enter valid other location delivery charges limit'
        );
      }
    }

    // Prepare payload matching Android sendDataToServer
    final dataPayload = <String, dynamic>{
      'refund_days': state.refundDays,
      'replacement_days': state.replacementDays,
      'delivery_local_radius': state.currentRadius,
      'delivery_local_type': state.localDeliveryTypes,
      'delivery_local_from': state.fromTime,
      'delivery_local_to': state.toTime,
      'delivery_local_fee': state.deliveryFee,
      'delivery_local_fee_limit': state.deliveryFeeLimit,
      'delivery_per_km': state.perKmFee,
      'delivery_charge_for_subs': state.deliveryFeeSubscription,
      'limit_applied': state.isLimitApplied,
      'delivery_local_is_cod': state.isCodEnabled,
      'delivery_local_is_cod_limit_type': state.codLimitType,
      'delivery_local_is_cod_limit':
          state.codLimitType == 'limit' ? state.codLimit : 0,
      'delivery_local_is_online_payment': state.isOnlinePaymentEnabled,
      'availability': state.availability,
      'delivery_other_is_enabled': state.isOtherLocationEnabled,
      'delivery_other_type': state.otherDeliveryTypes,
      'delivery_other_is_cod': state.isOtherLocationEnabled,
      'delivery_other_fee':
          state.isOtherLocationEnabled ? state.otherDeliveryFee : 0,
      'delivery_other_fee_limit':
          state.isOtherLocationEnabled ? state.otherDeliveryFeeLimit : 0,
      'private_request': state.isPrivateEnabled,
    };

    state = state.copyWith(isSaving: true, errorMessage: null);

    final res = await _repo.saveDeliveryConfig(
      shopId: _store.id,
      categoryId: _store.categoryId,
      dataPayload: dataPayload,
    );

    state = state.copyWith(isSaving: false);

    if (res.success) {
      state = state.copyWith(successMessage: res.message);
    } else {
      state = state.copyWith(errorMessage: res.message);
    }

    return (success: res.success, message: res.message);
  }
}
