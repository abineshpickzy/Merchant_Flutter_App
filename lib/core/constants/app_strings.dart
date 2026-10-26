abstract final class AppStrings {
  // App General
  static const String appName = 'Bayfay Merchant';
  static const String appTitleDev = 'Merchant-Dev';
  static const String appTitleQa = 'Merchant-Qa';
  static const String appTitleProd = 'Merchant';

  // Common Actions & Buttons
  static const String login = 'Log In';
  static const String merchantLogin = 'Merchant Login';
  static const String register = 'Register';
  static const String signup = 'Merchant Signup';
  static const String submit = 'Submit';
  static const String save = 'Save';
  static const String cancel = 'Cancel';
  static const String ok = 'OK';
  static const String logOut = 'Log Out';
  static const String retry = 'Retry';
  static const String edit = 'Edit';
  static const String delete = 'Delete';
  static const String continueText = 'Continue';
  static const String next = 'Next';
  static const String update = 'Update';
  static const String verify = 'Verify';
  static const String resendOtp = 'Resend OTP';
  static const String forgotPasswordAction = 'Forgot Password?';

  // Auth - Welcome Screen
  static const String welcomeTitle = 'BayFay Merchant';
  static const String welcomeSubtitle = 'Manage your store, products, and orders efficiently';
  static const String welcomeBack = 'Welcome Back';
  static const String poweredBy = 'Powered by BayFay';

  // Auth - Login Screen
  static const String loginHeaderTitle = 'Bayfay Merchant';
  static const String loginHeaderSubtitle =
      'Sign in with your email or mobile number';
  static const String emailOrMobileLabel = 'Email or Mobile Number';
  static const String emailOrMobileHint = 'Enter your Email or Mobile Number';
  static const String passwordLabel = 'Password';
  static const String passwordHint = 'Enter your password';
  static const String dontHaveAccount = "Don't have a merchant account?";

  // Auth - Registration Screen
  static const String registerTitle = 'Merchant Registration';
  static const String joinBayfayTitle = 'Join Bayfay as a Merchant';
  static const String joinBayfaySubtitle =
      'Create your account to start selling products';
  static const String firstNameLabel = 'First Name';
  static const String firstNameHint = 'Enter first name';
  static const String lastNameLabel = 'Last Name';
  static const String lastNameHint = 'Enter last name';
  static const String storeNameLabel = 'Store / Business Name';
  static const String storeNameHint = 'Enter store or business name';
  static const String mobileNumberLabel = 'Mobile Number';
  static const String mobileNumberHint = '9894555037';
  static const String countryCodeIndia = '+91';
  static const String emailLabel = 'Email Address';
  static const String emailHint = 'name@example.com';
  static const String passwordMinCharsLabel = 'Password (min 6 chars)';
  static const String createMerchantAccount = 'Create Merchant Account';
  static const String nextStep = 'Next';
  static const String alreadyHaveAccount = 'Already have an account?';
  static const String registrationSuccess =
      'Registration successful! Please log in.';

  // Auth - Verification Screen
  static const String verificationTitle = 'Account Verification';
  static const String verificationSubtitle =
      'Enter the OTP sent to your mobile number and set your password';
  static const String otpLabel = 'OTP Verification Code';
  static const String otpHint = 'Enter 4-6 digit OTP';
  static const String verifyAndRegister = 'Verify & Register';
  static const String otpSentSuccess = 'OTP sent successfully';
  static const String otpResentSuccess = 'OTP resent successfully';

  // Auth - Forgot & Reset Password Screen
  static const String forgotPasswordTitle = 'Forgot Password';
  static const String forgotPasswordSubtitle =
      'Enter your registered mobile number to receive a verification code';
  static const String getOtp = 'Get OTP';
  static const String resetPasswordTitle = 'Reset Password';
  static const String resetPasswordSubtitle =
      'Enter the OTP and set a new password for your account';
  static const String newPasswordLabel = 'New Password';
  static const String newPasswordHint = 'Enter new password';
  static const String confirmPasswordLabel = 'Confirm Password';
  static const String confirmPasswordHint = 'Confirm new password';
  static const String updatePassword = 'Update Password';
  static const String passwordsDoNotMatch = 'Passwords do not match';
  static const String passwordResetSuccess =
      'Password updated successfully! Please login with your new password.';

  // Dashboard Screen
  static const String dashboardTitle = 'BayFay Merchant';
  static const String merchantDefaultName = 'Merchant';
  static const String activeStores = 'Active Stores';
  static const String todaysOrders = "Today's Orders";
  static const String logoutConfirmTitle = 'Log Out';
  static const String logoutConfirmMessage =
      'Are you sure you want to log out?';

  // Dashboard Tabs & Store Switcher
  static const String tabStores = 'Stores';
  static const String tabOrders = 'Orders';
  static const String tabInventory = 'Inventory';
  static const String tabAccount = 'Account';
  static const String myStores = 'My Stores';
  static const String selectStore = 'Select Store';
  static const String switchStore = 'Switch Active Store';
  static const String addStore = 'Add Store';
  static const String openStatus = 'Open';
  static const String closedStatus = 'Closed';
  static const String newOrders = 'New Orders';
  static const String totalStores = 'Total Stores';
  static const String openStores = 'Open Stores';
  static const String searchStoresHint = 'Search your stores...';
  static const String filterAll = 'All';
  static const String filterRetail = 'Retail';
  static const String filterWholesale = 'Wholesale';
  static const String noStoresFound = 'No stores found';
  static const String noStoresFoundSubtitle =
      'Create your first store to start receiving orders';

  // Navigation Drawer Strings (matching HomeActivity.java)
  static const String drawerStores = 'Stores';
  static const String drawerWholesale = 'Wholesale Shops';
  static const String drawerUsersRoles = 'Users & Roles';
  static const String drawerBillings = 'Billings & Transactions';
  static const String drawerDelivery = 'Delivery Console';
  static const String drawerPromotions = 'Promotions & Messages';
  static const String drawerAbout = 'About BayFay';
  static const String drawerHelp = 'Help & Support';
  static const String drawerLogout = 'Logout';

  // Store Orders Management Strings (matching StoreOrdersActivity & OrdersFragment)
  static const String ordersTitle = 'Store Orders';
  static const String tabNewOrders = 'New';
  static const String tabProcessingOrders = 'Processing';
  static const String tabReadyOrders = 'Ready';
  static const String tabOnTheWayOrders = 'On The Way';
  static const String tabDeliveredOrders = 'Delivered';
  static const String tabCancelledOrders = 'Cancelled';
  static const String acceptOrderAction = 'Accept';
  static const String cancelOrderAction = 'Cancel';
  static const String markReadyAction = 'Mark Ready';
  static const String viewOrderDetails = 'View Details';
  static const String orderDetailsTitle = 'Order Details';
  static const String customerInfo = 'Customer Details';
  static const String orderItems = 'Ordered Products';
  static const String billSummary = 'Bill Summary';
  static const String deliveryMode = 'Delivery Mode';
  static const String paymentMode = 'Payment Mode';
  static const String cancelReasonPrompt = 'Select a reason to cancel this order:';
  static const String cancelReasonOutOfStock = 'Item out of stock';
  static const String cancelReasonStoreBusy = 'Store too busy to fulfill';
  static const String cancelReasonCustomerRequest = 'Customer requested cancellation';
  static const String cancelReasonOther = 'Other operational reason';
  static const String noOrdersInTab = 'No orders in this status';
  static const String noOrdersInTabSubtitle =
      'Incoming orders for this store will appear here in real-time';
  static const String orderAcceptedSuccess = 'Order accepted successfully!';
  static const String orderCancelledSuccess = 'Cancel request sent to BayFay support.';
  static const String orderReadySuccess = 'Order marked as ready for dispatch!';

  // Form Validation Messages
  static const String enterEmailOrMobile =
      'Please enter your email or mobile number';
  static const String enterValidEmail = 'Please enter a valid email address';
  static const String enterValidMobile = 'Please enter a valid 10-digit mobile number';
  static const String mobileDigitsRequired = 'Mobile number must be 10 digits';
  static const String enterPassword = 'Please enter your password';
  static const String passwordMinLength =
      'Password must be at least 6 characters';
  static const String firstNameRequired = 'Please enter your first name';
  static const String lastNameRequired = 'Please enter your last name';
  static const String storeNameRequired = 'Please enter your store/business name';
  static const String emailRequired = 'Please enter an email address';
  static const String mobileRequired = 'Please enter your mobile number';
  static const String enterOtp = 'Enter OTP';
  static const String otpRequired = 'Please enter the OTP';
  static const String fieldRequired = 'This field is required';
  static const String enterValidVerificationCode = 'Enter valid verification code';
  static const String confirmPasswordRequired = 'Please confirm your password';
  static const String locationRequiredForLogin =
      'Please turn on location to log in';
  static const String locationPermissionRequired =
      'Location permission is required to log in';
  static const String locationRequiredForRegister =
      'Please turn on location to register';
  static const String locationPermissionRequiredForRegister =
      'Location permission is required to register';

  // Network & Error Messages
  static const String connectionTimeout =
      'Connection timed out. Please check your network.';
  static const String noInternetConnection = 'No internet connection.';
  static const String serverError = 'Server error occurred';
  static const String sessionExpired =
      'Your session has expired. Please sign in again.';
  static const String requestCancelled = 'Request was cancelled.';
  static const String sslValidationFailed = 'SSL certificate validation failed.';
  static const String unknownNetworkError = 'Unknown network error occurred.';

  // Additional Centralized UI Strings
  static const String bayfayTitle = 'BayFay';
  static const String loggingOn = 'Logging on';
  static const String whatsNewText = 'What new ?';
  static const String goToDashboard = 'Go to Dashboard';
  static const String switchAccount = 'Switch Account';
  static const String accountCreatedSuccess =
      'Account successfully created! Welcome to BayFay.';
  static const String smsVerificationLabel = 'SMS Verification code';
  static const String enterOtpLabel = 'Enter your OTP';
  static const String enterYourMobileNumber = 'Enter your mobile number';
  static const String enterYourEmailId = 'Enter your email id';
  static const String mobileHint10Digit = '10-digit mobile number';
  static const String enterPasswordLabel = 'Enter Password';
  static const String enterOtpHint = 'Enter OTP';
  static const String enter6DigitOtpHint = 'Enter 6-digit OTP';
  static const String reenterPasswordHint = 'Re-enter password';
  static const String navigationMenu = 'Navigation Menu';
  static const String notifications = 'Notifications';
  static const String notificationsScreen = 'Notifications screen';
  static const String createAddStoreFlow = 'Create/Add Store flow';
  static const String productCatalogInventory = 'Product Catalog & Inventory';
  static const String catalogFor = 'Catalog for:';
  static const String selectStoreToManageProducts =
      'Select a store to manage products';
  static const String storeManagement = 'Store Management';
  static const String configureStoreDetails = 'Configure store details and hours';
  static const String notificationPreferences = 'Notification Preferences';
  static const String securityAndPassword = 'Security & Password';
  static const String failedToLoadStores = 'Failed to load stores';
  static const String adminUsersRolesManagement =
      'Admin Users & Roles management';
  static const String billingsTransactionsConsole =
      'Billings & Transactions console';
  static const String deliveryAssociateConsole = 'Delivery Associate Console';
  static const String promotionsMarketing = 'Promotions & Marketing';
  static const String aboutAppDescription =
      'BayFay Merchant Application for retail and wholesale store management.';
  static const String helpSupportContact = 'Help & Support: support@bayfay.com';
  static const String activeBadge = 'ACTIVE';
  static const String openBadge = 'OPEN';
  static const String closedBadge = 'CLOSED';
  static const String wholesaleStore = 'Wholesale Store';
  static const String retailStore = 'Retail Store';
  static const String restaurant = 'Restaurant';
  static const String newBadgeLower = 'new';
  static const String noStoreSelectedTitle = 'No Store Selected';
  static const String noStoreSelectedSubtitle =
      'Select an active merchant store to view and manage incoming orders.';
  static const String chooseStoreAction = 'Choose Store';
  static const String refreshOrders = 'Refresh Orders';
  static const String unableToLoadOrders = 'Unable to load orders';
  static const String noStoreSelected = 'No store selected';
  static const String pleaseSelectStoreToViewOrders =
      'Please select a store to view its orders';
  static const String keepOrder = 'Keep Order';
  static const String confirmCancel = 'Confirm Cancel';
  static const String describeCancelReason =
      'Describe cancellation reason...';
  static const String orderedLabel = 'Ordered:';
  static const String itemDetailsNotSpecified = 'Item details not specified.';
  static const String productsCouldNotBeLoaded =
      'Products could not be loaded.';
  static const String totalBillAmount = 'Total Bill Amount';
  static const String failedToAcceptOrder = 'Failed to accept order';
  static const String failedToCancelOrder = 'Failed to cancel order';
  static const String failedToUpdateOrder = 'Failed to update order';

  // Permissions - Onboarding & Explanations
  static const String permissionsRequiredTitle = 'Permissions Required';
  static const String permissionsOnboardingTitle = 'Welcome to BayFay Merchant';
  static const String permissionsOnboardingSubtitle =
      'To give you the best store management experience, we need a few essential permissions:';

  // Permission Items
  static const String locationPermissionItemTitle = 'Device Location';
  static const String locationPermissionItemDesc =
      'To locate your store, verify delivery coverage, and calculate distance for customers.';
  static const String cameraPermissionItemTitle = 'Camera';
  static const String cameraPermissionItemDesc =
      'To capture product photos and scan order barcodes.';
  static const String mediaPermissionItemTitle = 'Photos & Media';
  static const String mediaPermissionItemDesc =
      'To upload store logos, banners, and catalog product images.';
  static const String notificationPermissionItemTitle = 'Push Notifications';
  static const String notificationPermissionItemDesc =
      'To alert you immediately when new orders, updates, and messages arrive.';

  // Permission Actions
  static const String grantPermissions = 'Continue & Grant Permissions';
  static const String allowAccess = 'Allow Access';
  static const String openAppSettingsAction = 'Open App Settings';
  static const String maybeLater = 'Maybe Later';
  static const String notNow = 'Not Now';

  // Permanently Denied Strings
  static const String permissionPermanentlyDeniedTitle = 'Permission Required';
  static const String permissionPermanentlyDeniedSubtitle =
      'Some required permissions were permanently denied. Please enable them in device settings to access all merchant features.';

  // Location Service (Zomato-style) Strings
  static const String locationOffTitle = 'Device location is off';
  static const String locationOffSubtitle =
      'Turning on device location helps us detect your store, calculate delivery distance, and receive orders smoothly.';
  static const String locationPromptTitle = 'Location is Off';
  static const String locationPromptSubtitle = 'Please turn on device location to continue.';
  static const String enableLocation = 'Enable Location';
  static const String enableGps = 'Enable GPS';
  static const String locationPermissionRequiredTitle = 'Location is Required';
  static const String locationPermissionRequiredSubtitle =
      'Location permission helps verify your merchant store address and route delivery riders accurately.';

  // Add Store & OTP Verification Strings
  static const String verifyMobileNumber = 'Verify Mobile Number';
  static const String enterValidOtp = 'Enter valid OTP';
  static const String enterNumericOtp = 'Enter numeric OTP';
  static const String invalidOtpTryAgain = 'Invalid OTP. Please try again.';
  static const String otpResentSuccessMsg = 'OTP resent successfully';
  static const String weHaveSentCodeTo = 'We have sent a verification code to';
  static const String primaryMobileVerifiedSuccess =
      'Primary mobile number verified successfully!';
  static const String secondaryMobileVerifiedSuccess =
      'Secondary mobile number verified successfully!';
  static const String enterValidPrimaryMobile =
      'Please enter a valid 10-digit primary mobile number';
  static const String enterValidSecondaryMobile =
      'Please enter a valid 10-digit secondary mobile number';
  static const String storeCreatedTitle = 'Store Created!';
  static const String storeCreatedDesc =
      'Your store has been created successfully. It will be live on BayFay after review.';
  static const String storeCreationFailed =
      'Store creation failed. Please check fields.';
  static const String addStoreTitle = 'Add Store';
  static const String addWholesaleStoreTitle = 'Add Wholesale Store';
  static const String addD2CStoreTitle = 'Add D2C Store';
  static const String createWholesaleStoreTitle = 'Create Wholesale Store';
  static const String createNewStoreTitle = 'Create New Store';
  static const String createDigitalStore = 'Create Digital Store';
  static const String selectStoreType = 'Select Store Type';
  static const String chooseStoreTypeSubtitle =
      'Choose the type of store you want to create';
  static const String b2cRetail = 'B2C Retail';
  static const String b2cRetailSubtitle = 'Sell directly to customers';
  static const String d2c = 'D2C';
  static const String d2cSubtitle = 'Direct to consumer brand';
  static const String b2bWholesale = 'B2B Wholesale';
  static const String b2bWholesaleSubtitle = 'Sell in bulk to businesses';
  static const String buyFromWholesale = 'Buy from Wholesale';
  static const String buyFromWholesaleSubtitle = 'Wholesale buyer profile';
  static const String storeInfoStep = 'Store Info';
  static const String operationsStep = 'Operations';
  static const String mediaSubmitStep = 'Create Store';
  static const String confirmStoreLocationTitle = 'Confirm Store Location';
  static const String searchLocationHint = 'Search location...';
  static const String searchStreetAreaLandmark = 'Search street, area or landmark...';
  static const String searchByStreetAreaLandmark = 'Search by street, area, or landmark';
  static const String noLocationsFound = 'No locations found';
  static const String poweredByGoogle = 'powered by Google';
  static const String moveMapToPlacePin = 'Move map to place pin';
  static const String selectedStoreAddress = 'Selected Store Address';
  static const String resolvingAddress = 'Resolving address...';
  static const String locatingAddress = 'Locating address...';
  static const String confirmUpper = 'CONFIRM';
  static const String maxImagesAllowed = 'Maximum 5 images allowed';
  static const String takePhoto = 'Take a Photo';
  static const String chooseFromGallery = 'Choose from Gallery';
  static const String addPhoto = 'Add Photo';
  static const String storeImagesTitle = 'Store Images *';
  static const String storeWorkingDaysTitle = 'Store Availablity *';
  static const String cameraPermissionRequiredTitle = 'Camera Permission Required';
  static const String cameraPermissionRequiredMsg =
      'Camera access is required to capture photos of your store. Please enable camera permission in App Settings.';
  static const String galleryPermissionRequiredTitle = 'Photo Gallery Permission Required';
  static const String galleryPermissionRequiredAndroidMsg =
      'Gallery access is required to select photos of your store. Please enable photo/media permission in App Settings.';
  static const String galleryPermissionRequiredIosMsg =
      'Photo library access is required to select photos of your store. Please enable photo permission in App Settings.';

  // Step 2 Operations & Delivery Strings
  static const String deliveryShippingDetailsTitle =
      'Delivery and Shipping Details (Nearby locations)';
  static const String maxDeliveryDistanceLabel = 'Max delivery distance: *';
  static const String maxDeliveryRadiusLabel = 'Max delivery distance: *';
  static const String deliveryChargeUpTo2KmLabel = 'Delivery charge up to 2 km (₹)';
  static const String applicableLessThanMinPurchaseLimit =
      'Applicable for less than minimum purchase limit';
  static const String helperLimitAppliedDesc =
      "Select 'Limit Applied' to avoid low amount order. In that case delivery fee applicable for all orders";
  static const String minPurchaseLimitLabel = 'Minimum purchase limit (₹)';
  static const String minPurchaseAmountHint = 'Minimum Purchase Amount';
  static const String deliveryChargePerKmLabel = 'Delivery charge per km (₹)';
  static const String after2KmChargeApplicable =
      'After 2 km this charge will be applicable';
  static const String deliveryChargeSubsTitle =
      'Delivery charge applicable for subscription order?';
  static const String deliveryChargeSubsSubtitle =
      'Apply delivery fees to recurring subscription orders';
  static const String deliveryByLabel = 'Delivery by: *';
  static const String deliveryByShop = 'Shop';
  static const String deliveryByAgency = 'Agency';
  static const String deliveryBySelfPickup = 'Self pickup';
  static const String deliveryTimeLabel = 'Delivery time: *';
  static const String timeFromLabel = 'From';
  static const String timeToLabel = 'To';
  static const String codTitle = 'Cash on Delivery (COD)';
  static const String codSubtitle =
      'Allow customers to pay upon receiving orders';
  static const String codAny = 'Any';
  static const String codLimit = 'Limit';
  static const String codAnyAmount = 'Any';
  static const String codApplyLimit = 'Limit';
  static const String maxCodHint = 'Max COD ₹';
  static const String onlinePaymentTitle = 'Online Payment';
  static const String onlinePaymentSubtitle = 'Accept UPI, Cards & Net Banking';
  static const String atLeastOnePaymentMethodRequired =
      'At least one payment method must be enabled';
  static const String productReplacementWithinLabel =
      'Product replacement within: * (In case any escalation)';
  static const String refundWithinLabel =
      'Refund within: * (In case any escalation)';

  // Step 3 Extended Delivery & Privacy Strings
  static const String extendedDeliveryTitle =
      'Ship To Other Locations';
  static const String enableOtherLocations = 'Enable Other locations:';
  static const String selectTargetCountriesLabel = 'Select Target Countries: *';
  static const String deliveryChargeLabel = 'Delivery charge:';
  static const String applicableLessThanMinPurchaseLimitStep3 =
      'Applicable for lessthan minimum purchase limit';
  static const String minPurchaseLimitLabelStep3 = 'Minimum purchase limit:';
  static const String minPurchaseAmountHintStep3 = 'Minimum Purchase Amount';
  static const String enablePrivateChat = 'Enable Private Store';
  static const String termsAndConditionsAgree =
      'I agree to the BayFay shop terms of service and privacy policy.';
}


