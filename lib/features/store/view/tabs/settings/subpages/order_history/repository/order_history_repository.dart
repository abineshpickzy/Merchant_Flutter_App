import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayfay_merchant_flutter/core/network/api_client.dart';
import 'package:bayfay_merchant_flutter/core/network/api_endpoints.dart';
import '../model/order_history_model.dart';

final orderHistoryRepositoryProvider = Provider<OrderHistoryRepository>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return OrderHistoryRepository(apiClient);
});

class OrderHistoryRepository {
  final ApiClient _apiClient;

  const OrderHistoryRepository(this._apiClient);

  /// Fetch paginated order history list matching Android callGetNewAllStoresOrdersList (@GET "order/history")
  Future<({List<OrderHistoryItem> orders, int count})> getOrderHistory({
    required String shopId,
    required String fromDate,
    required String toDate,
    int skip = 0,
    int limit = 30,
  }) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.orderHistory,
        queryParameters: {
          'shop_id': shopId,
          'from': fromDate,
          'to': toDate,
          'skip': skip,
          'limit': limit,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['success'] == true) {
        final innerData = data['data'];
        if (innerData is Map<String, dynamic>) {
          final count = (innerData['count'] as num?)?.toInt() ?? 0;
          final orderList = innerData['orders'] ?? innerData['order'];
          if (orderList is List) {
            final orders = orderList
                .whereType<Map<String, dynamic>>()
                .map((item) => OrderHistoryItem.fromJson(item))
                .toList();
            return (orders: orders, count: count);
          }
        }
      }
      return (orders: <OrderHistoryItem>[], count: 0);
    } catch (_) {
      return (orders: <OrderHistoryItem>[], count: 0);
    }
  }
}
