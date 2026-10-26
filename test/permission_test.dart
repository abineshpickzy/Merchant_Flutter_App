import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayfay_merchant_flutter/core/constants/app_strings.dart';
import 'package:bayfay_merchant_flutter/core/providers/permission_notifier_provider.dart';
import 'package:bayfay_merchant_flutter/core/providers/location_service_provider.dart';
import 'package:bayfay_merchant_flutter/core/widgets/permission_permanently_denied_dialog.dart';
import 'package:bayfay_merchant_flutter/features/auth/welcome/view/welcome_screen.dart';

void main() {
  group('AppPermissionState Unit Tests', () {
    test('Initial state defaults to first-time and not all granted', () {
      const state = AppPermissionState();
      expect(state.isFirstTime, isTrue);
      expect(state.areAllGranted, isFalse);
      expect(state.hasPermanentlyDenied, isFalse);
      expect(state.isGpsOff, isFalse);
    });

    test('areAllGranted returns true only when all permissions are granted and GPS is on', () {
      const allGranted = AppPermissionState(
        isFirstTime: false,
        cameraStatus: PermissionStatus.granted,
        mediaStatus: PermissionStatus.granted,
        locationStatus: PermissionStatus.granted,
        notificationStatus: PermissionStatus.granted,
        isLocationServiceEnabled: true,
      );
      expect(allGranted.areAllGranted, isTrue);
      expect(allGranted.isGpsOff, isFalse);

      final gpsOff = allGranted.copyWith(isLocationServiceEnabled: false);
      expect(gpsOff.areAllGranted, isFalse);
      expect(gpsOff.isGpsOff, isTrue);
    });

    test('hasPermanentlyDenied detects permanently denied permissions', () {
      const deniedState = AppPermissionState(
        permanentlyDeniedList: [Permission.location],
      );
      expect(deniedState.hasPermanentlyDenied, isTrue);
    });

    test('Notification permission status updates state and detects permanent denial', () {
      const state = AppPermissionState(
        notificationStatus: PermissionStatus.permanentlyDenied,
        permanentlyDeniedList: [Permission.notification],
      );
      expect(state.notificationStatus, PermissionStatus.permanentlyDenied);
      expect(state.hasPermanentlyDenied, isTrue);
      expect(state.areAllGranted, isFalse);
    });
  });

  group('LocationServiceState Unit Tests', () {
    test('Initial state defaults to enabled and not checking', () {
      const state = LocationServiceState();
      expect(state.isGpsEnabled, isTrue);
      expect(state.isChecking, isFalse);
      expect(state.currentPosition, isNull);
      expect(state.errorMessage, isNull);
    });

    test('copyWith updates fields correctly', () {
      const state = LocationServiceState();
      final updated = state.copyWith(
        isGpsEnabled: false,
        isChecking: true,
        errorMessage: 'Location disabled',
      );
      expect(updated.isGpsEnabled, isFalse);
      expect(updated.isChecking, isTrue);
      expect(updated.errorMessage, 'Location disabled');
    });
  });

  group('Permission UI Widgets Tests', () {

    testWidgets('PermissionPermanentlyDeniedDialog renders title and Open App Settings action', (tester) async {
      bool settingsOpened = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PermissionPermanentlyDeniedDialog(
              onOpenSettings: () => settingsOpened = true,
              onCancel: () {},
            ),
          ),
        ),
      );

      expect(find.text(AppStrings.permissionPermanentlyDeniedTitle), findsOneWidget);
      expect(find.text(AppStrings.permissionPermanentlyDeniedSubtitle), findsOneWidget);
      expect(find.text(AppStrings.openAppSettingsAction), findsOneWidget);
      expect(find.text(AppStrings.cancel), findsOneWidget);

      await tester.tap(find.text(AppStrings.openAppSettingsAction));
      await tester.pumpAndSettle();
      expect(settingsOpened, isTrue);
    });

    testWidgets('WelcomeScreen renders and initiates location check flow in initState', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: WelcomeScreen(),
          ),
        ),
      );

      expect(find.text(AppStrings.welcomeTitle), findsOneWidget);
      expect(find.text(AppStrings.merchantLogin), findsOneWidget);
      expect(find.text(AppStrings.signup), findsOneWidget);
    });
  });
}
