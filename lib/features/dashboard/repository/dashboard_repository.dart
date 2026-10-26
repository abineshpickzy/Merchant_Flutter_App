import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayfay_merchant_flutter/core/network/api_client.dart';
import 'package:bayfay_merchant_flutter/core/network/api_endpoints.dart';
import '../model/metric_models.dart';
import '../model/store_model.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return DashboardRepository(apiClient);
});

class DashboardRepository {
  final ApiClient _apiClient;

  const DashboardRepository(this._apiClient);

  /// Fetches merchant stores from GET merchant/shop/list (matching HomeFragment.ListOfStores)
  Future<List<StoreModel>> fetchStores() async {
    final response = await _apiClient.get(
      ApiEndpoints.shopList,
      requiresAuth: true,
    );

    if (response.data is Map<String, dynamic>) {
      final map = response.data as Map<String, dynamic>;
      final rawData = map['data'];
      if (rawData is List) {
        return rawData
            .whereType<Map<String, dynamic>>()
            .map((json) => StoreModel.fromJson(json))
            .toList();
      }
    }
    return const [];
  }

  /// Fetches unread notification count from POST notify/pushCount (matching HomeActivity.getNotificationCount)
  Future<int> fetchNotificationCount() async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.notificationCount,
        requiresAuth: true,
      );

      if (response.data is Map<String, dynamic>) {
        final map = response.data as Map<String, dynamic>;
        return (map['count'] as num?)?.toInt() ?? 0;
      }
    } catch (_) {
      // Graceful fallback for offline / mock
    }
    return 0;
  }

  /// Fetches business value and customer lead count from POST merchant/business/value (API-078)
  Future<BusinessValueModel> fetchBusinessValue({
    double? latitude,
    double? longitude,
  }) async {
    try {
      final Map<String, dynamic> data = {};
      if (latitude != null &&
          longitude != null &&
          (latitude != 0.0 || longitude != 0.0)) {
        data['latitude'] = latitude;
        data['longitude'] = longitude;
      }

      final response = await _apiClient.post(
        ApiEndpoints.businessValue,
        data: data.isNotEmpty ? data : null,
        requiresAuth: true,
      );

      if (response.data is Map<String, dynamic>) {
        return BusinessValueModel.fromJson(
            response.data as Map<String, dynamic>);
      }
    } catch (_) {
      // Graceful error isolation
    }
    return const BusinessValueModel();
  }

  /// Fetches partner turnover and agency details from POST merchant/partner/info (API-077)
  Future<PartnerInfoModel> fetchPartnerInfo({
    double? latitude,
    double? longitude,
  }) async {
    try {
      final Map<String, dynamic> data = {};
      if (latitude != null &&
          longitude != null &&
          (latitude != 0.0 || longitude != 0.0)) {
        data['latitude'] = latitude;
        data['longitude'] = longitude;
      }

      final response = await _apiClient.post(
        ApiEndpoints.partnerInfo,
        data: data.isNotEmpty ? data : null,
        requiresAuth: true,
      );

      if (response.data is Map<String, dynamic>) {
        return PartnerInfoModel.fromJson(
            response.data as Map<String, dynamic>);
      }
    } catch (_) {
      // Graceful error isolation
    }
    return const PartnerInfoModel();
  }
}
