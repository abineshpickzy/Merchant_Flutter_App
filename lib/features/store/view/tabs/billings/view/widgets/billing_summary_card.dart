import 'package:flutter/material.dart';
import '../../model/billing_model.dart';

/// Calculation summary card matching Android fragment_store_billing.xml (layout_calculates & drawable_billing.xml)
class BillingSummaryCard extends StatelessWidget {
  final BillingSummaryModel? summary;

  const BillingSummaryCard({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final debitsSettled = summary?.debitsSettled.toStringAsFixed(2) ?? '0.00';
    final debitsPending = summary?.debitsPending.toStringAsFixed(2) ?? '0.00';
    final creditsSettled = summary?.creditsSettled.toStringAsFixed(2) ?? '0.00';
    final creditsPending = summary?.creditsPending.toStringAsFixed(2) ?? '0.00';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F8FB), // Android drawable_billing solid
        borderRadius: BorderRadius.circular(2),
        border: Border.all(
          color: const Color(0xFF32C7DA), // Android drawable_billing stroke
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: Total Debits & Total Credits
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total debits : $debitsSettled',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black87,
                  fontFamily: 'Nunito',
                ),
              ),
              Text(
                'Total credits : $creditsSettled',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black87,
                  fontFamily: 'Nunito',
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Row 2: Pending Debits & Pending Credits
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pending debits : $debitsPending',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black87,
                  fontFamily: 'Nunito',
                ),
              ),
              Text(
                'Pending credits : $creditsPending',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black87,
                  fontFamily: 'Nunito',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
