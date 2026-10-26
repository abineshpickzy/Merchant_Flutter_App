import 'package:equatable/equatable.dart';

/// Data model representing order cancellation reason returned by `GET order/cancelReason/list`.
class CancelReasonModel extends Equatable {
  final String id;
  final String displayName;

  const CancelReasonModel({
    required this.id,
    required this.displayName,
  });

  factory CancelReasonModel.fromJson(Map<String, dynamic> json) {
    return CancelReasonModel(
      id: json['_id']?.toString() ?? '',
      displayName: json['display_name']?.toString() ?? '',
    );
  }

  @override
  List<Object?> get props => [id, displayName];
}
