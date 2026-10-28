import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:bayfay_merchant_flutter/core/network/api_endpoints.dart';
import 'package:bayfay_merchant_flutter/features/dashboard/controller/dashboard_controller.dart';
import '../../model/billing_model.dart';
import 'billing_transaction_details_dialog.dart';

/// Single transaction card matching Android single_history_transactions.xml & HistoryTransactionAdapter
class BillingTransactionCard extends ConsumerWidget {
  final BillingTransaction transaction;

  const BillingTransactionCard({
    super.key,
    required this.transaction,
  });

  String _formatDate(String isoString) {
    if (isoString.isEmpty) return '-';
    try {
      final parsed = DateTime.parse(isoString);
      return DateFormat('dd MMM yyyy').format(parsed);
    } catch (_) {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = transaction.order;
    final txDetail = order.transaction;

    // Service fee calculation matching Android HistoryTransactionAdapter:
    double serviceFee = order.serviceFee;
    if ((txDetail.type == 2 || txDetail.type == 1) &&
        (txDetail.serviceFee != 0.0 || txDetail.paymentFee != 0.0)) {
      if (txDetail.serviceFee != 0.0) serviceFee += txDetail.serviceFee;
      if (txDetail.paymentFee != 0.0) serviceFee += txDetail.paymentFee;
    }

    // Status & Date labels matching Android HistoryTransactionAdapter:
    String statusLabel = 'Pending';
    String datePrefix = txDetail.type == 1 ? 'Credit date : ' : 'Debit date : ';
    final isSettled = txDetail.status == 2;

    if (isSettled) {
      if (txDetail.type == 1) {
        statusLabel = 'Credited';
        datePrefix = 'Credited date : ';
      } else {
        statusLabel = 'Debited';
        datePrefix = 'Debited date : ';
      }
    }

    final dateText = datePrefix + _formatDate(txDetail.expectedAt);

    // Card background: #FAFAFA when settled/credited, #E0E0E0 when pending
    final cardBgColor = isSettled ? const Color(0xFFFAFAFA) : const Color(0xFFE0E0E0);

    // Category & shop image URL resolving with secure auth headers and store fallback
    String imageUrl = transaction.shop.getImageUrl(ApiEndpoints.baseUrl);
    if (imageUrl.isEmpty) {
      final selectedStore = ref.watch(selectedStoreProvider);
      if (selectedStore != null) {
        imageUrl = selectedStore.getImageUrl(ApiEndpoints.baseUrl);
      }
    }
    final authHeaderAsync = ref.watch(authHeaderProvider);
    final headers = authHeaderAsync.valueOrNull ?? {};

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      constraints: const BoxConstraints(minHeight: 110),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: const Color(0xFFD6D6D6), width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: 85x85 image thumbnail with shimmer loading placeholder
          Container(
            width: 85,
            height: 85,
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      headers: headers.isNotEmpty ? headers : null,
                      fit: BoxFit.cover,
                      errorBuilder: (_, error, _) => const Center(
                        child: Icon(
                          Icons.storefront_outlined,
                          size: 38,
                          color: Color(0xFF9E9E9E),
                        ),
                      ),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(
                            width: 85,
                            height: 85,
                            color: Colors.white,
                          ),
                        );
                      },
                    )
                  : const Center(
                      child: Icon(
                        Icons.storefront_outlined,
                        size: 38,
                        color: Color(0xFF9E9E9E),
                      ),
                    ),
            ),
          ),

          // Center: Order ID, Purchase Amount, Service Fee matching Android
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    order.id,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Purchase Amount : ${order.amount.toStringAsFixed(2)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Service fee : ${serviceFee.toStringAsFixed(2)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Right: Date, Amount, Status, and Underlined Invoice link
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          dateText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹ ${txDetail.value.toStringAsFixed(2)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          statusLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Invoice button matching Android txt_invoice (underlined blue)
                  InkWell(
                    onTap: () => BillingTransactionDetailsDialog.show(context, transaction),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      child: Text(
                        'Invoice',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFF0000FF),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
