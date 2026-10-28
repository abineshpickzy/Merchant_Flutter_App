import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayfay_merchant_flutter/core/network/api_client.dart';
import 'package:bayfay_merchant_flutter/core/network/api_endpoints.dart';
import '../model/order_model.dart';

/// Standard result record for order action APIs capturing success flag and backend message
typedef OrderActionResult = ({bool success, String message});

class InvoiceResult {
  final bool isSuccess;
  final String? data;
  final String? message;

  const InvoiceResult({
    required this.isSuccess,
    this.data,
    this.message,
  });
}

final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return OrdersRepository(apiClient);
});

class OrdersRepository {
  final ApiClient _apiClient;

  const OrdersRepository(this._apiClient);

  OrderActionResult _parseActionResult(dynamic data) {
    if (data is Map<String, dynamic>) {
      return (
        success: data['success'] as bool? ?? true,
        message: data['message']?.toString() ?? '',
      );
    }
    return (success: true, message: '');
  }

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

  /// Fetch tab counts for orders (matching ApiService.getOrderDetailsCount)
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

  /// Accept incoming new order (matching ApiService.callOrderAcceptNewApi & callOrderEscalateAcceptNewApi)
  Future<OrderActionResult> acceptOrder({
    required String shopId,
    required String categoryId,
    required String orderId,
    required String expectedTime,
    bool isEscalated = false,
    String? productId,
    String? correspondenceId,
  }) async {
    final endpoint = isEscalated
        ? ApiEndpoints.orderEscalateAccept
        : ApiEndpoints.orderAccept;
    final response = await _apiClient.patch(
      endpoint,
      data: {
        'category_id': categoryId,
        'shop_id': shopId,
        'order_id': orderId,
        'expectedTime': expectedTime,
        if (isEscalated && productId != null && productId.isNotEmpty)
          'product_id': productId,
        if (isEscalated &&
            correspondenceId != null &&
            correspondenceId.isNotEmpty)
          'correspondence_id': correspondenceId,
      },
      requiresAuth: true,
    );

    return _parseActionResult(response.data);
  }

  /// Escalate whole order (matching ApiService.callOrderEscalatedNewApi)
  Future<OrderActionResult> escalateOrder({
    required String shopId,
    required String categoryId,
    required String orderId,
  }) async {
    final response = await _apiClient.patch(
      ApiEndpoints.orderEscalateOrder,
      data: {
        'shop_id': shopId,
        'category_id': categoryId,
        'order_id': orderId,
      },
      requiresAuth: true,
    );

    return _parseActionResult(response.data);
  }

  /// Auto-assign delivery assistant (matching ApiService.autoAssignEnableOrder)
  Future<OrderActionResult> autoAssignOrder({
    required String orderId,
    required String expectedDeliveryTime,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.deliveryAssistantAutoAssign,
      data: {
        'order_id': orderId,
        'expected_delivery_time': expectedDeliveryTime,
        'auto_assign': true,
      },
      requiresAuth: true,
    );

    return _parseActionResult(response.data);
  }

