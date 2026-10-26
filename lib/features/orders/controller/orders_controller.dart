import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/order_model.dart';
import '../repository/orders_repository.dart';

/// Active order tab status filter
final orderStatusTabProvider = StateProvider<OrderStatus>((ref) {
  return OrderStatus.newOrder;
});

/// Argument record for querying orders by store & status
typedef OrderQueryArg = ({String shopId, String categoryId, OrderStatus status});

/// Argument record for querying products of an order
typedef OrderProductsArg = ({String orderId, String shopId, String categoryId});

/// Provider for fetching orders list by store & status
final ordersListProvider = AutoDisposeAsyncNotifierProviderFamily<
    OrdersListNotifier, List<OrderModel>, OrderQueryArg>(() {
  return OrdersListNotifier();
});

class OrdersListNotifier
    extends AutoDisposeFamilyAsyncNotifier<List<OrderModel>, OrderQueryArg> {
  @override
  FutureOr<List<OrderModel>> build(OrderQueryArg arg) async {
    if (arg.shopId.isEmpty || arg.categoryId.isEmpty) return const [];
    final repository = ref.read(ordersRepositoryProvider);
    return repository.fetchOrdersByStatus(
      shopId: arg.shopId,
      categoryId: arg.categoryId,
      status: arg.status,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(ordersRepositoryProvider);
      return repository.fetchOrdersByStatus(
        shopId: arg.shopId,
        categoryId: arg.categoryId,
        status: arg.status,
      );
    });
  }
}

/// Provider for live order counts by store
final orderCountsProvider = AutoDisposeFutureProviderFamily<OrderCountsModel, String>(
    (ref, shopId) async {
  if (shopId.isEmpty) return const OrderCountsModel();
  final repository = ref.read(ordersRepositoryProvider);
  return repository.fetchOrderCounts(shopId: shopId);
});

/// Provider for fetching line-item products of an order
final orderProductsProvider =
    AutoDisposeFutureProviderFamily<List<OrderProductItem>, OrderProductsArg>(
        (ref, arg) async {
  if (arg.orderId.isEmpty) return const [];
  final repository = ref.read(ordersRepositoryProvider);
  return repository.fetchOrderProducts(
    orderId: arg.orderId,
    shopId: arg.shopId,
    categoryId: arg.categoryId,
  );
});

/// Controller handling merchant actions on orders (Accept, Cancel, Ready)
final orderActionControllerProvider =
    AutoDisposeAsyncNotifierProvider<OrderActionController, void>(() {
  return OrderActionController();
});

class OrderActionController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    // Idle state
  }

  Future<bool> acceptOrder({
    required String shopId,
    required String categoryId,
    required String orderId,
    required String expectedTime,
  }) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(ordersRepositoryProvider);
      final success = await repository.acceptOrder(
        shopId: shopId,
        categoryId: categoryId,
        orderId: orderId,
        expectedTime: expectedTime,
      );

      if (success) {
        // Invalidate counts and lists to trigger reload
        ref.invalidate(orderCountsProvider(shopId));
        ref.invalidate(ordersListProvider((shopId: shopId, categoryId: categoryId, status: OrderStatus.newOrder)));
        ref.invalidate(ordersListProvider((shopId: shopId, categoryId: categoryId, status: OrderStatus.processing)));
        state = const AsyncData(null);
        return true;
      }
      state = AsyncError('Failed to accept order', StackTrace.current);
      return false;
    } catch (e, stack) {
      state = AsyncError(e, stack);
      return false;
    }
  }

  Future<bool> cancelOrder({
    required String shopId,
    required String categoryId,
    required String orderId,
    required String reason,
  }) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(ordersRepositoryProvider);
      final success = await repository.cancelOrder(
        shopId: shopId,
        orderId: orderId,
        reason: reason,
      );

      if (success) {
        ref.invalidate(orderCountsProvider(shopId));
        ref.invalidate(ordersListProvider((shopId: shopId, categoryId: categoryId, status: OrderStatus.newOrder)));
        ref.invalidate(ordersListProvider((shopId: shopId, categoryId: categoryId, status: OrderStatus.processing)));
        ref.invalidate(ordersListProvider((shopId: shopId, categoryId: categoryId, status: OrderStatus.cancelled)));
        state = const AsyncData(null);
        return true;
      }
      state = AsyncError('Failed to cancel order', StackTrace.current);
      return false;
    } catch (e, stack) {
      state = AsyncError(e, stack);
      return false;
    }
  }

  Future<bool> markReadyToShip({
    required String shopId,
    required String categoryId,
    required String orderId,
  }) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(ordersRepositoryProvider);
      final success = await repository.readyToShipOrder(
        shopId: shopId,
        categoryId: categoryId,
        orderId: orderId,
      );

      if (success) {
        ref.invalidate(orderCountsProvider(shopId));
        ref.invalidate(ordersListProvider((shopId: shopId, categoryId: categoryId, status: OrderStatus.processing)));
        ref.invalidate(ordersListProvider((shopId: shopId, categoryId: categoryId, status: OrderStatus.ready)));
        state = const AsyncData(null);
        return true;
      }
      state = AsyncError('Failed to mark order ready', StackTrace.current);
      return false;
    } catch (e, stack) {
      state = AsyncError(e, stack);
      return false;
    }
  }
}