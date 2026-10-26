import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Full DTO for `POST merchant/shop/new` (and `POST merchant/shop/other`).
/// Matches `StoreCreateNewRequest.java` + `CreateNewStoreOtherCategory.java`.
///
/// Submitted as multipart/form-data:
///   - text part  "inputs"  : dart:convert JSON of this model
///   - file parts "image1"…"imageN": compressed JPEG images
class CreateStoreRequest {
  final String categoryId;
  final String displayName;
  final int storeKind;
  final String? storeId; // only when resubmitting
  final String? categoryDescription; // only for "others" category
  final String? contactTime; // only for "others" category

  // GPS
  final double latitude;
  final double longitude;

  // Address
  final String locationId; // city _id from merchant/location
  final String street;
  final int zipcode;
  final String area;

  // Mobile
  final int primaryDialingCode;
  final int primaryNumber;
  final bool primaryVerified;
  final int? secondaryDialingCode;
  final int? secondaryNumber;
  final bool secondaryVerified;

  // Policies
  final bool replacementAccepted;
  final int replacementDays;
  final bool refundAccepted;
  final int refundDays;

  // Availability
  final List<String> availability;

  // Delivery – Local
  final bool localDeliveryEnabled;
  final bool isCod;
  final String codLimitType; // "any" | "limit"
  final double codLimit;
  final bool isOnlinePayment;
  final double deliveryRadius;
  final double deliveryFee;
  final double feeLimit;
  final bool isLimitApplied;
  final double perKmFee;
  final bool isDeliveryFeeSubs;
  final String deliveryFrom;
  final String deliveryTo;

  // Delivery – Other locations
  final bool otherDeliveryEnabled;
  final double otherDeliveryFee;
  final double otherFeeLimit;
  final List<int> otherDeliveryTypes;

  final List<int> deliveryTypes;
  final List<dynamic> timeSlots;

  // Privacy
  final bool isPrivate;

  const CreateStoreRequest({
    required this.categoryId,
    required this.displayName,
    this.storeKind = 0,
    this.storeId,
    this.categoryDescription,
    this.contactTime,
    required this.latitude,
    required this.longitude,
    required this.locationId,
    required this.street,
    required this.zipcode,
    this.area = '',
    this.primaryDialingCode = 91,
    required this.primaryNumber,
    this.primaryVerified = true,
    this.secondaryDialingCode,
    this.secondaryNumber,
    this.secondaryVerified = false,
    this.replacementAccepted = true,
    this.replacementDays = 5,
    this.refundAccepted = true,
    this.refundDays = 5,
    this.availability = const [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
    ],
    this.localDeliveryEnabled = true,
    this.isCod = true,
    this.codLimitType = 'any',
    this.codLimit = 0,
    this.isOnlinePayment = true,
    this.deliveryRadius = 10,
    this.deliveryFee = 40,
    this.feeLimit = 500,
    this.isLimitApplied = false,
    this.perKmFee = 0,
    this.isDeliveryFeeSubs = false,
    this.deliveryFrom = '09:00 AM',
    this.deliveryTo = '09:00 PM',
    this.otherDeliveryEnabled = false,
    this.otherDeliveryFee = 0,
    this.otherFeeLimit = 0,
    this.otherDeliveryTypes = const [1, 1],
    this.deliveryTypes = const [1, 2],
    this.timeSlots = const [],
    this.isPrivate = true,
  });

  /// JSON payload for `@POST("merchant/shop/other")` (Others Category Creation).
  Map<String, dynamic> toOtherJson() {
    return {
      'category_id': 'others',
      if (categoryDescription != null && categoryDescription!.isNotEmpty)
        'category_description': categoryDescription,
      'display_name': displayName,
      if (contactTime != null && contactTime!.isNotEmpty)
        'contact_time': contactTime,
      'mobile': {
        'primary': {
          'dialing_code': primaryDialingCode,
          'number': primaryNumber,
        },
        if (secondaryNumber != null && secondaryNumber! > 0)
          'secondary': {
            'dialing_code': secondaryDialingCode ?? 91,
            'number': secondaryNumber,
          },
      },
      'location': {
        'type': 'Point',
        'coordinates': [longitude, latitude],
      },
      'address': {
        'location_id': locationId,
        'street': street,
        'zipcode': zipcode,
      },
    };
  }

