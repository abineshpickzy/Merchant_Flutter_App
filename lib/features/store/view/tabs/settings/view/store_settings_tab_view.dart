import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayfay_merchant_flutter/core/network/api_endpoints.dart';
import 'package:bayfay_merchant_flutter/features/dashboard/controller/dashboard_controller.dart';
import 'package:bayfay_merchant_flutter/features/dashboard/model/store_model.dart';
import 'package:bayfay_merchant_flutter/features/store/view/widgets/store_tab_app_bar.dart';
import '../controller/setting_controller.dart';
import 'subpages/additional_settings_view.dart';
import 'subpages/api_keys_view.dart';
import 'subpages/configure_shop_ui_view.dart';
import 'subpages/licence_details_view.dart';
import 'subpages/order_history_view.dart';
import 'subpages/shop_info_view.dart';
import 'subpages/store_delivery_setting_view.dart';
import 'subpages/store_details_setting_view.dart';
import 'subpages/store_messages_view.dart';
import 'widgets/branded_shop_card.dart';
import 'widgets/private_shop_card.dart';
import 'widgets/setting_menu_row.dart';
import 'widgets/setting_section_header.dart';
import 'widgets/settings_bottom_bar.dart';
import 'widgets/settings_skeleton_loader.dart';

/// Tab 5: Store Settings View matching Android SettingsFragment.java & shop_setting_fragment.xml 1:1
class StoreSettingsTabView extends ConsumerStatefulWidget {
  final StoreModel store;

  const StoreSettingsTabView({
    super.key,
    required this.store,
  });

  @override
  ConsumerState<StoreSettingsTabView> createState() => _StoreSettingsTabViewState();
}

