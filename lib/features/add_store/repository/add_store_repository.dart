import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayfay_merchant_flutter/core/network/api_client.dart';
import 'package:bayfay_merchant_flutter/core/network/api_endpoints.dart';
import '../model/create_store_request.dart';
import '../model/location_model.dart';
import '../model/store_category_model.dart';
import '../model/store_type_model.dart';
import '../model/wholesale_time_slot_model.dart';

class StoreCreationResult {
  final bool success;
  final String? message;

  const StoreCreationResult({
    required this.success,
    this.message,
  });
}

final addStoreRepositoryProvider = Provider<AddStoreRepository>((ref) {
  return AddStoreRepository(ref.read(apiClientProvider));
});

class AddStoreRepository {
  final ApiClient _api;

  const AddStoreRepository(this._api);

  // ── Store Types ────────────────────────────────────────────────────────────

  /// `GET merchant/category` — returns list of store types (Public, Branded…)
  Future<List<StoreTypeModel>> fetchStoreTypes() async {
    final res = await _api.get(ApiEndpoints.merchantCategory);
    final data = res.data as Map<String, dynamic>?;
    final typeList = (data?['data']?['type'] as List?) ?? [];
    return typeList
        .whereType<Map<String, dynamic>>()
        .map(StoreTypeModel.fromJson)
        .toList();
  }

  // ── Store Categories ────────────────────────────────────────────────────────

  /// `GET merchant/category/{typeId}` — categories for a given type id
  Future<List<StoreCategoryModel>> fetchCategories(int typeId) async {
    final res = await _api.get(ApiEndpoints.merchantCategoryById(typeId));
    final data = res.data as Map<String, dynamic>?;
    final catList = (data?['categories'] as List?) ?? [];
    final categories = catList
        .whereType<Map<String, dynamic>>()
        .map(StoreCategoryModel.fromJson)
        .toList();
    // Android always appends an "Others" entry at the end
    categories.add(
      const StoreCategoryModel(id: 'others', displayName: 'Others'),
    );
    return categories;
  }

  // ── Locations ─────────────────────────────────────────────────────────────

  /// `GET merchant/location` — returns list of country names (matches Android CountryResponse)
  Future<List<String>> fetchCountries() async {
    final res = await _api.get(ApiEndpoints.merchantLocation);
    final data = res.data as Map<String, dynamic>?;
    final list = (data?['location'] as List?) ?? [];
    return list.map((e) => e.toString()).toList();
  }

