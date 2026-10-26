import 'package:equatable/equatable.dart';

/// Represents one entry in the `GET merchant/category` → `type[]` array.
/// Matches `StoreCategoryResponse.Type` from Android.
class StoreTypeModel extends Equatable {
  final int id;
  final String name;

  const StoreTypeModel({required this.id, required this.name});

  factory StoreTypeModel.fromJson(Map<String, dynamic> json) {
    return StoreTypeModel(
      id: (json['_id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [id, name];
}
