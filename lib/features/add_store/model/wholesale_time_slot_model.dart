import 'package:equatable/equatable.dart';

/// Model representing a wholesale delivery time slot item with custom order limit.
/// Matches legacy Android WholesaleTimeSlot payload contract.
class WholesaleTimeSlotModel extends Equatable {
  final String id;
  final String slotName;
  final String startTime;
  final String endTime;
  final int defaultLimit;
  final bool isSelected;
  final int limit;

  const WholesaleTimeSlotModel({
    required this.id,
    required this.slotName,
    this.startTime = '',
    this.endTime = '',
    this.defaultLimit = 0,
    this.isSelected = false,
    this.limit = 0,
  });

  factory WholesaleTimeSlotModel.fromJson(Map<String, dynamic> json) {
    final idStr = json['_id']?.toString() ??
        json['id']?.toString() ??
        json['slot_id']?.toString() ??
        '';
    final nameStr = json['slot_name']?.toString() ??
        json['name']?.toString() ??
        json['time_slot']?.toString() ??
        json['slot']?.toString() ??
        '';
    final limitVal = (json['limit'] as num?)?.toInt() ??
        (json['default_limit'] as num?)?.toInt() ??
        0;
    final selected = json['is_selected'] as bool? ??
        json['selected'] as bool? ??
        false;

    return WholesaleTimeSlotModel(
      id: idStr.isNotEmpty ? idStr : nameStr,
      slotName: nameStr,
      startTime: json['start_time']?.toString() ?? '',
      endTime: json['end_time']?.toString() ?? '',
      defaultLimit: limitVal,
      isSelected: selected,
      limit: limitVal,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'time_slot_id': id,
      'slot_name': slotName,
      'limit': limit,
    };
  }

  /// Formats time slot object to match native Android backend contract:
  /// { "id": 9, "max_count": 100, "slot": "7 pm to 9 pm" } or { "id": 9, "slot": "7 pm to 9 pm" }
  Map<String, dynamic> toNativeJson() {
    final parsedId = int.tryParse(id);
    final map = <String, dynamic>{
      'id': parsedId ?? id,
      'slot': slotName,
    };
    if (limit > 0) {
      map['max_count'] = limit;
    }
    return map;
  }

  WholesaleTimeSlotModel copyWith({
    String? id,
    String? slotName,
    String? startTime,
    String? endTime,
    int? defaultLimit,
    bool? isSelected,
    int? limit,
  }) {
    return WholesaleTimeSlotModel(
      id: id ?? this.id,
      slotName: slotName ?? this.slotName,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      defaultLimit: defaultLimit ?? this.defaultLimit,
      isSelected: isSelected ?? this.isSelected,
      limit: limit ?? this.limit,
    );
  }

  @override
  List<Object?> get props => [
        id,
        slotName,
        startTime,
        endTime,
        defaultLimit,
        isSelected,
        limit,
      ];
}
