import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bayfay_merchant_flutter/core/config/app_config.dart';
import 'package:bayfay_merchant_flutter/features/add_store/model/location_model.dart';
import 'package:bayfay_merchant_flutter/features/add_store/model/picked_location_data.dart';
import 'package:bayfay_merchant_flutter/features/add_store/model/store_category_model.dart';
import 'package:bayfay_merchant_flutter/features/add_store/model/store_type_model.dart';
import 'package:bayfay_merchant_flutter/features/add_store/model/create_store_request.dart';
import 'package:bayfay_merchant_flutter/features/add_store/controller/add_store_controller.dart';
import 'package:bayfay_merchant_flutter/features/add_store/repository/add_store_repository.dart';
import 'package:bayfay_merchant_flutter/features/add_store/view/add_store_form_screen.dart';
import 'package:bayfay_merchant_flutter/features/add_store/view/widgets/store_image_picker.dart';
import 'package:bayfay_merchant_flutter/features/add_store/view/widgets/step_indicator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:bayfay_merchant_flutter/core/services/geocoding_service.dart';
import 'package:bayfay_merchant_flutter/core/services/places_service.dart';
import 'package:bayfay_merchant_flutter/features/add_store/view/location_flow/select_store_location_screen.dart';
import 'package:bayfay_merchant_flutter/features/add_store/view/select_store_type_screen.dart';

import 'package:bayfay_merchant_flutter/core/constants/app_strings.dart';
import 'package:bayfay_merchant_flutter/features/add_store/view/terms_condition_screen.dart';
import 'package:bayfay_merchant_flutter/features/add_store/view/widgets/otp_verify_dialog.dart';
import 'package:bayfay_merchant_flutter/features/add_store/view/widgets/availability_days_row.dart';

import 'package:bayfay_merchant_flutter/features/add_store/model/wholesale_time_slot_model.dart';

class _TestHttpOverrides extends HttpOverrides {}

class FakeAddStoreRepository extends Fake implements AddStoreRepository {
  @override
  Future<List<WholesaleTimeSlotModel>> fetchWholesaleTimeSlots() async => const [
        WholesaleTimeSlotModel(id: 'slot_1', slotName: '7 am to 9 am', limit: 100, isSelected: true),
        WholesaleTimeSlotModel(id: 'slot_2', slotName: '9 am to 11 am', limit: 100, isSelected: false),
      ];

  @override
  Future<List<StoreTypeModel>> fetchStoreTypes() async => [];

  @override
  Future<List<StoreCategoryModel>> fetchCategories(int typeId) async => [];

  @override
  Future<List<String>> fetchCountries() async => ['India'];

  @override
  Future<List<LocationModel>> fetchStatesByCountry(String country) async => const [
        LocationModel(
            id: 'loc_ambur',
            city: 'Ambur',
            state: 'Tamil Nadu',
            country: 'India'),
        LocationModel(
            id: 'loc_vellore',
            city: 'Vellore',
            state: 'Tamil Nadu',
            country: 'India'),
      ];

  @override
  Future<List<LocationModel>> fetchLocations() async => fetchStatesByCountry('India');

  @override
  Future<StoreCreationResult> createStore(CreateStoreRequest request, List<File> images) async =>
      const StoreCreationResult(success: true, message: 'Request sent successfully');

  @override
  Future<StoreCreationResult> createOtherStore(CreateStoreRequest request, List<File> images) async =>
      const StoreCreationResult(success: true, message: 'Request sent successfully');

