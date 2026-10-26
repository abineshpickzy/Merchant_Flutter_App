import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../model/dashboard_date_filter.dart';
import '../model/store_dashboard_metrics_model.dart';

final storeRepositoryProvider = Provider<StoreRepository>((ref) {
  return StoreRepository(apiClient: ref.watch(apiClientProvider));
});

/// Dedicated repository handling 10 native Android Store Dashboard overview APIs.
class StoreRepository {
  final ApiClient _apiClient;

  StoreRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Fetches 11 overview endpoints concurrently using `Future.wait`, strictly matching native Android.
  Future<StoreDashboardMetricsModel> fetchDashboardMetrics({
    required String storeId,
    String? categoryId,
    required DashboardDateFilter filter,
  }) async {
    final filterDate = filter.buildFilterDatePayload();
    final storePayload = {
      'store_id': storeId,
      'filter_date': filterDate,
    };

    Future<Map<String, dynamic>?> safePost(String path, dynamic data) async {
      try {
        final response = await _apiClient.post(path, data: data);
        if (response.data is Map<String, dynamic>) {
          debugPrint('Dashboard API POST [$path] Response: ${response.data}');
          return response.data as Map<String, dynamic>;
        }
      } catch (e, stack) {
        debugPrint('Dashboard safePost Error [$path]: $e\n$stack');
      }
      return null;
    }

    Future<Map<String, dynamic>?> safeGet(String path) async {
      try {
        final response = await _apiClient.get(path);
        if (response.data is Map<String, dynamic>) {
          debugPrint('Dashboard API GET [$path] Response: ${response.data}');
          return response.data as Map<String, dynamic>;
        }
      } catch (e, stack) {
        debugPrint('Dashboard safeGet Error [$path]: $e\n$stack');
      }
      return null;
    }

    try {
      final results = await Future.wait([
        safePost('overview/usersVisited', storePayload),
        safePost('overview/totalSalesAmount', storePayload),
        safePost('overview/noOfOrders', storePayload),
        safePost('overview/usersInCart', storePayload),
        safePost('overview/refund', storePayload),
        safePost('overview/noOfReplacedProducts', storePayload),
        safePost('overview/overAllStatus', storePayload),
        safePost('order/count', {'shop_id': storeId}),
        safeGet('order/cancelReason/list'),
        safePost('order/msgTemplate', {}),
        safePost('order/newOrder', {
          'shop_id': storeId,
          'category_id': (categoryId != null && categoryId.isNotEmpty) ? categoryId : '',
        }),
      ]);

      return StoreDashboardMetricsModel.fromResponses(
        usersVisitedRes: results[0],
        totalSalesRes: results[1],
        noOfOrdersRes: results[2],
        usersInCartRes: results[3],
        refundRes: results[4],
        replacedProductsRes: results[5],
        overAllStatusRes: results[6],
        orderCountRes: results[7],
        cancelReasonsRes: results[8],
        msgTemplatesRes: results[9],
        newOrderRes: results[10],
        filter: filter,
      );
    } catch (e, stack) {
      debugPrint('Error in fetchDashboardMetrics: $e\n$stack');
      return StoreDashboardMetricsModel.sampleForFilter(filter);
    }
  }
}
