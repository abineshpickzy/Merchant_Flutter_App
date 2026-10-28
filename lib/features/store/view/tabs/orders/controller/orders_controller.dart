import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayfay_merchant_flutter/core/storage/secure_storage_service.dart';
import 'package:bayfay_merchant_flutter/core/widgets/app_snackbar.dart';
import '../model/order_model.dart';
import '../repository/orders_repository.dart';

export '../repository/orders_repository.dart' show OrderActionResult;

/// Auth headers provider for authenticated network image loading (matching BaseActivity.java GlideUrl LazyHeaders)
final orderAuthHeadersProvider =
    FutureProvider<Map<String, String>>((ref) async {
  final storage = ref.read(secureStorageServiceProvider);
  final token = await storage.getAccessToken();
  final schema = await storage.getAccessSchema();
  if (token == null || token.isEmpty) {
    return const <String, String>{};
  }
  return <String, String>{
    'Authorization': '$schema $token',
  };
});

/// Active order tab status filter
final orderStatusTabProvider = StateProvider<OrderStatus>((ref) {
  return OrderStatus.newOrder;
});

/// Tracks whether the "More.." menu view (Delivered / Replace/Refund / Cancelled list) is currently open
final isMoreMenuOpenProvider = StateProvider<bool>((ref) {
  return false;
});

/// Argument record for querying orders by store & status
typedef OrderQueryArg = ({
  String shopId,
  String categoryId,
  OrderStatus status,
});

/// Argument record for querying products of an order
typedef OrderProductsArg = ({
  String orderId,
  String shopId,
  String categoryId,
  bool isEscalated,
});

/// Argument record for querying active delivery assistants
typedef ActiveAssistantsArg = ({
  String orderId,
  String expectedDeliveryTime,
});

/// Argument record for querying escalation correspondence chat
typedef EscalationChatArg = ({
  String shopId,
  String categoryId,
  String orderId,
  String productId,
});

/// Argument record for querying full product info & reviews
typedef OrderProductInfoArg = ({
  String categoryId,
  String storeId,
  String productId,
  String type,
});

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
final orderCountsProvider =
    AutoDisposeFutureProviderFamily<OrderCountsModel, String>(
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
    isEscalated: arg.isEscalated,
  );
});

/// Provider for active delivery associates for assignment
final activeDeliveryAssistantsProvider = AutoDisposeFutureProviderFamily<
    List<DeliveryAssistantModel>, ActiveAssistantsArg>((ref, arg) async {
  final repository = ref.read(ordersRepositoryProvider);
  return repository.fetchActiveDeliveryAssistants(
    orderId: arg.orderId,
    expectedDeliveryTime: arg.expectedDeliveryTime,
  );
});

/// Provider for checking if an order is in the auto-assign delivery queue
final orderInDeliveryQueueProvider =
    AutoDisposeFutureProviderFamily<bool, String>((ref, orderId) async {
  if (orderId.isEmpty) return false;
  final repository = ref.read(ordersRepositoryProvider);
  return repository.checkOrderInDeliveryQueue(orderId: orderId);
});

/// Provider for fetching assigned delivery associate info
final deliveryPersonInfoProvider =
    AutoDisposeFutureProviderFamily<Map<String, dynamic>?, String>(
        (ref, assistantId) async {
  if (assistantId.isEmpty) return null;
  final repository = ref.read(ordersRepositoryProvider);
  return repository.fetchDeliveryPersonInfo(assistantId);
});

/// Provider for fetching cancel reason options
final cancelReasonsProvider =
    AutoDisposeFutureProvider<List<CancelReasonItem>>((ref) async {
  final repository = ref.read(ordersRepositoryProvider);
  return repository.fetchCancelReasons();
});

/// Provider for fetching customer contact message templates
final contactTemplatesProvider = AutoDisposeFutureProviderFamily<
    List<CustomerContactTemplate>, ({String shopId, String orderId})>(
  (ref, arg) async {
    final repository = ref.read(ordersRepositoryProvider);
    return repository.fetchContactTemplates(
      shopId: arg.shopId,
      orderId: arg.orderId,
    );
  },
);

