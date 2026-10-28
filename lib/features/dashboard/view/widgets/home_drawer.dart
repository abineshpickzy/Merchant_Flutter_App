import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayfay_merchant_flutter/app/providers/auth_state_provider.dart';
import 'package:bayfay_merchant_flutter/app/theme/app_colors.dart';
import 'package:bayfay_merchant_flutter/core/constants/app_strings.dart';
import '../../controller/dashboard_controller.dart';

import 'package:bayfay_merchant_flutter/core/widgets/widgets.dart';

class HomeDrawer extends ConsumerWidget {
  const HomeDrawer({super.key});

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.logoutConfirmTitle),
        content: const Text(AppStrings.logoutConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(AppStrings.cancel),
          ),
          AppButton.danger(
            width: 100,
            height: 36,
            borderRadius: 4,
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(authStateProvider.notifier).logout();
            },
            text: AppStrings.logOut,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    String merchantName = AppStrings.merchantDefaultName;
    String mobileOrEmail = '';
    String businessName = '';

    if (authState is AuthAuthenticated) {
      final profile = authState.profile;
      if (profile != null) {
        merchantName = profile.fullName.isNotEmpty
            ? profile.fullName
            : AppStrings.merchantDefaultName;
        businessName = profile.businessName ?? '';
        mobileOrEmail = profile.mobileNumber > 0
            ? '+${profile.dialingCode} ${profile.mobileNumber}'
            : (profile.email ?? '');
      }
    }

    return Drawer(
      child: Column(
        children: [
          // Merchant Profile Header
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              color: AppColors.primary,
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                merchantName.isNotEmpty ? merchantName[0].toUpperCase() : 'M',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            accountName: Text(
              merchantName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            accountEmail: Text(
              businessName.isNotEmpty ? '$businessName • $mobileOrEmail' : mobileOrEmail,
              style: const TextStyle(fontSize: 13),
            ),
          ),

          // Drawer Navigation Items (matching HomeActivity.java navigationRecyclerView)
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: const Icon(Icons.storefront_rounded, color: AppColors.primary),
                  title: const Text(AppStrings.drawerStores),
                  onTap: () {
                    Navigator.of(context).pop();
                    ref.read(dashboardIndexProvider.notifier).state = 0;
                    ref.read(storeFilterProvider.notifier).state = 'All';
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.business_center_outlined, color: AppColors.textPrimary),
                  title: const Text(AppStrings.drawerWholesale),
                  onTap: () {
                    Navigator.of(context).pop();
                    ref.read(dashboardIndexProvider.notifier).state = 0;
                    ref.read(storeFilterProvider.notifier).state = 'Wholesale';
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.people_outline, color: AppColors.textPrimary),
                  title: const Text(AppStrings.drawerUsers),
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.manage_accounts_outlined, color: AppColors.textPrimary),
                  title: const Text(AppStrings.drawerRoles),
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.local_shipping_outlined, color: AppColors.textPrimary),
                  title: const Text(AppStrings.drawerDelivery),
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.account_balance_wallet_outlined, color: AppColors.textPrimary),
                  title: const Text(AppStrings.drawerBillings),
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.payments_outlined, color: AppColors.textPrimary),
                  title: const Text(AppStrings.drawerGetPaid),
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.campaign_outlined, color: AppColors.textPrimary),
                  title: const Text(AppStrings.drawerPromo),
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.history_rounded, color: AppColors.textPrimary),
                  title: const Text(AppStrings.drawerHistory),
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.settings_outlined, color: AppColors.textPrimary),
                  title: const Text(AppStrings.drawerSettings),
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.info_outline, color: AppColors.textSecondary),
                  title: const Text(AppStrings.drawerAbout),
                  onTap: () {
                    Navigator.of(context).pop();
                    showAboutDialog(
                      context: context,
                      applicationName: AppStrings.appName,
                      applicationVersion: '1.0.0',
                      applicationIcon: const Icon(
                        Icons.storefront_rounded,
                        color: AppColors.primary,
                        size: 40,
                      ),
                      children: const [
                        Text(AppStrings.aboutAppDescription),
                      ],
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.help_outline, color: AppColors.textSecondary),
                  title: const Text(AppStrings.drawerHelp),
                  onTap: () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(AppStrings.helpSupportContact),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Logout Item at bottom
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.error),
            title: const Text(
              AppStrings.drawerLogout,
              style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
            ),
            onTap: () {
              Navigator.of(context).pop();
              _showLogoutDialog(context, ref);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