class _StoreSettingsTabViewState extends ConsumerState<StoreSettingsTabView> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(settingControllerProvider(widget.store));
    final controller = ref.read(settingControllerProvider(widget.store).notifier);
    final authHeaderAsync = ref.watch(authHeaderProvider);
    final authHeaders = authHeaderAsync.valueOrNull ?? {};
    final baseUrl = authHeaders['baseUrl'] ?? ApiEndpoints.baseUrl;
    final fallbackImgUrl = widget.store.getImageUrl(baseUrl);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: StoreTabAppBar(
        title: 'Settings - ${widget.store.displayName}',
      ),
      body: Stack(
        children: [
          // Main Body
          if (state.isLoading && state.data == null)
            const SettingsSkeletonLoader()
          else
            RefreshIndicator(
              onRefresh: () => controller.loadSettings(),
              color: const Color(0xFF2196F3),
              child: ListView(
                padding: const EdgeInsets.only(bottom: 90),
                children: [
                  // 1. Order History
                  SettingMenuRow(
                    title: 'Order History',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => OrderHistoryView(store: widget.store),
                        ),
                      );
                    },
                  ),

                  // 2. Message
                  SettingMenuRow(
                    title: 'Message',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => StoreMessagesView(store: widget.store),
                        ),
                      );
                    },
                  ),

                  // 3. Branded Store Section Header
                  SettingSectionHeader(
                    title: state.data?.categoryType.isNotEmpty == true
                        ? '${state.data!.categoryType} Settings'
                        : '${widget.store.displayName} Settings',
                  ),

                  // 4. Branded Store Details Card
                  if (state.data != null)
                    BrandedShopCard(
                      data: state.data!,
                      fallbackImageUrl: fallbackImgUrl,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => StoreDetailsSettingView(store: widget.store),
                          ),
                        );
                      },
                    ),

                  // 5. Shop Delivery Settings
                  SettingMenuRow(
                    title: 'Shop Delivery Settings',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => StoreDeliverySettingView(store: widget.store),
                        ),
                      );
                    },
                  ),

                  // 6. Additional Settings
                  SettingMenuRow(
                    title: 'Additional Settings',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AdditionalSettingsView(store: widget.store),
                        ),
                      );
                    },
                  ),

                  // 7. Licence Details
                  SettingMenuRow(
                    title: 'Licence Details',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => LicenceDetailsView(store: widget.store),
                        ),
                      );
                    },
                  ),

                  // 8. About Shop
                  SettingMenuRow(
                    title: 'About Shop',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ShopInfoView(store: widget.store),
                        ),
                      );
                    },
                  ),

                  // 9. Configure Shop UI
                  SettingMenuRow(
                    title: 'Configure Shop UI',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ConfigureShopUiView(store: widget.store),
                        ),
                      );
                    },
                  ),

                  // 10. Private Shop (Conditional)
                  if (state.data?.privateShop != null && state.data!.privateShop!.isEnabled) ...[
                    const SettingSectionHeader(title: 'Private Shop Settings'),
                    PrivateShopCard(
                      data: state.data!,
                      onToggleOpen: (val) => _handlePrivateShopToggle(val),
                    ),
                  ],

                  // 11. Common Section Header
                  const SettingSectionHeader(title: 'Common'),

                  // 12. API Key's
                  SettingMenuRow(
                    title: "API Key's",
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ApiKeysView(store: widget.store),
                        ),
                      );
                    },
                  ),

                  // 13. Agency Settings (Conditional)
                  if (state.data?.isDeliveryAgency == true) ...[
                    const SettingSectionHeader(title: 'Agency Settings'),
                    SettingMenuRow(
                      title: 'Detach Store',
                      onTap: () => _handleDetachStore(),
                    ),
                  ],
                ],
              ),
            ),

          // Pinned Bottom Bar (Shop Close/Open + Busy)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SettingsBottomBar(
              isOpen: state.data?.isOpen ?? widget.store.isOpen,
              isBusy: state.data?.isBusy ?? false,
              isEnabled: !state.isUpdating,
              onToggleOpen: (val) {
                final status = state.data?.shopStatus ?? 3;
                _handleShopOpenToggle(val, status);
              },
              onToggleBusy: (val) => _handleShopBusyToggle(val),
            ),
          ),
        ],
      ),
    );
  }

  /// Busy toggle confirmation alert matching Android shopBusy dialog
  void _handleShopBusyToggle(bool b) {
    final controller = ref.read(settingControllerProvider(widget.store).notifier);

    if (b) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogCtx) => AlertDialog(
          title: const Text('Info', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text(
            'This option will indicate the customers that quick delivery is unavailable now but they can place order. Do you wish to continue?',
            style: TextStyle(fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogCtx).pop();
                controller.setShopBusy(true);
              },
              child: const Text('Ok', style: TextStyle(color: Color(0xFF2196F3))),
            ),
          ],
        ),
      );
    } else {
      controller.setShopBusy(false);
    }
  }

  /// Shop Open/Close toggle matching Android check logic
  void _handleShopOpenToggle(bool b, int storeStatus) {
    final controller = ref.read(settingControllerProvider(widget.store).notifier);

    if (storeStatus == 1) {
      // Payment check required
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Info'),
          content: const Text('Payment setup is pending for this store.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Ok'),
            ),
          ],
        ),
      );
    } else if (storeStatus == 2) {
      // Review required
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Warning'),
          content: const Text('Shop under review'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Ok'),
            ),
          ],
        ),
      );
    } else {
      // Normal confirmation
      final message = b ? 'Do you want to open the shop?' : 'Do you want to close the shop?';
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogCtx) => AlertDialog(
          title: const Text('Confirm', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text(message, style: const TextStyle(fontSize: 13)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogCtx).pop();
                controller.setShopOpen(b);
              },
              child: const Text('Ok', style: TextStyle(color: Color(0xFF2196F3))),
            ),
          ],
        ),
      );
    }
  }

  /// Private Shop toggle confirmation
  void _handlePrivateShopToggle(bool b) {
    final controller = ref.read(settingControllerProvider(widget.store).notifier);
    final message = b
        ? 'Do you want to open the private shop?'
        : 'Do you want to close the private shop?';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Confirm', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message, style: const TextStyle(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              controller.setPrivateShopOpen(b);
            },
            child: const Text('Ok', style: TextStyle(color: Color(0xFF2196F3))),
          ),
        ],
      ),
    );
  }

  /// Detach store confirmation
  void _handleDetachStore() {
    final controller = ref.read(settingControllerProvider(widget.store).notifier);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Detach Store', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          'Are you sure you want to detach this store from the agency?',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              final result = await controller.detachShop();
              if (mounted) {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Info'),
                    content: Text(result.message),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('OKAY', style: TextStyle(color: Colors.blue)),
                      ),
                    ],
                  ),
                );
              }
            },
            child: const Text('Detach', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

/// Backward compatibility typedef
typedef StoreMoreTabView = StoreSettingsTabView;