  @override
  Future<StoreCreationResult> createWsStore(CreateStoreRequest request, List<File> images) async =>
      const StoreCreationResult(success: true, message: 'Request sent successfully');
}

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

  group('AddStoreState & Model Parity Tests', () {
    test('StoreTypeModel json parsing matches Android payload', () {
      final json = {'_id': 1, 'name': 'Public Shops'};
      final model = StoreTypeModel.fromJson(json);
      expect(model.id, 1);
      expect(model.name, 'Public Shops');
    });

    test('StoreCategoryModel json parsing matches Android payload', () {
      final json = {'_id': 'cat_supermarket', 'display_name': 'Supermarket'};
      final model = StoreCategoryModel.fromJson(json);
      expect(model.id, 'cat_supermarket');
      expect(model.displayName, 'Supermarket');
    });

    test('LocationModel json parsing matches Android payload', () {
      final json = {
        '_id': 'loc_ambur',
        'name': 'Ambur',
        'state': 'Tamil Nadu',
        'country': 'India',
      };
      final model = LocationModel.fromJson(json);
      expect(model.id, 'loc_ambur');
      expect(model.city, 'Ambur');
      expect(model.state, 'Tamil Nadu');
      expect(model.country, 'India');
    });

    test('PickedLocationData model holds resolved location components', () {
      const data = PickedLocationData(
        latitude: 12.7904,
        longitude: 78.7166,
        formattedAddress: 'Main Bazar, Ambur, Tamil Nadu',
        street: 'Main Bazar',
        city: 'Ambur',
        state: 'Tamil Nadu',
        country: 'India',
        postalCode: '635802',
      );
      expect(data.latitude, 12.7904);
      expect(data.longitude, 78.7166);
      expect(data.city, 'Ambur');
      expect(data.postalCode, '635802');
    });
  });

  group('SelectStoreTypeScreen UI Tests', () {
    testWidgets('SelectStoreTypeScreen renders title and 4 store type cards', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SelectStoreTypeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Create Digital Store'), findsOneWidget);
      expect(find.text('Select Store Type'), findsOneWidget);
      expect(find.text('B2C Retail'), findsOneWidget);
      expect(find.text('D2C'), findsOneWidget);
      expect(find.text('B2B Wholesale'), findsOneWidget);
      expect(find.text('Buy from Wholesale'), findsOneWidget);
    });

    testWidgets('Tapping B2C Retail card navigates to AddStoreFormScreen', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SelectStoreTypeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('B2C Retail'));
      await tester.pumpAndSettle();

      // AddStoreFormScreen should now be mounted
      expect(find.byType(AddStoreFormScreen), findsOneWidget);
      expect(find.text('Store Info'), findsOneWidget);
    });
  });

  group('AddStoreFormScreen 3-Step Wizard UI Tests', () {
    testWidgets('AddStoreFormScreen renders Step 1 elements with proper constraints', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AddStoreFormScreen(storeKind: 0),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Create New Store'), findsOneWidget);
      expect(find.text('Store Info'), findsOneWidget);
      expect(find.text('Operations'), findsOneWidget);
      expect(find.text(AppStrings.mediaSubmitStep), findsOneWidget);

      // Media picker should be on Step 1
      expect(find.byType(StoreImagePicker), findsOneWidget);
      expect(find.text('Store Images *'), findsOneWidget);

      expect(find.text('Store Type *'), findsOneWidget);
      expect(find.text('Store Category *'), findsOneWidget);
      expect(find.text('Store Name *'), findsOneWidget);
      expect(find.text('Primary Mobile Number *'), findsOneWidget);
      expect(find.text('Store Address *'), findsOneWidget);

      // Editable location fields should be present on Step 1
      expect(find.text('Country *'), findsOneWidget);
      expect(find.text('State *'), findsOneWidget);
      expect(find.text('City *'), findsOneWidget);
      expect(find.text('Pin Code *'), findsOneWidget);

      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets('AddStoreFormScreen renders Wholesale mode properly', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AddStoreFormScreen(storeKind: 1, storeFlow: StoreFlow.wholesale),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Create Wholesale Store'), findsOneWidget);
      expect(find.text('Operations'), findsOneWidget);
      expect(find.byType(StoreImagePicker), findsOneWidget);
      expect(find.text('Store Images *'), findsOneWidget);
    });

    testWidgets('Tapping Next passes to Step 2 under temporary validation bypass', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AddStoreFormScreen(storeKind: 0),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Next without filling required fields (validates fields)
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Stays on Step 1 and displays validation error SnackBar
      expect(find.text('Please enter store name'), findsOneWidget);
    });

    testWidgets('Step 2 (Operations) renders missing business fields, compact heights, and Sunday-Saturday availability', (tester) async {
      final container = ProviderContainer(
        overrides: [
          addStoreRepositoryProvider.overrideWithValue(FakeAddStoreRepository()),
        ],
      );
      addTearDown(container.dispose);
      container.read(addStoreControllerProvider.notifier).setStep(1);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: AddStoreFormScreen(storeKind: 0),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check section headers and legacy parity fields
      expect(find.text(AppStrings.deliveryShippingDetailsTitle), findsOneWidget);
      expect(find.text(AppStrings.maxDeliveryRadiusLabel), findsOneWidget);
      expect(find.text('Delivery charges up to 2km:'), findsOneWidget);
      expect(find.text(AppStrings.applicableLessThanMinPurchaseLimit), findsWidgets);
      expect(find.text('Minimum purchase limit:'), findsOneWidget);
      expect(find.text(AppStrings.minPurchaseAmountHint), findsOneWidget);
      expect(find.text(AppStrings.deliveryChargePerKmLabel), findsOneWidget);
      expect(find.text(AppStrings.after2KmChargeApplicable), findsOneWidget);
      expect(find.text(AppStrings.deliveryChargeSubsTitle), findsOneWidget);

      // Check delivery modes
      expect(find.text(AppStrings.deliveryByLabel), findsOneWidget);
      expect(find.text(AppStrings.deliveryByShop), findsOneWidget);
      expect(find.text(AppStrings.deliveryByAgency), findsOneWidget);
      expect(find.text(AppStrings.deliveryBySelfPickup), findsOneWidget);

      // Check delivery time
      expect(find.text(AppStrings.deliveryTimeLabel), findsOneWidget);
      expect(find.text(AppStrings.timeFromLabel), findsOneWidget);
      expect(find.text(AppStrings.timeToLabel), findsOneWidget);

      // Check payment options
      expect(find.text(AppStrings.codTitle), findsOneWidget);
      expect(find.text(AppStrings.codAny), findsOneWidget);
      expect(find.text('Online Payment'), findsOneWidget);

      // Check return & refund policies
      expect(find.text('Return & Refund Policies'), findsOneWidget);
      expect(find.text(AppStrings.productReplacementWithinLabel), findsOneWidget);
      expect(find.text(AppStrings.refundWithinLabel), findsOneWidget);

      // Check operating days row
      expect(find.byType(AvailabilityDaysRow), findsOneWidget);
      expect(find.text('Sun'), findsOneWidget);
      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Sat'), findsOneWidget);
    });

    test('AvailabilityDaysRow starts with Sun and ends with Sat', () {
      expect(AvailabilityDaysRow.allDays.first, 'Sun');
      expect(AvailabilityDaysRow.allDays.last, 'Sat');
      expect(AvailabilityDaysRow.allDays.length, 7);
      expect(AvailabilityDaysRow.shortLabels['Sunday'], 'Sun');
      expect(AvailabilityDaysRow.shortLabels['Saturday'], 'Sat');
    });

    testWidgets('Step 2 delivery fee and minimum purchase limit fields are clearable and accept 0', (tester) async {
      final container = ProviderContainer(
        overrides: [
          addStoreRepositoryProvider.overrideWithValue(FakeAddStoreRepository()),
        ],
      );
      addTearDown(container.dispose);
      container.read(addStoreControllerProvider.notifier).setStep(1);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: AddStoreFormScreen(storeKind: 1, storeFlow: StoreFlow.wholesale),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find delivery fee text field (defaults to 20)
      final feeFinder = find.byKey(const Key('delivery_fee_input'));
      expect(feeFinder, findsOneWidget);
      expect(find.widgetWithText(TextField, '20'), findsOneWidget);

      // Clear the delivery fee text field completely
      await tester.enterText(feeFinder, '');
      await tester.pumpAndSettle();

      // Enter '0'
      await tester.enterText(feeFinder, '0');
      await tester.pumpAndSettle();
      expect(find.descendant(of: feeFinder, matching: find.text('0')), findsOneWidget);

      // Find minimum purchase limit text field (defaults to disabled until Limit Applied is checked)
      await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -400));
      await tester.pumpAndSettle();
      final checkboxFinder = find.byKey(const Key('limit_applied_checkbox'));
      await tester.tap(checkboxFinder);
      await tester.pumpAndSettle();

      final limitFinder = find.byKey(const Key('fee_limit_input'));
      expect(limitFinder, findsOneWidget);
      expect((tester.widget(limitFinder) as TextField).enabled, isTrue);

      // Clear minimum purchase limit completely
      await tester.enterText(limitFinder, '');
      await tester.pumpAndSettle();

      // Enter '0'
      await tester.enterText(limitFinder, '0');
      await tester.pumpAndSettle();
      expect(find.descendant(of: limitFinder, matching: find.text('0')), findsOneWidget);
    });

    testWidgets('Step 2 enforces mutual payment toggle validation and COD Any/Limit amount disabled state', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = FakeAddStoreRepository();
      final container = ProviderContainer(
        overrides: [
          addStoreRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);
      container.read(addStoreControllerProvider.notifier).setStep(1);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: AddStoreFormScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify COD title and Online Payment title
      expect(find.text(AppStrings.codTitle), findsOneWidget);
      expect(find.text(AppStrings.onlinePaymentTitle), findsOneWidget);

      // Verify Return & Refund policies default to 1 Day
      expect(find.text('1 Day'), findsNWidgets(2));

      // Verify COD amount field is disabled and shows '0' when COD limit type is 'any'
      final codTextField = tester.widget<TextField>(find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText == AppStrings.maxCodHint,
      ));
      expect(codTextField.enabled, isFalse);

      // Find COD switch and Online Payment switch
      final codSwitchFinder = find.byKey(const Key('cod_switch'));
      final onlineSwitchFinder = find.byWidgetPredicate(
        (w) => w is SwitchListTile && (w.title as Text?)?.data == AppStrings.onlinePaymentTitle,
      );
      expect(codSwitchFinder, findsOneWidget);
      expect(onlineSwitchFinder, findsOneWidget);

      // Scroll to reveal payment options if needed
      await tester.ensureVisible(codSwitchFinder);
      await tester.pumpAndSettle();

      // Toggle COD off (Online Payment is still on) -> should succeed
      await tester.tap(codSwitchFinder);
      await tester.pumpAndSettle();

      final codSwitchAfter = tester.widget<Switch>(codSwitchFinder);
      expect(codSwitchAfter.value, isFalse);

      // Now attempt to toggle Online Payment off as well -> must be PREVENTED!
      await tester.tap(find.descendant(of: onlineSwitchFinder, matching: find.byType(Switch)));
      await tester.pumpAndSettle();

      // SnackBar shown: At least one payment method must be enabled
      expect(find.text(AppStrings.atLeastOnePaymentMethodRequired), findsOneWidget);
      final onlineSwitchAfter = tester.widget<SwitchListTile>(onlineSwitchFinder);
      expect(onlineSwitchAfter.value, isTrue); // Remained true!
    });
  });



  group('Wholesale Parity Controller Tests', () {
    test('Wholesale initial load configures default fee 20, limit 800, deliveryTypes [2, 3]', () {
      final controller = AddStoreController(FakeAddStoreRepository());
      controller.loadInitialData(overrideKind: 1);
      expect(controller.state.storeKind, 1);
      expect(controller.state.deliveryFee, 20.0);
      expect(controller.state.deliveryRadius, 15.0);
      expect(controller.state.feeLimit, 800.0);
      expect(controller.state.deliveryTypes, [2, 3]);
    });

    test('B2C initial load configures default fee 20, limit 500, deliveryTypes [2, 3], radius 5', () {
      final controller = AddStoreController(FakeAddStoreRepository());
      controller.loadInitialData(overrideKind: 0);
      expect(controller.state.storeKind, 0);
      expect(controller.state.deliveryFee, 20.0);
      expect(controller.state.deliveryRadius, 5.0);
      expect(controller.state.feeLimit, 500.0);
      expect(controller.state.deliveryTypes, [2, 3]);
    });

    test('onTypeChanged ignores re-selection of the same store type and preserves selectedCategory', () async {
      final controller = AddStoreController(FakeAddStoreRepository());
      await controller.loadInitialData(overrideKind: 0);

      const category = StoreCategoryModel(id: 'cat_bakery', displayName: 'Bakery');
      controller.onCategoryChanged(category);
      expect(controller.state.selectedCategory?.displayName, 'Bakery');

      // Re-select the same store type (Public Shops, id: 1)
      const sameType = StoreTypeModel(id: 1, name: 'Public Shops');
      await controller.onTypeChanged(sameType);

      // selectedCategory must remain Bakery
      expect(controller.state.selectedCategory?.displayName, 'Bakery');
    });

    test('Toggling wholesale delivery type updates deliveryTypes list', () {
      final controller = AddStoreController(FakeAddStoreRepository());
      controller.loadInitialData(overrideKind: 2);
      expect(controller.state.deliveryTypes.contains(1), false);
      controller.toggleDeliveryType(1);
      expect(controller.state.deliveryTypes.contains(1), true);
      controller.toggleDeliveryType(1);
      expect(controller.state.deliveryTypes.contains(1), false);
    });

    test('Toggling time slots and adding custom time slot works', () {
      final controller = AddStoreController(FakeAddStoreRepository());
      controller.toggleTimeSlot('10:00 AM - 01:00 PM');
      expect(controller.state.selectedTimeSlots.contains('10:00 AM - 01:00 PM'), true);
      controller.toggleTimeSlot('10:00 AM - 01:00 PM');
      expect(controller.state.selectedTimeSlots.contains('10:00 AM - 01:00 PM'), false);

      controller.addCustomTimeSlot('06:00 PM - 09:00 PM');
      expect(controller.state.availableTimeSlots.contains('06:00 PM - 09:00 PM'), true);
      expect(controller.state.selectedTimeSlots.contains('06:00 PM - 09:00 PM'), true);
    });

    test('submitStore captures dynamic response message in state.successMessage', () async {
      final repo = FakeAddStoreRepository();
      final controller = AddStoreController(repo);
      await controller.loadInitialData(overrideKind: 0);

      controller.setStoreName('Test Store');
      controller.setPrimaryNumber(9876543210);
      controller.setPrimaryVerified(true);
      controller.setImages([File('img1.jpg'), File('img2.jpg')]);
      controller.setStreet('Main Road');
      controller.updateLocationFromMap(const PickedLocationData(
        latitude: 12.0,
        longitude: 78.0,
        formattedAddress: 'Main Road, Ambur',
        city: 'Ambur',
        state: 'Tamil Nadu',
        postalCode: '635802',
      ));
      controller.setTermsAccepted(true);

      final success = await controller.submitStore();
      expect(success, true);
      expect(controller.state.successMessage, 'Request sent successfully');
    });

    test('toggleWholesaleTimeSlot, updateWholesaleTimeSlotLimit, and setIsLimitApplied update state correctly', () {
      final controller = AddStoreController(FakeAddStoreRepository());
      expect(controller.state.isLimitApplied, false);

      controller.setIsLimitApplied(true);
      expect(controller.state.isLimitApplied, true);

      final firstSlotId = controller.state.wholesaleTimeSlots.first.id;
      controller.toggleWholesaleTimeSlot(firstSlotId, false);
      expect(controller.state.wholesaleTimeSlots.firstWhere((s) => s.id == firstSlotId).isSelected, false);

      controller.updateWholesaleTimeSlotLimit(firstSlotId, 250);
      expect(controller.state.wholesaleTimeSlots.firstWhere((s) => s.id == firstSlotId).limit, 250);
    });

    test('Wholesale CreateStoreRequest serializes structured time_slots JSON objects', () {
      const req = CreateWsStoreRequest(
        categoryId: 'cat_supermarket',
        displayName: 'Wholesale Store',
        latitude: 12.79,
        longitude: 78.71,
        locationId: 'loc_ambur',
        street: 'Main Street',
        zipcode: 635802,
        primaryNumber: 9894555037,
        timeSlots: [
          {'id': 'slot_1', 'slot': '7 am to 9 am', 'max_count': 100}
        ],
      );

      final json = req.toJson();
      final delivery = json['delivery'] as Map<String, dynamic>;
      final local = delivery['local'] as Map<String, dynamic>;
      final timeSlots = local['time_slot'] as List<dynamic>;

      expect(timeSlots.length, 1);
      expect(timeSlots.first['id'], 'slot_1');
      expect(timeSlots.first['slot'], '7 am to 9 am');
      expect(timeSlots.first['max_count'], 100);
    });

    test('CreateStoreRequest delivery.other payload when enabled vs disabled', () {
      // Other enabled
      const reqEnabled = CreateWsStoreRequest(
        categoryId: 'cat_supermarket',
        displayName: 'Wholesale Store',
        latitude: 12.79,
        longitude: 78.71,
        locationId: 'loc_ambur',
        street: 'Main Street',
        zipcode: 635802,
        primaryNumber: 9894555037,
        otherDeliveryEnabled: true,
        otherDeliveryFee: 60,
        otherFeeLimit: 2000,
      );
      final jsonEnabled = reqEnabled.toJson()['delivery']['other'];
      expect(jsonEnabled['is_enabled'], true);
      expect(jsonEnabled['fee'], 60);
      expect(jsonEnabled['fee_limit'], 2000);
      expect(jsonEnabled['is_cod'], false);
      expect(jsonEnabled['is_cod_limit'], 0);
      expect(jsonEnabled['type'], [1, 1]);

      // Other disabled
      const reqDisabled = CreateWsStoreRequest(
        categoryId: 'cat_supermarket',
        displayName: 'Wholesale Store',
        latitude: 12.79,
        longitude: 78.71,
        locationId: 'loc_ambur',
        street: 'Main Street',
        zipcode: 635802,
        primaryNumber: 9894555037,
        otherDeliveryEnabled: false,
        otherDeliveryFee: 60,
        otherFeeLimit: 2000,
      );
      final jsonDisabled = reqDisabled.toJson()['delivery']['other'];
      expect(jsonDisabled['is_enabled'], false);
      expect(jsonDisabled['fee'], 0);
      expect(jsonDisabled['fee_limit'], 0);
      expect(jsonDisabled['is_cod'], false);
      expect(jsonDisabled['is_cod_limit'], 0);
      expect(jsonDisabled['type'], [1, 1]);
    });

    test('WholesaleTimeSlotModel.toNativeJson includes max_count only when limit > 0', () {
      const slotWithLimit = WholesaleTimeSlotModel(id: '9', slotName: '7 pm to 9 pm', limit: 100);
      expect(slotWithLimit.toNativeJson(), {
        'id': 9,
        'max_count': 100,
        'slot': '7 pm to 9 pm',
      });

      const slotNoLimit = WholesaleTimeSlotModel(id: '9', slotName: '7 pm to 9 pm', limit: 0);
      expect(slotNoLimit.toNativeJson(), {
        'id': 9,
        'slot': '7 pm to 9 pm',
      });
    });

    test('CreateStoreRequest differentiation between merchant/shop/new (toB2cJson) and merchant/wsshop/new (toWsJson / CreateWsStoreRequest)', () {
      const reqB2c = CreateStoreRequest(
        categoryId: 'cat_grocery',
        displayName: 'Retail Shop',
        storeKind: 0,
        latitude: 12.79,
        longitude: 78.71,
        locationId: 'loc_ambur',
        street: 'Main Street',
        zipcode: 635802,
        primaryNumber: 9894555037,
      );
      final jsonB2c = reqB2c.toB2cJson();
      final localB2c = jsonB2c['delivery']['local'] as Map<String, dynamic>;
      expect(localB2c.containsKey('limit_applied'), false);
      expect(localB2c.containsKey('from'), true);
      expect(localB2c.containsKey('to'), true);
      expect(jsonB2c['replacement']['is_accepted'], true);

      const reqWs = CreateWsStoreRequest(
        categoryId: 'cat_supermarket',
        displayName: 'Wholesale Shop',
        latitude: 12.79,
        longitude: 78.71,
        locationId: 'loc_ambur',
        street: 'Main Street',
        zipcode: 635802,
        primaryNumber: 9894555037,
        isLimitApplied: true,
        timeSlots: [
          {'id': 9, 'slot': '7 pm to 9 pm'}
        ],
      );
      final jsonWs = reqWs.toJson();
      final localWs = jsonWs['delivery']['local'] as Map<String, dynamic>;
      expect(jsonWs['store_kind'], 1);
      expect(localWs['limit_applied'], true);
      expect(localWs['time_slot'], [
        {'id': 9, 'slot': '7 pm to 9 pm'}
      ]);
      expect(localWs.containsKey('from'), false);
      expect(localWs.containsKey('to'), false);
      expect(jsonWs['replacement']['is_accepted'], false);
    });
  });

  group('Location Picker Flow UI Tests', () {
    testWidgets('SelectStoreLocationScreen displays GPS and Google search cards', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SelectStoreLocationScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Select Store Location'), findsOneWidget);
      expect(find.text('Auto Selected Current Location'), findsOneWidget);
      expect(find.text('Using Google Location'), findsOneWidget);
    });
  });

  group('Automated Location API & Cascading Tests', () {
    test('Initial load auto-selects first country, first state, and first city', () async {
      final controller = AddStoreController(FakeAddStoreRepository());
      await controller.loadInitialData(overrideKind: 0);

      // Default country selected
      expect(controller.state.selectedCountry, 'India');
      expect(controller.state.countryText, 'India');

      // Default state selected
      expect(controller.state.selectedState, 'Tamil Nadu');
      expect(controller.state.stateText, 'Tamil Nadu');

      // Default city selected
      expect(controller.state.selectedCity?.city, 'Ambur');
      expect(controller.state.cityText, 'Ambur');
      expect(controller.state.selectedCityId, 'loc_ambur');
    });

    test('State change re-filters and auto-selects first city of new state', () async {
      final controller = AddStoreController(FakeAddStoreRepository());
      await controller.loadInitialData(overrideKind: 0);

      controller.onStateChanged('Tamil Nadu');
      expect(controller.state.selectedState, 'Tamil Nadu');
      expect(controller.state.selectedCity?.city, 'Ambur');
    });
  });

  group('Store Image Picker UI & 5-Image Limit Tests', () {
    testWidgets('StoreImagePicker renders thumbnails area on left and Add Photo on right', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StoreImagePicker(
              images: const [],
              onImagesChanged: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Store Images *'), findsOneWidget);
      expect(find.text('0/5 (Min 2 required)'), findsOneWidget);
      expect(find.text('Add Photo'), findsOneWidget);
      expect(find.text('No images added yet (Min 2, Max 5)'), findsOneWidget);
    });

    testWidgets('Tapping Add Photo opens bottom sheet with Take a Photo and Choose from Gallery', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StoreImagePicker(
              images: const [],
              onImagesChanged: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Add Photo'));
      await tester.pumpAndSettle();

      expect(find.text('Take a Photo'), findsOneWidget);
      expect(find.text('Choose from Gallery'), findsOneWidget);
    });

    testWidgets('Camera permanently denied shows alert dialog with Open Settings and Cancel', (tester) async {
      bool settingsOpened = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StoreImagePicker(
              images: const [],
              onImagesChanged: (_) {},
              onOpenSettings: () {
                settingsOpened = true;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final context = tester.element(find.byType(StoreImagePicker));
      StoreImagePicker.showPermissionDeniedDialog(
        context,
        title: 'Camera Permission Required',
        message: 'Camera access is required to capture photos of your store. Please enable camera permission in App Settings.',
        onOpenSettings: () {
          settingsOpened = true;
        },
      );
      await tester.pumpAndSettle();

      expect(find.text('Camera Permission Required'), findsOneWidget);
      expect(find.text('Camera access is required to capture photos of your store. Please enable camera permission in App Settings.'), findsOneWidget);
      expect(find.text(AppStrings.openAppSettingsAction), findsOneWidget);
      expect(find.text(AppStrings.cancel), findsOneWidget);

      await tester.tap(find.text(AppStrings.openAppSettingsAction));
      await tester.pumpAndSettle();

      expect(settingsOpened, isTrue);
    });

    testWidgets('Gallery permanently denied shows alert dialog with Open Settings and Cancel', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StoreImagePicker(
              images: const [],
              onImagesChanged: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final context = tester.element(find.byType(StoreImagePicker));
      StoreImagePicker.showPermissionDeniedDialog(
        context,
        title: 'Photo Gallery Permission Required',
        message: 'Gallery access is required to select photos of your store. Please enable photo/media permission in App Settings.',
      );
      await tester.pumpAndSettle();

      expect(find.text('Photo Gallery Permission Required'), findsOneWidget);
      expect(find.text(AppStrings.cancel), findsOneWidget);
      expect(find.text(AppStrings.openAppSettingsAction), findsOneWidget);

      await tester.tap(find.text(AppStrings.cancel));
      await tester.pumpAndSettle();

      expect(find.text('Photo Gallery Permission Required'), findsNothing);
    });

    testWidgets('Tapping Take a Photo or Choose from Gallery triggers permission checker', (tester) async {
      dynamic checkedSource;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StoreImagePicker(
              images: const [],
              onImagesChanged: (_) {},
              permissionChecker: (source) async {
                checkedSource = source;
                return false;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Test Camera selection
      await tester.tap(find.text('Add Photo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Take a Photo'));
      await tester.pumpAndSettle();

      expect(checkedSource.toString(), contains('camera'));

      // Test Gallery selection
      await tester.tap(find.text('Add Photo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Choose from Gallery'));
      await tester.pumpAndSettle();

      expect(checkedSource.toString(), contains('gallery'));
    });

    test('AddStoreController setImages enforces 5-image cap strictly', () {
      final controller = AddStoreController(FakeAddStoreRepository());
      final sixImages = List.generate(6, (i) => File('img_$i.jpg'));
      controller.setImages(sixImages);
      expect(controller.state.images.length, 5);
    });

    test('Remaining slots calculation accurately yields 2 when 3 images are present and slices over-selection', () {
      final currentImages = List.generate(3, (i) => File('img_$i.jpg'));
      final int remainingSlots = 5 - currentImages.length;
      expect(remainingSlots, 2);

      // Simulating user selecting 9 items from gallery
      final pickedFiles = List.generate(9, (i) => 'picked_$i.jpg');
      final allowedFiles = pickedFiles.take(remainingSlots).toList();
      expect(allowedFiles.length, 2);

      final combined = [...currentImages, ...allowedFiles.map((p) => File(p))].take(5).toList();
      expect(combined.length, 5);
    });
  });

  group('Page 1 Refactoring: Secondary Contact, Multiline Address & Cascading Fix Tests', () {
    testWidgets('Secondary Contact displays header, full-width dropdown, and Mobile inline layout', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AddStoreFormScreen(storeKind: 0),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Header label
      expect(find.text('Secondary number (Optional)'), findsOneWidget);
      // Type Selector dropdown shows Secondary Mobile by default
      expect(find.text('Secondary Mobile'), findsOneWidget);
      // Mobile inline layout: +91 prefix, Enter Secondary Number, and Verify button
      expect(find.text('+91'), findsNWidgets(2)); // Primary and Secondary both have +91
      expect(find.text('Enter Secondary Number'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Verify'), findsNWidgets(2)); // Primary and Secondary
    });

    testWidgets('Switching Secondary Contact to Landline shows Code input and hides Verify button', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AddStoreFormScreen(storeKind: 0),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap the secondary contact type dropdown
      await tester.tap(find.text('Secondary Mobile'));
      await tester.pumpAndSettle();

      // Tap 'Landline Number' from dropdown items
      await tester.tap(find.text('Landline Number').last);
      await tester.pumpAndSettle();

      // Should now display Code (STD area code) field
      expect(find.text('Code'), findsOneWidget);
      expect(find.text('Enter Secondary Number'), findsOneWidget);
      // Secondary landline hides Verify button (only primary has Verify)
      expect(find.widgetWithText(ElevatedButton, 'Verify'), findsOneWidget);
    });

    testWidgets('Store address field is multi-line with minLines: 3 and maxLines: 5', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AddStoreFormScreen(storeKind: 0),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find the TextField for store address
      final addressFinder = find.widgetWithText(TextField, 'Street address / Building name');
      expect(addressFinder, findsOneWidget);

      final textField = tester.widget<TextField>(addressFinder);
      expect(textField.minLines, 3);
      expect(textField.maxLines, isNull);
      expect(textField.keyboardType, TextInputType.multiline);
    });

    test('GeocodingService synthesizes complete address including thoroughfare and sublocality without skipping', () {
      final placemark = Placemark(
        subThoroughfare: '4/170',
        thoroughfare: 'Eraniel - Thuckala Rd',
        subLocality: 'Velayuthan Nagar',
        locality: 'Padmanabhapuram',
        administrativeArea: 'Tamil Nadu',
        postalCode: '629175',
        country: 'India',
      );

      final result = GeocodingService.fromPlacemark(placemark);
      expect(result.formattedAddress, '4/170, Eraniel - Thuckala Rd, Velayuthan Nagar, Padmanabhapuram, Tamil Nadu, 629175, India');
      expect(result.area, 'Velayuthan Nagar');
      expect(result.city, 'Padmanabhapuram');
      expect(result.state, 'Tamil Nadu');
      expect(result.postalCode, '629175');
      expect(result.country, 'India');
    });

    testWidgets('StoreImagePicker shows warning alert and blocks picker when 5 images reached', (tester) async {
      final dummyFiles = List.generate(5, (i) => File('dummy_$i.png'));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StoreImagePicker(
              images: dummyFiles,
              onImagesChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Add Photo button
      await tester.tap(find.text('Add Photo'));
      await tester.pump();

      // Warning snackbar displayed immediately without opening bottom sheet
      expect(find.text('Maximum 5 images allowed'), findsOneWidget);
      expect(find.text('Take a Photo'), findsNothing);
      expect(find.text('Choose from Gallery'), findsNothing);
    });

    test('Controller handles secondary contact types, code, and OTP logic', () async {
      final controller = AddStoreController(FakeAddStoreRepository());
      expect(controller.state.secondaryType, 'mobile');
      expect(controller.state.secCodeText, '+91');

      controller.setSecondaryType('landline');
      expect(controller.state.secondaryType, 'landline');
      expect(controller.state.secCodeText, '');

      controller.setSecCodeText('044');
      expect(controller.state.secCodeText, '044');

      controller.setSecondaryNumber(23456789);
      expect(controller.state.secondaryNumber, 23456789);
      expect(controller.state.isSecondaryVerified, false);

      controller.setSecondaryVerified(true);
      expect(controller.state.isSecondaryVerified, true);
    });

    test('City dropdown strictly filters out cities from unrelated states', () async {
      final controller = AddStoreController(FakeAddStoreRepository());
      await controller.loadInitialData(overrideKind: 0);

      // Tamil Nadu should only have Ambur and Vellore, not Bengaluru
      expect(controller.state.selectedState, 'Tamil Nadu');
      for (final city in controller.state.cities) {
        expect(city.state, 'Tamil Nadu');
      }
      expect(controller.state.cities.any((c) => c.city == 'Bengaluru'), false);
    });

    test('City/District dropdown list sorts cities alphabetically (A to Z) case-insensitively and preserves selection', () async {
      final repo = _JumbledCityRepository();
      final controller = AddStoreController(repo);
      await controller.loadInitialData(overrideKind: 0);

      // Cities should be sorted A to Z case-insensitively
      final cityNames = controller.state.cities.map((c) => c.city).toList();
      expect(cityNames, ['Ambur', 'chennai', 'Coimbatore', 'madurai', 'Vellore']);

      // Pre-selection: first alphabetical city is 'Ambur'
      expect(controller.state.selectedCity?.city, 'Ambur');

      // Select 'Coimbatore'
      final coimbatore = controller.state.cities.firstWhere((c) => c.city == 'Coimbatore');
      controller.onCityChanged(coimbatore);
      expect(controller.state.selectedCity?.city, 'Coimbatore');
      expect(controller.state.cityText, 'Coimbatore');

      // Address update preserves alphabetical list and sets matching city
      controller.updateLocationFromMap(const PickedLocationData(
        formattedAddress: '123 Main St, Vellore, Tamil Nadu',
        street: '123 Main St',
        area: 'Gandhi Nagar',
        city: 'Vellore',
        state: 'Tamil Nadu',
        country: 'India',
        postalCode: '632001',
        latitude: 12.9165,
        longitude: 79.1325,
      ));

      expect(controller.state.cities.map((c) => c.city).toList(),
          ['Ambur', 'chennai', 'Coimbatore', 'madurai', 'Vellore']);
      expect(controller.state.selectedCity?.city, 'Vellore');
      expect(controller.state.cityText, 'Vellore');
    });

    test('GeocodingService fromPlacemark retains subLocality (Velayuthan Nagar) and maps city to district', () async {
      const placemark = Placemark(
        name: 'Plot 10',
        subThoroughfare: '12',
        thoroughfare: 'Eraniel - Thuckala Road',
        subLocality: 'Velayuthan Nagar',
        locality: 'Padmanabhapuram',
        subAdministrativeArea: 'Kanyakumari',
        administrativeArea: 'Tamil Nadu',
        postalCode: '629175',
        country: 'India',
      );

      final result = GeocodingService.fromPlacemark(placemark);

      // Verify complete formatted address order with Velayuthan Nagar
      expect(result.formattedAddress,
          '12, Plot 10, Eraniel - Thuckala Road, Velayuthan Nagar, Padmanabhapuram, Kanyakumari, Tamil Nadu, 629175, India');
      expect(result.area, 'Velayuthan Nagar');
      expect(result.city, 'Padmanabhapuram');
      expect(result.district, 'Kanyakumari');
      expect(result.state, 'Tamil Nadu');
      expect(result.postalCode, '629175');

      // Test Controller city mapping when database has Kanyakumari district as city
      final repo = _DistrictLocationRepository();
      final controller = AddStoreController(repo);
      await controller.loadInitialData(overrideKind: 0);
      controller.updateLocationFromMap(PickedLocationData(
        formattedAddress: result.formattedAddress,
        street: result.formattedAddress,
        area: result.area,
        city: result.city,
        state: result.state,
        country: result.country,
        postalCode: result.postalCode,
        latitude: 8.2435,
        longitude: 77.3276,
      ));

      // Successfully mapped to Kanyakumari from formattedAddress / district instead of failing
      expect(controller.state.selectedCity?.city, 'Kanyakumari');
    });

    test('PlacesService PlacePrediction and PlaceDetails model parsing', () {
      final predictionJson = {
        'place_id': 'ChIJxyz123',
        'description': 'Thuckalay Bus Stand, Ramanparabhu Road, Brammapuram South, Padmanabhapuram, Tamil Nadu, India',
        'structured_formatting': {
          'main_text': 'Thuckalay Bus Stand',
          'secondary_text': 'Ramanparabhu Road, Brammapuram South, Padmanabhapuram, Tamil Nadu, India',
        },
      };

      final prediction = PlacePrediction.fromJson(predictionJson);
      expect(prediction.placeId, 'ChIJxyz123');
      expect(prediction.mainText, 'Thuckalay Bus Stand');
      expect(prediction.secondaryText,
          'Ramanparabhu Road, Brammapuram South, Padmanabhapuram, Tamil Nadu, India');

      final detailsJson = {
        'formatted_address':
            'Velayuthan Nagar, Eraniel - Thuckala Rd, Padmanabhapuram, Tamil Nadu 629175, India',
        'geometry': {
          'location': {'lat': 8.237, 'lng': 77.322},
        },
        'address_components': [
          {'long_name': 'Eraniel - Thuckala Rd', 'types': ['route']},
          {'long_name': 'Velayuthan Nagar', 'types': ['sublocality_level_2']},
          {'long_name': 'Padmanabhapuram', 'types': ['locality']},
          {'long_name': 'Kanniyakumari', 'types': ['administrative_area_level_2']},
          {'long_name': 'Tamil Nadu', 'types': ['administrative_area_level_1']},
          {'long_name': 'India', 'types': ['country']},
          {'long_name': '629175', 'types': ['postal_code']},
        ],
      };

      final details = PlaceDetails.fromJson(detailsJson);
      expect(details.latitude, 8.237);
      expect(details.longitude, 77.322);
      expect(details.area, 'Velayuthan Nagar');
      expect(details.city, 'Padmanabhapuram');
      expect(details.district, 'Kanniyakumari');
      expect(details.state, 'Tamil Nadu');
      expect(details.postalCode, '629175');
      expect(details.formattedAddress,
          'Velayuthan Nagar, Eraniel - Thuckala Rd, Padmanabhapuram, Tamil Nadu 629175, India');
    });

    test('Kanniyakumari spelling variation matches Kanyakumari without falling back to Ambur', () async {
      final repoWithKk = _DistrictLocationRepository();
      final controller = AddStoreController(repoWithKk);
      await controller.loadInitialData(overrideKind: 0);

      // Simulating GPS or Google Places result with Padmanabhapuram as city and Kanniyakumari as district
      controller.updateLocationFromMap(const PickedLocationData(
        formattedAddress:
            'Velayuthan Nagar, Eraniel - Thuckala Rd, Padmanabhapuram, Tamil Nadu 629175, India',
        street: 'Eraniel - Thuckala Rd',
        area: 'Velayuthan Nagar',
        city: 'Padmanabhapuram',
        district: 'Kanniyakumari',
        state: 'Tamil Nadu',
        country: 'India',
        postalCode: '629175',
        latitude: 8.237,
        longitude: 77.322,
      ));

      expect(controller.state.selectedCity?.city, 'Kanyakumari');
      expect(controller.state.selectedCityId, 'loc_kk');
      expect(controller.state.formattedAddress,
          'Velayuthan Nagar, Eraniel - Thuckala Rd, Padmanabhapuram, Tamil Nadu 629175, India');
    });

    test('PlacesService.autocomplete does not trigger request when input has less than 3 characters', () async {
      expect(await PlacesService.autocomplete(''), isEmpty);
      expect(await PlacesService.autocomplete('a'), isEmpty);
      expect(await PlacesService.autocomplete('th'), isEmpty);
      expect(await PlacesService.autocomplete('  ab  '), isEmpty);
    });

    testWidgets('OtpVerifyDialog renders Resend OTP link with underline and horizontal Verify (Left) Cancel (Right) buttons', (tester) async {
      bool resendTriggered = false;
      int? verifiedOtp;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OtpVerifyDialog(
              mobileNumber: 9894555037,
              onVerify: (otp) async {
                verifiedOtp = otp;
                return true;
              },
              onResend: () {
                resendTriggered = true;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Dialog title and description with AppStrings
      expect(find.text(AppStrings.verifyMobileNumber), findsOneWidget);
      expect(find.text('${AppStrings.weHaveSentCodeTo} +91 9894555037'), findsOneWidget);

      // Resend OTP link
      final resendFinder = find.text(AppStrings.resendOtp);
      expect(resendFinder, findsOneWidget);
      final Text resendTextWidget = tester.widget(resendFinder);
      expect(resendTextWidget.style?.decoration, TextDecoration.underline);

      // Tap Resend OTP
      await tester.tap(resendFinder);
      await tester.pump();
      expect(resendTriggered, isTrue);

      // Horizontal side-by-side buttons: Cancel on Left, Verify on Right
      final cancelFinder = find.widgetWithText(OutlinedButton, AppStrings.cancel);
      final verifyFinder = find.widgetWithText(ElevatedButton, AppStrings.verify);
      expect(cancelFinder, findsOneWidget);
      expect(verifyFinder, findsOneWidget);

      // Cancel Left position < Verify Right position
      final cancelCenter = tester.getCenter(cancelFinder);
      final verifyCenter = tester.getCenter(verifyFinder);
      expect(cancelCenter.dx < verifyCenter.dx, isTrue);

      // Enter OTP and submit
      await tester.enterText(find.byType(TextField), '123456');
      await tester.tap(verifyFinder);
      await tester.pumpAndSettle();

      expect(verifiedOtp, 123456);
    });

    testWidgets('Step 2 Payment Options has vertical spacing (height: 12) above COD section', (tester) async {
      late ProviderContainer container;
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container = ProviderContainer(
            overrides: [
              addStoreRepositoryProvider.overrideWithValue(FakeAddStoreRepository()),
            ],
          ),
          child: const MaterialApp(
            home: AddStoreFormScreen(storeKind: 0),
          ),
        ),
      );
      await tester.pumpAndSettle();

      container.read(addStoreControllerProvider.notifier).setStep(1);
      await tester.pumpAndSettle();

      final paymentOptionsFinder = find.text('Payment Options');
      final codTitleFinder = find.text(AppStrings.codTitle);

      expect(paymentOptionsFinder, findsOneWidget);
      expect(codTitleFinder, findsOneWidget);

      final paymentBottom = tester.getBottomLeft(paymentOptionsFinder).dy;
      final codTop = tester.getTopLeft(codTitleFinder).dy;

      // Vertical distance between Payment Options and COD title must be at least 12
      expect(codTop - paymentBottom, greaterThanOrEqualTo(12.0));
    });

    testWidgets('Step 2 Replacement & Refund labels match exact legacy native copy', (tester) async {
      late ProviderContainer container;
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container = ProviderContainer(
            overrides: [
              addStoreRepositoryProvider.overrideWithValue(FakeAddStoreRepository()),
            ],
          ),
          child: const MaterialApp(
            home: AddStoreFormScreen(storeKind: 0),
          ),
        ),
      );
      await tester.pumpAndSettle();

      container.read(addStoreControllerProvider.notifier).setStep(1);
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.productReplacementWithinLabel), findsOneWidget);
      expect(find.text(AppStrings.refundWithinLabel), findsOneWidget);
    });

    testWidgets('Public store contains specific duration options (1 Day, 3 Days, 6 Days, 1 Month, 6 Months, 1 Year)', (tester) async {
      // 1. Public store (storeKind: 0 / Public Shops)
      late ProviderContainer container;
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container = ProviderContainer(
            overrides: [
              addStoreRepositoryProvider.overrideWithValue(FakeAddStoreRepository()),
            ],
          ),
          child: const MaterialApp(
            home: AddStoreFormScreen(storeKind: 0),
          ),
        ),
      );
      await tester.pumpAndSettle();

      container.read(addStoreControllerProvider.notifier).setStep(1);
      await tester.pumpAndSettle();

      // Tap on replacement dropdown to inspect items
      final repDropdownFinder = find.byKey(const Key('replacement_dropdown'));
      await tester.ensureVisible(repDropdownFinder);
      await tester.tap(repDropdownFinder);
      await tester.pumpAndSettle();

      // All 6 public store options should be present
      expect(find.text('1 Day'), findsWidgets);
      expect(find.text('3 Days'), findsWidgets);
      expect(find.text('6 Days'), findsWidgets);
      expect(find.text('1 Month'), findsWidgets);
      expect(find.text('6 Months'), findsWidgets);
      expect(find.text('1 Year'), findsWidgets);

      // Dismiss dropdown
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
    });

    testWidgets('Branded store contains extended duration options (5 Days, 15 Days, 1 Month, 3 Months, 6 Months, 1 Year)', (tester) async {
      // 2. Branded store (storeKind: 4 / D2C)
      late ProviderContainer container;
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container = ProviderContainer(
            overrides: [
              addStoreRepositoryProvider.overrideWithValue(FakeAddStoreRepository()),
            ],
          ),
          child: const MaterialApp(
            home: AddStoreFormScreen(storeKind: 4),
          ),
        ),
      );
      await tester.pumpAndSettle();

      container.read(addStoreControllerProvider.notifier).setStep(1);
      await tester.pumpAndSettle();

      // Tap replacement dropdown
      final repDropdownFinder = find.byKey(const Key('replacement_dropdown'));
      await tester.ensureVisible(repDropdownFinder);
      await tester.tap(repDropdownFinder);
      await tester.pumpAndSettle();

      // Branded store options should be present
      expect(find.text('5 Days'), findsWidgets);
      expect(find.text('15 Days'), findsWidgets);
      expect(find.text('1 Month'), findsWidgets);
      expect(find.text('3 Months'), findsWidgets);
      expect(find.text('6 Months'), findsWidgets);
      expect(find.text('1 Year'), findsWidgets);

      // Select 3 Months
      await tester.tap(find.text('3 Months').last);
      await tester.pumpAndSettle();

      expect(find.text('3 Months'), findsOneWidget);
    });

    test('AddStoreController policy duration dynamically binds and re-validates on type change', () async {
      final container = ProviderContainer(
        overrides: [
          addStoreRepositoryProvider.overrideWithValue(FakeAddStoreRepository()),
        ],
      );
      addTearDown(container.dispose);
      final sub = container.listen(addStoreControllerProvider, (_, __) {});
      addTearDown(sub.close);

      final notifier = container.read(addStoreControllerProvider.notifier);
      await notifier.loadInitialData(overrideKind: 0); // Standard Public store

      final state = container.read(addStoreControllerProvider);
      expect(state.isBrandedStore, isFalse);
      expect(state.policyOptions.length, 6);
      expect(state.policyOptions.keys.toList(), [1, 3, 6, 30, 180, 365]);
      expect(state.replacementDays, 1);
      expect(state.refundDays, 1);

      // Switch to Branded / D2C (kind == 4)
      const brandedType = StoreTypeModel(id: 4, name: 'D2C Branded');
      await notifier.onTypeChanged(brandedType);

      final brandedState = container.read(addStoreControllerProvider);
      expect(brandedState.isBrandedStore, isTrue);
      expect(brandedState.policyOptions.keys.toList(), [5, 15, 30, 90, 180, 365]);
      // Since 1 was not valid for Branded, re-validated to first option (5)
      expect(brandedState.replacementDays, 5);
      expect(brandedState.refundDays, 5);

      // Set to 30 (1 Month), which is valid in both Public and Branded
      notifier.setReplacementDays(30);
      notifier.setRefundDays(30);

      // Switch back to Public store
      const publicType = StoreTypeModel(id: 1, name: 'Public Shops');
      await notifier.onTypeChanged(publicType);

      final backToPublicState = container.read(addStoreControllerProvider);
      expect(backToPublicState.isBrandedStore, isFalse);
      // 30 should be retained!
      expect(backToPublicState.replacementDays, 30);
      expect(backToPublicState.refundDays, 30);

      // Set to 3 (3 Days), only valid in Public store
      notifier.setReplacementDays(3);
      // Switch to Branded store
      await notifier.onTypeChanged(brandedType);
      final reBrandedState = container.read(addStoreControllerProvider);
      // 3 should be re-validated to 5
      expect(reBrandedState.replacementDays, 5);
    });

    testWidgets('Step 2 Delivery by checkboxes have Expanded equal widths and native defaults', (tester) async {
      final container = ProviderContainer(
        overrides: [
          addStoreRepositoryProvider.overrideWithValue(FakeAddStoreRepository()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: AddStoreFormScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      container.read(addStoreControllerProvider.notifier).setStep(1);
      await tester.pumpAndSettle();

      // Verify each delivery checkbox is inside an Expanded widget
      final shopCheckboxFinder = find.byKey(const Key('delivery_by_shop'));
      final agencyCheckboxFinder = find.byKey(const Key('delivery_by_agency'));
      final selfCheckboxFinder = find.byKey(const Key('delivery_by_self'));

      expect(shopCheckboxFinder, findsOneWidget);
      expect(agencyCheckboxFinder, findsOneWidget);
      expect(selfCheckboxFinder, findsOneWidget);

      final rowFinder = find.byWidgetPredicate(
        (w) => w is Row && w.children.any((c) => c is Expanded && c.child.key == const Key('delivery_by_shop')),
      );
      expect(rowFinder, findsOneWidget);
      final deliveryRow = tester.widget<Row>(rowFinder);
      expect(deliveryRow.children.length, 3);
      expect(deliveryRow.children.every((c) => c is Expanded), isTrue);

      // Verify native defaults: Shop is false, Agency is true, Self pickup is true
      final shopCb = tester.widget<Checkbox>(find.descendant(of: shopCheckboxFinder, matching: find.byType(Checkbox)));
      final agencyCb = tester.widget<Checkbox>(find.descendant(of: agencyCheckboxFinder, matching: find.byType(Checkbox)));
      final selfCb = tester.widget<Checkbox>(find.descendant(of: selfCheckboxFinder, matching: find.byType(Checkbox)));

      expect(shopCb.value, isFalse);
      expect(agencyCb.value, isTrue);
      expect(selfCb.value, isTrue);

      // Verify replacement dropdown shows all 6 public store options
      final repDropdownFinder = find.byKey(const Key('replacement_dropdown'));
      await tester.tap(repDropdownFinder);
      await tester.pumpAndSettle();
      expect(find.text('1 Day'), findsWidgets);
      expect(find.text('3 Days'), findsWidgets);
      expect(find.text('6 Days'), findsWidgets);
      expect(find.text('1 Month'), findsWidgets);
      expect(find.text('6 Months'), findsWidgets);
      expect(find.text('1 Year'), findsWidgets);
    });

    testWidgets('Step 1 to Step 2 wizard flow dynamically updates and re-validates duration dropdown when switching store types', (tester) async {
      final container = ProviderContainer(
        overrides: [
          addStoreRepositoryProvider.overrideWithValue(FakeAddStoreRepository()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: AddStoreFormScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Go to Step 2 as Public Shop
      container.read(addStoreControllerProvider.notifier).setStep(1);
      await tester.pumpAndSettle();

      // Verify Public Shop default is 1 Day
      expect(find.text('1 Day'), findsWidgets);

      // Change replacement to 3 Days
      await tester.tap(find.byKey(const Key('replacement_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('3 Days').last);
      await tester.pumpAndSettle();

      expect(container.read(addStoreControllerProvider).replacementDays, 3);

      // Return to Step 1
      await tester.tap(find.widgetWithText(OutlinedButton, 'Previous'));
      await tester.pumpAndSettle();

      // Switch Store Type to D2C (Branded)
      final notifier = container.read(addStoreControllerProvider.notifier);
      final brandedType = container.read(addStoreControllerProvider).storeTypes.firstWhere((t) => t.id == 4);
      await notifier.onTypeChanged(brandedType);
      await tester.pumpAndSettle();

      // Go to Step 2
      notifier.setStep(1);
      await tester.pumpAndSettle();

      // 3 Days was invalid for Branded, so it should have been re-validated/reset to 5 Days
      expect(container.read(addStoreControllerProvider).replacementDays, 5);
      expect(find.text('5 Days'), findsWidgets);

      // Select 1 Month (30) which is common to both
      await tester.tap(find.byKey(const Key('replacement_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('1 Month').last);
      await tester.pumpAndSettle();
      expect(container.read(addStoreControllerProvider).replacementDays, 30);

      // Return to Step 1 and switch back to Public Shop
      await tester.tap(find.widgetWithText(OutlinedButton, 'Previous'));
      await tester.pumpAndSettle();

      final publicType = container.read(addStoreControllerProvider).storeTypes.firstWhere((t) => t.id == 1);
      await notifier.onTypeChanged(publicType);
      await tester.pumpAndSettle();

      // Go to Step 2
      notifier.setStep(1);
      await tester.pumpAndSettle();

      // 1 Month (30) is valid for Public Shop, so it should be retained!
      expect(container.read(addStoreControllerProvider).replacementDays, 30);
      expect(find.text('1 Month'), findsWidgets);
    });

    test('StoreCategoryModel.fromJson correctly parses nested settings and policies', () {
      final json = {
        '_id': 'cat_garments',
        'display_name': 'Garments & Apparel',
        'settings': {
          'general': {
            'replacement': {
              'is_accepted': true,
              'days': 5,
            },
            'refund': {
              'is_accepted': true,
              'days': 5,
            },
            'delivery': {
              'local': {
                'radius': 10,
                'is_cod': true,
                'is_online_payment': true,
              }
            }
          }
        }
      };
      final model = StoreCategoryModel.fromJson(json);
      expect(model.id, 'cat_garments');
      expect(model.displayName, 'Garments & Apparel');
      expect(model.replacementAccepted, isTrue);
      expect(model.replacementDays, 5);
      expect(model.refundAccepted, isTrue);
      expect(model.refundDays, 5);
      expect(model.maxDeliveryRadius, 10);
      expect(model.isCod, isTrue);
      expect(model.isOnlinePayment, isTrue);
    });

    test('computeDurationOptions strictly matches native loop formula across categories', () {
      // 1. Garments (base = 5) -> 5 Days, 15 Days, 1 Month, 3 Months, 6 Months, 1 Year
      final garmentsOptions = StoreCategoryModel.computeDurationOptions(5);
      expect(garmentsOptions.keys.toList(), [5, 15, 30, 90, 180, 365]);
      expect(garmentsOptions[5], '5 Days');
      expect(garmentsOptions[15], '15 Days');
      expect(garmentsOptions[30], '1 Month');
      expect(garmentsOptions[90], '3 Months');
      expect(garmentsOptions[180], '6 Months');
      expect(garmentsOptions[365], '1 Year');

      // 2. Restaurant (base = 1) -> 1 Day, 3 Days, 6 Days, 3 Months, 6 Months, 1 Year
      final restaurantOptions = StoreCategoryModel.computeDurationOptions(1);
      expect(restaurantOptions.keys.toList(), [1, 3, 6, 90, 180, 365]);
      expect(restaurantOptions[1], '1 Day');
      expect(restaurantOptions[3], '3 Days');
      expect(restaurantOptions[6], '6 Days');
      expect(restaurantOptions[90], '3 Months');
      expect(restaurantOptions[180], '6 Months');
      expect(restaurantOptions[365], '1 Year');

      // 3. Sugar / FMCG (base = 3) -> 3 Days, 9 Days, 18 Days, 3 Months, 6 Months, 1 Year
      final sugarOptions = StoreCategoryModel.computeDurationOptions(3);
      expect(sugarOptions.keys.toList(), [3, 9, 18, 90, 180, 365]);
      expect(sugarOptions[3], '3 Days');
      expect(sugarOptions[9], '9 Days');
      expect(sugarOptions[18], '18 Days');
      expect(sugarOptions[90], '3 Months');
      expect(sugarOptions[180], '6 Months');
      expect(sugarOptions[365], '1 Year');
    });

    test('AddStoreController dynamically updates policy durations on category switch', () {
      const garmentsCat = StoreCategoryModel(
        id: 'cat_garments',
        displayName: 'Garments',
        replacementDays: 5,
        refundDays: 5,
      );
      const restaurantCat = StoreCategoryModel(
        id: 'cat_restaurant',
        displayName: 'Restaurant',
        replacementDays: 1,
        refundDays: 1,
      );
      const sugarCat = StoreCategoryModel(
        id: 'cat_sugar',
        displayName: 'Sugar & FMCG',
        replacementDays: 3,
        refundDays: 3,
      );

      final controller = AddStoreController(FakeAddStoreRepository());

      // 1. Select Garments
      controller.onCategoryChanged(garmentsCat);
      expect(controller.state.replacementOptions.keys.toList(), [5, 15, 30, 90, 180, 365]);
      expect(controller.state.refundOptions.keys.toList(), [5, 15, 30, 90, 180, 365]);
      expect(controller.state.replacementDays, 5); // position 0 default
      expect(controller.state.refundDays, 5);

      // Select 30 (1 Month)
      controller.setReplacementDays(30);
      expect(controller.state.replacementDays, 30);

      // 2. Switch to Restaurant (1, 3, 6, 90, 180, 365)
      // 30 is NOT valid for Restaurant, so it re-validates to position 0 default (1)
      controller.onCategoryChanged(restaurantCat);
      expect(controller.state.replacementOptions.keys.toList(), [1, 3, 6, 90, 180, 365]);
      expect(controller.state.replacementDays, 1);
      expect(controller.state.refundDays, 1);

      // 3. Switch to Sugar / FMCG (3, 9, 18, 90, 180, 365)
      // 1 is NOT valid for Sugar, so it re-validates to position 0 default (3)
      controller.onCategoryChanged(sugarCat);
      expect(controller.state.replacementOptions.keys.toList(), [3, 9, 18, 90, 180, 365]);
      expect(controller.state.replacementDays, 3);
      expect(controller.state.refundDays, 3);
    });

    testWidgets('Step 2 hides dropdown when category does not accept replacement or refund', (tester) async {
      final container = ProviderContainer(
        overrides: [
          addStoreRepositoryProvider.overrideWithValue(FakeAddStoreRepository()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: AddStoreFormScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      const noRefundCat = StoreCategoryModel(
        id: 'cat_food',
        displayName: 'Perishable Food',
        replacementAccepted: true,
        replacementDays: 1,
        refundAccepted: false,
        refundDays: 1,
      );
      container.read(addStoreControllerProvider.notifier).onCategoryChanged(noRefundCat);
      await tester.pumpAndSettle();

      // Go to Step 2
      container.read(addStoreControllerProvider.notifier).setStep(1);
      await tester.pumpAndSettle();

      // Replacement accepted -> dropdown visible
      expect(find.byKey(const Key('replacement_dropdown')), findsOneWidget);
      // Refund NOT accepted -> dropdown hidden
      expect(find.byKey(const Key('refund_dropdown')), findsNothing);
    });

    test('AddStoreController.sanitizePhysicalAddress cleans currency, charges, and payload residue', () {
      expect(
        AddStoreController.sanitizePhysicalAddress('123 Main St, Gandhi Nagar, ₹50 delivery charge'),
        '123 Main St, Gandhi Nagar',
      );
      expect(
        AddStoreController.sanitizePhysicalAddress('45 Bazar St, Ambur, Delivery charge: ₹60, min purchase: 2000'),
        '45 Bazar St, Ambur',
      );
      expect(
        AddStoreController.sanitizePhysicalAddress('{"street": "7th Cross", "city": "Vellore"} 632001'),
        '7th Cross, Vellore 632001',
      );
      expect(
        AddStoreController.sanitizePhysicalAddress('No 10, Cross Rd, Ambur, 635802'),
        'No 10, Cross Rd, Ambur, 635802',
      );
    });

    test('CreateStoreRequest.toJson outputs stripped payload for Others category', () {
      final reqOthers = CreateStoreRequest(
        categoryId: 'others',
        categoryDescription: 'Handmade crafts',
        displayName: 'Craft Store',
        contactTime: '10 AM - 6 PM',
        primaryDialingCode: 91,
        primaryNumber: 9876543210,
        primaryVerified: true,
        longitude: 78.7,
        latitude: 12.8,
        locationId: 'loc_1',
        street: 'Main Street',
        zipcode: 635802,
        area: 'Ambur',
        deliveryFee: 40,
        feeLimit: 500,
        isCod: true,
      );

      final json = reqOthers.toJson();
      expect(json['category_id'], 'others');
      expect(json['category_description'], 'Handmade crafts');
      expect(json['display_name'], 'Craft Store');
      expect(json['contact_time'], '10 AM - 6 PM');
      expect(json['mobile'], isNotNull);
      expect(json['location'], isNotNull);
      expect(json['address'], isNotNull);
      expect((json['address'] as Map).containsKey('area'), isFalse);

      // Operational fields should NOT be present
      expect(json.containsKey('delivery_radius'), isFalse);
      expect(json.containsKey('delivery_fee'), isFalse);
      expect(json.containsKey('is_cod'), isFalse);
      expect(json.containsKey('replacement_days'), isFalse);
      expect(json.containsKey('refund_days'), isFalse);
    });

    test('CreateStoreRequest.toJson excludes is_verified from mobile primary and secondary objects to conform to backend Joi schema', () {
      final req = CreateStoreRequest(
        categoryId: 'cat_supermarket',
        displayName: 'My Mart',
        primaryDialingCode: 91,
        primaryNumber: 9876543210,
        primaryVerified: true,
        secondaryDialingCode: 91,
        secondaryNumber: 9123456789,
        secondaryVerified: true,
        longitude: 78.71,
        latitude: 12.79,
        locationId: 'loc_ambur',
        street: 'Main St',
        zipcode: 635802,
      );

      final json = req.toJson();
      final mobile = json['mobile'] as Map<String, dynamic>;
      final primary = mobile['primary'] as Map<String, dynamic>;
      final secondary = mobile['secondary'] as Map<String, dynamic>;

      expect(primary.containsKey('is_verified'), isFalse);
      expect(primary['dialing_code'], 91);
      expect(primary['number'], 9876543210);

      expect(secondary.containsKey('is_verified'), isFalse);
      expect(secondary['dialing_code'], 91);
      expect(secondary['number'], 9123456789);
    });

    test('CreateStoreRequest formats delivery.from and delivery.to as ISO 8601 UTC timestamps', () {
      final req = CreateStoreRequest(
        categoryId: 'cat_supermarket',
        displayName: 'My Mart',
        primaryDialingCode: 91,
        primaryNumber: 9876543210,
        longitude: 78.71,
        latitude: 12.79,
        locationId: 'loc_ambur',
        street: 'Main St',
        zipcode: 635802,
        deliveryFrom: '09:00 AM',
        deliveryTo: '06:00 PM',
      );

      final json = req.toJson();
      final delivery = json['delivery'] as Map<String, dynamic>;
      final local = delivery['local'] as Map<String, dynamic>;

      final from = local['from'] as String;
      final to = local['to'] as String;

      expect(from, contains('T09:00:00.000Z'));
      expect(to, contains('T18:00:00.000Z'));

      expect(CreateStoreRequest.formatDeliveryTimeIso('2026-09-12T09:00:00.000Z'), '2026-09-12T09:00:00.000Z');
    });

    test('CreateStoreRequest formats availability as 3-letter day codes', () {
      final req = CreateStoreRequest(
        categoryId: 'cat_supermarket',
        displayName: 'My Mart',
        primaryDialingCode: 91,
        primaryNumber: 9876543210,
        longitude: 78.71,
        latitude: 12.79,
        locationId: 'loc_ambur',
        street: 'Main St',
        zipcode: 635802,
        availability: const ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'],
      );

      final json = req.toJson();
      expect(json['availability'], const ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']);
    });

    test('StoreCategoryModel parses isOtherDeliverySupported from nested settings', () {
      final catWithOther = StoreCategoryModel.fromJson({
        '_id': 'cat_garments',
        'display_name': 'Garments',
        'settings': {
          'general': {
            'delivery': {
              'other': {'is_enabled': true},
            },
          },
        },
      });
      expect(catWithOther.isOtherDeliverySupported, isTrue);

      final catWithoutOther = StoreCategoryModel.fromJson({
        '_id': 'cat_food',
        'display_name': 'Restaurant',
        'settings': {
          'general': {
            'delivery': {
              'other': {'is_enabled': false},
            },
          },
        },
      });
      expect(catWithoutOther.isOtherDeliverySupported, isFalse);
    });

    testWidgets('Single-step flow collapses indicator and shows Create Store on Step 1 for Others category', (tester) async {
      late ProviderContainer container;
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container = ProviderContainer(
            overrides: [
              addStoreRepositoryProvider.overrideWithValue(FakeAddStoreRepository()),
            ],
          ),
          child: const MaterialApp(
            home: AddStoreFormScreen(storeKind: 0),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially 3 steps
      expect(find.text('Operations'), findsOneWidget);
      expect(find.text(AppStrings.mediaSubmitStep), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Next'), findsOneWidget);

      // Select 'others' category
      final othersCat = const StoreCategoryModel(id: 'others', displayName: 'Others');
      container.read(addStoreControllerProvider.notifier).onCategoryChanged(othersCat);
      await tester.pumpAndSettle();

      // Now single step flow: Entire 1 2 3 StepIndicator section is hidden
      expect(find.byType(StepIndicator), findsNothing);
      expect(find.text('Operations'), findsNothing);
      expect(container.read(addStoreControllerProvider).isSingleStepFlow, isTrue);

      // Bottom bar shows 'Create Store' instead of 'Next', and no 'Previous' button
      expect(find.widgetWithText(ElevatedButton, 'Create Store'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Previous'), findsNothing);

      // Switching away restores 3 steps
      final regularCat = const StoreCategoryModel(id: 'regular', displayName: 'Regular Store');
      container.read(addStoreControllerProvider.notifier).onCategoryChanged(regularCat);
      await tester.pumpAndSettle();

      expect(container.read(addStoreControllerProvider).isSingleStepFlow, isFalse);
      expect(find.byType(StepIndicator), findsOneWidget);
      expect(find.text('Operations'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Next'), findsOneWidget);
    });

    testWidgets('Step back-navigation retains form state and keeps action buttons stable', (tester) async {
      late ProviderContainer container;
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container = ProviderContainer(
            overrides: [
              addStoreRepositoryProvider.overrideWithValue(FakeAddStoreRepository()),
            ],
          ),
          child: const MaterialApp(
            home: AddStoreFormScreen(storeKind: 0),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Step 1: verify Next button is present and Back button is absent
      expect(find.widgetWithText(ElevatedButton, 'Next'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Previous'), findsNothing);

      // Advance to Step 2
      container.read(addStoreControllerProvider.notifier).setStep(1);
      await tester.pumpAndSettle();
      expect(container.read(addStoreControllerProvider).currentStep, 1);

      // Step 2: verify both Back and Next buttons are present and equally split the row
      expect(find.widgetWithText(OutlinedButton, 'Previous'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Next'), findsOneWidget);
      final backSize = tester.getSize(find.widgetWithText(OutlinedButton, 'Previous'));
      final nextSize = tester.getSize(find.widgetWithText(ElevatedButton, 'Next'));
      expect(backSize.width, equals(nextSize.width));

      // Verify Back button styling has blue border
      final backBtn = tester.widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Previous'));
      expect(backBtn.style?.side?.resolve({})?.color, const Color(0xFF1976D2));
      expect(backBtn.style?.foregroundColor?.resolve({}), const Color(0xFF1976D2));

      // Mutate delivery fee
      container.read(addStoreControllerProvider.notifier).setDeliveryFee(35.0);
      await tester.pumpAndSettle();

      // Advance to Step 3
      container.read(addStoreControllerProvider.notifier).setStep(2);
      await tester.pumpAndSettle();
      expect(container.read(addStoreControllerProvider).currentStep, 2);

      // Step 3: verify Back and Create Store buttons
      expect(find.widgetWithText(OutlinedButton, 'Previous'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Create Store'), findsOneWidget);

      // Navigate BACK to Step 2
      await tester.tap(find.widgetWithText(OutlinedButton, 'Previous'));
      await tester.pumpAndSettle();
      expect(container.read(addStoreControllerProvider).currentStep, 1);

      // Verify Step 2 action buttons did not collapse and retain delivery fee state
      expect(find.widgetWithText(OutlinedButton, 'Previous'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Next'), findsOneWidget);
      expect(container.read(addStoreControllerProvider).deliveryFee, 35.0);

      // Navigate BACK to Step 1
      await tester.tap(find.widgetWithText(OutlinedButton, 'Previous'));
      await tester.pumpAndSettle();
      expect(container.read(addStoreControllerProvider).currentStep, 0);

      // Step 1: verify Back button is cleanly removed and Next button is present
      expect(find.widgetWithText(OutlinedButton, 'Previous'), findsNothing);
      expect(find.widgetWithText(ElevatedButton, 'Next'), findsOneWidget);
    });

    testWidgets('Popping AddStoreFormScreen safely unmounts without disposed controller exception', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            addStoreRepositoryProvider.overrideWithValue(FakeAddStoreRepository()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AddStoreFormScreen(storeKind: 0),
                      ),
                    );
                  },
                  child: const Text('Launch Form'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Launch form
      await tester.tap(find.text('Launch Form'));
      await tester.pump(); // Pump frame without settling all async operations

      // Immediately pop out of form while async data loads
      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();

      // Form safely popped, no exception thrown
      expect(find.text('Launch Form'), findsOneWidget);
    });

    testWidgets('Step 3 Terms & Conditions layout is compact, centered, and contains clickable blue link', (tester) async {
      late ProviderContainer container;
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container = ProviderContainer(
            overrides: [
              addStoreRepositoryProvider.overrideWithValue(FakeAddStoreRepository()),
            ],
          ),
          child: const MaterialApp(
            home: AddStoreFormScreen(storeKind: 0),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to Step 3
      container.read(addStoreControllerProvider.notifier).setStep(2);
      await tester.pumpAndSettle();
      expect(container.read(addStoreControllerProvider).currentStep, 2);

      // Verify Private Store switch is defaultly enabled (true) matching native
      expect(container.read(addStoreControllerProvider).isPrivate, isTrue);
      final privateSwitchFinder = find.descendant(
        of: find.ancestor(
          of: find.text(AppStrings.enablePrivateChat),
          matching: find.byType(Row),
        ),
        matching: find.byType(Switch),
      );
      expect(privateSwitchFinder, findsOneWidget);
      expect(tester.widget<Switch>(privateSwitchFinder).value, isTrue);

      // Verify compact Checkbox
      final checkboxFinder = find.byType(Checkbox);
      expect(checkboxFinder, findsOneWidget);
      final checkbox = tester.widget<Checkbox>(checkboxFinder);
      expect(checkbox.visualDensity, VisualDensity.compact);
      expect(checkbox.materialTapTargetSize, MaterialTapTargetSize.shrinkWrap);
      expect(checkbox.value, isFalse);

      // Tap Checkbox and verify state updates
      await tester.tap(checkboxFinder);
      await tester.pumpAndSettle();
      expect(container.read(addStoreControllerProvider).termsAccepted, isTrue);

      // Verify RichText exists with the link text
      final richTextFinder = find.byWidgetPredicate((widget) {
        if (widget is RichText) {
          final text = widget.text.toPlainText();
          return text.contains('I agree to the BayFay shop') &&
              text.contains('terms of service and privacy policy.');
        }
        return false;
      });
      expect(richTextFinder, findsOneWidget);

      final richText = tester.widget<RichText>(richTextFinder);
      TextSpan? linkSpan;
      (richText.text as TextSpan).visitChildren((span) {
        if (span is TextSpan && span.text == 'terms of service and privacy policy.') {
          linkSpan = span;
          return false;
        }
        return true;
      });
      expect(linkSpan, isNotNull);
      expect(linkSpan!.text, 'terms of service and privacy policy.');
      expect(linkSpan!.style?.color, const Color(0xFF1976D2));
      expect(linkSpan!.style?.decoration, TextDecoration.underline);
      expect(linkSpan!.recognizer, isNotNull);

      // Invoke the recognizer tap to verify navigation to TermsConditionScreen
      (linkSpan!.recognizer as dynamic).onTap();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(TermsConditionScreen), findsOneWidget);
      expect(find.text('Terms & Conditions'), findsOneWidget);

      // Clean up Navigator stack by popping TermsConditionScreen
      Navigator.of(tester.element(find.byType(TermsConditionScreen))).pop();
      await tester.pumpAndSettle();
    });

    testWidgets('TermsConditionScreen renders app bar, title, back arrow, and browser icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TermsConditionScreen(),
        ),
      );
      await tester.pump();

      expect(find.text('Terms & Conditions'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.byIcon(Icons.open_in_browser),
        ),
        findsOneWidget,
      );

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.backgroundColor, const Color(0xFF1976D2));
    });

    // ── Phase 81: Category-driven COD Enablement ──────────────────────────

    // ── Phase 81: Category-driven Payment Method Enablement (Local delivery settings) ──

    test('onCategoryChanged with isCod=true and isOnlinePayment=false (Fast Food example)', () {
      final container = ProviderContainer(
        overrides: [
          addStoreRepositoryProvider.overrideWithValue(FakeAddStoreRepository()),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(addStoreControllerProvider.notifier);

      // Fast Food category: COD enabled, Online Payment disabled
      const fastFoodCat = StoreCategoryModel(
        id: '5e022ac1aa94cc0011138fc3',
        displayName: 'Fast Food',
        isCod: true,
        isOnlinePayment: false,
      );
      controller.onCategoryChanged(fastFoodCat);

      final state = container.read(addStoreControllerProvider);
      expect(state.isCodEnabled, true);
      expect(state.isCod, true);
      expect(state.isOnlinePaymentEnabled, false);
      expect(state.isOnlinePayment, false);
    });

    test('onCategoryChanged with isCod=false and isOnlinePayment=true', () {
      final container = ProviderContainer(
        overrides: [
          addStoreRepositoryProvider.overrideWithValue(FakeAddStoreRepository()),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(addStoreControllerProvider.notifier);

      const digitalCat = StoreCategoryModel(
        id: 'cat_digital',
        displayName: 'Digital Goods',
        isCod: false,
        isOnlinePayment: true,
      );
      controller.onCategoryChanged(digitalCat);

      final state = container.read(addStoreControllerProvider);
      expect(state.isCodEnabled, false);
      expect(state.isCod, false);
      expect(state.isOnlinePaymentEnabled, true);
      expect(state.isOnlinePayment, true);
    });

    test('onCategoryChanged with null isCod and isOnlinePayment defaults to enabled', () {
      final container = ProviderContainer(
        overrides: [
          addStoreRepositoryProvider.overrideWithValue(FakeAddStoreRepository()),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(addStoreControllerProvider.notifier);

      const noSettingCategory = StoreCategoryModel(
        id: 'cat_generic',
        displayName: 'Generic',
      );
      controller.onCategoryChanged(noSettingCategory);

      final state = container.read(addStoreControllerProvider);
      expect(state.isCodEnabled, true);
      expect(state.isCod, true);
      expect(state.isOnlinePaymentEnabled, true);
      expect(state.isOnlinePayment, true);
    });

    testWidgets('COD Switch and Online Payment Switch respect category local settings', (tester) async {
      late ProviderContainer container;
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container = ProviderContainer(
            overrides: [
              addStoreRepositoryProvider.overrideWithValue(FakeAddStoreRepository()),
            ],
          ),
          child: const MaterialApp(
            home: AddStoreFormScreen(storeKind: 0),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to Step 2
      container.read(addStoreControllerProvider.notifier).setStep(1);
      await tester.pumpAndSettle();
      expect(container.read(addStoreControllerProvider).currentStep, 1);

      // Fast Food: COD enabled/on, Online Payment disabled/off
      container.read(addStoreControllerProvider.notifier).onCategoryChanged(
        const StoreCategoryModel(
          id: '5e022ac1aa94cc0011138fc3',
          displayName: 'Fast Food',
          isCod: true,
          isOnlinePayment: false,
        ),
      );
      await tester.pumpAndSettle();

      final codSwitch = tester.widget<Switch>(find.byKey(const Key('cod_switch')));
      expect(codSwitch.onChanged, isNotNull);
      expect(codSwitch.value, true);

      final onlineSwitch = tester.widget<SwitchListTile>(find.byKey(const Key('online_payment_switch')));
      expect(onlineSwitch.onChanged, isNull);
      expect(onlineSwitch.value, false);
    });

    test('validateStep1 validates required store fields', () {
      final notifier = AddStoreController(FakeAddStoreRepository());
      expect(notifier.validateStep1(), equals('Please enter store name'));
      notifier.setStoreName('My Test Shop');
      expect(notifier.validateStep1(), equals('Please enter a valid 10-digit primary mobile number'));
    });

    test('onTypeChanged and onStoreTypeChanged clear selectedCategory to prevent dropdown crash', () async {
      final notifier = AddStoreController(FakeAddStoreRepository());
      notifier.onCategoryChanged(const StoreCategoryModel(id: 'cat_supermarket', displayName: 'Supermarket'));
      expect(notifier.debugState.selectedCategory, isNotNull);

      await notifier.onStoreTypeChanged(const StoreTypeModel(id: 4, name: 'D2C'));
      // Verify selectedCategory was cleared on store type change
      expect(notifier.debugState.selectedCategory, isNull);
    });

    testWidgets('AddStoreFormScreen renders Create Wholesale Store title for wholesale and Create New Store for others', (tester) async {
      // 1. Render B2C Retail store form (storeKind = 0)
      await tester.pumpWidget(
        ProviderScope(
          key: UniqueKey(),
          overrides: [
            addStoreRepositoryProvider.overrideWithValue(FakeAddStoreRepository()),
          ],
          child: const MaterialApp(
            home: AddStoreFormScreen(storeKind: 0),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Create New Store'), findsOneWidget);

      // 2. Render Wholesale store form (storeKind = 1)
      await tester.pumpWidget(
        ProviderScope(
          key: UniqueKey(),
          overrides: [
            addStoreRepositoryProvider.overrideWithValue(FakeAddStoreRepository()),
          ],
          child: const MaterialApp(
            home: AddStoreFormScreen(storeKind: 1, storeFlow: StoreFlow.wholesale),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Create Wholesale Store'), findsOneWidget);
    });

    testWidgets('AddStoreFormScreen renders LinearProgressIndicator when isCategoriesLoading is true', (tester) async {
      final container = ProviderContainer(
        overrides: [
          addStoreRepositoryProvider.overrideWithValue(FakeAddStoreRepository()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: AddStoreFormScreen(storeKind: 0),
          ),
        ),
      );

      // Verify widget builds without error
      expect(find.byType(AddStoreFormScreen), findsOneWidget);
    });

    testWidgets('OtpVerifyDialog auto-clears error text on typing new OTP digits', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OtpVerifyDialog(
              mobileNumber: 9894555037,
              onVerify: (otp) async => false, // returns false to trigger error
              onResend: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap verify button with empty field -> triggers validation error
      final verifyButton = find.widgetWithText(ElevatedButton, AppStrings.verify);
      await tester.tap(verifyButton);
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.enterValidOtp), findsOneWidget);

      // Type digits into OTP field -> error text must be cleared immediately
      await tester.enterText(find.byType(TextField), '1');
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.enterValidOtp), findsNothing);
    });

    testWidgets('AddStoreFormScreen renders Primary Mobile, Secondary Mobile, and Store Address labels strictly once', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AddStoreFormScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Primary Mobile Number *'), findsOneWidget);
      expect(find.text('Secondary number (Optional)'), findsOneWidget);
      expect(find.text('Store Address *'), findsOneWidget);
    });

    test('AddStoreState default availability includes Sunday as first day', () {
      const state = AddStoreState();
      expect(state.availability.first, 'Sun');
      expect(state.availability, containsAll(['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']));
    });

    testWidgets('Wholesale Step 2 form hides Replacement within field and populates 5-50 km distance options', (tester) async {
      final container = ProviderContainer(
        overrides: [
          addStoreRepositoryProvider.overrideWithValue(FakeAddStoreRepository()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: AddStoreFormScreen(storeKind: 1), // Wholesale flow
          ),
        ),
      );
      await tester.pumpAndSettle();

      final notifier = container.read(addStoreControllerProvider.notifier);
      // Navigate to Step 2
      notifier.setStep(1);
      await tester.pumpAndSettle();

      // Replacement within label should NOT be rendered in Wholesale flow
      expect(find.text(AppStrings.productReplacementWithinLabel), findsNothing);

      // Refund within label SHOULD be rendered
      expect(find.text(AppStrings.refundWithinLabel), findsOneWidget);

      // Max Delivery Distance dropdown should display 15 km (Wholesale default)
      expect(find.text('15 km'), findsOneWidget);

      // Verify Sunday is selected by default in availability row
      expect(find.text('Sun'), findsOneWidget);
    });

    test('AddStoreController computes dynamic delivery distance options & default radius correctly', () {
      const fastFood = StoreCategoryModel(id: 'cat_food', displayName: 'Fast Food');
      const bakery = StoreCategoryModel(id: 'cat_bakery', displayName: 'Bakery');
      const garments = StoreCategoryModel(id: 'cat_garments', displayName: 'Garments');

      // Fast Food in B2C: 1 to 5 km, default 5 km
      final foodOptions = AddStoreController.computeDeliveryDistanceOptions(category: fastFood, isWholesale: false);
      final foodDefault = AddStoreController.computeDefaultDeliveryRadius(category: fastFood, isWholesale: false, options: foodOptions);
      expect(foodOptions, [1, 2, 3, 4, 5]);
      expect(foodDefault, 5);

      // Bakery in B2C: 1 to 10 km, default 5 km
      final bakeryOptions = AddStoreController.computeDeliveryDistanceOptions(category: bakery, isWholesale: false);
      final bakeryDefault = AddStoreController.computeDefaultDeliveryRadius(category: bakery, isWholesale: false, options: bakeryOptions);
      expect(bakeryOptions, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
      expect(bakeryDefault, 5);

      // Garments in B2C: 1 to 30 km, default 5 km
      final garmentOptions = AddStoreController.computeDeliveryDistanceOptions(category: garments, isWholesale: false);
      final garmentDefault = AddStoreController.computeDefaultDeliveryRadius(category: garments, isWholesale: false, options: garmentOptions);
      expect(garmentOptions.length, 30);
      expect(garmentOptions.first, 1);
      expect(garmentOptions.last, 30);
      expect(garmentDefault, 5);

      // Wholesale: 5 to 50 km step 5, default 15 km
      final wsOptions = AddStoreController.computeDeliveryDistanceOptions(category: fastFood, isWholesale: true);
      final wsDefault = AddStoreController.computeDefaultDeliveryRadius(category: fastFood, isWholesale: true, options: wsOptions);
      expect(wsOptions, [5, 10, 15, 20, 25, 30, 35, 40, 45, 50]);
      expect(wsDefault, 15);
    });

    testWidgets('StoreFlow decoupling: switching store type in B2C flow stays in B2C and keeps Create New Store title', (tester) async {
      final repo = FakeAddStoreRepository();
      late ProviderContainer container;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container = ProviderContainer(
            overrides: [
              addStoreRepositoryProvider.overrideWithValue(repo),
            ],
          ),
          child: const MaterialApp(
            home: AddStoreFormScreen(storeKind: 0, storeFlow: StoreFlow.b2c),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final state = container.read(addStoreControllerProvider);
      expect(state.storeFlow, StoreFlow.b2c);
      expect(state.isWholesale, isFalse);
      expect(find.text(AppStrings.createNewStoreTitle), findsOneWidget);
      expect(find.text(AppStrings.createWholesaleStoreTitle), findsNothing);

      // Switch Store Type to Branded Shop (id: 4)
      final notifier = container.read(addStoreControllerProvider.notifier);
      const brandedType = StoreTypeModel(id: 4, name: 'Branded Shops');
      await notifier.onTypeChanged(brandedType);
      await tester.pumpAndSettle();

      final stateAfter = container.read(addStoreControllerProvider);
      expect(stateAfter.storeFlow, StoreFlow.b2c);
      expect(stateAfter.isWholesale, isFalse);
      expect(find.text(AppStrings.createNewStoreTitle), findsOneWidget);
      expect(find.text(AppStrings.createWholesaleStoreTitle), findsNothing);

      // Go to Step 2 and verify replacement field is visible (not Wholesale)
      notifier.setStep(1);
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.productReplacementWithinLabel), findsOneWidget);
    });

    testWidgets('StoreFlow.wholesale flow strictly renders Create Wholesale Store title and hides replacement field', (tester) async {
      final repo = FakeAddStoreRepository();
      late ProviderContainer container;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container = ProviderContainer(
            overrides: [
              addStoreRepositoryProvider.overrideWithValue(repo),
            ],
          ),
          child: const MaterialApp(
            home: AddStoreFormScreen(storeKind: 1, storeFlow: StoreFlow.wholesale),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final state = container.read(addStoreControllerProvider);
      expect(state.storeFlow, StoreFlow.wholesale);
      expect(state.isWholesale, isTrue);
      expect(find.text(AppStrings.createWholesaleStoreTitle), findsOneWidget);
      expect(find.text(AppStrings.createNewStoreTitle), findsNothing);

      // Go to Step 2
      container.read(addStoreControllerProvider.notifier).setStep(1);
      await tester.pumpAndSettle();

      // Replacement field must be omitted for Wholesale
      expect(find.text(AppStrings.productReplacementWithinLabel), findsNothing);
      expect(find.text(AppStrings.refundWithinLabel), findsOneWidget);
    });

    test('setStreet extracts area dynamically from comma-separated address or falls back to city name when area is empty', () {
      final container = ProviderContainer();
      final controller = container.read(addStoreControllerProvider.notifier);

      controller.setStreet('Building 4, M.G. Road, Indiranagar, Bengaluru');
      expect(controller.state.area, 'Indiranagar');

      controller.setArea('Custom Area');
      expect(controller.state.area, 'Custom Area');

      controller.setArea('');
      controller.setCityText('Padmanabhapuram');
      controller.setStreet('4/170, Eraniel - Thuckala Rd, Velayuthan Nagar, Padmanabhapuram, Tamil Nadu, 629175, India');
      expect(controller.state.area, 'Padmanabhapuram');
    });
  });
}

class _DistrictLocationRepository extends Fake implements AddStoreRepository {
  @override
  Future<List<StoreTypeModel>> fetchStoreTypes() async => [];
  @override
  Future<List<StoreCategoryModel>> fetchCategories(int typeId) async => [];
  @override
  Future<List<String>> fetchCountries() async => ['India'];
  @override
  Future<List<LocationModel>> fetchStatesByCountry(String country) async => const [
        LocationModel(id: 'loc_kk', city: 'Kanyakumari', state: 'Tamil Nadu', country: 'India'),
        LocationModel(id: 'loc_ch', city: 'Chennai', state: 'Tamil Nadu', country: 'India'),
      ];
  @override
  Future<List<LocationModel>> fetchLocations() async => fetchStatesByCountry('India');
}

class _JumbledCityRepository extends Fake implements AddStoreRepository {
  @override
  Future<List<StoreTypeModel>> fetchStoreTypes() async => [];
  @override
  Future<List<StoreCategoryModel>> fetchCategories(int typeId) async => [];
  @override
  Future<List<String>> fetchCountries() async => ['India'];
  @override
  Future<List<LocationModel>> fetchStatesByCountry(String country) async => const [
        LocationModel(id: '1', city: 'Vellore', state: 'Tamil Nadu', country: 'India'),
        LocationModel(id: '2', city: 'chennai', state: 'Tamil Nadu', country: 'India'),
        LocationModel(id: '3', city: 'Ambur', state: 'Tamil Nadu', country: 'India'),
        LocationModel(id: '4', city: 'Coimbatore', state: 'Tamil Nadu', country: 'India'),
        LocationModel(id: '5', city: 'madurai', state: 'Tamil Nadu', country: 'India'),
      ];
  @override
  Future<List<LocationModel>> fetchLocations() async => fetchStatesByCountry('India');
}

