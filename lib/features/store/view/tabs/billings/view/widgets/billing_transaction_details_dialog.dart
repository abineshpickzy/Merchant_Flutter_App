import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../model/billing_model.dart';

/// Modal dialog displaying transaction breakdown matching Android alert_history_transaction.xml
class BillingTransactionDetailsDialog extends StatelessWidget {
  final BillingTransaction transaction;

  const BillingTransactionDetailsDialog({
    super.key,
    required this.transaction,
  });

  static void show(BuildContext context, BillingTransaction transaction) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => BillingTransactionDetailsDialog(transaction: transaction),
    );
  }

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
  Widget build(BuildContext context) {
    final order = transaction.order;
    final txDetail = order.transaction;
    final offer = order.offer;

    // Service fee calculation matching Android:
    double serviceFee = order.serviceFee;
    if (txDetail.type == 2 && (txDetail.serviceFee != 0.0 || txDetail.paymentFee != 0.0)) {
      serviceFee = txDetail.serviceFee + txDetail.paymentFee;
    }

    final isCredit = txDetail.type == 1;
    final totalLabel = isCredit ? 'Total Credit Amount' : 'Total Debit Amount';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Row: Title & Close 'X'
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Transaction Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Icon(Icons.close, size: 20, color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFF2F2F2)),

            // Key-Value Pairs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDetailRow('Store Location Name :', transaction.shop.location),
                  _buildDetailRow('Order Id :', order.id),
                  _buildDetailRow('Purchase Date :', _formatDate(order.orderedAt)),
                  _buildDetailRow('Delivery Date :', _formatDate(order.deliveredAt)),
                  _buildDetailRow('Purchase Amount :', '₹ ${order.amount.toStringAsFixed(2)}'),
                  if (order.tipAmount != null && order.tipAmount! > 0)
                    _buildDetailRow('Tip Amount :', '₹ ${order.tipAmount}'),
                  _buildDetailRow('Payment Mode :', order.paymentType.isNotEmpty ? order.paymentType : '-'),
                  _buildDetailRow('Service Fee :', '₹ ${serviceFee.toStringAsFixed(2)}'),
                  if (offer != null && offer.isOfferApplied)
                    _buildDetailRow(
                      offer.offerType == 1 ? 'Cash Back :' : 'Discount :',
                      '₹ ${offer.offerAmount.toStringAsFixed(2)}',
                    ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    '$totalLabel :',
                    '₹ ${txDetail.value.toStringAsFixed(2)}',
                    isHighlight: true,
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFF2F2F2)),

            // Footer Button: OK
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: SizedBox(
                  width: 75,
                  height: 32,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0275D8),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(2),
                      ),
                      padding: EdgeInsets.zero,
                      elevation: 0,
                    ),
                    child: const Text(
                      'OK',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 11,
            child: Text(
              label,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
                color: isHighlight ? const Color(0xFF0275D8) : const Color(0xFF424242),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 10,
            child: Text(
              value,
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
