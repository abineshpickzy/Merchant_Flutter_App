import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayfay_merchant_flutter/core/network/api_client.dart';
import 'package:bayfay_merchant_flutter/core/network/api_endpoints.dart';
import '../model/configure_shop_ui_model.dart';

final configureShopUiRepositoryProvider =
    Provider<ConfigureShopUiRepository>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return ConfigureShopUiRepository(apiClient);
});

class ConfigureShopUiRepository {
  final ApiClient _apiClient;

  const ConfigureShopUiRepository(this._apiClient);

  /// Fetch frames matching Android callSettingFrame (@POST "shop/view/private")
  Future<({List<ShopFrameType> frameTypes, int selectedFrameId})?> getFrameList({
    required String shopId,
    required dynamic categoryId,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.shopViewPrivate,
        data: {
          'shop_id': shopId,
          'category_id': categoryId,
        },
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data['success'] == true) {
        final innerData = data['data'];
        if (innerData is Map<String, dynamic>) {
          final typesList = innerData['frame_types'] as List<dynamic>? ?? [];
          final types = typesList
              .whereType<Map<String, dynamic>>()
              .map((e) => ShopFrameType.fromJson(e))
              .toList();
          final selected = (innerData['frame_selected'] as num?)?.toInt() ?? 0;
          return (frameTypes: types, selectedFrameId: selected);
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Update configured UI frame matching Android callSettingUpdate (@POST "shop/edit")
  Future<({bool success, String message})> saveFrame({
    required String shopId,
    required dynamic categoryId,
    required int frameId,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.shopEdit,
        data: {
          'shop_id': shopId,
          'category_id': categoryId,
          'data': {
            'private_frame_type': frameId,
          },
        },
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final success = data['success'] == true;
        final message = data['message']?.toString() ??
            (success
                ? 'Shop UI configured successfully'
                : 'Failed to update Shop UI');
        return (success: success, message: message);
      }
      return (success: false, message: 'Invalid response from server');
    } catch (e) {
      return (success: false, message: e.toString());
    }
  }
}
