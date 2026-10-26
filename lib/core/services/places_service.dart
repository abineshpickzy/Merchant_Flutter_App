import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';

/// Represents a single autocomplete prediction returned from Google Places API.
class PlacePrediction {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;

  const PlacePrediction({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
  });

  factory PlacePrediction.fromJson(Map<String, dynamic> json) {
    final structured =
        json['structured_formatting'] as Map<String, dynamic>? ?? {};
    return PlacePrediction(
      placeId: json['place_id'] as String? ?? '',
      description: json['description'] as String? ?? '',
      mainText: structured['main_text'] as String? ??
          json['description'] as String? ??
          '',
      secondaryText: structured['secondary_text'] as String? ?? '',
    );
  }
}

/// Represents detailed location data for a chosen Google Place.
class PlaceDetails {
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

  const PlaceDetails({
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

  factory PlaceDetails.fromJson(Map<String, dynamic> json) {
    final geometry = json['geometry'] as Map<String, dynamic>? ?? {};
    final location = geometry['location'] as Map<String, dynamic>? ?? {};
    final lat = (location['lat'] as num?)?.toDouble() ?? 0.0;
    final lng = (location['lng'] as num?)?.toDouble() ?? 0.0;
    final formattedAddress = json['formatted_address'] as String? ?? '';

    final components =
        (json['address_components'] as List?)?.whereType<Map<String, dynamic>>() ??
            [];

    String streetNumber = '';
    String route = '';
    String subLocality2 = '';
    String subLocality1 = '';
    String locality = '';
    String adminArea2 = ''; // District
    String adminArea1 = ''; // State
    String country = 'India';
    String postalCode = '';

    for (final comp in components) {
      final types = (comp['types'] as List?)?.map((e) => e.toString()).toList() ?? [];
      final longName = comp['long_name'] as String? ?? '';

      if (types.contains('street_number')) {
        streetNumber = longName;
      } else if (types.contains('route')) {
        route = longName;
      } else if (types.contains('sublocality_level_2')) {
        subLocality2 = longName;
      } else if (types.contains('sublocality_level_1') || types.contains('sublocality')) {
        subLocality1 = longName;
      } else if (types.contains('locality')) {
        locality = longName;
      } else if (types.contains('administrative_area_level_2')) {
        adminArea2 = longName;
      } else if (types.contains('administrative_area_level_1')) {
        adminArea1 = longName;
      } else if (types.contains('country')) {
        country = longName;
      } else if (types.contains('postal_code')) {
        postalCode = longName;
      }
    }

    final streetParts = [streetNumber, route].where((s) => s.isNotEmpty).join(' ');
    final area = subLocality2.isNotEmpty
        ? subLocality2
        : (subLocality1.isNotEmpty ? subLocality1 : locality);

    return PlaceDetails(
      latitude: lat,
      longitude: lng,
      formattedAddress: formattedAddress.isNotEmpty
          ? formattedAddress
          : [streetParts, area, locality, adminArea2, adminArea1, postalCode, country]
              .where((s) => s.isNotEmpty)
              .join(', '),
      street: streetParts.isNotEmpty ? streetParts : formattedAddress,
      area: area,
      city: locality.isNotEmpty ? locality : adminArea2,
      district: adminArea2,
      state: adminArea1,
      country: country,
      postalCode: postalCode,
    );
  }
}

/// Service providing Google Places Autocomplete and Place Details.
class PlacesService {
  static String get googleApiKey => AppConstants.googleMapsApiKey;

  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
    ),
  );

  /// Queries Google Places Autocomplete API for place predictions.
  static Future<List<PlacePrediction>> autocomplete(
    String query, {
    String countryCode = 'in',
  }) async {
    final trimmed = query.trim();
    if (trimmed.length < 3) return [];

    try {
      final res = await _dio.get(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json',
        queryParameters: {
          'input': trimmed,
          'key': AppConstants.googleMapsApiKey,
          'components': 'country:$countryCode',
        },
      );

      final data = res.data as Map<String, dynamic>?;
      if (data == null) return [];

      final status = data['status'] as String?;
      if (status != 'OK' && status != 'ZERO_RESULTS') {
        debugPrint('[PlacesService] Autocomplete status: $status');
        return [];
      }

      final predictions = (data['predictions'] as List?) ?? [];
      return predictions
          .whereType<Map<String, dynamic>>()
          .map(PlacePrediction.fromJson)
          .toList();
    } catch (e) {
      debugPrint('[PlacesService] autocomplete error: $e');
      return [];
    }
  }

  /// Fetches place details (geometry and address components) for a place_id.
  static Future<PlaceDetails?> getPlaceDetails(String placeId) async {
    if (placeId.trim().isEmpty) return null;

    try {
      final res = await _dio.get(
        'https://maps.googleapis.com/maps/api/place/details/json',
        queryParameters: {
          'place_id': placeId,
          'key': AppConstants.googleMapsApiKey,
          'fields': 'geometry,formatted_address,address_components,name',
        },
      );

      final data = res.data as Map<String, dynamic>?;
      if (data == null) return null;

      final result = data['result'] as Map<String, dynamic>?;
      if (result == null) return null;

      return PlaceDetails.fromJson(result);
    } catch (e) {
      debugPrint('[PlacesService] getPlaceDetails error: $e');
      return null;
    }
  }
}
