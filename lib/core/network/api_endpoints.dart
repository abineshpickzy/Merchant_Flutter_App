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
  static const String productAvgPriceRating = 'product/avg_price/avg_rating';
  static String inventoryUpcStatus(
    String categoryId,
    String storeId,
    String productId,
  ) =>
      'inventory/upc/$categoryId/$storeId/$productId';
  static String inventoryProductView(
    String categoryId,
    String storeId,
    String productId,
    String type,
  ) =>
      'inv/$categoryId/$storeId/$productId/$type/vw';
  static const String inventoryProductReviews = 'inv/view/reviews';

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
  static const String orderDirectDispatched = 'order/dispatched';
  static const String orderShip = 'order/shipTheOrder';
  static const String orderDeliver = 'order/deliverTheOrder';
  static const String orderProducts = 'order/viewProducts';
  static const String orderCounts = 'order/count';
  static const String orderCancelReasons = 'order/cancelReason/list';
  static const String orderUpdateMfdExp = 'order/updateMfdExp';
  static const String orderMsgTemplate = 'order/msgTemplate';
  static const String orderSendMessage = 'order/message';
  static const String orderInvoiceSent = 'order/invoice/sent';
  static const String orderHistory = 'order/history';
  static const String orderEscalateMessagesCurrent = 'order/escalate/messages/current';
  static const String orderEscalateMessagesProducts = 'order/escalate/messages/viewProducts';
  static String orderNotesDownloadUrl(String filename) =>
      '${baseUrl}order/notes/download?file=$filename';

  // Delivery Assistant & Assignment Endpoints
  static const String deliveryAssistantActiveList = 'delivery/assistant/active/list';
  static const String deliveryAssistantAssign = 'delivery/assistant/assign';
  static const String deliveryAssistantAutoAssign = 'delivery/assistant/assign/auto';
  static const String deliveryAssistantAutoAssignView = 'delivery/assistant/assign/auto/view';
  static String deliveryAssistantLocation(String id) => 'order/user/$id/info';

  // Escalated & Refund Endpoints
  static const String orderEscalateAccept = 'order/escalate/acceptOrder';
  static const String orderEscalateAcceptTemplate = 'order/escalate/acceptTemplate';
  static const String orderEscalateDenyTemplate = 'order/escalate/denyTemplate';
  static const String orderEscalateDeleteCorrespondence = 'order/escalate/deleteCorrespondence';
  static const String orderEscalateOrder = 'order/escalate/escalateOrder';
  static const String orderEscalateRefund = 'order/escalate/refundOrder';
  static const String orderEscalateRefundRequest = 'order/escalate/refundOrderRequest';
  static const String orderEscalateProducts = 'order/escalate/viewProducts';
  static const String orderEscalateAcceptProduct = 'order/escalate/acceptProduct';
  static const String orderEscalateProduct = 'order/escalate/escalateProduct';
  static const String orderEscalateRefundProduct = 'order/escalate/refundProduct';
  static const String orderEscalateRefundProductRequest = 'order/escalate/refundProductRequest';
  static const String orderEscalateViewCorrespondence = 'order/escalate/viewCorrespondence';

  // Billing & Transactions Endpoints (matching ApiService.java callTransaction & callGetTransactionDetails)
  static const String merchantTransactions = 'merchant/transactions';
  static const String merchantAccounts = 'merchant/accounts';

  // Settings Endpoints (matching ApiService.java callSetting, callSettingUpdate, detachShop)
  static const String shopViewBasic = 'shop/view/basic';
  static const String shopViewAdvanced = 'shop/view/advanced';
  static const String shopViewDelivery = 'shop/view/delivery';
  static const String shopViewPrivate = 'shop/view/private';
  static const String shopAddSettings = 'shop/addSettings';
  static const String shopViewLicence = 'shop/view/licence';
  static const String shopLicenceSettings = 'shop/licence/settings';
  static const String shopViewShopInfo = 'shop/view/shopInfo';
  static const String shopShopInfo = 'shop/shopInfo';
  static const String shopEdit = 'shop/edit';
  static const String shopRemove = 'shop/remove';
  static const String shopPaymentInfo = 'merchant/payment/info';
  static const String merchantOtpSend = 'merchant/onetimepassword/send';
  static const String merchantOtpVerify = 'merchant/onetimepassword/verify';

  // Notifications
  static const String notifications = 'notifications';
  static const String notificationCount = 'notify/pushCount';

  /// Extracts image format from filename matching Android BaseActivity.getFormatFromFilename
  static String imageFormatFromFilename(String filename) {
    final clean = filename.replaceAll('file:///', '').trim();
    final dotIndex = clean.lastIndexOf('.');
    if (dotIndex != -1 && dotIndex < clean.length - 1) {
      final ext = clean.substring(dotIndex + 1).toLowerCase();
      if (ext == 'jpg' || ext == 'jpeg') {
        return 'jpeg';
      }
      return ext;
    }
    return 'png';
  }

  /// Store Category & Shop image URL matching Android BaseActivity.loadCategoryImage
  static String categoryImageUrl(String filename) {
    final clean = filename.replaceAll('file:///', '').trim();
    if (clean.isEmpty) return '';
    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      return clean;
    }
    final format = imageFormatFromFilename(clean);
    return '${baseUrl}merchant/category/image?width=200&height=200&file=$clean&format=$format';
  }

  /// Customer avatar image URL matching Android BaseActivity.loadCustomerImage & loadWholeSaleCustomerImage
  static String customerImageUrl(String filename, {bool isWholesale = false}) {
    final clean = filename.replaceAll('file:///', '').trim();
    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      return clean;
    }
    if (isWholesale) {
      return '${baseUrl}profile/image/view?width=200&height=200&img=$clean';
    }
    final format = imageFormatFromFilename(clean);
    return '${baseUrl}order/customer/image?width=200&height=200&format=$format&file=$clean';
  }

  /// Delivery associate avatar image URL matching Android DeliveryPersonCurrentLocationActivity.loadImage
  static String deliveryPersonAvatarUrl(String filename) {
    final clean = filename.replaceAll('file:///', '').trim();
    if (clean.isEmpty) return '';
    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      return clean;
    }
    return '${baseUrl}profile/image/view?img=$clean&format=png&width=300&height=300';
  }

  /// Order product line-item image URL matching Android BaseActivity.loadProductImage
  static String productImageUrl(String filename, {int? width, int height = 200}) {
    final clean = filename.replaceAll('file:///', '').trim();
    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      return clean;
    }
    final format = imageFormatFromFilename(clean);
    final widthParam = width != null ? 'width=$width&' : '';
    return '${baseUrl}order/product/image?${widthParam}height=$height&format=$format&file=$clean';
  }

  /// Inventory product image URL matching Android BaseActivity.loadInventoryImage (300x300)
  static String inventoryImageUrl(String filename) {
    return productImageUrl(filename, width: 300, height: 300);
  }

  /// Escalated correspondence chat image URL matching Android BaseActivity.loadEscalatedImages
  static String escalatedImageUrl(String filename) {
    final clean = filename.replaceAll('file:///', '').trim();
    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      return clean;
    }
    final format = imageFormatFromFilename(clean);
    return '${baseUrl}order/escalate/image?width=500&file=$clean&format=$format';
  }

  /// Customer order note image URL matching Android BaseActivity.loadNoteImage
  static String orderNoteImageUrl(String filename) {
    final clean = filename.replaceAll('file:///', '').trim();
    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      return clean;
    }
    final format = imageFormatFromFilename(clean);
    return '${baseUrl}order/notes/image?width=500&format=$format&file=$clean';
  }

  /// Customer order note attachment download URL matching Android ApiService.callDownloadNoteImage
  static String orderNoteDownloadUrl(String filename) {
    final clean = filename.replaceAll('file:///', '').trim();
    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      return clean;
    }
    return '${baseUrl}order/notes/download?file=$clean';
  }

  // Legal & Web URLs (matching Android AppConstants.TERMS_CONDITIONS)
  static const String termsAndConditionsUrl = 'https://www.bayfay.com/merchant-policy';
}
