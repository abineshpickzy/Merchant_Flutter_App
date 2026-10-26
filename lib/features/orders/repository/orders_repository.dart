import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayfay_merchant_flutter/core/network/api_client.dart';
import 'package:bayfay_merchant_flutter/core/network/api_endpoints.dart';
import '../model/order_model.dart';

final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return OrdersRepository(apiClient);
});

class OrdersRepository {
  final ApiClient _apiClient;

  const OrdersRepository(this._apiClient);

  /// Fetch orders for a specific store and status (matching OrdersFragment sub-fragments)
  Future<List<OrderModel>> fetchOrdersByStatus({
    required String shopId,
    required String categoryId,
    required OrderStatus status,
  }) async {
    final endpoint = _getEndpointForStatus(status);

    final response = await _apiClient.post(
      endpoint,
      data: {'shop_id': shopId, 'category_id': categoryId},
      requiresAuth: true,
    );

    if (response.data is Map<String, dynamic>) {
      final map = response.data as Map<String, dynamic>;
      final rawData = map['data'];
      if (rawData is List) {
        return rawData
            .whereType<Map<String, dynamic>>()
            .map((json) => OrderModel.fromJson(json, status))
            .toList();
      }
    }
    return const [];
  }

  /// Fetch tab counts for orders (matching ApiService.getOrdersCount)
  Future<OrderCountsModel> fetchOrderCounts({required String shopId}) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.orderCounts,
        data: {'shop_id': shopId},
        requiresAuth: true,
      );

      if (response.data is Map<String, dynamic>) {
        return OrderCountsModel.fromJson(
          response.data as Map<String, dynamic>,
        );
      }
    } catch (_) {
      // Gracefully fall back if counts endpoint is unavailable
    }
    return const OrderCountsModel();
  }

  /// Accept incoming new order (matching ApiService.callOrderAcceptNewApi)
  Future<bool> acceptOrder({
    required String shopId,
    required String categoryId,
    required String orderId,
    required String expectedTime,
  }) async {
    final response = await _apiClient.patch(
      ApiEndpoints.orderAccept,
      data: {
        'category_id': categoryId,
        'shop_id': shopId,
        'order_id': orderId,
        'expectedTime': expectedTime,
      },
      requiresAuth: true,
    );

    if (response.data is Map<String, dynamic>) {
      final map = response.data as Map<String, dynamic>;
      return map['success'] as bool? ?? true;
    }
    return true;
  }

  /// Cancel an order (matching ApiService.callOrderCancelNewApi)
  Future<bool> cancelOrder({
    required String shopId,
    required String orderId,
    required String reason,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.orderCancel,
      data: {
        'shop_id': shopId,
        'order_id': orderId,
        'title': reason,
      },
      requiresAuth: true,
    );

    if (response.data is Map<String, dynamic>) {
      final map = response.data as Map<String, dynamic>;
      return map['success'] as bool? ?? true;
    }
    return true;
  }

  /// Mark order ready to ship / dispatched (matching ApiService.callOrderDispatchedNewApi)
  Future<bool> readyToShipOrder({
    required String shopId,
    required String categoryId,
    required String orderId,
  }) async {
    final response = await _apiClient.patch(
      ApiEndpoints.orderReadyToShip,
      data: {
        'category_id': categoryId,
        'shop_id': shopId,
        'order_id': orderId,
      },
      requiresAuth: true,
    );

    if (response.data is Map<String, dynamic>) {
      final map = response.data as Map<String, dynamic>;
      return map['success'] as bool? ?? true;
    }
    return true;
  }

  /// Fetch order products breakdown (matching ApiService.callOrderDetailNewApi)
  Future<List<OrderProductItem>> fetchOrderProducts({
    required String orderId,
    required String shopId,
    required String categoryId,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.orderProducts,
      data: {
        'category_id': categoryId,
        'shop_id': shopId,
        'order_id': orderId,
      },
      requiresAuth: true,
    );

    if (response.data is Map<String, dynamic>) {
      final map = response.data as Map<String, dynamic>;
      final rawData = map['data'];
      if (rawData is List) {
        return rawData
            .whereType<Map<String, dynamic>>()
            .map((json) => OrderProductItem.fromJson(json))
            .toList();
      }
    }
    return const [];
  }

  String _getEndpointForStatus(OrderStatus status) {
    switch (status) {
      case OrderStatus.newOrder:
        return ApiEndpoints.ordersNew;
      case OrderStatus.processing:
        return ApiEndpoints.ordersAccepted;
      case OrderStatus.ready:
        return ApiEndpoints.ordersReady;
      case OrderStatus.onTheWay:
        return ApiEndpoints.ordersShipping;
      case OrderStatus.delivered:
        return ApiEndpoints.ordersDelivered;
      case OrderStatus.cancelled:
        return ApiEndpoints.ordersCancelled;
      case OrderStatus.replaceRefund:
        return ApiEndpoints.ordersEscalated;
    }
  }
}