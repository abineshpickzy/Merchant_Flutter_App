import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayfay_merchant_flutter/app/providers/auth_state_provider.dart';
import 'package:bayfay_merchant_flutter/core/providers/location_service_provider.dart';
import 'package:bayfay_merchant_flutter/features/splash/controller/splash_controller.dart';

/// Wraps the entire application to universally monitor Location (GPS) service status.
///
/// Runs silently on every app launch and foreground resume (both Logged-In & Logged-Out):
/// - Checks if GPS / Location Services are turned ON.
/// - When authenticated, if Location is OFF, immediately triggers the native Google Play Services system
///   dialog (with the "Turn on" button) via [LocationServiceNotifier.checkAndPromptLocationService].
/// - On unauthenticated auth screens, prompt behavior is governed specifically per screen
///   (WelcomeScreen prompts native resolution dialog; LoginScreen redirects to settings without OS prompt).
class UniversalLocationObserver extends ConsumerStatefulWidget {
  final Widget child;

  const UniversalLocationObserver({super.key, required this.child});

  @override
  ConsumerState<UniversalLocationObserver> createState() =>
      _UniversalLocationObserverState();
}

class _UniversalLocationObserverState
    extends ConsumerState<UniversalLocationObserver>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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

  Future<void> _checkLocationService() async {
    // Only prompt on resume after splash finishes
    final isSplashComplete = ref.read(splashCompletedProvider);
    if (!isSplashComplete) return;

    final isGpsOn = await ref
        .read(locationServiceProvider.notifier)
        .checkServiceStatus();

    final authState = ref.read(authStateProvider);
    // On unauthenticated auth screens, prompt behavior is governed specifically by screen logic
    // (e.g. WelcomeScreen prompts native resolution dialog; LoginScreen redirects to settings without OS prompt).
    // Prompting universally on resume only applies when authenticated (Dashboard, Orders, etc.).
    if (!isGpsOn && authState is AuthAuthenticated) {
      await ref
          .read(locationServiceProvider.notifier)
          .checkAndPromptLocationService();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
