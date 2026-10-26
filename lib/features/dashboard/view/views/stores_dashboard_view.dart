import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayfay_merchant_flutter/app/theme/app_colors.dart';
import 'package:bayfay_merchant_flutter/core/constants/app_strings.dart';
import 'package:bayfay_merchant_flutter/core/widgets/widgets.dart';
import '../../controller/dashboard_controller.dart';
import '../widgets/store_card.dart';

class StoresDashboardView extends ConsumerWidget {
  const StoresDashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storesAsync = ref.watch(storesProvider);
    final filteredStores = ref.watch(filteredStoresProvider);
    final selectedStore = ref.watch(selectedStoreProvider);
    final activeFilter = ref.watch(storeFilterProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(storesProvider.notifier).refreshStores(),
      child: storesAsync.when(
        data: (allStores) {
          final totalStores = allStores.length;
          final openStores = allStores.where((s) => s.isOpen).length;
          final totalNewOrders =
              allStores.fold<int>(0, (sum, s) => sum + s.newOrderCount);

          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Summary Metrics Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                  child: Row(
                    children: [
                      // Total Stores Metric
                      Expanded(
                        child: _MetricCard(
                          label: AppStrings.totalStores,
                          value: '$totalStores',
                          icon: Icons.storefront_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Open Stores Metric
                      Expanded(
                        child: _MetricCard(
                          label: AppStrings.openStores,
                          value: '$openStores',
                          icon: Icons.check_circle_outline,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // New Orders Metric
                      Expanded(
                        child: _MetricCard(
                          label: AppStrings.newOrders,
                          value: '$totalNewOrders',
                          icon: Icons.receipt_long_outlined,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Search Bar & Filter Chips
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Column(
                    children: [
                      // Search TextField
                      TextField(
                        onChanged: (val) => ref
                            .read(storeSearchQueryProvider.notifier)
                            .state = val,
                        decoration: InputDecoration(
                          hintText: AppStrings.searchStoresHint,
                          prefixIcon: const Icon(
                            Icons.search,
                            color: AppColors.textSecondary,
                          ),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: AppColors.divider,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: AppColors.divider,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Filter Chips Row
                      Row(
                        children: [
                          _FilterChip(
                            label: AppStrings.filterAll,
                            isSelected: activeFilter == 'All',
                            onSelected: () => ref
                                .read(storeFilterProvider.notifier)
                                .state = 'All',
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: AppStrings.filterRetail,
                            isSelected: activeFilter == 'Retail',
                            onSelected: () => ref
                                .read(storeFilterProvider.notifier)
                                .state = 'Retail',
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: AppStrings.filterWholesale,
                            isSelected: activeFilter == 'Wholesale',
                            onSelected: () => ref
                                .read(storeFilterProvider.notifier)
                                .state = 'Wholesale',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Store Cards Grid or Empty State
              if (filteredStores.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.storefront_outlined,
                            size: 64,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            AppStrings.noStoresFound,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            AppStrings.noStoresFoundSubtitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 24.0),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.76,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final store = filteredStores[index];
                        final isSelected = selectedStore?.id == store.id;

                        return StoreCard(
                          store: store,
                          isSelected: isSelected,
                          onTap: () =>
                              StoreCard.handleStoreTap(context, ref, store),
                        );
                      },
                      childCount: filteredStores.length,
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(
          child: LoadingIndicator(size: 32),
        ),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: AppColors.error,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  '${AppStrings.failedToLoadStores}: $error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
                const SizedBox(height: 16),
                AppButton.primary(
                  width: 140,
                  height: 42,
                  borderRadius: 8,
                  text: AppStrings.retry,
                  onPressed: () =>
                      ref.read(storesProvider.notifier).refreshStores(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: isSelected ? Colors.white : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: AppColors.primary,
      backgroundColor: Colors.grey.shade100,
      visualDensity: VisualDensity.compact,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
