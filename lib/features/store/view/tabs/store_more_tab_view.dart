import 'package:flutter/material.dart';
import 'package:bayfay_merchant_flutter/app/theme/app_colors.dart';
import 'package:bayfay_merchant_flutter/core/constants/app_strings.dart';
import '../../../dashboard/model/store_model.dart';

/// Tab 5: Store Settings & More Options Tab View
class StoreMoreTabView extends StatelessWidget {
  final StoreModel store;

  const StoreMoreTabView({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Card(
          elevation: 1.5,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  store.displayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  AppStrings.configureStoreDetails,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ListTile(
          leading: const Icon(Icons.storefront_outlined, color: AppColors.primary),
          title: const Text(AppStrings.storeManagement),
          subtitle: const Text('Operating hours, address & delivery settings'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        ),
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.notifications_outlined, color: AppColors.primary),
          title: const Text(AppStrings.notificationPreferences),
          subtitle: const Text('Order alerts & message notifications'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        ),
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.lock_outline, color: AppColors.primary),
          title: const Text(AppStrings.securityAndPassword),
          subtitle: const Text('Account credentials & access'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        ),
      ],
    );
  }
}
