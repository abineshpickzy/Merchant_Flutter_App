import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayfay_merchant_flutter/app/theme/app_colors.dart';
import 'package:bayfay_merchant_flutter/core/constants/app_strings.dart';
import 'package:bayfay_merchant_flutter/core/widgets/widgets.dart';
import '../../controller/orders_controller.dart';
import '../../model/order_model.dart';
import '../cancelled/cancelled_order_card.dart';
import '../delivered/delivered_order_card.dart';
import '../dispatched/dispatched_order_card.dart';
import '../new_order/new_order_card.dart';
import '../on_the_way/on_the_way_order_card.dart';
import '../packaging/packaging_order_card.dart';
import '../replacement/replacement_order_card.dart';

/// Renders the list of orders for a given store and status tab with pull-to-refresh,
/// date grouping headers for New Orders (matching NewOrderHeaderAdapter),
/// and dedicated status-specific cards matching the Android app.
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

    final OrderQueryArg queryArg = (
      shopId: shopId,
      categoryId: categoryId,
      status: status,
    );
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
          child: status == OrderStatus.newOrder
              ? _buildDateGroupedList(orders)
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: orders.length,
                  itemBuilder: (context, index) => _getCard(orders[index]),
                ),
        );
      },
    );
  }

  /// Groups New Orders by date header ("Today", "Yesterday", "X Days Ago", or "dd MMM yyyy")
  /// matching Android NewOrderHeaderAdapter & new_order_header_layout.xml
  Widget _buildDateGroupedList(List<OrderModel> orders) {
    final grouped = <String, List<OrderModel>>{};
    for (final o in orders) {
      final header = o.dateGroupHeader;
      grouped.putIfAbsent(header, () => []).add(o);
    }

    final entries = grouped.entries.toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: entries.length,
      itemBuilder: (context, groupIndex) {
        final entry = entries[groupIndex];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 25,
              margin: const EdgeInsets.fromLTRB(4, 4, 4, 0),
              decoration: BoxDecoration(
                color: const Color(0xFF9E9E9E),
                borderRadius: BorderRadius.circular(1),
              ),
              alignment: Alignment.center,
              child: Text(
                entry.key,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Nunito',
                ),
              ),
            ),
            Container(
              height: 1,
              margin: const EdgeInsets.fromLTRB(4, 0, 4, 2),
              color: const Color(0xFFD1D1D1),
            ),
            ...entry.value.map(_getCard),
          ],
        );
      },
    );
  }

  Widget _getCard(OrderModel order) {
    final key = ValueKey(order.id);
    switch (status) {
      case OrderStatus.newOrder:
        return NewOrderCard(
          key: key,
          order: order,
          shopId: shopId,
          categoryId: categoryId,
        );
      case OrderStatus.processing:
        return PackagingOrderCard(
          key: key,
          order: order,
          shopId: shopId,
          categoryId: categoryId,
        );
      case OrderStatus.ready:
        return DispatchedOrderCard(
          key: key,
          order: order,
          shopId: shopId,
          categoryId: categoryId,
        );
      case OrderStatus.onTheWay:
        return OnTheWayOrderCard(
          key: key,
          order: order,
          shopId: shopId,
          categoryId: categoryId,
        );
      case OrderStatus.delivered:
        return DeliveredOrderCard(
          key: key,
          order: order,
          shopId: shopId,
          categoryId: categoryId,
        );
      case OrderStatus.replaceRefund:
        return ReplacementOrderCard(
          key: key,
          order: order,
          shopId: shopId,
          categoryId: categoryId,
        );
      case OrderStatus.cancelled:
        return CancelledOrderCard(
          key: key,
          order: order,
          shopId: shopId,
          categoryId: categoryId,
        );
    }
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
                     
                 
                      const Text(
                        AppStrings.noOrdersInTab,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 144, 143, 143),
                        ),
                        textAlign: TextAlign.center,
                      ),
                   
                      // const SizedBox(height: 20),
                      // AppButton.outline(
                      //   onPressed: () {
                      //     ref
                      //         .read(ordersListProvider(queryArg).notifier)
                      //         .refresh();
                      //     ref.invalidate(orderCountsProvider(shopId));
                      //   },
                      //   icon: const Icon(Icons.refresh, size: 16),
                      //   text: AppStrings.refreshOrders,
                      //   width: 170,
                      //   height: 40,
                      //   borderRadius: 8,
                      // ),
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
            Icon(Icons.storefront_outlined,
                size: 48, color: AppColors.textMuted),
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
