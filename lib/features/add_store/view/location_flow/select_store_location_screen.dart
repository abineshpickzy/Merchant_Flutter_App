import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../model/picked_location_data.dart';
import 'confirm_store_location_screen.dart';
import 'google_places_search_screen.dart';

/// Screen allowing the merchant to choose how to select store location:
/// 1. GPS Auto-detect
/// 2. Google Places text search
/// Mirrors Android's `LocationPickActivity.java`.
class SelectStoreLocationScreen extends StatefulWidget {
  const SelectStoreLocationScreen({super.key});

  @override
  State<SelectStoreLocationScreen> createState() =>
      _SelectStoreLocationScreenState();
}

class _SelectStoreLocationScreenState extends State<SelectStoreLocationScreen> {
  bool _isLoadingGps = false;

  Future<void> _pickWithGps() async {
    setState(() => _isLoadingGps = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permissions are denied')),
            );
            setState(() => _isLoadingGps = false);
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Location permissions are permanently denied. Please enable in Settings.'),
            ),
          );
          setState(() => _isLoadingGps = false);
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );

      if (!mounted) return;
      setState(() => _isLoadingGps = false);

      final picked = await Navigator.of(context).push<PickedLocationData>(
        MaterialPageRoute(
          builder: (_) => ConfirmStoreLocationScreen(
            initialLatitude: pos.latitude,
            initialLongitude: pos.longitude,
          ),
        ),
      );

      if (picked != null && mounted) {
        Navigator.of(context).pop(picked);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingGps = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not fetch GPS location: $e')),
      );
    }
  }

  Future<void> _pickWithSearch() async {
    final picked = await Navigator.of(context).push<PickedLocationData>(
      MaterialPageRoute(
        builder: (_) => const GooglePlacesSearchScreen(),
      ),
    );

    if (picked != null && mounted) {
      Navigator.of(context).pop(picked);
    }
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
          'Select Store Location',
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'How would you like to set store location?',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF212121),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Accurate location allows customers nearby to discover your store.',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),

              // Option 1: GPS Current Location
              _LocationOptionCard(
                title: 'Auto Selected Current Location',
                subtitle: 'Using GPS to detect current position',
                icon: Icons.my_location,
                iconColor: const Color(0xFF1976D2),
                isLoading: _isLoadingGps,
                onTap: _isLoadingGps ? null : _pickWithGps,
              ),

              const SizedBox(height: 16),

              // Option 2: Search via Google
              _LocationOptionCard(
                title: 'Using Google Location',
                subtitle: 'Tap to search landmark, street, or city',
                icon: Icons.search,
                iconColor: const Color(0xFF388E3C),
                isLoading: false,
                onTap: _pickWithSearch,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final bool isLoading;
  final VoidCallback? onTap;

  const _LocationOptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE0E0E0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: iconColor.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: isLoading
                  ? Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: iconColor,
                        ),
                      ),
                    )
                  : Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF212121),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
