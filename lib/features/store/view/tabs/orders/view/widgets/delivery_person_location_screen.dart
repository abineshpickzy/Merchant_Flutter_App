import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:bayfay_merchant_flutter/app/theme/app_colors.dart';
import 'package:bayfay_merchant_flutter/core/network/api_endpoints.dart';
import '../../controller/orders_controller.dart';
import '../../model/order_model.dart';

/// Full-screen Delivery Person Current Location & Info screen
/// strictly matching Android DeliveryPersonCurrentLocationActivity (activity_delivery_person_current_location.xml)
class DeliveryPersonLocationScreen extends ConsumerStatefulWidget {
  final OrderModel order;

  const DeliveryPersonLocationScreen({
    super.key,
    required this.order,
  });

  static Future<void> open(
    BuildContext context, {
    required OrderModel order,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DeliveryPersonLocationScreen(order: order),
      ),
    );
  }

  @override
  ConsumerState<DeliveryPersonLocationScreen> createState() =>
      _DeliveryPersonLocationScreenState();
}

class _DeliveryPersonLocationScreenState
    extends ConsumerState<DeliveryPersonLocationScreen> {
  GoogleMapController? _mapController;

  @override
  Widget build(BuildContext context) {
    final assistantId = widget.order.assistantInfo?.assistantId ?? '';
    final infoAsync = ref.watch(deliveryPersonInfoProvider(assistantId));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(45),
        child: AppBar(
          backgroundColor: AppColors.primary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
          centerTitle: true,
          title: infoAsync.when(
            data: (data) {
              final firstName = data?['first_name']?.toString() ?? '';
              final lastName = data?['last_name']?.toString() ?? '';
              final title = '$firstName $lastName'.trim();
              return Text(
                title.isNotEmpty ? title : 'Location',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Nunito',
                ),
              );
            },
            loading: () => const Text(
              'Location',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                fontFamily: 'Nunito',
              ),
            ),
            error: (_, _) => const Text(
              'Location',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                fontFamily: 'Nunito',
              ),
            ),
          ),
        ),
      ),
      body: infoAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                const SizedBox(height: 12),
                Text(
                  'Failed to load delivery person info\n$err',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        data: (data) {
          if (data == null || data.isEmpty) {
            return const Center(
              child: Text(
                'Delivery Person Info not Available',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            );
          }

          return _buildBody(data);
        },
      ),
    );
  }

  Widget _buildBody(Map<String, dynamic> data) {
    final firstName = data['first_name']?.toString() ?? '';
    final lastName = data['last_name']?.toString() ?? '';
    final fullName = '$firstName $lastName'.trim();

    // Mobile number extraction
    String mobileNumber = '';
    if (data['mobile'] is Map) {
      final mobMap = data['mobile'] as Map<String, dynamic>;
      final code = mobMap['dialing_code']?.toString() ?? '';
      final num = mobMap['number']?.toString() ?? '';
      mobileNumber =
          num.isNotEmpty ? (code.isNotEmpty ? '+$code$num' : num) : '';
    } else if (data['mobile'] != null) {
      mobileNumber = data['mobile'].toString();
    }

    // Avatar URL extraction
    String avatarUrl = '';
    if (data['avatar'] is List && (data['avatar'] as List).isNotEmpty) {
      final first = (data['avatar'] as List).first;
      if (first is Map && first['name'] != null) {
        avatarUrl =
            ApiEndpoints.deliveryPersonAvatarUrl(first['name'].toString());
      }
    }
    if (avatarUrl.isEmpty && data['image'] != null) {
      avatarUrl =
          ApiEndpoints.deliveryPersonAvatarUrl(data['image'].toString());
    }

    // Online Status Calculation matching Android minutesValidation
    final onlineTimeStr = data['online_time']?.toString() ?? '';
    int? diffMinutes;
    if (onlineTimeStr.isNotEmpty) {
      final parsed = DateTime.tryParse(onlineTimeStr)?.toLocal();
      if (parsed != null) {
        diffMinutes = DateTime.now().difference(parsed).inMinutes;
      }
    }

    Color statusColor;
    String statusText;
    if (diffMinutes != null && diffMinutes < 3) {
      statusColor = const Color(0xFF4CAF50); // Online
      statusText = 'Online';
    } else if (diffMinutes != null && diffMinutes <= 30) {
      statusColor = const Color(0xFFFF9800); // Away
      statusText = 'Away';
    } else {
      statusColor = const Color(0xFF9E9E9E); // Offline
      statusText = 'Offline';
    }

    // Coordinates extraction: GeoJSON format [lng, lat]
    final location = data['location'] as Map<String, dynamic>?;
    final coordinates = location?['coordinates'] as List?;
    double? lat;
    double? lng;
    if (coordinates != null && coordinates.length >= 2) {
      lng = (coordinates[0] as num?)?.toDouble();
      lat = (coordinates[1] as num?)?.toDouble();
    }

    return Column(
      children: [
        // 1. Top Card strictly matching R.id.delivery_person_detail in Android
        Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE0E0E0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Left: Avatar + Online Status Badge
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFBDBDBD), width: 1),
                    ),
                    child: ClipOval(
                      child: avatarUrl.isNotEmpty
                          ? Image.network(
                              avatarUrl,
                              width: 54,
                              height: 54,
                              fit: BoxFit.cover,
                              headers: ref
                                  .watch(orderAuthHeadersProvider)
                                  .valueOrNull,
                              errorBuilder: (_, _, _) => _buildAvatarPlaceholder(),
                            )
                          : _buildAvatarPlaceholder(),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                          fontFamily: 'Nunito',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 14),

              // Center: Name & Order ID
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      fullName.isNotEmpty ? fullName : 'Delivery Associate',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        fontFamily: 'Nunito',
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (widget.order.orderId.isNotEmpty)
                      Text(
                        'Order ID: ${widget.order.orderId}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                          fontFamily: 'Nunito',
                        ),
                      ),
                  ],
                ),
              ),

              // Right: Call Button matching R.id.call_btn (ic_phone_img)
              if (mobileNumber.isNotEmpty)
                InkWell(
                  onTap: () => _handleCall(mobileNumber),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2196F3),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x332196F3),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.phone,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // 2. Google Map taking rest of the screen matching R.id.map
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            clipBehavior: Clip.antiAlias,
            child: (lat != null && lng != null)
                ? GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(lat, lng),
                      zoom: 17,
                    ),
                    onMapCreated: (ctrl) => _mapController = ctrl,
                    markers: {
                      Marker(
                        markerId: const MarkerId('delivery_person_marker'),
                        position: LatLng(lat, lng),
                        infoWindow: InfoWindow(
                          title: fullName.isNotEmpty
                              ? fullName
                              : 'Delivery Person Location',
                          snippet: 'Delivery Associate Location',
                        ),
                      ),
                    },
                    myLocationEnabled: false,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: true,
                    mapToolbarEnabled: true,
                  )
                : Container(
                    color: Colors.white,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_off_outlined,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Delivery Person Location not Available',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                            fontFamily: 'Nunito',
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Container(
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: const Icon(
        Icons.person,
        size: 32,
        color: Colors.grey,
      ),
    );
  }

  Future<void> _handleCall(String number) async {
    final clean = number.trim();
    if (clean.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: clean);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (_) {
      // Fall through
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
