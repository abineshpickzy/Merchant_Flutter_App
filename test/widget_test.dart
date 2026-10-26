import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayfay_merchant_flutter/app/app.dart';
import 'package:bayfay_merchant_flutter/core/config/app_config.dart';
import 'package:bayfay_merchant_flutter/core/storage/local_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    AppConfig.init(
      environment: Environment.dev,
      serverUrl: 'https://store-devapi.bayfay.com/merchant/',
      appName: 'Merchant-Dev',
      paymentEnvironment: 2,
    );
  });

  testWidgets('App launches and displays initial screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final sharedPreferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        ],
        child: const BayfayMerchantApp(),
      ),
    );

    // Initial pump (splash screen)
    await tester.pump();
    expect(find.byType(BayfayMerchantApp), findsOneWidget);

    // Settle splash timer
    await tester.pump(const Duration(milliseconds: 1500));
  });
}
