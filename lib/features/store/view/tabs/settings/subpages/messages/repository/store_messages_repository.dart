import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayfay_merchant_flutter/core/network/api_client.dart';
import 'package:bayfay_merchant_flutter/core/network/api_endpoints.dart';
import '../model/store_messages_model.dart';

final storeMessagesRepositoryProvider = Provider<StoreMessagesRepository>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return StoreMessagesRepository(apiClient);
});

class StoreMessagesRepository {
  final ApiClient _apiClient;

  const StoreMessagesRepository(this._apiClient);

  /// Fetch order chat threads matching Android callGetChatList (@POST "order/escalate/messages/current")
  Future<List<StoreMessageItem>> getChatList({
    required String storeId,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.orderEscalateMessagesCurrent,
        data: {
          'store_id': storeId,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['success'] == true) {
        final list = data['data'];
        if (list is List) {
          return list
              .whereType<Map<String, dynamic>>()
              .map((item) => StoreMessageItem.fromJson(item))
              .toList();
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}
