import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayfay_merchant_flutter/app/theme/app_colors.dart';
import 'package:bayfay_merchant_flutter/core/constants/app_strings.dart';
import 'package:bayfay_merchant_flutter/core/widgets/widgets.dart';
import '../../controller/dashboard_controller.dart';

class StoreSelectorBottomSheet extends ConsumerWidget {
  const StoreSelectorBottomSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (_) => const StoreSelectorBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storesAsync = ref.watch(storesProvider);
    final selectedStore = ref.watch(selectedStoreProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  AppStrings.switchStore,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // List of stores
            storesAsync.when(
              data: (stores) {
                if (stores.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32.0),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(
                            Icons.storefront_outlined,
                            size: 48,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            AppStrings.noStoresFound,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            AppStrings.noStoresFoundSubtitle,
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.45,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: stores.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final store = stores[index];
                      final isSelected = selectedStore?.id == store.id;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 6.0,
                          horizontal: 4.0,
                        ),
                        leading: CircleAvatar(
                          backgroundColor:
                              AppColors.primaryLight.withValues(alpha: 0.3),
                          child: const Icon(
                            Icons.storefront_rounded,
                            color: AppColors.primary,
                          ),
                        ),
                        title: Text(
                          store.displayName,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          store.isWholeSale
                              ? '${AppStrings.wholesaleStore} • ${store.isOpen ? AppStrings.openStatus : AppStrings.closedStatus}'
                              : '${AppStrings.retailStore} • ${store.isOpen ? AppStrings.openStatus : AppStrings.closedStatus}',
                          style: TextStyle(
                            fontSize: 12,
                            color: store.isOpen
                                ? AppColors.success
                                : AppColors.textSecondary,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check_circle,
                                color: AppColors.primary,
                              )
                            : null,
                        onTap: () {
                          if (store.status == 2) {
                            ref
                                .read(selectedStoreProvider.notifier)
                                .selectStore(store);
                            Navigator.of(context).pop();
                          } else {
                            final String message =
                                (store.status == 1 || store.status == 0)
                                    ? 'Store is waiting for approval'
                                    : 'This store is currently inactive';

                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(message),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: LoadingIndicator(),
                ),
              ),
              error: (err, _) => Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Text(
                    '${AppStrings.failedToLoadStores}: $err',
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
