import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayfay_merchant_flutter/app/providers/auth_state_provider.dart';
import 'package:bayfay_merchant_flutter/features/dashboard/model/store_model.dart';
import '../model/store_details_setting_model.dart';
import '../repository/store_details_setting_repository.dart';

final storeDetailsSettingControllerProvider = StateNotifierProvider.autoDispose
    .family<StoreDetailsSettingController, StoreDetailsSettingState, StoreModel>(
  (ref, store) {
    final repo = ref.read(storeDetailsSettingRepositoryProvider);
    final authState = ref.read(authStateProvider);
    int? registeredPhone;
    if (authState is AuthAuthenticated) {
      registeredPhone = authState.profile?.mobileNumber;
    }
    return StoreDetailsSettingController(
      repo: repo,
      store: store,
      registeredMerchantPhone: registeredPhone,
    );
  },
);

class StoreDetailsSettingController
    extends StateNotifier<StoreDetailsSettingState> {
  final StoreDetailsSettingRepository _repo;
  final StoreModel _store;
  final int? _registeredMerchantPhone;

  StoreDetailsSettingController({
    required StoreDetailsSettingRepository repo,
    required StoreModel store,
    int? registeredMerchantPhone,
  })  : _repo = repo,
        _store = store,
        _registeredMerchantPhone = registeredMerchantPhone,
        super(StoreDetailsSettingState(displayName: store.displayName)) {
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final details = await _repo.getSettingLocation(
      shopId: _store.id,
      categoryId: _store.categoryId,
    );

    if (details == null) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load store settings',
      );
      return;
    }

    final countries = await _repo.getCountries();
    List<String> states = [];
    List<String> cities = [];
    final stateCityMap = <String, List<String>>{};

    if (details.country != null && details.country!.isNotEmpty) {
      final locItems = await _repo.getStatesAndCities(details.country!);
      for (final item in locItems) {
        if (!stateCityMap.containsKey(item.state)) {
          stateCityMap[item.state] = [];
        }
        if (!stateCityMap[item.state]!.contains(item.name)) {
          stateCityMap[item.state]!.add(item.name);
        }
      }
      states = stateCityMap.keys.toList()..sort();
      if (details.state != null && stateCityMap.containsKey(details.state)) {
        cities = stateCityMap[details.state]!..sort();
      }
    }

    if (!mounted) return;

    final hasSecMobile = details.secondaryMobile != null &&
        details.secondaryMobile! > 0;
    final hasLandline = details.landlineNumber != null &&
        details.landlineNumber! > 0;

    final secType = hasLandline && !hasSecMobile
        ? SecondaryNumberType.landline
        : SecondaryNumberType.mobile;

    state = state.copyWith(
      isLoading: false,
      displayName: details.displayName.isNotEmpty
          ? details.displayName
          : _store.displayName,
      primaryMobile: details.primaryMobile != null
          ? details.primaryMobile.toString()
          : '',
      isPrimaryVerified: details.primaryVerified,
      initialPrimaryMobile: details.primaryMobile != null
          ? details.primaryMobile.toString()
          : '',
      secondaryType: secType,
      secondaryDialingCode: details.secondaryDialingCode?.toString() ?? '91',
      secondaryMobile: details.secondaryMobile != null &&
              details.secondaryMobile! > 0
          ? details.secondaryMobile.toString()
          : '',
      isSecondaryVerified: details.secondaryVerified,
      initialSecondaryMobile: details.secondaryMobile != null &&
              details.secondaryMobile! > 0
          ? details.secondaryMobile.toString()
          : '',
      secondaryLandlineStd: details.landlineStdCode?.toString() ?? '',
      secondaryLandlineNum: details.landlineNumber?.toString() ?? '',
      streetAddress: details.street ?? '',
      latitude: details.latitude,
      longitude: details.longitude,
      country: details.country,
      state: details.state,
      city: details.city,
      pincode: details.zipcode?.toString() ?? '',
      countries: countries,
      states: states,
      cities: cities,
      stateCityMap: stateCityMap,
    );
  }

  void onStoreNameChanged(String val) {
    state = state.copyWith(displayName: val);
  }

  void onPrimaryMobileChanged(String val) {
    final clean = val.trim();
    final verified = (clean == state.initialPrimaryMobile && clean.isNotEmpty);
    state = state.copyWith(
      primaryMobile: clean,
      isPrimaryVerified: verified,
    );
  }

  void onSecondaryTypeChanged(SecondaryNumberType type) {
    state = state.copyWith(secondaryType: type);
  }

  void onSecondaryMobileChanged(String val) {
    final clean = val.trim();
    final verified =
        (clean == state.initialSecondaryMobile && clean.isNotEmpty);
    state = state.copyWith(
      secondaryMobile: clean,
      isSecondaryVerified: verified,
    );
  }

  void onSecondaryLandlineStdChanged(String val) {
    state = state.copyWith(secondaryLandlineStd: val.trim());
  }

  void onSecondaryLandlineNumChanged(String val) {
    state = state.copyWith(secondaryLandlineNum: val.trim());
  }

  void onPincodeChanged(String val) {
    state = state.copyWith(pincode: val.trim());
  }

  void onStreetAddressChanged(String val) {
    state = state.copyWith(streetAddress: val.trim());
  }

  void updateLocationFromPicked({
    required String street,
    required double lat,
    required double lng,
    String? pincode,
    String? city,
    String? stateName,
    String? countryName,
  }) {
    state = state.copyWith(
      streetAddress: street,
      latitude: lat,
      longitude: lng,
      pincode: (pincode != null && pincode.isNotEmpty) ? pincode : state.pincode,
      city: (city != null && city.isNotEmpty) ? city : state.city,
      state: (stateName != null && stateName.isNotEmpty) ? stateName : state.state,
      country: (countryName != null && countryName.isNotEmpty) ? countryName : state.country,
    );
  }

  /// Request OTP for primary mobile. Returns true if OTP dialog should open, false if auto-verified or error.
  Future<({bool openDialog, String message})> sendOtpPrimary() async {
    final mobileNumStr = state.primaryMobile.trim();
    if (mobileNumStr.isEmpty || mobileNumStr.length < 10) {
      return (openDialog: false, message: 'Please enter primary mobile number');
    }

    final number = int.tryParse(mobileNumStr);
    if (number == null) {
      return (openDialog: false, message: 'Invalid mobile number');
    }

    // Matching Android: check if mobile matches registered merchant login phone
    if (_registeredMerchantPhone != null &&
        _registeredMerchantPhone == number) {
      state = state.copyWith(isPrimaryVerified: true);
      return (
        openDialog: false,
        message: 'Primary mobile number automatically verified with profile'
      );
    }

    state = state.copyWith(isSendingOtp: true, errorMessage: null);
    final res = await _repo.sendOtp(dialingCode: 91, number: number);
    if (!mounted) return (openDialog: false, message: '');
    state = state.copyWith(isSendingOtp: false);

    return (openDialog: res.success, message: res.message);
  }

  /// Request OTP for secondary mobile.
  Future<({bool openDialog, String message})> sendOtpSecondary() async {
    final mobileNumStr = state.secondaryMobile.trim();
    if (mobileNumStr.isEmpty || mobileNumStr.length < 10) {
      return (openDialog: false, message: 'Please enter secondary mobile number');
    }

    final number = int.tryParse(mobileNumStr);
    if (number == null) {
      return (openDialog: false, message: 'Invalid secondary mobile number');
    }

    if (_registeredMerchantPhone != null &&
        _registeredMerchantPhone == number) {
      state = state.copyWith(isSecondaryVerified: true);
      return (
        openDialog: false,
        message: 'Secondary mobile number automatically verified with profile'
      );
    }

    state = state.copyWith(isSendingOtp: true, errorMessage: null);
    final res = await _repo.sendOtp(dialingCode: 91, number: number);
    if (!mounted) return (openDialog: false, message: '');
    state = state.copyWith(isSendingOtp: false);

    return (openDialog: res.success, message: res.message);
  }

  /// Verify OTP received by user
  Future<({bool success, String message})> verifyOtp({
    required int otp,
    required bool isPrimary,
  }) async {
    final numberStr =
        isPrimary ? state.primaryMobile.trim() : state.secondaryMobile.trim();
    final number = int.tryParse(numberStr);
    if (number == null) {
      return (success: false, message: 'Invalid phone number');
    }

    state = state.copyWith(isVerifyingOtp: true, errorMessage: null);
    final res = await _repo.verifyOtp(
      dialingCode: 91,
      number: number,
      otp: otp,
    );
    if (!mounted) return (success: false, message: '');
    state = state.copyWith(isVerifyingOtp: false);

    if (res.success) {
      if (isPrimary) {
        state = state.copyWith(
          isPrimaryVerified: true,
          initialPrimaryMobile: state.primaryMobile,
        );
      } else {
        state = state.copyWith(
          isSecondaryVerified: true,
          initialSecondaryMobile: state.secondaryMobile,
        );
      }
    }

    return (success: res.success, message: res.message);
  }

  /// Validates and saves updated store details matching Android sendDataToServer
  Future<({bool success, String message})> saveDetails() async {
    if (state.streetAddress.isEmpty) {
      return (success: false, message: 'Please enter store address');
    }

    if (state.displayName.trim().isEmpty) {
      return (success: false, message: 'Please enter store name');
    }

    if (state.primaryMobile.trim().length < 10) {
      return (
        success: false,
        message: 'Primary Mobile number must have 10 numbers'
      );
    }

    if (state.secondaryType == SecondaryNumberType.landline &&
        state.secondaryLandlineNum.trim().isNotEmpty &&
        state.secondaryLandlineStd.trim().isEmpty) {
      return (success: false, message: 'STD Code missing/Invalid');
    }

    if (state.pincode.trim().length <= 5) {
      return (success: false, message: 'Please enter pin code');
    }

    if (state.country == null || state.country!.isEmpty) {
      return (success: false, message: 'Please select country');
    }

    final dataPayload = <String, dynamic>{
      'display_name': state.displayName.trim(),
    };

    // Primary mobile
    if (state.primaryMobile != state.initialPrimaryMobile &&
        state.primaryMobile.isNotEmpty) {
      dataPayload['mobile_primary'] = {
        'dialing_code': 91,
        'number': int.tryParse(state.primaryMobile) ?? 0,
      };
    }

    // Secondary mobile or landline
    if (state.secondaryType == SecondaryNumberType.mobile &&
        state.secondaryMobile.trim().isNotEmpty) {
      dataPayload['mobile_secondary'] = {
        'dialing_code': 91,
        'number': int.tryParse(state.secondaryMobile) ?? 0,
      };
    } else if (state.secondaryType == SecondaryNumberType.landline &&
        state.secondaryLandlineNum.trim().isNotEmpty) {
      dataPayload['landline'] = {
        'dialing_code': int.tryParse(state.secondaryLandlineStd) ?? 0,
        'number': int.tryParse(state.secondaryLandlineNum) ?? 0,
      };
    }

    state = state.copyWith(isSaving: true, errorMessage: null);

    final res = await _repo.saveStoreDetails(
      shopId: _store.id,
      categoryId: _store.categoryId,
      dataPayload: dataPayload,
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
