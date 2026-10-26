import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bayfay_merchant_flutter/app/providers/auth_state_provider.dart';
import 'package:bayfay_merchant_flutter/features/auth/login/model/login_response.dart';
import 'package:bayfay_merchant_flutter/features/auth/welcome/view/welcome_screen.dart';
import 'package:bayfay_merchant_flutter/core/constants/app_strings.dart';
import 'package:bayfay_merchant_flutter/features/auth/login/view/login_screen.dart';
import 'package:bayfay_merchant_flutter/features/auth/register/view/register_screen.dart';
import 'package:bayfay_merchant_flutter/features/auth/register/view/register_verify_screen.dart';
import 'package:bayfay_merchant_flutter/features/auth/forgot_password/view/forgot_password_screen.dart';
import 'package:bayfay_merchant_flutter/features/auth/forgot_password/view/reset_password_screen.dart';
import 'package:bayfay_merchant_flutter/core/validators/app_validators.dart';
import 'package:bayfay_merchant_flutter/features/auth/forgot_password/model/forgot_password_request.dart';
import 'package:bayfay_merchant_flutter/features/auth/login/model/login_request.dart';
import 'package:bayfay_merchant_flutter/features/auth/register/model/register_request.dart';

void main() {
  group('Auth Model Serializations & Parity Tests', () {
    test('LoginRequest sends real device coordinates instead of [0, 0] and hashes password with MD5', () {
      final req = LoginRequest.fromInput(
        emailOrMobile: '9876543210',
        password: 'merchantSecretPassword',
        latitude: 13.0473748,
        longitude: 79.9288071,
        deviceToken: 'fcm_token_login_test',
      );

      final json = req.toJson();
      expect(json['mobile']['dialing_code'], 91);
      expect(json['mobile']['number'], 9876543210);
      expect(json['password'], LoginRequest.hashPassword('merchantSecretPassword'));
      expect(json['password'], isNot('merchantSecretPassword'));
      expect(json['current_location']['type'], 'Point');
      // Must send [longitude, latitude] in coordinates
      expect(json['current_location']['coordinates'], [79.9288071, 13.0473748]);
      expect(json['current_location']['coordinates'], isNot([0, 0]));
      expect(json['device_details']['token'], 'fcm_token_login_test');
    });

    test('SignUpVerifyRequest produces expected JSON', () {
      const req = SignUpVerifyRequest(
        email: 'merchant@bayfay.com',
        dialingCode: 91,
        mobileNumber: 9876543210,
      );
      final json = req.toJson();
      expect(json['email'], 'merchant@bayfay.com');
      expect(json['mobile']['dialing_code'], 91);
      expect(json['mobile']['number'], 9876543210);
    });

    test('SignUpCompleteRequest hashes password with MD5 and formats coordinates', () {
      final req = SignUpCompleteRequest(
        firstName: 'Nishanth',
        lastName: 'Merchant',
        email: 'merchant@bayfay.com',
        dialingCode: 91,
        mobileNumber: 9876543210,
        otp: 1234,
        password: 'secretPassword123',
        deviceToken: 'dummy_fcm_token',
      );
      final json = req.toJson();
      expect(json['first_name'], 'Nishanth');
      expect(json['last_name'], 'Merchant');
      expect(json['email']['id'], 'merchant@bayfay.com');
      expect(json['otp'], 1234);
      // Password must be MD5 hashed
      expect(json['password'], hashPasswordMd5('secretPassword123'));
      expect(json['password'], isNot('secretPassword123'));
      expect(json['current_location']['type'], 'Point');
      expect(json['current_location']['coordinates'], [79.9288071, 13.0473748]);
      expect(json['device_details']['token'], 'dummy_fcm_token');
    });

    test('SignUpCompleteRequest accurately captures and formats dynamic GPS coordinates [lng, lat]', () {
      final req = SignUpCompleteRequest(
        firstName: 'Nishanth',
        lastName: 'Merchant',
        email: 'merchant@bayfay.com',
        dialingCode: 91,
        mobileNumber: 9876543210,
        otp: 1234,
        password: 'secretPassword123',
        latitude: 12.971598,
        longitude: 77.594566,
        deviceToken: 'dummy_fcm_token',
      );
      final json = req.toJson();
      expect(json['current_location']['coordinates'], [77.594566, 12.971598]);
    });

    test('ForgotPasswordRequest produces expected JSON', () {
      const req = ForgotPasswordRequest(dialingCode: 91, mobileNumber: 9876543210);
      final json = req.toJson();
      expect(json['mobile']['dialing_code'], 91);
      expect(json['mobile']['number'], 9876543210);
    });

    test('ResetPasswordRequest hashes password and structures request', () {
      const req = ResetPasswordRequest(
        dialingCode: 91,
        mobileNumber: 9876543210,
        otp: 5678,
        password: 'newPassword321',
      );
      final json = req.toJson();
      expect(json['mobile']['dialing_code'], 91);
      expect(json['mobile']['number'], 9876543210);
      expect(json['otp'], 5678);
      expect(json['password'], hashPasswordMd5('newPassword321'));
    });
  });

  group('Auth Validators Tests', () {
    test('validateFirstName and validateLastName', () {
      expect(AppValidators.validateFirstName(''), isNotNull);
      expect(AppValidators.validateFirstName('Nishanth'), isNull);
      expect(AppValidators.validateLastName(''), isNotNull);
      expect(AppValidators.validateLastName('M'), isNull);
    });

    test('validateMobile and validateEmail', () {
      expect(AppValidators.validateMobile('123'), isNotNull);
      expect(AppValidators.validateMobile('9876543210'), isNull);
      expect(AppValidators.validateEmail('invalid-email'), isNotNull);
      expect(AppValidators.validateEmail('merchant@bayfay.com'), isNull);
    });
  });

  group('RegisterScreen UI Tests', () {
    testWidgets('RegisterScreen displays Merchant Signup title and mobile number box correctly', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: RegisterScreen(),
          ),
        ),
      );

      // Verify title is "Merchant Signup"
      expect(find.text(AppStrings.signup), findsOneWidget);
      expect(find.text('Merchant Signup'), findsOneWidget);
      expect(find.text('Sign Up'), findsNothing);

      // Verify Mobile Number field and prefix
      expect(find.text('+91'), findsOneWidget);
      expect(find.text('10-digit mobile number'), findsOneWidget);

      // Tap Next button to trigger validation
      await tester.tap(find.text(AppStrings.next));
      await tester.pumpAndSettle();

      // Verify error appears properly
      expect(find.text(AppStrings.firstNameRequired), findsOneWidget);
    });

    testWidgets('ForgotPasswordScreen displays Android toolbar, mobile box, and Next button', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ForgotPasswordScreen(),
          ),
        ),
      );

      // Verify title is "Forgot Password"
      expect(find.text(AppStrings.forgotPasswordTitle), findsOneWidget);

      // Verify Mobile Number field and prefix
      expect(find.text('+91'), findsOneWidget);
      expect(find.text('10-digit mobile number'), findsOneWidget);
      expect(find.text(AppStrings.next), findsOneWidget);
    });

    testWidgets('ResetPasswordScreen displays OTP, Password, Confirm Password, and Next button', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ResetPasswordScreen(mobileNumber: '9876543210'),
          ),
        ),
      );

      // Verify title is "Reset Password"
      expect(find.text(AppStrings.resetPasswordTitle), findsOneWidget);

      // Verify fields
      expect(find.text('Enter your OTP'), findsOneWidget);
      expect(find.text('Enter Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
      expect(find.text(AppStrings.next), findsOneWidget);
    });

    testWidgets('RegisterScreen validation check only on Next, no errors while typing, and auto-clears on typing', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: RegisterScreen(),
          ),
        ),
      );

      // Step 1: Initial state - type partial input before Next. Verify NO errors are shown while typing.
      await tester.enterText(find.byType(TextField).at(2), 'user@');
      await tester.enterText(find.byType(TextField).at(3), '9894');
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.firstNameRequired), findsNothing);
      expect(find.text(AppStrings.lastNameRequired), findsNothing);
      expect(find.text(AppStrings.emailRequired), findsNothing);
      expect(find.text(AppStrings.enterValidEmail), findsNothing);
      expect(find.text(AppStrings.mobileRequired), findsNothing);
      expect(find.text(AppStrings.mobileDigitsRequired), findsNothing);

      // Step 2: Tap Next button - validation check triggers ONLY upon clicking 'Next'
      await tester.tap(find.text(AppStrings.next));
      await tester.pumpAndSettle();

      // First & Last Name were empty -> required errors
      expect(find.text(AppStrings.firstNameRequired), findsOneWidget);
      expect(find.text(AppStrings.lastNameRequired), findsOneWidget);
      // Email was 'user@' -> invalid email error
      expect(find.text(AppStrings.enterValidEmail), findsOneWidget);
      // Mobile was '9894' (4 digits) -> 10 digits required error
      expect(find.text(AppStrings.mobileDigitsRequired), findsOneWidget);

      // Step 3: As soon as user types into any field, all active errors across the entire form are cleared immediately
      await tester.enterText(find.byType(TextField).at(0), 'J');
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.firstNameRequired), findsNothing);
      expect(find.text(AppStrings.lastNameRequired), findsNothing);
      expect(find.text(AppStrings.enterValidEmail), findsNothing);
      expect(find.text(AppStrings.mobileDigitsRequired), findsNothing);

      // Step 4: Fill completely valid data
      await tester.enterText(find.byType(TextField).at(0), 'John');
      await tester.enterText(find.byType(TextField).at(1), 'Doe');
      await tester.enterText(find.byType(TextField).at(2), 'john@bayfay.com');
      await tester.enterText(find.byType(TextField).at(3), '9894555037');
      await tester.pumpAndSettle();

      // Still no errors
      expect(find.text(AppStrings.firstNameRequired), findsNothing);
      expect(find.text(AppStrings.lastNameRequired), findsNothing);
      expect(find.text(AppStrings.enterValidEmail), findsNothing);
      expect(find.text(AppStrings.mobileDigitsRequired), findsNothing);
    });

    testWidgets('LoginScreen validation check only on Submit, no errors while typing, all errors cleared on typing any field, and re-validation on click', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      // Step 1: Initial state - type partial input before Login. Verify NO errors are shown while typing.
      await tester.enterText(find.byType(TextField).at(0), 'user@');
      await tester.enterText(find.byType(TextField).at(1), '123');
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.enterEmailOrMobile), findsNothing);
      expect(find.text(AppStrings.enterValidEmail), findsNothing);
      expect(find.text(AppStrings.enterPassword), findsNothing);
      expect(find.text(AppStrings.passwordMinLength), findsNothing);

      // Step 2: Clear inputs and tap Login - validation check triggers ONLY upon clicking Login
      await tester.enterText(find.byType(TextField).at(0), '');
      await tester.enterText(find.byType(TextField).at(1), '');
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.merchantLogin));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.enterEmailOrMobile), findsOneWidget);
      expect(find.text(AppStrings.enterPassword), findsOneWidget);

      // Step 3: Start typing into identifier field -> ALL active errors across the entire form clear immediately
      await tester.enterText(find.byType(TextField).at(0), 'a');
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.enterEmailOrMobile), findsNothing);
      expect(find.text(AppStrings.enterPassword), findsNothing);

      // Step 4: Tapping Login again re-validates all fields
      await tester.tap(find.text(AppStrings.merchantLogin));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.enterValidMobile), findsOneWidget);
      expect(find.text(AppStrings.enterPassword), findsOneWidget);

      // Step 5: Start typing into password field -> ALL active errors across the entire form clear immediately
      await tester.enterText(find.byType(TextField).at(1), 'password123');
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.enterValidMobile), findsNothing);
      expect(find.text(AppStrings.passwordMinLength), findsNothing);
    });

    testWidgets('RegisterVerifyScreen sequential validation on Next: validates one field at a time and auto-clears on typing', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: RegisterVerifyScreen(
              firstName: 'Test',
              lastName: 'User',
              email: 'test@example.com',
              mobileNumber: '9876543210',
            ),
          ),
        ),
      );

      // Step 1: Initial state - all fields empty -> tap Next shows ONLY Enter OTP error
      await tester.tap(find.text(AppStrings.next));
      await tester.pumpAndSettle();

      final otpField1 = tester.widget<TextField>(find.byType(TextField).at(0));
      final passField1 = tester.widget<TextField>(find.byType(TextField).at(1));
      final confirmField1 = tester.widget<TextField>(find.byType(TextField).at(2));

      expect(otpField1.decoration?.errorText, AppStrings.enterOtp);
      expect(passField1.decoration?.errorText, isNull);
      expect(confirmField1.decoration?.errorText, isNull);

      // Step 2: Typing in OTP field clears error immediately
      await tester.enterText(find.byType(TextField).at(0), '1');
      await tester.pumpAndSettle();
      final otpField2 = tester.widget<TextField>(find.byType(TextField).at(0));
      expect(otpField2.decoration?.errorText, isNull);

      // Step 3: OTP < 6 digits -> tap Next shows ONLY enterValidVerificationCode
      await tester.enterText(find.byType(TextField).at(0), '12345');
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.next));
      await tester.pumpAndSettle();

      final otpField3 = tester.widget<TextField>(find.byType(TextField).at(0));
      final passField3 = tester.widget<TextField>(find.byType(TextField).at(1));
      final confirmField3 = tester.widget<TextField>(find.byType(TextField).at(2));

      expect(otpField3.decoration?.errorText, AppStrings.enterValidVerificationCode);
      expect(passField3.decoration?.errorText, isNull);
      expect(confirmField3.decoration?.errorText, isNull);

      // Step 4: Valid 6-digit OTP -> Next proceeds to Password
      await tester.enterText(find.byType(TextField).at(0), '123456');
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.next));
      await tester.pumpAndSettle();

      final otpField4 = tester.widget<TextField>(find.byType(TextField).at(0));
      final passField4 = tester.widget<TextField>(find.byType(TextField).at(1));
      final confirmField4 = tester.widget<TextField>(find.byType(TextField).at(2));

      expect(otpField4.decoration?.errorText, isNull);
      expect(passField4.decoration?.errorText, AppStrings.enterPassword);
      expect(confirmField4.decoration?.errorText, isNull);

      // Step 5: Password < 6 chars -> shows ONLY passwordMinLength
      await tester.enterText(find.byType(TextField).at(1), 'pass');
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.next));
      await tester.pumpAndSettle();

      final passField5 = tester.widget<TextField>(find.byType(TextField).at(1));
      final confirmField5 = tester.widget<TextField>(find.byType(TextField).at(2));

      expect(passField5.decoration?.errorText, AppStrings.passwordMinLength);
      expect(confirmField5.decoration?.errorText, isNull);

      // Step 6: Valid password -> Next proceeds to Confirm Password
      await tester.enterText(find.byType(TextField).at(1), 'password123');
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.next));
      await tester.pumpAndSettle();

      final passField6 = tester.widget<TextField>(find.byType(TextField).at(1));
      final confirmField6 = tester.widget<TextField>(find.byType(TextField).at(2));

      expect(passField6.decoration?.errorText, isNull);
      expect(confirmField6.decoration?.errorText, AppStrings.confirmPasswordRequired);

      // Step 7: Confirm password mismatch -> shows ONLY passwordsDoNotMatch
      await tester.enterText(find.byType(TextField).at(2), 'mismatch123');
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.next));
      await tester.pumpAndSettle();

      final confirmField7 = tester.widget<TextField>(find.byType(TextField).at(2));
      expect(confirmField7.decoration?.errorText, AppStrings.passwordsDoNotMatch);

      // Step 8: Typing into any field clears errors immediately
      await tester.enterText(find.byType(TextField).at(0), '654321');
      await tester.pumpAndSettle();
      final confirmField8 = tester.widget<TextField>(find.byType(TextField).at(2));
      expect(confirmField8.decoration?.errorText, isNull);
    });

    testWidgets('ForgotPasswordScreen validation check only on Next, no errors while typing, and auto-clears on typing', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ForgotPasswordScreen(),
          ),
        ),
      );

      // Step 1: Initial state - partial input. Verify NO errors are shown while typing.
      await tester.enterText(find.byType(TextField), '9894');
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.mobileDigitsRequired), findsNothing);
      expect(find.text(AppStrings.mobileRequired), findsNothing);

      // Step 2: Tap Next - validation triggers ONLY upon clicking Next
      await tester.tap(find.text(AppStrings.next));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.mobileDigitsRequired), findsOneWidget);

      // Step 3: Start typing into field -> error clears immediately
      await tester.enterText(find.byType(TextField), '98945');
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.mobileDigitsRequired), findsNothing);

      // Step 4: Clear field and tap Next -> empty error
      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.next));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.mobileRequired), findsOneWidget);

      // Step 5: Start typing -> error clears
      await tester.enterText(find.byType(TextField), '9');
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.mobileRequired), findsNothing);
    });

    testWidgets('ResetPasswordScreen sequential validation on Next: validates one field at a time and auto-clears on typing', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ResetPasswordScreen(mobileNumber: '9876543210'),
          ),
        ),
      );

      // Step 1: All fields empty -> tapping Next shows ONLY Enter OTP error
      await tester.tap(find.text(AppStrings.next));
      await tester.pumpAndSettle();

      final otpField1 = tester.widget<TextField>(find.byType(TextField).at(0));
      final passField1 = tester.widget<TextField>(find.byType(TextField).at(1));
      final confirmField1 = tester.widget<TextField>(find.byType(TextField).at(2));

      expect(otpField1.decoration?.errorText, AppStrings.enterOtp);
      expect(passField1.decoration?.errorText, isNull);
      expect(confirmField1.decoration?.errorText, isNull);

      // Step 2: Typing in OTP clears error immediately
      await tester.enterText(find.byType(TextField).at(0), '1');
      await tester.pumpAndSettle();
      final otpField2 = tester.widget<TextField>(find.byType(TextField).at(0));
      expect(otpField2.decoration?.errorText, isNull);

      // Step 3: OTP < 4 digits -> tapping Next shows ONLY verification code error
      await tester.enterText(find.byType(TextField).at(0), '12');
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.next));
      await tester.pumpAndSettle();

      final otpField3 = tester.widget<TextField>(find.byType(TextField).at(0));
      final passField3 = tester.widget<TextField>(find.byType(TextField).at(1));
      final confirmField3 = tester.widget<TextField>(find.byType(TextField).at(2));

      expect(otpField3.decoration?.errorText, AppStrings.enterValidVerificationCode);
      expect(passField3.decoration?.errorText, isNull);
      expect(confirmField3.decoration?.errorText, isNull);

      // Step 4: Enter valid OTP (4 digits) -> now Next proceeds to check Password
      await tester.enterText(find.byType(TextField).at(0), '1234');
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.next));
      await tester.pumpAndSettle();

      final otpField4 = tester.widget<TextField>(find.byType(TextField).at(0));
      final passField4 = tester.widget<TextField>(find.byType(TextField).at(1));
      final confirmField4 = tester.widget<TextField>(find.byType(TextField).at(2));

      expect(otpField4.decoration?.errorText, isNull);
      expect(passField4.decoration?.errorText, AppStrings.enterPassword);
      expect(confirmField4.decoration?.errorText, isNull);

      // Step 5: Password < 6 chars -> shows ONLY password min length error
      await tester.enterText(find.byType(TextField).at(1), 'abc');
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.next));
      await tester.pumpAndSettle();

      final passField5 = tester.widget<TextField>(find.byType(TextField).at(1));
      final confirmField5 = tester.widget<TextField>(find.byType(TextField).at(2));

      expect(passField5.decoration?.errorText, AppStrings.passwordMinLength);
      expect(confirmField5.decoration?.errorText, isNull);

      // Step 6: Valid password entered -> Next proceeds to check Confirm Password
      await tester.enterText(find.byType(TextField).at(1), 'password123');
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.next));
      await tester.pumpAndSettle();

      final passField6 = tester.widget<TextField>(find.byType(TextField).at(1));
      final confirmField6 = tester.widget<TextField>(find.byType(TextField).at(2));

      expect(passField6.decoration?.errorText, isNull);
      expect(confirmField6.decoration?.errorText, AppStrings.confirmPasswordRequired);

      // Step 7: Confirm password mismatch -> shows ONLY passwords do not match error
      await tester.enterText(find.byType(TextField).at(2), 'mismatch123');
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.next));
      await tester.pumpAndSettle();

      final confirmField7 = tester.widget<TextField>(find.byType(TextField).at(2));
      expect(confirmField7.decoration?.errorText, AppStrings.passwordsDoNotMatch);

      // Step 8: Typing into OTP clears the mismatch error immediately
      await tester.enterText(find.byType(TextField).at(0), '12345');
      await tester.pumpAndSettle();

      final confirmField8 = tester.widget<TextField>(find.byType(TextField).at(2));
      expect(confirmField8.decoration?.errorText, isNull);
    });

    testWidgets('RegisterVerifyScreen does not display 0/6 character counter below SMS Verification Code', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: RegisterVerifyScreen(
              firstName: 'John',
              lastName: 'Doe',
              email: 'john@bayfay.com',
              mobileNumber: '9894555037',
            ),
          ),
        ),
      );

      // Verify that no counter text "0/6" is shown anywhere
      expect(find.text('0/6'), findsNothing);
      expect(find.textContaining('/6'), findsNothing);
    });

    test('AuthTokens parses access and refresh tokens and schemas correctly', () {
      final json = {
        'access': {
          'token': 'access_token_123',
          'schema': 'Bearer',
          'exp': 1710000000,
        },
        'refresh': {
          'token': 'refresh_token_456',
          'schema': 'Bearer',
        },
      };

      final tokens = AuthTokens.fromJson(json);
      expect(tokens.accessToken, 'access_token_123');
      expect(tokens.accessSchema, 'Bearer');
      expect(tokens.refreshToken, 'refresh_token_456');
      expect(tokens.refreshSchema, 'Bearer');
      expect(tokens.accessExp, 1710000000);
    });

    test('LoginResponse parses full auth response matching legacy Android LoginNewResponse', () {
      final json = {
        'success': true,
        'message': 'Success',
        'data': {
          'auth_token': {
            'access': {'token': 'acc_123', 'schema': 'Bearer'},
            'refresh': {'token': 'ref_456', 'schema': 'Bearer'},
          },
          'merchant_profile': {
            '_id': 'merchant_001',
            'is_merchant': true,
            'first_name': 'Nishanth',
            'last_name': 'Kumar',
            'email': {'id': 'nishanth@bayfay.com'},
            'mobile': {'dialing_code': 91, 'number': 9876543210},
            'role': ['admin'],
            'store': ['store_1'],
            'out_stores': [],
            'wsbuyer': {'display_name': 'BayFay Retail Hub'},
          },
        },
      };

      final response = LoginResponse.fromJson(json);
      expect(response.success, true);
      expect(response.tokens.accessToken, 'acc_123');
      expect(response.tokens.refreshToken, 'ref_456');
      expect(response.profile?.fullName, 'Nishanth Kumar');
      expect(response.profile?.businessName, 'BayFay Retail Hub');
    });

    testWidgets('WelcomeScreen displays dynamic merchant name and Welcome Back when authenticated', (tester) async {
      const profile = MerchantProfile(
        id: '123',
        isMerchant: true,
        firstName: 'Nishanth',
        lastName: 'Kumar',
        dialingCode: 91,
        mobileNumber: 9876543210,
        roles: ['admin'],
        stores: [],
        outStores: [],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(() => _FakeAuthenticatedNotifier(profile)),
          ],
          child: const MaterialApp(
            home: WelcomeScreen(),
          ),
        ),
      );

      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Nishanth Kumar'), findsOneWidget);
      expect(find.text('Loading\n Please Wait..'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}

class _FakeAuthenticatedNotifier extends AuthStateNotifier {
  final MerchantProfile fakeProfile;
  _FakeAuthenticatedNotifier(this.fakeProfile);

  @override
  AuthState build() {
    return AuthAuthenticated(token: 'mock_token', profile: fakeProfile);
  }

  @override
  Future<bool> refreshToken() async {
    return true;
  }
}

