import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayfay_merchant_flutter/app/theme/app_colors.dart';
import 'package:bayfay_merchant_flutter/core/constants/app_strings.dart';
import 'package:bayfay_merchant_flutter/core/widgets/widgets.dart';
import '../../dashboard/controller/dashboard_controller.dart';
import '../../dashboard/view/widgets/store_selector_bottom_sheet.dart';
import '../controller/orders_controller.dart';
import '../model/order_model.dart';
import 'views/orders_list_view.dart';

/// Orders management screen providing multi-tab workflow matching StoreOrdersActivity:
/// New, Processing (Packaging), Ready (Dispatched), On The Way (Shipping), Delivered, Cancelled.
class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const List<OrderStatus> _tabs = [
    OrderStatus.newOrder,
    OrderStatus.processing,
    OrderStatus.ready,
    OrderStatus.onTheWay,
    OrderStatus.delivered,
    OrderStatus.replaceRefund,
    OrderStatus.cancelled,
    
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        ref.read(orderStatusTabProvider.notifier).state = _tabs[_tabController.index];
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedStore = ref.watch(selectedStoreProvider);
    final shopId = selectedStore?.id ?? '';
    final categoryId = selectedStore?.categoryId ?? '';
    final countsAsync = ref.watch(orderCountsProvider(shopId));
    final counts = countsAsync.value ?? const OrderCountsModel();

    if (selectedStore == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.storefront_outlined,
                    size: 48,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  AppStrings.noStoreSelectedTitle,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  AppStrings.noStoreSelectedSubtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),
                AppButton.primary(
                  onPressed: () => StoreSelectorBottomSheet.show(context),
                  icon: const Icon(Icons.store_mall_directory),
                  text: AppStrings.chooseStoreAction,
                  width: 180,
                  height: 44,
                  borderRadius: 10,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Order Tabs Header
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              tabs: _tabs.map((status) {
                final count = _getCountForStatus(status, counts);
                return Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(status.label),
                      if (count > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: status == OrderStatus.newOrder
                                ? AppColors.error
                                : AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$count',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: status == OrderStatus.newOrder
                                  ? Colors.white
                                  : AppColors.primaryDark,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _tabs.map((status) {
                return OrdersListView(
                  shopId: shopId,
                  categoryId: categoryId,
                  status: status,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  int _getCountForStatus(OrderStatus status, OrderCountsModel counts) {
    return counts.getCountForStatus(status);
  }
}
