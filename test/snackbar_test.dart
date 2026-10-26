import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bayfay_merchant_flutter/app/theme/app_colors.dart';
import 'package:bayfay_merchant_flutter/core/errors/exceptions.dart';
import 'package:bayfay_merchant_flutter/core/errors/failures.dart';
import 'package:bayfay_merchant_flutter/core/widgets/app_snackbar.dart';

void main() {
  group('AppSnackBar.cleanErrorMessage Tests', () {
    test('Strips ServerException prefix and (code: 500) status code', () {
      const raw = 'ServerException: Email-id is taken already (code: 500)';
      final clean = AppSnackBar.cleanErrorMessage(raw);
      expect(clean, 'Email-id is taken already');
    });

    test('Strips Exception prefix', () {
      const raw = 'Exception: Email-id is taken already';
      final clean = AppSnackBar.cleanErrorMessage(raw);
      expect(clean, 'Email-id is taken already');
    });

    test('Strips ServerException from actual ServerException instance', () {
      const exception = ServerException('Email-id is taken already', 500);
      final clean = AppSnackBar.cleanErrorMessage(exception);
      expect(clean, 'Email-id is taken already');
    });

    test('Strips NetworkException and (code: null)', () {
      const exception = NetworkException('No internet connection. Please verify your network.');
      final clean = AppSnackBar.cleanErrorMessage(exception);
      expect(clean, 'No internet connection. Please verify your network.');
    });

    test('Strips ServerFailure wrapper and code', () {
      const failure = ServerFailure('Mobile number already registered', 400);
      final clean = AppSnackBar.cleanErrorMessage(failure);
      expect(clean, 'Mobile number already registered');
    });

    test('Strips nested prefixes if present', () {
      const raw = 'Exception: ServerException: Invalid credentials (code: 401)';
      final clean = AppSnackBar.cleanErrorMessage(raw);
      expect(clean, 'Invalid credentials');
    });

    test('Strips outer quotes if returned by API', () {
      const raw = 'ServerException: "Store not found" (code: 404)';
      final clean = AppSnackBar.cleanErrorMessage(raw);
      expect(clean, 'Store not found');
    });

    test('Preserves clean, normal message strings untouched', () {
      const raw = 'Please turn on device location to login.';
      final clean = AppSnackBar.cleanErrorMessage(raw);
      expect(clean, 'Please turn on device location to login.');
    });

    test('AppException.toString() returns clean message directly', () {
      const exception = ServerException('Email-id is taken already', 500);
      expect(exception.toString(), 'Email-id is taken already');
      expect(exception.toDebugString(), 'ServerException: Email-id is taken already (code: 500)');
    });

    test('Failure.toString() returns clean message directly', () {
      const failure = ServerFailure('Email-id is taken already', 500);
      expect(failure.toString(), 'Email-id is taken already');
      expect(failure.toDebugString(), 'ServerFailure(message: Email-id is taken already, code: 500)');
    });
  });

  group('AppSnackBar UI & Styling Tests', () {
    test('createErrorSnackBar builds modern floating SnackBar with soft red styling', () {
      final snackBar = AppSnackBar.createErrorSnackBar(
        'ServerException: Email-id is taken already (code: 500)',
      );

      expect(snackBar.behavior, SnackBarBehavior.floating);
      expect(snackBar.backgroundColor, AppColors.errorSoft);
      expect(snackBar.shape, isA<RoundedRectangleBorder>());
      final shape = snackBar.shape as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(10.0));
      expect(snackBar.margin, const EdgeInsets.only(bottom: 16.0, left: 16.0, right: 16.0));
    });

    testWidgets('AppSnackBar.showError displays clean error message in floating SnackBar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    AppSnackBar.showError(
                      context,
                      'ServerException: Email-id is taken already (code: 500)',
                    );
                  },
                  child: const Text('Trigger Error'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Trigger Error'));
      await tester.pump(); // Start SnackBar animation
      await tester.pump(const Duration(milliseconds: 750)); // Finish animation

      // Should display only the clean human-readable text
      expect(find.text('Email-id is taken already'), findsOneWidget);
      expect(find.textContaining('ServerException'), findsNothing);
      expect(find.textContaining('code: 500'), findsNothing);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });
  });
}