/// Provider for fetching product escalation correspondence messages
final escalationChatProvider = AutoDisposeFutureProviderFamily<
    List<EscalationChatMessage>, EscalationChatArg>((ref, arg) async {
  final repository = ref.read(ordersRepositoryProvider);
  return repository.fetchEscalationCorrespondence(
    shopId: arg.shopId,
    categoryId: arg.categoryId,
    orderId: arg.orderId,
    productId: arg.productId,
  );
});

/// Provider for fetching full product details (ProductFragment / ProductInfo)
final orderProductFullDetailProvider = AutoDisposeFutureProviderFamily<
    OrderProductDetailData, OrderProductInfoArg>((ref, arg) async {
  final repository = ref.read(ordersRepositoryProvider);
  return repository.fetchProductFullDetails(
    categoryId: arg.categoryId,
    storeId: arg.storeId,
    productId: arg.productId,
    type: arg.type,
  );
});

/// Provider for fetching product average selling price & customer rating (ProductInfo)
final orderProductAvgStatsProvider =
    AutoDisposeFutureProviderFamily<OrderProductAvgData, OrderProductInfoArg>(
        (ref, arg) async {
  final repository = ref.read(ordersRepositoryProvider);
  return repository.fetchProductAvgStats(
    categoryId: arg.categoryId,
    storeId: arg.storeId,
    productId: arg.productId,
  );
});

/// Provider for fetching product customer reviews & star counts (ReviewFragment)
final orderProductReviewsProvider = AutoDisposeFutureProviderFamily<
    OrderProductReviewData, OrderProductInfoArg>((ref, arg) async {
  final repository = ref.read(ordersRepositoryProvider);
  return repository.fetchProductReviews(
    categoryId: arg.categoryId,
    productId: arg.productId,
  );
});

/// Controller handling merchant actions on orders (Accept, Cancel, Ready, Ship, Deliver, Assign, Escalate, Refund, MFD/EXP)
/// NOT auto-dispose: actions may complete after the triggering widget closes
final orderActionControllerProvider =
    AsyncNotifierProvider<OrderActionController, void>(() {
  return OrderActionController();
});

