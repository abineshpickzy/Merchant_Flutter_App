import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/places_service.dart';
import '../../model/picked_location_data.dart';
import 'confirm_store_location_screen.dart';

/// Screen for searching store location via Google Places Autocomplete.
/// Matches Android's `AutocompleteActivity`.
class GooglePlacesSearchScreen extends StatefulWidget {
  final bool returnDirectly;

  const GooglePlacesSearchScreen({
    super.key,
    this.returnDirectly = false,
  });

  @override
  State<GooglePlacesSearchScreen> createState() =>
      _GooglePlacesSearchScreenState();
}

class _GooglePlacesSearchScreenState extends State<GooglePlacesSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  List<_SearchResultItem> _results = [];
  bool _isLoading = false;
  Timer? _debounceTimer;

  @override
  void dispose() {
    _controller.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounceTimer?.cancel();
    final trimmed = query.trim();
    if (trimmed.length < 3) {
      setState(() {
        _results = [];
        _isLoading = false;
      });
      return;
    }

    // Trigger rebuild to show/hide suffix clear icon and update state
    setState(() {});

    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      _searchPlaces(trimmed);
    });
  }

  Future<void> _searchPlaces(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 3) {
      if (mounted) {
        setState(() {
          _results = [];
          _isLoading = false;
        });
      }
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // 1. Try Google Places Autocomplete API
      final predictions = await PlacesService.autocomplete(trimmed);
      if (!mounted) return;

      if (predictions.isNotEmpty) {
        final items = predictions
            .map((p) => _SearchResultItem(
                  placeId: p.placeId,
                  title: p.mainText,
                  subtitle: p.secondaryText.isNotEmpty
                      ? p.secondaryText
                      : p.description,
                ))
            .toList();

        setState(() {
          _results = items;
          _isLoading = false;
        });
        return;
      }

      // 2. Fallback to platform Geocoder if Places Autocomplete returned empty
      final locations = await locationFromAddress(trimmed);
      if (!mounted) return;

      final items = <_SearchResultItem>[];
      for (final loc in locations.take(5)) {
        try {
          final placemarks =
              await placemarkFromCoordinates(loc.latitude, loc.longitude);
          if (placemarks.isNotEmpty) {
            final p = placemarks.first;
            final title = [p.name, p.street, p.subLocality]
                .where((s) => s != null && s.isNotEmpty)
                .toSet()
                .join(', ');
            final subtitle = [
              p.locality,
              p.subAdministrativeArea,
              p.administrativeArea,
              p.postalCode,
              p.country
            ].where((s) => s != null && s.isNotEmpty).join(', ');
            items.add(_SearchResultItem(
              title: title.isNotEmpty ? title : trimmed,
              subtitle: subtitle,
              latitude: loc.latitude,
              longitude: loc.longitude,
            ));
          } else {
            items.add(_SearchResultItem(
              title: trimmed,
              subtitle:
                  '${loc.latitude.toStringAsFixed(4)}, ${loc.longitude.toStringAsFixed(4)}',
              latitude: loc.latitude,
              longitude: loc.longitude,
            ));
          }
        } catch (_) {
          items.add(_SearchResultItem(
            title: trimmed,
            subtitle:
                '${loc.latitude.toStringAsFixed(4)}, ${loc.longitude.toStringAsFixed(4)}',
            latitude: loc.latitude,
            longitude: loc.longitude,
          ));
        }
      }

      setState(() {
        _results = items;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _results = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _selectResult(_SearchResultItem item) async {
    setState(() => _isLoading = true);

    double lat = item.latitude;
    double lng = item.longitude;
    String fullAddress = '${item.title}, ${item.subtitle}';
    String street = item.title;
    String area = '';
    String city = '';
    String district = '';
    String stateStr = '';
    String country = 'India';
    String postalCode = '';

    if (item.placeId.isNotEmpty) {
      final details = await PlacesService.getPlaceDetails(item.placeId);
      if (details != null) {
        lat = details.latitude;
        lng = details.longitude;
        fullAddress = details.formattedAddress;
        street = details.street;
        area = details.area;
        city = details.city;
        district = details.district;
        stateStr = details.state;
        country = details.country;
        postalCode = details.postalCode;
      }
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    final pickedData = PickedLocationData(
      latitude: lat,
      longitude: lng,
      formattedAddress: fullAddress,
      street: street.isNotEmpty ? street : fullAddress,
      area: area,
      city: city,
      district: district,
      state: stateStr,
      country: country,
      postalCode: postalCode,
    );

    if (widget.returnDirectly) {
      Navigator.of(context).pop(pickedData);
      return;
    }

    final confirmed = await Navigator.of(context).push<PickedLocationData>(
      MaterialPageRoute(
        builder: (_) => ConfirmStoreLocationScreen(
          initialLatitude: lat,
          initialLongitude: lng,
          initialAddress: fullAddress,
        ),
      ),
    );

    if (confirmed != null && mounted) {
      Navigator.of(context).pop(confirmed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Container(
          height: 44,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE0E0E0)),
          ),
          child: TextField(
            controller: _controller,
            autofocus: true,
            onChanged: _onQueryChanged,
            textAlignVertical: TextAlignVertical.center,
            decoration: InputDecoration(
              hintText: AppStrings.searchLocationHint,
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey, size: 18),
                      onPressed: () {
                        _controller.clear();
                        _onQueryChanged('');
                      },
                    )
                  : null,
            ),
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isLoading)
            const LinearProgressIndicator(
              minHeight: 2,
              color: Color(0xFF1976D2),
            ),
          Expanded(
            child: _results.isEmpty
                ? Center(
                    child: Text(
                      _controller.text.isEmpty
                          ? AppStrings.searchByStreetAreaLandmark
                          : AppStrings.noLocationsFound,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  )
                : ListView.separated(
                    itemCount: _results.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 56),
                    itemBuilder: (context, index) {
                      final item = _results[index];
                      return ListTile(
                        leading: const CircleAvatar(
                          radius: 18,
                          backgroundColor: Color(0xFFF5F5F5),
                          child: Icon(
                            Icons.location_on_outlined,
                            color: Color(0xFF1976D2),
                            size: 20,
                          ),
                        ),
                        title: Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF212121),
                          ),
                        ),
                        subtitle: item.subtitle.isNotEmpty
                            ? Text(
                                item.subtitle,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              )
                            : null,
                        onTap: () => _selectResult(item),
                      );
                    },
                  ),
          ),
          // Powered by Google indicator matching native Android UI
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey[200]!, width: 1),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  AppStrings.poweredByGoogle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9E9E9E),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchResultItem {
  final String placeId;
  final String title;
  final String subtitle;
  final double latitude;
  final double longitude;

  _SearchResultItem({
    this.placeId = '',
    required this.title,
    required this.subtitle,
    this.latitude = 0.0,
    this.longitude = 0.0,
  });
}
