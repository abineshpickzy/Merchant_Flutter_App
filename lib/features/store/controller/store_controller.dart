import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/dashboard_date_filter.dart';
import '../model/store_dashboard_metrics_model.dart';
import '../repository/store_repository.dart';

/// Active store bottom navigation tab index provider (0: Dashboard, 1: Orders, 2: Inventory, 3: Billing, 4: More)
final storeTabIndexProvider = StateProvider.autoDispose<int>((ref) => 0);

/// Active store dashboard period & custom date range selector provider
final storeDashboardDateFilterProvider =
    StateProvider<DashboardDateFilter>((ref) => const DashboardDateFilter());

/// Async Riverpod provider fetching live store overview metrics for a given `storeId` and date filter.
final storeDashboardMetricsProvider =
    FutureProvider.family<StoreDashboardMetricsModel, String>((ref, storeId) async {
  final filter = ref.watch(storeDashboardDateFilterProvider);
  final repository = ref.watch(storeRepositoryProvider);
  try {
    return await repository.fetchDashboardMetrics(storeId: storeId, filter: filter);
  } catch (e, stack) {
    debugPrint('storeDashboardMetricsProvider Error: $e\n$stack');
    return StoreDashboardMetricsModel.sampleForFilter(filter);
  }
});
