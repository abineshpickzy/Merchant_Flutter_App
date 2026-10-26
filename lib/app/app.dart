import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayfay_merchant_flutter/core/widgets/universal_location_observer.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class BayfayMerchantApp extends ConsumerWidget {
  const BayfayMerchantApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Bayfay Merchant',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
      builder: (context, child) => UniversalLocationObserver(
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
