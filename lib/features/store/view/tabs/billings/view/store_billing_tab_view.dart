import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayfay_merchant_flutter/features/dashboard/model/store_model.dart';
import 'package:bayfay_merchant_flutter/features/store/view/widgets/store_tab_app_bar.dart';
import '../controller/billing_controller.dart';
import '../model/billing_model.dart';
import 'widgets/billing_date_filter_header.dart';
import 'widgets/billing_skeleton_loader.dart';
import 'widgets/billing_summary_card.dart';
import 'widgets/billing_transaction_card.dart';

/// Tab 4: Store Billing & Transactions Tab View
/// Strictly matching Android StoreBillingFragment.java and fragment_store_billing.xml
class StoreBillingTabView extends ConsumerStatefulWidget {
  final StoreModel store;

  const StoreBillingTabView({super.key, required this.store});

  @override
  ConsumerState<StoreBillingTabView> createState() => _StoreBillingTabViewState();
}

class _StoreBillingTabViewState extends ConsumerState<StoreBillingTabView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(billingControllerProvider(widget.store.id).notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final billingState = ref.watch(billingControllerProvider(widget.store.id));
    final controller = ref.read(billingControllerProvider(widget.store.id).notifier);
    final title = 'Billing - ${widget.store.displayName}';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: StoreTabAppBar(
        title: title,
      ),
      body: Column(
        children: [
          // 1. Filter Header (Segmented Today / 7D / 30D + Custom Pickers & Go Button)
          BillingDateFilterHeader(
            activeFilter: billingState.filterType,
            fromDate: billingState.fromDate,
            toDate: billingState.toDate,
            onFilterSelected: (filter) => controller.selectFilter(filter),
            onCustomRangeSelected: (from, to) => controller.selectCustomDateRange(from, to),
          ),

          // 2. Transaction List Area with SwipeRefreshLayout Parity
          Expanded(
            child: RefreshIndicator(
              color: const Color(0xFF2196F3),
              onRefresh: () => controller.loadBillingData(),
              child: _buildTransactionContent(billingState),
            ),
          ),

          // 3. Bottom Calculation Summary Card matching Android layout_calculates
          BillingSummaryCard(summary: billingState.summary),
        ],
      ),
    );
  }

  Widget _buildTransactionContent(BillingState billingState) {
    if (billingState.isLoading ) {
      return const BillingSkeletonLoader(itemCount: 6);
    }

    if (billingState.transactions.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: const Center(
                child: Text(
                  'No records found!',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF757575),
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: billingState.transactions.length + (billingState.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < billingState.transactions.length) {
          final tx = billingState.transactions[index];
          return BillingTransactionCard(transaction: tx);
        } else {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF2196F3),
                ),
              ),
            ),
          );
        }
      },
    );
  }
}
