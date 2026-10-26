import 'package:equatable/equatable.dart';

/// Represents a location picked via GPS, Map, or Google Places Autocomplete.
/// Mirrors Android's `PickedLocation.java` & `SelectedLocationLatLng.java`.
class PickedLocationData extends Equatable {
  final double latitude;
  final double longitude;
  final String formattedAddress;
  final String street;
  final String area;
  final String city;
  final String district;
  final String state;
  final String country;
  final String postalCode;

  const PickedLocationData({
    required this.latitude,
    required this.longitude,
    required this.formattedAddress,
    this.street = '',
    this.area = '',
    this.city = '',
    this.district = '',
    this.state = '',
    this.country = 'India',
    this.postalCode = '',
  });

  @override
  List<Object?> get props => [
        latitude,
        longitude,
        formattedAddress,
        street,
        area,
        city,
        district,
        state,
        country,
        postalCode,
      ];
}
