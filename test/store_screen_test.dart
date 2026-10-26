import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bayfay_merchant_flutter/core/config/app_config.dart';
import 'package:bayfay_merchant_flutter/core/storage/local_storage_service.dart';
import 'package:bayfay_merchant_flutter/features/dashboard/model/store_model.dart';
import 'package:bayfay_merchant_flutter/features/dashboard/view/widgets/store_card.dart';
import 'package:bayfay_merchant_flutter/features/store/controller/store_controller.dart';
import 'package:bayfay_merchant_flutter/features/store/model/store_dashboard_metrics_model.dart';
import 'package:bayfay_merchant_flutter/features/store/view/store_screen.dart';

void main() {
  late SharedPreferences sharedPreferences;

  setUpAll(() {
    AppConfig.init(
      environment: Environment.dev,
      serverUrl: 'https://store-devapi.bayfay.com/merchant/',
      appName: 'Merchant-Dev',
      paymentEnvironment: 2,
    );
    HttpOverrides.global = _TestHttpOverrides();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    sharedPreferences = await SharedPreferences.getInstance();
  });

  group('Store Status Validation Gate Tests (status == 2)', () {
    const pendingStore = StoreModel(
      id: 'pending_1',
      displayName: 'Pending Bakery',
      status: 1, // Pending review
    );

    const suspendedStore = StoreModel(
      id: 'suspended_1',
      displayName: 'Suspended Market',
      status: 4, // Suspended
    );

    const activeStore = StoreModel(
      id: 'active_1',
      displayName: 'Super Active Store',
      status: 2, // Approved & Active
    );

    testWidgets('Tapping store with status == 1 blocks navigation and shows "Store is waiting for approval"', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(sharedPreferences),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => Consumer(
                  builder: (context, ref, _) {
                    return ElevatedButton(
                      onPressed: () => StoreCard.handleStoreTap(
                        context,
                        ref,
                        pendingStore,
                      ),
                      child: const Text('Tap Pending Store'),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tap Pending Store'));
      await tester.pumpAndSettle();

      // Warning snackbar is displayed
      expect(find.text('Store is waiting for approval'), findsOneWidget);
      // Navigation is blocked; StoreScreen is not created
      expect(find.byType(StoreScreen), findsNothing);
    });

    testWidgets('Tapping store with status == 4 blocks navigation and shows "This store is currently inactive"', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(sharedPreferences),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => Consumer(
                  builder: (context, ref, _) {
                    return ElevatedButton(
                      onPressed: () => StoreCard.handleStoreTap(
                        context,
                        ref,
                        suspendedStore,
                      ),
                      child: const Text('Tap Suspended Store'),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tap Suspended Store'));
      await tester.pumpAndSettle();

      // Warning snackbar is displayed
      expect(find.text('This store is currently inactive'), findsOneWidget);
      // Navigation is blocked; StoreScreen is not created
      expect(find.byType(StoreScreen), findsNothing);
    });

    testWidgets('Tapping store with status == 2 navigates to StoreScreen cleanly', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(sharedPreferences),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => Consumer(
                  builder: (context, ref, _) {
                    return ElevatedButton(
                      onPressed: () => StoreCard.handleStoreTap(
                        context,
                        ref,
                        activeStore,
                      ),
                      child: const Text('Tap Active Store'),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tap Active Store'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Navigation succeeds into StoreScreen
      expect(find.byType(StoreScreen), findsOneWidget);
      expect(find.text('Super Active Store'), findsWidgets);
    });
  });

  group('StoreScreen Layout & Navigation Tests', () {
    const activeStore = StoreModel(
      id: 'active_99',
      displayName: 'Very Long Merchant Supermarket Store Name That Will Be Truncated With Ellipsis',
      status: 2,
      isOpen: true,
      newOrderCount: 4,
      rating: 4.8,
    );

    testWidgets('StoreScreen displays truncated store title, custom AppBar with solid Home leading icon & 5 BottomNav tabs', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(sharedPreferences),
            storeDashboardMetricsProvider('active_99').overrideWith(
              (ref) => Future.value(const StoreDashboardMetricsModel(
                usersVisited: 18,
                totalSalesAmount: 4500,
                noOfOrders: 10,
                usersInCart: 5,
                noOfReplacedProducts: 2,
              )),
            ),
          ],
          child: const MaterialApp(
            home: StoreScreen(store: activeStore),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify AppBar title displays store name
      expect(find.text('Very Long Merchant Supermarket Store Name That Will Be Truncated With Ellipsis'), findsWidgets);

      // Verify Solid Home leading icon button
      expect(find.byIcon(Icons.home_rounded), findsWidgets);

      // Verify 5 BottomNavigationBar items
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Orders'), findsOneWidget);
      expect(find.text('Inventory'), findsOneWidget);
      expect(find.text('Billing'), findsOneWidget);
      expect(find.text('More'), findsOneWidget);

      // Verify initial tab (Dashboard) displays exact native 16 pastel cards grid & date filters
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('7 Days'), findsOneWidget);
      expect(find.text('30 Days'), findsOneWidget);
      expect(find.text('Go'), findsOneWidget);
      expect(find.text('Users Visited'), findsOneWidget);
      expect(find.text('Users till cart'), findsOneWidget);
      expect(find.text('Number of orders'), findsOneWidget);
      expect(find.text('Total Amount'), findsOneWidget);

      // Switch to Tab 1 (Orders)
      await tester.tap(find.text('Orders'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(IndexedStack), findsOneWidget);

      // Switch to Tab 2 (Inventory)
      await tester.tap(find.text('Inventory'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Inventory & Catalog Manager'), findsOneWidget);

      // Switch to Tab 3 (Billing)
      await tester.tap(find.text('Billing'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Billing & Transactions'), findsOneWidget);

      // Switch to Tab 4 (More)
      await tester.tap(find.text('More'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Store Management'), findsOneWidget);
      expect(find.text('Notification Preferences'), findsOneWidget);
      expect(find.text('Security & Password'), findsOneWidget);
    });

    testWidgets('Tapping leading Home icon on AppBar returns to root route directly', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(sharedPreferences),
          ],
          child: MaterialApp(
            initialRoute: '/',
            routes: {
              '/': (context) => const Scaffold(body: Text('Root Screen')),
              '/details': (context) => const StoreScreen(store: activeStore),
            },
          ),
        ),
      );

      // Push store details shell onto navigator
      final BuildContext rootContext = tester.element(find.text('Root Screen'));
      Navigator.of(rootContext).pushNamed('/details');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(StoreScreen), findsOneWidget);

      // Tap Leading Home button
      await tester.tap(find.byIcon(Icons.home_rounded).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // Returns directly to Root Screen
      expect(find.text('Root Screen'), findsOneWidget);
      expect(find.byType(StoreScreen), findsNothing);
    });
  });
}

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _MockHttpClient();
  }
}

class _MockHttpClient implements HttpClient {
  @override
  bool autoUncompress = true;

  @override
  Duration idleTimeout = const Duration(seconds: 15);

  @override
  int? maxConnectionsPerHost;

  @override
  String? userAgent;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _MockHttpClientRequest();

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async => _MockHttpClientRequest();

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockHttpClientRequest implements HttpClientRequest {
  @override
  HttpHeaders get headers => _MockHttpHeaders();

  @override
  Future<HttpClientResponse> close() async => _MockHttpClientResponse();

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockHttpHeaders implements HttpHeaders {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockHttpClientResponse implements HttpClientResponse {
  static final List<int> _transparentPng = <int>[
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
    0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
    0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
    0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
    0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
    0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
    0x42, 0x60, 0x82,
  ];

  @override
  int get statusCode => 200;

  @override
  int get contentLength => _transparentPng.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.value(_transparentPng).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
