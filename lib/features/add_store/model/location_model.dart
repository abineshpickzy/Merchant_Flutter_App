import 'package:equatable/equatable.dart';

/// Represents one city/location entry from `GET merchant/location`.
/// Matches `StateCityResponse.Location` from Android.
class LocationModel extends Equatable {
  final String id;
  final String city;
  final String state;
  final String country;

  const LocationModel({
    required this.id,
    required this.city,
    required this.state,
    required this.country,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: json['_id'] as String? ?? '',
      city: json['name'] as String? ?? '',
      state: json['state'] as String? ?? '',
      country: json['country'] as String? ?? 'India',
    );
  }

  @override
  List<Object?> get props => [id, city, state, country];
}
