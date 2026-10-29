import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../model/billing_model.dart';
import '../repository/billing_repository.dart';

final billingControllerProvider = StateNotifierProvider.autoDispose
    .family<BillingController, BillingState, String>((ref, shopId) {
  final repository = ref.read(billingRepositoryProvider);
  return BillingController(repository: repository, shopId: shopId);
});

class BillingController extends StateNotifier<BillingState> {
  final BillingRepository _repository;
  final String _shopId;

  static const int _limit = 30;
  static final DateFormat _apiDateFormat = DateFormat('yyyy-MM-dd');

  BillingController({
    required BillingRepository repository,
    required String shopId,
  })  : _repository = repository,
        _shopId = shopId,
        super(
          BillingState(
            filterType: BillingFilterType.today,
            fromDate: DateTime.now(),
            toDate: DateTime.now(),
          ),
        ) {
    loadBillingData();
  }

  String _formatApiDate(DateTime date, bool isEnd) {
    final base = _apiDateFormat.format(date);
    return isEnd ? '$base 23:59:59.000' : '$base 00:00:00.000';
  }

  /// Switch filter between Today, Last 7 Days, Last 30 Days matching Android StoreBillingFragment
  void selectFilter(BillingFilterType filter) {
    if (filter == BillingFilterType.custom) return;

    final now = DateTime.now();
    DateTime from;
    final to = now;

    switch (filter) {
      case BillingFilterType.today:
        from = now;
        break;
      case BillingFilterType.sevenDays:
        from = now.subtract(const Duration(days: 7));
        break;
      case BillingFilterType.thirtyDays:
        from = now.subtract(const Duration(days: 30));
        break;
      case BillingFilterType.custom:
        return;
    }

    state = state.copyWith(
      filterType: filter,
      fromDate: from,
      toDate: to,
      skip: 0,
      hasMore: true,
      error: null,
    );

    loadBillingData();
  }

  /// Trigger custom range query matching Android StoreBillingFragment btn_go click
  void selectCustomDateRange(DateTime from, DateTime to) {
    state = state.copyWith(
      filterType: BillingFilterType.custom,
      fromDate: from,
      toDate: to,
      skip: 0,
      hasMore: true,
      error: null,
    );

    loadBillingData();
  }

  /// Initial load or refresh of transactions & accounts summary
  Future<void> loadBillingData() async {
    if (_shopId.isEmpty) return;

    state = state.copyWith(isLoading: true, error: null);

    final fromStr = _formatApiDate(state.fromDate, false);
    final toStr = _formatApiDate(state.toDate, true);

    try {
      final results = await Future.wait([
        _repository.getTransactions(
          shopId: _shopId,
          fromDate: fromStr,
          toDate: toStr,
          skip: 0,
          limit: _limit,
        ),
        _repository.getAccountsSummary(
          shopId: _shopId,
          fromDate: fromStr,
          toDate: toStr,
        ),
      ]);

      if (!mounted) return;

      final transactions = results[0] as List<BillingTransaction>;
      final summary = results[1] as BillingSummaryModel?;

      state = state.copyWith(
        isLoading: false,
        transactions: transactions,
        summary: summary,
        skip: transactions.length,
        hasMore: transactions.length >= _limit,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Lazy pagination matching Android setUpLoadMoreListener
  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore || _shopId.isEmpty) {
      return;
    }

    state = state.copyWith(isLoadingMore: true);

    final fromStr = _formatApiDate(state.fromDate, false);
    final toStr = _formatApiDate(state.toDate, true);

    try {
      final moreItems = await _repository.getTransactions(
        shopId: _shopId,
        fromDate: fromStr,
        toDate: toStr,
        skip: state.skip,
        limit: _limit,
      );

      if (!mounted) return;

      final combined = [...state.transactions, ...moreItems];

      state = state.copyWith(
        isLoadingMore: false,
        transactions: combined,
        skip: combined.length,
        hasMore: moreItems.length >= _limit,
      );
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(isLoadingMore: false);
    }
  }
}
