import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:bayfay_merchant_flutter/core/constants/app_strings.dart';
import '../../model/picked_location_data.dart';
import 'package:bayfay_merchant_flutter/core/services/geocoding_service.dart';
import 'google_places_search_screen.dart';

/// Interactive Map screen for confirming the store location pin.
/// Matches Android's `PickedLocationMapsActivity.java`.
class ConfirmStoreLocationScreen extends StatefulWidget {
  final double initialLatitude;
  final double initialLongitude;
  final String? initialAddress;

  const ConfirmStoreLocationScreen({
    super.key,
    required this.initialLatitude,
    required this.initialLongitude,
    this.initialAddress,
  });

  @override
  State<ConfirmStoreLocationScreen> createState() =>
      _ConfirmStoreLocationScreenState();
}

class _ConfirmStoreLocationScreenState
    extends State<ConfirmStoreLocationScreen> {
  GoogleMapController? _mapController;
  late LatLng _currentCenter;
  String _resolvedAddress = AppStrings.locatingAddress;
  String _street = '';
  String _area = '';
  String _city = '';
  String _district = '';
  String _state = '';
  String _country = 'India';
  String _postalCode = '';
  bool _isResolving = false;

  @override
  void initState() {
    super.initState();
    _currentCenter = LatLng(
      widget.initialLatitude != 0.0 ? widget.initialLatitude : 12.9716,
      widget.initialLongitude != 0.0 ? widget.initialLongitude : 77.5946,
    );
    if (widget.initialAddress != null && widget.initialAddress!.isNotEmpty) {
      _resolvedAddress = widget.initialAddress!;
    } else {
      _reverseGeocode(_currentCenter.latitude, _currentCenter.longitude);
    }
  }

  Future<void> _reverseGeocode(double lat, double lng) async {
    if (!mounted) return;
    setState(() => _isResolving = true);
    try {
      final res = await GeocodingService.reverseGeocode(lat, lng);
      if (!mounted) return;
      setState(() {
        _street = res.formattedAddress;
        _area = res.area;
        _city = res.city;
        _district = res.district;
        _state = res.state;
        _country = res.country;
        _postalCode = res.postalCode;
        _resolvedAddress = res.formattedAddress;
        _isResolving = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _resolvedAddress =
            'Coordinates: ${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
        _isResolving = false;
      });
    }
  }

  Future<void> _goToCurrentLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );
      final newLatLng = LatLng(pos.latitude, pos.longitude);
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: newLatLng, zoom: 17),
        ),
      );
      _reverseGeocode(newLatLng.latitude, newLatLng.longitude);
    } catch (_) {}
  }

  Future<void> _openSearch() async {
    final picked = await Navigator.of(context).push<PickedLocationData>(
      MaterialPageRoute(
        builder: (_) => const GooglePlacesSearchScreen(returnDirectly: true),
      ),
    );
    if (picked != null && mounted) {
      final newLatLng = LatLng(picked.latitude, picked.longitude);
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: newLatLng, zoom: 17),
        ),
      );
      setState(() {
        _currentCenter = newLatLng;
        _resolvedAddress = picked.formattedAddress;
        _street = picked.street;
        _area = picked.area;
        _city = picked.city;
        _district = picked.district;
        _state = picked.state;
        _country = picked.country;
        _postalCode = picked.postalCode;
      });
    }
  }

  void _onConfirm() {
    final result = PickedLocationData(
      latitude: _currentCenter.latitude,
      longitude: _currentCenter.longitude,
      formattedAddress: _resolvedAddress,
      street: _street.isNotEmpty ? _street : _resolvedAddress,
      area: _area,
      city: _city,
      district: _district,
      state: _state,
      country: _country,
      postalCode: _postalCode,
    );
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          AppStrings.confirmStoreLocationTitle,
          style: TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE0E0E0)),
        ),
      ),
      body: Stack(
        children: [
          // 1. Interactive Google Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentCenter,
              zoom: 16,
            ),
            onMapCreated: (ctrl) => _mapController = ctrl,
            onCameraMove: (pos) {
              _currentCenter = pos.target;
            },
            onCameraIdle: () {
              _reverseGeocode(_currentCenter.latitude, _currentCenter.longitude);
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),

          // 2. Search Shortcut Overlay at top
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: InkWell(
              onTap: _openSearch,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search, color: Color(0xFF1976D2), size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        AppStrings.searchStreetAreaLandmark,
                        style: TextStyle(color: Color(0xFF757575), fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. Fixed Center Pin Marker Overlay
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 36),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(204),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      AppStrings.moveMapToPlacePin,
                      style: TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Icon(
                    Icons.location_on,
                    size: 46,
                    color: Color(0xFFE53935),
                  ),
                ],
              ),
            ),
          ),

          // 4. Floating Current Location Button
          Positioned(
            right: 16,
            bottom: 180,
            child: FloatingActionButton.small(
              heroTag: 'map_gps_btn',
              backgroundColor: Colors.white,
              onPressed: _goToCurrentLocation,
              child: const Icon(Icons.my_location, color: Color(0xFF1976D2)),
            ),
          ),

          // 5. Bottom Address Confirmation Sheet
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: const BoxDecoration(
                color: Color(0xFF263238),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Color(0xFFFF9800),
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                AppStrings.selectedStoreAddress,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _isResolving ? AppStrings.resolvingAddress : _resolvedAddress,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_isResolving)
                          const Padding(
                            padding: EdgeInsets.only(left: 8, top: 4),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFFFF9800),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _onConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6F00),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        AppStrings.confirmUpper,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
