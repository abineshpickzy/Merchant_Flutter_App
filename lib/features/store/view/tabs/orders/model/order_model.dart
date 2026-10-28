import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';
import 'package:bayfay_merchant_flutter/core/network/api_endpoints.dart';

enum OrderStatus {
  newOrder,
  processing,
  ready,
  onTheWay,
  delivered,
  replaceRefund,
  cancelled;

  String get label {
    switch (this) {
      case OrderStatus.newOrder:
        return 'New Order';
      case OrderStatus.processing:
        return 'Packaging';
      case OrderStatus.ready:
        return 'Dispatched';
      case OrderStatus.onTheWay:
        return 'On the way';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.replaceRefund:
        return 'Replace/Refund';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }
}

/// Delivery Assistant Model matching Android AssigneeListRsp.AssigneeData
class DeliveryAssistantModel extends Equatable {
  final String id;
  final String firstName;
  final String lastName;
  final String mobile;
  final int status; // 1 = In Service, 0/other = Idle
  final double distance;
  final int orders;
  final double rating;
  final String signinTime;

  const DeliveryAssistantModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.mobile,
    this.status = 0,
    this.distance = 0.0,
    this.orders = 0,
    this.rating = 0.0,
    this.signinTime = '',
  });

  String get fullName {
    final name = '$firstName $lastName'.trim();
    return name.isEmpty ? 'Delivery Associate' : name;
  }

  bool get isInService => status == 1;

  factory DeliveryAssistantModel.fromJson(Map<String, dynamic> json) {
    String mobileStr = '';
    if (json['mobile'] is Map<String, dynamic>) {
      final m = json['mobile'] as Map<String, dynamic>;
      mobileStr = '${m['number'] ?? ''}';
    } else if (json['mobile'] != null) {
      mobileStr = json['mobile'].toString();
    }

    double parseNum(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    int parseInt(dynamic val) {
      if (val == null) return 0;
      if (val is num) return val.toInt();
      return int.tryParse(val.toString()) ?? 0;
    }

    return DeliveryAssistantModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      mobile: mobileStr,
      status: parseInt(json['status']),
      distance: parseNum(json['distance']),
      orders: parseInt(json['orders']),
      rating: parseNum(json['rating']),
      signinTime: json['signin_time'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [
        id,
        firstName,
        lastName,
        mobile,
        status,
        distance,
        orders,
        rating,
        signinTime,
      ];
}

/// Structured Address representation matching Android Address class
class OrderAddress extends Equatable {
  final String street;
  final String area;
  final String zipcode;
  final String landmark;
  final String postAddress;
  final double? latitude;
  final double? longitude;

  const OrderAddress({
    this.street = '',
    this.area = '',
    this.zipcode = '',
    this.landmark = '',
    this.postAddress = '',
    this.latitude,
    this.longitude,
  });

  factory OrderAddress.fromJson(
    Map<String, dynamic> json, [
    Map<String, dynamic>? rootLocation,
  ]) {
    double? lat;
    double? lng;
    if (json['location'] is Map<String, dynamic>) {
      final loc = json['location'] as Map<String, dynamic>;
      lat = (loc['latitude'] as num?)?.toDouble() ??
          (loc['lat'] as num?)?.toDouble();
      lng = (loc['longitude'] as num?)?.toDouble() ??
          (loc['lng'] as num?)?.toDouble();
      if (lat == null && loc['coordinates'] is List) {
        final coords = loc['coordinates'] as List;
        if (coords.length >= 2) {
          lng = (coords[0] as num?)?.toDouble();
          lat = (coords[1] as num?)?.toDouble();
        }
      }
    }
    if ((lat == null || lng == null) && rootLocation != null) {
      if (rootLocation['coordinates'] is List) {
        final coords = rootLocation['coordinates'] as List;
        if (coords.length >= 2) {
          lng = (coords[0] as num?)?.toDouble();
          lat = (coords[1] as num?)?.toDouble();
        }
      }
    }

    return OrderAddress(
      street: json['street'] as String? ?? '',
      area: json['area'] as String? ?? '',
      zipcode: json['zipcode']?.toString() ?? '',
      landmark: json['landmark'] as String? ?? '',
      postAddress:
          json['post_address'] as String? ?? json['address'] as String? ?? '',
      latitude: lat,
      longitude: lng,
    );
  }

  String get formattedAddress {
    final parts = <String>[];
    if (street.isNotEmpty) parts.add(street);
    if (area.isNotEmpty) parts.add(area);
    if (zipcode.isNotEmpty) parts.add(zipcode);
    if (parts.isEmpty && postAddress.isNotEmpty) return postAddress;
    var result = parts.join(', ');
    if (landmark.isNotEmpty) {
      result += '\nLandmark: $landmark';
    }
    return result.isEmpty ? 'Store Pickup / Local Address' : result;
  }

  @override
  List<Object?> get props => [
        street,
        area,
        zipcode,
        landmark,
        postAddress,
        latitude,
        longitude,
      ];
}

/// Assistant Info matching Android AssistantInfo class
class AssistantInfo extends Equatable {
  final String assistantId;
  final bool isStarted;
  final String assignedAt;

  const AssistantInfo({
    required this.assistantId,
    this.isStarted = false,
    this.assignedAt = '',
  });

  factory AssistantInfo.fromJson(Map<String, dynamic> json) {
    return AssistantInfo(
      assistantId: json['assistant_id'] as String? ?? '',
      isStarted: json['is_started'] as bool? ?? false,
      assignedAt: json['assigned_at'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [assistantId, isStarted, assignedAt];
}

/// Reason item for cancellation matching Android CancelTitlesResponse
class CancelReasonItem extends Equatable {
  final String id;
  final String title;

  const CancelReasonItem({required this.id, required this.title});

  factory CancelReasonItem.fromJson(Map<String, dynamic> json) {
    return CancelReasonItem(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      title: json['title'] as String? ??
          json['name'] as String? ??
          json['display_name'] as String? ??
          '',
    );
  }

  @override
  List<Object?> get props => [id, title];
}

/// Customer Contact Message Template matching Android CustomerMsgTemplateResponse
class CustomerContactTemplate extends Equatable {
  final String id;
  final String message;

  const CustomerContactTemplate({required this.id, required this.message});

  factory CustomerContactTemplate.fromJson(Map<String, dynamic> json) {
    return CustomerContactTemplate(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      message: json['message'] as String? ??
          json['title'] as String? ??
          json['template'] as String? ??
          '',
    );
  }

  @override
  List<Object?> get props => [id, message];
}

/// Manufacture and Expiry date entry matching Android OrderDetailsNewResponse.Date
class MfdExpDate extends Equatable {
  final String mfgDate;
  final String expDate;

  const MfdExpDate({
    this.mfgDate = '',
    this.expDate = '',
  });

  factory MfdExpDate.fromJson(Map<String, dynamic> json) {
    return MfdExpDate(
      mfgDate: json['mfg_date'] as String? ?? '',
      expDate: json['exp_date'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (mfgDate.isNotEmpty) 'mfg_date': mfgDate,
      'exp_date': expDate,
    };
  }

  String get mfgDateFormatted => _fmtShortDate(mfgDate);
  String get expDateFormatted => _fmtShortDate(expDate);

  @override
  List<Object?> get props => [mfgDate, expDate];
}

/// MfdExp wrapper matching Android OrderDetailsNewResponse.MfdExp
/// type: 0 = not set, 1 = specific dates, 2 = Unknown, 3 = Not Applicable
class MfdExpInfo extends Equatable {
  final int type;
  final List<MfdExpDate> dates;

  const MfdExpInfo({
    this.type = 0,
    this.dates = const [],
  });

  factory MfdExpInfo.fromJson(Map<String, dynamic> json) {
    final rawDates = json['dates'];
    final parsedDates = <MfdExpDate>[];
    if (rawDates is List) {
      for (final d in rawDates) {
        if (d is Map<String, dynamic>) {
          parsedDates.add(MfdExpDate.fromJson(d));
        }
      }
    }
    return MfdExpInfo(
      type: (json['type'] as num?)?.toInt() ?? 0,
      dates: parsedDates,
    );
  }

  bool get isVerified => type == 1 || type == 2 || type == 3;

  @override
  List<Object?> get props => [type, dates];
}

/// Escalation correspondence chat item matching Android EscalateMessages.Chat_
class EscalationChatMessage extends Equatable {
  final String id;
  final String at;
  final String by;
  final String message;
  final bool isTemplate;
  final int templateResponse;
  final bool isDeleted;
  final String? imageName;
  final String? imageKeyId;

  const EscalationChatMessage({
    required this.id,
    this.at = '',
    this.by = '',
    this.message = '',
    this.isTemplate = false,
    this.templateResponse = 0,
    this.isDeleted = false,
    this.imageName,
    this.imageKeyId,
  });

  factory EscalationChatMessage.fromJson(Map<String, dynamic> json) {
    String? imgName;
    String? imgKey;
    if (json['image'] is Map<String, dynamic>) {
      final img = json['image'] as Map<String, dynamic>;
      imgName = img['name'] as String?;
      imgKey = img['keyid'] as String?;
    }
    return EscalationChatMessage(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      at: json['at'] as String? ?? '',
      by: json['by'] as String? ?? '',
      message: json['message'] as String? ?? '',
      isTemplate: json['is_template'] as bool? ?? false,
      templateResponse: (json['template_response'] as num?)?.toInt() ?? 0,
      isDeleted: json['is_deleted'] as bool? ?? false,
      imageName: imgName,
      imageKeyId: imgKey,
    );
  }

  String get atFormatted => _fmtDateTime(at);

  @override
  List<Object?> get props => [
        id,
        at,
        by,
        message,
        isTemplate,
        templateResponse,
        isDeleted,
        imageName,
        imageKeyId,
      ];
}

/// Comprehensive Order Model matching Android NewOrder / Package / Dispatch / OnTheWay / Delivery / Replacement / Cancel responses
class OrderModel extends Equatable {
  final String id;
  final String orderId;
  final double amount;
  final String customerName;
  final String customerMobile;
  final String? customerImage;
  final String customerAddress;
  final OrderAddress? address;
  final String deliveryType;
  final String paymentType;
  final String orderedAt;
  final String? deliveredAt;
  final String? cancelledAt;
  final String? rejectedAt;
  final String? deniedAt;
  final String? verifiedAt;
  final String orderStatusText;
  final OrderStatus status;
  final bool isWholesale;
  final bool isPrivate;
  final String categoryType;
  final bool isReplacement;
  final bool isUndelivery;
  final bool hasEscalation;
  final bool isEscalatedOrder;
  final bool refundRequestInitiate;
  final bool contactLessDelivery;
  final double distance;
  final int tipAmount;
  final int rating;
  final String preferredTime;
  final String expectedTime;
  final AssistantInfo? assistantInfo;
  final String? notes;
  final String? notesFile;
  final bool hasNotes;

  const OrderModel({
    required this.id,
    required this.orderId,
    required this.amount,
    required this.customerName,
    required this.customerMobile,
    this.customerImage,
    required this.customerAddress,
    this.address,
    required this.deliveryType,
    required this.paymentType,
    required this.orderedAt,
    this.deliveredAt,
    this.cancelledAt,
    this.rejectedAt,
    this.deniedAt,
    this.verifiedAt,
    this.orderStatusText = '',
    this.status = OrderStatus.newOrder,
    this.isWholesale = false,
    this.isPrivate = false,
    this.categoryType = '',
    this.isReplacement = false,
    this.isUndelivery = false,
    this.hasEscalation = false,
    this.isEscalatedOrder = false,
    this.refundRequestInitiate = false,
    this.contactLessDelivery = false,
    this.distance = 0.0,
    this.tipAmount = 0,
    this.rating = 0,
    this.preferredTime = 'Immediate',
    this.expectedTime = '',
    this.assistantInfo,
    this.notes,
    this.notesFile,
    this.hasNotes = false,
  });

  /// Matches Android `if (docs.getNotes() != null)` across OrderDetailFragment,
  /// PackageDetailsFragment, DispatchDetailsFragment, OntheWayDetailsFragment, and PackageOrderDetailsFragment.
  bool get hasCustomerNotes =>
      hasNotes ||
      (notes != null && notes!.trim().isNotEmpty) ||
      (notesFile != null && notesFile!.trim().isNotEmpty);

  bool get isSelfPickup =>
      deliveryType.toLowerCase().contains('self') ||
      deliveryType.toLowerCase().contains('pickup');

  bool get hasAssignedAssistant =>
      assistantInfo != null && assistantInfo!.assistantId.isNotEmpty;

  String get shopTypeDisplay {
    if (isPrivate) return '(Private)';
    if (categoryType.isNotEmpty) return '($categoryType)';
    return '';
  }

  factory OrderModel.fromJson(Map<String, dynamic> json, [OrderStatus? status]) {
    // Customer parsing
    String name = 'Customer';
    String mobile = '';
    String? customerImg;
    if (json['customer'] is Map<String, dynamic>) {
      final cust = json['customer'] as Map<String, dynamic>;
      name = cust['name'] as String? ?? 'Customer';
      customerImg = cust['image'] as String?;
      if (cust['mobile'] is Map<String, dynamic>) {
        final m = cust['mobile'] as Map<String, dynamic>;
        mobile = '${m['number'] ?? ''}';
      } else if (cust['mobile'] != null) {
        mobile = '${cust['mobile']}';
      }
    }

    // Address parsing
    OrderAddress? parsedAddress;
    String addressStr = 'Store Pickup / Local Delivery';
    final rootLocation = json['location'] is Map<String, dynamic>
        ? json['location'] as Map<String, dynamic>
        : null;
    if (json['address'] is Map<String, dynamic>) {
      parsedAddress = OrderAddress.fromJson(
        json['address'] as Map<String, dynamic>,
        rootLocation,
      );
      addressStr = parsedAddress.formattedAddress;
    }

    double parseAmount(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    int parseInt(dynamic val) {
      if (val == null) return 0;
      if (val is num) return val.toInt();
      return int.tryParse(val.toString()) ?? 0;
    }

    // Preferred delivery time parsing (preferences.is_anytime vs custom_time)
    String prefTime = 'Immediate';
    String expTime = '';
    if (json['preferences'] is Map<String, dynamic>) {
      final pref = json['preferences'] as Map<String, dynamic>;
      final isAnytime = pref['is_anytime'] as bool? ?? false;
      if (isAnytime) {
        prefTime = 'Immediate';
      } else if (pref['custom_time'] is Map<String, dynamic>) {
        final ct = pref['custom_time'] as Map<String, dynamic>;
        final from = _fmtTime(ct['from']?.toString() ?? '');
        final to = _fmtTime(ct['to']?.toString() ?? '');
        prefTime = from.isNotEmpty && to.isNotEmpty
            ? '$from - $to'
            : (from.isNotEmpty ? from : 'Immediate');
      }
      if (pref['expected_time'] is Map<String, dynamic>) {
        final et = pref['expected_time'] as Map<String, dynamic>;
        expTime = et['at']?.toString() ?? '';
      }
    }

    // Assistant Info
    AssistantInfo? asst;
    if (json['assistant_info'] is Map<String, dynamic>) {
      asst = AssistantInfo.fromJson(
          json['assistant_info'] as Map<String, dynamic>);
    }

    // Customer notes matching Android PackageNewResponse.Notes (@SerializedName("text") / @SerializedName("image"))
    String? noteText;
    String? noteFile;
    bool hasNoteObj = false;
    if (json['notes'] is Map<String, dynamic>) {
      final notesMap = json['notes'] as Map<String, dynamic>;
      noteText = (notesMap['text'] as String?) ?? (notesMap['notes'] as String?);
      noteFile = (notesMap['image'] as String?) ?? (notesMap['file'] as String?);
      hasNoteObj = (noteText != null && noteText.trim().isNotEmpty) ||
          (noteFile != null && noteFile.trim().isNotEmpty);
    } else if (json['notes'] is String) {
      noteText = json['notes'] as String;
      hasNoteObj = noteText.trim().isNotEmpty;
    }

    return OrderModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      orderId: json['order_id'] as String? ??
          '#${json['_id']?.toString().substring(0, 6) ?? 'ORD'}',
      amount: parseAmount(json['amount'] ?? json['total_amount']),
      customerName: name,
      customerMobile: mobile,
      customerImage: customerImg,
      customerAddress: addressStr,
      address: parsedAddress,
      deliveryType: json['delivery_type'] as String? ?? 'Home Delivery',
      paymentType: json['payment_type'] as String? ?? 'COD',
      orderedAt: json['ordered'] as String? ?? json['date'] as String? ?? '',
      deliveredAt: json['delivered'] as String?,
      cancelledAt: json['cancelled'] as String?,
      rejectedAt: json['rejected'] as String?,
      deniedAt: json['denied'] as String?,
      verifiedAt: json['verified'] as String?,
      orderStatusText: json['status']?.toString() ?? '',
      status: status ?? OrderStatus.newOrder,
      isWholesale: json['is_wholesale'] as bool? ?? false,
      isPrivate: json['is_private'] as bool? ?? false,
      categoryType: json['category_type'] as String? ?? '',
      isReplacement: json['is_replacement'] as bool? ?? false,
      isUndelivery: json['is_undelivery'] as bool? ?? false,
      hasEscalation: json['has_escalation'] as bool? ?? false,
      isEscalatedOrder: json['is_escalated_order'] as bool? ?? false,
      refundRequestInitiate: json['refund_request_initiate'] as bool? ?? false,
      contactLessDelivery:
          json['is_contact_less_delivery'] as bool? ?? false,
      distance: parseAmount(json['distance']),
      tipAmount: parseInt(json['tip_amount']),
      rating: parseInt(json['rating']),
      preferredTime: prefTime,
      expectedTime: expTime,
      assistantInfo: asst,
      notes: noteText,
      notesFile: noteFile,
      hasNotes: hasNoteObj,
    );
  }

  OrderModel copyWith({
    String? id,
    String? orderId,
    double? amount,
    String? customerName,
    String? customerMobile,
    String? customerImage,
    String? customerAddress,
    OrderAddress? address,
    String? deliveryType,
    String? paymentType,
    String? orderedAt,
    String? deliveredAt,
    String? cancelledAt,
    String? rejectedAt,
    String? deniedAt,
    String? verifiedAt,
    String? orderStatusText,
    OrderStatus? status,
    bool? isWholesale,
    bool? isPrivate,
    String? categoryType,
    bool? isReplacement,
    bool? isUndelivery,
    bool? hasEscalation,
    bool? isEscalatedOrder,
    bool? refundRequestInitiate,
    bool? contactLessDelivery,
    double? distance,
    int? tipAmount,
    int? rating,
    String? preferredTime,
    String? expectedTime,
    AssistantInfo? assistantInfo,
    String? notes,
    String? notesFile,
    bool? hasNotes,
  }) {
    return OrderModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      amount: amount ?? this.amount,
      customerName: customerName ?? this.customerName,
      customerMobile: customerMobile ?? this.customerMobile,
      customerImage: customerImage ?? this.customerImage,
      customerAddress: customerAddress ?? this.customerAddress,
      address: address ?? this.address,
      deliveryType: deliveryType ?? this.deliveryType,
      paymentType: paymentType ?? this.paymentType,
      orderedAt: orderedAt ?? this.orderedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      deniedAt: deniedAt ?? this.deniedAt,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      orderStatusText: orderStatusText ?? this.orderStatusText,
      status: status ?? this.status,
      isWholesale: isWholesale ?? this.isWholesale,
      isPrivate: isPrivate ?? this.isPrivate,
      categoryType: categoryType ?? this.categoryType,
      isReplacement: isReplacement ?? this.isReplacement,
      isUndelivery: isUndelivery ?? this.isUndelivery,
      hasEscalation: hasEscalation ?? this.hasEscalation,
      isEscalatedOrder: isEscalatedOrder ?? this.isEscalatedOrder,
      refundRequestInitiate:
          refundRequestInitiate ?? this.refundRequestInitiate,
      contactLessDelivery: contactLessDelivery ?? this.contactLessDelivery,
      distance: distance ?? this.distance,
      tipAmount: tipAmount ?? this.tipAmount,
      rating: rating ?? this.rating,
      preferredTime: preferredTime ?? this.preferredTime,
      expectedTime: expectedTime ?? this.expectedTime,
      assistantInfo: assistantInfo ?? this.assistantInfo,
      notes: notes ?? this.notes,
      notesFile: notesFile ?? this.notesFile,
      hasNotes: hasNotes ?? this.hasNotes,
    );
  }

  String get orderedAtFormatted => _fmtDateTime(orderedAt);
  String get deliveredAtFormatted => _fmtDateTime(deliveredAt ?? orderedAt);
  String get verifiedAtFormatted => _fmtDateTime(verifiedAt ?? orderedAt);
  String get expectedTimeFormatted => _fmtDateTime(expectedTime);

  /// Cancelled timestamp resolution matching Android CancelAdapter (cancelled -> rejected -> denied -> ordered)
  String get cancelledTimestampFormatted {
    if (cancelledAt != null && cancelledAt!.isNotEmpty) {
      return _fmtDateTime(cancelledAt!);
    }
    if (rejectedAt != null && rejectedAt!.isNotEmpty) {
      return _fmtDateTime(rejectedAt!);
    }
    if (deniedAt != null && deniedAt!.isNotEmpty) {
      return _fmtDateTime(deniedAt!);
    }
    return orderedAtFormatted;
  }

  /// Date header label matching Android NewOrderHeaderAdapter ("Today", "Yesterday", "X Days Ago", or "dd MMM yyyy")
  String get dateGroupHeader {
    final raw = (hasEscalation && verifiedAt != null && verifiedAt!.isNotEmpty)
        ? verifiedAt!
        : orderedAt;
    final dt = DateTime.tryParse(raw)?.toLocal();
    if (dt == null) return 'Today';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final orderDay = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(orderDay).inDays;
    if (diff <= 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff <= 7) return '$diff Days Ago';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}';
  }

  /// Full customer avatar image URL with query params for size/format.
  /// Returns null if customerImage is null/empty.
  String? get customerImageUrl {
    if (customerImage == null || customerImage!.trim().isEmpty) return null;
    return ApiEndpoints.customerImageUrl(
      customerImage!,
      isWholesale: isWholesale,
    );
  }

  // Keep raw filename for backwards compatibility
  String? get customerImageFilename => customerImage;

  @override
  List<Object?> get props => [
        id,
        orderId,
        amount,
        customerName,
        customerMobile,
        customerImage,
        customerAddress,
        deliveryType,
        paymentType,
        orderedAt,
        deliveredAt,
        cancelledAt,
        rejectedAt,
        deniedAt,
        verifiedAt,
        orderStatusText,
        status,
        isWholesale,
        isPrivate,
        categoryType,
        isReplacement,
        isUndelivery,
        hasEscalation,
        isEscalatedOrder,
        refundRequestInitiate,
        contactLessDelivery,
        distance,
        tipAmount,
        rating,
        preferredTime,
        expectedTime,
        assistantInfo,
        notes,
        notesFile,
        hasNotes,
      ];
}

/// Line-item product matching Android OrderDetailsNewResponse.Data
class OrderProductItem extends Equatable {
  final String id;
  final String productName;
  final int quantity;
  final int escalatedQty;
  final double netPrice;
  final double offer;
  final double productOfferAmount;
  final String unit;
  final String manufacturer;
  final String? image;
  final String? imageKeyId;
  final bool upc;
  final int verifyStatus;
  final int escalationStatus;
  final int resolute;
  final MfdExpInfo? mfdExp;
  final bool isChecked;

  const OrderProductItem({
    required this.id,
    required this.productName,
    required this.quantity,
    this.escalatedQty = 0,
    required this.netPrice,
    this.offer = 0.0,
    this.productOfferAmount = 0.0,
    this.unit = 'unit',
    this.manufacturer = '',
    this.image,
    this.imageKeyId,
    this.upc = false,
    this.verifyStatus = 0,
    this.escalationStatus = 0,
    this.resolute = 0,
    this.mfdExp,
    this.isChecked = false,
  });

  factory OrderProductItem.fromJson(Map<String, dynamic> json) {
    String? imgUrl;
    String? keyId;
    if (json['image'] is Map<String, dynamic>) {
      final imgMap = json['image'] as Map<String, dynamic>;
      imgUrl = imgMap['image'] as String? ??
          imgMap['thumbnail'] as String? ??
          imgMap['name'] as String?;
      keyId = imgMap['keyid'] as String?;
    } else if (json['image'] is String) {
      imgUrl = json['image'] as String;
    }

    double parsePrice(dynamic p) {
      if (p == null) return 0.0;
      if (p is num) return p.toDouble();
      return double.tryParse(p.toString()) ?? 0.0;
    }

    int parseInt(dynamic val) {
      if (val == null) return 0;
      if (val is num) return val.toInt();
      return int.tryParse(val.toString()) ?? 0;
    }

    MfdExpInfo? parsedMfdExp;
    if (json['mfd_exp'] is Map<String, dynamic>) {
      parsedMfdExp =
          MfdExpInfo.fromJson(json['mfd_exp'] as Map<String, dynamic>);
    }

    final checkedFlag = json['checked'] as bool? ??
        (parsedMfdExp != null && parsedMfdExp.isVerified);

    return OrderProductItem(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      productName: json['product_name'] as String? ?? 'Product',
      quantity: parseInt(json['qty'] ?? 1),
      escalatedQty: parseInt(json['escalated_qty']),
      netPrice: parsePrice(json['net_price'] ?? json['price']),
      offer: parsePrice(json['offer']),
      productOfferAmount: parsePrice(json['product_offer_amount']),
      unit: json['unit'] as String? ?? 'unit',
      manufacturer: json['manufacturer'] as String? ?? '',
      image: imgUrl,
      imageKeyId: keyId,
      upc: json['upc'] as bool? ?? false,
      verifyStatus: parseInt(json['verify_status']),
      escalationStatus: parseInt(json['escalation_status']),
      resolute: parseInt(json['resolute']),
      mfdExp: parsedMfdExp,
      isChecked: checkedFlag,
    );
  }

  String get name => productName;
  double get totalPrice => (netPrice - productOfferAmount) * quantity;
  double get escalatedTotalPrice =>
      (netPrice - productOfferAmount) * (escalatedQty > 0 ? escalatedQty : quantity);
  String? get imageUrl {
    if (image == null || image!.trim().isEmpty) return null;
    return ApiEndpoints.productImageUrl(image!);
  }

  OrderProductItem copyWith({
    bool? isChecked,
    MfdExpInfo? mfdExp,
    int? verifyStatus,
    int? escalationStatus,
    int? resolute,
  }) {
    return OrderProductItem(
      id: id,
      productName: productName,
      quantity: quantity,
      escalatedQty: escalatedQty,
      netPrice: netPrice,
      offer: offer,
      productOfferAmount: productOfferAmount,
      unit: unit,
      manufacturer: manufacturer,
      image: image,
      imageKeyId: imageKeyId,
      upc: upc,
      verifyStatus: verifyStatus ?? this.verifyStatus,
      escalationStatus: escalationStatus ?? this.escalationStatus,
      resolute: resolute ?? this.resolute,
      mfdExp: mfdExp ?? this.mfdExp,
      isChecked: isChecked ?? this.isChecked,
    );
  }

  @override
  List<Object?> get props => [
        id,
        productName,
        quantity,
        escalatedQty,
        netPrice,
        offer,
        productOfferAmount,
        unit,
        manufacturer,
        image,
        imageKeyId,
        upc,
        verifyStatus,
        escalationStatus,
        resolute,
        mfdExp,
        isChecked,
      ];
}

/// Order tab count summary model
class OrderCountsModel extends Equatable {
  final int newOrders;
  final int acceptedOrders;
  final int readyToShipOrders;
  final int shippingOrders;
  final int deliveredOrders;
  final int cancelledOrders;
  final int escalatedOrders;

  const OrderCountsModel({
    this.newOrders = 0,
    this.acceptedOrders = 0,
    this.readyToShipOrders = 0,
    this.shippingOrders = 0,
    this.deliveredOrders = 0,
    this.cancelledOrders = 0,
    this.escalatedOrders = 0,
  });

  factory OrderCountsModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    return OrderCountsModel(
      newOrders: (data['newOrders'] as num?)?.toInt() ?? 0,
      acceptedOrders: (data['acceptedOrders'] as num?)?.toInt() ?? 0,
      readyToShipOrders:
          ((data['readyToShipOrders'] ?? data['dispatchedOrders']) as num?)
                  ?.toInt() ??
              0,
      shippingOrders: (data['shippingOrders'] as num?)?.toInt() ?? 0,
      deliveredOrders: (data['deliveredOrders'] as num?)?.toInt() ?? 0,
      cancelledOrders: (data['cancelledOrders'] as num?)?.toInt() ?? 0,
      escalatedOrders: (data['escalatedOrders'] as num?)?.toInt() ?? 0,
    );
  }

  int get dispatchedOrders => readyToShipOrders;
  int get totalPending =>
      newOrders + acceptedOrders + readyToShipOrders + shippingOrders;

  int getCountForStatus(OrderStatus status) {
    switch (status) {
      case OrderStatus.newOrder:
        return newOrders;
      case OrderStatus.processing:
        return acceptedOrders;
      case OrderStatus.ready:
        return readyToShipOrders;
      case OrderStatus.onTheWay:
        return shippingOrders;
      case OrderStatus.delivered:
        return deliveredOrders;
      case OrderStatus.cancelled:
        return cancelledOrders;
      case OrderStatus.replaceRefund:
        return escalatedOrders;
    }
  }

  @override
  List<Object?> get props => [
        newOrders,
        acceptedOrders,
        readyToShipOrders,
        shippingOrders,
        deliveredOrders,
        cancelledOrders,
        escalatedOrders,
      ];
}

String _fmtDateTime(String iso) {
  if (iso.isEmpty) return '';
  final d = DateTime.tryParse(iso)?.toLocal();
  if (d == null) return iso;
  String two(int n) => n.toString().padLeft(2, '0');
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final ap = d.hour >= 12 ? 'pm' : 'am';
  return '${two(d.day)}/${two(d.month)}/${d.year} ${two(h)}:${two(d.minute)} $ap';
}

String _fmtTime(String iso) {
  if (iso.isEmpty) return '';
  final d = DateTime.tryParse(iso)?.toLocal();
  if (d == null) return iso;
  String two(int n) => n.toString().padLeft(2, '0');
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final ap = d.hour >= 12 ? 'pm' : 'am';
  return '${two(h)}:${two(d.minute)} $ap';
}

String _fmtShortDate(String iso) {
  if (iso.isEmpty) return '';
  final d = DateTime.tryParse(iso)?.toLocal();
  if (d == null) return iso;
  return DateFormat('dd MMM yyyy').format(d);
}

/// Column definition for Product Info table matching Android ProductDetailResponse.Column
class OrderProductColumn extends Equatable {
  final String keyName;
  final String displayName;

  const OrderProductColumn({
    required this.keyName,
    required this.displayName,
  });

  factory OrderProductColumn.fromJson(Map<String, dynamic> json) {
    return OrderProductColumn(
      keyName: json['key_name'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [keyName, displayName];
}

/// Full product details for ProductFragment + ProductInfo matching Android ProductDetailResponse
class OrderProductDetailData extends Equatable {
  final String id;
  final String productName;
  final List<String> images;
  final List<OrderProductColumn> columns;
  final Map<String, String> attributes;

  const OrderProductDetailData({
    this.id = '',
    this.productName = '',
    this.images = const [],
    this.columns = const [],
    this.attributes = const {},
  });

  factory OrderProductDetailData.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    final cols = <OrderProductColumn>[];
    if (data['column'] is List) {
      for (final c in data['column'] as List) {
        if (c is Map<String, dynamic>) {
          cols.add(OrderProductColumn.fromJson(c));
        }
      }
    }

    String prodId = '';
    String prodName = '';
    final imgList = <String>[];
    final attrs = <String, String>{};

    if (data['product'] is Map<String, dynamic>) {
      final prod = data['product'] as Map<String, dynamic>;
      prodId = prod['_id'] as String? ?? prod['id'] as String? ?? '';
      prodName = prod['product_name'] as String? ?? '';

      if (prod['images'] is List) {
        for (final img in prod['images'] as List) {
          if (img is Map<String, dynamic>) {
            final name = img['name'] as String? ?? img['image'] as String?;
            if (name != null && name.isNotEmpty) {
              imgList.add(name);
            }
          } else if (img is String && img.isNotEmpty) {
            imgList.add(img);
          }
        }
      }

      for (final col in cols) {
        final rawVal = prod[col.keyName];
        if (rawVal != null) {
          attrs[col.keyName] = rawVal.toString();
        }
      }
    }

    return OrderProductDetailData(
      id: prodId,
      productName: prodName,
      images: imgList,
      columns: cols,
      attributes: attrs,
    );
  }

  @override
  List<Object?> get props => [id, productName, images, columns, attributes];
}

/// Product average selling price and customer rating matching Android AvgResponse
class OrderProductAvgData extends Equatable {
  final double avgSellingPrice;
  final double averageCustomerRating;

  const OrderProductAvgData({
    this.avgSellingPrice = 0.0,
    this.averageCustomerRating = 0.0,
  });

  factory OrderProductAvgData.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    double parseNum(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    return OrderProductAvgData(
      avgSellingPrice: parseNum(data['avg_selling_price']),
      averageCustomerRating: parseNum(data['average_customer_rating']),
    );
  }

  @override
  List<Object?> get props => [avgSellingPrice, averageCustomerRating];
}

/// Individual customer review matching Android ReviewResponse.Reviews
class OrderProductReviewItem extends Equatable {
  final String id;
  final String customerName;
  final String? customerImage;
  final double rating;
  final String review;
  final String title;
  final String createdAt;

  const OrderProductReviewItem({
    this.id = '',
    this.customerName = 'Customer',
    this.customerImage,
    this.rating = 0.0,
    this.review = '',
    this.title = '',
    this.createdAt = '',
  });

  factory OrderProductReviewItem.fromJson(Map<String, dynamic> json) {
    String name = json['customer_name'] as String? ??
        json['name'] as String? ??
        json['user_name'] as String? ??
        'Customer';
    String? img = json['image'] as String? ?? json['customer_image'] as String?;
    if (json['customer'] is Map<String, dynamic>) {
      final c = json['customer'] as Map<String, dynamic>;
      name = c['name'] as String? ??
          '${c['first_name'] ?? ''} ${c['last_name'] ?? ''}'.trim();
      if (name.isEmpty) name = 'Customer';
      img = c['image'] as String?;
    }

    double parseNum(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    return OrderProductReviewItem(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      customerName: name,
      customerImage: img,
      rating: parseNum(json['rating'] ?? json['star']),
      review: json['review'] as String? ??
          json['comment'] as String? ??
          json['message'] as String? ??
          json['description'] as String? ??
          '',
      title: json['title'] as String? ?? '',
      createdAt: json['created_at'] as String? ??
          json['date'] as String? ??
          json['at'] as String? ??
          '',
    );
  }

  String get createdAtFormatted => _fmtShortDate(createdAt);

  @override
  List<Object?> get props => [
        id,
        customerName,
        customerImage,
        rating,
        review,
        title,
        createdAt,
      ];
}

/// Star rating breakdown matching Android ReviewFragment
class OrderProductReviewData extends Equatable {
  final List<OrderProductReviewItem> reviews;
  final Map<int, int> starCounts; // 1..5 -> count

  const OrderProductReviewData({
    this.reviews = const [],
    this.starCounts = const {},
  });

  int get totalCount {
    var sum = 0;
    for (final c in starCounts.values) {
      sum += c;
    }
    return sum > 0 ? sum : reviews.length;
  }

  double get averageRating {
    int totalStars = 0;
    int totalUsers = 0;
    starCounts.forEach((star, count) {
      totalStars += star * count;
      totalUsers += count;
    });
    if (totalUsers > 0) {
      return totalStars / totalUsers;
    }
    if (reviews.isNotEmpty) {
      final sum = reviews.fold<double>(0.0, (acc, r) => acc + r.rating);
      return sum / reviews.length;
    }
    return 0.0;
  }

  factory OrderProductReviewData.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    final parsedReviews = <OrderProductReviewItem>[];
    if (data['reviews'] is List) {
      for (final r in data['reviews'] as List) {
        if (r is Map<String, dynamic>) {
          parsedReviews.add(OrderProductReviewItem.fromJson(r));
        }
      }
    }

    final counts = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    if (data['count'] is List) {
      for (final c in data['count'] as List) {
        if (c is Map<String, dynamic>) {
          final star = (c['_id'] as num?)?.toInt() ?? 0;
          final cnt = (c['count'] as num?)?.toInt() ?? 0;
          if (star >= 1 && star <= 5) {
            counts[star] = cnt;
          }
        }
      }
    }

    return OrderProductReviewData(
      reviews: parsedReviews,
      starCounts: counts,
    );
  }

  @override
  List<Object?> get props => [reviews, starCounts];
}
