import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayfay_merchant_flutter/core/constants/app_constants.dart';
import 'package:bayfay_merchant_flutter/core/constants/app_strings.dart';
import 'package:bayfay_merchant_flutter/core/providers/permission_notifier_provider.dart';
import 'package:bayfay_merchant_flutter/core/services/device_token_service.dart';
import '../controller/splash_controller.dart';

/// Splash screen matching Android WelcomeActivity's splash overlay (R.id.splash_screen).
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _isPermissionFlowStarted = false;

  @override
  void initState() {
    super.initState();
    // Cache service synchronously before async gap to avoid "ref after disposed"
    final deviceTokenService = ref.read(deviceTokenServiceProvider);
    _initDeviceToken(deviceTokenService);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startSplashAndPermissionFlow();
    });
  }

  Future<void> _startSplashAndPermissionFlow() async {
    if (_isPermissionFlowStarted) return;
    _isPermissionFlowStarted = true;

    // Minimum delay for branding display
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    final permNotifier = ref.read(permissionNotifierProvider.notifier);
    final permState = ref.read(permissionNotifierProvider);

    if (permState.isFirstTime) {
      // First Launch: Sequentially request native OS permissions directly via permission_handler
      // (1. Camera -> 2. Photos/Media -> 3. Location, followed by automatic GPS resolution prompt)
      await permNotifier.requestFirstLaunchPermissions();
    } else {
      // Subsequent launches: silent check and seamless progression
      await permNotifier.recheckPermissions();
    }

    if (mounted) {
      ref.read(splashControllerProvider.notifier).markComplete();
    }
  }

  Future<void> _initDeviceToken(DeviceTokenService service) async {
    try {
      final token = await service.initAndFetchToken();
      if (token.isNotEmpty) {
        debugPrint('╔══════════════════════════════════════════════════════════════');
        debugPrint('║ [FCM TOKEN]: $token');
        debugPrint('╚══════════════════════════════════════════════════════════════');
      }
    } catch (e) {
      debugPrint('⚠️ [FCM] Splash error fetching token: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Triggers splash controller initialization
    ref.watch(splashControllerProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Center Logo: @drawable/logo (matching Android splash_image)
            Center(
              child: Image.asset(
                AppAssets.logo,
                width: 240,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Text(
                  AppStrings.bayfayTitle,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2196F3),
                  ),
                ),
              ),
            ),

            // Bottom: "Powered By" and @drawable/power_by (matching Android logo & TextView)
            Positioned(
              left: 0,
              right: 0,
              bottom: 24,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    AppStrings.poweredBy,
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF757575),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Image.asset(
                    AppAssets.powerBy,
                    height: 22,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Text(
                      AppStrings.bayfayTitle,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2196F3),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
