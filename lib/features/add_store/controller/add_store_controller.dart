import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../model/create_store_request.dart';
import '../model/location_model.dart';
import '../model/picked_location_data.dart';
import '../model/store_category_model.dart';
import '../model/store_type_model.dart';
import '../model/wholesale_time_slot_model.dart';
import '../repository/add_store_repository.dart';
import 'package:bayfay_merchant_flutter/core/services/geocoding_service.dart';

// ── Flow Enum & State ────────────────────────────────────────────────────────

enum StoreFlow { b2c, d2c, wholesale }

class AddStoreState {
  // Top-Level Flow Type
  final StoreFlow storeFlow;

  // Wizard Navigation
  final int currentStep; // 0, 1, 2
  final int storeKind; // 0 = B2C Retail, 4 = D2C, 1 = Wholesale

  bool get isWholesale => storeFlow == StoreFlow.wholesale;

  // Dropdowns & Metadata
  final List<StoreTypeModel> storeTypes;
  final List<StoreCategoryModel> categories;
  final List<LocationModel> allLocations;
  final List<String> countries;
  final List<String> states;
  final List<LocationModel> cities;

  final StoreTypeModel? selectedType;
  final StoreCategoryModel? selectedCategory;
  final String? selectedCountry;
  final String? selectedState;
  final LocationModel? selectedCity;

  // Fully editable location fields
  final String countryText;
  final String stateText;
  final String cityText;
  final String pincodeText;
  final String selectedCityId;

  // Step 1: Basics, Media & Location
  final String storeName;
  final String categoryDescription;
  final String contactTime;
  final int? primaryNumber;
  final bool isPrimaryVerified;
  final String secondaryType; // 'mobile' | 'landline'
  final int? secondaryNumber;
  final bool isSecondaryVerified;
  final String secCodeText;
  final List<File> images; // Page 1 Media Picker

  final String street;
  final int? pincode;
  final String area;
  final double latitude;
  final double longitude;
  final String formattedAddress;

  // Step 2: Operations & Policies
  final double deliveryRadius;
  final List<int> deliveryDistanceOptions;
  final double deliveryFee;
  final double feeLimit;
  final double perKmFee;
  final bool isDeliveryFeeSubs;
  final bool isCod;
  final bool isCodEnabled; // Whether COD switch is interactive (driven by category's is_cod)
  final String codLimitType; // 'any' | 'limit'
  final double codLimit;
  final bool isOnlinePayment;
  final bool isOnlinePaymentEnabled; // Whether Online Payment switch is interactive (driven by category's is_online_payment)
  final bool replacementAccepted;
  final int replacementDays;
  final bool refundAccepted;
  final int refundDays;
  final List<String> availability;
  final String deliveryFrom;
  final String deliveryTo;

  // Wholesale specific: fulfillment options & time slots
  final List<int> deliveryTypes; // 1 = Own Delivery, 2 = 3rd party associate, 3 = Self pickup
  final List<String> availableTimeSlots;
  final List<String> selectedTimeSlots;
  final List<WholesaleTimeSlotModel> wholesaleTimeSlots;
  final bool isLimitApplied;

  // Step 3: Extended Delivery, Privacy & Terms
  final bool otherDeliveryEnabled;
  final double otherDeliveryRadius;
  final double otherDeliveryFee;
  final double otherFeeLimit;
  final List<int> otherDeliveryTypes;
  final bool isPrivate;
  final bool termsAccepted;

  // Status
  final bool isLoadingTypes;
  final bool isLoadingCategories;
  final bool isLoadingLocations;
  final bool isSubmitting;
  final bool isSuccess;
  final String? successMessage;
  final String? error;

