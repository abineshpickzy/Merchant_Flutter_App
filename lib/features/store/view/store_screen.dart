import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayfay_merchant_flutter/app/theme/app_colors.dart';
import 'package:bayfay_merchant_flutter/core/constants/app_strings.dart';
import '../../dashboard/controller/dashboard_controller.dart';
import '../../dashboard/model/store_model.dart';
import '../controller/store_controller.dart';
import 'tabs/storedashboard/view/store_dashboard_tab_view.dart';
import 'tabs/orders/view/orders_screen.dart';
import 'tabs/inventory/view/store_inventory_tab_view.dart';
import 'tabs/billings/view/store_billing_tab_view.dart';
import 'tabs/settings/view/store_settings_tab_view.dart';

/// Primary Store Screen (`StoreScreen`) providing a 5-tab dashboard shell for an active store.
/// 
/// Located under feature directory `lib/features/store/`.
/// 
/// Matches native Android `StoreOrdersActivity` (activity_store_orders.xml):
/// - Root activity has NO AppBar; each tab fragment defines its own individual 45dp Toolbar.
/// - 5-tab persistent BottomNavigationBar (Dashboard, Orders, Inventory, Billing, More).
/// - IndexedStack preserving active tab state across switches.
/// - Selected store context provided to Riverpod [selectedStoreProvider].
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

  Widget _buildOrdersTabIcon({required bool isSelected, required int count}) {
    final icon = Image.asset(
      'assets/images/ic_orders_icons.png',
      width: 22,
      height: 22,
      color: isSelected ? const Color(0xFF007AFF) : const Color(0xFF616161),
      fit: BoxFit.contain,
    );

    if (count <= 0) return icon;

    return Badge(
      backgroundColor: const Color(0xFFF44336),
      textColor: Colors.white,
      textStyle: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
      label: Text('$count'),
      child: icon,
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedStore = widget.store ?? ref.watch(selectedStoreProvider);
    final int newOrdersCount = selectedStore?.newOrderCount ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
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
                StoreSettingsTabView(store: selectedStore),
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
        selectedItemColor: const Color(0xFF007AFF), // Android select_tab
        unselectedItemColor: const Color(0xFF616161), // Android tool_text
        selectedFontSize: 10,
        unselectedFontSize: 10,
        elevation: 8,
        items: [
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/images/ic_dash_icons.png', // Android ic_dash_icons
              width: 22,
              height: 22,
              color: const Color(0xFF616161),
              fit: BoxFit.contain,
            ),
            activeIcon: Image.asset(
              'assets/images/ic_dash_icons.png',
              width: 22,
              height: 22,
              color: const Color(0xFF007AFF),
              fit: BoxFit.contain,
            ),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: _buildOrdersTabIcon(
              isSelected: false,
              count: newOrdersCount,
            ),
            activeIcon: _buildOrdersTabIcon(
              isSelected: true,
              count: newOrdersCount,
            ),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/images/inventory.webp', // Android inventory
              width: 22,
              height: 22,
              color: const Color(0xFF616161),
              fit: BoxFit.contain,
            ),
            activeIcon: Image.asset(
              'assets/images/inventory.webp',
              width: 22,
              height: 22,
              color: const Color(0xFF007AFF),
              fit: BoxFit.contain,
            ),
            label: 'Inventory',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/images/orderhistory.webp', // Android orderhistory
              width: 22,
              height: 22,
              color: const Color(0xFF616161),
              fit: BoxFit.contain,
            ),
            activeIcon: Image.asset(
              'assets/images/orderhistory.webp',
              width: 22,
              height: 22,
              color: const Color(0xFF007AFF),
              fit: BoxFit.contain,
            ),
            label: 'Billing',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz, size: 22, color: Color(0xFF616161)),
            activeIcon: Icon(Icons.more_horiz, size: 22, color: Color(0xFF007AFF)),
            label: 'More..',
          ),
        ],
      ),
    );
  }
}

/// Backward compatibility alias typedefs
typedef StoreHomeScreen = StoreScreen;
typedef StoreDetailsShellScreen = StoreScreen;
