import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayfay_merchant_flutter/core/network/api_client.dart';
import 'package:bayfay_merchant_flutter/core/network/api_endpoints.dart';
import '../model/licence_details_model.dart';

final licenceDetailsRepositoryProvider =
    Provider<LicenceDetailsRepository>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return LicenceDetailsRepository(apiClient);
});

class LicenceDetailsRepository {
  final ApiClient _apiClient;

  const LicenceDetailsRepository(this._apiClient);

  /// Fetch licence details matching Android viewLicenceDetail (@POST "shop/view/licence")
  Future<LicenceDetailsData?> getLicenceDetails({
    required String shopId,
    required dynamic categoryId,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.shopViewLicence,
        data: {
          'shop_id': shopId,
          'category_id': categoryId,
        },
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data['success'] == true) {
        final innerData = data['data'];
        if (innerData is Map<String, dynamic>) {
          return LicenceDetailsData.fromJson(innerData);
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Save licence details matching Android sendShopLicenceDetails (@POST "shop/licence/settings")
  Future<({bool success, String message})> saveLicenceDetails({
    required String shopId,
    required String gstin,
    required String pan,
    required String fssai,
    required bool isAutoInvoice,
  }) async {
    try {
      final payload = <String, dynamic>{
        'store_id': shopId,
        'isAutoInvoice': isAutoInvoice,
      };
      if (gstin.isNotEmpty) payload['gstin'] = gstin;
      if (pan.isNotEmpty) payload['pan'] = pan;
      if (fssai.isNotEmpty) payload['fssai'] = fssai;

      final response = await _apiClient.post(
        ApiEndpoints.shopLicenceSettings,
        data: payload,
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final success = data['success'] == true;
        final message = data['message']?.toString() ??
            (success
                ? 'Licence details saved successfully'
                : 'Failed to update licence details');
        return (success: success, message: message);
      }
      return (success: false, message: 'Invalid response from server');
    } catch (e) {
      return (success: false, message: e.toString());
    }
  }
}
