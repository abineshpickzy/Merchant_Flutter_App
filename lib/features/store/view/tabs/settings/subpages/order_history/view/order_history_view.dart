import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayfay_merchant_flutter/features/dashboard/model/store_model.dart';
import 'package:bayfay_merchant_flutter/features/store/view/widgets/store_tab_app_bar.dart';
import '../controller/order_history_controller.dart';
import 'order_history_details_view.dart';
import 'widgets/order_history_card.dart';
import 'widgets/order_history_filter_header.dart';
import 'widgets/order_history_skeleton.dart';

/// Full Order History View matching Android OrderHistoryFragment.java
class OrderHistoryView extends ConsumerStatefulWidget {
  final StoreModel store;

  const OrderHistoryView({
    super.key,
    required this.store,
  });

  @override
  ConsumerState<OrderHistoryView> createState() => _OrderHistoryViewState();
}

class _OrderHistoryViewState extends ConsumerState<OrderHistoryView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!mounted) return;
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(orderHistoryControllerProvider(widget.store).notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(orderHistoryControllerProvider(widget.store));
    final controller = ref.read(orderHistoryControllerProvider(widget.store).notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: StoreTabAppBar(
        title: 'Order History',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF616161)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Segmented Date Filters + Custom Pickers
          OrderHistoryFilterHeader(
            activeFilter: state.activeFilter,
            fromDate: state.fromDate,
            toDate: state.toDate,
            onFilterSelected: (filter) => controller.selectFilter(filter),
            onCustomRangeApplied: (from, to) => controller.selectCustomDateRange(from, to),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),

          // Orders List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => controller.loadOrders(isRefresh: true),
              color: const Color(0xFF2196F3),
              child: Builder(
                builder: (context) {
                  if (state.isLoading) {
                    return const OrderHistorySkeleton();
                  }

                  if (state.orders.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history,
                            size: 54,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'No records found!',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF757575),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(top: 6, bottom: 20),
                    itemCount: state.orders.length + (state.isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == state.orders.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(12.0),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      }

                      final order = state.orders[index];
                      return OrderHistoryCard(
                        order: order,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => OrderHistoryDetailsView(
                                order: order,
                                store: widget.store,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
