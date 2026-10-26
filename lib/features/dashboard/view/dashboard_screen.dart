import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayfay_merchant_flutter/app/theme/app_colors.dart';
import 'package:bayfay_merchant_flutter/core/constants/app_strings.dart';
import 'package:bayfay_merchant_flutter/core/providers/permission_notifier_provider.dart';
import 'package:bayfay_merchant_flutter/core/widgets/permission_permanently_denied_dialog.dart';
import '../../add_store/view/select_store_type_screen.dart';
import '../controller/dashboard_controller.dart';
import 'views/home_body_view.dart';
import 'widgets/home_drawer.dart';

/// Legacy 1:1 Android HomeActivity parity screen (activity_home.xml + fragment_home.xml)
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with WidgetsBindingObserver {
  bool _hasPromptedLocation = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLocationAndPermissions();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(permissionNotifierProvider.notifier).recheckPermissions();
    }
  }

  void _checkLocationAndPermissions() {
    if (!mounted || _hasPromptedLocation) return;
    final permState = ref.read(permissionNotifierProvider);
    final permNotifier = ref.read(permissionNotifierProvider.notifier);

    // Check for permanently denied permissions
    if (permState.hasPermanentlyDenied) {
      _hasPromptedLocation = true;
      PermissionPermanentlyDeniedDialog.show(
        context,
        onOpenSettings: () {
          permNotifier.openAppSettingsPage();
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationCountAsync = ref.watch(notificationCountProvider);
    final notificationCount = notificationCountAsync.value ?? 0;

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const HomeDrawer(),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF5F5F5),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(
              Icons.menu_rounded,
              color: Color(0xFF616161),
            ),
            tooltip: AppStrings.navigationMenu,
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        centerTitle: true,
        title: const Text(
          'BayFay Merchant',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF616161),
          ),
        ),
        actions: [
          // Add Store Action (matching @id/next: TextView "Add Store")
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SelectStoreTypeScreen(),
                ),
              );
            },
            child: const Text(
              'Add Store',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),

          // Notification Bell with unread badge (matching @id/notification_layout + @id/notify_badge)
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Color(0xFF616161),
                ),
                tooltip: AppStrings.notifications,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(AppStrings.notificationsScreen),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              if (notificationCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE53935),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      notificationCount > 99 ? '99+' : '$notificationCount',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),
        ],
        // Bottom 1dp divider (matching activity_home.xml @id/view: #E3E3E3)
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Divider(
            height: 1,
            thickness: 1,
            color: Color(0xFFE3E3E3),
          ),
        ),
      ),
      body: const HomeBodyView(),
    );
  }
}
