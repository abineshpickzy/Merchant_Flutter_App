import 'package:equatable/equatable.dart';

/// Model representing the response from API-078: POST merchant/business/value
/// (matching legacy Android BusinessValueInfo.java)
class BusinessValueModel extends Equatable {
  final int customersCount;
  final int businessValue;

  const BusinessValueModel({
    this.customersCount = 0,
    this.businessValue = 0,
  });

  factory BusinessValueModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    return BusinessValueModel(
      customersCount: (data['customers_count'] as num?)?.toInt() ??
          (data['customersCount'] as num?)?.toInt() ??
          0,
      businessValue: (data['business_value'] as num?)?.toInt() ??
          (data['businessValue'] as num?)?.toInt() ??
          0,
    );
  }

  Map<String, dynamic> toJson() => {
        'customers_count': customersCount,
        'business_value': businessValue,
      };

  @override
  List<Object?> get props => [customersCount, businessValue];
}

/// Model representing the response from API-077: POST merchant/partner/info
/// (matching legacy Android AgencyActivateDetailRsp.java)
class PartnerInfoModel extends Equatable {
  final int annualTurnover;
  final int last30DaysTurnover;
  final List<String> agencyInfo;
  final String? note;
  final String? support;

  const PartnerInfoModel({
    this.annualTurnover = 0,
    this.last30DaysTurnover = 0,
    this.agencyInfo = const [],
    this.note,
    this.support,
  });

  factory PartnerInfoModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    final turnover = data['turnover'] is Map<String, dynamic>
        ? data['turnover'] as Map<String, dynamic>
        : null;

    final agency = data['agencyInfo'] is Map<String, dynamic>
        ? data['agencyInfo'] as Map<String, dynamic>
        : null;

    final rawInfo = agency?['info'];
    final List<String> parsedAgencyInfo = (rawInfo is List)
        ? rawInfo.map((e) => e.toString()).toList()
        : const [];

    return PartnerInfoModel(
      annualTurnover: (turnover?['annual'] as num?)?.toInt() ?? 0,
      last30DaysTurnover: (turnover?['last30days'] as num?)?.toInt() ?? 0,
      agencyInfo: parsedAgencyInfo,
      note: agency?['note'] as String?,
      support: agency?['support'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'turnover': {
          'annual': annualTurnover,
          'last30days': last30DaysTurnover,
        },
        'agencyInfo': {
          'info': agencyInfo,
          'note': note,
          'support': support,
        },
      };

  @override
  List<Object?> get props => [
        annualTurnover,
        last30DaysTurnover,
        agencyInfo,
        note,
        support,
      ];
}
