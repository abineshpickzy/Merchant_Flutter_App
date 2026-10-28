import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayfay_merchant_flutter/core/network/api_client.dart';
import 'package:bayfay_merchant_flutter/core/network/api_endpoints.dart';
import '../model/store_details_setting_model.dart';

final storeDetailsSettingRepositoryProvider =
    Provider<StoreDetailsSettingRepository>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return StoreDetailsSettingRepository(apiClient);
});

class StoreDetailsSettingRepository {
  final ApiClient _apiClient;

  const StoreDetailsSettingRepository(this._apiClient);

  /// Fetch store advanced details matching Android callSettingLocation (@POST "shop/view/advanced")
  Future<SettingLocationData?> getSettingLocation({
    required String shopId,
    required dynamic categoryId,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.shopViewAdvanced,
        data: {
          'shop_id': shopId,
          'category_id': categoryId,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['success'] == true) {
        final innerData = data['data'];
        if (innerData is Map<String, dynamic>) {
          return SettingLocationData.fromJson(innerData);
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Fetch list of countries matching Android GetListOfLocations (@GET "merchant/location")
  Future<List<String>> getCountries() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.merchantLocation);
      final data = response.data;
      if (data is Map<String, dynamic> && data['success'] == true) {
        final loc = data['location'];
        if (loc is List) {
          return loc.map((e) => e.toString()).toList();
        }
      }
      return const [];
    } catch (_) {
      return const [];
    }
  }

  /// Fetch list of states and cities for selected country matching Android GetListOfStates (@GET "merchant/location?country=")
  Future<List<LocationItem>> getStatesAndCities(String country) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.merchantLocation,
        queryParameters: {'country': country},
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data['success'] == true) {
        final loc = data['location'];
        if (loc is List) {
          return loc
              .whereType<Map<String, dynamic>>()
              .map((e) => LocationItem.fromJson(e))
              .toList();
        }
      }
      return const [];
    } catch (_) {
      return const [];
    }
  }

  /// Send OTP for primary or secondary mobile matching Android getOTPStoreMobile (@POST "merchant/onetimepassword/send")
  Future<({bool success, String message})> sendOtp({
    required int dialingCode,
    required int number,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.merchantOtpSend,
        data: {
          'mobile': {
            'dialing_code': dialingCode,
            'number': number,
          },
        },
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final success = data['success'] == true;
        final message = data['message']?.toString() ??
            (success ? 'OTP sent successfully' : 'Failed to send OTP');
        return (success: success, message: message);
      }
      return (success: false, message: 'Invalid response from server');
    } catch (e) {
      return (success: false, message: e.toString());
    }
  }

  /// Verify OTP matching Android verifyOTP (@POST "merchant/onetimepassword/verify")
  Future<({bool success, String message})> verifyOtp({
    required int dialingCode,
    required int number,
    required int otp,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.merchantOtpVerify,
        data: {
          'mobile': {
            'dialing_code': dialingCode,
            'number': number,
            'otp': otp,
          },
        },
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final success = data['success'] == true;
        final message = data['message']?.toString() ??
            (success ? 'OTP verified successfully' : 'Invalid OTP');
        return (success: success, message: message);
      }
      return (success: false, message: 'Invalid response from server');
    } catch (e) {
      return (success: false, message: e.toString());
    }
  }

  /// Save Store Details matching Android callSettingUpdate (@POST "shop/edit")
  Future<({bool success, String message})> saveStoreDetails({
    required String shopId,
    required dynamic categoryId,
    required Map<String, dynamic> dataPayload,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.shopEdit,
        data: {
          'shop_id': shopId,
          'category_id': categoryId,
          'data': dataPayload,
        },
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final success = data['success'] == true;
        final message = data['message']?.toString() ??
            (success ? 'Store details updated successfully' : 'Update failed');
        return (success: success, message: message);
      }
      return (success: false, message: 'Failed to update store details');
    } catch (e) {
      return (success: false, message: e.toString());
    }
  }
}
