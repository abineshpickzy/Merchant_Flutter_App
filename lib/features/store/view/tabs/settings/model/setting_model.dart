import 'package:bayfay_merchant_flutter/core/network/api_endpoints.dart';

/// Private shop configuration inside SettingResponse
class PrivateShopModel {
  final String icon;
  final bool isOpen;
  final bool isEnabled;
  final int status;

  const PrivateShopModel({
    this.icon = '',
    this.isOpen = false,
    this.isEnabled = false,
    this.status = 0,
  });

  factory PrivateShopModel.fromJson(Map<String, dynamic> json) {
    return PrivateShopModel(
      icon: (json['icon'] ?? json['private_icon'] ?? json['category_icon'] ?? '').toString(),
      isOpen: json['is_open'] == true,
      isEnabled: json['is_enabled'] == true,
      status: (json['status'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'icon': icon,
        'is_open': isOpen,
        'is_enabled': isEnabled,
        'status': status,
      };

  PrivateShopModel copyWith({
    String? icon,
    bool? isOpen,
    bool? isEnabled,
    int? status,
  }) {
    return PrivateShopModel(
      icon: icon ?? this.icon,
      isOpen: isOpen ?? this.isOpen,
      isEnabled: isEnabled ?? this.isEnabled,
      status: status ?? this.status,
    );
  }

  /// Builds authenticated category image URL
  String getImageUrl(String baseUrl) {
    if (icon.isEmpty) return '';
    if (icon.startsWith('http://') || icon.startsWith('https://')) return icon;
    final clean = icon.replaceAll('file:///', '').trim();
    final format = ApiEndpoints.imageFormatFromFilename(clean);
    final cleanBase = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    return '${cleanBase}merchant/category/image?width=200&height=200&file=$clean&format=$format';
  }
}

/// Setting Data Model matching Android SettingResponse.Data
class SettingData {
  final String id;
  final String displayName;
  final String categoryName;
  final String categoryType;
  final String categoryImage;
  final bool isOpen;
  final bool isBusy;
  final int shopStatus;
  final int? status;
  final bool isDeliveryAgency;
  final PrivateShopModel? privateShop;

  const SettingData({
    this.id = '',
    this.displayName = '',
    this.categoryName = '',
    this.categoryType = '',
    this.categoryImage = '',
    this.isOpen = false,
    this.isBusy = false,
    this.shopStatus = 0,
    this.status,
    this.isDeliveryAgency = false,
    this.privateShop,
  });

  factory SettingData.fromJson(Map<String, dynamic> json) {
    PrivateShopModel? privShop;
    if (json['private_shop'] is Map<String, dynamic>) {
      privShop = PrivateShopModel.fromJson(json['private_shop'] as Map<String, dynamic>);
    }

    return SettingData(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      displayName: (json['display_name'] ?? json['name'] ?? '').toString(),
      categoryName: (json['category_name'] ?? '').toString(),
      categoryType: (json['category_type'] ?? '').toString(),
      categoryImage: (json['category_image'] ?? json['image'] ?? '').toString(),
      isOpen: json['is_open'] == true,
      isBusy: json['is_busy'] == true,
      shopStatus: (json['shop_status'] as num?)?.toInt() ?? 0,
      status: (json['status'] as num?)?.toInt(),
      isDeliveryAgency: json['is_delivery_agency'] == true || json['AgencyDeliver'] == true,
      privateShop: privShop,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'display_name': displayName,
        'category_name': categoryName,
        'category_type': categoryType,
        'category_image': categoryImage,
        'is_open': isOpen,
        'is_busy': isBusy,
        'shop_status': shopStatus,
        'status': status,
        'is_delivery_agency': isDeliveryAgency,
        'private_shop': privateShop?.toJson(),
      };

  SettingData copyWith({
    String? id,
    String? displayName,
    String? categoryName,
    String? categoryType,
    String? categoryImage,
    bool? isOpen,
    bool? isBusy,
    int? shopStatus,
    int? status,
    bool? isDeliveryAgency,
    PrivateShopModel? privateShop,
  }) {
    return SettingData(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      categoryName: categoryName ?? this.categoryName,
      categoryType: categoryType ?? this.categoryType,
      categoryImage: categoryImage ?? this.categoryImage,
      isOpen: isOpen ?? this.isOpen,
      isBusy: isBusy ?? this.isBusy,
      shopStatus: shopStatus ?? this.shopStatus,
      status: status ?? this.status,
      isDeliveryAgency: isDeliveryAgency ?? this.isDeliveryAgency,
      privateShop: privateShop ?? this.privateShop,
    );
  }

  /// Builds authenticated category image URL
  String getImageUrl(String baseUrl) {
    if (categoryImage.isEmpty) return '';
    if (categoryImage.startsWith('http://') || categoryImage.startsWith('https://')) {
      return categoryImage;
    }
    final clean = categoryImage.replaceAll('file:///', '').trim();
    final format = ApiEndpoints.imageFormatFromFilename(clean);
    final cleanBase = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    return '${cleanBase}merchant/category/image?width=200&height=200&file=$clean&format=$format';
  }
}

/// Setting Update Request Payload matching Android SettingUpdateRequest
class SettingUpdateRequest {
  final String categoryId;
  final String shopId;
  final bool? isOpen;
  final bool? privateIsOpen;
  final bool? isBusy;

  const SettingUpdateRequest({
    required this.categoryId,
    required this.shopId,
    this.isOpen,
    this.privateIsOpen,
    this.isBusy,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (isOpen != null) data['is_open'] = isOpen;
    if (privateIsOpen != null) data['private_is_open'] = privateIsOpen;
    if (isBusy != null) data['is_busy'] = isBusy;

    return {
      'category_id': categoryId,
      'shop_id': shopId,
      'data': data,
    };
  }
}

/// Reactive State for Store Settings Tab
class SettingState {
  final bool isLoading;
  final bool isUpdating;
  final SettingData? data;
  final String? errorMessage;
  final String? successMessage;

  const SettingState({
    this.isLoading = false,
    this.isUpdating = false,
    this.data,
    this.errorMessage,
    this.successMessage,
  });

  SettingState copyWith({
    bool? isLoading,
    bool? isUpdating,
    SettingData? data,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return SettingState(
      isLoading: isLoading ?? this.isLoading,
      isUpdating: isUpdating ?? this.isUpdating,
      data: data ?? this.data,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}
