import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:bayfay_merchant_flutter/core/network/api_endpoints.dart';
import 'package:bayfay_merchant_flutter/features/dashboard/controller/dashboard_controller.dart';
import '../../model/setting_model.dart';

/// 120dp Branded Store Card matching Android branded_shop_details layout
class BrandedShopCard extends ConsumerWidget {
  final SettingData data;
  final String fallbackImageUrl;
  final VoidCallback onTap;

  const BrandedShopCard({
    super.key,
    required this.data,
    required this.fallbackImageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authHeaderAsync = ref.watch(authHeaderProvider);
    final authHeaders = authHeaderAsync.valueOrNull ?? {};
    final baseUrl = authHeaders['baseUrl'] ?? ApiEndpoints.baseUrl;
    final imageUrl = data.getImageUrl(baseUrl);
    final finalUrl = imageUrl.isNotEmpty ? imageUrl : fallbackImageUrl;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.white,
          child: InkWell(
            onTap: onTap,
            child: Container(
              height: 120,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  // 104x104 Store Thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      width: 104,
                      height: 104,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        border: Border.all(color: Colors.grey.shade200, width: 0.8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: finalUrl.isNotEmpty
                          ? Image.network(
                              finalUrl,
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
                                size: 40,
                                color: Color(0xFFBDBDBD),
                              ),
                            )
                          : const Icon(
                              Icons.storefront,
                              size: 40,
                              color: Color(0xFFBDBDBD),
                            ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Middle Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          data.displayName.isNotEmpty ? data.displayName : 'Store Details',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          data.categoryName.isNotEmpty ? data.categoryName : 'Category',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          data.categoryType.isNotEmpty ? data.categoryType : 'Store Type',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: Color(0xFF9E9E9E),
                  ),
                ],
              ),
            ),
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
