import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayfay_merchant_flutter/core/network/api_client.dart';
import 'package:bayfay_merchant_flutter/core/network/api_endpoints.dart';
import '../model/setting_model.dart';

final settingRepositoryProvider = Provider<SettingRepository>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return SettingRepository(apiClient);
});

class SettingRepository {
  final ApiClient _apiClient;

  const SettingRepository(this._apiClient);

  /// Fetch basic shop settings matching Android callSetting (@POST "shop/view/basic")
  Future<SettingData?> getSettingBasic({
    required String shopId,
    required String categoryId,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.shopViewBasic,
        data: {
          'shop_id': shopId,
          'category_id': categoryId,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['success'] == true) {
        final innerData = data['data'];
        if (innerData is Map<String, dynamic>) {
          return SettingData.fromJson(innerData);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Update store settings (open/close, busy, private open/close) matching Android callSettingUpdate (@POST "shop/edit")
  Future<({bool success, String message})> updateSetting(
    SettingUpdateRequest request,
  ) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.shopEdit,
        data: request.toJson(),
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        final isSuccess = data['success'] == true;
        final message = (data['message'] ?? (isSuccess ? 'Updated successfully' : 'Update failed')).toString();
        return (success: isSuccess, message: message);
      }
      return (success: false, message: 'Invalid response format');
    } catch (e) {
      return (success: false, message: e.toString());
    }
  }

  /// Detach store matching Android detachShop (@POST "shop/remove")
  Future<({bool success, String message})> detachShop({
    required String shopId,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.shopRemove,
        data: {
          'shop_id': shopId,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        final isSuccess = data['success'] == true;
        final message = (data['data'] ?? data['message'] ?? 'Detached successfully').toString();
        return (success: isSuccess, message: message);
      }
      return (success: false, message: 'Invalid response format');
    } catch (e) {
      return (success: false, message: e.toString());
    }
  }

  /// Shop payment status check matching Android getShopPayRsp (@POST "merchant/payment/info")
  Future<Map<String, dynamic>?> checkShopPay({
    required String storeId,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.shopPaymentInfo,
        data: {
          'store_id': storeId,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return data;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
