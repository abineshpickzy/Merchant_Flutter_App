/// Model classes for Store Details Setting (1:1 with Android SettingLocation & SettingUpdateRequest)
enum SecondaryNumberType { mobile, landline }

class SettingLocationData {
  final String id;
  final String displayName;
  final String? street;
  final int? zipcode;
  final String? country;
  final String? state;
  final String? city;
  final double? latitude;
  final double? longitude;
  final int? primaryDialingCode;
  final int? primaryMobile;
  final bool primaryVerified;
  final int? secondaryDialingCode;
  final int? secondaryMobile;
  final bool secondaryVerified;
  final int? landlineStdCode;
  final int? landlineNumber;

  const SettingLocationData({
    required this.id,
    required this.displayName,
    this.street,
    this.zipcode,
    this.country,
    this.state,
    this.city,
    this.latitude,
    this.longitude,
    this.primaryDialingCode,
    this.primaryMobile,
    this.primaryVerified = false,
    this.secondaryDialingCode,
    this.secondaryMobile,
    this.secondaryVerified = false,
    this.landlineStdCode,
    this.landlineNumber,
  });

  factory SettingLocationData.fromJson(Map<String, dynamic> json) {
    final addr = json['address'] as Map<String, dynamic>? ?? {};
    final loc = addr['location'] as Map<String, dynamic>? ?? {};
    final geoLoc = json['location'] as Map<String, dynamic>? ?? {};
    final coords = geoLoc['coordinates'] as List<dynamic>?;

    double? lng;
    double? lat;
    if (coords != null && coords.length >= 2) {
      lng = (coords[0] as num?)?.toDouble();
      lat = (coords[1] as num?)?.toDouble();
    }

    final mobile = json['mobile'] as Map<String, dynamic>? ?? {};
    final prim = mobile['primary'] as Map<String, dynamic>? ?? {};
    final sec = mobile['secondary'] as Map<String, dynamic>?;
    final landline = json['landline'] as Map<String, dynamic>?;

    return SettingLocationData(
      id: json['_id']?.toString() ?? '',
      displayName: json['display_name']?.toString() ?? '',
      street: addr['street']?.toString(),
      zipcode: (addr['zipcode'] as num?)?.toInt(),
      country: loc['country']?.toString(),
      state: loc['state']?.toString(),
      city: loc['name']?.toString(),
      latitude: lat,
      longitude: lng,
      primaryDialingCode: (prim['dialing_code'] as num?)?.toInt() ?? 91,
      primaryMobile: (prim['number'] as num?)?.toInt(),
      primaryVerified: prim['is_verified'] == true,
      secondaryDialingCode: (sec?['dialing_code'] as num?)?.toInt(),
      secondaryMobile: (sec?['number'] as num?)?.toInt(),
      secondaryVerified: sec?['is_verified'] == true,
      landlineStdCode: (landline?['dialing_code'] as num?)?.toInt(),
      landlineNumber: (landline?['number'] as num?)?.toInt(),
    );
  }
}

class LocationItem {
  final String id;
  final String name;
  final String state;

  const LocationItem({
    required this.id,
    required this.name,
    required this.state,
  });

  factory LocationItem.fromJson(Map<String, dynamic> json) {
    return LocationItem(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
    );
  }
}

class StoreDetailsSettingState {
  final bool isLoading;
  final bool isSaving;
  final bool isSendingOtp;
  final bool isVerifyingOtp;
  final String? errorMessage;
  final String? successMessage;
  final String displayName;
  final String primaryMobile;
  final bool isPrimaryVerified;
  final String initialPrimaryMobile;
  final SecondaryNumberType secondaryType;
  final String secondaryDialingCode;
  final String secondaryMobile;
  final bool isSecondaryVerified;
  final String initialSecondaryMobile;
  final String secondaryLandlineStd;
  final String secondaryLandlineNum;
  final String streetAddress;
  final double? latitude;
  final double? longitude;
  final String? country;
  final String? state;
  final String? city;
  final String pincode;
  final List<String> countries;
  final List<String> states;
  final List<String> cities;
  final Map<String, List<String>> stateCityMap;
  final bool hasEditPrivilege;

  const StoreDetailsSettingState({
    this.isLoading = false,
    this.isSaving = false,
    this.isSendingOtp = false,
    this.isVerifyingOtp = false,
    this.errorMessage,
    this.successMessage,
    this.displayName = '',
    this.primaryMobile = '',
    this.isPrimaryVerified = false,
    this.initialPrimaryMobile = '',
    this.secondaryType = SecondaryNumberType.mobile,
    this.secondaryDialingCode = '91',
    this.secondaryMobile = '',
    this.isSecondaryVerified = false,
    this.initialSecondaryMobile = '',
    this.secondaryLandlineStd = '',
    this.secondaryLandlineNum = '',
    this.streetAddress = '',
    this.latitude,
    this.longitude,
    this.country,
    this.state,
    this.city,
    this.pincode = '',
    this.countries = const [],
    this.states = const [],
    this.cities = const [],
    this.stateCityMap = const {},
    this.hasEditPrivilege = true,
  });

  StoreDetailsSettingState copyWith({
    bool? isLoading,
    bool? isSaving,
    bool? isSendingOtp,
    bool? isVerifyingOtp,
    String? errorMessage,
    String? successMessage,
    String? displayName,
    String? primaryMobile,
    bool? isPrimaryVerified,
    String? initialPrimaryMobile,
    SecondaryNumberType? secondaryType,
    String? secondaryDialingCode,
    String? secondaryMobile,
    bool? isSecondaryVerified,
    String? initialSecondaryMobile,
    String? secondaryLandlineStd,
    String? secondaryLandlineNum,
    String? streetAddress,
    double? latitude,
    double? longitude,
    String? country,
    String? state,
    String? city,
    String? pincode,
    List<String>? countries,
    List<String>? states,
    List<String>? cities,
    Map<String, List<String>>? stateCityMap,
    bool? hasEditPrivilege,
  }) {
    return StoreDetailsSettingState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      isSendingOtp: isSendingOtp ?? this.isSendingOtp,
      isVerifyingOtp: isVerifyingOtp ?? this.isVerifyingOtp,
      errorMessage: errorMessage,
      successMessage: successMessage,
      displayName: displayName ?? this.displayName,
      primaryMobile: primaryMobile ?? this.primaryMobile,
      isPrimaryVerified: isPrimaryVerified ?? this.isPrimaryVerified,
      initialPrimaryMobile: initialPrimaryMobile ?? this.initialPrimaryMobile,
      secondaryType: secondaryType ?? this.secondaryType,
      secondaryDialingCode: secondaryDialingCode ?? this.secondaryDialingCode,
      secondaryMobile: secondaryMobile ?? this.secondaryMobile,
      isSecondaryVerified: isSecondaryVerified ?? this.isSecondaryVerified,
      initialSecondaryMobile:
          initialSecondaryMobile ?? this.initialSecondaryMobile,
      secondaryLandlineStd: secondaryLandlineStd ?? this.secondaryLandlineStd,
      secondaryLandlineNum: secondaryLandlineNum ?? this.secondaryLandlineNum,
      streetAddress: streetAddress ?? this.streetAddress,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      country: country ?? this.country,
      state: state ?? this.state,
      city: city ?? this.city,
      pincode: pincode ?? this.pincode,
      countries: countries ?? this.countries,
      states: states ?? this.states,
      cities: cities ?? this.cities,
      stateCityMap: stateCityMap ?? this.stateCityMap,
      hasEditPrivilege: hasEditPrivilege ?? this.hasEditPrivilege,
    );
  }
}
