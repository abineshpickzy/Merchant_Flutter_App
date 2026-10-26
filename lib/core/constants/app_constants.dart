abstract final class AppConstants {
  // Network Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // Storage Keys
  static const String accessTokenKey = 'bayfay_merchant_access_token';
  static const String accessSchemaKey = 'bayfay_merchant_access_schema';
  static const String refreshTokenKey = 'bayfay_merchant_refresh_token';
  static const String refreshSchemaKey = 'bayfay_merchant_refresh_schema';
  static const String userProfileKey = 'bayfay_merchant_user_profile';
  static const String activeShopIdKey = 'bayfay_merchant_active_shop_id';
  static const String deviceTokenKey = 'bayfay_merchant_device_token';
  static const String permissionOnboardingCompletedKey =
      'bayfay_merchant_permission_onboarding_completed';

  // Google Maps / Places API Key (matches AndroidManifest.xml com.google.android.geo.API_KEY)
  static const String googleMapsApiKey =
      'AIzaSyBHK4QeuEk8smdq4CQlpdDilsTxBtlwpNI';

  // Pagination
  static const int defaultPageSize = 20;
}

abstract final class AppAssets {
  static const String logo = 'assets/images/logo.webp';
  static const String logoTransparent = 'assets/images/logo_transaparent.webp';
  static const String logoSmall = 'assets/images/logo_small_icon.png';
  static const String powerBy = 'assets/images/power_by.webp';
}

abstract final class AppFonts {
  static const String nunito = 'Nunito';
  static const String productSans = 'ProductSans';
  static const String roboto = 'Roboto';
}
