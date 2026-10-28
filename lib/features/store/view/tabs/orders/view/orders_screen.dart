import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayfay_merchant_flutter/app/theme/app_colors.dart';
import 'package:bayfay_merchant_flutter/core/constants/app_strings.dart';
import 'package:bayfay_merchant_flutter/core/widgets/widgets.dart';
import 'package:bayfay_merchant_flutter/features/dashboard/controller/dashboard_controller.dart';
import 'package:bayfay_merchant_flutter/features/dashboard/view/widgets/store_selector_bottom_sheet.dart';
import 'package:bayfay_merchant_flutter/features/store/view/widgets/store_tab_app_bar.dart';
import '../controller/orders_controller.dart';
import '../model/order_model.dart';
import 'views/orders_list_view.dart';

/// Primary Orders screen shell hosting a nested Navigator so order details screens
/// and More.. sub-screens replace the order list inside this tab while keeping the
/// 5-tab bottom navigation bar visible at all times.
class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  final GlobalKey<NavigatorState> _ordersNavigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // Pop nested sub-screen or details first if present
        if (_ordersNavigatorKey.currentState?.canPop() ?? false) {
          _ordersNavigatorKey.currentState?.pop();
        } else {
          // If already at the root of Orders tab, pop parent Navigator (exit store shell)
          Navigator.of(context).pop();
        }
      },
      child: Navigator(
        key: _ordersNavigatorKey,
        onGenerateRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) => const _OrdersTabView(),
          );
        },
      ),
    );
  }
}

/// Orders management screen matching Android StoreOrdersActivity & OrdersFragment (order_fragment.xml + fragment_more.xml)
class _OrdersTabView extends ConsumerWidget {
  const _OrdersTabView();

  static const List<OrderStatus> _primaryTabs = [
    OrderStatus.newOrder,
    OrderStatus.processing,
    OrderStatus.ready,
    OrderStatus.onTheWay,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedStore = ref.watch(selectedStoreProvider);
    final storeName = selectedStore?.displayName ?? '';
    final shopId = selectedStore?.id ?? '';
    final categoryId = selectedStore?.categoryId ?? '';
    final countsAsync = ref.watch(orderCountsProvider(shopId));
    final counts = countsAsync.valueOrNull ?? const OrderCountsModel();
    final activeStatus = ref.watch(orderStatusTabProvider);
    final isMoreMenuOpen = ref.watch(isMoreMenuOpenProvider);

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
                  style:
                      TextStyle(fontSize: 14, color: AppColors.textSecondary),
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

    final title = storeName.isNotEmpty ? '$storeName - Orders' : 'Orders';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: StoreTabAppBar(
        title: title,
      ),
      body: Column(
        children: [
          // 5-Button Top Bar matching Android order_fragment.xml
          Container(
            height: 40,
            decoration: const BoxDecoration(
              color: Colors.white,
            ),
            child: Row(
              children: [
                ..._primaryTabs.map((status) {
                  final count = counts.getCountForStatus(status);
                  final isSelected =
                      !isMoreMenuOpen && activeStatus == status;
                  final text = count > 0
                      ? '${status.label} ($count)'
                      : status.label;
                  return Expanded(
                    child: _OrderTabButton(
                      text: text,
                      isSelected: isSelected,
                      onTap: () {
                        ref.read(isMoreMenuOpenProvider.notifier).state = false;
                        ref.read(orderStatusTabProvider.notifier).state =
                            status;
                      },
                    ),
                  );
                }),
                Expanded(
                  child: _OrderTabButton(
                    text: 'More..',
                    isSelected: isMoreMenuOpen,
                    onTap: () {
                      ref.read(isMoreMenuOpenProvider.notifier).state = true;
                    },
                  ),
                ),
              ],
            ),
          ),

          // Main Content Area
          Expanded(
            child: isMoreMenuOpen
                ? _MoreOrdersMenuView(
                    counts: counts,
                    shopId: shopId,
                    categoryId: categoryId,
                  )
                : OrdersListView(
                    shopId: shopId,
                    categoryId: categoryId,
                    status: activeStatus,
                  ),
          ),
        ],
      ),
    );
  }
}

class _OrderTabButton extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const _OrderTabButton({
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 40,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : const Color(0xFFE0E0E0),
          border: isSelected
              ? const Border(
                  top: BorderSide(color: Color(0xFF9E9E9E), width: 0.5),
                  left: BorderSide(color: Color(0xFF9E9E9E), width: 0.5),
                  right: BorderSide(color: Color(0xFF9E9E9E), width: 0.5),
                )
              : Border.all(
                  color: const Color(0xFF9E9E9E),
                  width: 0.5,
                ),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontFamily: 'Nunito',
          ),
        ),
      ),
    );
  }
}

/// Matches Android MoreFragment (fragment_more.xml).
/// Clicking Delivered, Replace/Refund, or Cancelled replaces parent layout
/// with a separate screen inside the Orders tab (matching Android MoreFragment.InitializeFragment).
class _MoreOrdersMenuView extends StatelessWidget {
  final OrderCountsModel counts;
  final String shopId;
  final String categoryId;

  const _MoreOrdersMenuView({
    required this.counts,
    required this.shopId,
    required this.categoryId,
  });

  void _openSubOrders(BuildContext context, OrderStatus status) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MoreSubOrdersScreen(
          status: status,
          shopId: shopId,
          categoryId: categoryId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _MoreMenuRow(
          label: 'Delivered',
          count: counts.getCountForStatus(OrderStatus.delivered),
          onTap: () => _openSubOrders(context, OrderStatus.delivered),
        ),
        _MoreMenuRow(
          label: 'Replace/Refund',
          count: counts.getCountForStatus(OrderStatus.replaceRefund),
          onTap: () => _openSubOrders(context, OrderStatus.replaceRefund),
        ),
        _MoreMenuRow(
          label: 'Cancelled',
          count: counts.getCountForStatus(OrderStatus.cancelled),
          onTap: () => _openSubOrders(context, OrderStatus.cancelled),
        ),
      ],
    );
  }
}

class _MoreMenuRow extends StatelessWidget {
  final String label;
  final int count;
  final VoidCallback onTap;

  const _MoreMenuRow({
    required this.label,
    this.count = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(3),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(3),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
              ),
              if (count > 0)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                ),
              const Icon(
                Icons.chevron_right,
                color: Colors.black,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dedicated separate screen inside the Orders tab for More sub-tabs (Delivered, Replace/Refund, Cancelled)
/// strictly matching native Android DeliveryFragment, ReplacementFragment, and CancelFragment.
/// 
/// Replaces the 5-button tabs bar with its own 45dp Toolbar (back arrow, status label),
/// while keeping the bottom 5-tab navigation bar persistently visible.
class MoreSubOrdersScreen extends StatelessWidget {
  final OrderStatus status;
  final String shopId;
  final String categoryId;

  const MoreSubOrdersScreen({
    super.key,
    required this.status,
    required this.shopId,
    required this.categoryId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: Container(
          color: const Color(0xFFF5F5F5), // Android tool_bg
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: 60.0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Color(0xFF616161),
                            size: 22,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        Expanded(
                          child: Text(
                            status.label,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF616161),
                              fontFamily: 'ProductSans',
                            ),
                          ),
                        ),
                        const SizedBox(width: 48), // Balances the left 48px back button
                      ],
                    ),
                  ),
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0xFFE0E0E0),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: OrdersListView(
        shopId: shopId,
        categoryId: categoryId,
        status: status,
      ),
    );
  }
}
