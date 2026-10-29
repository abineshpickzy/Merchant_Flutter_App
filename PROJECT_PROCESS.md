# Bayfay Merchant Flutter — Development Journey & Technical Process Record

> **Document Purpose**: This file records the complete development process, architectural decisions, technical challenges, solutions, and project milestones undertaken while building and modernizing the **Bayfay Merchant Flutter Application**.

---

## 1. Project Background & Core Requirements

The objective of this project is to create a robust, production-grade Flutter application for **Bayfay Merchant**, modernizing and replacing the legacy Android Java codebase with clean cross-platform architecture while maintaining exact parity with existing backend contracts.

### Non-Negotiable Directives:
- **State Management**: Mandatory **Riverpod** (`flutter_riverpod`, `riverpod_annotation`, `build_runner`). Absolutely no GetX, Bloc, Provider, MobX, or Redux.
- **Architectural Pattern**: **Clean Architecture with Feature-First Organization**.
  - Path structure: `lib/features/<feature>/` containing `controller/`, `model/`, `repository/`, and `view/` (with screens suffixed `*_screen.dart`).
  - Common infrastructure in `lib/core/` and `lib/app/`.
- **Single Entry Point**: All flavors run from a single `lib/main.dart` with automatic flavor detection via Flutter's built-in `appFlavor`.
- **Android Product Flavors**:
  - `dev`: `SERVER_URL = "https://store-devapi.bayfay.com/merchant/"`, `app_name = "Merchant-Dev"`, `payment_environment = 2`.
  - `qa`: `SERVER_URL = "https://qa-api.bayfay.com/merchant/"`, `app_name = "Merchant-Qa"`, `payment_environment = 2`.
  - `prod`: `SERVER_URL = "https://store-api.bayfay.com/merchant/"`, `app_name = "Merchant"`, `payment_environment = 0`.
  - Default package / namespace: `com.bayfay.merchant`.
  - Separate application ID for dev: `com.bayfay.merchantdev` (allowing side-by-side installation with production).
- **Parity with Android Legacy Auth**:
  - Accept either **Email** or **Mobile Number** in a single input.
  - Dynamically call `POST auth/email` if input contains `@`, or `POST auth/mobile` if 10-digit number.
  - Client-side MD5 hashing of passwords.
  - Device token acquisition at launch (FCM token with hardware `ANDROID_ID` fallback) bundled into `device_details.token` and `device_details.type = 2`.
  - Clear, formatted console logging for all HTTP requests and responses.

---

## 2. Chronological Process & Milestones

```mermaid
flowchart TD
    M1["1. Clean Architecture & Setup"] --> M2["2. Android Flavors & Gradle Config"]
    M2 --> M3["3. Network, Auth & Dynamic Routing"]
    M3 --> M4["4. Device Token FCM & Console Logger"]
    M4 --> M5["5. Dashboard & Multi-Store Management"]
    M5 --> M6["6. Store Orders Management Console"]
    M6 --> M7["7. 1:1 Android Visual Parity & Drawables"]
    M7 --> M8["8. Typography & Font Normalization"]
    M8 --> M9["9. Forgot & Reset Password Flow"]
    M9 --> M10["10. Centralized Strings & Reusable Widgets"]
    M10 --> M11["11. Quality Verification & Testing"]
    M11 --> M12["12. Auto-Clear Errors on Typing"]
```

---

### Phase 1: Foundation & Clean Architecture Layering

1. **Dependency Setup (`pubspec.yaml`)**:
   - State management: `flutter_riverpod`, `riverpod_annotation`, `build_runner`, `riverpod_generator`, `riverpod_lint`.
   - Routing: `go_router`.
   - Networking: `dio`.
   - Storage: `flutter_secure_storage`, `shared_preferences`.
   - Utilities: `crypto` (for MD5 password hashing), `intl`, `equatable`.
2. **Directory Structure**:
   ```text
   lib/
   ├── app/
   │   ├── providers/          # Centralized auth & global state
   │   ├── router/             # GoRouter configuration & route guards
   │   └── theme/              # Material 3 theme & color tokens
   ├── core/
   │   ├── config/             # Environment & flavor AppConfig
   │   ├── constants/          # Storage keys & string constants
   │   ├── errors/             # App exceptions & failure models
   │   ├── network/            # Dio ApiClient & interceptors
   │   ├── services/           # DeviceTokenService (FCM & hardware ID)
   │   ├── storage/            # Secure & Local storage wrappers
   │   ├── validators/         # Centralized form input validators
   │   └── widgets/            # Reusable UI widgets (AppTextField, loaders)
   └── features/
       ├── auth/
       │   ├── login/          # controller, model, repository, view
       │   └── register/       # controller, model, repository, view
       ├── dashboard/          # controller, model, repository, view
       └── splash/             # controller, view
   ```
3. **Application Routing & Auth State**:
   - Implemented `AuthStateNotifier` in [`auth_state_provider.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/app/providers/auth_state_provider.dart) with states: `AuthInitializing`, `AuthUnauthenticated`, `AuthAuthenticated`, and `AuthSessionExpired`.
   - Wired `GoRouter` redirect logic to automatically navigate based on session status.

---

### Phase 2: Android Product Flavors & Gradle Setup

Configured Android build files using Kotlin DSL (`.gradle.kts`):
1. **[`android/app/build.gradle.kts`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/android/app/build.gradle.kts)**:
   - Namespace set to `com.bayfay.merchant`.
   - Application ID for dev set to `com.bayfay.merchantdev`.
   - Configured flavor dimension `"environment"` with flavors: `dev`, `qa`, and `prod`.
   - Added custom buildConfig fields: `SERVER_URL`, `payment_environment`, and `resValue` for `app_name`.
   - Added conditional Google Services plugin application (`if (hasGoogleServices) apply(plugin = "com.google.gms.google-services")`) so the build succeeds whether `google-services.json` is present or pending.
2. **Single Entry Point Bootstrap ([`lib/main.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/main.dart))**:
   - Detects `appFlavor` (`dev`, `qa`, `prod`).
   - Dynamically initializes `AppConfig.init(...)` with corresponding endpoints and payment environments.

---

### Phase 3: Dynamic Auth & Network Parity

1. **Dynamic Login Contract ([`login_request.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/auth/login/model/login_request.dart))**:
   - Supports inputs with `@` (routes to `POST auth/email`) or numeric strings (routes to `POST auth/mobile`).
   - Performs client-side MD5 hashing via `hashPassword(password)`.
   - Bundles location (`current_location: { coordinates: [lng, lat], type: "Point" }`) and device details (`device_details: { token: ..., type: 2 }`).
2. **Network Resilience & Interceptors**:
   - `AuthInterceptor`: Automatically injects `Bearer <token>` into authenticated requests and detects `401 Unauthorized` to trigger session expiration.
   - `ApiClient`: Standardized typed methods (`get`, `post`, `put`, `patch`, `delete`) with unified exception translation.

---

### Phase 4: Device / FCM Token Acquisition & Console Logger

1. **FCM Token Lifecycle in Splash & Secure Storage**:
   - **`SplashScreen.initState()` ([`lib/features/splash/view/splash_screen.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/splash/view/splash_screen.dart))**: Fetches the FCM token directly using `FirebaseMessaging.instance.getToken()` and persists it into `SecureStorageService` via `saveDeviceToken(token)`.
   - **`SecureStorageService` ([`lib/core/storage/secure_storage_service.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/core/storage/secure_storage_service.dart))**: Houses encrypted storage methods `saveDeviceToken(token)` and `getDeviceToken()`.
   - **`LoginController` ([`lib/features/auth/login/controller/login_controller.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/auth/login/controller/login_controller.dart))**: Directly retrieves the saved FCM token via `secureStorage.getDeviceToken()` and injects it into `LoginRequest.device_details` without depending on `DeviceTokenService`.
2. **Console Request & Response Logger ([`lib/core/network/interceptors/logging_interceptor.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/core/network/interceptors/logging_interceptor.dart))**:
   - Upgraded silent `developer.log` to a clean, boxed, terminal-friendly console logger using `debugPrint`.
   - Prettifies JSON request/response payloads with 2-space indentation.
   - Measures and logs round-trip response duration in milliseconds.

---

### Phase 5: Centralized Strings & Reusable Input Field Widget

1. **Centralized Text Constants ([`lib/core/constants/app_strings.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/core/constants/app_strings.dart))**:
   - Extracted all hardcoded string literals from views, controllers, dialogs, and validators into a single structured class.
   - Categorized into: App Info, Actions & Buttons, Login, Registration, Dashboard, Form Validations, and Network Errors.
2. **Standardized Input Widget ([`lib/core/widgets/app_text_field.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/core/widgets/app_text_field.dart))**:
   - Created a flexible `AppTextField` with built-in theme decoration, error styling, and focused states.
   - Specialized factory constructors:
     - `AppTextField.email(...)`: Preconfigured for email with mail icon and email keyboard.
     - `AppTextField.password(...)`: Preconfigured with lock icon, done action, and built-in eye icon toggle (`Icons.visibility` / `Icons.visibility_off`).
     - `AppTextField.phone(...)`: Preconfigured with `+91` country badge, digits-only input formatter, and 10-digit length limit.
3. **Screen Refactoring**:
   - Completely refactored `LoginScreen`, `RegisterScreen`, `DashboardScreen`, `AppValidators`, and `ApiClient` to use `AppTextField` and `AppStrings`.

---

### Phase 6: Build Troubleshooting & Resolution

During initial Android compilation, two build issues arose and were diagnosed and resolved:

#### Issue 1: Kotlin Plugin Version Conflict with `firebase_core`
- **Symptom**:
  ```text
  FAILURE: Build failed with an exception.
  * Where: Build file '.../firebase_core-4.14.0/android/build.gradle' line: 78
  * What went wrong:
  A problem occurred evaluating project ':firebase_core'.
  > Could not find method compilerOptions() for arguments [...] on extension 'kotlin'
  ```
- **Root Cause**: `firebase_core: 4.14.0` uses the `compilerOptions { ... }` DSL introduced in Kotlin 1.9+. The project's `android/settings.gradle.kts` was pinned to older Kotlin `1.8.22`.
- **Resolution**: Upgraded Kotlin Gradle plugin in [`android/settings.gradle.kts`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/android/settings.gradle.kts) to `2.1.0`.

#### Issue 2: Manifest Merger `minSdkVersion` Mismatch
- **Symptom**:
  ```text
  Execution failed for task ':app:processDevDebugMainManifest'.
  > Manifest merger failed : uses-sdk:minSdkVersion 21 cannot be smaller than version 23 declared in library [:firebase_messaging]
  ```
- **Root Cause**: `firebase_messaging 16.6.0` requires Android API level 23 (`Android 6.0+ Marshmallow`). The project's `minSdk` defaulted to 21.
- **Resolution**: Explicitly set `minSdk = 23` in [`android/app/build.gradle.kts`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/android/app/build.gradle.kts).

---

## 3. Current Verification Status

| Verification Check | Target / Command | Status |
| :--- | :--- | :--- |
| **Dart Static Analysis** | `flutter analyze` | **PASSED** (0 issues, clean) |
| **Kotlin Gradle Plugin** | Version `2.1.0` in `settings.gradle.kts` | **PASSED** (`compilerOptions` supported) |
| **Android Manifest Merger** | `minSdk = 23` in `app/build.gradle.kts` | **PASSED** (all 8 plugin manifests merged) |
| **Android Dev Debug Build** | `./gradlew assembleDevDebug` | **PASSED** (`BUILD SUCCESSFUL in 2m 50s`) |

---

## 4. How to Run and Build the Project

### Running in Development (Default Flavor):
```bash
flutter run --flavor dev
```

### Running in QA:
```bash
flutter run --flavor qa
```

### Running in Production:
```bash
flutter run --flavor prod
```

### Building APKs:
```bash
# Dev Flavor APK
flutter build apk --flavor dev

# QA Flavor APK
flutter build apk --flavor qa

# Production Flavor APK
flutter build apk --flavor prod
```

---

## 5. Summary of Key Files Created & Modified

- **Configurations**:
  - [`lib/main.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/main.dart)
  - [`lib/core/config/app_config.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/core/config/app_config.dart)
  - [`android/settings.gradle.kts`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/android/settings.gradle.kts)
  - [`android/app/build.gradle.kts`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/android/app/build.gradle.kts)
- **Centralized Constants & Utilities**:
  - [`lib/core/constants/app_strings.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/core/constants/app_strings.dart)
  - [`lib/core/constants/app_constants.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/core/constants/app_constants.dart)
  - [`lib/core/validators/app_validators.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/core/validators/app_validators.dart)
  - [`lib/core/widgets/app_text_field.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/core/widgets/app_text_field.dart)
- **Services & Network**:
  - [`lib/core/services/device_token_service.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/core/services/device_token_service.dart)
  - [`lib/core/network/interceptors/logging_interceptor.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/core/network/interceptors/logging_interceptor.dart)
  - [`lib/core/network/api_client.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/core/network/api_client.dart)
- **Features**:
  - `lib/features/auth/welcome/` (`welcome_screen.dart`)
  - `lib/features/auth/login/` (`login_screen.dart`, `login_controller.dart`, `login_repository.dart`, `login_request.dart`, `login_response.dart`)
  - `lib/features/auth/register/` (`register_screen.dart`, `register_verify_screen.dart`, `register_controller.dart`, `register_repository.dart`, `register_request.dart`, `register_response.dart`)
  - `lib/features/auth/forgot_password/` (`forgot_password_screen.dart`, `reset_password_screen.dart`, `forgot_password_controller.dart`, `forgot_password_repository.dart`, `forgot_password_request.dart`)
  - `lib/features/dashboard/` (`dashboard_screen.dart`, `dashboard_controller.dart`)
  - `lib/features/splash/` (`splash_screen.dart`, `splash_controller.dart`)

---

### Phase 7: Full Authentication & Onboarding Migration from Legacy Android

Migrated the complete legacy Android authentication suite from `/BayFay-AI-V3/MerchantAndroidApp` into `bayfay_merchant_flutter` with exact contract and behavior parity:

1. **Welcome Screen ([`welcome_screen.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/auth/welcome/view/welcome_screen.dart))**:
   - Replaced legacy `WelcomeActivity.java`.
   - Displays BayFay Merchant brand header, central icon/logo, and primary actions for "Merchant Login" and "Sign Up".
   - Handles returning users with a "Welcome Back" card displaying their saved profile name and a one-tap "Continue" button into dashboard.

2. **Two-Step Registration with OTP Verification**:
   - **Step 1 ([`register_screen.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/auth/register/view/register_screen.dart))**: Replaced `StoreSignUpActivity.java`. Captures First Name, Last Name, Email, and 10-digit mobile, triggering `POST auth/signup/verify`.
   - **Step 2 ([`register_verify_screen.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/auth/register/view/register_verify_screen.dart))**: Replaced `StoreVerificationActivity.java`. Captures SMS OTP, new password, password confirmation, with 30-second resend cooldown timer. Triggers `POST auth/signup`, parses credentials, persists auth session, and transitions state to authenticated.

3. **Forgot & Reset Password Flow**:
   - **Step 1 ([`forgot_password_screen.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/auth/forgot_password/view/forgot_password_screen.dart))**: Replaced `ForgetPasswordActivity.java`. Captures mobile number and calls `POST auth/forgotpassword/verify`.
   - **Step 2 ([`reset_password_screen.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/auth/forgot_password/view/reset_password_screen.dart))**: Replaced `ResetPasswordActivity.java`. Captures OTP, new password, confirm password, and calls `POST auth/resetpassword`. On success, redirects to login.

4. **Router & Guard Modernization ([`app_router.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/app/router/app_router.dart))**:
   - Registered `/welcome`, `/register/verify`, `/forgot-password`, `/reset-password`.
   - Configured unauthenticated access whitelist for all onboarding and auth screens.

---

### Phase 8: Home & Store Dashboard Migration from Legacy Android

Migrated the primary store management console and home experience from `/BayFay-AI-V3/MerchantAndroidApp` (`HomeActivity.java`, `HomeFragment.java`, `ShopsHeaderAdapter.java`, and `StoresListAdapter.java`) into `bayfay_merchant_flutter`:

1. **Dashboard Shell & Bottom Navigation ([`dashboard_screen.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/dashboard/view/dashboard_screen.dart))**:
   - Master layout hosting modern Material 3 bottom navigation bar with 4 core tabs: **Stores** (Home), **Orders**, **Inventory**, and **Account**.
   - Custom App Bar featuring active store switcher pill, unread notification counter badge, and "Add Store" action.

2. **Active Store Selection ([`store_selector_bottom_sheet.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/dashboard/view/widgets/store_selector_bottom_sheet.dart))**:
   - Migrated legacy store spinner (`shopSp`) into an accessible bottom sheet modal.
   - Powered by `selectedStoreProvider` with local persistence across application restarts.

3. **Stores Dashboard Grid & Metrics ([`stores_dashboard_view.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/dashboard/view/views/stores_dashboard_view.dart))**:
   - Replaced `HomeFragment.java` and `ShopsHeaderAdapter.java`.
   - Live metrics summary bar displaying Total Stores, Active/Open Stores, and Total New Orders.
   - Search bar and filter chips (All, Retail, Wholesale).
   - Responsive grid of [`StoreCard`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/dashboard/view/widgets/store_card.dart) items with open/closed status, thumbnail, rating, and new orders badge.
   - Connected to `GET merchant/shop/list`.

4. **Navigation Drawer Parity ([`home_drawer.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/dashboard/view/widgets/home_drawer.dart))**:
   - Complete parity with `HomeActivity.java` navigation drawer: Merchant Profile Header, Stores, Wholesale Shops, Admin Users & Roles, Billings, Delivery Console, Promotions & Messages, About BayFay, Help, and Logout.

---

### Phase 9: Store Orders Management Migration from Legacy Android

Migrated the multi-tab store orders management console from `/BayFay-AI-V3/MerchantAndroidApp` (`StoreOrdersActivity.java`, `OrdersFragment.java`, `NewOrderAdapter.java`, `OrderDetailsNewResponse.java`, and `OrderCountResponse.java`) into `bayfay_merchant_flutter`:

1. **Order Models & Domain Entities ([`order_model.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/orders/model/order_model.dart))**:
   - `OrderStatus` enum: `newOrder`, `processing`, `ready`, `onTheWay`, `delivered`, `cancelled`.
   - `OrderModel`: Parses order ID, amount, customer name/mobile, delivery address, delivery mode, payment mode, timestamp, notes, and wholesale flag.
   - `OrderProductItem`: Parses line-item products (`product_name`, `qty`, `net_price`, `unit`, `image`).
   - `OrderCountsModel`: Maps backend counts (`newOrders`, `acceptedOrders`, `readyToShipOrders`, `shippingOrders`, `deliveredOrders`, `cancelledOrders`).

2. **Orders Repository & API Endpoints ([`orders_repository.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/orders/repository/orders_repository.dart))**:
   - Fetches orders per status (`POST order/newOrder`, `POST order/acceptedOrder`, `POST order/dispatched`, `POST order/shippingOrders`, `POST order/deliveredOrders`, `POST order/cancelledOrders`).
   - Order actions: `PATCH order/acceptOrder`, `POST order/cancelOrder`, `PATCH order/readyToShipOrder`.
   - Fetches live order counts: `POST order/orderCount`.
   - Fetches order line items: `POST order/viewProducts`.

3. **Riverpod State Management ([`orders_controller.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/orders/controller/orders_controller.dart))**:
   - `orderStatusTabProvider`: Active status tab state.
   - `ordersListProvider`: Auto-disposing family async notifier querying orders by `(shopId, status)` with pull-to-refresh.
   - `orderCountsProvider`: Auto-disposing future provider for store badge counts.
   - `orderProductsProvider`: Family future provider for fetching order item breakdown.
   - `orderActionControllerProvider`: Mutation notifier handling accept, cancel, and ready-to-ship actions with automatic cache invalidation.

4. **UI Components & Contextual Actions**:
   - **Order Card ([`order_card.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/orders/view/widgets/order_card.dart))**: Displays order ID, timestamp, customer info, delivery and payment pills, price, and status-dependent action buttons (Accept/Cancel for New; Mark Ready/Cancel for Processing; View Details for other statuses).
   - **Order Details Modal ([`order_details_modal.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/orders/view/widgets/order_details_modal.dart))**: Bottom sheet with customer details, address, payment summary, and line-item products.
   - **Cancel Order Dialog ([`cancel_order_dialog.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/orders/view/widgets/cancel_order_dialog.dart))**: Radio selection for cancellation reasons (`Item out of stock`, `Store too busy`, `Customer requested cancellation`, `Other`).
   - **Orders List View ([`orders_list_view.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/orders/view/views/orders_list_view.dart))**: Supports loading spinners, pull-to-refresh, empty states with refresh action, and error states with retry.
   - **Orders Screen ([`orders_screen.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/orders/view/orders_screen.dart))**: Scrollable top TabBar with live badge counts wired into Tab 1 of [`DashboardScreen`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/dashboard/view/dashboard_screen.dart).

5. **Quality Verification**:
   - `flutter analyze`: 0 errors, 0 warnings.
   - `flutter test`: 20/20 tests passing across auth, dashboard, and orders modules.

---

### Phase 10: 1:1 UI & Asset Parity with MerchantAndroidApp (Welcome, Login, Registration)

Aligned the visual presentation, branding assets, and layout structures of the onboarding and authentication screens with `/BayFay-AI-V3/MerchantAndroidApp`:

1. **Asset Migration**:
   - Extracted official BayFay drawables from `MerchantAndroidApp/app/src/main/res/`:
     - `assets/images/logo_transaparent.webp` (centered in WelcomeActivity)
     - `assets/images/logo.webp` (used in splash overlay)
     - `assets/images/power_by.webp` (footer in splash overlay)
     - `assets/images/logo_small_icon.png` (app icons)
   - Registered `assets/images/` in `pubspec.yaml` and created [`AppAssets`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/core/constants/app_constants.dart).

2. **Color Palette & Visual Tokens ([`app_colors.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/app/theme/app_colors.dart))**:
   - Added Android brand colors:
     - `brandBlue`: `#2196F3` (`@color/logo` / `merchant_login` button)
     - `brandLime`: `#92C42C` (`@color/login_btn` / `signup` button)
     - `brandInputText`: `#262626` (`@color/login_txt_color`)
     - `brandInputBorder`: `#B5B5B5` (`@color/login_txt_brder`)
     - `brandCardBorder`: `#BCBCBC` (`@color/login_border`)

3. **Welcome Screen ([`welcome_screen.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/auth/welcome/view/welcome_screen.dart))**:
   - Header title: "BayFay Merchant" (22sp bold).
   - Centered `logo_transaparent.webp` (220x220).
   - Bottom two action buttons:
     - **Merchant Login**: Blue `#2196F3`, white bold text.
     - **Sign Up**: Lime Green `#92C42C`, white bold text.
   - Returning user card: "Welcome Back", user name, "Go to Dashboard", and account switcher button.

4. **Login Screen ([`login_screen.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/auth/login/view/login_screen.dart))**:
   - Enclosed inside Android's 1px bordered card (`#BCBCBC`).
   - "Email or Mobile Number" input box with `#B5B5B5` border.
   - "Password" label with aligned "Forgot Password?" link.
   - Blue "Merchant Login" button with "Logging on" loading state.
   - "What new ?" middle divider.
   - Lime Green "Sign Up" button.

5. **Registration Screens ([`register_screen.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/auth/register/view/register_screen.dart) & [`register_verify_screen.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/auth/register/view/register_verify_screen.dart))**:
   - Custom top AppBar (`#F5F5F5` background, back navigation, centered "Sign Up" title, and `#E3E3E3` bottom divider line).
   - Step 1: Bordered card with First Name, Last Name, Email Id, and Mobile Number featuring a fixed `+91` prefix container and 10-digit input. "Next" button in Lime Green (`#92C42C`).
   - Step 2: 6-digit SMS verification code, aligned "Resend OTP" countdown link, new password, confirm password, and Lime Green "Next" button.

6. **Splash Screen ([`splash_screen.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/splash/view/splash_screen.dart))**:
   - 1:1 match with Android's splash layout: white background, centered `logo.webp`, bottom "Powered By" text and `power_by.webp`.

---

### Phase 11: Typography & Android Font Normalization

Extracted and incorporated the exact legacy Android font assets from `MerchantAndroidApp/app/src/main/res/font/`:
1. **Font Assets Registered**:
   - `assets/fonts/nunito.ttf` & `nunito_semibold.ttf` (weights 400, 600, 700): Set as global theme font family in `app_theme.dart`. Used for card headers, field labels, action buttons, and bottom navigation.
   - `assets/fonts/product_sans_google.ttf` (weight 400): Used for input field text, hints, mobile prefix badges (`+91`), and subtext.
   - `assets/fonts/roboto.ttf` (weight 400): Used for top toolbar titles, tab titles, and OTP verification inputs.
2. **Font Weight Normalization**:
   - Resolved the issue where form inputs appeared excessively bold across login and registration forms.
   - Set all input fields to use `AppFonts.productSans` with `FontWeight.normal` (w400), matching the Android XML definitions (`edit_first_name`, `edit_last_name`, `edt_email_Id`, `edt_mno`, `login_edt`, `pwd_edt`).

---

### Phase 12: Forgot Password & Reset Password Screens 1:1 Android Parity

Migrated and visually aligned the forgot password workflow from `ForgetPasswordActivity.java` and `ResetPasswordActivity.java`:
1. **Forgot Password Screen ([`forgot_password_screen.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/auth/forgot_password/view/forgot_password_screen.dart))**:
   - Android standard 50px grey toolbar titled "Forgot Password" (Roboto).
   - Bordered card (`#BCBCBC`), reactive `+91` mobile prefix box with active focus border and 10-digit validation.
   - Lime Green "Next" button calling `POST auth/forgot/otp`.
2. **Reset Password Screen ([`reset_password_screen.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/auth/forgot_password/view/reset_password_screen.dart))**:
   - Android standard 50px grey toolbar titled "Reset Password" (Roboto).
   - Bordered card with OTP input, new password, confirm password, and Lime Green "Update" button calling `POST auth/forgot/reset`.

---

### Phase 13: Centralized UI Strings & Reusable Core Widgets Architecture

Refactored all view files to eliminate hardcoded strings and repeated widget definitions:
1. **Centralized UI Strings ([`app_strings.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/core/constants/app_strings.dart))**:
   - Over 260 constants added covering:
     - Authentication (Welcome, Login, Registration, Verification, Forgot Password, Reset Password).
     - Dashboard (App bar, Metrics, Store Switcher, Navigation Drawer, Account tab, Inventory tab).
     - Orders (Tab statuses, action buttons, customer info, logistics pills, order cancellation reasons, bill summary, empty states, error messages).
     - Badges and Categories (`ACTIVE`, `OPEN`, `CLOSED`, `Wholesale Store`, `Retail Store`, `Restaurant`).
2. **Reusable Core Widgets ([`lib/core/widgets/`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/core/widgets/))**:
   - [`AppButton`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/core/widgets/app_button.dart): Supports `.primary` (Brand Blue), `.lime` (Brand Lime), `.outline` (customizable border/color), and `.danger` (destructive red) with integrated `LoadingIndicator`.
   - [`AppToolbar`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/core/widgets/app_toolbar.dart): Standard 50px grey toolbar with back arrow and Roboto 16px title.
   - [`AppPhoneField`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/core/widgets/app_phone_field.dart): Standardized `+91` mobile box with reactive focus state and form validation.
   - [`AppTextField.brand`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/core/widgets/app_text_field.dart): 4px radius, `#B5B5B5` input border, ProductSans regular 13px text, optional password toggle.
   - [`LoadingIndicator`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/core/widgets/loading_indicator.dart): Clean standardized progress spinner.
   - [`widgets.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/core/widgets/widgets.dart): Barrel file for clean imports.
3. **Screens Refactored**:
   - Replaced all inline text fields, buttons, progress indicators, and toolbars across all 17+ views and widgets.

---

### Phase 14: Quality Assurance & Verification

| Verification Step | Command | Status | Details |
| :--- | :--- | :--- | :--- |
| **Dart Analyzer** | `flutter analyze` | **PASSED** | 0 errors, 0 warnings (100% clean) |
| **Auth Flow Tests** | `flutter test test/auth_flow_test.dart` | **PASSED** | 12/12 tests passed |
| **Dashboard Tests** | `flutter test test/dashboard_test.dart` | **PASSED** | 3/3 tests passed |
| **Orders Tests** | `flutter test test/orders_test.dart` | **PASSED** | 8/8 tests passed |
| **Widget Integration** | `flutter test test/widget_test.dart` | **PASSED** | App launches & renders correctly |
| **Full Test Suite** | `flutter test` | **PASSED** | **23/23 tests passed** |

---

### Phase 15: Auto-Clear Form Errors on Typing & Re-validation

Configured responsive auto-validation across all text fields and form views:
1. **Core Widgets Auto-Validation**:
   - [`AppTextField`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/core/widgets/app_text_field.dart): Added `autovalidateMode` parameter across default constructor and all factories (`.brand`, `.email`, `.password`, `.phone`). Passed to underlying `TextFormField`.
   - [`AppPhoneField`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/core/widgets/app_phone_field.dart): Configured `FormField<String>` with `GlobalKey<FormFieldState<String>>`, active controller listener (`_onControllerChange`), and dynamic value dispatching on every keystroke (`didChange(val)`).
2. **Cross-Field Re-validation & Form State Listeners**:
   - Added `_passwordController` listeners in [`RegisterVerifyScreen`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/auth/register/view/register_verify_screen.dart) and [`ResetPasswordScreen`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/auth/forgot_password/view/reset_password_screen.dart) to trigger real-time re-validation of the Confirm Password field as the user updates their password.
   - Retained all existing formatters (`FilteringTextInputFormatter.digitsOnly`, `LengthLimitingTextInputFormatter`), focus nodes, and visual styling tokens.

---

### Phase 16: Merchant Signup Validation Check On 'Next' & Immediate Auto-Clear On Typing

Refactored the validation model in the Merchant Signup page ([`register_screen.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/auth/register/view/register_screen.dart)) to deliver a smooth, distraction-free typing UX:
1. **Disabled Immediate Validation While Typing**:
   - Set `autovalidateMode: AutovalidateMode.disabled` on the `Form` widget and all input fields (`AppTextField.brand` and `AppPhoneField`).
   - Ensures errors are **never** shown prematurely while the user is typing fresh input (such as entering partial names, typing incomplete emails, or typing partial digits of a mobile number).
2. **Validation Check Only Upon Clicking 'Next'**:
   - Validation checks (`AppValidators.validateFirstName`, `AppValidators.validateLastName`, `AppValidators.validateEmail`, `AppValidators.validateMobile`) run strictly upon clicking the "Next" button or triggering keyboard submission.
   - Any validation failures populate stateful error variables (`_firstNameError`, `_lastNameError`, `_emailError`, `_mobileError`) and render field-level red error labels and error borders.
3. **Immediate Error Clearing on First Keystroke**:
   - Attached dedicated controller listeners and `onChanged` handlers to each field.
   - As soon as the user starts typing any character in a field that has an active error message, the error is immediately cleared (`setState(() => _fieldError = null)`), restoring the active/normal brand border and removing error labels without showing any intermediate errors.
4. **AppPhoneField Widget Enhancement**:
   - Added `errorText` property to [`AppPhoneField`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/core/widgets/app_phone_field.dart) to seamlessly support both external error control and FormField validation.
   - Added conditional error rendering and border color updates.
### Phase 17: Multi-Stage Permission Architecture & Zomato-Style Location UX

Implemented an end-to-end, multi-stage permission architecture with distinct first-time onboarding vs. subsequent launch handling, sequential system requests, permanent denial settings fallback, and Zomato-style Location/GPS prompts:

1. **Gradle Build Fix & Dependency Resolution**:
   - Pinned `permission_handler: 11.3.1` (resolving `permission_handler_android: 12.1.0`) to avoid Gradle Kotlin DSL receiver type mismatch and unresolved compiler options errors caused by premature Kotlin 2.3.x references in unverified candidate releases.
   - Integrated `geolocator: ^14.0.2` for device GPS detection and system location settings integration.
   - Android APK dev debug build confirmed: `✓ Built build/app/outputs/flutter-apk/app-dev-debug.apk` in 19.9s.

2. **Android & iOS Manifest Configurations**:
   - **`AndroidManifest.xml`**: Configured fine/coarse location (`ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`), camera (`CAMERA`), storage/media (`READ_MEDIA_IMAGES` for API 33+, `READ_EXTERNAL_STORAGE`, `WRITE_EXTERNAL_STORAGE`), and push notification (`POST_NOTIFICATIONS`) with clear merchant-centric inline documentation.
   - **`Info.plist`**: Added `NSLocationWhenInUseUsageDescription`, `NSLocationAlwaysAndWhenInUseUsageDescription`, `NSCameraUsageDescription`, and `NSPhotoLibraryUsageDescription`.

3. **Riverpod State Management (`permission_notifier_provider.dart`)**:
   - `AppPermissionState`: Centralizes `cameraStatus`, `mediaStatus`, `locationStatus`, `notificationStatus`, `isLocationServiceEnabled` (GPS hardware status), and `permanentlyDeniedList`.
   - `PermissionNotifier`:
     - `initCheck()`: Checks `permissionOnboardingCompletedKey` in `LocalStorageService` to distinguish first-time vs. subsequent launches.
     - `requestFirstTimePermissions()`: Sequentially requests Camera -> Media -> Location -> Notification permissions and marks onboarding complete.
     - `recheckPermissions()`: Silently checks statuses on subsequent launches or upon app resume from system settings.
     - `openAppSettingsPage()`: Opens application system settings for permanently denied permissions.
     - `openLocationSettingsPage()`: Calls `Geolocator.openLocationSettings()` to enable GPS.

4. **Reusable Core UI Components (`lib/core/widgets/`)**:
   - [`PermissionExplanationDialog`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/core/widgets/permission_explanation_dialog.dart): Scrollable modal explaining why Camera, Media, Location, and Notifications are required before triggering OS prompts. Includes `PermissionExplanationDialog.show(context)`.
   - [`LocationDisabledWidget`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/core/widgets/location_disabled_widget.dart): Zomato-style location prompt with concentric radar-pin illustration, title, subtitle, and primary action button. Includes `LocationDisabledBottomSheet.show(context)`.
   - [`PermissionPermanentlyDeniedDialog`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/core/widgets/permission_permanently_denied_dialog.dart): Clean dialog with direct "Open App Settings" action button.
   - Barrel export updated in [`lib/core/widgets/widgets.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/core/widgets/widgets.dart).

5. **Screen Flow Integration**:
   - **Splash Flow (`splash_screen.dart` & `app_router.dart`)**:
     - First-time launch: Displays `PermissionExplanationDialog` after branding delay, requests permissions sequentially upon user confirmation, then proceeds.
     - Subsequent launches: Checks permissions silently and seamlessly routes to Welcome or Dashboard.
   - **Dashboard Flow (`dashboard_screen.dart`)**:
     - Displays Zomato-style `LocationDisabledBottomSheet` if GPS is turned off (either on startup or toggled off mid-session).
     - Displays `PermissionPermanentlyDeniedDialog` if permissions are permanently denied.

6. **Automated Testing & Quality Verification**:
   - `flutter analyze`: **0 errors, 0 warnings (100% clean)**.
   - `flutter test`: **29/29 tests passed**, including unit and widget tests for `AppPermissionState`, `LocationDisabledWidget`, and `PermissionPermanentlyDeniedDialog`.

---

### Phase 18: Simplified Direct OS Permissions & Universal Zomato-Style Location Prompt with Auto-Dismiss

Refined the permission architecture according to user requirements:

1. **Removed Custom Pre-Permission Dialog**:
   - Completely deleted `lib/core/widgets/permission_explanation_dialog.dart` ("Welcome to BayFay Merchant" dialog).
   - Removed export from [`widgets.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/core/widgets/widgets.dart).

2. **First Launch Direct System Permission Requests**:
   - On the very first app launch, sequentially requests native OS permissions (Allow/Don't Allow) directly via code in [`splash_screen.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/splash/view/splash_screen.dart) without intermediate dialogs:
     1. **Location** (`Permission.location.request()`)
     2. **Notification** (`Permission.notification.request()`)
     3. **Camera** (`Permission.camera.request()`)
     4. **Photos / Media** (`_requestMediaPermission()`)
   - Implemented in [`permission_notifier_provider.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/core/providers/permission_notifier_provider.dart) as `requestFirstLaunchPermissions()`.

3. **Universal Location (GPS) Check (Both Logged-In & Logged-Out)**:
   - Created [`UniversalLocationObserver`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/core/widgets/universal_location_observer.dart) wrapping `MaterialApp.router` in [`app.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/app/app.dart).
   - Uses `rootNavigatorKey` defined in [`app_router.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/app/router/app_router.dart).
   - Every time the app launches or comes to the foreground (`AppLifecycleState.resumed`), silently checks device Location Services via `Geolocator.isLocationServiceEnabled()`.
   - **If GPS is OFF**: displays custom Zomato-style [`LocationDisabledBottomSheet`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/core/widgets/location_disabled_widget.dart).
   - **Action Button**: "Enable Location" (`AppStrings.enableLocation`) directly triggers `Geolocator.openLocationSettings()`.
   - **Auto-Dismiss**: Automatically dismisses the Bottom Sheet (`LocationDisabledBottomSheet.dismiss()`) as soon as GPS is switched ON.

4. **Centralized UI Strings**:
   - All Bottom Sheet strings are centralized in [`app_strings.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/core/constants/app_strings.dart):
     - `AppStrings.locationOffTitle` ("Device location is off")
     - `AppStrings.locationOffSubtitle` ("Turning on device location helps us detect your store, calculate delivery distance, and receive orders smoothly.")
     - `AppStrings.enableLocation` ("Enable Location")
     - `AppStrings.notNow` ("Not Now")

5. **Quality Verification**:
   - `flutter analyze`: **0 issues found (clean)**.
   - `flutter test`: **29/29 tests passed**.
   - `./gradlew assembleDevDebug`: **BUILD SUCCESSFUL in 4m 1s** (`app-dev-debug.apk`).

---

### Phase 19: Native Google Play Services Location Dialog & Direct First-Launch Permissions

Simplified the location architecture by removing all custom bottom sheets across the entire app and utilizing native Google Play Services resolution prompts:

1. **First-Launch Permission Flow**:
   - On the very first app launch, sequentially requests native OS permissions directly via `permission_handler` without any intermediate custom UI dialogs:
     1. **Camera** (`Permission.camera.request()`)
     2. **Photos / Media** (`_requestMediaPermission()`)
     3. **Notifications** (`Permission.notification.request()`)
     4. **Location** (`Permission.location.request()`)
   - Implemented in [`permission_notifier_provider.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/core/providers/permission_notifier_provider.dart) as `requestFirstLaunchPermissions()`.

2. **Native Google Play Services Location Check (Logged-In & Logged-Out)**:
   - Completely deleted all custom Zomato-style bottom sheets (`LocationDisabledWidget`, `LocationDisabledBottomSheet`).
   - Created dedicated [`location_service_provider.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/core/providers/location_service_provider.dart):
     - `LocationServiceNotifier.checkAndPromptLocationService()`:
       - Checks `Geolocator.isLocationServiceEnabled()`.
       - If Location is OFF, immediately triggers the native Google Play Services system resolution dialog (with the "Turn on" button) by invoking:
         `Geolocator.getCurrentPosition(locationSettings: LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 10)))`.
       - When the merchant taps "Turn on", the system turns on GPS directly in-place without navigating away from the app.
       - If the merchant taps "No thanks" or dismisses, catches `LocationServiceDisabledException` gracefully without error.
   - Wired to [`UniversalLocationObserver`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/core/widgets/universal_location_observer.dart) wrapping `MaterialApp.router` in [`app.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/app/app.dart) to check on app open and resume (`AppLifecycleState.resumed`) across all screens.

3. **Quality & Test Verification**:
   - `flutter analyze`: **0 issues found (100% clean)**.
   - `flutter test`: **29/29 automated tests passed** (including unit tests for `LocationServiceNotifier` and `LocationServiceState`).
   - `./gradlew assembleDevDebug`: **BUILD SUCCESSFUL in 46s** (`app-dev-debug.apk`).

---

### Phase 20: Relocation of Location Service Check from Splash Screen to Welcome Screen

Refactored the location enablement check and native Google Play Services GPS prompt (`Geolocator.getCurrentPosition`) from the Splash Screen to the Welcome Screen:

1. **Removed Location Check from Splash Screen**:
   - Removed `Geolocator.getCurrentPosition(...)` and any GPS enablement calls from `PermissionNotifier.requestFirstLaunchPermissions()` in [`permission_notifier_provider.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/core/providers/permission_notifier_provider.dart).
   - Removed `splashCompletedProvider` listener and post-frame callback on `initState` from [`UniversalLocationObserver`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/core/widgets/universal_location_observer.dart) so that the Splash Screen remains isolated and focused strictly on branding, token registration, and sequential OS permissions without prompting system GPS dialogs.

2. **Integrated Location Check into Welcome Screen**:
   - Converted [`WelcomeScreen`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/auth/welcome/view/welcome_screen.dart) from `ConsumerWidget` to `ConsumerStatefulWidget` with `WidgetsBindingObserver`.
   - In `initState`, schedules a post-frame callback to trigger `_checkLocationService()`.
   - In `didChangeAppLifecycleState`, monitors `AppLifecycleState.resumed` to dynamically re-evaluate GPS status when the merchant returns to the Welcome Screen (e.g. from system settings or native prompt dismissal).
   - In `_checkLocationService()`, checks device GPS status via `checkServiceStatus()`, and if OFF, triggers the native Google Play Services resolution dialog via `checkAndPromptLocationService()`.
   - Updated `locationServiceProvider` to check both `Permission.location` and `Permission.locationWhenInUse` so that merchants granting approximate/coarse or while-in-use permissions are not blocked from GPS activation.
   - Clean lifecycle cleanup in `dispose()` removing the observer.

3. **Quality & Verification**:
   - `flutter analyze`: **0 issues found (100% clean)**.
   - `flutter test`: **32/32 automated tests passed** across all modules.

---

### Phase 21: Form Validation Logic Refactoring for Registration & Login Screens

Refactored the validation model across Login and Registration (Step 1 and Step 2) screens to enforce manual submission triggers, dynamic single-field error clearing on typing, and automatic reset/re-validation:

1. **Manual Trigger for Validation**:
   - Set `autovalidateMode: AutovalidateMode.disabled` on `Form` and all `AppTextField` / `AppPhoneField` widgets.
   - Prevented premature error popups from displaying while the user is typing fresh input.
   - Validation checks (`AppValidators.validateEmailOrMobile`, `AppValidators.validatePassword`, `AppValidators.validateFirstName`, `AppValidators.validateLastName`, `AppValidators.validateEmail`, `AppValidators.validateMobile`, `AppValidators.validateOtp`) run strictly upon clicking the action button ("Merchant Login" or "Next").

2. **Error Clearing on Input**:
   - When a field fails validation and displays an error with red borders, typing any character into that specific field clears its error dynamically via controller listeners and `onChanged` handlers (`setState(() => _fieldError = null)`).
   - Only the error for that specific input box clears, while other field errors remain visible until addressed.

3. **Reset & Re-validation on Next/Submit**:
   - Clicking "Next" or "Merchant Login" again re-validates all fields dynamically against current values.

4. **Quality & Test Verification**:
   - `flutter analyze`: **0 issues found (100% clean)**.
   - `flutter test test/auth_flow_test.dart`: **14/14 tests passed**, including comprehensive widget tests validating typing without errors, error clearing on typing, and re-validation on re-submission.
   - `flutter test`: **32/32 tests passed**.

---

### Phase 22: Forgot Password OTP Validation Refactoring & Android App Security Audit

1. **Forgot Password & Reset Password Validation Model (Sequential Single-Error Validation)**:
   - Refactored [`ResetPasswordScreen`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/auth/forgot_password/view/reset_password_screen.dart) and [`ForgotPasswordScreen`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/auth/forgot_password/view/forgot_password_screen.dart):
     - **Sequential Validation on Next**: Fields are validated strictly one by one upon clicking the "Next" button.
       - If OTP is empty, displays **ONLY** `AppStrings.enterOtp` ("Enter OTP") and stops immediately without validating password fields.
       - If OTP is < 4 digits, displays **ONLY** `AppStrings.enterValidVerificationCode` and stops.
       - Only after a valid OTP is entered does validation proceed to check the password field. If password is missing or < 6 characters, displays **ONLY** `AppStrings.enterPassword` or `AppStrings.passwordMinLength` and stops.
       - Only after valid OTP and password are entered does validation proceed to check confirm password. If missing or mismatched, displays **ONLY** `AppStrings.confirmPasswordRequired` or `AppStrings.passwordsDoNotMatch`.
     - **Single Error Message**: Strictly one validation error is visible on the screen at any given time. Fields never fail simultaneously.
     - **Whole-Form Error Clearing on Input**: As soon as the merchant begins typing in the OTP input field (or any field), all active validation errors across the entire form disappear immediately.
     - **Standardized Button**: Kept button label as `AppStrings.next` ("Next") to match verification step consistency.

2. **Android App Security Review (Password Policy & Data Transmission)**:
   - **Password Policy Enforcement**:
     - Enforces minimum 6-character length across login, registration verification, and reset password screens via [`AppValidators.validatePassword`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/core/validators/app_validators.dart).
     - Full parity with legacy Android (`BaseActivity.java`, `ResetPasswordActivity.java`, `StoreVerificationActivity.java`).
   - **Client-Side Password Hashing**:
     - Verified that all authentication request models ([`LoginRequest`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/auth/login/data/models/login_request.dart), [`SignUpCompleteRequest`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/auth/register/data/models/register_request.dart), [`ResetPasswordRequest`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/auth/forgot_password/data/models/forgot_password_request.dart)) apply MD5 cryptographic hashing (`md5.convert(utf8.encode(password)).toString()`) client-side before sending.
     - Passwords and new passwords are never sent in plaintext across the network.
   - **Secure Transport (TLS / HTTPS)**:
     - All API endpoints across development, QA, and production environments strictly use HTTPS (`https://store-devapi.bayfay.com/api/v1/`, `https://qa-api.bayfay.com/api/v1/`, `https://store-api.bayfay.com/api/v1/`).
     - Android cleartext traffic is disabled by default on Android 9+ (API 28+).
   - **Logging & Debug Payload Inspection**:
     - Configured [`LoggingInterceptor`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/core/network/interceptors/logging_interceptor.dart) to output the actual request payload sent across the network (including mobile details, actual OTP, and client-side MD5-hashed passwords) to assist developer debugging.
     - Masked `Authorization: Bearer <token>` in HTTP headers using `_maskToken()`.
     - Guarded [`LoggingInterceptor`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/core/network/interceptors/logging_interceptor.dart) with `if (kDebugMode)` in [`ApiClient`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/core/network/api_client.dart), ensuring that in production release builds, all logging is automatically excluded and zero sensitive payload information is written to device Logcat.

3. **Quality & Test Verification**:
   - `flutter analyze`: **0 issues found (100% clean)**.
   - `flutter test`: **34/34 automated tests passed** (including unit tests and widget tests covering manual validation triggers, whole-form error clearing upon OTP typing, and security hashing).

---

### Phase 23: Login API Real Device Coordinates & GPS Settings Redirection

1. **GPS State Check on Login Click**:
   - In [`LoginController.login()`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/auth/login/controller/login_controller.dart), when the merchant taps "Merchant Login" and passes field validations:
     - Silently checks if device Location Services (GPS) are turned ON via `Geolocator.isLocationServiceEnabled()`.
     - If Location is OFF:
       - Directly redirects the merchant to the native device location settings screen via `Geolocator.openLocationSettings()`.
       - Emits `AppStrings.locationRequiredForLogin` ("Please turn on location to log in") floating SnackBar error on [`LoginScreen`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/auth/login/view/login_screen.dart).
       - Halts the login process without calling the remote authentication endpoint.

2. **Real Device Coordinates in Login API Payload**:
   - If GPS is ON:
     - Verifies location permissions (`Geolocator.checkPermission()` and `Geolocator.requestPermission()`).
     - Retrieves the active device coordinates via `Geolocator.getCurrentPosition(locationSettings: LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 5)))`, with automatic fallback to `Geolocator.getLastKnownPosition()`.
     - Passes retrieved `latitude` and `longitude` to [`LoginRepository.login()`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/auth/login/repository/login_repository.dart) and [`LoginRequest`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/auth/login/model/login_request.dart).
     - Result: `LoginRequest.toJson()` sends the actual device coordinates in the payload:
       ```json
       "current_location": {
         "coordinates": [
           longitude,
           latitude
         ],
         "type": "Point"
       }
       ```
       instead of default `[0, 0]`.

3. **Quality & Test Verification**:
   - `flutter analyze`: **0 issues found (100% clean)**.
   - `flutter test`: **35/35 automated tests passed** (including unit tests verifying that `LoginRequest` formats non-zero coordinates `[longitude, latitude]` with MD5-hashed passwords).

---

### Phase 24: Isolated Welcome Screen Native Location Accuracy Resolution Refactor

1. **Review & Root Cause Analysis of Phase 19 Enablement Flow**:
   - In Phase 19, `checkAndPromptLocationService()` relied on `Permission.location.isGranted` from `permission_handler`. On Android 12+ devices where merchants grant "Approximate" (coarse) location, `Permission.location.isGranted` returns `false`, preventing the app from ever triggering `Geolocator.getCurrentPosition()`.
   - Furthermore, prior session decline states could prevent prompts from firing on subsequent returns to the Welcome Screen.

2. **Strictly Isolated Refactoring on Welcome Screen**:
   - Confined 100% of the refactoring to [`WelcomeScreen._checkLocationService()`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/auth/welcome/view/welcome_screen.dart) without modifying or impacting any other module, repository, controller, or navigation flow.
   - Flow mechanics:
     1. **Silent Service Check**: Queries `Geolocator.isLocationServiceEnabled()`. If Location is ON, updates Riverpod provider state (`checkServiceStatus()`) and returns immediately.
     2. **Permission Safeguard**: Queries `Geolocator.checkPermission()`. If `LocationPermission.denied`, automatically requests permission via `Geolocator.requestPermission()`. Supports both Precise and Approximate permissions seamlessly across all Android versions.
     3. **Native Google Play Services Prompt**: With permission active and GPS OFF, calls:
        ```dart
        await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 10),
          ),
        );
        ```
        This raises the Android system's `ResolvableApiException`, launching Google Play Services' native Location Accuracy resolution dialog:
        *"To continue, turn on device location..."* with **"No thanks"** and **"Turn on"** buttons.
     4. **In-Place Activation**: Tapping "Turn on" activates GPS hardware in-place without routing away from the Welcome Screen.
     5. **Graceful Cancellation**: Tapping "No thanks" or dismissing throws `LocationServiceDisabledException`, which is caught cleanly without crashing or displaying erroneous alerts.
     6. **Lifecycle Synchronization & Debounce**: Employs `_isPromptingLocation` and `_userDeclinedThisSession` flags to prevent prompt loops during Android Activity pause/resume transitions, while dynamically keeping `locationServiceProvider` synchronized.

3. **Quality & Test Verification**:
   - `flutter analyze`: **0 issues found (100% clean)**.
   - `flutter test`: **35/35 automated tests passed**.

---

**Date: September 09, 2026**

### Phase 25: Location Permission, Service Activation & Registration Flow Architecture

1. **First-Time App Launch (Zomato-Style 2-Step Permission & Accuracy Flow)**:
   - On the first app launch, sequential OS permissions are requested: Camera → Media → Location.
   - **Step 1 (Permission)**: Android presents the native location permission dialog (*"Allow BayFay Merchant to access this device's location?"* with *While using the app* / *Only this time* / *Don't allow*).
   - **Step 2 (Location Accuracy System Dialog)**: As soon as the merchant taps **"While using the app"** / **"Allow"**, the app immediately invokes Google Play Services `SettingsClient` resolution prompt via `Geolocator.getCurrentPosition(locationSettings: LocationSettings(accuracy: LocationAccuracy.high))` if GPS is OFF.
   - Android displays: *"For a better experience, your device will need to use Location Accuracy"* with **[No, thanks]** and **[Turn on]** (matching the exact Zomato 2-step sequence).
   - Tapping **"Turn on"** activates device GPS hardware in-place.
   - Commits `permissionOnboardingCompletedKey = true` to local storage.

2. **Welcome Screen & Resumption**:
   - On secondary launches or when resuming on [`WelcomeScreen`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/auth/welcome/view/welcome_screen.dart), `_checkLocationService()` verifies device GPS status.
   - If GPS is OFF and location permission is granted, triggers the native Location Accuracy prompt (*"For a better experience, your device will need to use Location Accuracy"*).
   - **Strict Route Guarding**: Guarded via `ModalRoute.of(context)?.isCurrent == true` so the prompt is **NEVER** shown when the user is on the Login Screen or Registration Screen.
   - `UniversalLocationObserver` remains scoped to authenticated sessions (`authState is AuthAuthenticated`).

3. **Login Screen Logic & API Integration**:
   - When the merchant clicks "Merchant Login", the device's GPS status is checked via `Geolocator.isLocationServiceEnabled()`.
   - If GPS is disabled:
     - The native OS dialog is strictly avoided.
     - The user is redirected directly to the device's Location Settings page (`Geolocator.openLocationSettings()`).
     - SnackBar alert: *"Please turn on location to log in"*.
     - The login API call is halted.
   - When the user returns to the app and clicks "Merchant Login" again:
     - `WidgetsBindingObserver.didChangeAppLifecycleState` invalidates any prior error on `resumed`.
     - GPS is verified ON; coordinates `(latitude, longitude)` are captured using `AndroidSettings(forceLocationManager: true, accuracy: LocationAccuracy.high)`, ensuring Google Play Services native dialog is never triggered.
     - Coordinates are packaged into `LoginRequest` as GeoJSON `[longitude, latitude]` in `current_location.coordinates` and transmitted in the login payload.

4. **Registration Flow Location Verification & Dynamic Coordinate Capture**:
   - **Step 1 (RegisterScreen - `StoreSignUpActivity`)**:
     - When the user taps "Next", device GPS is verified.
     - If GPS is OFF: redirects directly to device Location Settings (`Geolocator.openLocationSettings()`), displays SnackBar error, and halts `initiateSignUp`.
     - When GPS is ON: proceeds to initiate signup and send SMS OTP.
   - **Step 2 (RegisterVerifyScreen - `StoreVerificationActivity`)**:
     - When the user taps "Next" / "Register", device GPS is verified.
     - If GPS is OFF: redirects directly to device Location Settings (`Geolocator.openLocationSettings()`), displays SnackBar error, and halts `completeVerification`.
     - When GPS is ON: captures active GPS coordinates `(latitude, longitude)` using `AndroidSettings(forceLocationManager: true)`.
     - Coordinates are injected into `SignUpCompleteRequest` as `current_location: { coordinates: [longitude, latitude], type: 'Point' }` in `POST auth/signup`.
   - **One-Shot Registration**:
     - `RegisterController.register` also verifies GPS status, redirects to settings if disabled, captures coordinates, and includes `[longitude, latitude]` in `RegisterRequest`.
   - **Lifecycle Resumption**:
     - Both `RegisterScreen` and `RegisterVerifyScreen` implement `WidgetsBindingObserver` to auto-clear error states upon returning from Location Settings.

5. **Quality & Test Verification**:
   - `flutter analyze`: **0 issues found (100% clean)**.
   - `flutter test`: **36/36 automated tests passed** (including unit tests verifying dynamic GPS coordinate serialization `[lng, lat]` for `SignUpCompleteRequest` and `LoginRequest`, form validation, sequential validation, and UI widget tests).

---

**Date: September 10, 2026**

### Phase 26: Google Location Accuracy Native Dialog Material 3 Styling Parity

Resolved the visual difference between Zomato and BayFay Merchant for the native Google Location Accuracy dialog (*"For a better experience, your device will need to use Location Accuracy"*):

1. **Root Cause Analysis**:
   - In Zomato, the dialog renders with **Material 3 button styles**: "No, thanks" with an outlined rounded pill border and "Turn on" with a solid blue filled pill button.
   - In BayFay Merchant, the dialog rendered with **legacy Material 2 flat text buttons** (blue text, no pill border, no solid fill) situated in the bottom right corner.
   - Flutter's default Android configuration sets `NormalTheme` in `styles.xml` to `@android:style/Theme.Light.NoTitleBar` (an Android 1.0/Gingerbread platform theme) with no Google Material library dependency.
   - When Google Play Services presents `ResolvableApiException` resolution dialogs within the host application window, it checks whether the app provides MaterialComponents / Material 3 styling. Lacking this, it fell back to legacy `ButtonBar` flat text button rendering.

2. **Resolution Applied**:
   - **Material Dependency**: Added `com.google.android.material:material:1.12.0` in [`android/app/build.gradle.kts`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/android/app/build.gradle.kts).
   - **Material 3 Android Theme**: Configured `NormalTheme` in both [`android/app/src/main/res/values/styles.xml`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/android/app/src/main/res/values/styles.xml) and [`android/app/src/main/res/values-night/styles.xml`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/android/app/src/main/res/values-night/styles.xml) with `parent="Theme.Material3.DayNight.NoActionBar"`.
   - **Activity Architecture**: Updated `MainActivity` in [`android/app/src/main/kotlin/com/bayfay/merchant/MainActivity.kt`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/android/app/src/main/kotlin/com/bayfay/merchant/MainActivity.kt) to extend `FlutterFragmentActivity`, ensuring full compatibility with Material 3 themes and fragment-based dialogs.

3. **Verification**:
   - `./gradlew assembleDevDebug --dry-run`: **BUILD SUCCESSFUL**.
   - `flutter analyze`: **0 issues found**.
   - `flutter test`: **36/36 tests passed**.

---

**Date: September 10, 2026**

### Phase 27: Clean API Error Message Display & Modern Floating SnackBar Architecture

Implemented clean, human-readable error message formatting and modern floating SnackBar UI across the Registration and Login screens:

1. **Root Cause Analysis**:
   - API errors were displayed with raw technical prefixes and status code suffixes (e.g., `ServerException: Email-id is taken already (code: 500)`).
   - In `AppException`, `toString()` was formatted as `'$runtimeType: $message (code: $statusCode)'`, which leaked runtime class names and HTTP status codes into UI listeners whenever `error.toString()` was evaluated.
   - Screen listeners used raw `SnackBar` instances without consistent padding, rounded corners, or error icons.

2. **Clean Error Parsing & Sanitization**:
   - Updated `AppException.toString()` in [`exceptions.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/core/errors/exceptions.dart) and `Failure.toString()` in [`failures.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/core/errors/failures.dart) to directly return `message`, retaining `toDebugString()` for internal diagnostics.
   - Implemented `AppSnackBar.cleanErrorMessage(dynamic error)` in [`lib/core/widgets/app_snackbar.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/core/widgets/app_snackbar.dart):
     - Strips technical prefixes: `ServerException:`, `Exception:`, `NetworkException:`, `AppException:`, `ServerFailure:`, `DioException:`, etc.
     - Strips HTTP status codes: `(code: 500)`, `(code: null)`, `[code: 500]`, `code: 500`.
     - Handles raw string errors, nested exception chains, and quoted server responses.
     - Preserves clean user-facing messages untouched.

3. **Modern Floating SnackBar Styling**:
   - Added `AppColors.errorSoft = Color(0xFFE53935)` in [`app_colors.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/app/theme/app_colors.dart).
   - Standardized `AppSnackBar.showError(BuildContext context, dynamic error)`:
     - Retains `ScaffoldMessenger.of(context).showSnackBar` (no native toasts).
     - Modern floating behavior: `behavior: SnackBarBehavior.floating`.
     - Soft red background: `backgroundColor: AppColors.errorSoft`.
     - Rounded corners: `RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0))`.
     - Margin: `EdgeInsets.only(bottom: 16.0, left: 16.0, right: 16.0)`.
     - Padding: `EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0)`.
     - Clean leading icon: `Icon(Icons.error_outline_rounded, color: Colors.white, size: 20)`.
     - Typography: `AppFonts.nunito` semi-bold white text.
     - Auto-dismisses existing snackbars via `hideCurrentSnackBar()` before presenting new alerts.
   - Added companion `AppSnackBar.showSuccess(BuildContext context, String message)` for OTP and password reset success alerts.

4. **Screen Integrations**:
   - **Login Screen** ([`login_screen.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/auth/login/view/login_screen.dart)): Replaced raw SnackBar in `loginControllerProvider` listener with `AppSnackBar.showError(context, next.error)`.
   - **Registration Step 1** ([`register_screen.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/auth/register/view/register_screen.dart)): Replaced raw SnackBar in `registerControllerProvider` listener with `AppSnackBar.showError`, and upgraded OTP sent confirmation to `AppSnackBar.showSuccess`.
   - **Registration Step 2** ([`register_verify_screen.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/auth/register/view/register_verify_screen.dart)): Replaced raw SnackBar in `registerControllerProvider` listener with `AppSnackBar.showError`, and upgraded OTP resend confirmation to `AppSnackBar.showSuccess`.
   - **Forgot Password & Reset Password** ([`forgot_password_screen.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/auth/forgot_password/view/forgot_password_screen.dart) & [`reset_password_screen.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/auth/forgot_password/view/reset_password_screen.dart)): Standardized with `AppSnackBar.showError` and `AppSnackBar.showSuccess`.

5. **Quality & Test Verification**:
   - `test/snackbar_test.dart`: 12 unit and widget tests verifying prefix stripping, code stripping, nested prefix handling, `AppException.toString()` parity, and floating SnackBar widget rendering.
   - `flutter test`: **48/48 automated tests passed**.
   - `flutter analyze`: **0 issues found (100% clean)**.

---

**Date: September 10, 2026**

### Phase 28: Suppression of 0/6 Character Counter on Registration Verification Screen

1. **Problem Analysis**:
   - On the Merchant Registration Step 2 screen ([`register_verify_screen.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/auth/register/view/register_verify_screen.dart)), the SMS Verification Code input field was rendering a `0/6` character counter below the field.
   - Flutter's `TextFormField` by default generates a `'$currentLength / $maxLength'` counter when `maxLength` is specified. In the legacy Android app, `EditText` with `android:maxLength="6"` strictly enforces input length without displaying any character counter text.

2. **Resolution Applied**:
   - **Centralized Form Field Component** ([`app_text_field.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/core/widgets/app_text_field.dart)):
     - In `InputDecoration` for `isBrandStyle`: configured `counterText: ''`.
     - In `TextFormField`: configured `buildCounter: widget.isBrandStyle ? (context, {required currentLength, required isFocused, maxLength}) => null : null`. This completely suppresses the counter widget and eliminates any unwanted bottom spacing across all brand fields.
   - **Verification Screen Input Formatters** ([`register_verify_screen.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/auth/register/view/register_verify_screen.dart)):
     - Removed `maxLength: 6`.
     - Added `LengthLimitingTextInputFormatter(6)` alongside `FilteringTextInputFormatter.digitsOnly`, preserving 6-digit numeric input enforcement.

3. **Quality & Test Verification**:
   - Added widget test in [`test/auth_flow_test.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/test/auth_flow_test.dart) confirming that `RegisterVerifyScreen` does not render `0/6` or any counter text.
   - `flutter test`: **49/49 automated tests passed**.
   - `flutter analyze`: **0 issues found (100% clean)**.

---

**Date: September 10, 2026**

### Phase 29: Verification & Reset Password Sequential Single-Error Validation Parity

Standardized the **Sequential Single-Error Validation Model** across both password reset and registration verification screens:

1. **Problem Analysis**:
   - In [`RegisterVerifyScreen`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/auth/register/view/register_verify_screen.dart), tapping the "Next" button previously triggered simultaneous validation across all three fields (SMS Verification Code, New Password, Confirm Password), rendering multiple error messages at once.
   - In contrast, the application standard (established in [`ResetPasswordScreen`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/auth/forgot_password/view/reset_password_screen.dart)) mandates strict sequential validation: evaluating one field at a time, displaying strictly a single error, and stopping immediately upon the first failure.
   - When merchants moved from signup step 1 to verification step 2 and tapped "Next", multiple validation errors were displayed simultaneously, breaking verification flow consistency.

2. **Sequential Single-Error Validation Implementation**:
   - **Step 1 — OTP Verification**:
     - If OTP is empty, displays **ONLY** `AppStrings.enterOtp` (`"Enter OTP"`) on the OTP field and halts validation immediately (`_passwordError = null`, `_confirmPasswordError = null`).
     - If OTP is incomplete (< 6 digits on `RegisterVerifyScreen`, < 4 digits on `ResetPasswordScreen`), displays **ONLY** `AppStrings.enterValidVerificationCode` (`"Enter valid verification code"`) and halts.
   - **Step 2 — New Password**:
     - Validation proceeds to the password field *only after* a valid OTP is entered.
     - If password is empty, displays **ONLY** `AppStrings.enterPassword` (`"Please enter your password"`) and halts (`_otpError = null`, `_confirmPasswordError = null`).
     - If password is less than 6 characters, displays **ONLY** `AppStrings.passwordMinLength` (`"Password must be at least 6 characters"`) and halts.
   - **Step 3 — Confirm Password**:
     - Validation proceeds to confirm password *only after* valid OTP and password are entered.
     - If confirm password is empty, displays **ONLY** `AppStrings.confirmPasswordRequired` (`"Please confirm your password"`).
     - If confirm password does not match the new password, displays **ONLY** `AppStrings.passwordsDoNotMatch` (`"Passwords do not match"`).
   - **Single Error Guarantee**: Strictly one validation error message is visible on the screen at any given moment. Fields never fail simultaneously.
   - **Whole-Form Immediate Error Clearing on Input**: As soon as the merchant types into the OTP field or any input field, all active error messages across the entire form are cleared immediately via `_clearAllErrorsOnTyping()`.
   - **Standardized Next Button**: Retained lime green button with `text: AppStrings.next` (`"Next"`) across both `RegisterVerifyScreen` and `ResetPasswordScreen`.
   - **Modern Floating SnackBar Parity**: Standardized registration completion alert with `AppSnackBar.showSuccess(context, AppStrings.accountCreatedSuccess)`.

3. **Quality & Test Verification**:
   - Updated widget test in [`test/auth_flow_test.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/test/auth_flow_test.dart) to verify sequential 8-step single-error validation on `RegisterVerifyScreen` (empty OTP -> typing auto-clear -> incomplete OTP -> valid OTP with missing password -> short password -> valid password with missing confirm password -> mismatched password -> typing auto-clear).
   - `flutter test`: **49/49 automated tests passed**.
   - `flutter analyze`: **0 issues found (100% clean)**.

---

**Date: September 10, 2026**

### Phase 30: Auth Success Navigation & 1:1 Legacy Android Home Page Architecture Parity

1. **Auth API Success Navigation Parity**:
   - **Login Screen** ([`login_screen.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/auth/login/view/login_screen.dart)):
     - Updated `ref.listen<AsyncValue<void>>(loginControllerProvider, ...)` to immediately trigger `context.go(AppRoutes.dashboard)` when login succeeds (`previous?.isLoading == true && next is AsyncData`).
     - Preserves session state synchronization via `AuthStateNotifier` so that GoRouter state and router notifier automatically transition the merchant to `/dashboard`.
   - **Registration Verification Screen** ([`register_verify_screen.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/auth/register/view/register_verify_screen.dart)):
     - Confirmed explicit navigation `context.go(AppRoutes.dashboard)` upon successful OTP verification and account creation.

2. **Legacy Android Home Page Parity & UI Removal**:
   - **Removed Modern Discrepancies**:
     - Removed the modern Material 3 `NavigationBar` (tabs: Stores, Orders, Inventory, Account).
     - Removed the summary metric chips (`Total Stores`, `Open Stores`, `New Orders`).
     - Removed category filter chips (`All`, `Retail`, `Wholesale`) and text search field.
   - **Android Toolbar Architecture (`activity_home.xml`)**:
     - Refactored `DashboardScreen` ([`dashboard_screen.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/dashboard/view/dashboard_screen.dart)):
       - Height: 53dp.
       - Background: `#F5F5F5`.
       - Leading: Hamburger menu toggle (`Icons.menu_rounded`, color `#616161`) opening `HomeDrawer`.
       - Title: Centered text `"BayFay Merchant"` (`#616161`, 16sp, bold).
       - Right Actions:
         - TextButton `"Add Store"` (`#2196F3` / primary bold, matching `@id/next`).
         - Notification Bell with red circular badge showing unread notification count (`@id/notification_layout` & `@id/notify_badge`).
       - Bottom Divider: 1dp solid divider `#E3E3E3` (matching `@id/view`).
   - **Legacy Home Body View (`HomeBodyView` / `fragment_home.xml`)**:
     - Built [`home_body_view.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/dashboard/view/views/home_body_view.dart):
       - Pull-to-refresh (`RefreshIndicator`) triggering store list and notification count refresh.
       - **Top 3 Gradient Cards (`header_lay`)**:
         1. **Wholesale Stores (`session_1`)**: Gradient from `#EC1F64` to `#FF9800` (bottom-to-top), wholesale storefront icon, subtext "Buy From", bold label "Wholesale Stores", right chevron icon.
         2. **Business Value (`session_2`)**: Gradient from `#9C27B0` to `#2196F3`, dashboard icon, label "Business value", user count icon + "0", business value amount "₹ 0", right chevron icon. Tapping presents the Business Value information dialog with 12-month projection explanation.
         3. **Activate Agency (`session_3`)**: Gradient from `#009688` to `#18D820`, bold "Activate Agency" text. Tapping presents the Agency activation dialog.
       - **Guaranteed More Orders Promotion Banner (`guranteed_layout`)**:
         - Card with green verified badge, title "Guaranteed More Orders", subtitle "Enable scratch card Promotion now.", instructions, discount text, "Later" red button and "Activate" green button.
       - **Categorized Store Sections (`ShopsHeaderAdapter` parity)**:
         - Categorizes stores into 3 sections:
           1. **"My Stores"** (Regular retail merchant stores)
           2. **"External Shops"** (External stores)
           3. **"Wholesale Shops"** (Wholesale stores)
         - Each category renders an 18sp `#2B2B2B` bold header and a **3-column Grid** (`crossAxisCount: 3`).
       - **Store Item Card Layout (`LegacyStoreGridItem` / `m_shops_list.xml`)**:
         - Built [`legacy_store_grid_item.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/dashboard/view/widgets/legacy_store_grid_item.dart):
           - Square aspect ratio (1:1) thumbnail container with rounded corners (6dp) and subtle border.
           - Store image or fallback shopping/wholesale/restaurant icon placeholder.
           - "Waiting for Review" red banner at bottom of thumbnail for pending review stores.
           - Rating pill (`4.0 ⭐`) at bottom-left of thumbnail.
           - Circular red badge with order count at top-right.
           - Store name below thumbnail: 12sp, maximum 2 lines, centered, `#333333`.
       - **Empty State**:
         - Displays centered `"No Stores Available"` (16sp, `#666666`, matching `@id/no_data_found`).

3. **Quality & Test Verification**:
   - Added unit test in [`test/dashboard_test.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/test/dashboard_test.dart) verifying store categorization into "My Stores", "External Shops", and "Wholesale Shops".
   - `flutter test`: **50/50 automated tests passed**.
   - `flutter analyze`: **0 issues found (100% clean)**.

---

**Date: September 10, 2026**

### Phase 31: Session Persistence Flow, Token Refresh, and Dynamic Welcome Profile Display

1. **Session Persistence Flow Parity**:
   - **Launch Routing Logic** ([`app_router.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/app/router/app_router.dart)):
     - Updated GoRouter redirect to guarantee that upon `SplashScreen` completion (`isSplashing && isSplashComplete`), the app routes through `AppRoutes.welcome` (`WelcomeScreen`) for all users, including authenticated merchants.
     - Allowed `WelcomeScreen` to remain active when `authState is AuthAuthenticated`, displaying the returning merchant experience before auto-transitioning to `/dashboard`.
     - Preserved redirect guards routing direct child auth screens (`login`, `register`, etc.) to `/dashboard` for authenticated sessions.

2. **Token Refresh Architecture (`auth/refresh` Parity)**:
   - **Storage & Schema Enhancements** ([`app_constants.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/core/constants/app_constants.dart) & [`secure_storage_service.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/core/storage/secure_storage_service.dart)):
     - Added `accessSchemaKey` and `refreshSchemaKey` to persist access and refresh schema values (defaulting to `"Bearer"`).
     - Upgraded `saveTokens` and `clearTokens` to handle full token and schema sets.
   - **AuthTokens & LoginResponse Model Parity** ([`login_response.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/auth/login/model/login_response.dart)):
     - Expanded `AuthTokens` to parse both `access.schema` and `refresh.schema` from backend payloads matching legacy `LoginNewResponse`.
   - **Refresh Implementation** ([`login_repository.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/auth/login/repository/login_repository.dart)):
     - Implemented `refreshToken()` method executing `POST auth/refresh` with `Authorization: <refreshSchema> <refreshToken>` header matching Android's `ApiClient.getInterfaceRefresh().callRefreshToken()`.
     - Persists rotated access and refresh tokens, schema, profile, and privileges upon success.
   - **Centralized Riverpod AuthStateNotifier** ([`auth_state_provider.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/app/providers/auth_state_provider.dart)):
     - Added `refreshToken()` method on `AuthStateNotifier` updating active state to `AuthAuthenticated` with rotated credentials.
   - **Session Expiration Auto-Recovery (401 Interceptor)** ([`auth_interceptor.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/core/network/interceptors/auth_interceptor.dart)):
     - In `onError`, intercepts HTTP 401 unauthorized responses on non-auth endpoints, automatically attempts silent token refresh, updates headers, and retries the failed request via `handler.resolve(await dio.fetch(...))`.
     - If refresh fails, triggers `setSessionExpired()` to gracefully prompt re-authentication.

3. **Dynamic User Profile Display on Welcome Screen**:
   - **WelcomeScreen Rebuild** ([`welcome_screen.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/auth/welcome/view/welcome_screen.dart)):
     - Reads cached profile from `secureStorageServiceProvider` (`AppConstants.userProfileKey`) matching Android's `PreferenceUtils.GetUserData()`.
     - Dynamically computes `profile.fullName` (e.g. `"${profile.firstName} ${profile.lastName}"`).
     - Renders Android `welcome_back_lay` 1:1:
       - Subtitle: `"Welcome Back"` (`#616161`, 16sp, ProductSans).
       - Merchant Name: Dynamic display name (22sp bold black, fallback `"BayFay Merchants"`).
       - Progress Indicator: Circular progress indicator alongside `"Loading\n Please Wait.."` (10sp).
     - Triggers token refresh automatically on startup:
       - On success: Navigates smoothly to `AppRoutes.dashboard` (`/dashboard`).
       - On failure: Displays friendly expiration alert and switches to `"Merchant Login"` and `"Sign Up"` buttons.

4. **Quality & Test Verification**:
   - Added unit tests in [`test/auth_flow_test.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/test/auth_flow_test.dart) verifying:
     - `AuthTokens` schema and token parsing.
     - `LoginResponse` full payload parsing.
     - `WelcomeScreen` widget rendering dynamic merchant name, "Welcome Back", and loading indicator.
   - `flutter test`: **53/53 automated tests passed**.
   - `flutter analyze`: **0 issues found (100% clean)**.

---

**Date: September 10, 2026**

### Phase 32: Dashboard Layout Overflow Fix, Metric Cards Parity & Promotional Banner Enhancements

1. **AppBar 4.0px Vertical Layout Overflow Fix**:
   - **Root Cause Analysis** ([`dashboard_screen.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/dashboard/view/dashboard_screen.dart)):
     - An outer `PreferredSize` specified `Size.fromHeight(53.0)`, but contained a Flutter `AppBar` (default toolbar height `56.0`) plus a `Divider` (`1.0dp`), resulting in `57.0 - 53.0 = 4.0` pixels vertical overflow below the AppBar.
   - **Resolution**:
     - Removed the redundant outer `PreferredSize` and `Column`.
     - Placed the 1dp `#E3E3E3` bottom divider directly into `AppBar.bottom: PreferredSize(preferredSize: Size.fromHeight(1.0), child: Divider(height: 1, thickness: 1, color: Color(0xFFE3E3E3)))`.
     - Allowed `Scaffold` to accurately compute the preferred size without vertical clipping or overflow.

2. **Top Metric Cards Parity (`fragment_home.xml` Parity)** ([`home_body_view.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/dashboard/view/views/home_body_view.dart)):
   - **Card 2 ("Business value")**:
     - Gradient: `#9C27B0` to `#2196F3` (`gredient_bg_s2`).
     - Layout & Typography: Top `Icons.dashboard_rounded`, "Business value" (12sp bold white), customer count with `Icons.people_alt_rounded` (Nunito font), and turnover `₹ 0` with chevron right arrow.
   - **Card 3 ("Sales Analytics" replacing green "Activate Agency")**:
     - Background: Blue gradient `#0275D8` to `#2196F3` (`header_four_bg` / `header_two_bg`).
     - Analytics Displays:
       - "Last 1 Year" (11sp white, ProductSans) with annual amount (`₹ 0`, 13sp bold white).
       - Thin divider separation (`Colors.white24`).
       - "Last 30 Days" (11sp white, ProductSans) with monthly amount (`₹ 0`, 13sp bold white).
     - On Tap: Opens `Sales Analytics & Agency` dialog with comprehensive overview.

3. **Guaranteed More Orders Promotional Banner Enhancements** ([`home_body_view.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/dashboard/view/views/home_body_view.dart)):
   - **Circular Badge Icon**: Replaced generic tick icon with the circular promotional badge asset (`ic_guranteed_tick.png`) featuring golden-yellow ring and green checkmark.
   - **Store Selector Dropdown (`shops_sp` / `shop_sp`)**: Integrated store selection dropdown directly adjacent to the action buttons in the bottom row, allowing the merchant to switch the active store for promotional activation.
   - **Action Buttons**:
     - Updated "Later" button background to subtle grey (`#EEEEEE` with `#424242` bold text, matching Android `@drawable/gray_btn_bg_corner_half`).
     - Kept "Activate" button green (`#2E7D32` with bold white text, matching `@drawable/green_btn_bg_corner_half`).

4. **"My Stores" Grid Item Refinement** ([`legacy_store_grid_item.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/dashboard/view/widgets/legacy_store_grid_item.dart)):
   - Network image loading with smooth loading and error fallback.
   - Rating badge overlay pinned to bottom-left of thumbnail (`3.0 ★`, `4.4 ★` with yellow star).
   - "Waiting for Review" banner overlay when store status is pending review (`status == 0`).
   - Aspect ratio (`0.72`) ensuring comfortable layout for 2 lines of centered store title.

5. **Quality & Test Verification**:
- Added widget tests in [`test/dashboard_test.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/test/dashboard_test.dart):
     - Verified AppBar rendering with zero overflow.
     - Verified Card 2 ("Business value") and Card 3 ("Sales Analytics" with "Last 1 Year" & "Last 30 Days").
     - Verified Guaranteed More Orders banner with store dropdown, Later button, and Activate button.
     - Verified dismissing the promotion card on tapping "Later".
   - `flutter test`: **55/55 automated tests passed**.
   - `flutter analyze`: **0 issues found (100% clean)**.

---

**Date: September 10, 2026**

### Phase 33: Home Screen Dynamic Metric Cards Integration (API-078 & API-077)

Integrated Home Screen metric APIs to populate the top summary cards dynamically with live data:

1. **API Endpoints & Request/Response Models**:
   - Added endpoint constants in [`api_endpoints.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/core/network/api_endpoints.dart):
     - `ApiEndpoints.businessValue = 'merchant/business/value'` (API-078)
     - `ApiEndpoints.partnerInfo = 'merchant/partner/info'` (API-077)
   - Created typed data models in [`metric_models.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/dashboard/model/metric_models.dart):
     - `BusinessValueModel`: parses `customers_count` (int), `business_value` (num), and optional breakdown values matching Android `BusinessValueInfo.java`.
     - `PartnerInfoModel`: parses `annual_turnover` (num), `last_30_days_turnover` (num), `agency_info` (`List<String>`), and `note` (`String?`) matching Android `AgencyActivateDetailRsp.java`.

2. **Repository & Service Layer Implementation**:
   - Implemented methods in [`dashboard_repository.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/dashboard/repository/dashboard_repository.dart):
     - `fetchBusinessValue({double? latitude, double? longitude})`: POSTs to `merchant/business/value` with Bearer auth token and device coordinates payload.
     - `fetchPartnerInfo({double? latitude, double? longitude})`: POSTs to `merchant/partner/info` with Bearer auth token and device coordinates payload.
   - Built with error resilience returning empty models or throwing clean domain failures.

3. **Riverpod State Management & Loading Architecture**:
   - In [`dashboard_controller.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/dashboard/controller/dashboard_controller.dart):
     - `businessValueProvider`: `AutoDisposeFutureProvider<BusinessValueModel>` dynamically reading current GPS coordinates from `locationServiceProvider`.
     - `partnerInfoProvider`: `AutoDisposeFutureProvider<PartnerInfoModel>` dynamically reading current GPS coordinates from `locationServiceProvider`.
   - In [`home_body_view.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/dashboard/view/views/home_body_view.dart):
     - Pull-to-refresh invalidates both `businessValueProvider` and `partnerInfoProvider` alongside store lists.
     - Built smooth skeleton shimmer box (`_buildSkeletonBox`) when metrics are loading.
     - Utilized `AsyncValue.valueOrNull` to guarantee strict error isolation: if either metric API fails or is unreachable, the Home Screen renders zero-state values (`₹ 0`, `0`) without ever breaking or crashing the dashboard.

4. **Dynamic Data Binding & Dialogs**:
   - **Card 2 (Business Value)**:
     - Bound live `customersCount` to customer icon badge.
     - Bound live `businessValue` to `₹ {businessValue}` amount.
     - Dialog displays dynamic values and 12-month value calculation details.
   - **Card 3 (Sales Analytics)**:
     - Bound live `annualTurnover` to "Last 1 Year" (`₹ {annualTurnover}`).
     - Bound live `last30DaysTurnover` to "Last 30 Days" (`₹ {last30DaysTurnover}`).
     - Dialog displays detailed sales turnover breakdown and dynamic agency privilege bullet points.

5. **Quality & Automated Test Verification**:
   - Added automated tests in [`test/dashboard_test.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/test/dashboard_test.dart):
     - Unit tests for `BusinessValueModel` and `PartnerInfoModel` JSON deserialization.
     - Widget test for dynamic card binding with live values and dialog contents.
     - Widget test for clean error isolation when metric APIs throw errors.
   - `flutter test`: **58/58 automated tests passed**.
   - `flutter analyze`: **0 issues found (100% clean)**.

---

**Date: September 10, 2026**

### Phase 34: Guaranteed More Orders Card Design & Copy Parity

Refined the "Guaranteed More Orders" promotional scratch card banner in [`home_body_view.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/dashboard/view/views/home_body_view.dart) with pixel-accurate layout, copy, button colors, and typography:

1. **Card Container & Elevation**:
   - Clean white card (`Colors.white`) with 12px rounded corners (`BorderRadius.circular(12)`).
   - Subtle 1.0dp border (`#E9ECEF`) and soft elevation/drop shadow (`elevation: 1.5`, `shadowColor: Color(0x1F000000)`).

2. **Left Promo Icon**:
   - Circular promo badge (`assets/images/ic_guranteed_tick.png`, 56x56) with yellow/gold outer ring and green checkmark icon (`#1EA838`), plus matching circular fallback widget.

3. **Text & Description Copy Parity**:
   - Bold title: `"Guaranteed More Orders"` (`15sp`, `#212529`).
   - Subtitle: `"Enable scratch card Promotion now."` (`12sp`, `#495057`, w600).
   - Line 1: `"The scratch card promo appears first when customer open the app."` (`11sp`, `#6C757D`).
   - Line 2: `"The promo applies only if the customer scratched your promo code."` (`11sp`, `#6C757D`).
   - Discount threshold: `"20 % Discount above purchase limit ₹ 199"` with active rupee currency symbol (`₹`) in bold vibrant green (`#1EA838`).

4. **Button Styles & Colors**:
   - **Store Selector Dropdown**: Light gray pill-shaped container (`#EFF2F5`, `BorderRadius.circular(16)`), subtle border (`#DEE2E6`), dropdown indicator arrow (`Icons.keyboard_arrow_down_rounded`), and active store name text.
   - **Later Button**: Medium slate/gray rounded button (`#8F9AA3`, `BorderRadius.circular(8)`) with white text.
   - **Activate Button**: Vibrant green rounded button (`#1EA838`, `BorderRadius.circular(8)`) with bold white text.

5. **Quality & Test Verification**:
   - Updated widget test assertions in [`test/dashboard_test.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/test/dashboard_test.dart) to verify all updated copy lines and rupee symbol.
   - `flutter test`: **58/58 automated tests passed**.
   - `flutter analyze`: **0 issues found (100% clean)**.

---

**Date: September 10, 2026**

### Phase 35: Reusable PillActionButton Widget & Reordered Action Row Layout

1. **Centralized `PillActionButton` Widget in `app_button.dart`**:
   - Added [`PillActionButton`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/core/widgets/app_button.dart) to the core UI button library:
     - Uses `StadiumBorder()` for a 100% fully rounded pill-shaped curved design.
     - Supports configurable `label`, `backgroundColor`, `textColor`, `fontWeight`, `height`, and `onPressed` callbacks.
     - Centralized in [`app_button.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/core/widgets/app_button.dart) and exported across the app via [`widgets.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/core/widgets/widgets.dart).

2. **Reordered Action Row Layout**:
   - In [`home_body_view.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/dashboard/view/views/home_body_view.dart):
     - Aligned the two action buttons on the **LEFT**:
       - `Later` button: slate gray (`#8F9AA3`) fully curved pill shape.
       - `Activate` button: vibrant green (`#1EA838`) fully curved pill shape.
     - Positioned the store selector dropdown box on the **RIGHT** (`Expanded` container with light gray `#EFF2F5` background).

3. **Quality & Test Verification**:
   - Added widget unit test in [`test/dashboard_test.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/test/dashboard_test.dart) verifying `PillActionButton` stadium curve rendering and tap handling.
   - `flutter test`: **59/59 automated tests passed**.
   - `flutter analyze`: **0 issues found (100% clean)**.

---

**Date: September 10, 2026**

### Phase 36: Android Store Image Endpoint & Rating System Audit and Parity

1. **Android Legacy Code Audit (`StoresListAdapter.java` & `ListOfStoreResponse.java`)**:
   - **Store Image API Endpoint**:
     - Endpoint: `merchant/category/image?width={w}&height={h}&file={filename}&format=png`
     - Image File Selection: `private_icon` if available, falling back to `category_image`.
     - Open vs Closed Store: Standard open stores request `width=200&height=200`. Closed stores (`is_open == false`) request `width=300&height=300` and append `&is_open=false`.
     - Authentication: HTTP `GET` with Bearer auth token header (`Authorization: <accessSchema> <accessToken>`).
   - **Store Rating System & Statuses**:
     - Rating source: `store_rating.avg_rating` (formatted via `DecimalFormat("0.0")`).
     - Display Condition: Rating pill badge renders **ONLY IF** store `status == 2` (Approved Active Store) AND `avg_rating > 0.0`.
     - Store Status Codes:
       - `status == 1`: Pending / Submitted ("Waiting for Review").
       - `status == 2`: Active / Approved (Rating pill visible if `avg_rating > 0`).
       - `status == 3`: Rejected ("Rejected").
       - `status == 4`: Suspended ("Suspended").

2. **Flutter Codebase Enhancements**:
   - Updated [`StoreModel`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/dashboard/model/store_model.dart):
     - Added `privateIcon` field and `getImageUrl(baseUrl)` helper method.
     - Updated `parseRating` to inspect `store_rating['avg_rating']`.
   - Updated [`LegacyStoreGridItem`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/dashboard/view/widgets/legacy_store_grid_item.dart):
     - Configured rating badge visibility strictly when `status == 2` and `rating > 0.0`.
     - Displayed status review banners for pending (`1`), rejected (`3`), and suspended (`4`) stores.

3. **Quality & Test Verification**:
   - `flutter test`: **59/59 automated tests passed**.
   - `flutter analyze`: **0 issues found (100% clean)**.

---

**Date: September 10, 2026**

### Phase 37: Store Image Loading Root Cause Fix & Authorization Header Lifecycle

1. **Root Cause Analysis & Backend Path Confirmation**:
   - **Backend Route Path Structure**: Confirmed exact image backend endpoint path format: `https://store-devapi.bayfay.com/merchant/merchant/category/image?file={file}&width={w}&height={h}`.
   - **Premature Unauthenticated Image Fetch**: `authHeaderProvider` reads access tokens asynchronously. On initial build, `Image.network` was invoked immediately with `headers: null`, causing backend authorization failures (HTTP 401) before token retrieval completed.

2. **Technical Resolutions**:
   - **URL Generator ([`store_model.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/dashboard/model/store_model.dart))**:
     - Automatically returns `file` directly if already a full `http://` or `https://` URL.
     - Preserves the `baseUrl` path (`https://store-devapi.bayfay.com/merchant/`) and appends `merchant/category/image?file=$file...` to construct the exact backend route: `https://store-devapi.bayfay.com/merchant/merchant/category/image?file=$file&width=200&height=200`.
   - **Asynchronous Header Lifecycle**:
     - Wrapped `Image.network` in `authHeaderAsync.when(...)` to await `Authorization: Bearer <token>` retrieval before triggering image network requests.

3. **Quality & Test Verification**:
   - `flutter test test/dashboard_test.dart`: **10/10 tests passed**.
   - `flutter analyze`: **0 issues found (100% clean)**.

---

**Date: September 10, 2026**

### Phase 38: Action Row Reordering ("Guaranteed More Orders" Card)

1. **Reordered Action Row Layout**:
   - Updated `_buildGuaranteedOrderCard` in [`home_body_view.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/dashboard/view/views/home_body_view.dart):
     - **Left Side**: Store Selector Dropdown container (`#EFF2F5`), expanded directly under the circular promo icon section.
     - **Right Side**: `Later` slate gray (`#8F9AA3`) pill button and `Activate` green (`#1EA838`) pill button aligned on the far right.

2. **Quality & Test Verification**:
   - `flutter test test/dashboard_test.dart`: **10/10 tests passed**.
   - `flutter analyze`: **0 issues found (100% clean)**.

---

**Date: September 10, 2026**

### Phase 39: Store Card Widget Unification & Token Expiration Redirect to Login Screen

1. **Store Card Widget Unification**:
   - Deleted `legacy_store_grid_item.dart` and unified store card implementations into a single [`StoreCard`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/dashboard/view/widgets/store_card.dart) widget matching the Android `m_shops_list.xml` grid design.
   - Added optional `isSelected` parameter to support selection states in [`stores_dashboard_view.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/dashboard/view/views/stores_dashboard_view.dart).
   - Updated all references across [`home_body_view.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/dashboard/view/views/home_body_view.dart) and [`stores_dashboard_view.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/dashboard/view/views/stores_dashboard_view.dart).

2. **Token Error Redirect to Login Screen**:
   - Updated GoRouter redirect logic in [`app_router.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/app/router/app_router.dart):
     - Configured `AuthSessionExpired` state (triggered on token refresh failure or unauthorized API response) to redirect directly to the **Login Screen** (`AppRoutes.login`).

3. **Quality & Test Verification**:
   - `flutter test`: **59/59 automated unit and widget tests passed**.
   - `flutter analyze`: **0 issues found (100% clean)**.

---

**Date: September 10, 2026**

### Phase 40: Store Image Debug Logging & Linear Gradient Status Badge

1. **Store Image Debug Logging**:
   - Updated [`StoreCard`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/dashboard/view/widgets/store_card.dart):
     - Added `debugPrint` logs during widget build outputting `Store Name`, `Store ID`, and computed `Image URL`.
     - Added `debugPrint` exception logging in `errorBuilder` to log exact network error details if an image fails to load.

2. **Status Review Banner Gradient & Design**:
   - Replaced flat color with a rich **red-to-orange/crimson linear gradient** (`LinearGradient(colors: [Color(0xFFE52D27), Color(0xFFFF512F)])`).
   - Increased height padding (`vertical: 4.0`) and font size (`10sp`, `FontWeight.bold`, `letterSpacing: 0.2`).
   - Positioned fixed at the bottom edge of the image thumbnail container (`left: 0, right: 0, bottom: 0`) with rounded bottom corners (`BorderRadius.only(bottomLeft: Radius.circular(6), bottomRight: Radius.circular(6))`).

3. **Quality & Test Verification**:
   - `flutter test`: **59/59 automated unit and widget tests passed**.
   - `flutter analyze`: **0 issues found (100% clean)**.

---

**Date: September 10, 2026**

### Phase 41: Store Image Shimmer Loading Integration

1. **Dependency Integration**:
   - Added `shimmer: ^3.0.0` dependency to [`pubspec.yaml`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/pubspec.yaml).

2. **Smooth Shimmer Loading Placeholder**:
   - Updated [`StoreCard`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/dashboard/view/widgets/store_card.dart):
     - Added `_buildShimmerPlaceholder()` using `Shimmer.fromColors(baseColor: Color(0xFFE0E0E0), highlightColor: Color(0xFFF5F5F5))` matching card dimensions (`width: double.infinity, height: double.infinity`).
     - Displayed shimmer smoothly during image network fetch (`loadingBuilder`) and auth header retrieval (`loading:`).
     - Automatically hides shimmer instantly once network image renders.

3. **Quality & Test Verification**:
   - `flutter test`: **59/59 automated unit and widget tests passed**.
   - `flutter analyze`: **0 issues found (100% clean)**.

---

**Date: September 10, 2026**

### Phase 42: Global Session Expiration & Shimmer Wave Animation

1. **Global Session Expiration Interceptor & User-Friendly SnackBar**:
   - Enhanced [`AuthInterceptor`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/core/network/interceptors/auth_interceptor.dart):
     - Catches HTTP `401 Unauthorized` and responses containing `'Invalid Access-token'` or `'Authentication failed'`.
     - Automatically triggers token refresh or calls `setSessionExpired()`, clearing secure storage (`clearTokens()`).
   - Enhanced [`RouterNotifier`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/app/router/app_router.dart):
     - Listens to `authStateProvider` transitions to `AuthSessionExpired`.
     - Immediately redirects the user to the **Login Screen** (`AppRoutes.login`), clearing the entire screen stack.
     - Displays a brief, user-friendly floating SnackBar: `'Session Expired. Please login again.'` instead of rendering raw technical error screens or raw strings like `'Invalid Access-token'`.

2. **Animated Shimmer Wave (Glare Motion Effect)**:
   - Configured `Shimmer.fromColors` in [`StoreCard`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/dashboard/view/widgets/store_card.dart#L255-L269):
     - `baseColor: Colors.grey[300]!` (`#E0E0E0`)
     - `highlightColor: Colors.grey[100]!` (`#F5F5F5`)
     - `direction: ShimmerDirection.ltr`
     - `period: const Duration(milliseconds: 1200)`
     - Solid child widget: `Container(width: double.infinity, height: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)))`.
   - Produces a smooth animated glare sweep across store card placeholders while images load.

3. **Quality & Test Verification**:
   - `flutter test`: **59/59 automated unit and widget tests passed**.
   - `flutter analyze`: **0 issues found (100% clean)**.







---

### Phase 43: Home Page Skeleton Loading Screen

**Date: September 10, 2026**

**Objective**: Replace the `CircularProgressIndicator` spinner on the home page with a full shimmer skeleton that mirrors the actual layout while stores data loads.

#### Problem
The `storesAsync.when(loading: …)` branch showed a lone spinner centered on a blank white page — a jarring experience that gives no layout preview to the user.

#### Solution
Created `HomeSkeletonLoader` — a new self-contained widget using a **single top-level `Shimmer.fromColors`** so the glare wave sweeps all placeholders simultaneously:

| Skeleton Section | Mirrors Real Widget |
|---|---|
| 3 × gradient card placeholders (125 px row) | Header cards row |
| Card-shaped promo banner (108 px) with circular badge + text lines | Guaranteed Order card |
| Section label bar + 6-card 3×2 shimmer grid | "My Stores" grid |
| Section label bar + 3-card 3×1 shimmer grid | "External Shops" grid |

#### Files Changed

1. **[NEW] `lib/features/dashboard/view/widgets/home_skeleton_loader.dart`**:
   - `HomeSkeletonLoader` — full-page shimmer skeleton widget.
   - `_StoreCardSkeleton` — square image area + two text lines below (matches `StoreCard` shape exactly).
   - `_SkeletonBox` — reusable solid-white shimmer block (configurable `width`, `height`, `radius`).
   - Shimmer config: `baseColor: Colors.grey[300]!`, `highlightColor: Colors.grey[100]!`, `direction: ShimmerDirection.ltr`, `period: 1200ms`.

2. **[MODIFIED] `lib/features/dashboard/view/views/home_body_view.dart`**:
   - Added import for `home_skeleton_loader.dart`.
   - Replaced `loading: () => const Center(child: CircularProgressIndicator(...))` with `loading: () => const HomeSkeletonLoader()`.

#### Package Dependency
`shimmer: ^3.0.0` was already in `pubspec.yaml` — no new dependency needed.

#### Quality Verification
- `flutter analyze`: **0 issues**.
- `flutter test`: **59/59 tests passed**.

---

### Phase 45: 3-Step Store Wizard & Dedicated Location Picker Sub-screens

**Date: September 10, 2026**

**Objective**: Replicate the exact 3-step store creation wizard architecture and 3-screen dedicated location selection flow as specified in user requirements and design screenshots (Screenshots 1-4).

#### 1. Dynamic Dropdowns & Location Hierarchy (`lib/features/add_store/repository/` & `controller/`)
- Integrated dynamic Country, State, and City dropdown fetching without hardcoding:
  - Country list fetched on init (`GET merchant/location`).
  - State list fetched dynamically based on selected country (`GET merchant/location/{country}`).
  - City list populates dynamically for the selected state.
- `updateResolvedLocation(...)`: Auto-matches and pre-selects Country, State, and City dropdowns whenever an address is selected via Map or GPS.

#### 2. Multi-Step Wizard Architecture (`lib/features/add_store/view/add_store_form_screen.dart`)
Rebuilt `AddStoreFormScreen` into a managed 3-page wizard with strict validation before step advancement:
- **Page 1 (Basics, Address & Verification)** — 1:1 UI parity with Screenshot 1:
  - Store Type dropdown ("Public Shops").
  - Store Category * dropdown ("Supermarket").
  - Store Name * text input.
  - Primary Mobile Number * (+91 prefix box, `Verify` button with inline OTP modal flow).
  - Optional Secondary Number (Type dropdown: "Secondary Mobile", +91 box, `Verify` button).
  - Store Address * textarea with red caption: `To select store address click on the right side map button.`
  - Red Map Pin Icon button on right side of address box.
  - Dynamic Country *, State *, and City * dropdowns.
  - Full-width blue **Next** button.
- **Page 2 (Operations, Timing & Settings)**:
  - Operational hours, delivery radius/charges, commissions/COD/online payment options, return policies, 7-day availability chips, and full-width blue **Next** button.
- **Page 3 (Media Uploads & Final Submission)**:
  - Store Images / Logo picker (2-5 images with previews and delete buttons), Private Store toggle, Terms & Conditions checkbox, and full-width blue **Create Store** submission button.

#### 3. Dedicated Location Selection Flow (`lib/features/add_store/view/location_flow/`)
- **`select_store_location_screen.dart`** (Screenshot 2 Parity):
  - Auto Selected Current Location (Using GPS).
  - Using Google Location (Tap to Search Location).
- **`google_places_search_screen.dart`** (Screenshot 3 Parity):
  - Blue search bar header + `powered by Google` sub-header logo.
  - Real-time place prediction list resolving coordinates.
- **`confirm_store_location_screen.dart`** (Screenshot 4 Parity):
  - Full-screen `GoogleMap` widget centered on picked coordinates with red pin marker.
  - Center pin overlay graphic.
  - Dark bottom address card.
  - Full-width orange **CONFIRM** button passing resolved `ResolvedLocationPayload` back to Page 1 and auto-updating address, lat/lng, pincode, country, state, and city.

#### Quality Verification
- `flutter analyze`: **0 issues found (100% clean)**.
- `flutter test`: **59/59 automated unit and widget tests passed**.

---

### Phase 46: Layout Constraints, Error Boundaries & Form Fallback Rendering

**Date: September 10, 2026**

**Objective**: Eliminate blank white body rendering issues during initial loading/API fetch by establishing bounded layout constraints, top-level linear progress indicator, and defensive fallback defaults.

#### Key Enhancements
1. **Layout Constraints & Structure (`add_store_form_screen.dart`)**:
   - Fixed Scaffold body structure to use bounded constraints: `Column(children: [ LinearProgressIndicator(), Expanded(child: PageView(...)) ])`.
   - Removed full-screen blank loading check that previously replaced the body with a lone spinner.
2. **Defensive Metadata Fallbacks & Logging (`add_store_controller.dart`)**:
   - Added `debugPrint` logging around `loadInitialData()` and `_loadCategories()`.
   - Introduced fallback store types ("Public Shops", "Wholesale", "D2C"), fallback locations ("Ambur, Tamil Nadu"), and fallback categories ("Supermarket", "Grocery", "Others") so the form and Step 1 fields always render visibly regardless of network latency or API failures.
3. **Defensive Dropdowns (`_DropdownItem`)**:
   - Enhanced `_DropdownItem` with `isLoading` indicator support and safe item selection matching `selectedVal = hasValidValue ? value : items.first`.

#### Quality Verification
- `flutter analyze`: **0 issues found (100% clean)**.
- `flutter test`: **59/59 automated unit and widget tests passed**.

---

### Phase 47: Dropdown Synchronization & Layout Assertion Fix

**Date: September 10, 2026**

**Objective**: Fix the `!_debugDoingThisLayout` assertion and blank screen issues by synchronizing Riverpod state with dropdown value selections and eliminating layout mutation during build passes.

#### Key Enhancements
1. **Dropdown Value Matching & Hint Display (`add_store_form_screen.dart`)**:
   - Refactored `_DropdownItem` to only set `selectedVal` when `value` is non-null and exists within `items`.
   - Prevented forced fallbacks to `items.first` inside `build()` without updating underlying Riverpod state, ensuring hints ("Select Country *", "Select State *", "Select City *") display correctly.
2. **State Synchronization (`add_store_controller.dart`)**:
   - Updated `onCountryChanged` and `onStateChanged` to auto-calculate valid cascading `selectedState` and `selectedCity` values from `state.locations`.
   - Prevented mismatched or stale state references between Country, State, and City dropdowns.
3. **Automated Unit & Widget Testing (`test/add_store_test.dart`)**:
   - Created `test/add_store_test.dart` to verify `AddStoreFormScreen` UI rendering, AppBar titles, B2B mode, and model JSON parsing.

#### Quality Verification
- `flutter analyze`: **0 issues found (100% clean)**.
- `flutter test`: **64/64 automated unit and widget tests passed**.

---

### Phase 48: SliverMultiBoxAdaptor child.hasSize Assertion Fix

**Date: September 10, 2026**

**Objective**: Fix the `'package:flutter/src/rendering/sliver_multi_box_adaptor.dart': Failed assertion: line 626 pos 12: 'child.hasSize': is not true` layout exception across store grid views.

#### Key Enhancements
1. **Grid Tile Aspect Ratio Normalization**:
   - `home_body_view.dart`: Adjusted 3-column store grid `childAspectRatio` from `0.72` to `0.65` to grant adequate vertical height for store thumbnails, status review badges, and multi-line titles without exceeding grid tile bounds.
   - `home_skeleton_loader.dart`: Matched shimmer skeleton grid `childAspectRatio` to `0.65`.
   - `stores_dashboard_view.dart`: Adjusted 2-column store grid `childAspectRatio` from `0.85` to `0.76`.
2. **Flexible Column Child Scoping (`store_card.dart`)**:
   - Wrapped `store.displayName` inside a `Flexible` widget within `StoreCard`'s `Column` so text bounds adapt gracefully without breaking `SliverMultiBoxAdaptor` layout passes.

#### Quality Verification
- `flutter analyze`: **0 issues found (100% clean)**.
- `flutter test`: **64/64 automated unit and widget tests passed**.

---

### Phase 49: Reversion & Cleanup of Multi-Step Wizard & Location Flow

**Date: September 10, 2026**

**Objective**: Completely clean up and remove the 3-step store creation wizard, location flow, and form-specific helper widgets while strictly retaining `SelectStoreTypeScreen` and `WholesaleBuyerProfileScreen`.

#### Key Actions & Removals
1. **Retained Screens & Navigation**:
   - Kept `lib/features/add_store/view/select_store_type_screen.dart` and its entry point from the top bar/dashboard intact.
   - Replaced B2C, D2C, and B2B card tap navigation actions in `SelectStoreTypeScreen` with temporary floating `Feature under development` Snackbars.
   - Retained independent `WholesaleBuyerProfileScreen` navigation route.
2. **Deleted Files**:
   - `lib/features/add_store/view/add_store_form_screen.dart`
   - `lib/features/add_store/view/location_flow/` (`select_store_location_screen.dart`, `google_places_search_screen.dart`, `confirm_store_location_screen.dart`)
   - `lib/features/add_store/view/widgets/` (`delivery_section.dart`, `availability_days_row.dart`, `store_image_picker.dart`, `otp_verify_dialog.dart`)
3. **Controller & Test Cleanup**:
   - Cleaned `add_store_controller.dart` to remove wizard-specific step handling, map payload resolvers, and form controllers.
   - Updated `test/add_store_test.dart` to focus on `SelectStoreTypeScreen` UI rendering and store model JSON serializations.

#### Quality Verification
- `flutter analyze`: **0 issues found (100% clean)**.
- `flutter test`: **64/64 automated unit and widget tests passed**.

---

### Phase 50: Complete 3-Step Add Store Wizard & Native Android App Migration

**Date: September 11, 2026**

**Objective**: Deeply analyze `/Users/nishanth/Documents/BitBucket/BayFay-AI-V3/MerchantAndroidApp` (`SelectStoreType.java`, `CreateWsStoreFirstActivity.java`, `CreateWsStoreSecondActivity.java`, `CreateWsStoreSubmitActivity.java`, `StoreCreationActivity.java`, `StoreProdReplaceActivity.java`, `LocationPickActivity.java`, `PickedLocationMapsActivity.java`), extract the production Google Maps API Key, and re-implement the complete modern 3-step Add Store Wizard and location selection sub-flow in Flutter for B2C Retail (`storeKind = 0`), D2C (`storeKind = 4`), and B2B Wholesale (`storeKind = 2`).

#### Key Accomplishments & Architectural Deliverables

1. **Android Analysis & Google Maps Key Integration**:
   - Traced Google Maps API key `AIzaSyBHK4QeuEk8smdq4CQlpdDilsTxBtlwpNI` from the native Android app resources.
   - Configured `<meta-data android:name="com.google.android.geo.API_KEY" ...>` inside `android/app/src/main/AndroidManifest.xml`.

2. **Dedicated Location Picker Flow (`lib/features/add_store/view/location_flow/`)**:
   - `select_store_location_screen.dart`: Options for GPS Auto-detection and Google Places search.
   - `google_places_search_screen.dart`: Search bar with real-time geocoding predictions.
   - `confirm_store_location_screen.dart`: Full-screen `GoogleMap` centered on picked coordinates with center pin marker, camera drag reverse-geocoding, and "CONFIRM" action.
   - `picked_location_data.dart`: Strong data transfer model transferring coordinates, street, area, city, state, country, and postal code.

3. **Controller & State Management (`add_store_controller.dart`)**:
   - Dynamic location loading (`GET merchant/location`), splitting countries, states, and cities.
   - Automatic matching of Country, State, and City dropdowns from map reverse-geocoding placemarks.
   - Mobile OTP workflow (`sendOtp`, `verifyOtp`) with in-app verification dialog.
   - Robust step validation (`validateStep1`, `validateStep2`, `validateStep3`).
   - Final store submission calling `createStore`, `createOtherStore`, or `createWsStore` with multipart image payload.

4. **Modern 3-Step Wizard (`add_store_form_screen.dart`)**:
   - Step 1: Store Type, Category (with "Others" description/time), Store Name, Primary Mobile + OTP verify, Store Address with Map Pin picker, Country/State/City dropdowns, and Pincode.
   - Step 2: Delivery configurations (radius, fee, free limit), Operating hours (time pickers), Payment methods (COD + limit, Online payment), Return/Refund policy days, and Working days selector (`availability_days_row.dart`).
   - Step 3: Store images picker (`store_image_picker.dart` supporting 2–5 images), Extended delivery toggle, Private store switch, Terms & Conditions, and Store Overview summary.
   - Fully constrained layout architecture (`PageView` within `Expanded`, `SingleChildScrollView` per step) preventing any layout assertion errors.

5. **Navigation & Type Selection (`select_store_type_screen.dart`)**:
   - Connected B2C Retail (`storeKind: 0`), D2C (`storeKind: 4`), and B2B Wholesale (`storeKind: 2`) cards to launch `AddStoreFormScreen`.
   - Maintained Wholesale Buyer Profile independent route.

#### Quality Verification
- `flutter analyze`: **0 issues found (100% clean)**.
- `flutter test`: **68/68 automated tests passed**.

---

### Phase 51: Add Store Wizard Android Parity Refinements & Wholesale Flow

**Date: September 11, 2026**

**Objective**: Refine all three pages of the modern 3-step Add Store form to achieve 1:1 parity with the legacy Android app (`MerchantAndroidApp`), relocate media pickers to Page 1, integrate in-map direct search with center-pin geocoding, make Country/State/City/Pincode fully editable without dropdown restrictions, and implement wholesale-specific delivery modes, time slots, and API endpoints.

#### Key Accomplishments & Technical Details

1. **Store Media Picker Relocation to Page 1 (`StoreCreationActivity.java` Parity)**:
   - Relocated `StoreImagePicker` from Step 3 to Step 1 directly beneath the Store Name field.
   - Enforced validation requiring a minimum of 2 images and maximum of 5 images before allowing navigation to Step 2.
   - Features gallery multi-select, camera capture, thumbnail carousel preview, and delete chip actions.

2. **Fully Editable Location Mapping (Country, State, City, Pin Code)**:
   - Replaced restrictive cascading dropdowns with editable `TextField` inputs (`_countryCtrl`, `_stateCtrl`, `_cityCtrl`, `_pincodeCtrl`) bound to Riverpod state.
   - Auto-populates dynamically when confirming a location from the map or GPS, while permitting merchants to directly edit or type any field without state mismatches.
   - Formatted Pin Code with 6-digit numeric input formatters.

3. **In-Map Direct Search & Center-Pin Geocoding (`ConfirmStoreLocationScreen`)**:
   - Embedded a floating search bar directly above the interactive `GoogleMap` widget to search places/streets without navigating away.
   - Stationary center pin marker overlay with smooth camera moves and real-time reverse geocoding updating the bottom address preview card as the camera pans.
   - Floating GPS action button for rapid re-centering to device coordinates.

4. **Wholesale Store Parity (`storeKind = 2`)**:
   - Replicated business logic from `CreateWsStoreFirstActivity.java` and `CreateWsStoreSecondActivity.java`:
     - **Delivery Modes**: Selectable chips for `Shop Delivery` (1), `Delivery Associates` (2), and `Self Pickup` (3), with defaults `[2, 3]`.
     - **Pricing Defaults**: Default delivery fee ₹20 (vs ₹40 for B2C) and free delivery above ₹800 (vs ₹500 for B2C).
     - **Time Slots vs Hours**: Wholesale uses selectable delivery window chips (`10:00 AM - 01:00 PM`, `02:00 PM - 05:00 PM`, `06:00 PM - 09:00 PM`) plus a custom slot dialog (`+ Add Custom Slot`) instead of fixed opening/closing hours.
     - **API Submission**: Dispatches `POST merchant/wsshop/new` with `delivery_types` and `time_slots` via `createWsStore()`.

5. **Layout Stability & Sequential Navigation**:
   - Secured `PageView` inside an `Expanded` container with `NeverScrollableScrollPhysics()`.
   - Wrapped each step's content in a dedicated `SingleChildScrollView` keyed with `PageStorageKey` to guarantee zero viewport assertion crashes (`child.hasSize`) and preserve scroll positions.

#### Quality Verification
- `flutter analyze`: **0 issues found (100% clean)**.
- `flutter test test/add_store_test.dart`: **14/14 tests passed**.
- Full test suite `flutter test`: **73/73 tests passed (100% pass rate)**.

---

### Phase 52: Automated Location Cascading, Device GPS Pre-Fill & Image Picker Specs

**Date: September 11, 2026**

**Objective**: Implement automated location cascading APIs (`GET merchant/location` and `GET merchant/location?country={country}`), automatic device GPS location pre-population on launch, and revamped store image picker layout with thumbnails aligned on the left and 'Add Photo' button on the right, strictly enforcing 1:1 legacy Android parity with `StoreCreationActivity.java`.

#### Key Accomplishments & Technical Details

1. **Automated Location API & Cascading Logic (`StoreCreationActivity.java` Parity)**:
   - **Initial Country Call**: Automatically calls `GET merchant/location` on screen load.
   - **Default Country Selection**: Pre-selects the first country from the returned list by default (`India`).
   - **Automated Dependent Call**: Immediately queries `GET merchant/location?country={selectedCountry}` using query parameters.
   - **Default State & City Selection**:
     - Extracts unique states, sorts them alphabetically (`states.sort((a, b) => a.compareTo(b))` matching Android `Collections.sort(states, String::compareToIgnoreCase)`), and pre-selects the first state (`Tamil Nadu`).
     - Filters cities belonging to that state, pre-selects the first city (`Ambur`), and sets the city ID (`_id`).
   - **Dynamic Re-Filtering**: Selecting a different Country re-triggers the states/cities API, and selecting a State immediately updates the city list and pre-selects the first city.

2. **Device Current Location & Store Address Auto-Population**:
   - Fetches device GPS position on launch via `Geolocator.getCurrentPosition(locationSettings: ...)`.
   - Reverse geocodes coordinates to street address, postal code, state, city, and country via `geocoding` (`placemarkFromCoordinates`).
   - Automatically pre-populates `storeAddress` field, coordinates (`latitude`, `longitude`), and `pincode` field, matching corresponding dropdown values when available.
   - User can tap the map pin button anytime to manually inspect, fine-tune, or change location via `ConfirmStoreLocationScreen`.

3. **Store Image Picker Specs**:
   - **Strict Maximum Limit**: Enforced a strict limit of 5 images. Once 5 images are selected, further additions are disabled and the 'Add Photo' button is dimmed (opacity 0.4).
   - **Source Support**: Supports capturing photos directly from the device camera (`ImageSource.camera`) and multi-image picking from the gallery (`ImageSource.gallery`).
   - **UI Layout & Alignment**:
     - Selected image thumbnails are aligned on the **left side** in a smooth, horizontally scrollable array.
     - The 'Add Photo' / camera icon button remains fixed on the **right side**.
     - Compact preview sizes (70x70) with neat rounded corners and delete badges prevent overflow or layout breakage.

#### Quality Verification
- `flutter analyze`: **0 issues found (100% clean)**.
- `flutter test test/add_store_test.dart`: **17/17 tests passed**.
- Full test suite `flutter test`: **76/76 tests passed (100% pass rate)**.

---

### Phase 53: Add Store Page 1 UI & Functional Refactoring (Secondary Contact, Address & Cascading Fix)

**Date: September 11, 2026**

**Objective**: Refactor the First Page of the Add Store form (`add_store_form_screen.dart` and `add_store_controller.dart`) to resolve UI layout issues and functional discrepancies based on legacy Android app (`MerchantAndroidApp`) screenshots and layouts:

#### Key Accomplishments & Technical Details

1. **Secondary Contact Field Structure (`add_store_screen_1.xml` & `StoreCreationActivity.java` Parity)**:
   - **Section Header**: Clearly labeled as `Secondary number (Optional)`.
   - **Full-Width Type Selector**: Replaced the compact inline dropdown with a full-width dropdown container allowing selection between `Secondary Mobile` and `Landline Number`.
   - **Input Layout Behavior**:
     - **Secondary Mobile**:
       - Displays an inline `+91` prefix container (`height: 48, padding: horizontal 12`).
       - Displays `Enter Secondary Number` input field (10 digits max, numeric keyboard).
       - Displays an inline `Verify` button that initiates OTP verification via `sendSecondaryOtp()` and opens `OtpVerifyDialog`. Displays a green `Verified` badge upon verification.
     - **Landline Number**:
       - Displays two side-by-side split input fields: `Code` (STD area code, width 85) on the left, and `Enter Secondary Number` (11 digits max) on the right.
       - Hides the OTP verification button (since landlines do not receive SMS OTP).
     - **Submission Dialing Code**: Maps `secondaryDialingCode` to parsed `secCodeText` for landline numbers or `91` for mobile numbers.

2. **Full Store Address Display & Reverse Geocoding Parity**:
   - **Multi-Line Text Container**: Updated `Store address` input field to an auto-wrapping multi-line container with `minLines: 3, maxLines: 5, keyboardType: TextInputType.multiline`.
   - **Stationary Map Pin Button**: Aligned to top (`crossAxisAlignment: CrossAxisAlignment.start`) with `height: 85, width: 50`, matching the legacy Android layout (`@dimen/size85`).
   - **Complete Address Formatting**: Enhanced `fetchCurrentDeviceLocation()` to synthesize all non-empty placemark components (`name`, `street`, `subLocality`, `locality`, `subAdministrativeArea`, `administrativeArea`, `postalCode`, `country`), deduplicating consecutive identical segments. Complete addresses (e.g. `4/170, Eraniel - Thuckala Rd, Velayuthan Nagar, Padmanabhapuram, Tamil Nadu 629175, India`) now auto-populate and remain fully visible without truncation or clipping.

3. **Strict State & City Cascading Bug Fix**:
   - **Fallback Location Cleansing**: Corrected fallback data in `_loadLocations()` so that initial `cities` strictly contains cities belonging only to the selected state (`Tamil Nadu`).
   - **Controller State Synchrony**: Ensured `onCountryChanged()`, `onStateChanged()`, and `updateLocationFromMap()` filter cities strictly by `selectedState`.
   - **UI Dropdown Isolation**: In `add_store_form_screen.dart`, updated the City dropdown builder to strictly filter `allLocations` using `state.selectedState`. Cities belonging to other states (e.g., Bengaluru in Karnataka or Hyderabad in Telangana) can never appear when Tamil Nadu is selected.

#### Quality Verification
- `flutter analyze`: **0 issues found (100% clean)**.
- `flutter test test/add_store_test.dart`: **22/22 tests passed** (including new widget tests for full-width dropdown, mobile inline layout, landline split row, multi-line address, and strict city filtering).
- Full test suite `flutter test`: **81/81 tests passed (100% pass rate)**.

---

### Phase 54: Full Geocoding Address Composition & Dynamic Store Image Limit Validation

**Date: September 11, 2026**

**Objective**: Ensure complete geocoded address strings (street name, thoroughfare, subLocality, locality, etc.) are never skipped or truncated, support dynamic multiline address wrapping with `maxLines: null`, and strictly enforce the 5-image cap with dynamic remaining limit calculation and warning alerts.

#### Key Accomplishments & Technical Details

1. **Unified Geocoding Service (`geocoding_service.dart`)**:
   - **Google Maps Geocoding API First**: Direct call to `https://maps.googleapis.com/maps/api/geocode/json` using the configured API key (`AIzaSyBHK4QeuEk8smdq4CQlpdDilsTxBtlwpNI`), directly obtaining the native `results[0].formatted_address` (e.g. `4/170, Eraniel - Thuckala Rd, Velayuthan Nagar, Padmanabhapuram, Tamil Nadu 629175, India`) without intermediate loss of street or road names.
   - **Comprehensive Fallback Placemark Parser**: Appends all available non-empty components without skipping:
     `[subThoroughfare / name / street] + [thoroughfare / road name] + [subLocality / area] + [locality / town] + [subAdministrativeArea / district] + [administrativeArea / state] + [postalCode] + [country]`.
   - Token deduplication eliminates redundant prefixes while guaranteeing that specific road names (e.g. `Eraniel - Thuckala Rd`) and areas (`Velayuthan Nagar`) are preserved.
   - Unified integration across `AddStoreController.fetchCurrentDeviceLocation()`, `ConfirmStoreLocationScreen._reverseGeocode()`, and `AddStoreFormScreen._openLocationPicker()`.

2. **Dynamic Multiline Store Address Display**:
   - Updated `_addressCtrl` `TextField` in `add_store_form_screen.dart` to `minLines: 3, maxLines: null, keyboardType: TextInputType.multiline`.
   - Allows long addresses to wrap naturally across multiple lines dynamically without truncation or clipping.

3. **Dynamic Store Image Limit Validation (`store_image_picker.dart`)**:
   - **Dynamic Remaining Limit Calculation**: Calculates available slots before opening gallery: `remainingLimit = 5 - images.length`.
   - **Gallery Configuration Limit**: Passes `limit: remainingLimit` directly to `picker.pickMultiImage(limit: remainingLimit)` preventing over-selection natively.
   - **Post-Selection Safety Check & Truncation**: Truncates returned list via `.take(remainingLimit)` and alerts `Maximum 5 images allowed` if the picker returns excess items.
   - **Trigger Button State**: When `images.length == 5`, clicking "Add Photo" displays `Maximum 5 images allowed` immediately without opening the picker bottom sheet.

#### Quality Verification
- `flutter analyze`: **0 issues found (100% clean)**.
- `flutter test test/add_store_test.dart`: **24/24 tests passed**.
- Full test suite `flutter test`: **83/83 tests passed (100% pass rate)**.

---

### Phase 55: Store Images Picker Permission Handling & Startup Push Notification Prompt

**Date: September 11, 2026**

**Objective**: Implement runtime permission checks and rationale/settings dialogs for Camera and Gallery in the Add Store image picker, and trigger the native push notification permission prompt during app launch.

#### Key Accomplishments & Technical Details

1. **Push Notification Permission Prompt on App Startup (`permission_notifier_provider.dart` & `AndroidManifest.xml`)**:
   - **Manifest Verification**: Confirmed `<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />` is declared in `android/app/src/main/AndroidManifest.xml` (required for Android 13+ / API 33+).
   - **Sequential Startup Flow**: Updated `PermissionNotifier.requestFirstLaunchPermissions()` to request notification permission at runtime via `await _requestIfNotGranted(Permission.notification)`.
   - **Graceful Denial Handling**: Denials (user clicking "Don't Allow") are handled gracefully without blocking startup, enabling seamless progression into the app.
   - **On-Demand Request Helper**: Added public method `PermissionNotifier.requestNotificationPermission()` to allow re-requesting or checking notification permissions from settings or user profiles.

2. **Store Images Picker Runtime Permission Handling (`store_image_picker.dart`)**:
   - **Selection Modal**: Tapping "Add Photo" displays a bottom sheet to choose between "Take a Photo" (Camera) and "Choose from Gallery" (Gallery).
   - **Camera Permission Flow**:
     - Checks `Permission.camera.status`.
     - If granted or limited: opens the camera directly via `ImagePicker().pickImage(source: ImageSource.camera)`.
     - If not granted: requests permission at runtime via `Permission.camera.request()`.
     - If permanently denied: displays a custom `AlertDialog` explaining that camera access is required to capture store photos, with an **Open Settings** button (calling `openAppSettings()`) and a **Cancel** button.
   - **Gallery Permission Flow**:
     - For Android 13+ (API 33+): checks `Permission.photos`. For Android 12 and below: checks `Permission.storage`. For iOS: checks `Permission.photos`.
     - If granted or limited: opens the gallery directly via `ImagePicker().pickMultiImage(limit: remainingLimit)`.
     - If not granted: requests permission at runtime (photos first, with storage fallback on Android).
     - If permanently denied: displays a custom `AlertDialog` explaining that gallery access is required to select photos of the store, with **Open Settings** and **Cancel** buttons.
   - **Test Hooks**: Added optional `permissionChecker` and `onOpenSettings` parameters to `StoreImagePicker` allowing deterministic widget testing without native platform channel dependencies.

#### Quality Verification
- `flutter analyze`: **0 issues found (100% clean)**.
- `flutter test test/add_store_test.dart`: **28/28 tests passed** (verified bottom sheet, camera denial dialog, gallery denial dialog, and permission checker callback).
- `flutter test test/permission_test.dart`: **6/6 tests passed** (verified notification permission state and permanent denial detection).
- Full test suite `flutter test`: **88/88 tests passed (100% pass rate)**.

---

### Phase 56: Strict Native Geocoder Parity & Removal of HTTP Geocoding REST Call

**Date: September 11, 2026**

**Objective**: Strictly mirror the legacy Android app (`MerchantAndroidApp`) geocoding behavior by removing the HTTP Geocoding REST API call and keeping the Google Maps API key exclusively for map tile rendering.

#### Key Accomplishments & Technical Details

1. **Elimination of HTTP Geocoding Web Call (`geocoding_service.dart`)**:
   - Completely removed the `https://maps.googleapis.com/maps/api/geocode/json` HTTP network request, `Dio` dependency, and hardcoded `googleMapsApiKey` string from `geocoding_service.dart`.
   - Replaced with direct, 100% native platform geocoding via `placemarkFromCoordinates(lat, lng)`.
   - Uses `fromPlacemark()` to synthesize all non-empty components:
     `[subThoroughfare / name / street] + [thoroughfare / road name] + [subLocality / area] + [locality / town] + [subAdministrativeArea / district] + [administrativeArea / state] + [postalCode] + [country]`.
   - Matches Android's native `Address.getAddressLine(0)` without any paid web API consumption, rate-limiting, or web quota exposure.

2. **Google Maps API Key Scope Restriction (`AndroidManifest.xml`)**:
   - The Google Maps API key (`AIzaSyBHK4QeuEk8smdq4CQlpdDilsTxBtlwpNI`) remains strictly inside `android/app/src/main/AndroidManifest.xml` under `com.google.android.geo.API_KEY`, purely for native Google Maps SDK tile rendering.

#### Quality Verification
- `flutter analyze`: **0 issues found (100% clean)**.
- `flutter test test/add_store_test.dart`: **28/28 tests passed**.
- Full test suite `flutter test`: **88/88 tests passed (100% pass rate)**.

---

### Phase 57: Dynamic Slot Calculation & 5-Image Cap Safety Net Enforcement

**Date: September 11, 2026**

**Objective**: Fix the image picker selection limit and dynamic slot calculation in the Add Store form so that when images are already selected (e.g., 3/5), opening the photo picker strictly restricts selection to the remaining slots (e.g., 2), with safety net slicing in Dart and controller-level enforcement.

#### Key Accomplishments & Technical Details

1. **Dynamic Selection Limit (`store_image_picker.dart`)**:
   - Computes available slots dynamically before launching the picker:
     `final int remainingSlots = 5 - images.length;`
   - Passes `limit: remainingSlots` directly to `ImagePicker().pickMultiImage(limit: remainingSlots)` to restrict the native photo picker.

2. **Safety Net Validation & Dart Slicing (`store_image_picker.dart`)**:
   - In case legacy Android or OEM gallery pickers ignore the `limit` parameter, enforces a slice in Dart:
     `final allowedFiles = pickedFiles.take(remainingSlots).toList();`
   - Appends only `allowedFiles` to state: `final combined = [...images, ...newFiles].take(5).toList();`
   - Alerts the user with `Maximum 5 images allowed` snackbar if the user selected more than the available slots.

3. **Full State Guard & Button Disabling (`store_image_picker.dart` & `add_store_controller.dart`)**:
   - If `images.length >= 5`, the Add Photo button's opacity is reduced to `0.4` and tapping it immediately shows `Maximum 5 images allowed` without opening the bottom sheet.
   - Guarded inside `AddStoreController.setImages()`:
     `state = state.copyWith(images: imgs.take(5).toList());`

#### Quality Verification
- `flutter analyze`: **0 issues found (100% clean)**.
- `flutter test test/add_store_test.dart`: **30/30 tests passed** (including unit tests for dynamic remaining slot calculation and controller-level cap enforcement).
- Full test suite `flutter test`: **90/90 tests passed (100% pass rate)**.

---

### Phase 58: GeocodingService Relocation to Core Services

**Date: September 11, 2026**

**Objective**: Move `geocoding_service.dart` from the feature-specific directory (`lib/features/add_store/services/`) to the shared core services directory (`lib/core/services/`) so it functions as a common, app-wide utility. Clean up feature directory and update all consumer references.

#### Key Accomplishments & Technical Details

1. **Service Relocation (`lib/core/services/geocoding_service.dart`)**:
   - Moved `geocoding_service.dart` to `lib/core/services/geocoding_service.dart`.
   - Removed the now-empty `lib/features/add_store/services/` directory from the repository.

2. **Consumer Imports Updated**:
   - Updated `AddStoreController` (`add_store_controller.dart`): `import 'package:bayfay_merchant_flutter/core/services/geocoding_service.dart';`
   - Updated `ConfirmStoreLocationScreen` (`confirm_store_location_screen.dart`): `import 'package:bayfay_merchant_flutter/core/services/geocoding_service.dart';`
   - Updated Widget Test Suite (`test/add_store_test.dart`): `import 'package:bayfay_merchant_flutter/core/services/geocoding_service.dart';`

#### Quality Verification
- `flutter analyze`: **0 issues found (100% clean)**.
- `flutter test test/add_store_test.dart`: **30/30 tests passed**.
- Full test suite `flutter test`: **90/90 tests passed (100% pass rate)**.

---

### Phase 59: Native Android PhotoPicker UI Limit Enforcement & Single Slot Handling

**Date: September 11, 2026**

**Objective**: Fix the native system gallery picker UI allowing selection of over 5 images (e.g. choosing 9 items on first attempt, or selecting over 3 items when 2 are already chosen) by enabling the modern Android Photo Picker (`useAndroidPhotoPicker = true`), handling single-slot picks cleanly, and enforcing strict slice safety nets.

#### Root Cause Identified
In the Flutter `image_picker_android` plugin, the `useAndroidPhotoPicker` flag defaults to `false`. When `false`, Android launches the legacy `Intent.ACTION_GET_CONTENT` gallery intent, which has no native selection limit extra, allowing users to select unlimited checkboxes (9, 10, etc.) in the gallery UI regardless of the `limit` parameter passed.

#### Key Accomplishments & Technical Details

1. **Android PhotoPicker Activation (`main.dart` & `store_image_picker.dart`)**:
   - Explicitly configured `ImagePickerAndroid.useAndroidPhotoPicker = true`.
   - On Android devices (Android 11+ via Google Play Services or Android 13+ natively), Android now invokes `ActivityResultContracts.PickMultipleVisualMedia(limit)`.
   - The native Google Android Photo Picker UI **physically restricts the number of selectable checkboxes** to `limit`, displaying *"Select up to N items"* and preventing selecting more items in the UI.

2. **Single Slot Edge-Case Handling (`remainingSlots == 1`)**:
   - Handled Android SDK constraint where `PickMultipleVisualMedia` requires `limit >= 2`.
   - When 4 images are already added (`remainingSlots == 1`), `StoreImagePicker` switches to `picker.pickImage(source: ImageSource.gallery)`, opening the single-photo selection interface where only 1 image can ever be chosen.

3. **Multi-Layer Safety Net Truncation & Controller Guard**:
   - In Dart, slices `pickedFiles.take(remainingSlots)` and appends to existing images with `.take(5)`.
   - Guarded inside `AddStoreController.setImages(imgs.take(5).toList())`.
   - Disabled Add Photo button when full ($5/5$) with `Maximum 5 images allowed` snackbar.

#### Quality Verification
- `flutter analyze`: **0 issues found (100% clean)**.
- `flutter test test/add_store_test.dart`: **30/30 tests passed**.

---

### Phase 60: Clean Revert of Platform-Specific Image Picker Flags

**Date: September 11, 2026**

**Objective**: Revert the platform-specific `image_picker_android` configuration and dependency additions at user request, returning the codebase to a clean, stable state.

#### Actions Taken
1. **Reverted `pubspec.yaml`**: Removed `image_picker_android` and `image_picker_platform_interface` additions, preserving clean cross-platform `image_picker: ^1.1.2`.
2. **Reverted `lib/main.dart`**: Removed `image_picker_android` imports and initialization calls.
3. **Reverted `lib/features/add_store/view/widgets/store_image_picker.dart`**:
   - Removed platform-specific imports.
   - Cleaned `_pickImage()` to use standard `ImagePicker.pickMultiImage(limit: remainingSlots)` with Dart-level `take(remainingSlots)` safety net and `take(5)` cap.
4. **Dependency Sync & Test Verification**:
   - Executed `flutter pub get`.
   - Executed `flutter analyze`: **0 issues found**.
   - Executed `flutter test`: **90/90 tests passed (100% pass rate)**.

---

### Phase 61: Reinstated Android PhotoPicker Configuration & UI Limit Enforcement

**Date: September 11, 2026**

**Objective**: Bring back the Android PhotoPicker configuration and UI limit enforcement per user request.

#### Actions Taken
1. **Restored Dependencies (`pubspec.yaml`)**:
   - Added `image_picker_android: ^0.8.13+1` and `image_picker_platform_interface: ^2.10.0`.
2. **Restored `lib/main.dart`**:
   - Re-enabled `ImagePickerAndroid.useAndroidPhotoPicker = true` during application initialization.
3. **Restored `lib/features/add_store/view/widgets/store_image_picker.dart`**:
   - Re-enabled modern Android Photo Picker configuration.
   - Restored single-slot edge-case handling (`remainingSlots == 1` invokes `pickImage(source: ImageSource.gallery)` to enforce selecting strictly 1 image).
   - Maintained `limit: remainingSlots` and Dart `.take(remainingSlots)` safety net.
4. **Verification**:
   - `flutter pub get`: Succeeded.
   - `flutter analyze`: **0 issues found**.
   - `flutter test`: **90/90 tests passed (100% pass rate)**.

---

### Phase 62: Alphabetical (A to Z) Sorting & Robust Selection for City/District Dropdown

**Date: September 11, 2026**

**Objective**: Ensure all cities/districts in the Add Store form dropdown are sorted in case-insensitive alphabetical order (A to Z) so users can locate their city quickly, while preserving state/country cascading and selection integrity without dropdown mismatch exceptions.

#### Key Accomplishments & Technical Details

1. **Controller-Level Sorting (`lib/features/add_store/controller/add_store_controller.dart`)**:
   - Applied case-insensitive alphabetical sort (`..sort((a, b) => a.city.toLowerCase().compareTo(b.city.toLowerCase()))`) across all city resolution points:
     - `_loadLocations()`: Automatically sorts cities for the default state.
     - `fetchCurrentDeviceLocation()`: Sorts cities when pre-filling from device GPS coordinates.
     - `onCountryChanged()`: Sorts cities for the newly selected country's initial state.
     - `onStateChanged()`: Sorts cities whenever the user chooses a different state.
     - `updateLocationFromMap()`: Sorts cities when returning from map drag pin or Google Places search.

2. **UI & Dropdown Binding (`lib/features/add_store/view/add_store_form_screen.dart`)**:
   - In the City Dropdown `Builder`:
     - Deduplicates items by unique ID / lowercase city name to prevent duplicate `DropdownMenuItem` keys.
     - Sorts `uniqueCities` alphabetically from A to Z case-insensitively: `a.city.toLowerCase().compareTo(b.city.toLowerCase())`.
     - Preserves current selection safely using `uniqueCities.firstWhere(...)` (matching by id or city name) so the dropdown value is guaranteed to exist in `items`, preventing dropdown assertion or mismatch crashes.

3. **Quality & Test Verification**:
   - Added unit and regression test in `test/add_store_test.dart` verifying that jumbled city lists from the API (e.g. Vellore, chennai, Ambur, Coimbatore, madurai) are strictly sorted to `['Ambur', 'chennai', 'Coimbatore', 'madurai', 'Vellore']`, pre-select the first alphabetical city, and retain correct selection upon user change or map update.
   - `flutter analyze`: **0 issues found**.
   - `flutter test`: **91/91 tests passed (100% pass rate)**.

---

### Phase 63: Full Address Assembly Order & District/City Mapping Parity

**Date: September 11, 2026**

**Objective**: Fix the native geocoder address assembly in `GeocodingService` so neighborhood/area names (`placemark.subLocality` e.g., Velayuthan Nagar) and building names (`placemark.name`) are never skipped or dropped, and fix the city mapping logic so that district names (`placemark.subAdministrativeArea` e.g., Kanyakumari) correctly map to available state cities.

#### Key Accomplishments & Technical Details

1. **Address Token Assembly & Preservation (`lib/core/services/geocoding_service.dart`)**:
   - Preserved the original clean `addToken()` function architecture.
   - Fixed token order to prevent `subLocality` (e.g. `Velayuthan Nagar`) from being dropped or misordered:
     - `addToken(p.subThoroughfare)`: Door / Plot number.
     - `addToken(p.name)`: Building/Plot name only if distinct from thoroughfare, subLocality, and locality.
     - `addToken(p.thoroughfare)` (falling back to `p.street` if empty): Street / road name.
     - `addToken(p.subLocality)`: Neighborhood / Area name (`Velayuthan Nagar`).
     - `addToken(p.locality)`: Town / City (`Padmanabhapuram`).
     - `addToken(p.subAdministrativeArea)`: District (`Kanyakumari`).
     - `addToken(p.administrativeArea)`: State (`Tamil Nadu`).
     - `addToken(p.postalCode)`: Postal code (`629175`).
     - `addToken(p.country)`: Country (`India`).
   - Retained `district` in `GeocodingResult` for intelligent database city mapping.

2. **Intelligent District & City Resolution (`lib/features/add_store/controller/add_store_controller.dart`)**:
   - In both `fetchCurrentDeviceLocation()` and `updateLocationFromMap()`:
     - Step 1: Exact match with `locality` (town/city).
     - Step 2: Exact match with `district` / `subAdministrativeArea` (resolving e.g. Padmanabhapuram town to Kanyakumari district).
     - Step 3: Substring match within `district`, `city`, or `area`.
     - Step 4: Substring match within the complete `formattedAddress`.
     - Step 5: Graceful fallback to first alphabetical city in the state if unmatched.

3. **Quality & Test Verification**:
   - Added unit test in `test/add_store_test.dart` verifying complete address formatting: `'12, Plot 10, Eraniel - Thuckala Road, Velayuthan Nagar, Padmanabhapuram, Kanyakumari, Tamil Nadu, 629175, India'` and ensuring `subLocality` (Velayuthan Nagar) is preserved.
   - Verified that `updateLocationFromMap()` maps the location to the district city (`Kanyakumari`) in the database.
   - `flutter analyze`: **0 issues found (100% clean)**.
   - `flutter test`: **92/92 tests passed (100% pass rate)**.

---

### Phase 64: Google Places Autocomplete Integration, Rich Sublocality Reverse Geocoding & District Normalization Matching

**Date: September 11, 2026**

**Objective**: Parity with native Android app (`AutocompleteActivity` / `LocationPickActivity` / `AddStoreActivity`):
1. Resolve Google Places Autocomplete predictions in the Map search screen so querying a place (e.g. "Thuckalay") yields rich POI predictions ("Thuckalay Bus Stand", "Thuckalay Courts", "Thuckalay Police Station") rather than on-device geocoder single-result coordinates.
2. Ensure reverse geocoding retrieves complete sublocality neighborhood details (`Velayuthan Nagar`) via Google Maps Geocoding REST API with offline fallback.
3. Add `district` tracking to `PickedLocationData` and implement spelling variation normalization (e.g. `Kanniyakumari` <-> `Kanyakumari`) in `AddStoreController` to prevent falling back to `Ambur`.

#### 1. Implementation Details

1. **Centralized Google Maps / Places API Key & Places Service (`lib/core/constants/app_constants.dart`, `android/app/build.gradle.kts` & `lib/core/services/places_service.dart`)**:
   - Centralized `googleMapsApiKey = 'AIzaSyBHK4QeuEk8smdq4CQlpdDilsTxBtlwpNI'` inside `AppConstants`.
   - **Dynamic AndroidManifest Injection**: In `android/app/build.gradle.kts`, Gradle dynamically parses `googleMapsApiKey` from `lib/core/constants/app_constants.dart` and sets it in `manifestPlaceholders["googleMapsApiKey"]`.
   - In `android/app/src/main/AndroidManifest.xml`, configured `<meta-data android:name="com.google.android.geo.API_KEY" android:value="${googleMapsApiKey}" />` so the native Android SDK directly consumes the key from `app_constants.dart` as the single source of truth.
   - Removed hardcoded key strings from `PlacesService` and `GeocodingService`, referencing `AppConstants.googleMapsApiKey` directly for all Google Places and Geocoding REST requests.
   - `autocomplete(query)`: Queries `https://maps.googleapis.com/maps/api/place/autocomplete/json` with `components=country:in`.
   - Strictly enforces minimum 3 characters (`if (trimmed.length < 3) return [];`), eliminating redundant network calls for short/empty queries.
   - `getPlaceDetails(placeId)`: Queries `https://maps.googleapis.com/maps/api/place/details/json` for coordinates (`geometry.location.lat`, `lng`), `formatted_address`, and `address_components` (door, route, sublocalities, locality, district, state, country, postal code).

2. **Google Places Search Screen (`lib/features/add_store/view/location_flow/google_places_search_screen.dart`)**:
   - Replaced on-device `locationFromAddress` with debounced (350ms) calls to `PlacesService.autocomplete(query)`.
   - Added minimum 3-character check in `_onQueryChanged` and `_searchPlaces` to immediately clear existing suggestions and skip API calls when `< 3` characters.
   - **Integrated Clear ('X') Icon**: Moved the clear button inside the bordered search input box using `InputDecoration.suffixIcon` on a rounded container (`BoxDecoration(color: Color(0xFFF5F5F5), borderRadius: 8, border: Color(0xFFE0E0E0))`), removing the external AppBar actions button.
   - Added platform Geocoder fallback if Google Autocomplete is offline or returns empty.
   - Renders results matching native Android UI: location pin icon, bold `main_text`, subtle `secondary_text`, and bottom "powered by Google" branding indicator.
   - On tap: resolves exact details via `PlacesService.getPlaceDetails()` and navigates to `ConfirmStoreLocationScreen` (or pops directly when `returnDirectly: true`).

3. **Map Screen Duplicate Search Action Removal (`lib/features/add_store/view/location_flow/confirm_store_location_screen.dart`)**:
   - Removed duplicate `IconButton(icon: Icon(Icons.search), onPressed: _openSearch)` from `AppBar.actions`.
   - Retained the floating search card situated directly on top of the interactive Google Map.

4. **Rich Reverse Geocoding with Sublocality (`lib/core/services/geocoding_service.dart`)**:
   - In `reverseGeocode(lat, lng)`, queries Google Maps Geocoding REST API (`https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$key`) first to extract sublocalities like `Velayuthan Nagar` (`sublocality_level_2`).
   - Gracefully falls back to device native `placemarkFromCoordinates(lat, lng)` on network failure or offline mode.
   - Retains full address assembly preserving door number, name, street/thoroughfare, sublocality, locality, district, state, pin code, and country.

5. **District Tracking in Location Models (`lib/features/add_store/model/picked_location_data.dart` & `confirm_store_location_screen.dart`)**:
   - Added `final String district;` (default `''`) to `PickedLocationData` and its equality comparison props.
   - `ConfirmStoreLocationScreen` tracks `_district` from reverse geocoding or search and forwards it in `_onConfirm()`.

6. **District Normalization & Matching Logic (`lib/features/add_store/controller/add_store_controller.dart`)**:
   - Added static helper `_matchesCityOrDistrict(locationCity, target)`:
     - Handles case-insensitivity and substring containment.
     - Maps Indian district alias variations: `kanniyakumari` <-> `kanyakumari`, `trichy` <-> `tiruchirappalli`, `tanjore` <-> `thanjavur`, `tuticorin` <-> `thoothukudi`, `bengaluru` <-> `bangalore`, etc.
     - Normalizes phonetic spelling variants (`nniya` <-> `nya`, removing non-alphanumerics).
   - Applied in both `fetchCurrentDeviceLocation()` and `updateLocationFromMap()`:
     - Step 1: Match `locality` / `city`.
     - Step 2: Match `district` (e.g. `Kanniyakumari` matching `Kanyakumari` in the database).
     - Step 3: Match `area`.
     - Step 4: Match within full `formattedAddress`.
     - Step 5: Fallback across all locations.
   - Resolves the issue where locations with `Kanniyakumari` district previously defaulted to the first alphabetical city (`Ambur`).

#### 2. Quality Verification & Automated Testing

- **Unit & Regression Tests Added (`test/add_store_test.dart`)**:
  - `PlacesService PlacePrediction and PlaceDetails model parsing`: verifies parsing of predictions ("Thuckalay Bus Stand") and details containing "Velayuthan Nagar".
  - `Kanniyakumari spelling variation matches Kanyakumari without falling back to Ambur`: verifies that `Kanniyakumari` maps to `Kanyakumari` (`loc_kk`) instead of `Ambur`.
  - `PlacesService.autocomplete does not trigger request when input has less than 3 characters`: verifies inputs `''`, `'a'`, `'th'`, `'  ab  '` return empty without API calls.
- **Verification Results**:
  - `flutter analyze`: **0 issues found (100% clean)**.
  - `flutter test test/add_store_test.dart`: **35/35 tests passed (100%)**.
  - Full test suite `flutter test`: **95/95 tests passed (100% pass rate)**.

---

### Phase 65: OTP Dialog Layout Modernization & Complete AppStrings Centralization

**Date: September 11, 2026**

**Objective**:
1. Modernize `OtpVerifyDialog` layout:
   - Position 'Resend OTP' directly below the 6-digit OTP input box, styled with an underline link (`TextDecoration.underline`).
   - Change vertical actions into horizontal side-by-side buttons inside a `Row`: **Verify** on the Left and **Cancel** on the Right, with equal width using `Expanded`.
2. Centralize hardcoded strings into `AppStrings` across Add Store and related features to ensure maintainability and support future localization.

#### 1. Implementation Details

1. **OTP Verification Dialog Layout & Styling (`lib/features/add_store/view/widgets/otp_verify_dialog.dart`)**:
   - **Resend OTP Link**: Replaced the separate action text with an `InkWell` directly beneath the OTP input field, styled with blue color (`#1976D2`), `FontWeight.w600`, and `TextDecoration.underline` with matching `decorationColor`.
   - **Horizontal Side-by-Side Action Buttons**:
     - Placed inside `actionsPadding: EdgeInsets.fromLTRB(16, 0, 16, 16)`.
     - Uses a `Row` with `Expanded` widgets to give equal width.
     - **Left button**: `OutlinedButton` for `AppStrings.cancel` (subtle border `#BDBDBD`, grey text `#757575`, semi-bold).
     - **Right button**: `ElevatedButton` for `AppStrings.verify` (primary color `#1976D2`, bold text, white foreground, loading spinner when busy).

2. **Centralized AppStrings Expansion (`lib/core/constants/app_strings.dart`)**:
   - Added centralized string constants:
     - Common Actions: `verify = 'Verify'`, `resendOtp = 'Resend OTP'`.
     - OTP Dialog: `verifyMobileNumber`, `enterValidOtp`, `enterNumericOtp`, `invalidOtpTryAgain`, `otpResentSuccessMsg`, `weHaveSentCodeTo`.
     - Mobile Verification & Add Store: `primaryMobileVerifiedSuccess`, `secondaryMobileVerifiedSuccess`, `enterValidPrimaryMobile`, `enterValidSecondaryMobile`, `storeCreatedTitle`, `storeCreatedDesc`, `storeCreationFailed`.
     - Store Titles: `addStoreTitle`, `addWholesaleStoreTitle`, `addD2CStoreTitle`, `createDigitalStore`, `selectStoreType`, `chooseStoreTypeSubtitle`.
     - Store Kinds: `b2cRetail`, `b2cRetailSubtitle`, `d2c`, `d2cSubtitle`, `b2bWholesale`, `b2bWholesaleSubtitle`, `buyFromWholesale`, `buyFromWholesaleSubtitle`.
     - Wizard Steps: `storeInfoStep`, `operationsStep`, `mediaSubmitStep`.
     - Location & Map: `confirmStoreLocationTitle`, `searchLocationHint`, `searchStreetAreaLandmark`, `searchByStreetAreaLandmark`, `noLocationsFound`, `poweredByGoogle`, `moveMapToPlacePin`, `selectedStoreAddress`, `resolvingAddress`, `locatingAddress`, `confirmUpper`.
     - Media Picker: `maxImagesAllowed`, `takePhoto`, `chooseFromGallery`, `addPhoto`, `storeImagesTitle`, `storeWorkingDaysTitle`, `cameraPermissionRequiredTitle`, `cameraPermissionRequiredMsg`, `galleryPermissionRequiredTitle`, `galleryPermissionRequiredAndroidMsg`, `galleryPermissionRequiredIosMsg`.

3. **String Replacements Across Add Store Features**:
   - `lib/features/add_store/view/widgets/otp_verify_dialog.dart`: Fully replaced all dialog titles, hints, errors, snackbars, and button labels with `AppStrings`.
   - `lib/features/add_store/view/widgets/store_image_picker.dart`: Replaced permission titles, rationales, button labels ("Open Settings", "Cancel"), snackbar alerts, bottom sheet options, and titles with `AppStrings`.
   - `lib/features/add_store/view/widgets/availability_days_row.dart`: Replaced section header with `AppStrings.storeWorkingDaysTitle`.
   - `lib/features/add_store/view/widgets/step_indicator.dart`: Replaced step titles with `AppStrings.storeInfoStep`, `AppStrings.operationsStep`, `AppStrings.mediaSubmitStep`.
   - `lib/features/add_store/view/select_store_type_screen.dart`: Replaced AppBar title, header, subtitle, and all 4 card titles/subtitles with `AppStrings`.
   - `lib/features/add_store/view/location_flow/google_places_search_screen.dart`: Replaced search input hint, empty state messages, and Google attribution with `AppStrings`.
   - `lib/features/add_store/view/location_flow/confirm_store_location_screen.dart`: Replaced AppBar title, search card placeholder, map pin overlay instructions, address status indicators, and uppercase "CONFIRM" button label with `AppStrings`.
   - `lib/features/add_store/view/add_store_form_screen.dart`: Replaced success dialog title/description/button, creation failure message, mobile validation error messages, verified snackbars, and dynamic page titles with `AppStrings`.

#### 2. Quality Verification & Automated Testing

- **Widget & Layout Tests Added (`test/add_store_test.dart`)**:
  - Added test `'OtpVerifyDialog renders Resend OTP link with underline and horizontal Cancel (Left) Verify (Right) buttons'`:
    - Verifies Resend OTP text has `TextDecoration.underline`.
    - Verifies tapping Resend OTP executes the `onResend` callback.
    - Verifies horizontal layout in `Row` where `cancelCenter.dx < verifyCenter.dx` (Cancel on the Left, Verify on the Right).
    - Verifies numeric submission of OTP executes `onVerify`.
- **Verification Results**:
  - `flutter analyze`: **0 issues found (100% clean)**.
  - `flutter test test/add_store_test.dart`: **36/36 tests passed (100%)**.
  - Full test suite `flutter test`: **96/96 tests passed (100% pass rate)**.

---

### Phase 66: Temporary Bypass of Step 1 Form Validation

**Date: September 11, 2026**

**Objective**: Allow rapid navigation and testing of Page 2 (Operations) by temporarily bypassing Step 1 validation checks when tapping the "Next" button on Page 1 (Store Info).

#### 1. Implementation Details
- In [`lib/features/add_store/view/add_store_form_screen.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/add_store/view/add_store_form_screen.dart):
  - In `_onNextPressed()`:
    - Commented out the `validateStep1()` barrier when `state.currentStep == 0`.
    - Directly executes `_goToStep(1)` so users can freely navigate to Step 2 without needing to pre-fill store name, primary mobile number, images, or map coordinates during development and testing.
    - Preserved the full validation logic (`validateStep1()`) in `AddStoreController` ready to be re-enabled at any time.

#### 2. Quality Verification & Automated Testing
- **Test Updated (`test/add_store_test.dart`)**:
  - Updated widget test to verify tapping "Next" on Page 1 immediately advances to Page 2 ("Operations").
- **Verification Results**:
  - `flutter analyze`: **0 issues found (100% clean)**.
  - `flutter test test/add_store_test.dart`: **36/36 tests passed (100%)**.
  - Full test suite `flutter test`: **96/96 tests passed (100% pass rate)**.

---

### Phase 67: Retention of Verify Button UI with Mocked/Bypassed OTP Network API

**Date: September 11, 2026**

**Objective**: Keep the complete Verify Button and OTP verification UI fully interactive and visible across the Add Store form, while strictly bypassing the backend OTP network API calls (`_repo.sendOtp`, `_repo.verifyOtp`) so testing and store creation can proceed smoothly without SMS delays or network dependencies.

#### 1. Implementation Details
1. **Full Verification UI Kept Intact ([`add_store_form_screen.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/add_store/view/add_store_form_screen.dart))**:
   - The "Verify" button and "Verified" badge are rendered unconditionally next to both the Primary Mobile Number and Secondary Mobile Number fields.
   - Tapping "Verify" validates the 10-digit input and opens the modernized `OtpVerifyDialog` with the Resend OTP link and horizontal Cancel/Verify buttons.
   - Verification callbacks (`_verifyPrimaryMobile` and `_verifySecondaryMobile`) are active and trigger local verification success, displaying the green success snackbar upon completion.
2. **OTP API Calls Bypassed in Controller ([`add_store_controller.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/add_store/controller/add_store_controller.dart))**:
   - Introduced feature toggle:
     ```dart
     static const bool _bypassOtpApi = true;
     ```
   - In `sendPrimaryOtp()` & `sendSecondaryOtp()`: When `_bypassOtpApi` is enabled, returns `'OTP sent successfully'` immediately without invoking `_repo.sendOtp()`.
   - In `verifyPrimaryOtp()` & `verifySecondaryOtp()`: When `_bypassOtpApi` is enabled, sets `isPrimaryVerified: true` / `isSecondaryVerified: true` in state and returns `true` without invoking `_repo.verifyOtp()`.
   - In `submitStore()`: Passes `primaryVerified: _bypassOtpApi ? true : state.isPrimaryVerified` so store creation is never blocked.
   - To re-enable live network OTP calls, simply flip `_bypassOtpApi = false`.

#### 2. Quality Verification & Automated Testing
- **Tests Synchronized ([`test/add_store_test.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/test/add_store_test.dart))**:
   - Widget tests verify the Verify buttons are rendered in the UI (2 Verify buttons when secondary is mobile, 1 Verify button when secondary is landline).
- **Verification Results**:
   - `flutter analyze`: **0 issues found (100% clean)**.
   - `flutter test test/add_store_test.dart`: **36/36 tests passed (100%)**.
   - Full test suite `flutter test`: **96/96 tests passed (100% pass rate)**.

---

### Phase 68: Custom Native & Flutter Splash Screen Architecture (Android, iOS & Smooth Initialization)

**Date: September 12, 2026**

**Objective**: Completely replace the default Flutter splash screen with a custom-branded splash screen across Android and iOS native layers, and ensure a seamless, zero-flicker transition into the Flutter application.

#### 1. Android Native Splash Setup
1. **`launch_background.xml` Configuration (`res/drawable/` & `res/drawable-v21/`)**:
   - Replaced default blank/Flutter template layer-list with custom background color (`@android:color/white`) and centered custom logo bitmap (`@drawable/splash_logo` or `@mipmap/ic_launcher`).
   - Added secondary bottom branding (`@drawable/power_by`) with bottom gravity.
2. **`styles.xml` Configuration (`res/values/` & `res/values-night/`)**:
   - Configured `LaunchTheme` with `android:windowBackground="@drawable/launch_background"` and `android:windowFullscreen="false"`.
   - Added Android 12+ (API 31+) SplashScreen compatibility (`android:windowSplashScreenBackground` and `android:windowSplashScreenAnimatedIcon`).
   - Preserved `NormalTheme` transition via `io.flutter.embedding.android.NormalTheme` metadata in `AndroidManifest.xml`.

#### 2. iOS Native Splash Setup
1. **Asset Catalog (`Assets.xcassets/LaunchImage.imageset`)**:
   - Replaced default Flutter placeholder assets with custom 1x, 2x, and 3x brand logo files.
2. **`LaunchScreen.storyboard` Layout**:
   - Configured root view background color to match Flutter theme (`#FFFFFF`).
   - Configured `UIImageView` with AutoLayout constraints (`centerX`, `centerY`) and set `contentMode="scaleAspectFit"` to prevent distortion across all device form factors.

#### 3. Seamless Flutter Initialization & Transition
1. **Visual Parity Between Native & Flutter Routes**:
   - Matched `SplashScreen` in `lib/features/splash/view/splash_screen.dart` pixel-for-pixel with native splash layouts.
2. **Asynchronous Pre-Warming & Guarded Delay**:
   - Initialized device tokens, validated auth state, and ran permission checks during the splash phase.
   - Enforced an intentional minimum display duration (1200ms) to eliminate flickering before routing to Welcome, Login, or Dashboard.

---

### Phase 69: Step 2 (Operations) Form Refinement & Legacy Business Parity

**Date: September 12, 2026**

**Objective**: Refine the Step 2 (Operations) screen in `AddStoreFormScreen` to integrate all legacy Android business fields while retaining modern component styling, and standardize compact input field heights matching the Login / Register form standards.

#### 1. Business Fields & Legacy Parity Implementation
1. **Store Availability (Operating Days: Sunday to Saturday)**:
   - Reordered `AvailabilityDaysRow` ([`lib/features/add_store/view/widgets/availability_days_row.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/add_store/view/widgets/availability_days_row.dart)) so the week begins with **Sunday** through **Saturday** (`['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']`), matching legacy Android `add_store_screen_2.xml` (`check_sunday` through `check_saturday`).
   - Retained modern rounded filter chips with active brand blue highlight (`#1976D2`) and day counters.
2. **Delivery / Shipping Details Integration**:
   - **Max Delivery Radius**: Dropdown selector in standardized 44px container (`5 km`, `10 km`, `15 km`, `20 km`, `30 km`, `50 km`).
   - **Delivery charge up to 2 km**: Numeric input field with helper text: `'Applicable for less than minimum purchase limit'` (matching legacy `edit_delivery`).
   - **Minimum purchase limit**: Numeric input field with label `'Minimum purchase limit (₹)'` and hint `'Minimum Purchase Amount'` (matching legacy `edit_limit`).
   - **Delivery charge per km**: Numeric input field with helper text: `'After 2 km this charge will be applicable'` (matching legacy `edit_delivery_per_km_etxt`).
   - **Subscription Order Delivery Charge**: Toggle switch with label `'Delivery charge applicable for subscription order?'` and subtitle `'Apply delivery fees to recurring subscription orders'` (matching legacy `delivery_charge_switch`).
   - **Delivery Fulfillment Modes**: Checkbox list tiles for *Own Delivery / Shop Delivery*, *Delivery Associates (3rd Party)*, and *Self Pickup / Customer Takeaway*.
3. **Cash on Delivery (COD) Configuration**:
   - SwitchListTile for enabling/disabling COD.
   - When enabled, displays limit type dropdown (`'Any Amount'` vs `'Apply Max Limit'`) and numeric input field for maximum COD amount (`Max COD ₹`) when limit is selected.
4. **Operating / Delivery Hours**:
   - For retail/D2C stores: Side-by-side Opening Time and Closing Time pickers in uniform 44px containers with clock icons.
   - For wholesale stores: Delivery time slot chips with dialog to add custom slots.
5. **Return & Refund Policies**:
   - Product Replacement and Refund Policy dropdowns in uniform 44px containers.

#### 2. Compact Input Field Heights & Typography Standards
1. **`_inputDecoration` Normalization**:
   - Configured `isDense: true` and `contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11)` matching Login and Register form standards.
   - Added support for red italic helper text (`helperStyle: const TextStyle(fontSize: 11, color: Color(0xFFD32F2F), fontStyle: FontStyle.italic)`).
2. **Standardized Container Heights (44px)**:
   - All dropdown containers (Radius, COD limit type, Product replacement, Refund policy) and time picker boxes are standardized to `height: 44` with `BorderRadius.circular(10)` and border color `#D0D7DE`.
   - `DropdownButton` configured with `isDense: true` to prevent internal padding expansion.
3. **Controller Synchronization**:
   - Enhanced `_syncControllersWithState()` to populate `_deliveryFeeCtrl`, `_feeLimitCtrl`, `_perKmFeeCtrl`, and `_codLimitCtrl` cleanly from state without resetting cursor positions during typing.

#### 3. Quality Verification & Automated Testing
- **Tests Added ([`test/add_store_test.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/test/add_store_test.dart))**:
  - Verified `AvailabilityDaysRow` starts with Sunday and ends with Saturday with 7 total days.
  - Verified widget rendering of all Step 2 business fields:
    - `Delivery / Shipping Details` section header
    - `Max Delivery Radius (km) *`
    - `Delivery charge up to 2 km (₹)` with `Applicable for less than minimum purchase limit` helper text
    - `Minimum purchase limit (₹)` with `Minimum Purchase Amount` hint
    - `Delivery charge per km (₹)` with `After 2 km this charge will be applicable` helper text
    - `Delivery charge applicable for subscription order?` toggle switch
    - `Cash on Delivery (COD)` configuration
    - `Return & Refund Policies`
    - Operating days chips (`Sun` through `Sat`)
- **Verification Results**:
  - `flutter analyze`: **0 issues found (100% clean)**.
  - `flutter test test/add_store_test.dart`: **38/38 tests passed (100%)**.
  - Full test suite `flutter test`: **98/98 tests passed (100% pass rate)**.

---

### Phase 70: Step 2 Operations Exact Field Labels, Defaults & Density Optimization

**Date: September 12, 2026**

**Objective**: Update the Step 2 (Operations) screen in `AddStoreFormScreen` with exact field labels, defaults (delivery fee 20, distance 5 km), 1-10 km dropdown list, clean vertical fulfillment checkboxes, From/To delivery timings, Any/Limit COD options, clearable fields accepting 0, and native compact density (`isDense: true`, `EdgeInsets.symmetric(horizontal: 12, vertical: 10)`).

#### 1. Implementation Details
1. **Section Header & Max Delivery Distance**:
   - Header updated to `'Delivery and Shipping Details (Nearby locations)'` in [`AppStrings`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/core/constants/app_strings.dart).
   - Label updated to `'Max delivery distance: *'`.
   - Dropdown options strictly populated with integers from `1 km` to `10 km` (`1 km`, `2 km`, ... `10 km`), removing old 5/10/15 interval list.
   - Default selection set to `5 km` (`5.0`) in `AddStoreState` and `AddStoreController.loadInitialData()`.
2. **Pricing & Purchase Fields (Fully Editable & Clearable)**:
   - **Delivery charges up to 2km**: Default set to `20` (replacing 40) across B2C/D2C and wholesale.
   - Guarded controller sync (`_step2Initialized = true`) so users can freely clear text fields completely or type `0` without the form resetting values on rebuild.
   - **Minimum purchase limit**: Fully editable and clearable, accepting 0 or any integer amount.
   - **Delivery charge per km**: Retained numeric input with `'After 2 km this charge will be applicable'` helper text, fully editable and clearable.
3. **Delivery Fulfillment Modes ('Delivery by: *')**:
   - Section header updated to `'Delivery by: *'`.
   - Strictly three checkboxes arranged in a clean vertical list:
     - `Shop` (id: 1)
     - `Agency` (id: 2)
     - `Self pickup` (id: 3)
   - Configured `controlAffinity: ListTileControlAffinity.leading` and `visualDensity: VisualDensity.compact` for native alignment.
4. **Delivery Timings & COD Configuration**:
   - Delivery time title changed to `'Delivery time: *'`.
   - Time pickers cleanly labeled `'From'` and `'To'` with 40px compact containers.
   - Cash on Delivery (COD) limit dropdown options simplified strictly to:
     - `'Any'`
     - `'Limit'` (revealing numeric max COD amount input when selected).
5. **Input Field Height & Density Optimization**:
   - `_inputDecoration` contentPadding reduced to `EdgeInsets.symmetric(horizontal: 12, vertical: 10)` with `isDense: true`.
   - Standardized uniform 40px height across all dropdown containers (distance, COD limit type, replacement days, refund days) and From/To time picker boxes to match native sleek styling.

#### 2. Quality Verification & Automated Testing
- **Tests Added/Updated ([`test/add_store_test.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/test/add_store_test.dart))**:
  - Verified `Delivery and Shipping Details (Nearby locations)` section header.
  - Verified `Max delivery distance: *` label and default 5 km.
  - Verified `Delivery by: *` with `Shop`, `Agency`, `Self pickup` vertical list.
  - Verified `Delivery time: *` with `From` and `To` labels.
  - Verified COD dropdown shows `Any` and `Limit`.
  - Added widget test verifying delivery fee and minimum purchase limit text fields are completely clearable and accept `0`.
  - Verified initial B2C load defaults to delivery fee 20 and radius 5 km.
- **Verification Results**:
  - `flutter analyze`: **0 issues found (100% clean)**.
  - `flutter test test/add_store_test.dart`: **39/39 tests passed (100%)**.
  - Full test suite `flutter test`: **99/99 tests passed (100% pass rate)**.

---

### Phase 71: Payment Options Mutual Validation, COD Amount Layout, Return & Refund Preset Policies & Global Visual Standardization

**Date: September 12, 2026**

**Objective**: Refine Step 2 form logic with mutual payment toggle validation (preventing both COD and Online Payment from being disabled), implement COD Any/Limit adjacent amount input field with read-only/greyed-out behavior on Any, update Return & Refund policy dropdown options to match exact legacy Android values (5 Days to 1 Year, default 5 Days), clean up Step 1 location picker icon halo, and standardize global input, dropdown, and button sizing across all steps.

#### 1. Implementation Details
1. **Payment Options Layout & Mutual Validation**:
   - Added centralized string constants in [`AppStrings`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/core/constants/app_strings.dart):
     - `onlinePaymentTitle = 'Online Payment'`
     - `onlinePaymentSubtitle = 'Accept UPI, Cards & Net Banking'`
     - `atLeastOnePaymentMethodRequired = 'At least one payment method must be enabled'`
   - **Mutual Toggle Validation**:
     - When toggling Cash on Delivery off, checks if Online Payment is also off. If so, rejects the toggle change and displays floating SnackBar: `'At least one payment method must be enabled'`.
     - When toggling Online Payment off, checks if Cash on Delivery is also off. If so, rejects the toggle change and displays the same error SnackBar.
   - **Cash on Delivery (COD) Structure**:
     - Layout: COD Label with inline Toggle Switch, followed by a Row containing the Dropdown (`Any` / `Limit`) and the adjacent Amount Input Field.
     - When `Any` is selected: Amount input field is strictly disabled (`enabled: false`), background is greyed out (`fillColor: Color(0xFFF5F5F5)`), and defaults to `'0'`.
     - When `Limit` is selected: Amount input field becomes active (`enabled: true`, white background) so the merchant can define their COD ceiling.
2. **Return & Refund Policy Dropdowns**:
   - Standardized options map (`_policyOptions`) matching legacy Android `StoreProdReplaceActivity.java`:
     - `5`: `'5 Days'`
     - `15`: `'15 Days'`
     - `30`: `'1 Month'`
     - `90`: `'3 Months'`
     - `180`: `'6 Months'`
     - `365`: `'1 Year'`
   - Updated default values in [`AddStoreState`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/add_store/controller/add_store_controller.dart) and [`CreateStoreRequest`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/add_store/model/create_store_request.dart) from 7 to `5` (`5 Days`).
3. **Location Icon & Wrapper Cleanup (Step 1)**:
   - Removed the faint light-red background container/halo (`#FFFFEBEE`) and red border (`#FFFFCDD2`) surrounding the map location picker icon.
   - Replaced with a clean, standalone native-style location pin icon.
4. **Global Input, Dropdown & Verify Button Standardization (Steps 1, 2, 3)**:
   - **Uniform Height (40px)**: Standardized container height across all dropdowns (Country, State, City, Secondary Type, Radius, COD limit type, Product replacement, Refund policy, Extended radius) and From/To time picker boxes to 40px.
   - **Standardized Button Heights**:
     - `+91` country code boxes and adjacent Verify buttons on Step 1 standardized to uniform 40px height (`minimumSize: Size(70, 40)`, `padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)`).
     - Bottom navigation action buttons (Next, Create Store, Back) standardized with compact padding (`vertical: 11`).
   - **Typography & Cursor Normalization**:
     - Set input text font size to `fontSize: 14` with matching `hintStyle: TextStyle(fontSize: 14, color: Colors.grey)`.
     - Reduced cursor dimensions to `cursorHeight: 18, cursorWidth: 1.5` across all TextFields.

#### 2. Quality Verification & Automated Testing
- **Tests Added/Updated ([`test/add_store_test.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/test/add_store_test.dart))**:
  - Added widget test verifying mutual payment toggle validation:
    - Toggling COD off while Online Payment is on succeeds.
    - Subsequent attempt to toggle Online Payment off is prevented and displays SnackBar: `'At least one payment method must be enabled'`.
  - Verified COD amount field is disabled with text `'0'` when `Any` is selected.
  - Verified Return & Refund policy dropdowns default to `'5 Days'`.
  - Scoped delivery fee and minimum purchase limit test assertions to their respective widget finders.
- **Verification Results**:
  - `flutter analyze`: **0 issues found (100% clean)**.
  - `flutter test test/add_store_test.dart`: **40/40 tests passed (100%)**.
  - Full test suite `flutter test`: **100/100 tests passed (100% pass rate)**.

---

### Phase 72: COD Single-Row Re-alignment, Horizontal Delivery By & Compact Step 1 Dropdowns

**Date: September 12, 2026**

**Objective**: Re-align the Cash on Delivery (COD) controls into a clean single horizontal row (Dropdown, Amount TextField, and Toggle Switch), arrange 'Delivery by: *' options into a side-by-side horizontal row, and standardize Store Type & Store Category dropdowns in Step 1 to match the global compact input field styling.

#### 1. Implementation Details
1. **COD Row Structure & Re-alignment (Step 2)**:
   - Replaced the previous two-line layout with a unified horizontal structure under the Cash on Delivery label and description.
   - Built a single horizontal `Row` containing:
     - **Dropdown (`Any` / `Limit`)**: Wrapped in `Expanded(flex: 5)` with uniform 40px height container and compact padding.
     - **Amount Text Input**: Wrapped in `Expanded(flex: 5)` with 40px height, disabled/read-only with grey background when `Any` is selected, and active/editable when `Limit` is selected.
     - **Toggle Switch**: Positioned at the end of the row with `Key('cod_switch')`, maintaining mutual validation with Online Payment (ensuring at least one payment method remains active).
   - Ensured clean visual alignment with 8px horizontal spacing between components.
2. **'Delivery by: *' Horizontal Alignment (Step 2)**:
   - Replaced the vertical `CheckboxListTile` list with a compact horizontal `Row` displaying all three fulfillment options side-by-side:
     - `Shop`
     - `Agency`
     - `Self pickup`
   - Used compact 24x24 touch-target checkboxes with inline labels and 12px spacing, fitting seamlessly without overflow across mobile form factors.
3. **Compact Store Type & Store Category Dropdowns (Step 1)**:
   - Updated Store Type and Store Category dropdown form containers to match the global compact styling:
     - Standardized container height to 40px (`height: 40`).
     - Content padding set to `EdgeInsets.symmetric(horizontal: 12)`.
     - `isDense: true` with `iconSize: 22`.
     - Normalized font size to `fontSize: 14` with matching `hintStyle: TextStyle(fontSize: 14, color: Colors.grey)`.

#### 2. Quality Verification & Automated Testing
- **Tests Added/Updated ([`test/add_store_test.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/test/add_store_test.dart))**:
  - Updated COD switch finder to `Key('cod_switch')` for the new single-row layout.
  - Verified mutual payment toggle validation (COD + Online Payment).
  - Verified horizontal delivery by checkboxes (`Shop`, `Agency`, `Self pickup`).
- **Verification Results**:
  - `flutter analyze`: **0 issues found (100% clean)**.
  - `flutter test test/add_store_test.dart`: **40/40 tests passed (100%)**.
  - Full test suite `flutter test`: **100/100 tests passed (100% pass rate)**.

---

### Phase 73: Payment Options Spacing, Exact Legacy Replacement & Refund Copy & Conditional Duration Options (Page 1 Dependency)

**Date: September 12, 2026**

**Objective**: Refine Step 2 (Operations) form layout with vertical spacing above Cash on Delivery, update Replacement and Refund labels to exact legacy Android copy (`Product replacement within: * (In case any escalation)` and `Refund within: * (In case any escalation)`), and implement dynamic conditional duration options depending on whether the store selected on Page 1 is a Standard/Public Store vs. a Branded/Verified Store.

#### 1. Implementation Details
1. **Vertical Spacing in Payment Options (Step 2)**:
   - Added `const SizedBox(height: 12)` between the `'Payment Options'` section header and `'Cash on Delivery (COD)'` so elements do not appear cramped together.
2. **Exact Native Label Phrasing**:
   - Added centralized string constants in [`AppStrings`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/core/constants/app_strings.dart):
     - `productReplacementWithinLabel = 'Product replacement within: * (In case any escalation)'`
     - `refundWithinLabel = 'Refund within: * (In case any escalation)'`
   - Updated the form labels in [`AddStoreFormScreen`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/add_store/view/add_store_form_screen.dart) to display full-width native labels above each 40px dropdown container.
3. **Conditional Options Based on Store Selection (Page 1 Dependency)**:
   - **Store Classification Logic (`isBrandedStore`)**:
     - Evaluates whether the selected store type from Step 1 has ID 4 (D2C / Branded Type matching `SelectStoreType.java: store_kind = 4`), contains `'brand'`, `'d2c'`, or `'verified'`, or `storeKind == 4`.
   - **Dynamic Preset Lists (`state.policyOptions`)**:
     - **Standard / Public Store (`!isBrandedStore`)**: Restricted presets:
       - `5`: `'5 Days'`
       - `15`: `'15 Days'`
       - `30`: `'1 Month'`
     - **Branded / Verified Store (`isBrandedStore`)**: Extended duration presets:
       - `5`: `'5 Days'`
       - `15`: `'15 Days'`
       - `30`: `'1 Month'`
       - `90`: `'3 Months'`
       - `180`: `'6 Months'`
       - `365`: `'1 Year'`
   - **Persistence & Default Fallback**:
     - In both UI (`DropdownButton.value`) and controller (`onTypeChanged`), if the currently selected replacement or refund days are not part of the active policy options (e.g. switching from Branded with 90 days to Public Store), it automatically falls back to native default `5` (`'5 Days'`).
     - Preserves merchant's selection when toggling between eligible categories/types.

#### 2. Quality Verification & Automated Testing
- **Tests Added/Updated ([`test/add_store_test.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/test/add_store_test.dart))**:
  - Updated existing policy label test assertions to `AppStrings.productReplacementWithinLabel` and `AppStrings.refundWithinLabel`.
  - Added widget test verifying `SizedBox(height: 12)` spacing between Payment Options and COD title (`codTop - paymentBottom >= 12.0`).
  - Added widget test verifying Public Shop dropdown only populates restricted presets (5 Days, 15 Days, 1 Month) and excludes extended durations.
  - Added widget test verifying Branded Shop (storeKind: 4) populates all 6 extended duration options (including 3 Months, 6 Months, 1 Year).
  - Added unit test in `AddStoreController` verifying `onTypeChanged` adjusts duration options and falls back to default 5 days when switching from Branded to Public.
- **Verification Results**:
---

### Phase 74: Replacement/Refund Duration Legacy Parity, Delivery by Equal Spacing, and Fulfillment Defaults (September 12, 2026)

#### 1. Requirements & Architecture Refinements
1. **Replacement & Refund Duration Options Parity**:
   - **Legacy Native Audit**: Inspected `StoreProdReplaceActivity.java` (lines 307–360) and `AddStoreActivity.java` (lines 1058–1085). In the legacy Android implementation, duration options are dynamically populated from `general.getReplacement()` and `general.getRefund()` through loops `for (int i = 1; i < 4; i++)` producing `5 Days`, `15 Days`, `1 Month`, followed by adding `3 Month` (90), `6 Month` (180), and `1 Year` (365) for all stores (both Public Shop and Branded Store). Position 0 (`5 Days` / value `5`) is preselected as default.
   - **Flutter Controller Update**:
     - Updated `AddStoreState.policyOptions` in [`add_store_controller.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/add_store/controller/add_store_controller.dart) to make all 6 duration presets available across all store kinds: `{5: '5 Days', 15: '15 Days', 30: '1 Month', 90: '3 Months', 180: '6 Months', 365: '1 Year'}`.
     - Confirmed native default values `replacementDays = 5` and `refundDays = 5` are automatically pre-selected.
     - Updated `onTypeChanged` to validate against all 6 duration values `[5, 15, 30, 90, 180, 365]`.

2. **Delivery by Checkboxes: Equal Spacing & Horizontal Alignment**:
   - In [`add_store_form_screen.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/add_store/view/add_store_form_screen.dart), updated the `Row` containing the three `Delivery by` checkboxes (`Shop`, `Agency`, `Self pickup`):
     - Wrapped each `_buildDeliveryCheckbox` widget in an `Expanded` widget so that all 3 options occupy exactly equal width (1/3 of available screen width each) and distribute uniformly across the display.
     - Wrapped the checkbox text label in `Flexible(child: Text(label, overflow: TextOverflow.ellipsis))` inside `_buildDeliveryCheckbox` to guarantee complete overflow safety across small screen form factors.

3. **Delivery Fulfillment Modes / Delivery by Defaults**:
   - **Legacy Native Audit**: Inspected `add_store_screen_2.xml` (lines 364–388) and `StoreProdReplaceActivity.java` (lines 214–221):
     - `check_shop` (`Shop`, type 1): unchecked (`false`).
     - `check_other` (`Agency`, type 2): `android:checked="true"`.
     - `check_self` (`Self pickup`, type 3): `android:checked="true"`.
     - In `setDefaultValues()`, `deliveryTypeArrayList` initializes with `[2, 3]` (`DELIVERY_THIRD_PARTY` and `DELIVERY_BY_SELF_PICKUP`).
   - **Flutter State & Initializer Update**:
     - Updated `AddStoreState.deliveryTypes` default to `const [2, 3]`.
     - Updated `AddStoreController.loadInitialData()` to initialize `deliveryTypes: const [2, 3]` across both Wholesale and B2C / Retail.

#### 2. Quality Verification & Automated Testing
- **Tests Added & Updated ([`test/add_store_test.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/test/add_store_test.dart))**:
  - Updated B2C initial load test to assert `deliveryTypes` initializes to `[2, 3]`.
  - Added unit test verifying `policyOptions` contains all 6 duration options (`[5, 15, 30, 90, 180, 365]`) for standard Public Store with default pre-selection `5`.
  - Added widget test verifying:
    - Step 2 `Delivery by` row contains 3 `Expanded` children with equal width distribution.
    - Default checkbox states: `Shop` is false, `Agency` is true, and `Self pickup` is true.
    - Dropdown menu renders all 6 duration options: `5 Days`, `15 Days`, `1 Month`, `3 Months`, `6 Months`, `1 Year`.
---

### Phase 75: Public Shop Specific Refund & Replacement Durations with Dynamic Binding & Re-validation (September 12, 2026)

#### 1. Requirements & Architectural Implementation
1. **Public Shop Specific Duration Presets (`publicStoreDurations`)**:
   - Defined dedicated preset options for standard Public Shop:
     - `1`: `'1 Day'`
     - `3`: `'3 Days'`
     - `6`: `'6 Days'`
     - `30`: `'1 Month'`
     - `180`: `'6 Months'`
     - `365`: `'1 Year'`
   - Retained extended presets for Branded / Verified / D2C Store (`brandedStoreDurations`):
     - `5`: `'5 Days'`, `15`: `'15 Days'`, `30`: `'1 Month'`, `90`: `'3 Months'`, `180`: `'6 Months'`, `365`: `'1 Year'`.

2. **Dynamic Binding Based on Step 1 Store Type**:
   - In [`AddStoreController`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/add_store/controller/add_store_controller.dart), updated `AddStoreState.policyOptions` getter:
     - Returns `publicStoreDurations` when `isBrandedStore == false` (Public Shop).
     - Returns `brandedStoreDurations` when `isBrandedStore == true` (Branded Store).
   - In [`AddStoreFormScreen`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/add_store/view/add_store_form_screen.dart), both `Product replacement within: *` and `Refund within: *` dropdowns dynamically bind to `state.policyOptions`, defaulting safely to `state.policyOptions.keys.first` if unselected.
   - Assigned test keys `const Key('replacement_dropdown')` and `const Key('refund_dropdown')`.

3. **Dynamic Re-validation and Reset on Store Type Switching**:
   - Updated `onTypeChanged(StoreTypeModel? type)` and `_loadTypesAndCategories(int kind)`:
     - When the merchant toggles store types on Step 1:
       - Evaluates whether the current `replacementDays` and `refundDays` exist within the new store type's active options (`activeOptions.containsKey(state.replacementDays)`).
       - If valid (such as `30` / `'1 Month'` which exists in both), the merchant's choice is retained.
       - If invalid (such as `'1 Day'` when switching to Branded, or `'5 Days'` when switching to Public), automatically resets to `activeOptions.keys.first` (`1` for Public, `5` for Branded) preventing invalid state persistence.

#### 2. Quality Verification & Automated Testing
- **Tests Added & Updated ([`test/add_store_test.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/test/add_store_test.dart))**:
  - Updated widget test verifying Public Shop dropdown contains all 6 specific options: `1 Day`, `3 Days`, `6 Days`, `1 Month`, `6 Months`, `1 Year`.
  - Updated widget test verifying Branded Shop dropdown contains: `5 Days`, `15 Days`, `1 Month`, `3 Months`, `6 Months`, `1 Year`.
  - Added comprehensive state test verifying:
    - Initial load of Public Store defaults to `1 Day` (`1`).
    - Switching to Branded resets invalid `1 Day` to `5 Days` (`5`).
    - Setting common option `1 Month` (`30`) preserves selection when toggling between Public and Branded.
    - Setting Public-only option `3 Days` (`3`) resets to `5 Days` (`5`) when switching to Branded.
  - Updated Step 2 mutual payment validation test to assert `1 Day` default for Public Shop.
  - Added full wizard flow widget test verifying that transitioning back and forth between Step 1 and Step 2 dynamically binds options, resets invalid selections (`3 Days` -> `5 Days`), and preserves shared selections (`1 Month`).
- **Verification Results**:
  - `flutter analyze`: **0 issues found (100% clean)**.
  - `flutter test test/add_store_test.dart`: **47/47 tests passed (100%)**.
  - Full test suite `flutter test`: **107/107 tests passed (100% pass rate across entire project)**.

---

## Phase 76 - Dynamic Category-Based Replacement and Refund Policy Durations & Parity
**Date**: September 12, 2026
- **Legacy Native Audit**:
  - Deeply audited legacy Android implementation across `AddStoreActivity.java` (lines 967–1085 & 2094–2122), `CategoryTypeResponse.java` (lines 34–180), `StoreProdReplaceActivity.java` (lines 273–360), `CreateWsStoreSecondActivity.java` (lines 365–406), and `StoreDetailsLocationSettingFragment.java` (lines 467–505).
  - Confirmed that policy duration options are NOT hardcoded globally or mapped via switch-cases, but resolve dynamically from backend category metadata: `category.getSettings().getGeneral().getReplacement()` and `getRefund()`.
  - Discovered native dynamic generation algorithm:
    ```java
    int refundDays = 0;
    for (int i = 1; i < 4; i++) {
        refundDays += refund.getDays() * i;
        if (refundDays / 30 == 1) { refundSpinnerList.add("1 Month"); }
        else { refundSpinnerList.add(refundDays + " Days"); }
        refundIdList.add(refundDays);
    }
    refundSpinnerList.add("3 Month"); refundIdList.add(90);
    refundSpinnerList.add("6 Month"); refundIdList.add(180);
    refundSpinnerList.add("1 Year");  refundIdList.add(365);
    ```
  - Categorical Proof:
    - **Garments** (`baseDays = 5`): $i=1 \rightarrow 5$ Days (`5`), $i=2 \rightarrow 15$ Days (`15`), $i=3 \rightarrow 30$ Days / 1 Month (`30`), followed by `3 Months` (`90`), `6 Months` (`180`), `1 Year` (`365`).
    - **Restaurant** (`baseDays = 1`): $i=1 \rightarrow 1$ Day (`1`), $i=2 \rightarrow 3$ Days (`3`), $i=3 \rightarrow 6$ Days (`6`), followed by `3 Months` (`90`), `6 Months` (`180`), `1 Year` (`365`).
    - **Sugar / FMCG** (`baseDays = 3`): $i=1 \rightarrow 3$ Days (`3`), $i=2 \rightarrow 9$ Days (`9`), $i=3 \rightarrow 18$ Days (`18`), followed by `3 Months` (`90`), `6 Months` (`180`), `1 Year` (`365`).
  - Visibility & Defaults: If `is_accepted` is false, dropdown is hidden. Selection defaults to position 0 (first calculated duration).
- **Implementation & Enhancements**:
  1. **Category Model Parsing** ([`store_category_model.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/add_store/model/store_category_model.dart)):
     - Updated `StoreCategoryModel.fromJson` to parse `settings.general.replacement` (`is_accepted`, `days`), `settings.general.refund` (`is_accepted`, `days`), and `settings.general.delivery.local` (`radius`, `is_cod`, `is_online_payment`).
     - Added `computeDurationOptions(int baseDays)` replicating the legacy loop and extended intervals.
  2. **Controller & State Management** ([`add_store_controller.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/add_store/controller/add_store_controller.dart)):
     - Added dynamic getters `replacementOptions` and `refundOptions` in `AddStoreState` derived from `selectedCategory`.
     - Updated `_loadCategories` to initialize duration options and position 0 default values from the first loaded category.
     - Updated `onCategoryChanged` to dynamically re-evaluate options, auto-select category defaults, and reset/re-validate invalid selections.
  3. **Step 2 Form Binding** ([`add_store_form_screen.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/add_store/view/add_store_form_screen.dart)):
     - Bound Replacement dropdown to `state.replacementOptions`.
     - Bound Refund dropdown to `state.refundOptions`.
     - Conditionally rendered dropdowns based on `state.replacementAccepted` and `state.refundAccepted`.
  4. **Automated Testing** ([`test/add_store_test.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/test/add_store_test.dart)):
     - Added JSON deserialization tests for nested category settings and delivery/refund/replacement policies.
     - Added unit tests for `computeDurationOptions` across Garments (5), Restaurant (1), and Sugar/FMCG (3).
     - Added controller tests validating category switching, dynamic duration updates, and invalid selection re-validation.
     - Added widget tests validating conditional dropdown rendering based on `is_accepted`.
- **Verification Results**:
  - `flutter analyze`: **0 issues found (100% clean)**.
  - `flutter test test/add_store_test.dart`: **51/51 tests passed (100%)**.
  - Full test suite `flutter test`: **111/111 tests passed (100% pass rate across entire project)**.

---

## Phase 77 - Branded 'Others' Single-Step Flow, Step 1 Clean Address Sanitization, Step 3 Overhaul & Back-Navigation Stability
**Date**: September 12, 2026
- **Native Android Architecture Audit**:
  - Investigated `CreateNewStoreOtherCategory.java`, `AddStoreActivity.java`, `add_store_screen_3.xml`, and Retrofit endpoint `@POST("merchant/shop/other")` (`ApiEndpoints.createOtherStore`).
  - Discovered that when a merchant chooses the "Others" category under Branded Shop:
    1. The creation process is a direct 1-step form bypassing Step 2 (Operations) and Step 3 (Media/Extended Delivery) entirely.
    2. The submission payload is strictly stripped to `category_id: "others"`, `category_description`, `display_name`, `contact_time`, `mobile`, `location`, and `address`, omitting all operational parameters (COD, delivery radius, refund days, etc.).
    3. The Step 3 layout in `add_store_screen_3.xml` consists of `Extended delivery on ship to other location` with `Enable Other locations:` conditional toggle (derived from `category.settings.general.delivery.other.is_enabled`), target country `India`, delivery modes `Shop` and `Agency`, default delivery fee of `60`, minimum purchase limit of `2000`, and `Enable private chat` toggle.
- **Key Implementation & Enhancements**:
  1. **Conditional Single-Step Flow & Stripped Payload**:
     - Added `isSingleStepFlow => selectedCategory?.id == 'others'` on `AddStoreState`.
     - In [`step_indicator.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/add_store/view/widgets/step_indicator.dart), added `isSingleStep` support dynamically collapsing indicator to show only Step 1.
     - In [`add_store_form_screen.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/add_store/view/add_store_form_screen.dart), updated `_buildBottomBar` to hide the "Back" button and replace "Next" with "Create Store" on Step 1 when `isSingleStepFlow` is active.
     - In [`add_store_controller.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/add_store/controller/add_store_controller.dart), updated `submitStore()` to validate only Step 1 for `isSingleStepFlow`, and `onCategoryChanged` to reset `categoryDescription` and `contactTime` when switching back to regular categories.
     - In [`create_store_request.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/add_store/model/create_store_request.dart), updated `toJson()` to return the exact stripped payload matching `CreateNewStoreOtherCategory.java` when `categoryId == 'others'`.
  2. **Step 1 Clean Physical Address Sanitization**:
     - Implemented `AddStoreController.sanitizePhysicalAddress(String raw)` static sanitizer.
     - Robustly strips currency symbols (`₹`, `Rs.`), delivery charge/fee artifacts, minimum purchase limit text, and stray JSON tokens.
     - Integrated across address text input syncing and GPS/Map location resolver hooks.
  3. **Step 3 UI & Architecture Overhaul**:
     - Updated step title from `Media & Submit` to `Create Store` (`AppStrings.mediaSubmitStep`).
     - Added section `Extended delivery on ship to other location` with `Enable Other locations:` toggle conditionally shown/enabled via `state.isOtherDeliverySupported`.
     - Configured defaults: Delivery Charge `60` (hint `Amount`) and Minimum Purchase Limit `2000` (hint `Minimum Purchase Amount`).
     - Added `Delivery by: *` checkboxes with `Shop` (1) and `Agency` (2) side-by-side.
     - Added `Enable private chat` toggle container.
  4. **Back-Navigation & Crash Resilience**:
     - Wrapped screen scaffold in `PopScope(canPop: state.currentStep == 0, onPopInvokedWithResult: ...)` to transition back one step at a time without inadvertently popping the entire wizard route.
     - Switched wizard body from `PageView` to `IndexedStack(index: state.currentStep.clamp(0, 2), children: ...)` ensuring that all 3 step views, form controllers, text field values, and scroll offsets are 100% retained when transitioning back and forth between steps, eliminating `PageController` animation ticker leaks and controller detachment exceptions.
     - Relocated bottom navigation action bar into `Scaffold(bottomNavigationBar: SafeArea(...))` and applied explicit minimum dimensions (`Size(100, 46)` on Back and `Size(double.infinity, 46)` on Next/Create Store) so action buttons never shrink, break, or collapse when navigating backward from Step 3 to Step 2 or Step 1.
     - Added `if (!mounted) return;` lifecycle guards across all asynchronous methods in `AddStoreController` (`loadInitialData`, `_loadTypesAndCategories`, `_loadCategories`, `_loadLocations`, `fetchCurrentDeviceLocation`, `onCountryChanged`, `verifyPrimaryOtp`, `verifySecondaryOtp`, `submitStore`), completely preventing `Bad state: Tried to modify a disposed StateNotifier` on premature route pop.
     - Added `if (mounted)` checks around all `setState()` calls in `select_store_location_screen.dart` and `confirm_store_location_screen.dart`.
  5. **Automated Testing & Parity Coverage** ([`test/add_store_test.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/test/add_store_test.dart)):
     - Added unit tests for address sanitizer stripping charges, limits, currency, and JSON residue while preserving physical addresses.
     - Added model serialization tests verifying stripped payload output for `others`.
     - Added widget tests for single-step indicator collapse, "Create Store" button on Step 1, and reversible restoration on regular category switch.
     - Added tests for `isOtherDeliverySupported` category settings parsing.
     - Added widget test verifying that navigating backward from Step 3 -> Step 2 -> Step 1 retains all form state and keeps action buttons stable without collapsing.
     - Added widget test verifying that popping `AddStoreFormScreen` while async data is loading cleanly unmounts without throwing unhandled or disposed-notifier exceptions.
  6. **Button Styling & Visual Parity**:
     - Updated "Create Store" button background color to `Color(0xFF1976D2)` (exact same primary blue as "Next" button, mirroring native Android `blue_btn_bg`).
- **Verification Results**:
  - `flutter analyze`: **0 issues found (100% clean)**.
  - `flutter test test/add_store_test.dart`: **57/57 tests passed (100%)**.
  - Full test suite `flutter test`: **117/117 tests passed (100% pass rate across entire project)**.

---

## Phase 78 - Back Button Blue Border & 50/50 Equal Split Bottom Navigation Bar
**Date**: September 12, 2026
- **Requirement & Enhancements**:
  1. **Back Button Styling Alignment**:
     - Changed the "Back" `OutlinedButton` border from green/default to primary blue (`side: const BorderSide(color: Color(0xFF1976D2), width: 1.5)`).
     - Set foreground text color to primary blue (`foregroundColor: const Color(0xFF1976D2)`).
     - Styled font to bold 15sp (`TextStyle(fontSize: 15, fontWeight: FontWeight.bold)`), matching the "Next" / "Create Store" button visual weight.
  2. **50/50 Equal Width Row Split**:
     - Wrapped the "Back" button inside `Expanded(child: ...)` alongside the `Expanded(child: ElevatedButton(...))` for "Next" / "Create Store", with `SizedBox(width: 12)` spacing between them.
     - When `state.currentStep > 0` and `!isSingleStep`, both buttons now equally split the row width (50% / 50%).
     - When on Step 1 (or single step flow where Back is hidden), Next/Create Store gracefully takes the entire width (100%).
  3. **Automated Verification**:
     - Updated widget tests in `test/add_store_test.dart` to assert:
       - `backSize.width == nextSize.width` (exact 50/50 row split).
       - Back button side border color equals `Color(0xFF1976D2)`.
       - Back button foreground text color equals `Color(0xFF1976D2)`.
- **Verification Results**:
  - `flutter analyze`: **0 issues found (100% clean)**.
  - `flutter test test/add_store_test.dart`: **57/57 tests passed (100%)**.
  - Full test suite `flutter test`: **117/117 tests passed (100%)**.

---

## Phase 79 - Terms & Conditions Section Refinement & In-App WebView Screen
**Date**: September 12, 2026
- **Native Android Architecture Inspection**:
  - Inspecting `AddStoreActivity.java` (lines 771-776) and `add_store_screen_3.xml` revealed that:
    1. The agreement section uses a centered horizontal linear layout containing a checkbox and `@string/terms`:
       `I agree to the BayFay shop <u><font fgcolor="#2828CC">terms of service and privacy policy.</font></u>`.
    2. Clicking `txt_terms_conditions` starts `TermsConditionActivity.class`.
    3. `TermsConditionActivity.java` and `activity_terms_condition.xml` display a toolbar titled `"Terms & Conditions"` (`@string/terms_conditions`) with back navigation and an in-app WebView loading `AppConstants.TERMS_CONDITIONS = "https://www.bayfay.com/merchant-policy"`.
- **Key Implementation & Enhancements**:
  1. **Dependencies & Legal Endpoint**:
     - Added `webview_flutter: ^4.13.0` and `url_launcher: ^6.3.2` to `pubspec.yaml`.
     - Added `ApiEndpoints.termsAndConditionsUrl = 'https://www.bayfay.com/merchant-policy'` in [`api_endpoints.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/core/network/api_endpoints.dart).
  2. **In-App WebView Screen & Route**:
     - Created [`terms_condition_screen.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/add_store/view/terms_condition_screen.dart) mirroring `TermsConditionActivity`:
       - AppBar with primary blue background (`Color(0xFF1976D2)`), white back arrow, and title `"Terms & Conditions"`.
       - Browser action button to launch in external browser as secondary option.
       - Embedded `WebViewWidget` with `WebViewController` configured for JavaScript and loading progress indicator.
       - Graceful error view with retry and "Open in Browser" action if network or platform view fails.
     - Registered `AppRoutes.termsConditions = '/terms-conditions'` in [`app_routes.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/app/router/app_routes.dart) and [`app_router.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/app/router/app_router.dart).
  3. **Tightened Step 3 Agreement Layout**:
     - Replaced loose `CheckboxListTile` with centered, compact `Row` in [`add_store_form_screen.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/add_store/view/add_store_form_screen.dart):
       - Checkbox configured with `visualDensity: VisualDensity.compact` and `materialTapTargetSize: MaterialTapTargetSize.shrinkWrap`.
       - Reduced horizontal gap between checkbox and label to `SizedBox(width: 6)`.
     - Rendered label using `Text.rich`:
       - Base text: `"I agree to the BayFay shop "` in dark gray 12sp.
       - Clickable link: `"terms of service and privacy policy."` in primary blue (`Color(0xFF1976D2)`), underlined (`TextDecoration.underline`), and semi-bold (`FontWeight.w600`).
     - Added `_termsRecognizer` initialized in `initState()` and properly disposed in `dispose()` to navigate seamlessly to `TermsConditionScreen`.
  4. **Automated Verification**:
     - Added widget tests verifying:
       - Compact checkbox properties (`VisualDensity.compact`, `MaterialTapTargetSize.shrinkWrap`).
       - RichText text content and link styling (blue, underlined, semi-bold).
       - Clickable link triggers navigation to `TermsConditionScreen`.
       - `TermsConditionScreen` renders app bar, title, back arrow, and browser icon.
- **Verification Results**:
  - `flutter analyze`: **0 issues found (100% clean)**.
  - `flutter test test/add_store_test.dart`: **59/59 tests passed (100%)**.
  - Full test suite `flutter test`: **119/119 tests passed (100%)**.

---

## Phase 80 - Enable Private Store (Private Shop) Defaulted to On
**Date**: September 12, 2026
- **Native Android Alignment**:
  - Inspected `add_store_screen_3.xml`:
    ```xml
    <androidx.appcompat.widget.SwitchCompat
        android:id="@+id/enable_private"
        ...
        android:checked="true" />
    ```
  - In the native Android app, the Private Store (`enable_private`) toggle was initialized to checked (`true`) by default.
- **Key Implementation & Enhancements**:
  - In [`add_store_controller.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/add_store/controller/add_store_controller.dart), updated `AddStoreState` constructor default `this.isPrivate = true` (previously `false`).
  - In [`create_store_request.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/add_store/model/create_store_request.dart), updated `CreateStoreRequest` constructor default `this.isPrivate = true`.
  - In `test/add_store_test.dart`, added widget tests validating that `isPrivate` is `true` by default on Step 3 and the "Enable private chat" `Switch` widget is checked (`value: true`).
- **Verification Results**:
  - `flutter analyze`: **0 issues found (100% clean)**.
  - `flutter test test/add_store_test.dart`: **59/59 tests passed (100%)**.
  - Full test suite `flutter test`: **119/119 tests passed (100%)**.

## Phase 81 - Dynamic Category Payment Method Enablement (`local.is_cod` & `local.is_online_payment`)
**Date**: September 12, 2026
- **Native Android Category API Contract**:
  - Category API response (`GET merchant/category/{id}`):
    ```json
    "categories":[{
      "_id":"5e022ac1aa94cc0011138fc3",
      "display_name":"Fast Food",
      "settings":{
        "general":{
          "delivery":{
            "local":{
              "is_cod": true,
              "is_online_payment": false
            }
          }
        }
      }
    }]
    ```
  - `delivery.local.is_cod` and `delivery.local.is_online_payment` directly control the checked value AND interactive enabled states of Cash on Delivery and Online Payment toggles in Step 2.
- **Key Implementation & Enhancements**:
  - Added `isCodEnabled` and `isOnlinePaymentEnabled` boolean fields to `AddStoreState` (default `true`).
  - Updated `onCategoryChanged()` in [`add_store_controller.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/add_store/controller/add_store_controller.dart):
    - `isCodEnabled`: `cat.isCod ?? true`
    - `isCod`: `codEnabled ? (cat.isCod ?? state.isCod) : false`
    - `isOnlinePaymentEnabled`: `cat.isOnlinePayment ?? true`
    - `isOnlinePayment`: `onlineEnabled ? (cat.isOnlinePayment ?? state.isOnlinePayment) : false`
  - Updated `_loadCategories()` to automatically invoke `onCategoryChanged(firstCat)` when categories load or fallback is used.
  - Updated UI in [`add_store_form_screen.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/add_store/view/add_store_form_screen.dart):
    - COD Switch: `onChanged` set to `null` when `isCodEnabled == false` (grayed out & disabled).
    - COD Dropdown & Limit field: `enabled` gated by `isCodEnabled && isCod`.
    - Online Payment `SwitchListTile`: `onChanged` set to `null` when `isOnlinePaymentEnabled == false` (grayed out & disabled).
- **Tests**:
  - Added unit & widget tests covering:
    - Fast Food example (`is_cod: true`, `is_online_payment: false`): COD ON/Enabled, Online Payment OFF/Disabled.
    - Digital Goods example (`is_cod: false`, `is_online_payment: true`): COD OFF/Disabled, Online Payment ON/Enabled.
    - Generic/null example: Both default to ON/Enabled.
- **Verification Results**:
  - `flutter analyze`: **0 issues found (100% clean)**.
  - `flutter test test/add_store_test.dart`: **63/63 tests passed (100%)**.
  - Full test suite `flutter test`: **123/123 tests passed (100%)**.

## Phase 82 - Fix HTTP 413 Request Entity Too Large via Store Image Compression
**Date**: September 12, 2026
- **Native Android Alignment**:
  - Inspected `AddStoreActivity.java` (lines 1165 & 1196):
    ```java
    compressedImage = new Compressor(this).compressToFile(file);
    ```
  - Native Android passes all selected store images through an image compressor before building `MultipartBody.Part` entries for `POST merchant/shop/new`.
  - High-resolution camera photos (5MB–15MB each) picked without compression caused the total HTTP Multipart payload size to exceed NGINX's `client_max_body_size` limit (HTTP Status 413 `Request Entity Too Large`).
- **Key Implementation & Enhancements**:
  - In [`store_image_picker.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/add_store/view/widgets/store_image_picker.dart):
    - Added `maxWidth: 1024`, `maxHeight: 1024`, and `imageQuality: 80` to all `ImagePicker` calls (`pickImage(source: ImageSource.gallery)`, `pickMultiImage()`, and `pickImage(source: ImageSource.camera)`).
    - Reduces raw 10MB+ camera/gallery photos down to ~150KB–300KB each, matching native Android `Compressor`.
  - In [`create_store_request.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/add_store/model/create_store_request.dart):
    - Added debug size logging in `toFormData(images)` to output individual attached image file sizes in KB before POST transmission.
- **Verification Results**:
  - `flutter analyze`: **0 issues found (100% clean)**.
  - `flutter test test/add_store_test.dart`: **63/63 tests passed (100%)**.
  - Full test suite `flutter test`: **123/123 tests passed (100%)**.

## Phase 83 - Hide Top 1 2 3 Step Indicator Section for "Others" Category
**Date**: September 12, 2026
- **Requirement & Native Parity**:
  - When the merchant selects the **Others** category (`id == 'others'`), the single-step flow is active.
  - The top step indicator bar (`1 Store Info`, `2 Operations`, `3 Media & Submit`) must be completely hidden.
- **Key Implementation & Enhancements**:
  - In [`add_store_form_screen.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/add_store/view/add_store_form_screen.dart):
    - Configured `appBar.bottom` to evaluate `state.isSingleStepFlow ? null : PreferredSize(...)`.
    - Completely removes the `StepIndicator` bar and divider when single-step flow is active.
    - Automatically restores the 3-step indicator bar when switching back to a standard category.
  - In [`add_store_test.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/test/add_store_test.dart):
    - Added widget test assertions: `find.byType(StepIndicator)` returns `findsNothing` when category is `others`, and `findsOneWidget` when restored to standard category.
- **Verification Results**:
  - `flutter analyze`: **0 issues found (100% clean)**.
  - `flutter test test/add_store_test.dart`: **63/63 tests passed (100%)**.
  - Full test suite `flutter test`: **123/123 tests passed (100%)**.

## Phase 86 - Page 1 Compulsory Primary Mobile & Conditional Secondary Mobile OTP Verification
**Date**: September 12, 2026
- **Requirement & Logic**:
  - Enforced strict mobile verification checks on Page 1 (Step 1) in `AddStoreController.validateStep1()`:
    1. **Primary Mobile Number**: Must be entered (valid 10 digits) AND compulsory verified (`state.isPrimaryVerified == true`). Returns `'Please verify primary mobile number'` if unverified.
    2. **Secondary Mobile Number**: Optional field. If entered, requires valid 10 digits AND if `secondaryType == 'mobile'`, requires verification (`state.isSecondaryVerified == true`). Returns `'Please verify secondary mobile number'` if unverified.
- **Verification Results**:
  - `flutter analyze`: **0 issues found (100% clean)**.
  - Full test suite `flutter test`: **125/125 tests passed (100%)**.

## Phase 87 - Exclude `is_verified` from `CreateStoreRequest.toJson()` to fix Backend Joi Validation Error
**Date**: September 12, 2026
- **Root Cause & Native Parity**:
  - The backend server (`https://store-devapi.bayfay.com/merchant/merchant/shop/new`) uses a Joi schema that forbids `"is_verified"` inside `mobile.primary` or `mobile.secondary`.
  - Sending `'is_verified'` caused HTTP 400 badResponse (`child "mobile" fails because [child "primary" fails because ["is_verified" is not allowed]]`).
  - In native Android (`StoreCreateNewRequest.java`), `is_verified` is not part of the network request payload.
- **Key Implementation & Enhancements**:
  - In [`create_store_request.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/add_store/model/create_store_request.dart):
    - Removed `'is_verified'` key from `mobile.primary` and `mobile.secondary` in `CreateStoreRequest.toJson()`.
    - Preserved local Page 1 OTP verification UI & `validateStep1()` checks in Flutter.
- **Verification Results**:
  - `flutter analyze`: **0 issues found (100% clean)**.
  - Full test suite `flutter test`: **125/125 tests passed (100%)**.

## Phase 88 - Delivery `from` & `to` ISO 8601 UTC Timestamp Formatting
**Date**: September 12, 2026
- **Requirement & Format**:
  - The backend requires `delivery.local.from` and `delivery.local.to` to be formatted as ISO 8601 UTC timestamp strings (`YYYY-MM-DDTHH:mm:ss.000Z`, e.g. `"2026-09-12T09:00:00.000Z"` and `"2026-09-12T18:00:00.000Z"`).
- **Key Implementation & Enhancements**:
  - In [`create_store_request.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/add_store/model/create_store_request.dart):
    - Added `CreateStoreRequest.formatDeliveryTimeIso(String rawTime)` static helper.
    - Automatically formats display time strings (`'09:00 AM'`, `'06:00 PM'`, `'18:00'`) into ISO 8601 UTC timestamps.
    - Serialized directly into `from` and `to` inside `delivery.local` in `CreateStoreRequest.toJson()`.
- **Verification Results**:
  - `flutter analyze`: **0 issues found (100% clean)**.
  - Full test suite `flutter test`: **126/126 tests passed (100%)**.

## Phase 89 - Refined Optional Secondary Mobile Number Validation & Serialization
**Date**: September 12, 2026
- **Requirement & Parity**:
  - Secondary mobile number is 100% optional. If not entered (`secondaryNumber` is null, 0, or empty), secondary validation is completely bypassed.
  - If a secondary mobile number IS entered (`secondaryNumber != null && secondaryNumber > 0 && non-empty`):
    - Validates 10-digit format.
    - Requires verification (`isSecondaryVerified == true`) if `secondaryType == 'mobile'`.
- **Key Implementation & Enhancements**:
  - Refined `validateStep1()` in [`add_store_controller.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/add_store/controller/add_store_controller.dart) with `hasSecondary` check.
  - Updated `CreateStoreRequest.toJson()` in [`create_store_request.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/add_store/model/create_store_request.dart) to check `if (secondaryNumber != null && secondaryNumber! > 0)`.
- **Verification Results**:
  - `flutter analyze`: **0 issues found (100% clean)**.
  - Full test suite `flutter test`: **126/126 tests passed (100%)**.

## Phase 90 - Fix Secondary Mobile Clearing State Bug & Auto-Clear OTP Dialog Error on Typing
**Date**: September 12, 2026
- **Requirement & Fixes**:
  1. **Secondary Number State Clearing Fix**:
     - When deleting/clearing the text in the secondary mobile number field (`_secMnoCtrl.text = ""`), `int.tryParse("")` returned `null`.
     - Previously, `AddStoreState.copyWith()` used `secondaryNumber: secondaryNumber ?? this.secondaryNumber`, which retained the old number in state despite the text field being visually empty.
     - Added `clearPrimaryNumber` and `clearSecondaryNumber` boolean flags to `AddStoreState.copyWith()`.
     - Updated `setSecondaryNumber(int? number)` to pass `clearSecondaryNumber: number == null || number == 0`, ensuring `state.secondaryNumber` is reset to `null` when cleared.
  2. **OTP Dialog Error Auto-Clearing**:
     - Added `onChanged` handler to the OTP input `TextField` in `OtpVerifyDialog`.
     - Automatically resets `_errorText = null` as soon as the user starts typing or modifying OTP digits.
- **Verification Results**:
  - `flutter analyze`: **0 issues found (100% clean)**.
  - Full test suite `flutter test`: **127/127 tests passed (100%)**.

## Phase 91 - Availability 3-Letter Day Codes (`"Sun"..."Sat"`)
**Date**: September 12, 2026
- **Requirement & Format**:
  - The backend payload requires `availability` to be formatted as an array of short 3-letter day codes: `["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]`.
- **Key Implementation & Enhancements**:
  - Updated default `availability` in `AddStoreState` and `CreateStoreRequest` to `['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']`.
  - Added `CreateStoreRequest.formatAvailability(List<String> rawDays)` static helper method to convert day names to 3-letter day codes.
  - Updated `AvailabilityDaysRow` to use `['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']` as `allDays`.
- **Verification Results**:
  - `flutter analyze`: **0 issues found (100% clean)**.
  - Full test suite `flutter test`: **128/128 tests passed (100%)**.

## Phase 92 - Store Approval Status Badge Update to 'Pending' with Yellow/Amber Gradient
**Date**: September 15, 2026
- **Requirement & UI Parity**:
  - Aligned store approval status badge in merchant dashboard store card widget ([`store_card.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/dashboard/view/widgets/store_card.dart)) to match legacy Android native UI.
  - Text label updated from `"Waiting for Review"` to `"Pending"`.
  - Replaced red gradient with yellow/amber linear gradient:
    ```dart
    gradient: const LinearGradient(
      colors: [Color(0xFFFFB300), Color(0xFFFFA000)],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ),
    ```
  - Text styled with `color: Colors.white`, `fontSize: 11`, `fontWeight: FontWeight.w600`, centered alignment, and bottom corner radii (`bottomLeft` and `bottomRight` at `Radius.circular(6)`).
  - Maintained red gradient for other non-pending statuses like `"Suspended"` and `"Rejected"`.
- **Verification Results**:
  - `flutter analyze`: **0 issues found (100% clean)**.
  - Full test suite `flutter test`: **130/130 tests passed (100%)**.

## Phase 93 - Login Direct Location Settings Redirect & Prevent Add Store Category Reset
**Date**: September 15, 2026
- **Requirements & UX Fixes**:
  1. **Login Flow Location Settings Redirect**:
     - In [`login_controller.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/auth/login/controller/login_controller.dart):
     - When location service is disabled (`!isGpsOn`), directly triggers `Geolocator.openLocationSettings()` and sets `state = const AsyncData(null)`.
     - Completely eliminates red error SnackBar (`"Please turn on location to log in"`) while cleanly aborting login until location is enabled.
  2. **Add Store Category Reset Prevention**:
     - In [`add_store_controller.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/add_store/controller/add_store_controller.dart):
     - Added equality guard `if (state.selectedType?.id == type.id) return;` inside `onTypeChanged`.
     - Prevents resetting `selectedCategory` or triggering redundant category API requests when the user re-selects the currently active store type.
- **Verification Results**:
  - `flutter analyze`: **0 issues found (100% clean)**.
  - Full test suite `flutter test`: **131/131 tests passed (100%)**.

## Phase 94 - Dynamic Store Creation Success Message & Targeted Stores Section Refresh
**Date**: September 15, 2026
- **Requirements & Parity Implementation**:
  1. **Dynamic Success Message Handling**:
     - In [`add_store_repository.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/add_store/repository/add_store_repository.dart): Added `StoreCreationResult` class and updated `createStore`, `createOtherStore`, and `createWsStore` methods to extract `message` dynamically from response payload (`response.data['message']`).
     - In [`add_store_controller.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/add_store/controller/add_store_controller.dart): Updated `AddStoreState` and `submitStore` to store the dynamic `successMessage`.
     - In [`add_store_form_screen.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/add_store/view/add_store_form_screen.dart): Updated popup dialog to display the dynamic extracted message text (e.g., `"Request sent successfully"` or `"Store request submitted for review"`).
  2. **Targeted Stores Section Refresh on Dashboard**:
     - In [`dashboard_controller.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/dashboard/controller/dashboard_controller.dart): Added `fetchMerchantStores()` and `refreshStoresOnly()` methods on `StoresNotifier`, exposing `dashboardControllerProvider` alias.
     - In [`add_store_form_screen.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/add_store/view/add_store_form_screen.dart): On "Go to Dashboard" button press, triggers `ref.read(storesProvider.notifier).fetchMerchantStores()` and pops navigation back to `DashboardScreen`.
     - In [`home_body_view.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/dashboard/view/views/home_body_view.dart): Isolated `_buildStoresSection()` so that refreshing merchant stores displays an isolated loader/shimmer spinner only for the store grid section, leaving top feature gradient cards, sales analytics, business value dialogs, and location services untouched.
- **Verification Results**:
  - `flutter analyze`: **0 issues found (100% clean)**.
  - Automated tests updated and verified.

## Phase 95 - Refactor Create Store Flow ('Others' vs Normal Categories) & Dashboard Shimmer
**Date**: September 15, 2026
- **Requirements & Parity Implementation**:
  1. **Unified Loading Button During API Submission**:
     - In [`add_store_form_screen.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/add_store/view/add_store_form_screen.dart): When `state.isSubmitting` is true, replaces bottom Previous/Create buttons with a single full-width disabled button with inline loading spinner and text `"Creating store, please wait..."`.
  2. **Response Handling ('Others' vs Normal Category)**:
     - Created [`others_acknowledgment_screen.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/add_store/view/others_acknowledgment_screen.dart) (`Merchant Signup` title, support message, `sales@bayfay.com`, and blue outlined `OK` button).
     - Category `'others'`: Navigates directly to `OthersAcknowledgmentScreen`. Tapping `OK` triggers `fetchMerchantStores()` and pops to Dashboard root.
     - Normal Category: Completely removes popup dialogs. Displays a floating green SnackBar/Toast, triggers `fetchMerchantStores()`, and immediately redirects back to Dashboard root.
  3. **Dashboard Stores Section Shimmer Loading**:
     - In [`home_skeleton_loader.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/dashboard/view/widgets/home_skeleton_loader.dart): Added `StoresSectionSkeletonLoader` rendering 6 shimmering skeleton card placeholders.
     - In [`home_body_view.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/dashboard/view/views/home_body_view.dart): Renders `StoresSectionSkeletonLoader()` during `_buildStoresSection` loading state while keeping header cards, analytics, banners, and location services static without flickering or reloading.
     
## Phase 96 - Add Store App Bar Titles, Keyboard Insets, Dropdown Crash Fix & Temporary Validation Bypass
**Date**: September 15, 2026
- **Requirements & UI Refactoring**:
  1. **Dynamic App Bar Title Logic**:
     - Updated [`app_strings.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/core/constants/app_strings.dart) and [`add_store_form_screen.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/add_store/view/add_store_form_screen.dart).
     - Removed title variations like "Add Store", "Add D2C Store", and "Add New Store".
     - Strictly enforced:
       - App Bar title is **`Create Wholesale Store`** if `storeKind == 2` or `selectedType.id == 2` or type name contains `'wholesale'`.
       - App Bar title is **`Create New Store`** for all other store types (Public, Branded, D2C, etc.).
  2. **Keyboard Insets & Bottom Action Button Visibility**:
     - Configured `resizeToAvoidBottomInset: true` on `Scaffold` in `add_store_form_screen.dart`.
     - Wrapped `bottomNavigationBar` with `AnimatedPadding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom))`.
     - Ensures bottom action buttons (`Next`, `Back`, `Submit`) automatically shift up above the soft keyboard on mobile devices.
  3. **DropdownButton Red Screen Crash Fix (`Failed assertion: items.where(...)`)**:
     - In [`add_store_controller.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/add_store/controller/add_store_controller.dart):
       - Added `clearSelectedCategory: true` in `onTypeChanged()` / `onStoreTypeChanged()` so `selectedCategory` is immediately cleared (`null`) before loading new categories.
       - Added `onStoreTypeChanged` alias method.
     - In [`add_store_form_screen.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/add_store/view/add_store_form_screen.dart):
       - Added safety existence checks (`categoryExists`, `typeExists`, `countryExists`, `stateExists`, `cityExists`, `repExists`, `refExists`) to all `DropdownButton` `value` parameters to prevent assertion failures if the current value is missing in newly fetched items.
  4. **Temporary Bypass for Validations and Verify OTP API**:
     - In `_verifyPrimaryMobile` and `_verifySecondaryMobile`: Bypassed OTP dialog API calls and set verified state directly with green SnackBars. Marked with `// TODO: RE-ENABLE VALIDATION`.
     - In `validateStep1()`, `validateStep2()`, `validateStep3()`: Temporarily bypassed compulsory field validators to return `null`. Marked with `// TODO: RE-ENABLE VALIDATION`.
     - In `submitStore()`: Added mock fallback values for empty request fields (`'Test Store'`, `'123 Main Street'`, `9894555037`) so submission succeeds smoothly during test runs.
- **Verification Results**:
  - `flutter analyze`: **0 issues found (100% clean)**.
  - Full test suite `flutter test`: **135/135 tests passed (100%)**.

## Phase 97 - Native-Parity Horizontal Loader in AppBar Bottom During Category Fetch
**Date**: September 15, 2026
- **Requirements & Parity Implementation**:
  1. **Native-Style AppBar Linear Loader**:
     - Added `isCategoriesLoading` getter to `AddStoreState` in [`add_store_controller.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/add_store/controller/add_store_controller.dart).
     - In [`add_store_form_screen.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/add_store/view/add_store_form_screen.dart):
       - Configured `AppBar.bottom` with `PreferredSize`:
         - When `state.isCategoriesLoading` is true: Renders an indeterminate `LinearProgressIndicator(minHeight: 3.0, backgroundColor: Color(0xFFE3F2FD), valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1976D2)))`.
         - Fixed height at 3.0 dp in both loading and idle states to completely eliminate any vertical UI jumping or layout shifts.
  2. **Synchronized Category Dropdown Interaction**:
     - While `state.isCategoriesLoading` is true:
       - Disabled user interaction on Store Category dropdown (`onChanged: null`).
       - Set container background color to light grey (`Color(0xFFF5F5F5)`).
       - Kept selected value cleared (`value: null`) with hint `"Loading categories..."`.
     - Once category fetching resolves:
       - Linear loader automatically dismisses.
       - Category dropdown becomes enabled with freshly fetched categories.

## Phase 98 - Decouple Store Flow from Store Type Dropdown Selection
**Date**: September 15, 2026
- **Requirements & State Management**:
  - In [`add_store_controller.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/add_store/controller/add_store_controller.dart): Defined explicit `enum StoreFlow { b2c, d2c, wholesale }` and `final StoreFlow storeFlow;` in `AddStoreState`.
  - Added getter `bool get isWholesale => storeFlow == StoreFlow.wholesale;`.
  - In `loadInitialData()`: Initialized `storeFlow` strictly from entry point (`0` -> `b2c`, `4` -> `d2c`, `2` -> `wholesale`).
  - In `onStoreTypeChanged()` / `onTypeChanged()`: Changing store type dropdown (e.g., switching between "Public Shops" and "Branded Shops") updates `selectedType` but strictly preserves `state.storeFlow`.
- **UI & App Bar Title Parity**:
  - In [`add_store_form_screen.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/add_store/view/add_store_form_screen.dart): App Bar title renders **`Create Wholesale Store`** strictly when `state.isWholesale` is true (`storeFlow == StoreFlow.wholesale`), and **`Create New Store`** for all `b2c` and `d2c` flows.
  - Step 2 Operations hides "Replacement within" field for Wholesale flows while displaying "Refund within" dropdown.
- **Verification Results**:
  - `flutter analyze`: **0 issues found (100% clean)**.
  - Full test suite `flutter test`: **138/138 tests passed (100%)**.

## Phase 99 - Dynamic Max Delivery Distance by Store Category & Store Type
**Date**: September 15, 2026
- **Requirements & Distance Options Formula**:
  - In [`add_store_controller.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/add_store/controller/add_store_controller.dart): Implemented `computeDeliveryDistanceOptions()` and `computeDefaultDeliveryRadius()`.
  - **Wholesale**: Distance range options strictly allow discrete step values `[5, 10, 15, 20, 25, 30, 35, 40, 45, 50]` km with default radius set to `15` km.
  - **B2C / D2C**: Dynamic range based on selected category:
    - Fast Food / Food / Restaurant: 1 to 5 km (Default: 5 km).
    - Bakery / Grocery / Supermarket: 1 to 10 km (Default: 5 km).
    - Garments / Fashion / Apparel / Others: 1 to 30 km (Default: 5 km).
- **Verification Results**:
  - `flutter analyze`: **0 issues found (100% clean)**.
  - Full test suite `flutter test`: **140/140 tests passed (100%)**.

## Phase 100 - Remove Wholesale Label Bracket Tags, Dynamic Wholesale Time Slots API (`POST merchant/wsshop/timeslot`) & Submission Payload Serialization
**Date**: September 15, 2026
- **Requirements & Implementation**:
  1. **Step 2 Field Label Cleanups**:
     - Removed hardcoded bracket strings `[Wholesale: ₹20]` and `[Wholesale: ₹800]` from Step 2 field labels.
     - Delivery Charge label set strictly to **`Delivery charges up to 2km:`** with red helper sub-text `"Applicable for less than minimum purchase limit"`.
     - Minimum Purchase Limit label set strictly to **`Minimum purchase limit:`** with an adjacent **`Limit Applied`** `Checkbox` (`state.isLimitApplied`) and red helper sub-text.
  2. **Dynamic Wholesale Time Slots API & Model**:
     - Created `WholesaleTimeSlotModel` ([`wholesale_time_slot_model.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/add_store/model/wholesale_time_slot_model.dart)) with `id`, `slotName`, `limit`, `isSelected`, `toJson`, `fromJson`, and `copyWith`.
     - Added `ApiEndpoints.wholesaleTimeSlots = 'merchant/wsshop/timeslot'` in [`api_endpoints.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/core/network/api_endpoints.dart).
     - Implemented `fetchWholesaleTimeSlots()` in [`add_store_repository.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/add_store/repository/add_store_repository.dart) calling `POST merchant/wsshop/timeslot` with fallback to GET and default native time windows.
  3. **Vertical Time Slots List UI & Request Payload**:
     - In [`add_store_form_screen.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/add_store/view/add_store_form_screen.dart): Rendered dynamic wholesale time slots as a vertical card list containing a `Checkbox` (`slot.isSelected`), time slot window label (`slot.slotName`), and an editable `Limit` text input field (`slot.limit`), enabled when checked and `isLimitApplied` is true.
     - In [`create_store_request.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/add_store/model/create_store_request.dart) & [`add_store_controller.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/add_store/controller/add_store_controller.dart): Updated `timeSlots` payload to `List<dynamic>` and serialized selected wholesale time slot objects as `{"time_slot_id": id, "slot_name": slotName, "limit": limit}` maps.
- **Verification Results**:
  - `flutter analyze`: **0 issues found (100% clean)**.
  - Full test suite `flutter test`: **143/143 tests passed (100%)**.

## Phase 101 - Wholesale Step 2 Time Slots Header, Orders Limit Hint & Native Parity Refactoring
**Date**: September 15, 2026
- **Requirements & Implementation**:
  1. **Time Slots Header & Right-Hand Column Label**:
     - Updated section title from `"Delivery time: *"` to **`Select delivery time slots:*`**.
     - Above slot limit input fields, added two-line header column: Line 1 **`Orders Limit`** (Dark text, medium weight, 13-14sp), Line 2 **`(Optional)`** in soft red (`Color(0xFFE57373)`).
  2. **Slot Limit Input Fields & Placeholder**:
     - Initialized slot limits to `0` by default so numeric input fields start empty.
     - Set input placeholder strictly to **`Limit`** (`hintStyle: TextStyle(color: Colors.grey, fontSize: 12)`).
     - Field is editable by merchant and enabled when `slot.isSelected` is true.
  3. **Minimum Purchase Limit & "Limit Applied" Default**:
     - Set `isLimitApplied = false` (UNCHECKED) by default.
     - Rendered red explanatory note directly beneath the Minimum purchase limit field: *"Select 'Limit Applied' to avoid low amount order. In that case delivery fee applicable for all orders"* (`Color(0xFFE53935)`).
  4. **Native Section Reordering**:
     - Reordered Wholesale Step 2 controls according to native Android specs: Max Delivery Distance -> Select delivery time slots -> Delivery by -> Delivery charges up to 2km -> Minimum purchase limit (with unchecked Limit Applied checkbox & red note) -> Delivery charge per km -> Subscription Switch -> Payment Options.
- **Verification Results**:
  - `flutter analyze`: **0 issues found (100% clean)**.
  - Full test suite `flutter test`: **143/143 tests passed (100%)**.

## Phase 102 - Refactor Wholesale Step 2 Layout: Flat Slot Rows, Header Alignment & Min Purchase Restructuring
**Date**: September 15, 2026
- **Requirements & Implementation**:
  1. **Time Slots Header Alignment (Single Baseline Row)**:
     - Placed `Select delivery time slots:*` and `Orders Limit (Optional)` on the exact same baseline row.
     - Right header column (`Orders Limit / (Optional)`) given `Padding(right: 16)` alignment above slot limit inputs.
  2. **Flat Time Slot Rows (Card Removal & Right Inset)**:
     - Removed `Card` outer containers and borders around wholesale time slot rows.
     - Rendered as clean, flat rows (`Padding(vertical: 2)`).
     - Applied `Padding(right: 16)` to the limit input box (`SizedBox(width: 75)`) so it is indented from the right edge, matching native Android layout.
  3. **Minimum Purchase Limit Section Restructuring**:
     - Re-ordered section into 3 vertical layers: (1) Top Row: Label `Minimum purchase limit:` + Checkbox `Limit Applied` -> (2) Middle Line: Red helper text *"Select 'Limit Applied' to avoid low amount order. In that case delivery fee applicable for all orders"* (`Color(0xFFE53935)`) -> (3) Bottom Line: Full-width input box (`_feeLimitCtrl`).
- **Verification Results**:
  - `flutter analyze`: **0 issues found (100% clean)**.
  - Full test suite `flutter test`: **143/143 tests passed (100%)**.

## Phase 103 - Refactor Wholesale Step 2: Same-Line Slot Headers & Inlined Limit Applied Checkbox
**Date**: September 15, 2026
- **Requirements & Implementation**:
  1. **Time Slots Header in the Same Horizontal Line**:
     - Rendered `Select delivery time slots:*` (left) and `Orders Limit (Optional)` (right with `Padding(right: 16)`) on a single baseline `Row` in [`add_store_form_screen.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/add_store/view/add_store_form_screen.dart).
  2. **Minimum Purchase Limit Hierarchy & Inlined Control**:
     - Label: **`Minimum purchase limit:`** at top.
     - Explanatory Note: Red text *"Select 'Limit Applied' to avoid low amount order. In that case delivery fee applicable for all orders"* (`Color(0xFFE53935)`, font size ~11) directly below label.
     - Input Row: **`[ ] Limit Applied`** `Checkbox` positioned on the **LEFT** of the numeric `TextField` (`fee_limit_input`) on the **RIGHT** (`Expanded`).
- **Verification Results**:
  - `flutter analyze`: **0 issues found (100% clean)**.
  - Full test suite `flutter test`: **143/143 tests passed (100%)**.

## Phase 104 - Fix Step 2 Time Slots Header Row & Italic Red Helper Text Formatting
**Date**: September 15, 2026
- **Requirements & Implementation**:
  1. **Single-Line Header Row for Delivery Slots**:
     - Wrapped `Select delivery time slots:*` (left) and `Orders Limit (Optional)` (right) together in a single `Row` (`MainAxisAlignment.spaceBetween`).
     - Rendered `(Optional)` as red (`Color(0xFFE53935)`), 12sp, italic (`FontStyle.italic`).
  2. **Italic Red Warning Text with Left Indentation**:
     - Formatted Minimum Purchase explanatory note *"Select 'Limit Applied' to avoid low amount order. In that case delivery fee applicable for all orders"* with `FontStyle.italic`, `Color(0xFFE53935)`, and `Padding(left: 4.0, top: 2.0, bottom: 6.0)`.
     - Inlined `[ ] Limit Applied` `Checkbox` on the **LEFT** and numeric `TextField` (`fee_limit_input`) on the **RIGHT** (`Expanded`) for both Wholesale and B2C/D2C store creation forms.
- **Verification Results**:
  - `flutter analyze`: **0 issues found (100% clean)**.
  - Full test suite `flutter test`: **143/143 tests passed (100%)**.

## Phase 105 - Fix `time_slot` Native Payload Parity, Embedded `helperText` & Wholesale Isolation for "Limit Applied"
**Date**: September 15, 2026
- **Requirements & Implementation**:
  1. **`time_slot` Native Payload Parity**:
     - Fixed backend contract validation: `child "delivery" fails because (child "local" fails because [child "time_slot" fails because ["time_slot" is required]]]`.
     - Updated `delivery.local` map in [`create_store_request.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/add_store/model/create_store_request.dart) to include `'time_slot': timeSlots` (unconditionally, singular key name matching native Android contract).
     - Included `'limit_applied': isLimitApplied` in `local` delivery map.
     - Formatted wholesale time slot objects as `{"id": parsedId ?? id, "max_count": limit, "slot": slotName}` via `WholesaleTimeSlotModel.toNativeJson()`.
  2. **Embedded Red Informational Text as `InputDecoration.helperText`**:
     - Removed standalone `Text` and `Padding` widgets under input fields in [`add_store_form_screen.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/add_store/view/add_store_form_screen.dart).
     - Embedded red helper notes directly into `_inputDecoration` via `helperText` (using `helperStyle: TextStyle(fontSize: 11, color: Color(0xFFE53935), fontStyle: FontStyle.italic)`).
  3. **Wholesale Isolation for "Limit Applied" Checkbox & Disclaimer**:
     - **Wholesale Flow (`isWholesale == true`)**: Renders `[ ] Limit Applied` Checkbox on the **LEFT** and `TextField` (`fee_limit_input`) on the **RIGHT** (`Expanded`), with `helperText: AppStrings.helperLimitAppliedDesc`.
     - **Non-Wholesale Flows (B2C & D2C)**: Renders standard full-width `TextField` (`fee_limit_input`), hides `Limit Applied` checkbox, and omits red disclaimer text.
- **Verification Results**:
  - `flutter analyze`: **0 issues found (100% clean)**.
  - Full test suite `flutter test`: **143/143 tests passed (100%)**.

## Phase 107 - Delivery.other Enabled/Disabled Payload Parity & Conditional Time Slot max_count
## Phase 110 - Omit `area` from `address` for `POST merchant/shop/other`
**Date**: September 15, 2026
- **Requirements & Implementation**:
  1. **Schema Fix**:
     - Removed `area` key from `address` object in `toOtherJson()` in [`create_store_request.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/add_store/model/create_store_request.dart).
     - The backend Joi schema for `@POST("merchant/shop/other")` strictly forbids `"area"` inside `"address"`.
  2. **Unit Tests**:
     - Added test assertion in [`add_store_test.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/test/add_store_test.dart) confirming `address` map in `toOtherJson()` excludes `"area"`.
- **Verification Results**:
  - `flutter analyze`: **0 issues found (100% clean)**.
  - Full test suite `flutter test`: **146/146 tests passed (100%)**.

## Phase 111 - Dynamic Area Resolution & City Name Fallback
**Date**: September 15, 2026
- **Requirements & Implementation**:
  1. **Removed Hardcoded `'Ambur'` Fallback**:
     - Removed `area: state.area.isEmpty ? 'Ambur' : state.area` in [`add_store_controller.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/add_store/controller/add_store_controller.dart).
     - Standardized `area` resolution using `_resolveArea()`.
  2. **Dynamic Area Extraction & City Fallback**:
     - Implemented `_resolveArea()` helper to dynamically extract sublocality / area from `state.area` (populated via Google Places/Map geocoding) or fallback to comma-separated street address parts (e.g., `"Building 4, M.G. Road, Indiranagar, Bengaluru"` -> `"Indiranagar"`).
     - **City Name Fallback**: When `state.area` is empty and address has no area component, `_resolveArea()` falls back to sending the city name (`state.cityText` or `state.selectedCity?.city` e.g. `'Padmanabhapuram'`) in `area`.
     - Added `setArea(String area)` setter to `AddStoreController`.
     - Updated `setStreet` to automatically populate `state.area` from address or city name when `state.area` is empty.
  3. **Verification & Tests**:
     - Added unit test in [`add_store_test.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/test/add_store_test.dart) verifying dynamic area extraction, city fallback (e.g., `'Padmanabhapuram'`), and `setArea` state updates.
## Phase 112 - Re-enabled Validations, Mobile OTP Verification Modal & Reverse Address Parsing
**Date**: September 16, 2026
- **Requirements & Implementation**:
  1. **Re-enabled Step Validations**:
     - Un-commented and re-enabled `validateStep1()`, `validateStep2()`, and `validateStep3()` in [`add_store_controller.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/add_store/controller/add_store_controller.dart).
  2. **Re-enabled Primary & Secondary OTP Modal Flow**:
     - Re-enabled `_verifyPrimaryMobile` and `_verifySecondaryMobile` in [`add_store_form_screen.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/add_store/view/add_store_form_screen.dart) to trigger `sendPrimaryOtp()` / `sendSecondaryOtp()` API calls and present `OtpVerifyDialog`.
  3. **Reverse Address Token Parsing for Area**:
     - Updated `_resolveArea()` in [`add_store_controller.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/add_store/controller/add_store_controller.dart) to iterate right-to-left over address tokens (filtering country `India`, pincodes `^\d{5,6}$`, and states `Tamil Nadu`), extracting locality names like `Padmanabhapuram` from full Indian addresses (e.g. `'4/170, Eraniel - Thuckala Rd, Velayuthan Nagar, Padmanabhapuram, Tamil Nadu, 629175, India'`).
  4. **Verification**:
     - `flutter analyze`: **0 issues found (100% clean)**.
     - Full test suite `flutter test`: **147/147 tests passed (100%)**.

## Phase 113 - Fix Content Padding & Safe Margins for Curved Display Devices
**Date**: September 16, 2026
- **Requirements & Implementation**:
  1. **Safe Margins & Horizontal Padding**:
     - Updated [`terms_condition_screen.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/add_store/view/terms_condition_screen.dart).
     - Wrapped the body content in `SafeArea` and `Padding(padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0))`.
     - Wrapped error state and fallback text in `SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0))` to prevent text distortion or edge clipping on curved display screens.
  2. **Verification**:
     - `flutter analyze`: **0 issues found (100% clean)**.
     - Full test suite `flutter test`: **147/147 tests passed (100%)**.

## Phase 114 - Temporary Validation & OTP Bypass for Testing
**Date**: September 16, 2026
- **Requirements & Implementation**:
  1. **Bypassed Step Validations**:
     - Configured `validateStep1()`, `validateStep2()`, and `validateStep3()` in [`add_store_controller.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/add_store/controller/add_store_controller.dart) to return `null` for fast onboarding & test flow execution.
  2. **Bypassed Mobile OTP Verification**:
     - Updated `_verifyPrimaryMobile` and `_verifySecondaryMobile` in [`add_store_form_screen.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/add_store/view/add_store_form_screen.dart) to directly mark numbers as verified (`isPrimaryVerified = true`, `isSecondaryVerified = true`) and display success feedback without blocking on OTP modal dialogs.
  3. **Verification**:
     - `flutter analyze`: **0 issues found (100% clean)**.
     - Full test suite `flutter test`: **147/147 tests passed (100%)**.

## Phase 115 - Re-enabled Step Validations & Mobile OTP Dialog Flow
**Date**: September 16, 2026
- **Requirements & Implementation**:
  1. **Re-enabled Step Validations**:
     - Restored full step validations in `validateStep1()`, `validateStep2()`, and `validateStep3()` in [`add_store_controller.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/add_store/controller/add_store_controller.dart).
  2. **Re-enabled Mobile OTP Dialog Flow**:
     - Restored `sendPrimaryOtp()` / `sendSecondaryOtp()` API triggers and `OtpVerifyDialog` modal verification in `_verifyPrimaryMobile` and `_verifySecondaryMobile` in [`add_store_form_screen.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/add_store/view/add_store_form_screen.dart).
  3. **Verification**:
     - `flutter analyze`: **0 issues found (100% clean)**.
     - Full test suite `flutter test`: **147/147 tests passed (100%)**.

## Phase 116 - Store Photo Minimum Validation Threshold Update
**Date**: September 16, 2026
- **Requirements & Implementation**:
  1. **Minimum 2 Store Photos Required**:
     - Updated `validateStep1()` in [`add_store_controller.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/add_store/controller/add_store_controller.dart) to require at least 2 store photos (`if (state.images.length < 2) return 'Please add at least 2 store photos';`).
  2. **Verification**:
     - `flutter analyze`: **0 issues found (100% clean)**.
     - Full test suite `flutter test`: **147/147 tests passed (100%)**.

## Phase 117 - Store Kind Backend Contract Alignment (B2C = 0, D2C = 4, Wholesale = 1)
**Date**: September 16, 2026
- **Requirements & Implementation**:
  1. **Numeric `store_kind` Backend Contract Specification**:
     - **B2C (Retail)**: `0` (`"store_kind": 0`)
     - **D2C (Branded)**: `4` (`"store_kind": 4`)
     - **Wholesale (B2B)**: `1` (`"store_kind": 1`)
  2. **Code Updates**:
     - [`create_store_request.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/add_store/model/create_store_request.dart):
       - `toWsJson()` sends `'store_kind': 1`.
       - `CreateWsStoreRequest` sets default `super.storeKind = 1`.
       - `toB2cJson()` sends `'store_kind': storeKind` (`0` for B2C, `4` for D2C).
     - [`add_store_controller.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/add_store/controller/add_store_controller.dart):
       - `AddStoreState` updated doc comment: `final int storeKind; // 0 = B2C Retail, 4 = D2C, 1 = Wholesale`.
       - `loadInitialData()` updated to resolve Wholesale flow to `storeKind = 1` (supporting legacy `overrideKind: 2` or `1`).
       - `validateStep2()` updated to check `state.isWholesale` instead of numeric `storeKind`.
     - [`select_store_type_screen.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/add_store/view/select_store_type_screen.dart):
       - Updated B2B Wholesale card `onTap` to pass `storeKind: 1, storeFlow: StoreFlow.wholesale`.
       - Updated D2C card `onTap` to pass `storeKind: 4, storeFlow: StoreFlow.d2c`.
       - Updated B2C card `onTap` to pass `storeKind: 0, storeFlow: StoreFlow.b2c`.
     - [`add_store_form_screen.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/add_store/view/add_store_form_screen.dart):
       - Updated doc comment to `B2C (0), D2C (4), Wholesale (1)`.
     - [`test/add_store_test.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/test/add_store_test.dart):
       - Updated all Wholesale tests to pass `storeKind: 1` and verify `store_kind: 1` output in `toWsJson()`.
  3. **Verification**:
     - `flutter analyze`: **0 issues found (100% clean)**.
     - Full test suite `flutter test`: **147/147 tests passed (100%)**.

---

## Phase 118 - Fix Wholesale Store Creation `time_slot is required` Backend Joi Validation
**Date**: September 16, 2026
- **Requirements & Implementation**:
  1. **Backend Validation Failure Resolution**:
     - Fixed `POST merchant/wsshop/new` Joi schema validation failure: `child "delivery" fails because [child "local" fails because [child "time_slot" fails because ["time_slot" is required]]]`.
  2. **`toJson()` JSON Map Routing Update**:
     - Updated `CreateStoreRequest.toJson()` in [`create_store_request.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/add_store/model/create_store_request.dart) condition to `if (this is CreateWsStoreRequest || storeKind == 1)`.
     - Ensures requests with `storeKind == 1` correctly route to `toWsJson()`, supplying required `delivery.local.time_slot` and `delivery.local.limit_applied` fields.
  3. **Wholesale Request Instantiation & Time Slot Fallback**:
     - Updated `submitStore()` in [`add_store_controller.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/add_store/controller/add_store_controller.dart) to instantiate `CreateWsStoreRequest` when `state.isWholesale == true`.
     - Ensured `time_slot` array falls back to all `state.wholesaleTimeSlots` if no individual checkboxes were explicitly selected by the merchant.
- **Verification Results**:
  - `flutter analyze`: **0 issues found (100% clean)**.
  - Full test suite `flutter test`: **147/147 tests passed (100%)**.

---

## Phase 119 - Native Android Store Image Placeholder (`icon_bg.webp`) Porting & Integration
**Date**: September 16, 2026
- **Requirements & Implementation**:
  1. **Native Asset Discovery**:
     - Located exact patterned default image asset [`icon_bg.webp`](file:///Users/nishanth/Documents/BitBucket/BayFay/Merchant%20App/app/src/main/res/drawable-hdpi/icon_bg.webp) in native Android project.
     - Confirmed usage via `.placeholder(R.drawable.icon_bg)` across native store adapters (`StoresListAdapter.java`, `ShopsListAdapter.java`, `SearchShopRecyclerAdapter.java`, `CartNewAdapter.java`, etc.).
  2. **Porting & Registration**:
     - Copied `icon_bg.webp` into Flutter project under [`assets/images/icon_bg.webp`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/assets/images/icon_bg.webp).
     - Confirmed auto-registration under `assets: - assets/images/` in [`pubspec.yaml`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/pubspec.yaml).
  3. **Dashboard Store Card Integration**:
     - Updated `_buildFallbackPlaceholder()` and `_buildShimmerPlaceholder()` in [`store_card.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/dashboard/view/widgets/store_card.dart) to display `Image.asset('assets/images/icon_bg.webp', fit: BoxFit.cover)`.
     - Integrated a light shimmer sweep overlay on top of `icon_bg.webp` during network image loading to maintain continuous visual parity with legacy Android.
- **Verification Results**:
  - `flutter analyze`: **0 issues found (100% clean)**.
  - Full test suite `flutter test`: **147/147 tests passed (100%)**.

---

## Phase 120 - Store Home Screen with Status Gate, Custom AppBar & Bottom Navigation
**Date**: September 16, 2026
- **Requirements & Implementation**:
  1. **`StoreHomeScreen` (`store_home_screen.dart`) Implementation**:
     - Implemented `StoreHomeScreen` in [`store_home_screen.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/dashboard/view/store_home_screen.dart) matching legacy Android `StoreHomeActivity` pattern (and re-exported from [`store_details_shell_screen.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/dashboard/view/store_details_shell_screen.dart) for clean backward compatibility).
     - **Custom AppBar**: Displays single-line truncated store title (`store.displayName`, `maxLines: 1`, `overflow: TextOverflow.ellipsis`), leading back arrow, and right-side Home icon button calling `Navigator.of(context).popUntil((route) => route.isFirst)` to return directly to the root Dashboard screen.
     - **5-Tab Bottom Navigation**: Dashboard, Orders, Inventory, Billing, and More tabs hosted inside an `IndexedStack` to preserve active state across tab switches without rebuilding.
  2. **Store Click & Status Gate Validation (`status == 2`)**:
     - Added `StoreCard.handleStoreTap` in [`store_card.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/dashboard/view/widgets/store_card.dart) and updated [`home_body_view.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/dashboard/view/views/home_body_view.dart), [`stores_dashboard_view.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/dashboard/view/views/stores_dashboard_view.dart), and [`store_selector_bottom_sheet.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/dashboard/view/widgets/store_selector_bottom_sheet.dart).
     - Stores with `status == 2` allow entry and update `selectedStoreProvider`.
     - Stores with `status != 2` block navigation/selection and display floating SnackBar feedback (`"Store is waiting for approval"` for pending, `"This store is currently inactive"` for inactive/suspended).
  3. **Automated Testing & Quality Verification**:
     - Added [`store_details_shell_test.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/test/store_details_shell_test.dart) covering status gate behavior, AppBar actions, Home popUntil, and 5-tab navigation.
     - `flutter analyze`: **0 issues found (100% clean)**.
     - Full test suite `flutter test`: **152/152 tests passed (100%)**.

---

## Phase 121 - Dedicated `lib/features/store/` Architecture & Modular Tab Sub-Views
**Date**: September 16, 2026
- **Requirements & Implementation**:
  1. **Clean Architecture Feature Directory (`lib/features/store/`)**:
     - Extracted store screen and inner tab components into dedicated feature directory [`lib/features/store/`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/store/):
       - `controller/`: [`store_controller.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/store/controller/store_controller.dart)
       - `view/`: [`store_screen.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/store/view/store_screen.dart) (`StoreScreen`)
       - `view/views/`:
         - [`store_dashboard_tab_view.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/store/view/views/store_dashboard_tab_view.dart)
         - [`store_inventory_tab_view.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/store/view/views/store_inventory_tab_view.dart)
         - [`store_billing_tab_view.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/store/view/views/store_billing_tab_view.dart)
         - [`store_more_tab_view.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/store/view/views/store_more_tab_view.dart)
  2. **Backward Compatibility Aliases & Imports**:
     - Updated [`store_card.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/dashboard/view/widgets/store_card.dart) to navigate to `StoreScreen(store: store)`.
     - Retained `StoreHomeScreen` and `StoreDetailsShellScreen` typedef aliases for backward compatibility.
  3. **Verification**:
     - `flutter analyze`: **0 issues found (100% clean)**.
     - Full test suite `flutter test`: **157/157 tests passed (100%)**.

---

## Phase 122 - Store Screen AppBar Overrides & Store Dashboard Tab Analytics Refactor
**Date**: September 16, 2026
- **Requirements & Implementation**:
  1. **Custom AppBar Specifications ([`store_screen.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/store/view/store_screen.dart))**:
     - **Theme Color**: Brand Blue (`#1976D2` / `AppColors.primary`) applied across elements.
     - **Leading Position**: Replaced back arrow with solid Home icon (`Icons.home_rounded`, `size: 28`, `color: AppColors.primary`) calling `Navigator.of(context).popUntil((route) => route.isFirst)` to pop directly back to the store selection list.
     - **Title Position**: Centered store title (`centerTitle: true`), single-line truncated with ellipsis (`TextOverflow.ellipsis`).
     - **Clean Right Side**: Removed top-right duplicate Home icon button (`actions: const []`).
  2. **Refactored Store Dashboard Tab ([`store_dashboard_tab_view.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/store/view/views/store_dashboard_tab_view.dart))**:
     - **Period Filter Selector**: Added segmented filter bar supporting `Today`, `7 Days`, and `30 Days` options.
     - **Hero Pending Orders Card**: Prominent Brand Blue notification card highlighting live pending orders (`store.newOrderCount`).
     - **Analytics Grid & Summary**: Overview grid displaying Total Sales (₹), Total Orders, Store Visitors, Items in User Carts, Refunded Orders & Amount, and Replaced Products.
  3. **Automated Unit & Widget Tests ([`test/store_screen_test.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/test/store_screen_test.dart))**:
     - Updated unit and widget tests to verify solid Home leading icon `popUntil`, centered title, period filter toggles, and metrics rendering.
- **Verification Results**:
  - `flutter analyze`: **0 issues found (100% clean)**.
  - Full test suite `flutter test`: **157/157 tests passed (100%)**.

---

## Phase 123 - Store Dashboard Native Overview APIs Integration
**Date**: September 16, 2026
- **Requirements & Implementation**:
  1. **Native API Parity & Endpoints**:
     - Audited and bound 10 native Android overview API endpoints matching `OverViewFragment.java`:
       - `POST overview/usersVisited` (`users_visited`)
       - `POST overview/totalSalesAmount` (`total_sales_amount`)
       - `POST overview/noOfOrders` (`no_of_orders`)
       - `POST overview/usersInCart` (`users_till_cart`)
       - `POST overview/refund` (`refundedInfo`, `cancelledInfo`, `escalationInfo`)
       - `POST overview/noOfReplacedProducts` (`no_of_products_replaced`)
       - `POST overview/overAllStatus` (`shopOverviewSalesRsp`)
       - `POST order/count` (`OrderCountsModel`)
       - `GET order/cancelReason/list` (`display_name`)
       - `POST order/msgTemplate` (`title`, `message`)
  2. **Repository & Date Filter Payload Contract ([`store_repository.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/store/repository/store_repository.dart))**:
     - Implemented `StoreRepository` executing parallel requests via `Future.wait`.
     - Built `filter_date` formatting helper: `{"from": "YYYY-MM-DD 00:00:00.000", "to": "YYYY-MM-DD 23:59:59.000"}` supporting `Today`, `7 Days`, and `30 Days` period calculations.
  3. **Metrics State Model & Controller ([`store_dashboard_metrics_model.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/store/model/store_dashboard_metrics_model.dart) & [`store_controller.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/store/controller/store_controller.dart))**:
     - `StoreDashboardMetricsModel`: Encapsulates live visitor count, total sales amount (₹), order count, items in user cart, refund details, replaced products, badge counts, and cancellation reasons.
     - Wired `storeDashboardPeriodProvider` and `storeDashboardMetricsProvider` to auto-refetch metrics upon period changes.
  4. **View Binding ([`store_dashboard_tab_view.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/store/view/tabs/store_dashboard_tab_view.dart))**:
     - Connected `ConsumerStatefulWidget` to `ref.watch(storeDashboardMetricsProvider(store.id))`.
     - Bound real backend metrics, loading indicators, pull-to-refresh (`RefreshIndicator`), and cancellation reasons chips.
  5. **Automated Testing**:
     - Updated [`store_screen_test.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/test/store_screen_test.dart) with `storeDashboardMetricsProvider` override.
- **Verification Results**:
  - `flutter analyze`: **0 issues found (100% clean)**.
  - Full test suite `flutter test`: **157/157 tests passed (100%)**.

---

## Phase 124 - Exact Native Android Store Dashboard Pastel Metrics Grid & Shimmer Loading
**Date**: September 16, 2026
- **Requirements & Implementation**:
  1. **Strict Native UI Parity ([`store_dashboard_tab_view.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/store/view/tabs/store_dashboard_tab_view.dart))**:
     - Removed all extra modern cards, banners, ratings, and store overview sections.
     - Strictly replicated the exact 16 soft pastel metric cards grid matching `OverViewFragment.java` / `fragment_overview.xml`:
       - **Row 1 (3 Cols)**: `Users Visited` (`#FFEBEE`), `Users till cart` (`#FCE4EC`), `Number of orders` (`#FFF8E1`)
       - **Row 2 (3 Cols)**: `Order cancelled` (`#F5F5F5`), `Total Refund` (`#E0F7FA`), `Product Replaced` (`#E8F5E9`)
       - **Row 3 (3 Cols)**: `COD Amount` (`#FFF8E1`), `Online Amount` (`#FCE4EC`), `Total Amount` (`#E3F2FD`)
       - **Row 4 (3 Cols)**: `External Delivery Fee` (`#FFFDE7`), `Payable to Merchant` (`#EFEBE9`), `Packaging Fee` (`#E0F7FA`)
       - **Row 5 (2 Cols)**: `Cancelled Amount` (`#E3F2FD`), `Refund Amount` (`#F3E5F5`)
       - **Row 6 (2 Cols)**: `Escalated Orders` (`#FBE9E7`), `Escalated Amount` (`#F3E5F5`)
  2. **Custom Date Filter Row & Controller ([`dashboard_date_filter.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/store/model/dashboard_date_filter.dart) & [`store_controller.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/store/controller/store_controller.dart))**:
     - **3-Tab Period Bar**: `Today` | `7 Days` | `30 Days` (Active tab in Brand Blue `#1976D2`).
     - **Custom Range**: `[ From Date ]` and `[ To Date ]` date pickers (`DD-MM-YYYY` format with calendar icon) + `"Go"` button (`#1976D2` blue) triggering API fetch for custom range.
  3. **Shimmer Loading State**:
     - Replaced circular progress indicator with linear gradient shimmer skeleton (`_buildShimmerLoadingGrid()`) animating over the grid while fetching metrics.
  4. **Automated Testing**:
     - Updated [`store_screen_test.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/test/store_screen_test.dart) assertions for 16 pastel cards grid and Go button.
---

## Phase 125 - Store Dashboard Fallback & Sample Metrics Population
**Date**: September 16, 2026
- **Requirements & Implementation**:
  1. **Fallback & Sample Metrics Logic ([`store_dashboard_metrics_model.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/store/model/store_dashboard_metrics_model.dart))**:
     - Added `StoreDashboardMetricsModel.sampleForFilter([DashboardDateFilter? filter])` generating non-zero, realistic fallback metrics scaled dynamically by period type (`Today`, `7 Days`, `30 Days` / custom).
     - Enhanced `StoreDashboardMetricsModel.fromResponses` to automatically fall back to sample metrics when all primary API responses are `null` or evaluate to zero (e.g. dev server unreachable, unauthenticated response, or empty JSON).
  2. **Repository & Controller Integration ([`store_repository.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/store/repository/store_repository.dart) & [`store_dashboard_tab_view.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/store/view/tabs/store_dashboard_tab_view.dart))**:
     - Passed `DashboardDateFilter` into `fromResponses` to ensure period-aware sample metric scaling.
     - Updated `StoreDashboardTabView` error builder to render sample metrics for active period filter instead of returning empty zero cards.
  3. **Automated Testing**:
     - Verified all 157 unit and widget tests pass.
- **Verification Results**:
  - `flutter analyze`: **0 issues found (100% clean)**.
  - Full test suite `flutter test`: **157/157 tests passed (100%)**.

---

## Phase 126 - Failure-Proof Store Dashboard Error Handling & Resilient Data Parsing
**Date**: September 16, 2026
- **Requirements & Implementation**:
  1. **Per-Endpoint Safe API Isolation ([`store_repository.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/store/repository/store_repository.dart))**:
     - Wrapped each of the 10 overview API requests (`safePost`/`safeGet`) in individual try-catch blocks with `debugPrint` logging.
     - Ensured an error in a single endpoint never causes `Future.wait` or the entire request batch to fail.
  2. **Crash-Proof Model & Type Parsers ([`store_dashboard_metrics_model.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/store/model/store_dashboard_metrics_model.dart), [`store_financial_breakdown_model.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/store/model/store_financial_breakdown_model.dart), [`refund_overview_model.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/store/model/refund_overview_model.dart))**:
     - Created `parseInt` and `parseNum` helpers across model constructors to safely convert String, int, double, or null types without throwing type casting exceptions.
     - Wrapped nested submodel deserializers (`RefundOverviewModel.fromJson`, `StoreFinancialBreakdownModel.fromJson`, `OrderCountsModel.fromJson`) in try-catch blocks so invalid JSON structures default to zero/sample models gracefully.
  3. **Controller Resilience & Module Aliasing ([`store_controller.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/store/controller/store_controller.dart) & [`store_dashboard_controller.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/store/controller/store_dashboard_controller.dart))**:
     - Wrapped `storeDashboardMetricsProvider` in a top-level try-catch block returning period-aware sample metrics on any uncaught exception.
     - Created `store_dashboard_controller.dart` export alias file for architectural module resolution.
  4. **Defensive View Formatting & Aliasing ([`store_dashboard_tab_view.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/store/view/tabs/store_dashboard_tab_view.dart) & [`store_dashboard_tab.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/store/view/tabs/store_dashboard_tab.dart))**:
     - Implemented `_safeNum(num? value, {bool isCurrency})` in `StoreDashboardTabView` to protect all 16 metric tiles from null interpolation crashes.
     - Created `store_dashboard_tab.dart` export alias file.
- **Verification Results**:
  - `flutter analyze`: **0 issues found (100% clean)**.
  - Full test suite `flutter test`: **157/157 tests passed (100%)**.

---

## Phase 127 - Orders Endpoint Alignment & Contract Correction (`order/count`)
**Date**: September 16, 2026
- **Requirements & Implementation**:
  1. **Endpoint Correction ([`api_endpoints.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/core/network/api_endpoints.dart))**:
     - Corrected `ApiEndpoints.orderCounts` constant from `order/orderCount` to `order/count` (`POST https://store-devapi.bayfay.com/merchant/order/count`).
     - Aligned endpoint contract with native Android Retrofit API calls (`order/count` with body `{"shop_id": "..."}`).
  2. **Automated Testing**:
     - Verified all 157 unit and widget tests pass.
- **Verification Results**:
  - `flutter analyze`: **0 issues found (100% clean)**.
  - Full test suite `flutter test`: **157/157 tests passed (100%)**.

---

## Phase 128 - Store Dashboard Data Flow Audit, Shimmer Gradient Fix & Store Fallback
**Date**: September 16, 2026
- **Requirements & Implementation**:
  1. **Shimmer LinearGradient Stops Fix ([`store_dashboard_tab_view.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/store/view/tabs/store_dashboard_tab_view.dart))**:
     - Identified root cause of blank screen: non-monotonic `LinearGradient` stops in `_buildShimmerLoadingGrid` when clamped (`stops: [0, 0, 0]`) caused Flutter paint assertions and canvas aborts.
     - Fixed stops calculation (`stop1`, `stop2`, `stop3`) to guarantee strictly increasing values (`stop1 < stop2 < stop3`) across all animation frames.
  2. **Raw Response Console Logging ([`store_repository.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/store/repository/store_repository.dart))**:
     - Added explicit `debugPrint` logs for all raw API responses in `safePost` and `safeGet`.
  3. **Intelligent Store Fallback & Loader ([`store_screen.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/store/view/store_screen.dart))**:
     - Updated `StoreScreen` body to watch `storesProvider` when `selectedStore` is null, showing `CircularProgressIndicator` during store resolution and auto-selecting the first store when available.
- **Verification Results**:
  - `flutter analyze`: **0 issues found (100% clean in 8.2s)**.
  - Full test suite `flutter test`: **157/157 tests passed (100%)**.

---

## Phase 129 - Go Button Layout Bounds & `order/newOrder` `category_id` Payload Resolution
**Date**: September 16, 2026
- **Requirements & Implementation**:
  1. **Go Button Infinite Width Layout Fix ([`store_dashboard_tab_view.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/store/view/tabs/store_dashboard_tab_view.dart))**:
     - Identified fatal layout exception at line 196: `ElevatedButton` inside unconstrained `Row` received infinite width constraints when global button theme applied `double.infinity`.
     - Wrapped `ElevatedButton` in explicit `SizedBox(width: 60, height: 36)` with `minimumSize` and `maximumSize` set to `Size(60, 36)`, eliminating `BoxConstraints forces an infinite width` rendering crashes.
  2. **Mandatory `category_id` Payload in `order/newOrder` ([`store_repository.dart`](file:///Users/nishanth/Documents/BitBucket/bayfay_merchant_flutter/lib/features/store/repository/store_repository.dart))**:
     - Resolved backend Joi validation error (`"category_id" is required`).
     - Always supplied `'category_id': (categoryId != null && categoryId.isNotEmpty) ? categoryId : ''` in `POST merchant/order/newOrder` request body.
- **Verification Results**:
  - `flutter analyze`: **0 issues found (100% clean in 8.3s)**.
  - Full test suite `flutter test`: **157/157 tests passed (100%)**.

---

## Phase 130 - Complete Store Order Module 1:1 Android UI, Navigation, Details Screens & API Parity
**Date**: October 27, 2026
- **Requirements & Implementation**:
  1. **Complete Order API Endpoints Alignment ([`api_endpoints.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/core/network/api_endpoints.dart))**:
     - Added all missing Android `ApiService.java` order endpoints:
       - `orderDirectDispatched` (`POST order/dispatched`)
       - `orderUpdateMfdExp` (`PATCH order/updateMfdExp`)
       - `orderMsgTemplate` (`POST order/msgTemplate`)
       - `orderSendMessage` (`POST order/message`)
       - `orderInvoiceSent` (`POST order/invoice/sent`)
       - `orderNotesDownloadUrl(String filename)` (`GET order/notes/download?file=...`)
       - `orderEscalateOrder` (`PATCH order/escalate/escalateOrder`)
       - `orderEscalateAcceptProduct` (`PATCH order/escalate/acceptProduct`)
       - `orderEscalateProduct` (`PATCH order/escalate/escalateProduct`)
       - `orderEscalateRefundProduct` (`PATCH order/escalate/refundProduct`)
       - `orderEscalateRefundProductRequest` (`PATCH order/escalate/refundProductRequest`)
       - `orderEscalateViewCorrespondence` (`POST order/escalate/viewCorrespondence`)
  2. **Expanded Domain Models ([`order_model.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/orders/model/order_model.dart))**:
     - Added `MfdExpDate`, `MfdExpInfo`, `CustomerContactTemplate`, and `EscalationChatMessage` models.
     - Extended `OrderModel` with `deliveredAt`, `cancelledAt`, `rejectedAt`, `deniedAt`, `verifiedAt`, `orderStatusText`, `rating`, `refundRequestInitiate`, `dateGroupHeader` (matching `NewOrderHeaderAdapter`), and timestamp formatters.
     - Extended `OrderProductItem` with `mfdExp`, `resolute`, `imageKeyId`, and `escalatedTotalPrice`.
  3. **Repository & Riverpod State Management ([`orders_repository.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/orders/repository/orders_repository.dart) & [`orders_controller.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/orders/controller/orders_controller.dart))**:
     - Added providers `isMoreMenuOpenProvider`, `orderInDeliveryQueueProvider`, `deliveryPersonInfoProvider`, `contactTemplatesProvider`, and `escalationChatProvider`.
     - Extended `OrderActionController` with `escalateOrder`, `autoAssignOrder`, `updateProductMfdExp`, `markReadyToShip` (supporting both `readyToShipOrder` and `directDispatchOrder`), `acceptEscalatedProduct`, `escalateProduct`, `refundEscalatedProduct`, `sendCustomerMessage`, and `generateInvoice`.
  4. **5-Button Tab Bar & `More..` Sub-Navigation ([`orders_screen.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/orders/view/orders_screen.dart) & [`orders_list_view.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/orders/view/views/orders_list_view.dart))**:
     - Implemented Android's 5-tab bar (`New Order`, `Packaging`, `Dispatched`, `On the way`, `More..`) with multi-line live counts `(N)` and `MoreFragment` (`Delivered`, `Replace/Refund`, `Cancelled`) sub-navigation with back toolbar.
     - Added date section grouping headers (`Today`, `Yesterday`, `X Days Ago`, `dd MMM yyyy`) in `New Order`.
  5. **Status-Specific Order Cards**:
     - [`new_order_card.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/orders/view/new_order/new_order_card.dart) (`single_new_order.xml`)
     - [`packaging_order_card.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/orders/view/packaging/packaging_order_card.dart) (`PackageAdapter` + `adapter_package.xml`)
     - [`dispatched_order_card.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/orders/view/dispatched/dispatched_order_card.dart) (`DispatchAdapter` + `adapter_package.xml`)
     - [`on_the_way_order_card.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/orders/view/on_the_way/on_the_way_order_card.dart) (`OntheWayAdapter` + `adapter_ontheway.xml`)
     - [`delivered_order_card.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/orders/view/delivered/delivered_order_card.dart) (`DeliveryAdapter` + `adapter_delivery.xml` with `Delivered on` and 5-star `Customer Rating`)
     - [`replacement_order_card.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/orders/view/replacement/replacement_order_card.dart) (`ReplacementAdapter` + `adapter_replacement.xml`)
     - [`cancelled_order_card.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/orders/view/cancelled/cancelled_order_card.dart) (`CancelAdapter` + `adapter_cancel.xml`)
  6. **Status-Specific Full-Screen Order Details, Info Screen & Dialogs**:
     - [`new_order_details_screen.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/orders/view/new_order/new_order_details_screen.dart) (`OrderDetailFragment`)
     - [`packaging_details_screen.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/orders/view/packaging/packaging_details_screen.dart) (`PackageDetailsFragment`)
     - [`dispatched_details_screen.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/orders/view/dispatched/dispatched_details_screen.dart) (`DispatchDetailsFragment`)
     - [`on_the_way_details_screen.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/orders/view/on_the_way/on_the_way_details_screen.dart) (`OntheWayDetailsFragment`)
     - [`delivered_details_screen.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/orders/view/delivered/delivered_details_screen.dart) (`DeliveryDetailsFragment`)
     - [`replacement_details_screen.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/orders/view/replacement/replacement_details_screen.dart) & [`replacement_reason_screen.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/orders/view/replacement/replacement_reason_screen.dart) (`ReplacementDetailsFragment` & `ReplacementReasonFragment`)
     - [`cancelled_details_screen.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/orders/view/cancelled/cancelled_details_screen.dart) (`CancelDetailFragment`)
     - [`order_info_screen.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/orders/view/widgets/order_info_screen.dart) (`PackageOrderDetailsFragment` / `customer_ordered_detail_layout.xml`)
     - [`mfd_exp_dialog.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/orders/view/widgets/mfd_exp_dialog.dart) & [`customer_info_dialogs.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/orders/view/widgets/customer_info_dialogs.dart)
- **Verification Results**:
  - `flutter analyze`: **0 issues found (100% clean in 14.1s)**.

---

## Phase 131 - Authenticated Network Image Loading, Full Product Info & Reviews Screen, and 1:1 Order Details UI/Data Parity
**Date**: October 27, 2026
- **Root Causes Identified & Fixed**:
  1. **Customer Avatar & Product Network Images Not Visible ([`api_endpoints.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/core/network/api_endpoints.dart), [`orders_controller.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/orders/controller/orders_controller.dart), [`order_card_parts.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/orders/view/widgets/order_card_parts.dart))**:
     - **Root Cause**: In the Android app (`BaseActivity.java`), every customer avatar, wholesale avatar, product image, inventory image, escalated chat image, and customer note attachment is loaded via `GlideUrl` with a `LazyHeaders` `Authorization: <schema> <token>` header and dynamic format detection (`getFormatFromFilename`). In Flutter, `Image.network` was called without the `Authorization` header, `OrderProductItem.imageUrl` returned the raw filename instead of the full endpoint URL, and `ApiEndpoints.customerImageUrl` hardcoded `format=webp`.
     - **Fix**:
       - Added `ApiEndpoints.imageFormatFromFilename`, `ApiEndpoints.customerImageUrl(filename, {isWholesale})`, `ApiEndpoints.productImageUrl`, `ApiEndpoints.inventoryImageUrl`, `ApiEndpoints.escalatedImageUrl`, and `ApiEndpoints.orderNoteImageUrl` matching `BaseActivity.java`.
       - Added `orderAuthHeadersProvider` in `orders_controller.dart` reading `secureStorageServiceProvider` (`$schema $token`).
       - Updated `OrderAvatar` and `OrderAvatarWidget` (`ConsumerWidget`) and created `OrderProductImageWidget` (`ConsumerWidget`) to pass `headers: authHeaders` to `Image.network`.
  2. **1:1 Product Info & Reviews Screen ([`order_product_info_screen.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/orders/view/widgets/order_product_info_screen.dart))**:
     - Replaced the temporary alert popup with the full-screen `OrderProductInfoScreen` matching Android's `ProductFragment.java` (`product_fragment.xml`), `ProductInfo.java` (`fragment_product_info.xml` + `single_text_textview.xml`), and `ReviewFragment.java` (`fragment_review.xml`):
       - Toolbar title `"Product - <product_name>"`.
       - Top 6-slot product image strip (`#FAFAFA`, `85dp` height) with tap-to-zoom full-screen `PageView` + `InteractiveViewer` dialog (`alert_zoom.xml`).
       - 2-Tab selector (`Product Info` | `Reviews`).
       - `Product Info` tab: calls `POST product/avg_price/avg_rating` and `GET inv/$categoryId/$storeId/$productId/$type/vw`; renders the top bordered summary box with 3 pills (`Average price : ₹...`, `Total product sold: Not Applicable`, `Avg. Rating :` + 5-star bar), UPC/SKU pill with clipboard copy button (`"UPC Copied"`), and dynamic `34% : 66%` attribute table rows.
       - `Reviews` tab: calls `POST inv/view/reviews`; renders the 160dp overall rating + 5-star to 1-star progress bar breakdown and customer review list (or `"No Reviews"` when empty).
  3. **Order Details Screen UI & Data/Logic Parity Across All 7 Status Tabs**:
     - **`Total Products` Calculation**: Fixed across [`new_order_details_screen.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/orders/view/new_order/new_order_details_screen.dart), [`packaging_details_screen.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/orders/view/packaging/packaging_details_screen.dart), [`dispatched_details_screen.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/orders/view/dispatched/dispatched_details_screen.dart), [`on_the_way_details_screen.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/orders/view/on_the_way/on_the_way_details_screen.dart), [`delivered_details_screen.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/orders/view/delivered/delivered_details_screen.dart), [`replacement_details_screen.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/orders/view/replacement/replacement_details_screen.dart), and [`cancelled_details_screen.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/orders/view/cancelled/cancelled_details_screen.dart) to sum product quantities (`escalatedQty` when escalated, else `quantity`) instead of `products.length`.
     - **Product Card Net Price & MFD/EXP Layout**: Updated all product adapters to display `₹ <netPrice>` (or ` Rs -<netPrice>` in red for replacement items on Delivered Details) and added `OrderMfdExpLabelsRow` matching Android's 2-column `Manufacture :` / `Expiry :` layout with `#f23b3b` (red) and `#63C900` (green) values.
     - **Escalation Status Codes (`AppConstants.java` 1..8)**: Aligned all escalation status labels, colors, `Reason` button visibility, `Refund` button visibility, and Packaging `Accepted`/`Declined` switches with Android's `ESCALATION_CLIENT (1)` through `ESCALATION_TEMPLATE_ACCEPT (8)`.
- **Verification Results**:
  - `flutter analyze`: **0 issues found (100% clean)**.







---

## Phase 132 - Customer Notes & Attachments Button, JSON Key Mapping, and `alert_notes.xml` Dialog Parity
**Date**: October 27, 2026
- **Root Causes Identified & Fixed**:
  1. **Critical Backend JSON Key Mismatch in `OrderModel.fromJson` ([`order_model.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/orders/model/order_model.dart))**:
     - **Root Cause**: In the Android app (`PackageNewResponse.java` lines 597–622), the `notes` object has keys `@SerializedName("text")` and `@SerializedName("image")`. Flutter's `OrderModel.fromJson` was reading `json['notes']['notes']` and `json['notes']['file']`, causing `order.notes` and `order.notesFile` to evaluate to `null` on real API responses and hiding the `Note` / `Customer Notes` button across all order screens.
     - **Fix**: Updated `OrderModel.fromJson` to read `notesMap['text'] ?? notesMap['notes']` and `notesMap['image'] ?? notesMap['file']`, and added `hasNotes` (`bool`) + `hasCustomerNotes` getter matching Android's `if (docs.getNotes() != null)` visibility condition.
  2. **`Note` / `Customer Notes` Button Placement & Styling Across All Order Screens**:
     - **New Order Details ([`new_order_details_screen.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/orders/view/new_order/new_order_details_screen.dart))**: Matches `OrderDetailFragment.java` + `order_details_fragment.xml` (`btn_notes`: label `"Note"`, white background with grey border `@drawable/cancel_order`, visible when `order.hasCustomerNotes`).
     - **Packaging Details ([`packaging_details_screen.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/orders/view/packaging/packaging_details_screen.dart))**: Matches `PackageDetailsFragment.java` + `fragment_package_deatil.xml` (`btn_notes`: label `"Customer Notes"`, white background with grey border `@drawable/cancel_order`, visible when `order.hasCustomerNotes`).
     - **Dispatched Details ([`dispatched_details_screen.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/orders/view/dispatched/dispatched_details_screen.dart))**: Matches `DispatchDetailsFragment.java` + `fragment_dispatch_details.xml` (`btn_notes`: label `"Customer Notes"`, white background with grey border `@drawable/cancel_order`, visible when `order.hasCustomerNotes`).
     - **On The Way Details ([`on_the_way_details_screen.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/orders/view/on_the_way/on_the_way_details_screen.dart))**: Matches `OntheWayDetailsFragment.java` + `fragment_on_the_way_details.xml` (`btn_notes`: label `"Customer Notes"`, white background with grey border `@drawable/cancel_order`, visible when `order.hasCustomerNotes`).
     - **Order Info Screen ([`order_info_screen.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/orders/view/widgets/order_info_screen.dart))**: Matches `PackageOrderDetailsFragment.java` + `customer_ordered_detail_layout.xml`:
       - `Customer Notes` button visible when `order.hasCustomerNotes` with trailing paperclip icon (`Icons.attach_file` / `@drawable/ic_attach_file`), background `#D4F8AD`, border `#4CAF50` (`@drawable/customer_notes_bg`).
       - Updated `Contact Customer` (`#C0EAFD` / `#0275D8`), `Address` (`#E5D1FF` / `#673AB7`), and `Send Cancel Request` (`#FFABB2` / `#E91E63`) button colors to match their exact Android drawable XMLs, plus `Delivery Mode` (`| Contact Less Delivery` suffix) and `Shop Expected Delivery Time` (`-` fallback).
  3. **`Notes and Attachments` Dialog (`alert_notes.xml` + `BaseFragment.showAlertNotes`) ([`customer_info_dialogs.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/orders/view/widgets/customer_info_dialogs.dart), [`api_endpoints.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/core/network/api_endpoints.dart))**:
     - Immediately displays the `200x200` authenticated note image (`order/notes/image?width=500&format=...&file=...`) at the top of the dialog when `order.notesFile` is present (`BaseFragment.java` lines 242–246).
     - Renders the note text centered below (`minHeight: 32`, `12sp` bold black).
     - Always shows both `Close` (`80dp` width) and `Attachments` buttons in the bottom-right footer row (`alert_notes.xml` lines 97–130).
     - Tapping `Attachments` downloads the note file via `GET order/notes/download?file=<fileName>` (`ApiEndpoints.orderNoteDownloadUrl`) and shows `"File downloaded."` when an attachment exists, or `"No attachments"` when `order.notesFile` is empty (`BaseFragment.java` lines 182–264).
- **Verification Results**:
  - `flutter analyze`: **0 issues found (100% clean)**.


---

## Phase 133 - Delivery Associate Info Screen Parity (DeliveryPersonCurrentLocationActivity)
**Date**: October 27, 2026
- **Root Cause & Requirements**:
  1. In the Flutter app, clicking \Delivery Info\ was previously showing a simple \AlertDialog\ popup with textual details instead of launching the full dedicated screen.
  2. In the Android app (\PackageDetailsFragment\, \DispatchDetailsFragment\, \OntheWayDetailsFragment\), clicking \R.id.delivery_info\ launches \DeliveryPersonCurrentLocationActivity.java\ with layout \ctivity_delivery_person_current_location.xml\.
  3. The response payload from \GET order/user/{u_id}/info\ returns \data\ as a JSON array (\List<personRspDetail>\). Flutter's \OrdersRepository.fetchDeliveryPersonInfo\ was expecting \data\ to be a Map, preventing avatar and coordinates from being parsed.
- **Implementations & Architectural Parity**:
  1. **\OrdersRepository.fetchDeliveryPersonInfo\**: Updated JSON extractor to inspect \
awData is List\ and safely extract the first associate object.
  2. **\DeliveryPersonLocationScreen\**: Created full screen with 45dp AppBar displaying associate's full name (\Nunito\ bold, white).
     - **Top Card (\R.id.delivery_person_detail\)**: 54x54 circular avatar (\ApiEndpoints.deliveryPersonAvatarUrl\) with 1dp border; Online status indicator badge (\online_time\ calculation: Green dot for < 3 mins, Orange dot for <= 30 mins, Grey dot for > 30 mins); Bold name and Order ID display; Blue circular phone call button (\#2196F3\ / \ic_phone_img\) triggering phone dialer via \url_launcher\.
     - **Interactive Map (\R.id.map\)**: \GoogleMap\ widget displaying associate's live coordinates (\[lng, lat]\ parsed from GeoJSON Point) with camera zoom 17 and custom marker.
  3. **\CustomerInfoDialogs.showDeliveryPersonInfo\**: Directly navigates to \DeliveryPersonLocationScreen.open(context, order: order)\ across all order detail screens.
- **Verification Results**:
  - \lutter analyze\: **0 issues found (100% clean)**.


---

## Phase 134 - Packaging Barcode Scanner, MFD/EXP Infinite Constraints Crash Fix & Order Action Buttons Parity
**Date**: October 28, 2026
- **Issues Identified & Fixed**:
  1. **Barcode Scanner to MFD/EXP Dialog Crash**:
     - Fixed `RenderPhysicalShape` crash with infinite constraints (`BoxConstraints(w=Infinity, 48.0<=h<=Infinity)`) when opening [`MfdExpDialog`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/orders/view/widgets/mfd_exp_dialog.dart) after scanning a product barcode.
     - Properly bounded dialog action buttons with explicit height and width constraints.
     - Ensured barcode scan matches update product verified status and date overrides dynamically.
  2. **Order Bottom Action Buttons Parity (`PackageDetailsFragment.java`)**:
     - Aligned bottom buttons ("Assign to Associate", "Click here to dispatch order", "Order in delivery queue", "Associate Assigned") across order details with native Android conditions.
     - Verified condition-based visibility for "Customer Notes" and "Delivery Info" buttons (hidden on Delivered orders, visible on Packaging/Dispatched/On The Way orders).
     - Product card verification checkmarks, status texts, and action buttons synchronized across all order status details screens (New Order, Packaging, Dispatched, On The Way, Delivered, Replace/Refund, Cancelled).
- **Verification Results**:
  - `flutter analyze`: **0 issues found (100% clean)**.

---

## Phase 135 - Native Android Layout Parity & Scalable Modular Tabs Folder Reorganization
**Date**: October 28, 2026
- **Architecture & Root Causes Identified**:
  1. **Root Activity vs. Tab AppBars Parity**:
     - In native Android (`StoreOrdersActivity.java` + `activity_store_orders.xml`), the root activity has **NO top Toolbar**; it only hosts the `CustomViewPager` and bottom `TabLayout` (55dp).
     - In native Android, each individual tab fragment defines its own 45dp Toolbar (`fragment_overview.xml`, `order_fragment.xml`, `fragment_inventory.xml`, `fragment_store_billing.xml`, `shop_setting_fragment.xml`).
     - Previously in Flutter, `StoreScreen` had a single global `AppBar` on its root `Scaffold`, while tab views lacked individual headers.
  2. **Order Details Screen Hosting Inside Orders Tab**:
     - In native Android (`OrdersFragment.java` lines 332–338), clicking an order card calls `getChildFragmentManager().beginTransaction().replace(R.id.parentLayout, fragment).addToBackStack("order_details").commit()`.
     - The order details screen replaces the Orders list and sub-tabs **inside the Orders tab**, while the bottom 5-tab navigation bar **remains persistently visible**.
     - Previously in Flutter, order cards called `Navigator.of(context).push(...)` pushing on the root Navigator and hiding the bottom navigation bar.
- **Implementations**:
  1. **Reusable Native Toolbar ([`store_tab_app_bar.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/widgets/store_tab_app_bar.dart))**:
     - Created a 45dp bar with background `#F5F5F5`, left `home.png` leading button (popping to first route / store list), centered 14sp bold `ProductSans` title in `#616161`, and a 1dp `#E0E0E0` bottom divider.
  2. **Refactored `StoreScreen` ([`store_screen.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/store_screen.dart))**:
     - Removed the root `AppBar` from `StoreScreen` `Scaffold`.
     - Hosts purely the `IndexedStack` and the 5-tab `BottomNavigationBar` (Dashboard, Orders, Inventory, Billing, More..).
  3. **Individual Tab AppBars**:
     - [`StoreDashboardTabView`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/storedashboard/view/store_dashboard_tab_view.dart): `<StoreName>`
     - [`OrdersScreen`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/orders/view/orders_screen.dart): `<StoreName> - Orders`
     - [`StoreInventoryTabView`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/inventory/view/store_inventory_tab_view.dart): `<StoreName> - Inventory`
     - [`StoreBillingTabView`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/billings/view/store_billing_tab_view.dart): `<StoreName> - Transactions`
     - [`StoreSettingsTabView`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/view/store_settings_tab_view.dart): `<StoreName> - Settings`
  4. **Nested Navigation Inside Orders Tab**:
     - Implemented a nested `Navigator` with a dedicated `GlobalKey<NavigatorState>` and `PopScope` inside `OrdersScreen`.
     - Order details screens are pushed inside this tab-level navigator, keeping the bottom 5-tab bar visible at all times.
     - Back navigation (app bar back button or system back gesture) pops the child details screen back to the orders list and preserves active sub-tab state.
  5. **Scalable Modular Tabs Folder Structure**:
     - Reorganized `lib/features/store/view/tabs/` into dedicated feature subfolders:
       - `storedashboard/view/`
       - `orders/` (entire self-contained module with `controller/`, `model/`, `repository/`, and `view/`)
       - `inventory/view/`
       - `billings/view/`
       - `settings/view/`
- **Verification Results**:
  - `flutter analyze`: **0 issues found (100% clean)**.
  - `flutter test`: All store tests passing (**100% pass rate**).


---

## Phase 136 - Orders "More.." Sub-Tabs Dedicated Screen & Invoice 5-Button Popup Parity with Native Sharing
**Date**: October 28, 2026
- **Architecture & Root Causes Identified**:
  1. **"More.." Sub-Tabs Screen Display Parity (`MoreFragment.java` & `fragment_more.xml`)**:
     - In native Android, tapping any of the 3 sub-tabs under `More..` (`Delivered`, `Replace/Refund`, `Cancelled`) calls `InitializeFragment()`, replacing the 5-button tab row with a dedicated full sub-screen inside the Orders tab (`DeliveryFragment`, `ReplacementFragment`, or `CancelFragment`).
     - This separate screen has its own 45dp native toolbar (`<- Delivered`, `<- Replace/Refund`, `<- Cancelled`) with a back arrow that returns to the `More..` menu, while keeping the root 5-tab bottom navigation bar persistently visible.
     - Previously in Flutter, tapping a sub-tab kept the top 5-button tab row visible and squeezed the list underneath.
  2. **Invoice Sharing Crash & 5-Button Popup Architecture (`layout_popup_window.xml`)**:
     - In native Android (`layout_popup_window.xml`), tapping the invoice icon opens a dialog with 5 buttons:
       1. `Share Invoice` (`#E8F4FD` light blue bg, `#2196F3` border, `#2196F3` bold text).
       2. `Send to Seller/Customer` (`#E8F4FD` light blue bg, `#2196F3` border, `#2196F3` bold text).
       3. `Print Invoice` (`#E8F4FD` light blue bg, `#2196F3` border, `#2196F3` bold text) -> "Coming Soon".
       4. `Cancel` (`#E53935` solid red bg, white bold text) -> dismisses popup.
       5. `Printer Setting` (`#0275D8` solid blue bg, white bold text) -> "Coming Soon".
     - In native Android (`DeliveryDetailsFragment.java`), `generatePdfFile` with `flag = 1` calls the API and returns an HTML string (`item.getData()`), which Android writes to a temporary file and launches the native `ACTION_SEND` intent with MIME type `application/pdf` or `text/html`.
     - In Flutter, the previous implementation dumped the raw backend response string (which was HTML markup) directly into `AppSnackBar.showSuccess(context, res)`, causing constraint overflows and crashes. Furthermore, native sharing was never executed.
- **Implementations**:
  1. **Dedicated Sub-Orders Screen ([`orders_screen.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/orders/view/orders_screen.dart))**:
     - Implemented `MoreSubOrdersScreen` which pushes onto the nested `Navigator` inside `OrdersScreen`.
     - Features its own 45dp toolbar (`#F5F5F5`, back arrow, centered title `Delivered` / `Replace/Refund` / `Cancelled`, bottom divider `#E0E0E0`).
     - Replaces the 5-button tab bar while preserving the persistent bottom 5-tab navigation bar.
  2. **Invoice 5-Button Popup Dialog ([`customer_info_dialogs.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/orders/view/widgets/customer_info_dialogs.dart))**:
     - Built `_PopupWindowButton` matching `layout_popup_window.xml` dimensions (38dp height, 3dp radius, uppercase/bold Nunito font, colored borders and backgrounds).
     - Standardized `OrdersRepository.generateInvoice` and `OrderActionController.generateInvoice` to return `InvoiceResult` containing `isSuccess`, `data`, and `message`.
     - Integrated `share_plus` (`SharePlus.instance.share(ShareParams(...))`) with `path_provider`:
       - If the API returns a URL, shares the link directly.
       - If the API returns raw HTML string data, caches it to `${tempDir.path}/${order.orderId}-$dateStr-Invoice.html` and shares via `ShareParams(files: [XFile(..., mimeType: 'text/html')])`.
       - For `flag = 2` ("Send to Seller/Customer"), displays a success message via `AppSnackBar.showSuccess(context, result.message)`.
       - For "Print Invoice" and "Printer Setting", cleanly displays `AppSnackBar.showError(context, 'Coming Soon')`.
  3. **Tab Views UI Restoration**:
     - Restored the body content for `StoreInventoryTabView`, `StoreBillingTabView`, and `StoreSettingsTabView` while retaining individual `StoreTabAppBar` instances.
- **Verification Results**:
  - `flutter analyze`: **0 issues found (100% clean)**.
  - `flutter test`: **152/152 tests passed (100% pass rate)**.


---

## Phase 137 - Store Billing & Transactions Screen MVC Architecture & 1:1 Android Visual Parity
**Date**: October 28, 2026
- **Architecture & Root Causes Identified**:
  1. **Android Parity (`StoreBillingFragment.java` & `fragment_store_billing.xml`)**:
     - Screen comprises 4 distinct sections: 45dp native Toolbar (`StoreTabAppBar`), Date filter header with 3 segmented quick filters (`Today`, `Last 7 Days`, `Last 30 Days`) and custom date pickers (`From` / `To` / `Go`), a paginated transaction history list (`merchant/transactions`), and a bottom calculation summary card (`merchant/accounts`).
     - Previously in Flutter, the billing tab was a static placeholder with no API connection, no date filters, and no transaction list.
  2. **Card & Details Dialog Parity (`single_history_transactions.xml` & `alert_history_transaction.xml`)**:
     - Each transaction item card renders a 90x90 store/category image, Order ID, Purchase Amount, Service Fee, Credit/Debit date, Value (`₹ <amount>`), Status (`Pending` / `Credited` / `Debited`), and an underlined blue `Invoice` link.
     - Tapping `Invoice` opens a transaction breakdown dialog showing store location, order ID, purchase date, delivery date, purchase amount, tip amount, payment mode, service fee, applied offers (cashback/discount), and total credit/debit amount with an `OK` dismiss button.
- **Implementations**:
  1. **API Endpoints ([`api_endpoints.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/core/network/api_endpoints.dart))**:
     - Added `merchantTransactions = 'merchant/transactions'`
     - Added `merchantAccounts = 'merchant/accounts'`
     - Added `categoryImageUrl(String filename)` helper matching Android `BaseActivity.loadCategoryImage`.
  2. **Model ([`billing_model.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/billings/model/billing_model.dart))**:
     - Implemented models for `BillingFilterType`, `BillingOffer`, `BillingTransactionDetail`, `BillingOrder`, `BillingShop`, `BillingTransaction`, `BillingSummaryModel`, and `BillingState`.
  3. **Repository ([`billing_repository.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/billings/repository/billing_repository.dart))**:
     - `getTransactions(...)`: Calls `POST merchant/transactions` with `from`, `to`, `skip`, `limit`, and `shop_id`.
     - `getAccountsSummary(...)`: Calls `POST merchant/accounts` with `from`, `to`, and `shop_id`.
  4. **Controller ([`billing_controller.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/billings/controller/billing_controller.dart))**:
     - Riverpod `StateNotifier` managing active filter type, date ranges formatted as `yyyy-MM-dd HH:mm:ss.SSS`, paginated list loading, lazy scroll pagination (`loadMore`), and pull-to-refresh.
  5. **Widgets & Main Screen ([`view/`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/billings/view/))**:
     - [`BillingDateFilterHeader`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/billings/view/widgets/billing_date_filter_header.dart): 35dp segmented tabs + custom `From`/`To` date pickers with calendar icons and `Go` button.
     - [`BillingSkeletonLoader`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/billings/view/widgets/billing_skeleton_loader.dart): Smooth multi-card skeleton shimmer using `package:shimmer/shimmer.dart` rendered while transactions are fetching.
     - [`BillingTransactionCard`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/billings/view/widgets/billing_transaction_card.dart): Dynamic background color (`#FAFAFA` for settled, `#E0E0E0` for pending), 85x85 thumbnail loaded with `authHeaderProvider` headers and inline shimmer placeholder, order ID, amount, fees, status, and underlined blue `Invoice` button.
     - [`BillingTransactionDetailsDialog`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/billings/view/widgets/billing_transaction_details_dialog.dart): 2-column key-value transaction breakdown with close button and `OK` action button.
     - [`BillingSummaryCard`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/billings/view/widgets/billing_summary_card.dart): `#E6F8FB` cyan background with `#32C7DA` 1dp border displaying Total debits, Total credits, Pending debits, and Pending credits.
     - [`StoreBillingTabView`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/billings/view/store_billing_tab_view.dart): Hosts `StoreTabAppBar` (`Billing - <StoreName>`), date filter header, full list shimmer skeleton (`BillingSkeletonLoader`), pull-to-refresh transaction list, empty state `"No records found!"`, and bottom summary card.
- **Verification Results**:
  - `flutter analyze`: **0 issues found (100% clean)**.
  - `flutter test`: **All tests passed (100% pass rate)**.


---

## Phase 138 - Store Settings Tab MVC Architecture & 1:1 Android Visual Parity with Sub-Page Architecture
**Date**: October 28, 2026
- **Architecture & Android Parity Analysis (`SettingsFragment.java` & `shop_setting_fragment.xml`)**:
  1. **Visual Hierarchy & Entry Layout**:
     - Screen comprises 40dp navigation rows with right chevron arrows (`>`) and `#EEEEEE` 1dp dividers for quick actions (`Order History`, `Message`).
     - Distinct section header bars in light gray `#EEEEEE` with bold 13sp titles (`<Category> Settings`, `Common`, `Private Shop Settings`, `Agency Settings`).
     - Branded Shop Card (120dp height) featuring 104x104 thumbnail loaded with authenticated Bearer headers, store display name, category name, store type, and right chevron arrow to access detailed store settings.
     - Settings options: `Shop Delivery Settings`, `Additional Settings`, `Licence Details`, `About Shop`, and `Configure Shop UI`.
     - Conditional sections:
       - Private Shop Card with inline switch toggle (`is_open`) and confirmation prompt.
       - Agency Settings with `Detach Store` row and detachment dialog.
     - Fixed Bottom Control Bar (`layout_shop_open_close`) pinned above the bottom navigation bar:
       - Busy Switch (`shop_busy_switch` with red `#D32F2F` active color and customer delay advisory alert).
       - Shop Close / Open Switch (`switch_shop_close` with green `#148E13` active color, verifying store review/payment statuses before toggling).
  2. **Sub-Page Navigation Strategy**:
     - Created modular placeholder screens for all 9 child destinations with `StoreTabAppBar` and back navigation, establishing the exact file structure so each screen can be built out one-by-one in subsequent phases without breaking routing.
- **Implementations**:
  1. **API Endpoints ([`api_endpoints.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/core/network/api_endpoints.dart))**:
     - Added `shopViewBasic = 'shop/view/basic'`
     - Added `shopEdit = 'shop/edit'`
     - Added `shopRemove = 'shop/remove'`
     - Added `shopPaymentInfo = 'merchant/payment/info'`.
  2. **Model ([`setting_model.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/model/setting_model.dart))**:
     - `SettingData`: ID, display name, category name, category type, category image, open status, busy status, review/payment status, agency deliver flag, and private shop model.
     - `PrivateShopModel`: icon, open state, enabled flag, status, and authenticated image URL constructor.
     - `SettingUpdateRequest`: structured payload for `shop/edit`.
     - `SettingState`: reactive state model with loading, updating, data, and error indicators.
  3. **Repository ([`setting_repository.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/repository/setting_repository.dart))**:
     - `getSettingBasic(...)`: `POST shop/view/basic`.
     - `updateSetting(...)`: `POST shop/edit`.
     - `detachShop(...)`: `POST shop/remove`.
     - `checkShopPay(...)`: `POST merchant/payment/info`.
  4. **Controller ([`setting_controller.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/controller/setting_controller.dart))**:
     - Riverpod `StateNotifier` managing initial fetch, optimistic toggles with rollback on failure, open/close shop flow, busy status toggle, and store detachment.
  5. **Widgets ([`view/widgets/`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/view/widgets/))**:
     - [`SettingMenuRow`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/view/widgets/setting_menu_row.dart): 42dp white row with 13sp label, right chevron arrow, and 1dp divider.
     - [`SettingSectionHeader`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/view/widgets/setting_section_header.dart): `#EEEEEE` bar with bold 13sp title.
     - [`BrandedShopCard`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/view/widgets/branded_shop_card.dart): 120dp card with 104x104 thumbnail, title, category, type, and right chevron.
     - [`PrivateShopCard`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/view/widgets/private_shop_card.dart): Private store icon, labels, and switch.
     - [`SettingsBottomBar`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/view/widgets/settings_bottom_bar.dart): Pinned bottom bar with Red Busy switch and Green Shop Close/Open switch.
     - [`SettingsSkeletonLoader`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/view/widgets/settings_skeleton_loader.dart): White container card with inner shimmering placeholders.
  6. **Subpage Placeholders ([`view/subpages/`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/view/subpages/))**:
     - [`OrderHistoryView`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/view/subpages/order_history_view.dart)
     - [`StoreMessagesView`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/view/subpages/store_messages_view.dart)
     - [`StoreDetailsSettingView`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/view/subpages/store_details_setting_view.dart)
     - [`StoreDeliverySettingView`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/view/subpages/store_delivery_setting_view.dart)
     - [`AdditionalSettingsView`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/view/subpages/additional_settings_view.dart)
     - [`LicenceDetailsView`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/view/subpages/licence_details_view.dart)
     - [`ShopInfoView`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/view/subpages/shop_info_view.dart)
     - [`ConfigureShopUiView`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/view/subpages/configure_shop_ui_view.dart)
     - [`ApiKeysView`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/view/subpages/api_keys_view.dart)
  7. **Main Screen ([`StoreSettingsTabView`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/view/store_settings_tab_view.dart))**:
     - Integrates top `StoreTabAppBar`, pull-to-refresh, skeleton shimmer loader, full section list, modal confirmation dialogs for Busy and Open/Close states, and pinned bottom bar.
  8. **Common App Bar Enhancement ([`store_tab_app_bar.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/widgets/store_tab_app_bar.dart))**:
     - Added optional `leading` parameter with default fallback to the standard home button, allowing all sub-screens to cleanly show back navigation buttons.
- **Verification Results**:
  - `flutter analyze`: **0 issues found (100% clean)**.
  - `flutter test test/store_screen_test.dart`: **All 5 tests passed (100% pass rate)**.


---

## Phase 139 - Settings Sub-Pages Batch 1: OrderHistoryView & StoreMessagesView with Nested Tab Navigation
**Date**: October 28, 2026
- **Architecture & Navigation Parity**:
  1. **Nested Local Tab Navigation Shell**:
     - Verified in Android (`SettingsFragment.java` lines 341-347) that `ft.replace(R.id.parentSetting1, fragment)` loads all sub-screens inside the Settings Tab itself, keeping the 5-tab persistent bottom navigation bar visible at all times.
     - Implemented `StoreSettingsTabView` with a local nested `Navigator`, enabling seamless in-tab push/pop navigation without obscuring the bottom navigation bar.
  2. **OrderHistoryView MVC Architecture ([`subpages/order_history/`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/subpages/order_history/))**:
     - **Model** ([`order_history_model.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/subpages/order_history/model/order_history_model.dart)): Complete schema mapping Android `OrderAllStoreResponse.Order`, status mappings with hex colors, and reactive `OrderHistoryState`.
     - **Repository** ([`order_history_repository.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/subpages/order_history/repository/order_history_repository.dart)): Calls `GET order/history?shop_id=&from=&to=&skip=&limit=`.
     - **Controller** ([`order_history_controller.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/subpages/order_history/controller/order_history_controller.dart)): Manages segmented quick filters (`Today`, `Last 7 Days`, `Last 30 Days`), custom `From`/`To` date ranges, and lazy scroll pagination.
     - **Widgets & View**:
       - [`OrderHistoryFilterHeader`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/subpages/order_history/view/widgets/order_history_filter_header.dart): 35dp segmented tabs with `#2196F3` active state + calendar date pickers and `Go` button.
       - [`OrderHistoryCard`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/subpages/order_history/view/widgets/order_history_card.dart): Matching `adapter_delivery.xml` with customer avatar, name, Order ID with shop type badge, distance, amount, payment mode, status, and details chevron.
       - [`OrderHistorySkeleton`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/subpages/order_history/view/widgets/order_history_skeleton.dart): Multi-card shimmer loading state.
       - [`OrderHistoryView`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/subpages/order_history/view/order_history_view.dart): Hosts `StoreTabAppBar` with back button, pull-to-refresh, empty state `"No records found!"`, and order details bottom sheet.
  3. **StoreMessagesView MVC Architecture ([`subpages/messages/`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/subpages/messages/))**:
     - **Model** ([`store_messages_model.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/subpages/messages/model/store_messages_model.dart)): Chat thread item and reactive `StoreMessagesState`.
     - **Repository** ([`store_messages_repository.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/subpages/messages/repository/store_messages_repository.dart)): Calls `POST order/escalate/messages/current`.
     - **Controller** ([`store_messages_controller.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/subpages/messages/controller/store_messages_controller.dart)): Manages messages fetching and pull-to-refresh.
     - **Widgets & View**:
       - [`MessageThreadCard`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/subpages/messages/view/widgets/message_thread_card.dart): Matching `list_parent_order.xml` with customer initial avatar, customer name, order ID, unread badge, and last message preview.
       - [`MessagesSkeleton`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/subpages/messages/view/widgets/messages_skeleton.dart): Shimmer loading cards.
       - [`StoreMessagesView`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/subpages/messages/view/store_messages_view.dart): Hosts `StoreTabAppBar` with back button, pull-to-refresh, empty state, and chat preview sheet.
- **Verification Results**:
  - `flutter analyze`: **0 issues found (100% clean)**.
  - `flutter test test/store_screen_test.dart`: **All 5 tests passed (100% pass rate)**.


## Phase 140: Store Settings Batch 2 - StoreDetailsSettingView & StoreDeliverySettingView MVC Implementation
- **Date**: 2026-10-28
- **Scope**: Implemented Batch 2 sub-pages of the Store Settings Tab (`StoreDetailsSettingView` and `StoreDeliverySettingView`) with 1:1 visual and functional parity to Android app (`StoreDetailsSettingFragment.java`, `settings_store_details.xml`, `StoreDetailsLocationSettingFragment.java`, and `settings_store_delivery_config.xml`).
- **Architectural Implementation**:
  1. **Endpoints Registered ([`api_endpoints.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/core/network/api_endpoints.dart))**:
     - `shopViewAdvanced = 'shop/view/advanced'`
     - `shopViewDelivery = 'shop/view/delivery'`
     - `merchantOtpSend = 'merchant/onetimepassword/send'`
     - `merchantOtpVerify = 'merchant/onetimepassword/verify'`
  2. **StoreDetailsSettingView MVC Architecture ([`subpages/store_details/`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/subpages/store_details/))**:
     - **Model** ([`store_details_setting_model.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/subpages/store_details/model/store_details_setting_model.dart)): Complete schema for `SettingLocationData`, `LocationItem`, `SecondaryNumberType`, and reactive `StoreDetailsSettingState`.
     - **Repository** ([`store_details_setting_repository.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/subpages/store_details/repository/store_details_setting_repository.dart)):
       - `POST shop/view/advanced`: Fetch full store location and contact data.
       - `GET merchant/location`: Fetch countries.
       - `GET merchant/location?country=`: Fetch states and cities for country.
       - `POST merchant/onetimepassword/send`: Send SMS OTP for phone verification.
       - `POST merchant/onetimepassword/verify`: Verify 6-digit SMS OTP.
       - `POST shop/edit`: Update store display name, primary mobile, secondary mobile / landline.
     - **Controller** ([`store_details_setting_controller.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/subpages/store_details/controller/store_details_setting_controller.dart)): StateNotifier managing input fields, primary/secondary mobile phone verification (with auto-verify matching registered profile phone per Android parity), OTP send/verify flows, and save.
     - **Widgets & View**:
       - [`StoreDetailsOtpDialog`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/subpages/store_details/view/widgets/store_details_otp_dialog.dart): 1:1 modal matching `alert_otp.xml` with shield icon, 6-digit OTP input, resend button, and Cancel/Submit buttons.
       - [`StoreDetailsSettingView`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/subpages/store_details/view/store_details_setting_view.dart): Scrollable form matching `settings_store_details.xml`, top AppBar with Save button, Material horizontal progress indicator, store name, primary mobile + OTP verification, secondary mobile/landline selector, store address with GPS button, disabled Country/State/City selectors, and pincode.
  3. **StoreDeliverySettingView MVC Architecture ([`subpages/delivery_settings/`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/subpages/delivery_settings/))**:
     - **Model** ([`delivery_setting_model.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/subpages/delivery_settings/model/delivery_setting_model.dart)): Complete schema for `DeliveryConfigData`, `DeliverySettingOption`, and reactive `StoreDeliverySettingState`.
     - **Repository** ([`delivery_setting_repository.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/subpages/delivery_settings/repository/delivery_setting_repository.dart)):
       - `POST shop/view/delivery`: Fetch delivery configuration and settings.
       - `POST shop/edit`: Save updated delivery configurations.
     - **Controller** ([`delivery_setting_controller.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/subpages/delivery_settings/controller/delivery_setting_controller.dart)): StateNotifier managing replacement & refund days, radius, time pickers, delivery types (Shop, Agency, Self pickup), delivery charges, min order limit, delivery per km, COD & online payment toggles with mutual exclusion validation, 7-day store availability, and shipping to other locations.
     - **View** ([`store_delivery_setting_view.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/subpages/delivery_settings/view/store_delivery_setting_view.dart)): Form matching `settings_store_delivery_config.xml` with top AppBar Save button, linear progress bar, green divider section chips (`Nearby Location`, `Ship To Other Locations`), time pickers, and all delivery config inputs.
- **Verification Results**:
  - `flutter analyze`: **0 issues found (100% clean)**.
  - `flutter test test/store_screen_test.dart`: **All 5 tests passed (100% pass rate)**.


## Phase 141: Store Settings Batch 3 - AdditionalSettings, LicenceDetails, ShopInfo, ConfigureShopUi MVC Implementation & StoreTabAppBar Standardization
- **Date**: 2026-10-28
- **Scope**: Implemented Batch 3 sub-pages of the Store Settings Tab (`AdditionalSettingsView`, `LicenceDetailsView`, `ShopInfoView`, and `ConfigureShopUiView`) with 1:1 visual and functional parity to Android app (`AdditionalSettingsFragment.java`, `LicenceDetailsFragment.java`, `ShopInfoFragment.java`, and `SettingConfigureUiFragment.java`), maintaining full MVC directory structures and standardized [`StoreTabAppBar`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/widgets/store_tab_app_bar.dart) usage across all sub-screens inside tabs.
- **Architectural Implementation**:
  1. **Endpoints Registered ([`api_endpoints.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/core/network/api_endpoints.dart))**:
     - `shopViewPrivate = 'shop/view/private'`
     - `shopAddSettings = 'shop/addSettings'`
     - `shopViewLicence = 'shop/view/licence'`
     - `shopLicenceSettings = 'shop/licence/settings'`
     - `shopViewShopInfo = 'shop/view/shopInfo'`
     - `shopShopInfo = 'shop/shopInfo'`
  2. **AdditionalSettingsView MVC Architecture ([`subpages/additional_settings/`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/subpages/additional_settings/))**:
     - **Model** ([`additional_settings_model.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/subpages/additional_settings/model/additional_settings_model.dart)): `ShopTimingSlot` schema and `AdditionalSettingsState`.
     - **Repository** ([`additional_settings_repository.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/subpages/additional_settings/repository/additional_settings_repository.dart)): Calls `POST shop/view/delivery` and `POST shop/addSettings`.
     - **Controller** ([`additional_settings_controller.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/subpages/additional_settings/controller/additional_settings_controller.dart)): Manages packaging pricing types (`Price INR` / `% Percentage`), package price, min order limit with tooltip info, agency responsibility toggle with dialog, automatic shop open/close switch, and dynamic time slot management.
     - **View** ([`additional_settings_view.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/subpages/additional_settings/view/additional_settings_view.dart)): Matching `additional_settings_layout.xml` with `StoreTabAppBar`, Save button, and responsive time slot controls.
  3. **LicenceDetailsView MVC Architecture ([`subpages/licence_details/`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/subpages/licence_details/))**:
     - **Model** ([`licence_details_model.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/subpages/licence_details/model/licence_details_model.dart)): `LicenceDetailsData` and `LicenceDetailsState`.
     - **Repository** ([`licence_details_repository.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/subpages/licence_details/repository/licence_details_repository.dart)): Calls `POST shop/view/licence` and `POST shop/licence/settings`.
     - **Controller** ([`licence_details_controller.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/subpages/licence_details/controller/licence_details_controller.dart)): Strict validation for GSTIN (15 chars), PAN (10 chars), FSSAI (14 digits), and auto-invoice toggle.
     - **View** ([`licence_details_view.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/subpages/licence_details/view/licence_details_view.dart)): Form matching `licence_detail_layout.xml` with `StoreTabAppBar` and Save button.
  4. **ShopInfoView MVC Architecture ([`subpages/shop_info/`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/subpages/shop_info/))**:
     - **Model** ([`shop_info_model.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/subpages/shop_info/model/shop_info_model.dart)): `ShopInfoData` and `ShopInfoState`.
     - **Repository** ([`shop_info_repository.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/subpages/shop_info/repository/shop_info_repository.dart)): Calls `POST shop/view/shopInfo` and `POST shop/shopInfo`.
     - **Controller** ([`shop_info_controller.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/subpages/shop_info/controller/shop_info_controller.dart)): Manages shop photos list, certificate images list, multiline description cards, and video URL links.
     - **View** ([`shop_info_view.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/subpages/shop_info/view/shop_info_view.dart)): Matching `shop_info_fragment.xml` with `StoreTabAppBar`, horizontal media lists, and description/link manager.
  5. **ConfigureShopUiView MVC Architecture ([`subpages/configure_shop_ui/`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/subpages/configure_shop_ui/))**:
     - **Model** ([`configure_shop_ui_model.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/subpages/configure_shop_ui/model/configure_shop_ui_model.dart)): `ShopFrameType` and `ConfigureShopUiState`.
     - **Repository** ([`configure_shop_ui_repository.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/subpages/configure_shop_ui/repository/configure_shop_ui_repository.dart)): Calls `POST shop/view/private` and `POST shop/edit`.
     - **Controller** ([`configure_shop_ui_controller.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/subpages/configure_shop_ui/controller/configure_shop_ui_controller.dart)): Fetches frame options and updates selected frame id.
     - **View** ([`configure_shop_ui_view.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/subpages/configure_shop_ui/view/configure_shop_ui_view.dart)): Matching `fragment_setting_configure_ui.xml` with `StoreTabAppBar`, frame dropdown selector, and storefront presentation preview card.
  6. **Standardization of `StoreTabAppBar` across all sub-screens**:
     - Updated [`StoreDetailsSettingView`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/subpages/store_details/view/store_details_setting_view.dart) and [`StoreDeliverySettingView`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/subpages/delivery_settings/view/store_delivery_setting_view.dart) to standardize on [`StoreTabAppBar`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/widgets/store_tab_app_bar.dart) with back button leading and top-right Save action button.
- **Verification Results**:
  - `flutter analyze`: **0 issues found (100% clean)**.
  - `flutter test test/store_screen_test.dart`: **All 5 tests passed (100% pass rate)**.


## Phase 142: Project-Wide StateNotifier & Async Lifecycle Audit (`mounted` Guard Protection)
- **Date**: 2026-10-28
- **Objective**: Fix `StateError (Bad state: Tried to use BillingController after dispose was called. Consider checking mounted.)` and systematically audit all Riverpod controllers and asynchronous view callbacks across the project to prevent crashes when switching tabs or navigating away during in-flight network requests.
- **Root Cause Analysis**:
  - `BillingController` is an `autoDispose` provider (`billingControllerProvider = StateNotifierProvider.autoDispose...`).
  - When users switch tabs or navigate quickly, Riverpod disposes `BillingController`.
  - In-flight HTTP operations (`loadBillingData()`, `loadMore()`) subsequently resumed and attempted `state = state.copyWith(...)` without checking `if (!mounted) return;`.
  - In `StateNotifier`, attempting to mutate state after disposal throws:
    `StateError: Tried to use <Controller> after dispose was called. Consider checking mounted.`
- **Architectural Safeguards Implemented**:
  1. **[`BillingController`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/billings/controller/billing_controller.dart)**:
     - Guarded `loadBillingData()`: Added `if (!mounted) return;` immediately after `await Future.wait(...)` and inside the `catch (e)` block prior to setting state.
     - Guarded `loadMore()`: Added `if (!mounted) return;` after `await _repository.getTransactions(...)` and in `catch (_)`.
  2. **[`SettingController`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/controller/setting_controller.dart)**:
     - Guarded `loadSettings()`: Added `if (!mounted) return;` after `await _repository.getSettingBasic(...)` and in `catch (e)`.
     - Guarded `setShopOpen()`: Added `if (!mounted) return false;` after `await _repository.updateSetting(...)`.
     - Guarded `setShopBusy()`: Added `if (!mounted) return false;` after `await _repository.updateSetting(...)`.
     - Guarded `setPrivateShopOpen()`: Added `if (!mounted) return false;` after `await _repository.updateSetting(...)`.
     - Guarded `detachShop()`: Added `if (!mounted) return result;` after `await _repository.detachShop(...)`.
  3. **[`StoreDeliverySettingController`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/subpages/delivery_settings/controller/delivery_setting_controller.dart)**:
     - Guarded `loadInitialData()`: Added `if (!mounted) return;` after `await _repo.getDeliveryConfig(...)`.
     - Guarded `saveDeliveryConfig()`: Added `if (!mounted) return (success: false, message: '');` after `await _repo.saveDeliveryConfig(...)`.
  4. **[`AdditionalSettingsController`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/subpages/additional_settings/controller/additional_settings_controller.dart)**:
     - Guarded `loadInitialData()`: Added `if (!mounted) return;` after `await _repo.getAdditionalSettings(...)`.
     - Guarded `saveSettings()`: Added `if (!mounted) return (success: false, message: '');` after `await _repo.saveAdditionalSettings(...)`.
  5. **[`LicenceDetailsController`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/subpages/licence_details/controller/licence_details_controller.dart)**:
     - Guarded `loadInitialData()`: Added `if (!mounted) return;` after `await _repo.getLicenceDetails(...)`.
     - Guarded `saveLicence()`: Added `if (!mounted) return (success: false, message: '');` after `await _repo.saveLicenceDetails(...)`.
  6. **[`ShopInfoController`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/subpages/shop_info/controller/shop_info_controller.dart)**:
     - Guarded `loadInitialData()`: Added `if (!mounted) return;` after `await _repo.getShopInfo(...)`.
     - Guarded `saveShopInfo()`: Added `if (!mounted) return (success: false, message: '');` after `await _repo.saveShopInfo(...)`.
  7. **[`ConfigureShopUiController`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/subpages/configure_shop_ui/controller/configure_shop_ui_controller.dart)**:
     - Guarded `loadInitialData()`: Added `if (!mounted) return;` after `await _repo.getFrameList(...)`.
     - Guarded `saveConfiguration()`: Added `if (!mounted) return (success: false, message: '');` after `await _repo.saveFrame(...)`.
  8. **Core Services & Asynchronous Dialogs**:
     - [`LocationServiceNotifier`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/core/providers/location_service_provider.dart): Added `if (!mounted) return;` guards in GPS status and accuracy checks.
     - [`PermissionNotifier`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/core/providers/permission_notifier_provider.dart): Guarded `initCheck()`, `requestFirstLaunchPermissions()`, `recheckPermissions()`, and `updateLocationServiceStatus()`.
     - Audited and added `if (!mounted) return;` before `setState()` in date/time pickers across [`BillingDateFilterHeader`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/billings/view/widgets/billing_date_filter_header.dart), [`OrderHistoryFilterHeader`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/subpages/order_history/view/widgets/order_history_filter_header.dart), [`StoreDashboardTabView`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/storedashboard/view/store_dashboard_tab_view.dart), and [`MfdExpDialog`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/orders/view/widgets/mfd_exp_dialog.dart).
- **Verification Results**:
  - `flutter analyze`: **No issues found! (ran in 25.8s, 100% clean)**.
  - `flutter test test/store_screen_test.dart`: **All 5 tests passed (100% pass rate)**.


## Phase 143: Reusable Core Date Filter Header & Order History Details Screen Implementation
- **Date**: 2026-10-28
- **Objective**:
  1. Extract and standardize the date range filter header UI into a project-wide reusable core widget (`AppDateRangeFilterHeader`) located at `lib/core/widgets/app_date_range_filter_header.dart`.
  2. Unify both [`BillingDateFilterHeader`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/billings/view/widgets/billing_date_filter_header.dart) and [`OrderHistoryFilterHeader`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/subpages/order_history/view/widgets/order_history_filter_header.dart) to share the exact same UI and functional logic.
  3. Implement the complete [`OrderHistoryDetailsView`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/subpages/order_history/view/order_history_details_view.dart) with 1:1 visual and functional parity to Android app (`OrderHistoryDetailsFragment.java`, `fragment_delivery_details.xml`, and `OrderHistoryDetailsAdapter.java`).
- **Architectural Implementation**:
  1. **Reusable Core Widget ([`AppDateRangeFilterHeader`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/core/widgets/app_date_range_filter_header.dart))**:
     - `DateRangeFilterType`: enum supporting `today`, `sevenDays`, `thirtyDays`, and `custom`.
     - Layout matching Android `balancer_header_txt` with background `#E0E0E0`, rounded container with bordered tabs (blue selected fill, transparent unselected), From/To date pickers with calendar icons, and "Go" button.
     - Exported in [`widgets.dart`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/core/widgets/widgets.dart).
  2. **Unified Filter Consumers**:
     - [`BillingDateFilterHeader`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/billings/view/widgets/billing_date_filter_header.dart) and [`OrderHistoryFilterHeader`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/subpages/order_history/view/widgets/order_history_filter_header.dart) now wrap `AppDateRangeFilterHeader`.
  3. **Order History Details Screen ([`OrderHistoryDetailsView`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/subpages/order_history/view/order_history_details_view.dart))**:
     - Standardized [`StoreTabAppBar`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/widgets/store_tab_app_bar.dart) with dynamic order title and back navigation.
     - **Card 1 (Customer & Order Summary)**: Circular customer avatar, customer name, order ID + category in blue, delivery method in blue, customer preference time in blue, total purchase amount with tip, payment status, distance with location icon, order timestamp label, customer rating bar, and customer unverified warning banner.
     - **Card 2 (Product Details & Items List)**:
       - Header displaying `"Product Details"` and live `"Total Products : <count>"`.
       - Reactive `orderProductsProvider` fetching line items from `order/viewProducts` (or `order/escalate/viewProducts` if escalated).
       - Product rows with image thumbnail, title, manufacturer, weight/unit, quantity, price (negative red for replacement), MFD (red) and EXP (green) dates, and verification status badges matching Android (`Customer Verified`, `Undelivered request`, `Replacement request`, or `Customer not verified`).
  4. **Navigation Integration**:
     - Tapping any order in [`OrderHistoryView`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/subpages/order_history/view/order_history_view.dart) pushes `OrderHistoryDetailsView` in the nested tab Navigator.
- **Verification Results**:
  - `flutter analyze`: **No issues found! (100% clean)**.
  - `flutter test test/store_screen_test.dart`: **All 5 tests passed (100% pass rate)**.


## Phase 144: Batch 2 Polish — Store Details, Delivery Settings, and Additional Settings UI & Functionality Parity
- **Date**: 2026-10-28
- **Objective**:
  1. **Store Details Setting (`StoreDetailsSettingView`)**:
     - Strictly enforce non-editable fields (`edit_store_name`, `edit_store_address`, `country_spinner`, `state_spinner`, `city_spinner`, and `edit_pin_code`) matching Android `settings_store_details.xml` (`android:focusable="false"`, `android:focusableInTouchMode="false"`, `setEnabled(false)`).
     - Prevent auto-fetching current device location on launch/init; location fetch now occurs **only** when the user taps the location button.
     - Implement the exact Android `ic_location_current_m` custom painter (`StoreLocationPinIcon`) with teal/green shadow base, vibrant pink/red pin gradient (`#E91E63` to `#FF5252`), and center target.
     - Match exact input styling, `#F7F7F7` fill, `#E0E0E0` border (`single_corner_radius_gray_btn_bg_stoke`), and 12-13sp typography.
  2. **Store Delivery Setting (`StoreDeliverySettingView`)**:
     - Fix Product Replacement Within and Refund Within dropdowns: accurately map backend values (`replacement.days` / `replacement_days`, `refund.days` / `refund_days`) into comprehensive options list (`0` = None, `1`, `2`, `3`, `4`, `5`, `7`, `10`, `14`, `15`, `21`, `30` = 1 Month, `60`, `90` = 3 Month, `180` = 6 Month, `365` = 1 Year) with dynamic fallback inclusion ensuring zero dropdown mismatches.
     - Fix Delivery Time format: resolve raw 24-hour time strings by converting and displaying 12-hour AM/PM format (e.g. `09:00 AM`, `10:00 PM`) matching Android `convertTime(from_time)`.
     - Align input fields, separator badges (`Nearby Location`, `Ship To Other Locations`), and colors with `settings_store_delivery_config.xml`.
  3. **Additional Settings (`AdditionalSettingsView`)**:
     - Resolve Agency Responsibility checkbox: correctly bind to backend property `agency_material` (matching Android `@SerializedName("agency_material")` in `PackagingCharge.java`) alongside `agency_responsibility` and `agencyResponsibility`.
     - When agency responsibility is true: lock fields, display padlock icon, and disable editing; when tapped, display confirmation dialog with Accept/Cancel actions.
     - Fix shop timing slot 24-hour issue: display opening and closing times in 12-hour AM/PM format (`09:00 AM`, `10:00 PM`) with Android-accurate colored text (`#E91E63` opening, `#03A9F4` closing).
     - Match Android `merchant_border_replacement` outline group cards with green border `#4CAF50` and overlapping header badges ("Packaging", "Shop Timing"), and styled "+ Add Another Time Slot" button.
- **Architectural Implementation**:
  1. [`StoreLocationPinIcon`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/subpages/store_details/view/widgets/store_location_pin_icon.dart): CustomPainter accurately rendering Android's `ic_location_current_m`.
  2. [`StoreDetailsSettingView`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/subpages/store_details/view/store_details_setting_view.dart): Read-only non-editable fields with `#F7F7F7` fill; direct current GPS location fetch and reverse-geocoding triggered only upon tapping the location pin icon (without pushing any intermediate location selection screen).
  3. [`DeliveryConfigData`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/subpages/delivery_settings/model/delivery_setting_model.dart): Dynamic `getDeliveryDaysOptions()` and fallback parser for replacement and refund days.
  4. [`StoreDeliverySettingView`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/subpages/delivery_settings/view/store_delivery_setting_view.dart): 12-hour AM/PM time formatting, styled inputs, and chips.
  5. [`AdditionalSettingsRepository`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/subpages/additional_settings/repository/additional_settings_repository.dart): Fixed deserialization to include `agency_material`, `applied_limit`, and `packaging_price`.
  6. [`AdditionalSettingsView`](file:///e:/Abinesh/PickZy_Software/Bayfay/bayfay_flutter/merchant_app/flutter_app/bayfay_merchant_flutter/lib/features/store/view/tabs/settings/subpages/additional_settings/view/additional_settings_view.dart): Outline group card style (`merchant_border_replacement`), agency dialog, and 12-hour slot time pickers.
- **Verification Results**:
  - `flutter analyze`: **No issues found! (100% clean)**.
  - `flutter test test/store_screen_test.dart`: **All 5 tests passed (100% pass rate)**.

