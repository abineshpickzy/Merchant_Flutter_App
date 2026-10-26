import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import '../constants/app_constants.dart';

/// Result object holding all components from geocoding.
class GeocodingResult {
  final String formattedAddress;
  final String street;
  final String area;
  final String city;
  final String district;
  final String state;
  final String country;
  final String postalCode;
  final double latitude;
  final double longitude;

  const GeocodingResult({
    required this.formattedAddress,
    this.street = '',
    this.area = '',
    this.city = '',
    this.district = '',
    this.state = '',
    this.country = 'India',
    this.postalCode = '',
    this.latitude = 0.0,
    this.longitude = 0.0,
  });
}

/// Geocoding service that leverages Google Maps Geocoding REST API to retrieve
/// complete address components (including neighborhoods/sublocalities like "Velayuthan Nagar")
/// with graceful fallback to the device's native platform Geocoder (placemarkFromCoordinates).
class GeocodingService {
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ),
  );

  /// Reverse geocodes [lat] and [lng] into a comprehensive [GeocodingResult].
  /// Attempts Google Geocoding API first, falling back to native Geocoder.
  static Future<GeocodingResult> reverseGeocode(
    double lat,
    double lng,
  ) async {
    // 1. Try Google Maps Geocoding REST API for rich sublocality / neighborhood info
    try {
      final res = await _dio.get(
        'https://maps.googleapis.com/maps/api/geocode/json',
        queryParameters: {
          'latlng': '$lat,$lng',
          'key': AppConstants.googleMapsApiKey,
        },
      );

      final data = res.data as Map<String, dynamic>?;
      if (data != null && data['status'] == 'OK') {
        final results = (data['results'] as List?) ?? [];
        if (results.isNotEmpty) {
          final first = results.first as Map<String, dynamic>;
          final parsed = _fromGoogleGeocodeResult(first, lat: lat, lng: lng);
          if (parsed != null) {
            return parsed;
          }
        }
      }
    } catch (e) {
      debugPrint('[GeocodingService] Google Geocoding API error: $e');
    }

    // 2. Fallback to native platform Geocoder
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        return fromPlacemark(p, lat: lat, lng: lng);
      }
    } catch (e) {
      debugPrint('[GeocodingService] Native platform geocoding error: $e');
    }

    final coordFallback =
        '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
    return GeocodingResult(
      formattedAddress: coordFallback,
      street: coordFallback,
      latitude: lat,
      longitude: lng,
    );
  }

  static GeocodingResult? _fromGoogleGeocodeResult(
    Map<String, dynamic> json, {
    required double lat,
    required double lng,
  }) {
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

    return GeocodingResult(
      formattedAddress: formattedAddress,
      street: streetParts.isNotEmpty ? streetParts : formattedAddress,
      area: area,
      city: locality.isNotEmpty ? locality : adminArea2,
      district: adminArea2,
      state: adminArea1,
      country: country,
      postalCode: postalCode,
      latitude: lat,
      longitude: lng,
    );
  }

  /// Synthesizes a complete address string from all non-empty Placemark components.
  static GeocodingResult fromPlacemark(
    Placemark p, {
    double lat = 0.0,
    double lng = 0.0,
  }) {
    final addressTokens = <String>[];

    void addToken(String? val) {
      if (val == null) return;
      final trimmed = val.trim();
      if (trimmed.isEmpty) return;
      // Split on commas if the property has multiple sub-segments
      final subSegments = trimmed
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty);
      for (final segment in subSegments) {
        final alreadyPresent = addressTokens.any(
          (existing) => existing.toLowerCase() == segment.toLowerCase(),
        );
        if (!alreadyPresent) {
          addressTokens.add(segment);
        }
      }
    }

    // 1. Door / Plot / Building
    addToken(p.subThoroughfare);
    if (p.name != null &&
        p.name!.trim().isNotEmpty &&
        p.name!.trim().toLowerCase() != p.thoroughfare?.trim().toLowerCase() &&
        p.name!.trim().toLowerCase() != p.subLocality?.trim().toLowerCase() &&
        p.name!.trim().toLowerCase() != p.locality?.trim().toLowerCase()) {
      addToken(p.name);
    }

    // 2. Street / Thoroughfare (falls back to street if thoroughfare is empty)
    if (p.thoroughfare != null && p.thoroughfare!.trim().isNotEmpty) {
      addToken(p.thoroughfare);
    } else {
      addToken(p.street);
    }

    // 3. SubLocality / Neighborhood / Area (Velayuthan Nagar)
    addToken(p.subLocality);

    // 4. Locality / Town
    addToken(p.locality);

    // 5. SubAdministrativeArea / District
    addToken(p.subAdministrativeArea);

    // 6. AdministrativeArea / State
    addToken(p.administrativeArea);

    // 7. Postal Code
    addToken(p.postalCode);

    // 8. Country
    addToken(p.country);

    final formatted = addressTokens.isNotEmpty
        ? addressTokens.join(', ')
        : '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';

    return GeocodingResult(
      formattedAddress: formatted,
      street: formatted,
      area: (p.subLocality != null && p.subLocality!.trim().isNotEmpty)
          ? p.subLocality!.trim()
          : (p.locality ?? '').trim(),
      city: (p.locality != null && p.locality!.trim().isNotEmpty)
          ? p.locality!.trim()
          : ((p.subAdministrativeArea != null && p.subAdministrativeArea!.trim().isNotEmpty)
              ? p.subAdministrativeArea!.trim()
              : (p.subLocality ?? '').trim()),
      district: (p.subAdministrativeArea ?? '').trim(),
      state: (p.administrativeArea ?? '').trim(),
      country: (p.country ?? 'India').trim(),
      postalCode: (p.postalCode ?? '').trim(),
      latitude: lat,
      longitude: lng,
    );
  }
}
