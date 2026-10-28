import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:bayfay_merchant_flutter/features/dashboard/model/store_model.dart';
import '../model/order_history_model.dart';
import '../repository/order_history_repository.dart';

final orderHistoryControllerProvider = StateNotifierProvider.autoDispose
    .family<OrderHistoryController, OrderHistoryState, StoreModel>((ref, store) {
  final repository = ref.read(orderHistoryRepositoryProvider);
  return OrderHistoryController(repository, store);
});

class OrderHistoryController extends StateNotifier<OrderHistoryState> {
  final OrderHistoryRepository _repository;
  final StoreModel store;
  final DateFormat _apiDateFormat = DateFormat('yyyy-MM-dd');

  OrderHistoryController(this._repository, this.store)
      : super(
          OrderHistoryState(
            isLoading: true,
            fromDate: DateTime.now(),
            toDate: DateTime.now(),
            activeFilter: OrderHistoryFilterType.today,
          ),
        ) {
    loadOrders();
  }

  String _formatApiDate(DateTime dt, bool isStartOfDay) {
    final ymd = _apiDateFormat.format(dt);
    return isStartOfDay ? '$ymd 00:00:00.000' : '$ymd 23:59:59.000';
  }

  /// Change active filter tab (Today, Last 7 Days, Last 30 Days)
  void selectFilter(OrderHistoryFilterType filter) {
    final now = DateTime.now();
    DateTime from;
    DateTime to = now;

    switch (filter) {
      case OrderHistoryFilterType.today:
        from = now;
        break;
      case OrderHistoryFilterType.sevenDays:
        from = now.subtract(const Duration(days: 7));
        break;
      case OrderHistoryFilterType.thirtyDays:
        from = now.subtract(const Duration(days: 30));
        break;
      case OrderHistoryFilterType.custom:
        from = state.fromDate;
        to = state.toDate;
        break;
    }

    state = state.copyWith(
      activeFilter: filter,
      fromDate: from,
      toDate: to,
    );

    loadOrders();
  }

  /// Select custom date range from pickers
  void selectCustomDateRange(DateTime from, DateTime to) {
    state = state.copyWith(
      activeFilter: OrderHistoryFilterType.custom,
      fromDate: from,
      toDate: to,
    );
    loadOrders();
  }

  /// Initial or pull-to-refresh load
  Future<void> loadOrders({bool isRefresh = false}) async {
    state = state.copyWith(
      isLoading: !isRefresh,
      clearError: true,
    );

    final fromStr = _formatApiDate(state.fromDate, true);
    final toStr = _formatApiDate(state.toDate, false);

    final result = await _repository.getOrderHistory(
      shopId: store.id,
      fromDate: fromStr,
      toDate: toStr,
      skip: 0,
      limit: 30,
    );

    if (!mounted) return;
    state = state.copyWith(
      isLoading: false,
      orders: result.orders,
      totalCount: result.count,
    );
  }

  /// Lazy pagination on scroll
  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore) return;
    if (state.orders.length >= state.totalCount && state.totalCount > 0) return;

    state = state.copyWith(isLoadingMore: true);

    final fromStr = _formatApiDate(state.fromDate, true);
    final toStr = _formatApiDate(state.toDate, false);

    final result = await _repository.getOrderHistory(
      shopId: store.id,
      fromDate: fromStr,
      toDate: toStr,
      skip: state.orders.length,
      limit: 30,
    );

    if (!mounted) return;
    state = state.copyWith(
      isLoadingMore: false,
      orders: [...state.orders, ...result.orders],
      totalCount: result.count,
    );
  }
}