  /// JSON payload for `@POST("merchant/shop/new")` (B2C Retail / D2C Store Creation).
  Map<String, dynamic> toB2cJson() {
    return {
      'category_id': categoryId,
      'display_name': displayName,
      'store_kind': storeKind,
      if (storeId != null) 'store_id': storeId,
      if (categoryDescription != null && categoryDescription!.isNotEmpty)
        'category_description': categoryDescription,
      if (contactTime != null && contactTime!.isNotEmpty)
        'contact_time': contactTime,
      'location': {
        'type': 'Point',
        'coordinates': [longitude, latitude],
      },
      'address': {
        'location_id': locationId,
        'street': street,
        'zipcode': zipcode,
        if (area.isNotEmpty) 'area': area,
      },
      'mobile': {
        'primary': {
          'dialing_code': primaryDialingCode,
          'number': primaryNumber,
        },
        if (secondaryNumber != null && secondaryNumber! > 0)
          'secondary': {
            'dialing_code': secondaryDialingCode ?? 91,
            'number': secondaryNumber,
          },
      },
      'replacement': {
        'is_accepted': replacementAccepted,
        'days': replacementDays,
      },
      'refund': {
        'is_accepted': refundAccepted,
        'days': refundDays,
      },
      'availability': formatAvailability(availability),
      'delivery': {
        'local': {
          'is_enabled': localDeliveryEnabled,
          'is_cod': isCod,
          'is_cod_limit_type': codLimitType,
          'is_cod_limit': codLimit,
          'is_online_payment': isOnlinePayment,
          'radius': deliveryRadius,
          'fee': deliveryFee,
          'fee_limit': feeLimit,
          'per_km_fee': perKmFee,
          'is_delivery_fee_subs': isDeliveryFeeSubs,
          'from': formatDeliveryTimeIso(deliveryFrom),
          'to': formatDeliveryTimeIso(deliveryTo),
          'offset': '19800000',
          'type': deliveryTypes,
        },
        'other': {
          'fee': otherDeliveryEnabled
              ? (otherDeliveryFee == otherDeliveryFee.toInt()
                  ? otherDeliveryFee.toInt()
                  : otherDeliveryFee)
              : 0,
          'fee_limit': otherDeliveryEnabled
              ? (otherFeeLimit == otherFeeLimit.toInt()
                  ? otherFeeLimit.toInt()
                  : otherFeeLimit)
              : 0,
          'is_cod': false,
          'is_cod_limit': 0,
          'is_enabled': otherDeliveryEnabled,
          'type': otherDeliveryTypes,
        },
      },
      'private': {'is_enabled': isPrivate},
    };
  }

  /// JSON payload for `@POST("merchant/wsshop/new")` (B2B Wholesale Store Creation).
  Map<String, dynamic> toWsJson() {
    return {
      'category_id': categoryId,
      'display_name': displayName,
      'store_kind': 1,
      if (storeId != null) 'store_id': storeId,
      if (categoryDescription != null && categoryDescription!.isNotEmpty)
        'category_description': categoryDescription,
      if (contactTime != null && contactTime!.isNotEmpty)
        'contact_time': contactTime,
      'location': {
        'type': 'Point',
        'coordinates': [longitude, latitude],
      },
      'address': {
        'location_id': locationId,
        'street': street,
        'zipcode': zipcode,
        if (area.isNotEmpty) 'area': area,
      },
      'mobile': {
        'primary': {
          'dialing_code': primaryDialingCode,
          'number': primaryNumber,
        },
        if (secondaryNumber != null && secondaryNumber! > 0)
          'secondary': {
            'dialing_code': secondaryDialingCode ?? 91,
            'number': secondaryNumber,
          },
      },
      'replacement': {
        'is_accepted': false,
        'days': 0,
      },
      'refund': {
        'is_accepted': refundAccepted,
        'days': refundDays,
      },
      'availability': formatAvailability(availability),
      'delivery': {
        'local': {
          'is_enabled': localDeliveryEnabled,
          'is_cod': isCod,
          'is_cod_limit_type': codLimitType,
          'is_cod_limit': codLimit,
          'is_online_payment': isOnlinePayment,
          'radius': deliveryRadius,
          'fee': deliveryFee,
          'fee_limit': feeLimit,
          'limit_applied': isLimitApplied,
          'per_km_fee': perKmFee,
          'is_delivery_fee_subs': isDeliveryFeeSubs,
          'offset': '19800000',
          'type': deliveryTypes,
          'time_slot': timeSlots,
        },
        'other': {
          'fee': otherDeliveryEnabled
              ? (otherDeliveryFee == otherDeliveryFee.toInt()
                  ? otherDeliveryFee.toInt()
                  : otherDeliveryFee)
              : 0,
          'fee_limit': otherDeliveryEnabled
              ? (otherFeeLimit == otherFeeLimit.toInt()
                  ? otherFeeLimit.toInt()
                  : otherFeeLimit)
              : 0,
          'is_cod': false,
          'is_cod_limit': 0,
          'is_enabled': otherDeliveryEnabled,
          'type': otherDeliveryTypes,
        },
      },
      'private': {'is_enabled': isPrivate},
    };
  }

