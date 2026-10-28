import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayfay_merchant_flutter/core/network/api_client.dart';
import 'package:bayfay_merchant_flutter/core/network/api_endpoints.dart';
import '../model/billing_model.dart';

final billingRepositoryProvider = Provider<BillingRepository>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return BillingRepository(apiClient);
});

class BillingRepository {
  final ApiClient _apiClient;

  const BillingRepository(this._apiClient);

  /// Fetch paginated transactions list matching Android callTransaction (@POST "merchant/transactions")
  Future<List<BillingTransaction>> getTransactions({
    required String shopId,
    required String fromDate,
    required String toDate,
    int skip = 0,
    int limit = 30,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.merchantTransactions,
        data: {
          'from': fromDate,
          'to': toDate,
          'skip': skip,
          'limit': limit,
          'shop_id': shopId,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['success'] == true) {
        final innerData = data['data'];
        if (innerData is Map<String, dynamic>) {
          final list = innerData['transactions'];
          if (list is List) {
            return list
                .whereType<Map<String, dynamic>>()
                .map((item) => BillingTransaction.fromJson(item))
                .toList();
          }
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Fetch debits/credits summary metrics matching Android callGetTransactionDetails (@POST "merchant/accounts")
  Future<BillingSummaryModel?> getAccountsSummary({
    required String shopId,
    required String fromDate,
    required String toDate,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.merchantAccounts,
        data: {
          'from': fromDate,
          'to': toDate,
          'shop_id': shopId,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['success'] == true) {
        final innerData = data['data'];
        if (innerData is Map<String, dynamic>) {
          return BillingSummaryModel.fromJson(innerData);
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