  /// `GET merchant/location?country={country}` — states & cities for a given country (matches Android GetListOfStates)
  Future<List<LocationModel>> fetchStatesByCountry(String country) async {
    final res = await _api.get(
      ApiEndpoints.merchantLocation,
      queryParameters: {'country': country},
    );
    final data = res.data as Map<String, dynamic>?;
    final list = (data?['location'] as List?) ?? [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(LocationModel.fromJson)
        .toList();
  }

  /// Backwards-compatible helper returning default country locations
  Future<List<LocationModel>> fetchLocations() async {
    try {
      return await fetchStatesByCountry('India');
    } catch (_) {
      return [];
    }
  }

  // ── OTP ───────────────────────────────────────────────────────────────────

  /// `POST merchant/onetimepassword/send`
  Future<String> sendOtp({
    required int dialingCode,
    required int number,
  }) async {
    final res = await _api.post(
      ApiEndpoints.storeOtpSend,
      data: {
        'mobile': {'dialing_code': dialingCode, 'number': number},
      },
    );
    final data = res.data as Map<String, dynamic>?;
    return data?['message'] as String? ?? 'OTP sent';
  }

  /// `POST merchant/onetimepassword/verify`
  Future<bool> verifyOtp({
    required int dialingCode,
    required int number,
    required int otp,
  }) async {
    final res = await _api.post(
      ApiEndpoints.storeOtpVerify,
      data: {
        'mobile': {
          'dialing_code': dialingCode,
          'number': number,
          'otp': otp,
        },
      },
    );
    final data = res.data as Map<String, dynamic>?;
    return data?['success'] as bool? ?? false;
  }

  // ── Store Creation ────────────────────────────────────────────────────────

  /// `POST merchant/shop/new` — multipart B2C store creation
  Future<StoreCreationResult> createStore(
      CreateStoreRequest request, List<File> images) async {
    final formData = await request.toFormData(images);
    final res = await _api.post(
      ApiEndpoints.createStore,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    final data = res.data as Map<String, dynamic>?;
    final success = data?['success'] as bool? ?? false;
    final String? message = data?['message'] is String
        ? data!['message'] as String
        : ((data?['data'] is Map)
            ? (data!['data'] as Map)['message'] as String?
            : null);
    return StoreCreationResult(success: success, message: message);
  }

  /// `POST merchant/shop/other` — "Other category" multipart creation
  Future<StoreCreationResult> createOtherStore(
      CreateStoreRequest request, List<File> images) async {
    final formData = await request.toFormData(images);
    final res = await _api.post(
      ApiEndpoints.createOtherStore,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    final data = res.data as Map<String, dynamic>?;
    final success = data?['success'] as bool? ?? false;
    final String? message = data?['message'] is String
        ? data!['message'] as String
        : ((data?['data'] is Map)
            ? (data!['data'] as Map)['message'] as String?
            : null);
    return StoreCreationResult(success: success, message: message);
  }

  /// `POST merchant/wsshop/new` — multipart B2B Wholesale store creation
  Future<StoreCreationResult> createWsStore(
      CreateStoreRequest request, List<File> images) async {
    final formData = await request.toFormData(images);
    final res = await _api.post(
      ApiEndpoints.createWsStore,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    final data = res.data as Map<String, dynamic>?;
    final success = data?['success'] as bool? ?? false;
    final String? message = data?['message'] is String
        ? data!['message'] as String
        : ((data?['data'] is Map)
            ? (data!['data'] as Map)['message'] as String?
            : null);
    return StoreCreationResult(success: success, message: message);
  }

  /// `POST merchant/wshop/buyer` — Wholesale buyer profile creation
  Future<bool> registerWholesaleBuyer(Map<String, dynamic> payload) async {
    final res = await _api.post(
      ApiEndpoints.wholesaleBuyerReq,
      data: payload,
    );
    final data = res.data as Map<String, dynamic>?;
    return data?['success'] as bool? ?? false;
  }

  /// `POST merchant/wsshop/timeslot` — Fetch wholesale delivery time slots with default order limits
  Future<List<WholesaleTimeSlotModel>> fetchWholesaleTimeSlots() async {
    try {
      final res = await _api.post(ApiEndpoints.wholesaleTimeSlots);
      final data = res.data as Map<String, dynamic>?;
      final slotList = (data?['slots'] as List?) ??
          (data?['data'] as List?) ??
          (data?['time_slots'] as List?) ??
          [];
      if (slotList.isNotEmpty) {
        return slotList
            .whereType<Map<String, dynamic>>()
            .map(WholesaleTimeSlotModel.fromJson)
            .toList();
      }
    } catch (_) {
      try {
        final res = await _api.get(ApiEndpoints.wholesaleTimeSlots);
        final data = res.data as Map<String, dynamic>?;
        final slotList = (data?['slots'] as List?) ??
            (data?['data'] as List?) ??
            (data?['time_slots'] as List?) ??
            [];
        if (slotList.isNotEmpty) {
          return slotList
              .whereType<Map<String, dynamic>>()
              .map(WholesaleTimeSlotModel.fromJson)
              .toList();
        }
      } catch (_) {}
    }

    return const [
      WholesaleTimeSlotModel(id: 'slot_1', slotName: '7 am to 9 am', limit: 100),
      WholesaleTimeSlotModel(id: 'slot_2', slotName: '9 am to 11 am', limit: 100),
      WholesaleTimeSlotModel(id: 'slot_3', slotName: '11 am to 1 pm', limit: 100),
      WholesaleTimeSlotModel(id: 'slot_4', slotName: '1 pm to 3 pm', limit: 100),
      WholesaleTimeSlotModel(id: 'slot_5', slotName: '3 pm to 5 pm', limit: 100),
      WholesaleTimeSlotModel(id: 'slot_6', slotName: '5 pm to 7 pm', limit: 100),
    ];
  }
}
