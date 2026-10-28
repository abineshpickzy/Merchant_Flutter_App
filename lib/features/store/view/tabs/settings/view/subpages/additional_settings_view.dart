import 'package:flutter/material.dart';
import 'package:bayfay_merchant_flutter/features/dashboard/model/store_model.dart';
import 'package:bayfay_merchant_flutter/features/store/view/widgets/store_tab_app_bar.dart';

/// Placeholder for Additional Settings Screen (to be implemented next)
class AdditionalSettingsView extends StatelessWidget {
  final StoreModel store;

  const AdditionalSettingsView({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: StoreTabAppBar(
        title: 'Additional Settings',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.tune, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'Additional Settings',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Extended store preferences for ${store.displayName}',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