class OrderActionController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    // Idle state
  }

  /// Accept order with optional delivery assistant assignment or auto-assign
  Future<OrderActionResult> acceptOrder({
    required String shopId,
    required String categoryId,
    required String orderId,
    required String expectedTime,
    String? assistantId,
    bool autoAssign = false,
    bool isEscalated = false,
    bool isSelfPickup = false,
    String? productId,
    String? correspondenceId,
  }) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(ordersRepositoryProvider);

      // If manual assistant is selected, assign assistant first
      if (assistantId != null && assistantId.isNotEmpty) {
        await repository.assignDeliveryAssistant(
          orderId: orderId,
          assistantId: assistantId,
        );
      } else if (autoAssign && !isSelfPickup) {
        await repository.autoAssignOrder(
          orderId: orderId,
          expectedDeliveryTime: expectedTime,
        );
      }

      final res = await repository.acceptOrder(
        shopId: shopId,
        categoryId: categoryId,
        orderId: orderId,
        expectedTime: expectedTime,
        isEscalated: isEscalated,
        productId: productId,
        correspondenceId: correspondenceId,
      );

      if (res.success) {
        _invalidateTabs(shopId, categoryId, [
          OrderStatus.newOrder,
          OrderStatus.processing,
          if (isEscalated) OrderStatus.replaceRefund,
        ]);
        state = const AsyncData(null);
        return res;
      }
      final msg = res.message.isNotEmpty ? res.message : 'Failed to accept order';
      state = AsyncError(msg, StackTrace.current);
      return (success: false, message: msg);
    } catch (e, stack) {
      final msg = AppSnackBar.cleanErrorMessage(e);
      state = AsyncError(msg, stack);
      return (success: false, message: msg);
    }
  }

  /// Escalate whole order (matching NewOrderFragment / OrderDetailFragment)
  Future<OrderActionResult> escalateOrder({
    required String shopId,
    required String categoryId,
    required String orderId,
  }) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(ordersRepositoryProvider);
      final res = await repository.escalateOrder(
        shopId: shopId,
        categoryId: categoryId,
        orderId: orderId,
      );

      if (res.success) {
        _invalidateTabs(shopId, categoryId, [
          OrderStatus.newOrder,
          OrderStatus.replaceRefund,
        ]);
        state = const AsyncData(null);
        return res;
      }
      final msg = res.message.isNotEmpty ? res.message : 'Failed to escalate order';
      state = AsyncError(msg, StackTrace.current);
      return (success: false, message: msg);
    } catch (e, stack) {
      final msg = AppSnackBar.cleanErrorMessage(e);
      state = AsyncError(msg, stack);
      return (success: false, message: msg);
    }
  }

  /// Assign or reassign delivery assistant to order
  Future<OrderActionResult> assignAssistant({
    required String shopId,
    required String categoryId,
    required String orderId,
    required String assistantId,
    required OrderStatus currentStatus,
  }) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(ordersRepositoryProvider);
      final res = await repository.assignDeliveryAssistant(
        orderId: orderId,
        assistantId: assistantId,
      );

      if (res.success) {
        _invalidateTabs(shopId, categoryId, [currentStatus]);
        ref.invalidate(orderInDeliveryQueueProvider(orderId));
        state = const AsyncData(null);
        return res;
      }
      final msg = res.message.isNotEmpty
          ? res.message
          : 'Failed to assign delivery assistant';
      state = AsyncError(msg, StackTrace.current);
      return (success: false, message: msg);
    } catch (e, stack) {
      final msg = AppSnackBar.cleanErrorMessage(e);
      state = AsyncError(msg, stack);
      return (success: false, message: msg);
    }
  }

  /// Put order into auto-assign delivery queue
  Future<OrderActionResult> autoAssignOrder({
    required String shopId,
    required String categoryId,
    required String orderId,
    required String expectedDeliveryTime,
    required OrderStatus currentStatus,
  }) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(ordersRepositoryProvider);
      final res = await repository.autoAssignOrder(
        orderId: orderId,
        expectedDeliveryTime: expectedDeliveryTime,
      );

      if (res.success) {
        _invalidateTabs(shopId, categoryId, [currentStatus]);
        ref.invalidate(orderInDeliveryQueueProvider(orderId));
        state = const AsyncData(null);
        return res;
      }
      final msg = res.message.isNotEmpty
          ? res.message
          : 'Failed to queue order for auto-assign';
      state = AsyncError(msg, StackTrace.current);
      return (success: false, message: msg);
    } catch (e, stack) {
      final msg = AppSnackBar.cleanErrorMessage(e);
      state = AsyncError(msg, stack);
      return (success: false, message: msg);
    }
  }

  /// Cancel order
  Future<OrderActionResult> cancelOrder({
    required String shopId,
    required String categoryId,
    required String orderId,
    required String reason,
    String message = '',
    required OrderStatus currentStatus,
  }) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(ordersRepositoryProvider);
      final res = await repository.cancelOrder(
        shopId: shopId,
        orderId: orderId,
        reason: reason,
        message: message,
      );

      if (res.success) {
        _invalidateTabs(shopId, categoryId, [
          currentStatus,
          OrderStatus.cancelled,
        ]);
        state = const AsyncData(null);
        return res;
      }
      final msg = res.message.isNotEmpty ? res.message : 'Failed to cancel order';
      state = AsyncError(msg, StackTrace.current);
      return (success: false, message: msg);
    } catch (e, stack) {
      final msg = AppSnackBar.cleanErrorMessage(e);
      state = AsyncError(msg, stack);
      return (success: false, message: msg);
    }
  }

  /// Update product MFD/EXP dates & mark product verified in Packaging
  Future<OrderActionResult> updateProductMfdExp({
    required String shopId,
    required String categoryId,
    required String orderId,
    required String productId,
    required int type,
    List<MfdExpDate> dates = const [],
    String packagingType = 'manual',
    bool isEscalated = false,
  }) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(ordersRepositoryProvider);
      final res = await repository.updateProductMfdExp(
        shopId: shopId,
        categoryId: categoryId,
        orderId: orderId,
        productId: productId,
        type: type,
        dates: dates,
        packagingType: packagingType,
      );

      if (res.success) {
        ref.invalidate(orderProductsProvider((
          orderId: orderId,
          shopId: shopId,
          categoryId: categoryId,
          isEscalated: isEscalated,
        )));
        state = const AsyncData(null);
        return res;
      }
      final msg = res.message.isNotEmpty
          ? res.message
          : 'Failed to update MFD/EXP dates';
      state = AsyncError(msg, StackTrace.current);
      return (success: false, message: msg);
    } catch (e, stack) {
      final msg = AppSnackBar.cleanErrorMessage(e);
      state = AsyncError(msg, stack);
      return (success: false, message: msg);
    }
  }

  /// Mark order ready to ship / dispatched (supports both all-checked readyToShip and directDispatch)
  Future<OrderActionResult> markReadyToShip({
    required String shopId,
    required String categoryId,
    required String orderId,
    bool directDispatch = false,
  }) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(ordersRepositoryProvider);
      final res = directDispatch
          ? await repository.directDispatchOrder(
              shopId: shopId,
              categoryId: categoryId,
              orderId: orderId,
            )
          : await repository.readyToShipOrder(
              shopId: shopId,
              categoryId: categoryId,
              orderId: orderId,
            );

      if (res.success) {
        _invalidateTabs(shopId, categoryId, [
          OrderStatus.processing,
          OrderStatus.ready,
        ]);
        state = const AsyncData(null);
        return res;
      }
      final msg = res.message.isNotEmpty ? res.message : 'Failed to dispatch order';
      state = AsyncError(msg, StackTrace.current);
      return (success: false, message: msg);
    } catch (e, stack) {
      final msg = AppSnackBar.cleanErrorMessage(e);
      state = AsyncError(msg, stack);
      return (success: false, message: msg);
    }
  }

  /// Ship order (move to On The Way)
  Future<OrderActionResult> shipOrder({
    required String shopId,
    required String categoryId,
    required String orderId,
  }) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(ordersRepositoryProvider);
      final res = await repository.shipOrder(
        shopId: shopId,
        categoryId: categoryId,
        orderId: orderId,
      );

      if (res.success) {
        _invalidateTabs(shopId, categoryId, [
          OrderStatus.ready,
          OrderStatus.onTheWay,
        ]);
        state = const AsyncData(null);
        return res;
      }
      final msg = res.message.isNotEmpty ? res.message : 'Failed to ship order';
      state = AsyncError(msg, StackTrace.current);
      return (success: false, message: msg);
    } catch (e, stack) {
      final msg = AppSnackBar.cleanErrorMessage(e);
      state = AsyncError(msg, stack);
      return (success: false, message: msg);
    }
  }

  /// Deliver order (complete order)
  Future<OrderActionResult> deliverOrder({
    required String shopId,
    required String categoryId,
    required String orderId,
    OrderStatus currentStatus = OrderStatus.onTheWay,
  }) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(ordersRepositoryProvider);
      final res = await repository.deliverOrder(
        shopId: shopId,
        categoryId: categoryId,
        orderId: orderId,
      );

      if (res.success) {
        _invalidateTabs(shopId, categoryId, [
          currentStatus,
          OrderStatus.delivered,
        ]);
        state = const AsyncData(null);
        return res;
      }
      final msg = res.message.isNotEmpty ? res.message : 'Failed to deliver order';
      state = AsyncError(msg, StackTrace.current);
      return (success: false, message: msg);
    } catch (e, stack) {
      final msg = AppSnackBar.cleanErrorMessage(e);
      state = AsyncError(msg, stack);
      return (success: false, message: msg);
    }
  }

  /// Initiate refund for whole escalated order
  Future<OrderActionResult> refundOrder({
    required String shopId,
    required String categoryId,
    required String orderId,
    bool isRequest = false,
  }) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(ordersRepositoryProvider);
      final res = await repository.refundOrder(
        shopId: shopId,
        categoryId: categoryId,
        orderId: orderId,
        isRequest: isRequest,
      );

      if (res.success) {
        _invalidateTabs(shopId, categoryId, [
          OrderStatus.newOrder,
          OrderStatus.replaceRefund,
        ]);
        state = const AsyncData(null);
        return res;
      }
      final msg = res.message.isNotEmpty
          ? res.message
          : 'Failed to initiate refund';
      state = AsyncError(msg, StackTrace.current);
      return (success: false, message: msg);
    } catch (e, stack) {
      final msg = AppSnackBar.cleanErrorMessage(e);
      state = AsyncError(msg, stack);
      return (success: false, message: msg);
    }
  }

  /// Accept individual escalated product
  Future<OrderActionResult> acceptEscalatedProduct({
    required String shopId,
    required String categoryId,
    required String orderId,
    required String productId,
    String? correspondenceId,
  }) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(ordersRepositoryProvider);
      final res = await repository.acceptEscalatedProduct(
        shopId: shopId,
        categoryId: categoryId,
        orderId: orderId,
        productId: productId,
        correspondenceId: correspondenceId,
      );

      if (res.success) {
        ref.invalidate(orderProductsProvider((
          orderId: orderId,
          shopId: shopId,
          categoryId: categoryId,
          isEscalated: true,
        )));
        ref.invalidate(escalationChatProvider((
          shopId: shopId,
          categoryId: categoryId,
          orderId: orderId,
          productId: productId,
        )));
        state = const AsyncData(null);
        return res;
      }
      final msg = res.message.isNotEmpty ? res.message : 'Failed to accept product';
      state = AsyncError(msg, StackTrace.current);
      return (success: false, message: msg);
    } catch (e, stack) {
      final msg = AppSnackBar.cleanErrorMessage(e);
      state = AsyncError(msg, stack);
      return (success: false, message: msg);
    }
  }

  /// Accept escalation template correspondence
  Future<OrderActionResult> acceptEscalationTemplate({
    required String shopId,
    required String categoryId,
    required String orderId,
    required String productId,
    required String correspondenceId,
  }) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(ordersRepositoryProvider);
      final res = await repository.acceptEscalationTemplate(
        shopId: shopId,
        categoryId: categoryId,
        orderId: orderId,
        productId: productId,
        correspondenceId: correspondenceId,
      );

      if (res.success) {
        ref.invalidate(escalationChatProvider((
          shopId: shopId,
          categoryId: categoryId,
          orderId: orderId,
          productId: productId,
        )));
        state = const AsyncData(null);
        return res;
      }
      final msg = res.message.isNotEmpty ? res.message : 'Failed to accept template';
      state = AsyncError(msg, StackTrace.current);
      return (success: false, message: msg);
    } catch (e, stack) {
      final msg = AppSnackBar.cleanErrorMessage(e);
      state = AsyncError(msg, stack);
      return (success: false, message: msg);
    }
  }

  /// Deny escalation template correspondence (matching ApiService.callDeny)
  Future<OrderActionResult> denyEscalationTemplate({
    required String shopId,
    required String categoryId,
    required String orderId,
    required String productId,
    required String correspondenceId,
  }) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(ordersRepositoryProvider);
      final res = await repository.denyEscalationTemplate(
        shopId: shopId,
        categoryId: categoryId,
        orderId: orderId,
        productId: productId,
        correspondenceId: correspondenceId,
      );

      if (res.success) {
        ref.invalidate(escalationChatProvider((
          shopId: shopId,
          categoryId: categoryId,
          orderId: orderId,
          productId: productId,
        )));
        state = const AsyncData(null);
        return res;
      }
      final msg = res.message.isNotEmpty ? res.message : 'Failed to deny template';
      state = AsyncError(msg, StackTrace.current);
      return (success: false, message: msg);
    } catch (e, stack) {
      final msg = AppSnackBar.cleanErrorMessage(e);
      state = AsyncError(msg, stack);
      return (success: false, message: msg);
    }
  }

  /// Delete correspondence message (matching ApiService.callDeleteMessage)
  Future<OrderActionResult> deleteEscalationCorrespondence({
    required String shopId,
    required String categoryId,
    required String orderId,
    required String productId,
    required String correspondenceId,
  }) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(ordersRepositoryProvider);
      final res = await repository.deleteEscalationCorrespondence(
        shopId: shopId,
        categoryId: categoryId,
        orderId: orderId,
        productId: productId,
        correspondenceId: correspondenceId,
      );

      if (res.success) {
        ref.invalidate(escalationChatProvider((
          shopId: shopId,
          categoryId: categoryId,
          orderId: orderId,
          productId: productId,
        )));
        state = const AsyncData(null);
        return res;
      }
      final msg = res.message.isNotEmpty
          ? res.message
          : 'Failed to delete correspondence';
      state = AsyncError(msg, StackTrace.current);
      return (success: false, message: msg);
    } catch (e, stack) {
      final msg = AppSnackBar.cleanErrorMessage(e);
      state = AsyncError(msg, stack);
      return (success: false, message: msg);
    }
  }

  /// Escalate / decline individual product
  Future<OrderActionResult> escalateProduct({
    required String shopId,
    required String categoryId,
    required String orderId,
    required String productId,
    String? message,
  }) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(ordersRepositoryProvider);
      final res = await repository.escalateProduct(
        shopId: shopId,
        categoryId: categoryId,
        orderId: orderId,
        productId: productId,
        message: message,
      );

      if (res.success) {
        ref.invalidate(orderProductsProvider((
          orderId: orderId,
          shopId: shopId,
          categoryId: categoryId,
          isEscalated: true,
        )));
        ref.invalidate(escalationChatProvider((
          shopId: shopId,
          categoryId: categoryId,
          orderId: orderId,
          productId: productId,
        )));
        state = const AsyncData(null);
        return res;
      }
      final msg = res.message.isNotEmpty ? res.message : 'Failed to escalate product';
      state = AsyncError(msg, StackTrace.current);
      return (success: false, message: msg);
    } catch (e, stack) {
      final msg = AppSnackBar.cleanErrorMessage(e);
      state = AsyncError(msg, stack);
      return (success: false, message: msg);
    }
  }

  /// Refund individual escalated product
  Future<OrderActionResult> refundEscalatedProduct({
    required String shopId,
    required String categoryId,
    required String orderId,
    required String productId,
    bool isRequest = false,
  }) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(ordersRepositoryProvider);
      final res = await repository.refundEscalatedProduct(
        shopId: shopId,
        categoryId: categoryId,
        orderId: orderId,
        productId: productId,
        isRequest: isRequest,
      );

      if (res.success) {
        ref.invalidate(orderProductsProvider((
          orderId: orderId,
          shopId: shopId,
          categoryId: categoryId,
          isEscalated: true,
        )));
        _invalidateTabs(shopId, categoryId, [
          OrderStatus.newOrder,
          OrderStatus.replaceRefund,
        ]);
        state = const AsyncData(null);
        return res;
      }
      final msg = res.message.isNotEmpty ? res.message : 'Failed to refund product';
      state = AsyncError(msg, StackTrace.current);
      return (success: false, message: msg);
    } catch (e, stack) {
      final msg = AppSnackBar.cleanErrorMessage(e);
      state = AsyncError(msg, stack);
      return (success: false, message: msg);
    }
  }

  /// Send message to customer
  Future<OrderActionResult> sendCustomerMessage({
    required String orderId,
    required String storeId,
    required String message,
  }) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(ordersRepositoryProvider);
      final res = await repository.sendCustomerMessage(
        orderId: orderId,
        storeId: storeId,
        message: message,
      );
      state = const AsyncData(null);
      return res;
    } catch (e, stack) {
      final msg = AppSnackBar.cleanErrorMessage(e);
      state = AsyncError(msg, stack);
      return (success: false, message: msg);
    }
  }

  /// Generate / send invoice PDF (flag 1 = Share, flag 2 = Send to Seller/Customer)
  Future<InvoiceResult> generateInvoice({
    required String orderId,
    required int flag,
  }) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(ordersRepositoryProvider);
      final res = await repository.generateInvoice(
        orderId: orderId,
        flag: flag,
      );
      state = const AsyncData(null);
      return res;
    } catch (e, stack) {
      state = AsyncError(e, stack);
      return InvoiceResult(isSuccess: false, message: e.toString());
    }
  }

  void _invalidateTabs(
      String shopId, String categoryId, List<OrderStatus> statuses) {
    ref.invalidate(orderCountsProvider(shopId));
    for (final s in statuses) {
      ref.invalidate(ordersListProvider((
        shopId: shopId,
        categoryId: categoryId,
        status: s,
      )));
    }
  }
}
