import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayfay_merchant_flutter/app/providers/auth_state_provider.dart';

final splashCompletedProvider = StateProvider<bool>((ref) => false);

final splashControllerProvider =
    AutoDisposeAsyncNotifierProvider<SplashController, void>(() {
  return SplashController();
});

class SplashController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() async {
    // Artificial minimum delay for smooth splash experience
    await Future.delayed(const Duration(milliseconds: 1200));

    // Inspect auth state
    ref.read(authStateProvider);
  }

  void markComplete() {
    ref.read(splashCompletedProvider.notifier).state = true;
  }
}
