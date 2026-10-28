import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayfay_merchant_flutter/core/network/api_client.dart';
import 'package:bayfay_merchant_flutter/core/network/api_endpoints.dart';
import '../model/shop_info_model.dart';

final shopInfoRepositoryProvider = Provider<ShopInfoRepository>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return ShopInfoRepository(apiClient);
});

class ShopInfoRepository {
  final ApiClient _apiClient;

  const ShopInfoRepository(this._apiClient);

  /// Fetch shop info matching Android shopInfoView (@POST "shop/view/shopInfo")
  Future<ShopInfoData?> getShopInfo({
    required String shopId,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.shopViewShopInfo,
        data: {
          'shop_id': shopId,
        },
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data['success'] == true) {
        final innerData = data['data'];
        if (innerData is Map<String, dynamic>) {
          return ShopInfoData.fromJson(innerData);
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Save shop info matching Android saveUpdateShopInfoView (@POST "shop/shopInfo")
  Future<({bool success, String message})> saveShopInfo({
    required String shopId,
    required List<String> shopPhotos,
    required List<String> certificates,
    required List<String> descriptions,
    required List<String> videoUrls,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.shopShopInfo,
        data: {
          'shop_id': shopId,
          'shop_photo': shopPhotos,
          'certificate': certificates,
          'description': descriptions,
          'video_url': videoUrls,
        },
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final success = data['success'] == true;
        final message = data['message']?.toString() ??
            (success
                ? 'Shop info saved successfully'
                : 'Failed to update shop info');
        return (success: success, message: message);
      }
      return (success: false, message: 'Invalid response from server');
    } catch (e) {
      return (success: false, message: e.toString());
    }
  }
}
