import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayfay_merchant_flutter/core/network/api_client.dart';
import 'package:bayfay_merchant_flutter/core/network/api_endpoints.dart';
import '../model/delivery_setting_model.dart';

final storeDeliverySettingRepositoryProvider =
    Provider<StoreDeliverySettingRepository>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return StoreDeliverySettingRepository(apiClient);
});

class StoreDeliverySettingRepository {
  final ApiClient _apiClient;

  const StoreDeliverySettingRepository(this._apiClient);

  /// Fetch delivery config matching Android callSettingDelivery (@POST "shop/view/delivery")
  Future<DeliveryConfigData?> getDeliveryConfig({
    required String shopId,
    required dynamic categoryId,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.shopViewDelivery,
        data: {
          'shop_id': shopId,
          'category_id': categoryId,
        },
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data['success'] == true) {
        final innerData = data['data'];
        if (innerData is Map<String, dynamic>) {
          return DeliveryConfigData.fromJson(innerData);
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Save delivery configuration matching Android callSettingUpdate (@POST "shop/edit")
  Future<({bool success, String message})> saveDeliveryConfig({
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
            (success
                ? 'Delivery configuration saved successfully'
                : 'Failed to update delivery configuration');
        return (success: success, message: message);
      }
      return (
        success: false,
        message: 'Invalid response from server',
      );
    } catch (e) {
      return (success: false, message: e.toString());
    }
  }
}
