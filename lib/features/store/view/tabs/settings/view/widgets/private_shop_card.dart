import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:bayfay_merchant_flutter/core/network/api_endpoints.dart';
import 'package:bayfay_merchant_flutter/features/dashboard/controller/dashboard_controller.dart';
import '../../model/setting_model.dart';

/// Private Shop Card matching Android private_profile_details
class PrivateShopCard extends ConsumerWidget {
  final SettingData data;
  final ValueChanged<bool> onToggleOpen;

  const PrivateShopCard({
    super.key,
    required this.data,
    required this.onToggleOpen,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final privateShop = data.privateShop;
    if (privateShop == null || !privateShop.isEnabled) {
      return const SizedBox.shrink();
    }

    final authHeaderAsync = ref.watch(authHeaderProvider);
    final authHeaders = authHeaderAsync.valueOrNull ?? {};
    final baseUrl = authHeaders['baseUrl'] ?? ApiEndpoints.baseUrl;
    final imageUrl = privateShop.getImageUrl(baseUrl);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    border: Border.all(color: Colors.grey.shade200, width: 0.8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          headers: authHeaders,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Shimmer.fromColors(
                              baseColor: Colors.grey.shade300,
                              highlightColor: Colors.grey.shade100,
                              child: Container(color: Colors.white),
                            );
                          },
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.storefront,
                            size: 36,
                            color: Color(0xFFBDBDBD),
                          ),
                        )
                      : const Icon(
                          Icons.storefront,
                          size: 36,
                          color: Color(0xFFBDBDBD),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      data.displayName.isNotEmpty ? data.displayName : 'Private Shop',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data.categoryName,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Private Shop',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF1976D2),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: privateShop.isOpen,
                activeColor: const Color(0xFF2196F3),
                onChanged: onToggleOpen,
              ),
            ],
          ),
        ),
        const Divider(
          height: 1,
          thickness: 1,
          color: Color(0xFFEEEEEE),
        ),
      ],
    );
  }
}
