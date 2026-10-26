import '../config/app_config.dart';

abstract final class ApiEndpoints {
  // Base URLs dynamically driven by active flavor
  static String get baseUrl => AppConfig.instance.serverUrl;
  static int get paymentEnvironment => AppConfig.instance.paymentEnvironment;

  // Auth Endpoints
  static const String login = 'auth/login';
  static const String authMobile = 'auth/mobile';
  static const String authEmail = 'auth/email';
  static String authDynamic(String type) => 'auth/$type';
  static const String signupVerify = 'auth/signup/verify';
  static const String signup = 'auth/signup';
  static const String register = 'auth/signup';
  static const String logout = 'auth/logout';
  static const String refreshToken = 'auth/refresh';
  static const String forgotPasswordVerify = 'auth/forgotpassword/verify';
  static const String resetPassword = 'auth/resetpassword';
  static const String sendOtp = 'auth/send-otp';
  static const String verifyOtp = 'auth/verify-otp';
  static const String forgotPassword = 'auth/forgotpassword/verify';

  // Profile / Merchant
  static const String profile = 'profile';
  static const String businessValue = 'merchant/business/value';
  static const String partnerInfo = 'merchant/partner/info';

  // Shops & Stores
  static const String shops = 'shops';
  static const String shopList = 'merchant/shop/list';
  static const String shopDetails = 'shops/{id}';

  // Add Store — Store Creation Endpoints (matching ApiService.java)
  static const String merchantCategory = 'merchant/category';
  static String merchantCategoryById(int id) => 'merchant/category/$id';
  static const String merchantLocation = 'merchant/location';
  static String merchantLocationByCountry(String country) => 'merchant/location/$country';
  static const String storeOtpSend = 'merchant/onetimepassword/send';
  static const String storeOtpVerify = 'merchant/onetimepassword/verify';
  static const String createStore = 'merchant/shop/new';
  static const String createOtherStore = 'merchant/shop/other';
  static const String createWsStore = 'merchant/wsshop/new';
  static const String wholesaleBuyerReq = 'merchant/wshop/buyer';
  static const String wholesaleTimeSlots = 'merchant/wsshop/timeslot';

  // Products & Categories
  static const String products = 'products';
  static const String categories = 'categories';

  // Orders & Store Order Management (matching ApiService.java contracts)
  static const String orders = 'orders';
  static const String orderDetails = 'orders/{id}';
  static const String orderStatusUpdate = 'orders/{id}/status';
  static const String ordersNew = 'order/newOrder';
  static const String ordersAccepted = 'order/acceptedOrder';
  static const String ordersReady = 'order/readyToShipOrders';
  static const String ordersShipping = 'order/shippingOrders';
  static const String ordersDelivered = 'order/deliveredOrders';
    static const String ordersEscalated = 'order/escalatedOrders';
  static const String ordersCancelled = 'order/cancelledOrders';


  static const String orderAccept = 'order/acceptOrder';
  static const String orderCancel = 'order/cancelOrder';
  static const String orderReadyToShip = 'order/readyToShipOrder';
  static const String orderProducts = 'order/viewProducts';
  static const String orderCounts = 'order/count';

  // Notifications
  static const String notifications = 'notifications';
  static const String notificationCount = 'notify/pushCount';

  // Legal & Web URLs (matching Android AppConstants.TERMS_CONDITIONS)
  static const String termsAndConditionsUrl = 'https://www.bayfay.com/merchant-policy';
}