  /// Check if order is in auto-assign delivery queue (matching ApiService.getQueuedOrders)
  Future<bool> checkOrderInDeliveryQueue({required String orderId}) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.deliveryAssistantAutoAssignView,
        data: {'order_id': orderId},
        requiresAuth: true,
      );
      if (response.data is Map<String, dynamic>) {
        final map = response.data as Map<String, dynamic>;
        // In Android PackageDetailsFragment.java line 800: QueueOrderViewRsp.getSuccess() indicates order in queue
        return map['success'] == true;
      }
    } catch (_) {
      // Fall through
    }
    return false;
  }

  /// Fetch available active delivery associates (matching ApiService.getActiveAssignData)
  Future<List<DeliveryAssistantModel>> fetchActiveDeliveryAssistants({
    required String orderId,
    required String expectedDeliveryTime,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.deliveryAssistantActiveList,
        data: {
          'order_id': orderId,
          'expected_delivery_time': expectedDeliveryTime,
        },
        requiresAuth: true,
      );

      if (response.data is Map<String, dynamic>) {
        final map = response.data as Map<String, dynamic>;
        final rawData = map['data'];
        if (rawData is List) {
          return rawData
              .whereType<Map<String, dynamic>>()
              .map((json) => DeliveryAssistantModel.fromJson(json))
              .toList();
        }
      }
    } catch (_) {
      // Fall through
    }
    return const [];
  }

  /// Fetch assigned delivery person info & live location (matching ApiService.GetDeliveryPersonLocation)
  Future<Map<String, dynamic>?> fetchDeliveryPersonInfo(
      String assistantId) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.deliveryAssistantLocation(assistantId),
        requiresAuth: true,
      );
      if (response.data is Map<String, dynamic>) {
        final map = response.data as Map<String, dynamic>;
        final rawData = map['data'];
        if (rawData is List &&
            rawData.isNotEmpty &&
            rawData.first is Map<String, dynamic>) {
          return rawData.first as Map<String, dynamic>;
        }
        if (rawData is Map<String, dynamic>) {
          return rawData;
        }
        return map;
      }
    } catch (_) {
      // Fall through
    }
    return null;
  }

  /// Assign specific delivery assistant to order (matching ApiService.setDeliveryAssistance)
  Future<OrderActionResult> assignDeliveryAssistant({
    required String orderId,
    required String assistantId,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.deliveryAssistantAssign,
      data: {
        'order_id': orderId,
        'assistant_id': assistantId,
      },
      requiresAuth: true,
    );

    return _parseActionResult(response.data);
  }

  /// Cancel an order with reason (matching ApiService.callOrderCancelNewApi)
  Future<OrderActionResult> cancelOrder({
    required String shopId,
    required String orderId,
    required String reason,
    String message = '',
  }) async {
    final data = <String, dynamic>{
      'shop_id': shopId,
      'order_id': orderId,
      'title': reason,
    };
    if (message.trim().isNotEmpty) {
      data['message'] = message.trim();
    }

    final response = await _apiClient.post(
      ApiEndpoints.orderCancel,
      data: data,
      requiresAuth: true,
    );

    return _parseActionResult(response.data);
  }

  /// Fetch official cancel reason titles from backend (matching ApiService.getCancelTitles)
  Future<List<CancelReasonItem>> fetchCancelReasons() async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.orderCancelReasons,
        requiresAuth: true,
      );

      if (response.data is Map<String, dynamic>) {
        final map = response.data as Map<String, dynamic>;
        final rawData = map['data'];
        if (rawData is List) {
          return rawData
              .whereType<Map<String, dynamic>>()
              .map((json) => CancelReasonItem.fromJson(json))
              .toList();
        }
      }
    } catch (_) {
      // Return empty so caller can use defaults
    }
    return const [];
  }

  /// Fetch customer contact message templates (matching ApiService.getCustomerContactTemplate)
  Future<List<CustomerContactTemplate>> fetchContactTemplates({
    String? shopId,
    String? orderId,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.orderMsgTemplate,
        data: {
          if (shopId != null && shopId.isNotEmpty) 'store_id': shopId,
          if (orderId != null && orderId.isNotEmpty) 'order_id': orderId,
        },
        requiresAuth: true,
      );

      if (response.data is Map<String, dynamic>) {
        final map = response.data as Map<String, dynamic>;
        final rawData = map['data'];
        if (rawData is List) {
          return rawData
              .whereType<Map<String, dynamic>>()
              .map((json) => CustomerContactTemplate.fromJson(json))
              .toList();
        }
      }
    } catch (_) {
      // Return default templates fallback
    }
    return const [
      CustomerContactTemplate(
        id: '1',
        message: 'Your order is being packed and will be dispatched shortly.',
      ),
      CustomerContactTemplate(
        id: '2',
        message: 'One or more items in your order are out of stock. Please contact the store.',
      ),
      CustomerContactTemplate(
        id: '3',
        message: 'Your order is ready for pickup at the store.',
      ),
    ];
  }

  /// Send push & SMS message to customer (matching ApiService.sendCustomerContactMessage)
  Future<OrderActionResult> sendCustomerMessage({
    required String orderId,
    required String storeId,
    required String message,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.orderSendMessage,
      data: {
        'order_id': orderId,
        'store_id': storeId,
        'message': message,
      },
      requiresAuth: true,
    );

    return _parseActionResult(response.data);
  }

  /// Look up product ID by UPC / barcode / SKU matching Android getStatusUsingUPS
  /// GET inventory/upc/{categoryId}/{storeId}/{barcode}
  Future<String?> lookupProductByBarcode({
    required String categoryId,
    required String shopId,
    required String barcode,
  }) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.inventoryUpcStatus(categoryId, shopId, barcode.trim()),
        requiresAuth: true,
      );
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        final success = data['success'] == true;
        if (success && data['data'] != null && data['data'] is Map<String, dynamic>) {
          final d = data['data'] as Map<String, dynamic>;
          final prod = d['product'];
          if (prod is Map<String, dynamic>) {
            final id = prod['_id'] ?? prod['id'];
            if (id != null && id.toString().isNotEmpty) {
              return id.toString();
            }
          }
          final prods = d['products'];
          if (prods is Map<String, dynamic>) {
            final id = prods['id'] ?? prods['_id'];
            if (id != null && id.toString().isNotEmpty) {
              return id.toString();
            }
          }
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Update product MFD/EXP dates & verification status (matching ApiService.callUpdateDatesNewApi)
  /// type: 1 = specific dates, 2 = Unknown, 3 = Not Applicable
  Future<OrderActionResult> updateProductMfdExp({
    required String shopId,
    required String categoryId,
    required String orderId,
    required String productId,
    required int type,
    List<MfdExpDate> dates = const [],
    String packagingType = 'manual',
  }) async {
    final mfdExpPayload = <String, dynamic>{
      'type': type,
      if (type == 1 && dates.isNotEmpty)
        'dates': dates.map((d) => d.toJson()).toList(),
    };

    final response = await _apiClient.patch(
      ApiEndpoints.orderUpdateMfdExp,
      data: {
        'mfd_exp': mfdExpPayload,
        'packaging_type': packagingType,
        'product_id': productId,
        'order_id': orderId,
        'shop_id': shopId,
        'category_id': categoryId,
      },
      requiresAuth: true,
    );

    return _parseActionResult(response.data);
  }

  /// Mark order ready to ship when all products checked (matching ApiService.callOrderDispatchedNewApi)
  Future<OrderActionResult> readyToShipOrder({
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

    return _parseActionResult(response.data);
  }

  /// Direct dispatch order without checking all products (matching ApiService.callOrderDirectDispatched)
  Future<OrderActionResult> directDispatchOrder({
    required String shopId,
    required String categoryId,
    required String orderId,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.orderDirectDispatched,
      data: {
        'category_id': categoryId,
        'shop_id': shopId,
        'order_id': orderId,
      },
      requiresAuth: true,
    );

    return _parseActionResult(response.data);
  }

  /// Move order to shipping / On the way (matching ApiService.callOrderShipOrderNewApi)
  Future<OrderActionResult> shipOrder({
    required String shopId,
    required String categoryId,
    required String orderId,
  }) async {
    final response = await _apiClient.patch(
      ApiEndpoints.orderShip,
      data: {
        'category_id': categoryId,
        'shop_id': shopId,
        'order_id': orderId,
      },
      requiresAuth: true,
    );

    return _parseActionResult(response.data);
  }

  /// Deliver order (matching ApiService.callOrderDeliveredNewApi)
  Future<OrderActionResult> deliverOrder({
    required String shopId,
    required String categoryId,
    required String orderId,
  }) async {
    final response = await _apiClient.patch(
      ApiEndpoints.orderDeliver,
      data: {
        'category_id': categoryId,
        'shop_id': shopId,
        'order_id': orderId,
      },
      requiresAuth: true,
    );

    return _parseActionResult(response.data);
  }

  /// Fetch order products breakdown (matching ApiService.callOrderDetailNewApi & callOrderDetailEscalatedNewApi)
  Future<List<OrderProductItem>> fetchOrderProducts({
    required String orderId,
    required String shopId,
    required String categoryId,
    bool isEscalated = false,
  }) async {
    final endpoint = isEscalated
        ? ApiEndpoints.orderEscalateProducts
        : ApiEndpoints.orderProducts;
    final response = await _apiClient.post(
      endpoint,
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

  /// Initiate refund for whole escalated order (matching ApiService.callOrderRefundInitiateApi & callRefundForOrderRequestApi)
  Future<OrderActionResult> refundOrder({
    required String shopId,
    required String categoryId,
    required String orderId,
    bool isRequest = false,
  }) async {
    final endpoint = isRequest
        ? ApiEndpoints.orderEscalateRefundRequest
        : ApiEndpoints.orderEscalateRefund;
    final response = await _apiClient.patch(
      endpoint,
      data: {
        'shop_id': shopId,
        'category_id': categoryId,
        'order_id': orderId,
      },
      requiresAuth: true,
    );

    return _parseActionResult(response.data);
  }

  /// Accept individual escalated product (matching ApiService.callEscalateAcceptProduct)
  Future<OrderActionResult> acceptEscalatedProduct({
    required String shopId,
    required String categoryId,
    required String orderId,
    required String productId,
    String? correspondenceId,
  }) async {
    final response = await _apiClient.patch(
      ApiEndpoints.orderEscalateAcceptProduct,
      data: {
        'shop_id': shopId,
        'category_id': categoryId,
        'order_id': orderId,
        'product_id': productId,
        if (correspondenceId != null && correspondenceId.isNotEmpty)
          'correspondence_id': correspondenceId,
      },
      requiresAuth: true,
    );

    return _parseActionResult(response.data);
  }

  /// Accept template correspondence message (matching ApiService.callAccept -> POST order/escalate/acceptTemplate)
  Future<OrderActionResult> acceptEscalationTemplate({
    required String shopId,
    required String categoryId,
    required String orderId,
    required String productId,
    required String correspondenceId,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.orderEscalateAcceptTemplate,
      data: {
        'category_id': categoryId,
        'shop_id': shopId,
        'order_id': orderId,
        'product_id': productId,
        'correspondence_id': correspondenceId,
      },
      requiresAuth: true,
    );

    return _parseActionResult(response.data);
  }

  /// Deny template correspondence message (matching ApiService.callDeny -> POST order/escalate/denyTemplate)
  Future<OrderActionResult> denyEscalationTemplate({
    required String shopId,
    required String categoryId,
    required String orderId,
    required String productId,
    required String correspondenceId,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.orderEscalateDenyTemplate,
      data: {
        'category_id': categoryId,
        'shop_id': shopId,
        'order_id': orderId,
        'product_id': productId,
        'correspondence_id': correspondenceId,
      },
      requiresAuth: true,
    );

    return _parseActionResult(response.data);
  }

  /// Delete correspondence message (matching ApiService.callDeleteMessage -> DELETE order/escalate/deleteCorrespondence)
  Future<OrderActionResult> deleteEscalationCorrespondence({
    required String shopId,
    required String categoryId,
    required String orderId,
    required String productId,
    required String correspondenceId,
  }) async {
    final response = await _apiClient.delete(
      ApiEndpoints.orderEscalateDeleteCorrespondence,
      data: {
        'category_id': categoryId,
        'shop_id': shopId,
        'order_id': orderId,
        'product_id': productId,
        'correspondence_id': correspondenceId,
      },
      requiresAuth: true,
    );

    return _parseActionResult(response.data);
  }

  /// Escalate / decline individual product (matching ApiService.callEscalateProduct)
  Future<OrderActionResult> escalateProduct({
    required String shopId,
    required String categoryId,
    required String orderId,
    required String productId,
    String? message,
  }) async {
    final response = await _apiClient.patch(
      ApiEndpoints.orderEscalateProduct,
      data: {
        'shop_id': shopId,
        'category_id': categoryId,
        'order_id': orderId,
        'product_id': productId,
        if (message != null && message.trim().isNotEmpty)
          'message': message.trim(),
      },
      requiresAuth: true,
    );

    return _parseActionResult(response.data);
  }

  /// Refund individual escalated product (matching ApiService.callEscalateRefund & callEscalateRefundRequest)
  Future<OrderActionResult> refundEscalatedProduct({
    required String shopId,
    required String categoryId,
    required String orderId,
    required String productId,
    bool isRequest = false,
  }) async {
    final endpoint = isRequest
        ? ApiEndpoints.orderEscalateRefundProductRequest
        : ApiEndpoints.orderEscalateRefundProduct;
    final response = await _apiClient.patch(
      endpoint,
      data: {
        'shop_id': shopId,
        'category_id': categoryId,
        'order_id': orderId,
        'product_id': productId,
      },
      requiresAuth: true,
    );

    return _parseActionResult(response.data);
  }

  /// Fetch escalation correspondence chat messages (matching ApiService.callOrderDetailEscalatedMessageNewApi)
  Future<List<EscalationChatMessage>> fetchEscalationCorrespondence({
    required String shopId,
    required String categoryId,
    required String orderId,
    required String productId,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.orderEscalateViewCorrespondence,
        data: {
          'shop_id': shopId,
          'category_id': categoryId,
          'order_id': orderId,
          'product_id': productId,
        },
        requiresAuth: true,
      );

      if (response.data is Map<String, dynamic>) {
        final map = response.data as Map<String, dynamic>;
        final data = map['data'];
        if (data is Map<String, dynamic>) {
          final chatObj = data['chat'];
          if (chatObj is Map<String, dynamic> && chatObj['chat'] is List) {
            return (chatObj['chat'] as List)
                .whereType<Map<String, dynamic>>()
                .map((json) => EscalationChatMessage.fromJson(json))
                .toList();
          } else if (chatObj is List) {
            return chatObj
                .whereType<Map<String, dynamic>>()
                .map((json) => EscalationChatMessage.fromJson(json))
                .toList();
          }
        }
      }
    } catch (_) {
      // Return empty list if none
    }
    return const [];
  }

  /// Generate or send invoice PDF (matching ApiService.generatePdfFile)
  /// flag: 1 = generate/share PDF, 2 = send to seller/customer
  Future<InvoiceResult> generateInvoice({
    required String orderId,
    required int flag,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.orderInvoiceSent,
        data: {
          'order_id': orderId,
          'flag': flag,
        },
        requiresAuth: true,
      );

      if (response.data is Map<String, dynamic>) {
        final map = response.data as Map<String, dynamic>;
        final success = map['success'] == true;
        final data = map['data']?.toString();
        final message = map['message']?.toString();
        return InvoiceResult(
          isSuccess: success,
          data: data,
          message: message ?? (success ? 'Success' : 'Failed'),
        );
      }
      return const InvoiceResult(
        isSuccess: false,
        message: 'Invalid response from server',
      );
    } catch (e) {
      return InvoiceResult(
        isSuccess: false,
        message: e.toString(),
      );
    }
  }

  /// Fetch full product details for Product Info screen (matching ApiService.callViewGetProducts)
  Future<OrderProductDetailData> fetchProductFullDetails({
    required String categoryId,
    required String storeId,
    required String productId,
    required String type,
  }) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.inventoryProductView(categoryId, storeId, productId, type),
        requiresAuth: true,
      );
      if (response.data is Map<String, dynamic>) {
        return OrderProductDetailData.fromJson(
          response.data as Map<String, dynamic>,
        );
      }
    } catch (_) {
      // Fall through
    }
    return const OrderProductDetailData();
  }

  /// Fetch product average price & customer rating (matching ApiService.callAverage)
  Future<OrderProductAvgData> fetchProductAvgStats({
    required String categoryId,
    required String storeId,
    required String productId,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.productAvgPriceRating,
        data: {
          '_id': categoryId,
          'store_id': storeId,
          'product': productId,
        },
        requiresAuth: true,
      );
      if (response.data is Map<String, dynamic>) {
        return OrderProductAvgData.fromJson(
          response.data as Map<String, dynamic>,
        );
      }
    } catch (_) {
      // Fall through
    }
    return const OrderProductAvgData();
  }

  /// Fetch product customer reviews & star counts (matching ApiService.callReviewList)
  Future<OrderProductReviewData> fetchProductReviews({
    required String categoryId,
    required String productId,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.inventoryProductReviews,
        data: {
          'product': productId,
          '_id': categoryId,
        },
        requiresAuth: true,
      );
      if (response.data is Map<String, dynamic>) {
        return OrderProductReviewData.fromJson(
          response.data as Map<String, dynamic>,
        );
      }
    } catch (_) {
      // Fall through
    }
    return const OrderProductReviewData();
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