  const AddStoreState({
    this.storeFlow = StoreFlow.b2c,
    this.currentStep = 0,
    this.storeKind = 0,
    this.storeTypes = const [],
    this.categories = const [],
    this.allLocations = const [],
    this.countries = const [],
    this.states = const [],
    this.cities = const [],
    this.selectedType,
    this.selectedCategory,
    this.selectedCountry,
    this.selectedState,
    this.selectedCity,
    this.countryText = 'India',
    this.stateText = '',
    this.cityText = '',
    this.pincodeText = '',
    this.selectedCityId = '',
    this.storeName = '',
    this.categoryDescription = '',
    this.contactTime = '',
    this.primaryNumber,
    // TODO: RE-ENABLE VALIDATION
    this.isPrimaryVerified = false,
    this.secondaryType = 'mobile',
    this.secondaryNumber,
    // TODO: RE-ENABLE VALIDATION
    this.isSecondaryVerified = false,
    this.secCodeText = '+91',
    this.images = const [],
    this.street = '',
    this.pincode,
    this.area = '',
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.formattedAddress = '',
    this.deliveryRadius = 5,
    this.deliveryDistanceOptions = const [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
    this.deliveryFee = 20,
    this.feeLimit = 500,
    this.perKmFee = 0,
    this.isDeliveryFeeSubs = false,
    this.isCod = true,
    this.isCodEnabled = true,
    this.codLimitType = 'any',
    this.codLimit = 0,
    this.isOnlinePayment = true,
    this.isOnlinePaymentEnabled = true,
    this.replacementAccepted = true,
    this.replacementDays = 1,
    this.refundAccepted = true,
    this.refundDays = 1,
    this.availability = const [
      'Sun',
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
    ],
    this.deliveryFrom = '09:00 AM',
    this.deliveryTo = '09:00 PM',
    this.deliveryTypes = const [2, 3],
    this.availableTimeSlots = const [
      '06:00 AM - 10:00 AM',
      '10:00 AM - 02:00 PM',
      '02:00 PM - 06:00 PM',
      '06:00 PM - 10:00 PM',
    ],
    this.selectedTimeSlots = const [
      '10:00 AM - 02:00 PM',
      '02:00 PM - 06:00 PM',
    ],
    this.wholesaleTimeSlots = const [
      WholesaleTimeSlotModel(id: 'slot_1', slotName: '7 am to 9 am', limit: 0),
      WholesaleTimeSlotModel(id: 'slot_2', slotName: '9 am to 11 am', limit: 0),
      WholesaleTimeSlotModel(id: 'slot_3', slotName: '11 am to 1 pm', limit: 0),
      WholesaleTimeSlotModel(id: 'slot_4', slotName: '1 pm to 3 pm', limit: 0),
      WholesaleTimeSlotModel(id: 'slot_5', slotName: '3 pm to 5 pm', limit: 0),
      WholesaleTimeSlotModel(id: 'slot_6', slotName: '5 pm to 7 pm', limit: 0),
    ],
    this.isLimitApplied = false,
    this.otherDeliveryEnabled = false,
    this.otherDeliveryRadius = 20,
    this.otherDeliveryFee = 60,
    this.otherFeeLimit = 2000,
    this.otherDeliveryTypes = const [1, 1],
    this.isPrivate = true,
    this.termsAccepted = false,
    this.isLoadingTypes = false,
    this.isLoadingCategories = false,
    this.isLoadingLocations = false,
    this.isSubmitting = false,
    this.isSuccess = false,
    this.successMessage,
    this.error,
  });

  /// Whether categories are currently being fetched
  bool get isCategoriesLoading => isLoadingCategories;

  /// Whether the store uses a conditional single-step submission flow ("Others" category under Branded Shop)
  bool get isSingleStepFlow => selectedCategory?.id == 'others';

  /// Whether extended delivery to other locations is supported based on category metadata
  bool get isOtherDeliverySupported =>
      selectedCategory?.isOtherDeliverySupported ?? true;

  /// Whether the store is classified as Branded / Verified / D2C (vs standard Public store)
  bool get isBrandedStore {
    final typeName = selectedType?.name.toLowerCase() ?? '';
    final typeId = selectedType?.id ?? storeKind;
    return typeId == 4 ||
        typeName.contains('brand') ||
        typeName.contains('d2c') ||
        typeName.contains('verified');
  }

  /// Preset durations for standard Public Shop
  static const Map<int, String> publicStoreDurations = {
    1: '1 Day',
    3: '3 Days',
    6: '6 Days',
    30: '1 Month',
    180: '6 Months',
    365: '1 Year',
  };

  /// Preset durations for Branded / Verified / D2C Store
  static const Map<int, String> brandedStoreDurations = {
    5: '5 Days',
    15: '15 Days',
    30: '1 Month',
    90: '3 Months',
    180: '6 Months',
    365: '1 Year',
  };

  /// Helper to compute options from base days using the legacy Android loop formula
  static Map<int, String> computeDurationOptions(int baseDays) =>
      StoreCategoryModel.computeDurationOptions(baseDays);

  /// Dynamic duration presets for Product Replacement dropdown based on selected category
  Map<int, String> get replacementOptions {
    if (selectedCategory != null) {
      final base = selectedCategory!.replacementDays;
      if (base > 0) {
        return computeDurationOptions(base);
      }
    }
    return isBrandedStore ? brandedStoreDurations : publicStoreDurations;
  }

  /// Dynamic duration presets for Refund dropdown based on selected category
  Map<int, String> get refundOptions {
    if (selectedCategory != null) {
      final base = selectedCategory!.refundDays;
      if (base > 0) {
        return computeDurationOptions(base);
      }
    }
    return isBrandedStore ? brandedStoreDurations : publicStoreDurations;
  }

  /// Active duration presets for Replacement and Refund dropdowns
  Map<int, String> get policyOptions => replacementOptions;

  AddStoreState copyWith({
    StoreFlow? storeFlow,
    int? currentStep,
    int? storeKind,
    List<StoreTypeModel>? storeTypes,
    List<StoreCategoryModel>? categories,
    List<LocationModel>? allLocations,
    List<String>? countries,
    List<String>? states,
    List<LocationModel>? cities,
    StoreTypeModel? selectedType,
    StoreCategoryModel? selectedCategory,
    bool clearSelectedCategory = false,
    String? selectedCountry,
    String? selectedState,
    LocationModel? selectedCity,
    String? countryText,
    String? stateText,
    String? cityText,
    String? pincodeText,
    String? selectedCityId,
    String? storeName,
    String? categoryDescription,
    String? contactTime,
    int? primaryNumber,
    bool clearPrimaryNumber = false,
    bool? isPrimaryVerified,
    String? secondaryType,
    int? secondaryNumber,
    bool clearSecondaryNumber = false,
    bool? isSecondaryVerified,
    String? secCodeText,
    List<File>? images,
    String? street,
    int? pincode,
    String? area,
    double? latitude,
    double? longitude,
    String? formattedAddress,
    double? deliveryRadius,
    List<int>? deliveryDistanceOptions,
    double? deliveryFee,
    double? feeLimit,
    double? perKmFee,
    bool? isDeliveryFeeSubs,
    bool? isCod,
    bool? isCodEnabled,
    String? codLimitType,
    double? codLimit,
    bool? isOnlinePayment,
    bool? isOnlinePaymentEnabled,
    bool? replacementAccepted,
    int? replacementDays,
    bool? refundAccepted,
    int? refundDays,
    List<String>? availability,
    String? deliveryFrom,
    String? deliveryTo,
    List<int>? deliveryTypes,
    List<String>? availableTimeSlots,
    List<String>? selectedTimeSlots,
    List<WholesaleTimeSlotModel>? wholesaleTimeSlots,
    bool? isLimitApplied,
    bool? otherDeliveryEnabled,
    double? otherDeliveryRadius,
    double? otherDeliveryFee,
    double? otherFeeLimit,
    List<int>? otherDeliveryTypes,
    bool? isPrivate,
    bool? termsAccepted,
    bool? isLoadingTypes,
    bool? isLoadingCategories,
    bool? isLoadingLocations,
    bool? isSubmitting,
    bool? isSuccess,
    String? successMessage,
    String? error,
    bool clearError = false,
  }) {
    return AddStoreState(
      storeFlow: storeFlow ?? this.storeFlow,
      currentStep: currentStep ?? this.currentStep,
      storeKind: storeKind ?? this.storeKind,
      storeTypes: storeTypes ?? this.storeTypes,
      categories: categories ?? this.categories,
      allLocations: allLocations ?? this.allLocations,
      countries: countries ?? this.countries,
      states: states ?? this.states,
      cities: cities ?? this.cities,
      selectedType: selectedType ?? this.selectedType,
      selectedCategory:
          clearSelectedCategory ? null : (selectedCategory ?? this.selectedCategory),
      selectedCountry: selectedCountry ?? this.selectedCountry,
      selectedState: selectedState ?? this.selectedState,
      selectedCity: selectedCity ?? this.selectedCity,
      countryText: countryText ?? this.countryText,
      stateText: stateText ?? this.stateText,
      cityText: cityText ?? this.cityText,
      pincodeText: pincodeText ?? this.pincodeText,
      selectedCityId: selectedCityId ?? this.selectedCityId,
      storeName: storeName ?? this.storeName,
      categoryDescription: categoryDescription ?? this.categoryDescription,
      contactTime: contactTime ?? this.contactTime,
      primaryNumber:
          clearPrimaryNumber ? null : (primaryNumber ?? this.primaryNumber),
      isPrimaryVerified: isPrimaryVerified ?? this.isPrimaryVerified,
      secondaryType: secondaryType ?? this.secondaryType,
      secondaryNumber: clearSecondaryNumber
          ? null
          : (secondaryNumber ?? this.secondaryNumber),
      isSecondaryVerified: isSecondaryVerified ?? this.isSecondaryVerified,
      secCodeText: secCodeText ?? this.secCodeText,
      images: images ?? this.images,
      street: street ?? this.street,
      pincode: pincode ?? this.pincode,
      area: area ?? this.area,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      formattedAddress: formattedAddress ?? this.formattedAddress,
      deliveryRadius: deliveryRadius ?? this.deliveryRadius,
      deliveryDistanceOptions:
          deliveryDistanceOptions ?? this.deliveryDistanceOptions,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      feeLimit: feeLimit ?? this.feeLimit,
      perKmFee: perKmFee ?? this.perKmFee,
      isDeliveryFeeSubs: isDeliveryFeeSubs ?? this.isDeliveryFeeSubs,
      isCod: isCod ?? this.isCod,
      isCodEnabled: isCodEnabled ?? this.isCodEnabled,
      codLimitType: codLimitType ?? this.codLimitType,
      codLimit: codLimit ?? this.codLimit,
      isOnlinePayment: isOnlinePayment ?? this.isOnlinePayment,
      isOnlinePaymentEnabled:
          isOnlinePaymentEnabled ?? this.isOnlinePaymentEnabled,
      replacementAccepted: replacementAccepted ?? this.replacementAccepted,
      replacementDays: replacementDays ?? this.replacementDays,
      refundAccepted: refundAccepted ?? this.refundAccepted,
      refundDays: refundDays ?? this.refundDays,
      availability: availability ?? this.availability,
      deliveryFrom: deliveryFrom ?? this.deliveryFrom,
      deliveryTo: deliveryTo ?? this.deliveryTo,
      deliveryTypes: deliveryTypes ?? this.deliveryTypes,
      availableTimeSlots: availableTimeSlots ?? this.availableTimeSlots,
      selectedTimeSlots: selectedTimeSlots ?? this.selectedTimeSlots,
      wholesaleTimeSlots: wholesaleTimeSlots ?? this.wholesaleTimeSlots,
      isLimitApplied: isLimitApplied ?? this.isLimitApplied,
      otherDeliveryEnabled: otherDeliveryEnabled ?? this.otherDeliveryEnabled,
      otherDeliveryRadius: otherDeliveryRadius ?? this.otherDeliveryRadius,
      otherDeliveryFee: otherDeliveryFee ?? this.otherDeliveryFee,
      otherFeeLimit: otherFeeLimit ?? this.otherFeeLimit,
      otherDeliveryTypes: otherDeliveryTypes ?? this.otherDeliveryTypes,
      isPrivate: isPrivate ?? this.isPrivate,
      termsAccepted: termsAccepted ?? this.termsAccepted,
      isLoadingTypes: isLoadingTypes ?? this.isLoadingTypes,
      isLoadingCategories: isLoadingCategories ?? this.isLoadingCategories,
      isLoadingLocations: isLoadingLocations ?? this.isLoadingLocations,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSuccess: isSuccess ?? this.isSuccess,
      successMessage: successMessage ?? this.successMessage,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ── Provider ──────────────────────────────────────────────────────────────

final addStoreControllerProvider =
    StateNotifierProvider.autoDispose<AddStoreController, AddStoreState>(
  (ref) => AddStoreController(ref.read(addStoreRepositoryProvider)),
);

// ── Notifier ──────────────────────────────────────────────────────────────

class AddStoreController extends StateNotifier<AddStoreState> {
  final AddStoreRepository _repo;

  AddStoreController(this._repo) : super(const AddStoreState());

  @override
  @visibleForTesting
  AddStoreState get debugState => state;

  /// Sanitizes raw physical address to strip unwanted currency or payload artifacts.
  static String sanitizePhysicalAddress(String raw) {
    if (raw.trim().isEmpty) return '';
    String cleaned = raw.replaceAll(RegExp(r'[\{\}\[\]""]'), '');
    // Remove charges or limits before or after numbers (with or without currency signs)
    // e.g. "delivery charge: ₹60", "₹50 delivery charge", "min purchase: 2000"
    cleaned = cleaned.replaceAll(
      RegExp(
        r'\b(?:delivery\s*(?:charge|fee)|charge|fee|min\s*purchase(?:\s*limit)?|limit)\b\s*[:=]?\s*[₹$€£\s]*\d+',
        caseSensitive: false,
      ),
      '',
    );
    cleaned = cleaned.replaceAll(
      RegExp(
        r'[₹$€£\s]*\d+\s*\b(?:delivery\s*(?:charge|fee)|charge|fee)\b',
        caseSensitive: false,
      ),
      '',
    );
    cleaned = cleaned.replaceAll(RegExp(r'[₹$€£]'), '');
    cleaned = cleaned.replaceAll(
      RegExp(r'\b(?:street|city|state|zipcode|location_id)\s*:', caseSensitive: false),
      '',
    );
    cleaned = cleaned
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .join(', ');
    return cleaned;
  }

  void setStoreKind(int kind) {
    final isBranded = kind == 4;
    final activeOptions = isBranded
        ? AddStoreState.brandedStoreDurations
        : AddStoreState.publicStoreDurations;
    final newRepDays = activeOptions.containsKey(state.replacementDays)
        ? state.replacementDays
        : activeOptions.keys.first;
    final newRefDays = activeOptions.containsKey(state.refundDays)
        ? state.refundDays
        : activeOptions.keys.first;
    state = state.copyWith(
      storeKind: kind,
      replacementDays: newRepDays,
      refundDays: newRefDays,
    );
  }
  /// Dynamically computes allowed Max Delivery Distance options based on category metadata and store kind.
  static List<int> computeDeliveryDistanceOptions({
    required StoreCategoryModel? category,
    required bool isWholesale,
  }) {
    if (isWholesale) {
      return const [5, 10, 15, 20, 25, 30, 35, 40, 45, 50];
    }

    int maxRadius = category?.maxDeliveryRadius ?? 0;
    if (maxRadius <= 0 && category != null) {
      final name = category.displayName.toLowerCase();
      final id = category.id.toLowerCase();
      if (name.contains('fast food') || name.contains('food') || name.contains('restaurant') || id.contains('food')) {
        maxRadius = 5;
      } else if (name.contains('bakery') || name.contains('grocery') || name.contains('supermarket')) {
        maxRadius = 10;
      } else if (name.contains('garment') || name.contains('fashion') || name.contains('cloth') || name.contains('apparel') || name.contains('other')) {
        maxRadius = 30;
      }
    }

    if (maxRadius <= 0) {
      maxRadius = 10;
    }

    return List.generate(maxRadius, (i) => i + 1);
  }

  /// Computes default selected Max Delivery Distance:
  /// Wholesale: 15 km
  /// B2C / D2C: 5 km (or highest valid option if maxRadius < 5)
  static int computeDefaultDeliveryRadius({
    required StoreCategoryModel? category,
    required bool isWholesale,
    required List<int> options,
  }) {
    if (isWholesale) {
      return options.contains(15) ? 15 : (options.isNotEmpty ? options.first : 15);
    }

    const defaultB2c = 5;
    if (options.contains(defaultB2c)) {
      return defaultB2c;
    }
    return options.isNotEmpty ? options.last : 5;
  }

  // ── Initialization & Loading ─────────────────────────────────────────────

  Future<void> loadInitialData({int? overrideKind, StoreFlow? overrideFlow}) async {
    StoreFlow flow;
    if (overrideFlow != null) {
      flow = overrideFlow;
    } else if (overrideKind != null) {
      if (overrideKind == 1 || overrideKind == 2) {
        flow = StoreFlow.wholesale;
      } else if (overrideKind == 4) {
        flow = StoreFlow.d2c;
      } else {
        flow = StoreFlow.b2c;
      }
    } else {
      flow = state.storeFlow;
    }

    final kind = (overrideKind == 1 || overrideKind == 2)
        ? 1
        : (overrideKind ?? (flow == StoreFlow.wholesale ? 1 : (flow == StoreFlow.d2c ? 4 : 0)));
    final isWholesale = flow == StoreFlow.wholesale;
    final options = computeDeliveryDistanceOptions(
      category: state.selectedCategory,
      isWholesale: isWholesale,
    );
    final defaultRadius = computeDefaultDeliveryRadius(
      category: state.selectedCategory,
      isWholesale: isWholesale,
      options: options,
    );

    // Set Android-exact defaults based on store flow:
    // Delivery fee = 20, limit = 800 (Wholesale) / 500 (B2C/D2C)
    // Delivery types default to [2, 3] (Agency & Self pickup, matching native add_store_screen_2.xml check_other and check_self)
    state = state.copyWith(
      storeFlow: flow,
      storeKind: kind,
      deliveryDistanceOptions: options,
      deliveryRadius: defaultRadius.toDouble(),
      deliveryFee: 20.0,
      feeLimit: isWholesale ? 800.0 : 500.0,
      deliveryTypes: const [2, 3],
      replacementDays: flow == StoreFlow.d2c ? 5 : 1,
      refundDays: flow == StoreFlow.d2c ? 5 : 1,
      isLoadingTypes: true,
      isLoadingLocations: true,
      clearError: true,
    );

    await Future.wait([
      _loadTypesAndCategories(kind),
      _loadLocations(),
      if (isWholesale) _loadWholesaleTimeSlots(),
    ]);
    if (!mounted) return;

    // Silently fetch device GPS current location on launch (matching Android getGPSCoordinates)
    try {
      await fetchCurrentDeviceLocation();
    } catch (_) {}
  }

  Future<void> _loadWholesaleTimeSlots() async {
    try {
      final slots = await _repo.fetchWholesaleTimeSlots();
      if (!mounted) return;
      if (slots.isNotEmpty) {
        state = state.copyWith(wholesaleTimeSlots: slots);
      }
    } catch (e) {
      debugPrint('[AddStoreController] _loadWholesaleTimeSlots error: $e');
    }
  }

  Future<void> _loadTypesAndCategories(int kind) async {
    try {
      var types = await _repo.fetchStoreTypes();
      if (!mounted) return;
      if (types.isEmpty) {
        types = const [
          StoreTypeModel(id: 1, name: 'Public Shops'),
          StoreTypeModel(id: 2, name: 'Wholesale'),
          StoreTypeModel(id: 4, name: 'D2C'),
        ];
      }

      StoreTypeModel? defaultType;
      if (kind == 2) {
        defaultType =
            types.firstWhere((t) => t.id == 2, orElse: () => types.first);
      } else if (kind == 4) {
        defaultType =
            types.firstWhere((t) => t.id == 4, orElse: () => types.first);
      } else {
        defaultType =
            types.firstWhere((t) => t.id == 1, orElse: () => types.first);
      }

      final isBranded = defaultType.id == 4 ||
          defaultType.name.toLowerCase().contains('brand') ||
          defaultType.name.toLowerCase().contains('d2c') ||
          defaultType.name.toLowerCase().contains('verified');
      final activeOptions = isBranded
          ? AddStoreState.brandedStoreDurations
          : AddStoreState.publicStoreDurations;
      final newRep = activeOptions.containsKey(state.replacementDays)
          ? state.replacementDays
          : activeOptions.keys.first;
      final newRef = activeOptions.containsKey(state.refundDays)
          ? state.refundDays
          : activeOptions.keys.first;

      state = state.copyWith(
        storeTypes: types,
        isLoadingTypes: false,
        selectedType: defaultType,
        replacementDays: newRep,
        refundDays: newRef,
      );

      await _loadCategories(defaultType.id);
    } catch (e) {
      if (!mounted) return;
      debugPrint('[AddStoreController] _loadTypes error: $e');
      final fallbackTypes = const [
        StoreTypeModel(id: 1, name: 'Public Shops'),
        StoreTypeModel(id: 2, name: 'Wholesale'),
        StoreTypeModel(id: 4, name: 'D2C'),
      ];
      final sel = kind == 2
          ? fallbackTypes[1]
          : (kind == 4 ? fallbackTypes[2] : fallbackTypes[0]);
      final isBranded = sel.id == 4 ||
          sel.name.toLowerCase().contains('brand') ||
          sel.name.toLowerCase().contains('d2c') ||
          sel.name.toLowerCase().contains('verified');
      final activeOptions = isBranded
          ? AddStoreState.brandedStoreDurations
          : AddStoreState.publicStoreDurations;
      final newRep = activeOptions.containsKey(state.replacementDays)
          ? state.replacementDays
          : activeOptions.keys.first;
      final newRef = activeOptions.containsKey(state.refundDays)
          ? state.refundDays
          : activeOptions.keys.first;

      state = state.copyWith(
        isLoadingTypes: false,
        storeTypes: fallbackTypes,
        selectedType: sel,
        replacementDays: newRep,
        refundDays: newRef,
        error: e.toString(),
      );
      await _loadCategories(sel.id);
    }
  }

  Future<void> _loadCategories(int typeId) async {
    state = state.copyWith(isLoadingCategories: true, clearError: true);
    try {
      final cats = await _repo.fetchCategories(typeId);
      if (!mounted) return;
      final firstCat = cats.isNotEmpty ? cats.first : null;
      state = state.copyWith(
        categories: cats,
        isLoadingCategories: false,
      );
      if (firstCat != null) {
        onCategoryChanged(firstCat);
      }
    } catch (e) {
      if (!mounted) return;
      debugPrint('[AddStoreController] _loadCategories error: $e');
      const fallback = [
        StoreCategoryModel(id: 'cat_supermarket', displayName: 'Supermarket', replacementDays: 1, refundDays: 1),
        StoreCategoryModel(id: 'cat_grocery', displayName: 'Grocery & Staples', replacementDays: 1, refundDays: 1),
        StoreCategoryModel(id: 'others', displayName: 'Others', replacementDays: 1, refundDays: 1),
      ];
      final firstCat = fallback.first;
      state = state.copyWith(
        categories: fallback,
        isLoadingCategories: false,
      );
      onCategoryChanged(firstCat);
    }
  }

  Future<void> _loadLocations() async {
    try {
      // 1. Initial Country Call: GET merchant/location
      List<String> countries;
      try {
        countries = await _repo.fetchCountries();
      } catch (e) {
        debugPrint('[AddStoreController] fetchCountries error: $e');
        countries = ['India'];
      }
      if (!mounted) return;
      if (countries.isEmpty) countries = ['India'];
      if (!countries.contains('India')) countries.insert(0, 'India');

      // Default Country Selection: First country from response list (e.g. India)
      final defaultCountry = (state.selectedCountry != null && countries.contains(state.selectedCountry))
          ? state.selectedCountry!
          : countries.first;

      // 2. Automated Dependent Call: GET merchant/location?country={defaultCountry}
      List<LocationModel> locs = [];
      try {
        locs = await _repo.fetchStatesByCountry(defaultCountry);
      } catch (e) {
        debugPrint('[AddStoreController] fetchStatesByCountry error: $e');
      }
      if (!mounted) return;

      if (locs.isEmpty) {
        locs = const [
          LocationModel(
              id: 'loc_ambur',
              city: 'Ambur',
              state: 'Tamil Nadu',
              country: 'India'),
          LocationModel(
              id: 'loc_vellore',
              city: 'Vellore',
              state: 'Tamil Nadu',
              country: 'India'),
          LocationModel(
              id: 'loc_bengaluru',
              city: 'Bengaluru',
              state: 'Karnataka',
              country: 'India'),
        ];
      }

      // 3. Default State & City Selection (matching Android exact sorting and pre-fill):
      final statesForCountry = locs.map((l) => l.state).toSet().toList();
      statesForCountry.sort((a, b) => a.compareTo(b)); // Android Collections.sort(states, String::compareToIgnoreCase)

      // Automatically pre-select the first state from the returned state list
      final defaultState = (state.selectedState != null && statesForCountry.contains(state.selectedState))
          ? state.selectedState!
          : (statesForCountry.isNotEmpty ? statesForCountry.first : '');

      // Automatically pre-select the first city belonging to that state
      final citiesForState = locs
          .where((l) => l.state.toLowerCase() == defaultState.toLowerCase())
          .toList()
        ..sort((a, b) => a.city.toLowerCase().compareTo(b.city.toLowerCase()));

      final defaultCity = (state.selectedCity != null &&
              citiesForState.any((c) =>
                  c.city.toLowerCase() == state.selectedCity!.city.toLowerCase()))
          ? citiesForState.firstWhere((c) =>
              c.city.toLowerCase() == state.selectedCity!.city.toLowerCase())
          : (citiesForState.isNotEmpty ? citiesForState.first : null);

      state = state.copyWith(
        allLocations: locs,
        countries: countries,
        states: statesForCountry,
        cities: citiesForState,
        selectedCountry: defaultCountry,
        countryText: state.countryText.isNotEmpty ? state.countryText : defaultCountry,
        selectedState: defaultState,
        stateText: state.stateText.isNotEmpty ? state.stateText : defaultState,
        selectedCity: defaultCity,
        cityText: state.cityText.isNotEmpty ? state.cityText : (defaultCity?.city ?? ''),
        selectedCityId: defaultCity?.id ?? '',
        isLoadingLocations: false,
      );
    } catch (e) {
      debugPrint('[AddStoreController] _loadLocations error: $e');
      const fallbackLocs = [
        LocationModel(
            id: 'loc_ambur',
            city: 'Ambur',
            state: 'Tamil Nadu',
            country: 'India'),
        LocationModel(
            id: 'loc_vellore',
            city: 'Vellore',
            state: 'Tamil Nadu',
            country: 'India'),
        LocationModel(
            id: 'loc_bengaluru',
            city: 'Bengaluru',
            state: 'Karnataka',
            country: 'India'),
      ];

      const fallbackTamilNaduCities = [
        LocationModel(
            id: 'loc_ambur',
            city: 'Ambur',
            state: 'Tamil Nadu',
            country: 'India'),
        LocationModel(
            id: 'loc_vellore',
            city: 'Vellore',
            state: 'Tamil Nadu',
            country: 'India'),
      ];

      state = state.copyWith(
        allLocations: fallbackLocs,
        countries: const ['India'],
        states: const ['Karnataka', 'Tamil Nadu'],
        cities: fallbackTamilNaduCities,
        selectedCountry: 'India',
        countryText: 'India',
        selectedState: 'Tamil Nadu',
        stateText: 'Tamil Nadu',
        selectedCity: fallbackTamilNaduCities.first,
        cityText: 'Ambur',
        selectedCityId: fallbackTamilNaduCities.first.id,
        isLoadingLocations: false,
      );
    }
  }

  /// Matches a database city against a geocoded city or district name,
  /// taking into account case-insensitivity, substrings, spelling variations (e.g. Kanniyakumari vs Kanyakumari),
  /// and common Indian district aliases.
  static bool _matchesCityOrDistrict(String locationCity, String target) {
    final a = locationCity.trim().toLowerCase();
    final b = target.trim().toLowerCase();
    if (a.isEmpty || b.isEmpty) return false;
    if (a == b) return true;

    // Direct substring match
    if (a.contains(b) || b.contains(a)) return true;

    // Known Indian district aliases & spelling variations
    const aliases = {
      'kanniyakumari': 'kanyakumari',
      'kanyakumari': 'kanniyakumari',
      'trichy': 'tiruchirappalli',
      'tiruchirappalli': 'trichy',
      'tanjore': 'thanjavur',
      'thanjavur': 'tanjore',
      'tuticorin': 'thoothukudi',
      'thoothukudi': 'tuticorin',
      'nellai': 'tirunelveli',
      'tirunelveli': 'nellai',
      'bengaluru': 'bangalore',
      'bangalore': 'bengaluru',
      'mysuru': 'mysore',
      'mysore': 'mysuru',
      'mumbai': 'bombay',
      'bombay': 'mumbai',
      'chennai': 'madras',
      'madras': 'chennai',
      'kolkata': 'calcutta',
      'calcutta': 'kolkata',
      'pondicherry': 'puducherry',
      'puducherry': 'pondicherry',
    };

    if (aliases[a] == b || aliases[b] == a) return true;

    String normalize(String s) {
      return s
          .replaceAll('nniya', 'nya')
          .replaceAll('iya', 'ya')
          .replaceAll('ee', 'i')
          .replaceAll('oo', 'u')
          .replaceAll('th', 't')
          .replaceAll(RegExp(r'[^a-z0-9]'), '');
    }

    final normA = normalize(a);
    final normB = normalize(b);
    if (normA.isNotEmpty && normB.isNotEmpty) {
      if (normA == normB || normA.contains(normB) || normB.contains(normA)) {
        return true;
      }
    }

    return false;
  }

  /// Automatically fetch the device's Current Location on launch to pre-populate
  /// the Store Address field, pincode, and coordinates (matching Android getGPSCoordinates).
  /// Skips redundant fetching if address is already populated unless [force] is true.
  Future<void> fetchCurrentDeviceLocation({bool force = false}) async {
    // Riverpod State Caching & Redundant Call Prevention:
    // Only fetch when the address field is empty unless explicitly forced by the user.
    // Preserves user manual edits and prevents background overwrites.
    if (!force) {
      final existingAddress = state.street.trim().isNotEmpty
          ? state.street.trim()
          : state.formattedAddress.trim();
      if (existingAddress.isNotEmpty) {
        debugPrint(
            '[AddStoreController] Address already populated ("$existingAddress"), skipping redundant fetch.');
        return;
      }
    }

    try {
      final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isServiceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 6),
        ),
      );
      if (!mounted) return;

      state = state.copyWith(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      try {
        final geoResult = await GeocodingService.reverseGeocode(
          position.latitude,
          position.longitude,
        );
        if (!mounted) return;

        final address = sanitizePhysicalAddress(geoResult.formattedAddress);
        final postal = geoResult.postalCode;
        final c = geoResult.country;
        final s = geoResult.state;
        final city = geoResult.city;

        state = state.copyWith(
          street: address.isNotEmpty ? address : state.street,
          formattedAddress: address.isNotEmpty ? address : state.formattedAddress,
          pincodeText: postal.isNotEmpty ? postal : state.pincodeText,
          pincode: int.tryParse(postal) ?? state.pincode,
        );

        if (c.isNotEmpty) {
          state = state.copyWith(countryText: c);
          if (state.countries.contains(c)) {
            state = state.copyWith(selectedCountry: c);
          }
        }
        if (s.isNotEmpty) {
          state = state.copyWith(stateText: s);
          final matchedState = state.states.firstWhere(
            (st) => st.toLowerCase() == s.toLowerCase(),
            orElse: () => '',
          );
          if (matchedState.isNotEmpty) {
            final citiesForState = state.allLocations
                .where((l) => l.state.toLowerCase() == matchedState.toLowerCase())
                .toList()
              ..sort((a, b) => a.city.toLowerCase().compareTo(b.city.toLowerCase()));
            LocationModel? defaultCity;
            // 1. Match with locality (city)
            if (city.isNotEmpty) {
              for (final ct in citiesForState) {
                if (_matchesCityOrDistrict(ct.city, city)) {
                  defaultCity = ct;
                  break;
                }
              }
            }
            // 2. Match with district (subAdministrativeArea e.g. Kanniyakumari -> Kanyakumari)
            if (defaultCity == null && geoResult.district.isNotEmpty) {
              for (final ct in citiesForState) {
                if (_matchesCityOrDistrict(ct.city, geoResult.district)) {
                  defaultCity = ct;
                  break;
                }
              }
            }
            // 3. Match in area or district
            if (defaultCity == null) {
              for (final ct in citiesForState) {
                if ((geoResult.district.isNotEmpty && _matchesCityOrDistrict(ct.city, geoResult.district)) ||
                    (city.isNotEmpty && _matchesCityOrDistrict(ct.city, city)) ||
                    (geoResult.area.isNotEmpty && _matchesCityOrDistrict(ct.city, geoResult.area))) {
                  defaultCity = ct;
                  break;
                }
              }
            }
            // 4. Match city present in full formatted address
            if (defaultCity == null && address.isNotEmpty) {
              for (final ct in citiesForState) {
                if (address.toLowerCase().contains(ct.city.toLowerCase()) ||
                    _matchesCityOrDistrict(ct.city, address)) {
                  defaultCity = ct;
                  break;
                }
              }
            }
            // 5. Fallback to first city
            defaultCity ??= (citiesForState.isNotEmpty ? citiesForState.first : null);

            state = state.copyWith(
              selectedState: matchedState,
              cities: citiesForState,
              selectedCity: defaultCity,
              selectedCityId: defaultCity?.id ?? '',
              cityText: defaultCity?.city ?? city,
            );
          }
        }
      } catch (ge) {
        debugPrint('[AddStoreController] Geocoding error: $ge');
      }
    } catch (e) {
      debugPrint('[AddStoreController] fetchCurrentDeviceLocation error: $e');
    }
  }

  // ── Dropdown & Text Event Handlers ───────────────────────────────────────

  Future<void> onTypeChanged(StoreTypeModel? type) async {
    if (type == null) return;
    if (state.selectedType?.id == type.id) {
      return;
    }

    final isBranded = type.id == 4 ||
        type.name.toLowerCase().contains('brand') ||
        type.name.toLowerCase().contains('d2c') ||
        type.name.toLowerCase().contains('verified');

    final activeOptions = isBranded
        ? AddStoreState.brandedStoreDurations
        : AddStoreState.publicStoreDurations;

    // Reset or re-validate the currently selected value if the user switches store types
    // so an invalid option is not retained.
    final newRepDays = activeOptions.containsKey(state.replacementDays)
        ? state.replacementDays
        : activeOptions.keys.first;
    final newRefDays = activeOptions.containsKey(state.refundDays)
        ? state.refundDays
        : activeOptions.keys.first;

    final isWholesale = state.isWholesale;
    final distOptions = computeDeliveryDistanceOptions(
      category: null,
      isWholesale: isWholesale,
    );
    final defaultRadius = computeDefaultDeliveryRadius(
      category: null,
      isWholesale: isWholesale,
      options: distOptions,
    );

    state = state.copyWith(
      selectedType: type,
      clearSelectedCategory: true,
      deliveryDistanceOptions: distOptions,
      deliveryRadius: defaultRadius.toDouble(),
      feeLimit: isWholesale ? 800.0 : 500.0,
      replacementDays: newRepDays,
      refundDays: newRefDays,
    );
    await _loadCategories(type.id);
  }

  /// Alias for onTypeChanged required by prompt specifications
  Future<void> onStoreTypeChanged(StoreTypeModel? type) => onTypeChanged(type);

  void onCategoryChanged(StoreCategoryModel? cat) {
    if (cat == null) return;

    final isWholesale = state.isWholesale;
    final distOptions = computeDeliveryDistanceOptions(
      category: cat,
      isWholesale: isWholesale,
    );
    final defaultRadius = computeDefaultDeliveryRadius(
      category: cat,
      isWholesale: isWholesale,
      options: distOptions,
    );

  final repOptions = AddStoreState.computeDurationOptions(cat.replacementDays);
  final refOptions = AddStoreState.computeDurationOptions(cat.refundDays);

  final newRepDays = repOptions.containsKey(state.replacementDays)
      ? state.replacementDays
      : (repOptions.isNotEmpty ? repOptions.keys.first : 1);

  final newRefDays = refOptions.containsKey(state.refundDays)
      ? state.refundDays
      : (refOptions.isNotEmpty ? refOptions.keys.first : 1);

  // Category-driven COD & Online Payment settings (from delivery.local in category response)
  final bool codEnabled = cat.isCod ?? true;
  final bool codValue = cat.isCod ?? state.isCod;

  final bool onlineEnabled = cat.isOnlinePayment ?? true;
  final bool onlineValue = cat.isOnlinePayment ?? state.isOnlinePayment;

  state = state.copyWith(
    selectedCategory: cat,
    deliveryDistanceOptions: distOptions,
    deliveryRadius: defaultRadius.toDouble(),
    replacementAccepted: cat.replacementAccepted,
    refundAccepted: cat.refundAccepted,
    replacementDays: newRepDays,
    refundDays: newRefDays,
    categoryDescription: cat.id == 'others' ? state.categoryDescription : '',
    contactTime: cat.id == 'others' ? state.contactTime : '',
    otherDeliveryEnabled: cat.isOtherDeliverySupported ? state.otherDeliveryEnabled : false,

    // COD switch enablement & toggle state directly driven by API
    isCodEnabled: codEnabled,
    isCod: codEnabled ? codValue : false,

    // Online Payment switch enablement & toggle state directly driven by API
    isOnlinePaymentEnabled: onlineEnabled,
    isOnlinePayment: onlineEnabled ? onlineValue : false,
  );
}

  Future<void> onCountryChanged(String? country) async {
    if (country == null) return;
    try {
      final locs = await _repo.fetchStatesByCountry(country);
      if (!mounted) return;
      final statesForCountry = locs.map((l) => l.state).toSet().toList();
      statesForCountry.sort((a, b) => a.compareTo(b));

      final firstState = statesForCountry.isNotEmpty ? statesForCountry.first : '';
      final citiesForState = locs
          .where((l) => l.state.toLowerCase() == firstState.toLowerCase())
          .toList()
        ..sort((a, b) => a.city.toLowerCase().compareTo(b.city.toLowerCase()));
      final firstCity = citiesForState.isNotEmpty ? citiesForState.first : null;

      state = state.copyWith(
        allLocations: locs,
        selectedCountry: country,
        countryText: country,
        states: statesForCountry,
        selectedState: firstState,
        stateText: firstState,
        cities: citiesForState,
        selectedCity: firstCity,
        cityText: firstCity?.city ?? '',
        selectedCityId: firstCity?.id ?? '',
      );
    } catch (e) {
      debugPrint('[AddStoreController] onCountryChanged error: $e');
      state = state.copyWith(selectedCountry: country, countryText: country);
    }
  }

  void onStateChanged(String? stateName) {
    if (stateName == null) return;
    final citiesForState = state.allLocations
        .where((l) => l.state.toLowerCase() == stateName.toLowerCase())
        .toList()
      ..sort((a, b) => a.city.toLowerCase().compareTo(b.city.toLowerCase()));

    final firstCity = citiesForState.isNotEmpty ? citiesForState.first : null;

    state = state.copyWith(
      selectedState: stateName,
      stateText: stateName,
      cities: citiesForState,
      selectedCity: firstCity,
      cityText: firstCity?.city ?? '',
      selectedCityId: firstCity?.id ?? '',
    );
  }

  void onCityChanged(LocationModel? city) {
    if (city != null) {
      state = state.copyWith(
        selectedCity: city,
        cityText: city.city,
        selectedCityId: city.id,
      );
    }
  }

  // Fully editable text setters
  void setCountryText(String text) =>
      state = state.copyWith(countryText: text);
  void setStateText(String text) => state = state.copyWith(stateText: text);
  void setCityText(String text) {
    final matched = state.cities.firstWhere(
      (c) => c.city.toLowerCase() == text.trim().toLowerCase(),
      orElse: () => LocationModel(
        id: state.selectedCityId.isNotEmpty
            ? state.selectedCityId
            : 'loc_custom',
        city: text.trim(),
        state: state.stateText,
        country: state.countryText,
      ),
    );
    state = state.copyWith(
      cityText: text,
      selectedCity: matched,
      selectedCityId: matched.id,
    );
  }

  void setPincodeText(String text) {
    final val = int.tryParse(text);
    state = state.copyWith(pincodeText: text, pincode: val);
  }

  // ── Map Location Update ──────────────────────────────────────────────────

  void updateLocationFromMap(PickedLocationData data) {
    String countryToSet =
        data.country.isNotEmpty ? data.country : (state.countryText.isNotEmpty ? state.countryText : 'India');

    final statesForCountry = state.allLocations
        .where((l) => l.country.toLowerCase() == countryToSet.toLowerCase())
        .map((l) => l.state)
        .toSet()
        .toList();

    String stateToSet = data.state;
    if (data.state.isNotEmpty) {
      final matchedState = statesForCountry.firstWhere(
        (s) =>
            s.toLowerCase().contains(data.state.toLowerCase()) ||
            data.state.toLowerCase().contains(s.toLowerCase()),
        orElse: () => data.state,
      );
      stateToSet = matchedState;
    } else if (statesForCountry.isNotEmpty) {
      stateToSet = statesForCountry.first;
    }

    final citiesForState = state.allLocations
        .where((l) =>
            l.country.toLowerCase() == countryToSet.toLowerCase() &&
            l.state.toLowerCase() == stateToSet.toLowerCase())
        .toList()
      ..sort((a, b) => a.city.toLowerCase().compareTo(b.city.toLowerCase()));

    String cityToSet = data.city;
    String locationIdToSet = state.selectedCityId;
    LocationModel? matchedCityObj;

    // Prioritize matching within cities belonging to the resolved state
    if (citiesForState.isNotEmpty) {
      // 1. Match with data.city
      if (data.city.isNotEmpty) {
        for (final c in citiesForState) {
          if (_matchesCityOrDistrict(c.city, data.city)) {
            matchedCityObj = c;
            locationIdToSet = c.id;
            cityToSet = c.city;
            break;
          }
        }
      }

      // 2. Match with data.district (e.g. Kanniyakumari -> Kanyakumari)
      if (matchedCityObj == null && data.district.isNotEmpty) {
        for (final c in citiesForState) {
          if (_matchesCityOrDistrict(c.city, data.district)) {
            matchedCityObj = c;
            locationIdToSet = c.id;
            cityToSet = c.city;
            break;
          }
        }
      }

      // 3. Match within area
      if (matchedCityObj == null && data.area.isNotEmpty) {
        for (final c in citiesForState) {
          if (_matchesCityOrDistrict(c.city, data.area)) {
            matchedCityObj = c;
            locationIdToSet = c.id;
            cityToSet = c.city;
            break;
          }
        }
      }

      // 4. Match city found within full formatted address
      if (matchedCityObj == null && data.formattedAddress.isNotEmpty) {
        for (final c in citiesForState) {
          if (data.formattedAddress.toLowerCase().contains(c.city.toLowerCase()) ||
              _matchesCityOrDistrict(c.city, data.formattedAddress)) {
            matchedCityObj = c;
            locationIdToSet = c.id;
            cityToSet = c.city;
            break;
          }
        }
      }
    }

    // 5. Fallback: Search across all locations
    if (matchedCityObj == null && (data.city.isNotEmpty || data.district.isNotEmpty)) {
      for (final c in state.allLocations) {
        if ((data.city.isNotEmpty && _matchesCityOrDistrict(c.city, data.city)) ||
            (data.district.isNotEmpty && _matchesCityOrDistrict(c.city, data.district))) {
          matchedCityObj = c;
          locationIdToSet = c.id;
          cityToSet = c.city;
          break;
        }
      }
    }

    if (locationIdToSet.isEmpty && citiesForState.isNotEmpty) {
      locationIdToSet = citiesForState.first.id;
      cityToSet = citiesForState.first.city;
      matchedCityObj = citiesForState.first;
    }

    int? parsedPincode;
    if (data.postalCode.isNotEmpty) {
      parsedPincode = int.tryParse(data.postalCode);
    }

    final rawFormatted = data.formattedAddress.isNotEmpty
        ? data.formattedAddress
        : (data.street.isNotEmpty ? data.street : state.formattedAddress);
    final fullFormatted = sanitizePhysicalAddress(rawFormatted);

    state = state.copyWith(
      latitude: data.latitude,
      longitude: data.longitude,
      formattedAddress: fullFormatted,
      street: fullFormatted,
      area: data.area,
      pincode: parsedPincode ?? state.pincode,
      pincodeText: data.postalCode.isNotEmpty
          ? data.postalCode
          : (parsedPincode?.toString() ?? state.pincodeText),
      countryText: countryToSet,
      selectedCountry: countryToSet,
      states: statesForCountry,
      stateText: stateToSet,
      selectedState: stateToSet,
      cities: citiesForState,
      cityText: cityToSet.isNotEmpty ? cityToSet : data.city,
      selectedCity: matchedCityObj,
      selectedCityId: locationIdToSet,
    );
  }

  // ── Step Navigation ────────────────────────────────────────────────────────

  void setStep(int step) => state = state.copyWith(currentStep: step);

  // ── Step 1 Form Setters (Basics & Media) ──────────────────────────────────

  void setStoreName(String name) => state = state.copyWith(storeName: name);
  void setCategoryDescription(String desc) =>
      state = state.copyWith(categoryDescription: desc);
  void setContactTime(String time) =>
      state = state.copyWith(contactTime: time);
  void setPrimaryNumber(int? number) => state = state.copyWith(
        primaryNumber: number,
        clearPrimaryNumber: number == null || number == 0,
        isPrimaryVerified: false,
      );
  void setSecondaryType(String type) => state = state.copyWith(
        secondaryType: type,
        isSecondaryVerified: false,
        secCodeText: type == 'landline' ? '' : '+91',
      );
  void setSecCodeText(String code) =>
      state = state.copyWith(secCodeText: code);
  void setSecondaryNumber(int? number) => state = state.copyWith(
        secondaryNumber: number,
        clearSecondaryNumber: number == null || number == 0,
        isSecondaryVerified: false,
      );
  void setSecondaryVerified(bool verified) =>
      state = state.copyWith(isSecondaryVerified: verified);
  void setStreet(String street) {
    String derivedArea = state.area;
    if (derivedArea.isEmpty && street.contains(',')) {
      final parts = street.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      if (parts.length >= 2) {
        final candidate = parts[parts.length - 2];
        if (candidate.isNotEmpty && !RegExp(r'^\d{6}$').hasMatch(candidate)) {
          derivedArea = candidate;
        }
      }
    }
    if (derivedArea.isEmpty) {
      derivedArea = state.cityText.trim().isNotEmpty
          ? state.cityText.trim()
          : (state.selectedCity?.city.trim() ?? '');
    }
    state = state.copyWith(street: street, area: derivedArea);
  }
  void setArea(String area) => state = state.copyWith(area: area);

  String _resolveArea() {
    final areaStr = state.area.trim();
    if (areaStr.isNotEmpty) {
      return areaStr;
    }
    final streetStr = state.street.trim();
    if (streetStr.isNotEmpty && streetStr.contains(',')) {
      final parts = streetStr
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final knownCountries = {'india', 'in'};
      final knownStates = {
        'tamil nadu', 'karnataka', 'kerala', 'andhra pradesh',
        'telangana', 'maharashtra', 'delhi', 'punjab', 'gujarat',
        state.stateText.trim().toLowerCase(),
        (state.selectedState ?? '').trim().toLowerCase()
      };

      for (int i = parts.length - 1; i >= 0; i--) {
        final token = parts[i];
        final lower = token.toLowerCase();

        if (knownCountries.contains(lower)) continue;
        if (RegExp(r'^\d{5,6}$').hasMatch(token) || RegExp(r'^\d{3}\s*\d{3}$').hasMatch(token)) continue;
        if (knownStates.contains(lower)) continue;

        if (token.isNotEmpty) {
          return token;
        }
      }
    }
    final cityName = state.cityText.trim().isNotEmpty
        ? state.cityText.trim()
        : (state.selectedCity?.city.trim() ?? '');
    return cityName;
  }
  void setImages(List<File> imgs) =>
      state = state.copyWith(images: imgs.take(5).toList());

  // ── OTP Handling ─────────────────────────────────────────────────────────

  Future<String> sendPrimaryOtp() async {
    if (state.primaryNumber == null) return 'Please enter primary mobile number';
    try {
      final msg = await _repo.sendOtp(
        dialingCode: 91,
        number: state.primaryNumber!,
      );
      return msg;
    } catch (e) {
      return 'Failed to send OTP: $e';
    }
  }

  Future<bool> verifyPrimaryOtp(int otp) async {
    if (state.primaryNumber == null) return false;
    try {
      final success = await _repo.verifyOtp(
        dialingCode: 91,
        number: state.primaryNumber!,
        otp: otp,
      );
      if (!mounted) return false;
      if (success) {
        state = state.copyWith(isPrimaryVerified: true);
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  void setPrimaryVerified(bool verified) =>
      state = state.copyWith(isPrimaryVerified: verified);

  Future<String> sendSecondaryOtp() async {
    if (state.secondaryNumber == null) {
      return 'Please enter secondary mobile number';
    }
    try {
      final msg = await _repo.sendOtp(
        dialingCode: 91,
        number: state.secondaryNumber!,
      );
      if (!mounted) return 'Failed';
      return msg;
    } catch (e) {
      return 'Failed to send OTP: $e';
    }
  }

  Future<bool> verifySecondaryOtp(int otp) async {
    if (state.secondaryNumber == null) return false;
    try {
      final success = await _repo.verifyOtp(
        dialingCode: 91,
        number: state.secondaryNumber!,
        otp: otp,
      );
      if (!mounted) return false;
      if (success) {
        state = state.copyWith(isSecondaryVerified: true);
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  // ── Step 2 Form Setters (Operations, Policies & Fulfillment) ─────────────

  void setDeliveryRadius(double radius) =>
      state = state.copyWith(deliveryRadius: radius);
  void setDeliveryFee(double fee) => state = state.copyWith(deliveryFee: fee);
  void setFeeLimit(double limit) => state = state.copyWith(feeLimit: limit);
  void setPerKmFee(double fee) => state = state.copyWith(perKmFee: fee);
  void setIsDeliveryFeeSubs(bool val) =>
      state = state.copyWith(isDeliveryFeeSubs: val);
  void setIsCod(bool val) => state = state.copyWith(isCod: val);
  void setCodLimitType(String type) =>
      state = state.copyWith(codLimitType: type);
  void setCodLimit(double limit) => state = state.copyWith(codLimit: limit);
  void setIsOnlinePayment(bool val) =>
      state = state.copyWith(isOnlinePayment: val);
  void setReplacementAccepted(bool val) =>
      state = state.copyWith(replacementAccepted: val);
  void setReplacementDays(int days) =>
      state = state.copyWith(replacementDays: days);
  void setRefundAccepted(bool val) =>
      state = state.copyWith(refundAccepted: val);
  void setRefundDays(int days) => state = state.copyWith(refundDays: days);
  void setAvailability(List<String> days) =>
      state = state.copyWith(availability: days);
  void setDeliveryFrom(String from) =>
      state = state.copyWith(deliveryFrom: from);
  void setDeliveryTo(String to) => state = state.copyWith(deliveryTo: to);

  // Fulfillment delivery types (1 = Shop, 2 = Associate, 3 = Self pickup)
  void toggleDeliveryType(int type) {
    final current = List<int>.from(state.deliveryTypes);
    if (current.contains(type)) {
      if (current.length > 1) {
        current.remove(type);
      }
    } else {
      current.add(type);
    }
    state = state.copyWith(deliveryTypes: current);
  }

  // Wholesale Time Slots
  void toggleTimeSlot(String slot) {
    final current = List<String>.from(state.selectedTimeSlots);
    if (current.contains(slot)) {
      if (current.length > 1) {
        current.remove(slot);
      }
    } else {
      current.add(slot);
    }
    state = state.copyWith(selectedTimeSlots: current);
  }

  void addCustomTimeSlot(String slot) {
    if (slot.trim().isEmpty) return;
    final slots = List<String>.from(state.availableTimeSlots);
    final selected = List<String>.from(state.selectedTimeSlots);
    if (!slots.contains(slot.trim())) {
      slots.add(slot.trim());
    }
    if (!selected.contains(slot.trim())) {
      selected.add(slot.trim());
    }
    state = state.copyWith(
      availableTimeSlots: slots,
      selectedTimeSlots: selected,
    );
  }

  void toggleWholesaleTimeSlot(String id, bool isSelected) {
    final updated = state.wholesaleTimeSlots.map((slot) {
      if (slot.id == id) {
        return slot.copyWith(isSelected: isSelected);
      }
      return slot;
    }).toList();
    state = state.copyWith(wholesaleTimeSlots: updated);
  }

  void updateWholesaleTimeSlotLimit(String id, int limit) {
    final updated = state.wholesaleTimeSlots.map((slot) {
      if (slot.id == id) {
        return slot.copyWith(limit: limit);
      }
      return slot;
    }).toList();
    state = state.copyWith(wholesaleTimeSlots: updated);
  }

  void setIsLimitApplied(bool value) {
    state = state.copyWith(isLimitApplied: value);
  }

  // ── Step 3 Form Setters (Extended Delivery, Privacy & Terms) ─────────────

  void setOtherDeliveryEnabled(bool val) =>
      state = state.copyWith(otherDeliveryEnabled: val);
  void setOtherDeliveryRadius(double radius) =>
      state = state.copyWith(otherDeliveryRadius: radius);
  void setOtherDeliveryFee(double fee) =>
      state = state.copyWith(otherDeliveryFee: fee);
  void setOtherFeeLimit(double limit) =>
      state = state.copyWith(otherFeeLimit: limit);
  void setOtherDeliveryTypes(List<int> types) =>
      state = state.copyWith(otherDeliveryTypes: types);
  void toggleOtherDeliveryType(int type) {
    final current = List<int>.from(state.otherDeliveryTypes);
    if (current.contains(type)) {
      if (current.length > 1) current.remove(type);
    } else {
      current.add(type);
    }
    state = state.copyWith(otherDeliveryTypes: current);
  }

  void setIsPrivate(bool val) => state = state.copyWith(isPrivate: val);
  void setTermsAccepted(bool val) =>
      state = state.copyWith(termsAccepted: val);

  String? validateStep1() {
    if (state.storeName.trim().isEmpty) {
      return 'Please enter store name';
    }
    if (state.selectedCategory?.id == 'others' &&
        state.categoryDescription.trim().isEmpty) {
      return 'Please describe your store category';
    }
    if (state.primaryNumber == null ||
        state.primaryNumber.toString().length < 10) {
      return 'Please enter a valid 10-digit primary mobile number';
    }
    if (!state.isPrimaryVerified) {
      return 'Please verify primary mobile number';
    }
    final hasSecondary = state.secondaryNumber != null &&
        state.secondaryNumber! > 0 &&
        state.secondaryNumber.toString().trim().isNotEmpty;
    if (hasSecondary) {
      if (state.secondaryNumber.toString().length < 10) {
        return 'Please enter a valid 10-digit secondary mobile number';
      }
      if (state.secondaryType == 'mobile' && !state.isSecondaryVerified) {
        return 'Please verify secondary mobile number';
      }
    }
    if (state.images.length < 2) {
      return 'Please add at least 2 store photos';
    }
    if (state.street.trim().isEmpty) {
      return 'Please enter store address';
    }
    if (state.latitude == 0.0 && state.longitude == 0.0) {
      return 'Please pick store location on map';
    }
    if (state.cityText.trim().isEmpty && state.selectedCity == null) {
      return 'Please select or enter city';
    }
    if (state.pincode == null || state.pincode.toString().length < 6) {
      return 'Please enter valid 6-digit pin code';
    }
    return null;
  }

  String? validateStep2() {
    if (state.availability.isEmpty) {
      return 'Please select at least one working day';
    }
    if (state.deliveryTypes.isEmpty) {
      return 'Please select at least one delivery mode';
    }
    if (state.isWholesale && state.selectedTimeSlots.isEmpty) {
      return 'Please select at least one delivery time slot';
    }
    return null;
  }

  String? validateStep3() {
    if (!state.termsAccepted) {
      return 'Please accept terms & conditions to proceed';
    }
    return null;
  }

  // ── Final Store Submission ───────────────────────────────────────────────

  Future<bool> submitStore() async {
    final step1Err = validateStep1();
    if (step1Err != null) {
      state = state.copyWith(error: step1Err);
      return false;
    }
    if (!state.isSingleStepFlow) {
      final step2Err = validateStep2();
      if (step2Err != null) {
        state = state.copyWith(error: step2Err);
        return false;
      }
      final step3Err = validateStep3();
      if (step3Err != null) {
        state = state.copyWith(error: step3Err);
        return false;
      }
    }

    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      final cityId = state.selectedCityId.isNotEmpty
          ? state.selectedCityId
          : (state.selectedCity?.id ?? 'loc_custom');

      final timeSlotsToUse = state.isWholesale
          ? (() {
              final selected = state.wholesaleTimeSlots
                  .where((s) => s.isSelected)
                  .toList();
              final slotsToUse = selected.isNotEmpty
                  ? selected
                  : state.wholesaleTimeSlots;
              return slotsToUse.map((s) => s.toNativeJson()).toList();
            })()
          : state.selectedTimeSlots;

      final req = state.isWholesale
          ? CreateWsStoreRequest(
              categoryId: state.selectedCategory?.id ?? 'cat_supermarket',
              displayName: state.storeName.trim().isEmpty ? 'Test Store' : state.storeName.trim(),
              storeKind: state.storeKind,
              categoryDescription: state.selectedCategory?.id == 'others'
                  ? (state.categoryDescription.trim().isEmpty ? 'Store Category' : state.categoryDescription.trim())
                  : null,
              contactTime: state.selectedCategory?.id == 'others'
                  ? (state.contactTime.trim().isEmpty ? '10 AM - 6 PM' : state.contactTime.trim())
                  : null,
              latitude: state.latitude == 0.0 ? 12.7906 : state.latitude,
              longitude: state.longitude == 0.0 ? 78.7157 : state.longitude,
              locationId: cityId,
              street: state.street.trim().isEmpty ? '123 Main Street' : state.street.trim(),
              zipcode: state.pincode ?? 635802,
              area: _resolveArea(),
              primaryDialingCode: 91,
              primaryNumber: state.primaryNumber ?? 9894555037,
              primaryVerified: true,
              secondaryDialingCode: state.secondaryNumber != null
                  ? (state.secondaryType == 'landline'
                      ? (int.tryParse(state.secCodeText) ?? 91)
                      : 91)
                  : null,
              secondaryNumber: state.secondaryNumber,
              secondaryVerified: state.isSecondaryVerified,
              replacementAccepted: state.replacementAccepted,
              replacementDays: state.replacementDays,
              refundAccepted: state.refundAccepted,
              refundDays: state.refundDays,
              availability: state.availability,
              localDeliveryEnabled: true,
              isCod: state.isCod,
              codLimitType: state.codLimitType,
              codLimit: state.codLimit,
              isOnlinePayment: state.isOnlinePayment,
              deliveryRadius: state.deliveryRadius,
              deliveryFee: state.deliveryFee,
              feeLimit: state.feeLimit,
              isLimitApplied: state.isLimitApplied,
              perKmFee: state.perKmFee,
              isDeliveryFeeSubs: state.isDeliveryFeeSubs,
              deliveryFrom: state.deliveryFrom,
              deliveryTo: state.deliveryTo,
              deliveryTypes: state.deliveryTypes,
              timeSlots: timeSlotsToUse,
              otherDeliveryEnabled: state.otherDeliveryEnabled,
              otherDeliveryFee: state.otherDeliveryFee,
              otherFeeLimit: state.otherFeeLimit,
              otherDeliveryTypes: state.otherDeliveryTypes,
              isPrivate: state.isPrivate,
            )
          : CreateStoreRequest(
              categoryId: state.selectedCategory?.id ?? 'cat_supermarket',
              displayName: state.storeName.trim().isEmpty ? 'Test Store' : state.storeName.trim(),
              storeKind: state.storeKind,
              categoryDescription: state.selectedCategory?.id == 'others'
                  ? (state.categoryDescription.trim().isEmpty ? 'Store Category' : state.categoryDescription.trim())
                  : null,
              contactTime: state.selectedCategory?.id == 'others'
                  ? (state.contactTime.trim().isEmpty ? '10 AM - 6 PM' : state.contactTime.trim())
                  : null,
              latitude: state.latitude == 0.0 ? 12.7906 : state.latitude,
              longitude: state.longitude == 0.0 ? 78.7157 : state.longitude,
              locationId: cityId,
              street: state.street.trim().isEmpty ? '123 Main Street' : state.street.trim(),
              zipcode: state.pincode ?? 635802,
              area: _resolveArea(),
              primaryDialingCode: 91,
              primaryNumber: state.primaryNumber ?? 9894555037,
              primaryVerified: true,
              secondaryDialingCode: state.secondaryNumber != null
                  ? (state.secondaryType == 'landline'
                      ? (int.tryParse(state.secCodeText) ?? 91)
                      : 91)
                  : null,
              secondaryNumber: state.secondaryNumber,
              secondaryVerified: state.isSecondaryVerified,
              replacementAccepted: state.replacementAccepted,
              replacementDays: state.replacementDays,
              refundAccepted: state.refundAccepted,
              refundDays: state.refundDays,
              availability: state.availability,
              localDeliveryEnabled: true,
              isCod: state.isCod,
              codLimitType: state.codLimitType,
              codLimit: state.codLimit,
              isOnlinePayment: state.isOnlinePayment,
              deliveryRadius: state.deliveryRadius,
              deliveryFee: state.deliveryFee,
              feeLimit: state.feeLimit,
              isLimitApplied: state.isLimitApplied,
              perKmFee: state.perKmFee,
              isDeliveryFeeSubs: state.isDeliveryFeeSubs,
              deliveryFrom: state.deliveryFrom,
              deliveryTo: state.deliveryTo,
              deliveryTypes: state.deliveryTypes,
              timeSlots: timeSlotsToUse,
              otherDeliveryEnabled: state.otherDeliveryEnabled,
              otherDeliveryFee: state.otherDeliveryFee,
              otherFeeLimit: state.otherFeeLimit,
              otherDeliveryTypes: state.otherDeliveryTypes,
              isPrivate: state.isPrivate,
            );

      StoreCreationResult result;
      if (state.isWholesale) {
        // Wholesale (B2B)
        result = await _repo.createWsStore(req, state.images);
      } else if (state.selectedCategory?.id == 'others') {
        // Other Category
        result = await _repo.createOtherStore(req, state.images);
      } else {
        // B2C Retail or D2C
        result = await _repo.createStore(req, state.images);
      }
      if (!mounted) return result.success;

      state = state.copyWith(
        isSubmitting: false,
        isSuccess: result.success,
        successMessage: result.message,
        error: result.success
            ? null
            : (result.message ?? 'Failed to create store. Please try again.'),
      );
      return result.success;
    } catch (e) {
      debugPrint('[AddStoreController] submitStore error: $e');
      if (!mounted) return false;
      state = state.copyWith(
        isSubmitting: false,
        isSuccess: false,
        error: e.toString(),
      );
      return false;
    }
  }
}
