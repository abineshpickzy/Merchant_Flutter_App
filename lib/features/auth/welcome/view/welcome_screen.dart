import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bayfay_merchant_flutter/app/providers/auth_state_provider.dart';
import 'package:bayfay_merchant_flutter/app/router/app_routes.dart';
import 'package:bayfay_merchant_flutter/app/theme/app_colors.dart';
import 'package:bayfay_merchant_flutter/core/constants/app_constants.dart';
import 'package:bayfay_merchant_flutter/core/constants/app_strings.dart';
import 'package:bayfay_merchant_flutter/core/storage/secure_storage_service.dart';
import 'package:bayfay_merchant_flutter/core/widgets/app_button.dart';
import 'package:bayfay_merchant_flutter/core/widgets/app_snackbar.dart';
import 'package:geolocator/geolocator.dart';
import 'package:bayfay_merchant_flutter/core/providers/location_service_provider.dart';
import 'package:bayfay_merchant_flutter/features/auth/login/model/login_response.dart';

/// Welcome screen designed in 1:1 parity with Android's WelcomeActivity.java & welcome_activity.xml.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen>
    with WidgetsBindingObserver {
  bool _hasStartedRefresh = false;
  bool _refreshFailed = false;
  String? _cachedMerchantName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLocationService();
      _loadCachedProfileAndCheckSession();
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
      _checkLocationService();
    }
  }

  /// Retrieves cached merchant name from local storage (matching Android PreferenceUtils.GetUserData())
  Future<void> _loadCachedProfileAndCheckSession() async {
    if (!mounted) return;

    try {
      final storage = ref.read(secureStorageServiceProvider);
      final profileJson = await storage.read(AppConstants.userProfileKey);
      if (profileJson != null && profileJson.isNotEmpty) {
        final profile = MerchantProfile.fromJson(
          jsonDecode(profileJson) as Map<String, dynamic>,
        );
        final name = profile.fullName;
        if (name.isNotEmpty && mounted) {
          setState(() {
            _cachedMerchantName = name;
          });
        }
      }
    } catch (_) {}

    _checkSessionAndRefreshToken();
  }

  /// Automatically triggers token refresh for logged-in merchants (matching Android callRefreshToken())
  Future<void> _checkSessionAndRefreshToken() async {
    if (_hasStartedRefresh || !mounted) return;

    final authState = ref.read(authStateProvider);
    final storage = ref.read(secureStorageServiceProvider);
    final hasToken = (await storage.getAccessToken())?.isNotEmpty ?? false;

    if (authState is AuthAuthenticated || hasToken) {
      _hasStartedRefresh = true;

      final success =
          await ref.read(authStateProvider.notifier).refreshToken();

      if (!mounted) return;

      if (success) {
        // Small delay for smooth visual transition
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) {
          context.go(AppRoutes.dashboard);
        }
      } else {
        setState(() {
          _refreshFailed = true;
        });
        AppSnackBar.showError(
          context,
          'Session expired. Please log in to continue.',
        );
      }
    }
  }

  /// Checks device GPS status within the Welcome Screen lifecycle:
  /// - Only runs when this screen is strictly the top visible route.
  /// - If GPS is OFF and location permission is granted, triggers the native Google Location Accuracy prompt.
  Future<void> _checkLocationService({bool force = false}) async {
    if (!mounted) return;

    final isCurrentRoute = ModalRoute.of(context)?.isCurrent ?? false;
    if (!isCurrentRoute) return;

    try {
      final isGpsOn = await Geolocator.isLocationServiceEnabled();
      if (isGpsOn) {
        if (mounted) {
          await ref.read(locationServiceProvider.notifier).checkServiceStatus();
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      if (mounted) {
        await ref
            .read(locationServiceProvider.notifier)
            .checkAndPromptLocationService(force: force);
      }
    } catch (e) {
      debugPrint('⚠️ [WelcomeScreen] _checkLocationService error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isAuthenticated =
        (authState is AuthAuthenticated || _cachedMerchantName != null) &&
            !_refreshFailed;

    final merchantName = _cachedMerchantName ??
        (authState is AuthAuthenticated
            ? authState.profile?.fullName ?? ''
            : '');

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 48),

            // Top Header: "BayFay Merchant" (matching Android textView14)
            const Text(
              AppStrings.welcomeTitle,
              style: TextStyle(
                fontFamily: AppFonts.nunito,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                letterSpacing: 0.2,
              ),
            ),

            // Center: BayFay Transparent Logo (matching Android imageView6 @drawable/logo_transaparent)
            Expanded(
              child: Center(
                child: Image.asset(
                  AppAssets.logoTransparent,
                  width: 220,
                  height: 220,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.storefront_rounded,
                    size: 120,
                    color: AppColors.brandBlue,
                  ),
                ),
              ),
            ),

            // Bottom Actions Container (matching Android changes LinearLayout / welcome_back_lay)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
              child: isAuthenticated
                  ? _buildWelcomeBackLayout(context, merchantName)
                  : _buildLoginSignUpButtons(context),
            ),
          ],
        ),
      ),
    );
  }

  /// Buttons for unauthenticated visitors (matching Android's changes layout)
  Widget _buildLoginSignUpButtons(BuildContext context) {
    return Row(
      children: [
        // Merchant Login Button (Blue: @drawable/blue_btn_bg / @color/logo)
        Expanded(
          child: AppButton.primary(
            height: 46,
            borderRadius: 6,
            text: AppStrings.merchantLogin,
            onPressed: () => context.push(AppRoutes.login),
          ),
        ),
        const SizedBox(width: 14),

        // Sign Up Button (Lime Green: @drawable/sign_up_btn_bg / @color/login_btn)
        Expanded(
          child: AppButton.lime(
            height: 46,
            borderRadius: 6,
            text: AppStrings.signup,
            onPressed: () => context.push(AppRoutes.register),
          ),
        ),
      ],
    );
  }

  /// Welcome back layout for returning merchants (matching Android's welcome_back_lay)
  Widget _buildWelcomeBackLayout(
    BuildContext context,
    String merchantName,
  ) {
    final displayName =
        merchantName.isNotEmpty ? merchantName : 'BayFay Merchants';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: "Welcome Back" + Dynamic Merchant Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Welcome Back',
                  style: TextStyle(
                    fontFamily: AppFonts.productSans,
                    fontSize: 16,
                    color: Color(0xFF616161),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  displayName,
                  style: const TextStyle(
                    fontFamily: AppFonts.productSans,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Right: Progress indicator + "Loading\n Please Wait.."
          Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Loading\n Please Wait..',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppFonts.productSans,
                  fontSize: 10,
                  color: Colors.black,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
