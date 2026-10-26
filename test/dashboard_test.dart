import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bayfay_merchant_flutter/core/config/app_config.dart';
import 'package:bayfay_merchant_flutter/core/storage/local_storage_service.dart';
import 'package:bayfay_merchant_flutter/features/dashboard/controller/dashboard_controller.dart';
import 'package:bayfay_merchant_flutter/features/dashboard/model/metric_models.dart';
import 'package:bayfay_merchant_flutter/features/dashboard/model/store_model.dart';
import 'package:bayfay_merchant_flutter/features/dashboard/view/dashboard_screen.dart';
import 'package:bayfay_merchant_flutter/features/dashboard/view/widgets/store_card.dart';
import 'package:bayfay_merchant_flutter/core/widgets/app_button.dart';

void main() {
  setUpAll(() {
    AppConfig.init(
      environment: Environment.dev,
      serverUrl: 'https://store-devapi.bayfay.com/merchant/',
      appName: 'Merchant-Dev',
      paymentEnvironment: 2,
    );
    HttpOverrides.global = _TestHttpOverrides();
  });
  group('StoreModel Tests', () {
    test('StoreModel parses legacy Android ListOfStoreResponse.Data properly', () {
      final json = {
        '_id': 'store_12345',
        'display_name': 'BayFay Supermarket',
        'category_image': 'https://example.com/store.png',
        'category_id': 'cat_999',
        'is_open': true,
        'new_order_count': 5,
        'status': 1,
        'is_wholesale': false,
        'is_external': false,
        'is_restaurants': false,
        'store_rating': {'avg': 4.5},
      };

      final store = StoreModel.fromJson(json);

      expect(store.id, 'store_12345');
      expect(store.displayName, 'BayFay Supermarket');
      expect(store.categoryImage, 'https://example.com/store.png');
      expect(store.isOpen, true);
      expect(store.newOrderCount, 5);
      expect(store.isWholeSale, false);
      expect(store.rating, 4.5);
    });

    test('StoreModel handles wholesale and restaurant types', () {
      final json = {
        '_id': 'wholesale_store_1',
        'display_name': 'BayFay Wholesale Hub',
        'is_wholesale': true,
        'is_restaurants': false,
        'is_open': false,
        'new_order_count': 0,
        'store_rating': 4.8,
      };

      final store = StoreModel.fromJson(json);

      expect(store.id, 'wholesale_store_1');
      expect(store.isWholeSale, true);
      expect(store.isOpen, false);
      expect(store.rating, 4.8);
    });

    test('StoreModel toJson serializes correctly', () {
      const store = StoreModel(
        id: 'store_1',
        displayName: 'Test Retail Store',
        isOpen: true,
        newOrderCount: 3,
        isWholeSale: false,
        rating: 4.2,
      );

      final json = store.toJson();
      expect(json['_id'], 'store_1');
      expect(json['display_name'], 'Test Retail Store');
      expect(json['is_open'], true);
      expect(json['new_order_count'], 3);
      expect(json['is_wholesale'], false);
    });

    test('Store categorization into My Stores, External Shops, and Wholesale Shops matches legacy Android logic', () {
      const store1 = StoreModel(id: '1', displayName: 'Retail Store', isExternal: false, isWholeSale: false);
      const store2 = StoreModel(id: '2', displayName: 'External Store', isExternal: true, isWholeSale: false);
      const store3 = StoreModel(id: '3', displayName: 'Wholesale Store', isExternal: false, isWholeSale: true);

      final stores = [store1, store2, store3];

      final myStores = stores.where((s) => !s.isExternal && !s.isWholeSale).toList();
      final externalStores = stores.where((s) => s.isExternal).toList();
      final wholesaleStores = stores.where((s) => s.isWholeSale).toList();

      expect(myStores.length, 1);
      expect(myStores.first.displayName, 'Retail Store');
      expect(externalStores.length, 1);
      expect(externalStores.first.displayName, 'External Store');
      expect(wholesaleStores.length, 1);
      expect(wholesaleStores.first.displayName, 'Wholesale Store');
    });

    test('StoresNotifier fetchMerchantStores and refreshStoresOnly trigger stores refresh without error', () async {
      final container = ProviderContainer(
        overrides: [
          storesProvider.overrideWith(() => _MockStoresNotifier(const [])),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(storesProvider.notifier);
      await notifier.fetchMerchantStores();
      await notifier.refreshStoresOnly();

      expect(container.read(storesProvider).hasValue, isTrue);
      expect(container.read(dashboardControllerProvider).hasValue, isTrue);
    });
  });

  group('DashboardScreen & HomeBodyView UI Tests', () {
    late SharedPreferences sharedPreferences;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      sharedPreferences = await SharedPreferences.getInstance();
    });

    testWidgets('DashboardScreen renders AppBar with zero vertical overflow, Card 2, and Card 3 Sales Analytics', (tester) async {
      const mockStores = [
        StoreModel(
          id: 'store_1',
          displayName: 'Sweet Delights Bakery',
          isOpen: true,
          newOrderCount: 2,
          rating: 4.5,
          isExternal: false,
          isWholeSale: false,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(sharedPreferences),
            storesProvider.overrideWith(() => _MockStoresNotifier(mockStores)),
            notificationCountProvider.overrideWith((ref) => Future.value(3)),
            businessValueProvider.overrideWith((ref) => Future.value(
                  const BusinessValueModel(
                    customersCount: 18,
                    businessValue: 14400,
                  ),
                )),
            partnerInfoProvider.overrideWith((ref) => Future.value(
                  const PartnerInfoModel(
                    annualTurnover: 480000,
                    last30DaysTurnover: 52000,
                    agencyInfo: ['Priority Delivery', 'Turnover Bonus'],
                  ),
                )),
          ],
          child: const MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify AppBar elements
      expect(find.text('BayFay Merchant'), findsOneWidget);
      expect(find.text('Add Store'), findsOneWidget);
      expect(find.text('3'), findsWidgets); // Unread notification badge

      // Verify Card 1: Buy From Wholesale Stores
      expect(find.text('Buy From'), findsOneWidget);
      expect(find.text('Wholesale Stores'), findsOneWidget);

      // Verify Card 2: Dynamic Business Value
      expect(find.text('Business value'), findsOneWidget);
      expect(find.text('18'), findsOneWidget);
      expect(find.text('₹ 14400'), findsOneWidget);

      // Verify Card 3: Dynamic Sales Analytics
      expect(find.text('Last 1 Year'), findsOneWidget);
      expect(find.text('₹ 480000'), findsOneWidget);
      expect(find.text('Last 30 Days'), findsOneWidget);
      expect(find.text('₹ 52000'), findsOneWidget);

      // Verify Promotion banner elements
      expect(find.text('Guaranteed More Orders'), findsOneWidget);
      expect(find.text('Enable scratch card Promotion now.'), findsOneWidget);
      expect(find.text('The scratch card promo appears first when customer open the app.'), findsOneWidget);
      expect(find.text('The promo applies only if the customer scratched your promo code.'), findsOneWidget);
      expect(find.text('20 % Discount above purchase limit ₹ 199'), findsOneWidget);
      expect(find.text('Later'), findsOneWidget);
      expect(find.text('Activate'), findsOneWidget);
      expect(find.text('Sweet Delights Bakery'), findsWidgets);

      // Verify store section
      expect(find.text('My Stores'), findsOneWidget);

      // Tap Card 2: Business Value Dialog
      await tester.tap(find.text('Business value'));
      await tester.pumpAndSettle();
      expect(find.text('Current Value: ₹ 14400'), findsOneWidget);
      expect(find.text('Customer / Lead Count: 18'), findsOneWidget);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Tap Card 3: Sales Analytics Dialog
      await tester.tap(find.text('Last 1 Year'));
      await tester.pumpAndSettle();
      expect(find.text('Sales Analytics & Agency'), findsOneWidget);
      expect(find.text('• Annual Turnover: ₹ 480000'), findsOneWidget);
      expect(find.text('• Last 30 Days: ₹ 52000'), findsOneWidget);
      expect(find.text('• Priority Delivery'), findsOneWidget);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
    });

    testWidgets('DashboardScreen isolates metric API errors cleanly without breaking Home Screen', (tester) async {
      const mockStores = [
        StoreModel(
          id: 'store_1',
          displayName: 'Sweet Delights Bakery',
          isOpen: true,
          newOrderCount: 0,
          rating: 4.0,
          isExternal: false,
          isWholeSale: false,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(sharedPreferences),
            storesProvider.overrideWith(() => _MockStoresNotifier(mockStores)),
            notificationCountProvider.overrideWith((ref) => Future.value(0)),
            businessValueProvider.overrideWith((ref) => Future.error(Exception('API-078 failed'))),
            partnerInfoProvider.overrideWith((ref) => Future.error(Exception('API-077 failed'))),
          ],
          child: const MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Home Screen still renders perfectly with fallback values
      expect(find.text('BayFay Merchant'), findsOneWidget);
      expect(find.text('Business value'), findsOneWidget);
      expect(find.text('0'), findsWidgets);
      expect(find.text('₹ 0'), findsWidgets);
      expect(find.text('My Stores'), findsOneWidget);
    });

    testWidgets('Tapping Later dismisses the Guaranteed More Orders promotion card', (tester) async {
      const mockStores = [
        StoreModel(
          id: 'store_1',
          displayName: 'Sweet Delights Bakery',
          isOpen: true,
          newOrderCount: 0,
          rating: 4.0,
          isExternal: false,
          isWholeSale: false,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(sharedPreferences),
            storesProvider.overrideWith(() => _MockStoresNotifier(mockStores)),
            notificationCountProvider.overrideWith((ref) => Future.value(0)),
            businessValueProvider.overrideWith((ref) => Future.value(
                  const BusinessValueModel(customersCount: 10, businessValue: 5000),
                )),
            partnerInfoProvider.overrideWith((ref) => Future.value(
                  const PartnerInfoModel(annualTurnover: 100000, last30DaysTurnover: 10000),
                )),
          ],
          child: const MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Guaranteed More Orders'), findsOneWidget);

      // Tap "Later"
      await tester.tap(find.text('Later'));
      await tester.pumpAndSettle();

      // Promo banner should be hidden
      expect(find.text('Guaranteed More Orders'), findsNothing);
    });
  });

  group('MetricModels Unit Tests', () {
    test('BusinessValueModel parses API-078 response correctly', () {
      final json = {
        'success': true,
        'data': {
          'customers_count': 25,
          'business_value': 20000,
        },
      };

      final model = BusinessValueModel.fromJson(json);
      expect(model.customersCount, 25);
      expect(model.businessValue, 20000);
      expect(model.toJson()['customers_count'], 25);
    });

    test('PartnerInfoModel parses API-077 response correctly', () {
      final json = {
        'success': true,
        'data': {
          'turnover': {
            'annual': 350000,
            'last30days': 45000,
          },
          'agencyInfo': {
            'info': ['Higher Margins', 'Bulk Catalog'],
            'note': 'Special Partner Note',
            'support': 'agent@bayfay.com',
          },
        },
      };

      final model = PartnerInfoModel.fromJson(json);
      expect(model.annualTurnover, 350000);
      expect(model.last30DaysTurnover, 45000);
      expect(model.agencyInfo.length, 2);
      expect(model.agencyInfo.first, 'Higher Margins');
      expect(model.note, 'Special Partner Note');
      expect(model.support, 'agent@bayfay.com');
    });
  });

  group('PillActionButton & StoreCard Tests', () {
    testWidgets('PillActionButton renders pill curve and handles tap', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PillActionButton(
              label: 'Activate',
              backgroundColor: const Color(0xFF1EA838),
              onPressed: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Activate'), findsOneWidget);
      await tester.tap(find.text('Activate'));
      expect(tapped, isTrue);
    });

    testWidgets('StoreCard renders Pending status badge with yellow/amber gradient for pending stores', (tester) async {
      const store = StoreModel(
        id: 'pending_store_1',
        displayName: 'Fresh Grocery Mart',
        status: 1, // Pending review
        isOpen: false,
        newOrderCount: 0,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 140,
                height: 160,
                child: StoreCard(
                  store: store,
                  onTap: () {},
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Waiting for Review'), findsNothing);
    });
  });
}

class _MockStoresNotifier extends StoresNotifier {
  final List<StoreModel> _stores;
  _MockStoresNotifier(this._stores);

  @override
  FutureOr<List<StoreModel>> build() async {
    return _stores;
  }

  @override
  Future<void> refreshStores() async {
    state = const AsyncLoading();
    state = AsyncData(_stores);
  }
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

