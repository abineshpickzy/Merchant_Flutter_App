import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayfay_merchant_flutter/app/theme/app_colors.dart';
import 'package:bayfay_merchant_flutter/core/constants/app_strings.dart';
import 'package:bayfay_merchant_flutter/core/widgets/widgets.dart';
import '../../controller/orders_controller.dart';
import '../../model/order_model.dart';
import '../widgets/order_card.dart';

/// Renders the list of orders for a given store and status tab with pull-to-refresh
/// and comprehensive loading / error / empty state handling.
class OrdersListView extends ConsumerWidget {
   final String shopId;
  final String categoryId;
  final OrderStatus status;

  const OrdersListView({
    super.key,
    required this.shopId,
    required this.categoryId,
    required this.status,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
       if (shopId.isEmpty || categoryId.isEmpty) {
      return _buildNoStoreSelected();
    }

    final OrderQueryArg queryArg =
        (shopId: shopId, categoryId: categoryId, status: status);
    final ordersAsync = ref.watch(ordersListProvider(queryArg));

    return ordersAsync.when(
      loading: () => const Center(
        child: LoadingIndicator(),
      ),
      error: (error, _) => _buildErrorState(context, ref, queryArg, error),
      data: (orders) {
        if (orders.isEmpty) {
          return _buildEmptyState(context, ref, queryArg);
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            await Future.wait([
              ref.read(ordersListProvider(queryArg).notifier).refresh(),
              ref.refresh(orderCountsProvider(shopId).future),
            ]);
          },
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: orders.length,
            itemBuilder: (context, index) {
               return OrderCard(
                key: ValueKey(orders[index].id),
                order: orders[index],
                shopId: shopId,
                categoryId: categoryId,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    WidgetRef ref,
    OrderQueryArg queryArg,
  ) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        await Future.wait([
          ref.read(ordersListProvider(queryArg).notifier).refresh(),
          ref.refresh(orderCountsProvider(shopId).future),
        ]);
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.inbox_outlined,
                          size: 48,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppStrings.noOrdersInTab,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppStrings.noOrdersInTabSubtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      AppButton.outline(
                        onPressed: () {
                          ref.read(ordersListProvider(queryArg).notifier).refresh();
                          ref.invalidate(orderCountsProvider(shopId));
                        },
                        icon: const Icon(Icons.refresh, size: 16),
                        text: AppStrings.refreshOrders,
                        width: 170,
                        height: 40,
                        borderRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    WidgetRef ref,
    OrderQueryArg queryArg,
    Object error,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            const Text(
              AppStrings.unableToLoadOrders,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              error.toString(),
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            AppButton.primary(
              onPressed: () {
                ref.read(ordersListProvider(queryArg).notifier).refresh();
                ref.invalidate(orderCountsProvider(shopId));
              },
              icon: const Icon(Icons.refresh, size: 16),
              text: AppStrings.retry,
              width: 130,
              height: 40,
              borderRadius: 8,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoStoreSelected() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.storefront_outlined, size: 48, color: AppColors.textMuted),
            SizedBox(height: 12),
            Text(
              AppStrings.noStoreSelected,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 6),
            Text(
              AppStrings.pleaseSelectStoreToViewOrders,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