  /// Default JSON map router method for the "inputs" multipart text field.
  Map<String, dynamic> toJson() {
    if (categoryId == 'others') {
      return toOtherJson();
    }
    if (this is CreateWsStoreRequest || storeKind == 1) {
      return toWsJson();
    }
    return toB2cJson();
  }

  static const Map<String, String> _dayToShortMap = {
    'Sunday': 'Sun',
    'Monday': 'Mon',
    'Tuesday': 'Tue',
    'Wednesday': 'Wed',
    'Thursday': 'Thu',
    'Friday': 'Fri',
    'Saturday': 'Sat',
    'Sun': 'Sun',
    'Mon': 'Mon',
    'Tue': 'Tue',
    'Wed': 'Wed',
    'Thu': 'Thu',
    'Fri': 'Fri',
    'Sat': 'Sat',
  };

  /// Converts day names (e.g. 'Sunday' or 'Sun') to 3-letter codes ('Sun'...'Sat').
  static List<String> formatAvailability(List<String> rawDays) {
    return rawDays.map((d) => _dayToShortMap[d] ?? d).toList();
  }

  /// Converts a time string (e.g. '09:00 AM', '06:00 PM', '18:00') to an ISO 8601 UTC timestamp format ('YYYY-MM-DDTHH:mm:ss.000Z').
  static String formatDeliveryTimeIso(String rawTime) {
    if (rawTime.contains('T') || rawTime.startsWith('20')) {
      return rawTime;
    }

    final now = DateTime.now().toUtc();
    final dateStr =
        "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    int hour = 9;
    int minute = 0;

    final clean = rawTime.trim().toUpperCase();
    final isPm = clean.contains('PM');
    final isAm = clean.contains('AM');

    final timeOnly = clean.replaceAll(RegExp(r'[^\d:]'), '');
    final parts = timeOnly.split(':');
    if (parts.isNotEmpty) {
      hour = int.tryParse(parts[0]) ?? 9;
      if (parts.length > 1) {
        minute = int.tryParse(parts[1]) ?? 0;
      }
    }

    if (isPm && hour < 12) {
      hour += 12;
    } else if (isAm && hour == 12) {
      hour = 0;
    }

    final hStr = hour.toString().padLeft(2, '0');
    final mStr = minute.toString().padLeft(2, '0');

    return '${dateStr}T$hStr:$mStr:00.000Z';
  }

  /// Builds Dio [FormData] for the multipart POST.
  /// "inputs" = JSON string; "image1"…"imageN" = compressed files.
  Future<FormData> toFormData(List<File> images) async {
    final formData = FormData();
    formData.fields.add(MapEntry('inputs', jsonEncode(toJson())));

    for (int i = 0; i < images.length; i++) {
      final file = images[i];
      final filename = file.path.split('/').last;
      final sizeKb = (await file.length() / 1024).toStringAsFixed(1);
      debugPrint('[CreateStoreRequest] Attaching image${i + 1}: $filename ($sizeKb KB)');

      formData.files.add(
        MapEntry(
          'image${i + 1}',
          await MultipartFile.fromFile(
            file.path,
            filename: filename,
            contentType: DioMediaType('image', 'jpeg'),
          ),
        ),
      );
    }
    return formData;
  }
}

/// Dedicated DTO for `POST merchant/wsshop/new` (Wholesale B2B store creation).
class CreateWsStoreRequest extends CreateStoreRequest {
  const CreateWsStoreRequest({
    required super.categoryId,
    required super.displayName,
    super.storeKind = 1,
    super.storeId,
    super.categoryDescription,
    super.contactTime,
    required super.latitude,
    required super.longitude,
    required super.locationId,
    required super.street,
    required super.zipcode,
    super.area,
    super.primaryDialingCode,
    required super.primaryNumber,
    super.primaryVerified,
    super.secondaryDialingCode,
    super.secondaryNumber,
    super.secondaryVerified,
    super.replacementAccepted = false,
    super.replacementDays = 0,
    super.refundAccepted,
    super.refundDays,
    super.availability,
    super.localDeliveryEnabled,
    super.isCod,
    super.codLimitType,
    super.codLimit,
    super.isOnlinePayment,
    super.deliveryRadius,
    super.deliveryFee,
    super.feeLimit,
    super.isLimitApplied,
    super.perKmFee,
    super.isDeliveryFeeSubs,
    super.deliveryFrom,
    super.deliveryTo,
    super.otherDeliveryEnabled,
    super.otherDeliveryFee,
    super.otherFeeLimit,
    super.otherDeliveryTypes,
    super.deliveryTypes,
    super.timeSlots,
    super.isPrivate,
  });

  @override
  Map<String, dynamic> toJson() => toWsJson();
}
