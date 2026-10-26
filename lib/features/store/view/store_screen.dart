import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayfay_merchant_flutter/app/theme/app_colors.dart';
import 'package:bayfay_merchant_flutter/core/constants/app_strings.dart';
import '../../dashboard/controller/dashboard_controller.dart';
import '../../dashboard/model/store_model.dart';
import 'package:bayfay_merchant_flutter/features/orders/view/orders_screen.dart';
import '../controller/store_controller.dart';
import 'tabs/store_dashboard_tab_view.dart';
import 'tabs/store_inventory_tab_view.dart';
import 'tabs/store_billing_tab_view.dart';
import 'tabs/store_more_tab_view.dart';

/// Primary Store Screen (`StoreScreen`) providing a 5-tab dashboard shell for an active store.
/// 
/// Located under feature directory `lib/features/store/`.
/// 
/// Includes:
/// - Custom AppBar displaying store name with back leading arrow and Home action button.
/// - 5-tab BottomNavigationBar (Dashboard, Orders, Inventory, Billing, More).
/// - IndexedStack preserving active tab state across switches.
/// - Selected store context provided to Riverpod [selectedStoreProvider].
class StoreScreen extends ConsumerStatefulWidget {
  final StoreModel? store;
  final int initialTabIndex;

  const StoreScreen({
    super.key,
    this.store,
    this.initialTabIndex = 0,
  });

  @override
  ConsumerState<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends ConsumerState<StoreScreen> {
  late int _currentTabIndex;

  @override
  void initState() {
    super.initState();
    _currentTabIndex = widget.initialTabIndex;

    // Provide store context if explicitly passed
    if (widget.store != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(selectedStoreProvider.notifier).selectStore(widget.store!);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedStore = widget.store ?? ref.watch(selectedStoreProvider);
    final storeName = selectedStore?.displayName ?? AppStrings.appName;
     final appBarTitle = _currentTabIndex == 1 ? '$storeName - Orders' : storeName;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(
            Icons.home_rounded,
            color: AppColors.primary,
            size: 28,
          ),
          tooltip: 'Back to Stores',
          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
        ),
        title: Text(
          appBarTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: const [],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Divider(
            height: 1,
            thickness: 1,
            color: Color(0xFFE0E0E0),
          ),
        ),
      ),
      body: Builder(
        builder: (context) {
          if (selectedStore != null) {
            return IndexedStack(
              index: _currentTabIndex,
              children: [
                StoreDashboardTabView(store: selectedStore),
                const OrdersScreen(),
                StoreInventoryTabView(store: selectedStore),
                StoreBillingTabView(store: selectedStore),
                StoreMoreTabView(store: selectedStore),
              ],
            );
          }

          final storesAsync = ref.watch(storesProvider);
          return storesAsync.when(
            data: (stores) {
              if (stores.isNotEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    ref.read(selectedStoreProvider.notifier).selectStore(stores.first);
                  }
                });
                return const Center(child: CircularProgressIndicator(color: AppColors.primary));
              }
              return const Center(
                child: Text(
                  AppStrings.noStoreSelected,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            error: (err, _) => const Center(
              child: Text(
                AppStrings.noStoreSelected,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTabIndex,
        onTap: (index) {
          setState(() {
            _currentTabIndex = index;
            ref.read(storeTabIndexProvider.notifier).state = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: const Color(0xFF757575),
        selectedFontSize: 11,
        unselectedFontSize: 11,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: 'Inventory',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.point_of_sale_outlined),
            activeIcon: Icon(Icons.point_of_sale),
            label: 'Billing',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz_outlined),
            activeIcon: Icon(Icons.more_horiz),
            label: 'More',
          ),
        ],
      ),
    );
  }
}

/// Backward compatibility alias typedefs
typedef StoreHomeScreen = StoreScreen;
typedef StoreDetailsShellScreen = StoreScreen;
