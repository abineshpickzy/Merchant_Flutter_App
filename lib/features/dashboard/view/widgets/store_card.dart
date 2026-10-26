import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:bayfay_merchant_flutter/app/theme/app_colors.dart';
import 'package:bayfay_merchant_flutter/core/network/api_endpoints.dart';
import '../../controller/dashboard_controller.dart';
import '../../model/store_model.dart';
import 'package:bayfay_merchant_flutter/features/store/view/store_screen.dart';

/// 1:1 Parity implementation of legacy Android m_shops_list.xml store item card
class StoreCard extends ConsumerWidget {
  final StoreModel store;
  final bool isSelected;
  final VoidCallback? onTap;

  const StoreCard({
    super.key,
    required this.store,
    this.isSelected = false,
    this.onTap,
  });

  /// Handles store selection and navigation with status gate validation (status == 2).
  static void handleStoreTap(
    BuildContext context,
    WidgetRef ref,
    StoreModel store, {
    VoidCallback? onApproved,
  }) {
    if (store.status == 2) {
      ref.read(selectedStoreProvider.notifier).selectStore(store);
      if (onApproved != null) {
        onApproved();
      } else {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => StoreScreen(store: store),
          ),
        );
      }
    } else {
      final String message = (store.status == 1 || store.status == 0)
          ? 'Store is waiting for approval'
          : 'This store is currently inactive';

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authHeaderAsync = ref.watch(authHeaderProvider);

    final isApprovedActive = store.status == 2;
    final hasRating = isApprovedActive && store.rating > 0.0;
    final isPendingReview = store.status == 1 || store.status == 0;
    final isRejected = store.status == 3;
    final isSuspended = store.status == 4;
    final hasNewOrders = store.newOrderCount > 0;

    String? statusText;
    LinearGradient statusGradient = const LinearGradient(
      colors: [Color(0xFFFFB300), Color(0xFFFFA000)],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );

    if (isPendingReview) {
      statusText = 'Pending';
      statusGradient = const LinearGradient(
        colors: [Color(0xFFFFB300), Color(0xFFFFA000)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      );
    } else if (isRejected) {
      statusText = 'Rejected';
      statusGradient = const LinearGradient(
        colors: [Color(0xFFE52D27), Color(0xFFFF512F)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      );
    } else if (isSuspended) {
      statusText = 'Suspended';
      statusGradient = const LinearGradient(
        colors: [Color(0xFFE52D27), Color(0xFFFF512F)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      );
    }

    final imageUrl = store.getImageUrl(ApiEndpoints.baseUrl);
   // debugPrint('[StoreCard] Building "${store.displayName}" (id: ${store.id}) with Image URL: "$imageUrl"');

    return InkWell(
      onTap: onTap ?? () => handleStoreTap(context, ref, store),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thumbnail container with overlays
            AspectRatio(
              aspectRatio: 1.0,
              child: Stack(
                children: [
                  // Store Image / Thumbnail
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F2F2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : const Color(0xFFE0E0E0),
                            width: isSelected ? 2.0 : 0.8,
                          ),
                        ),
                        child: imageUrl.isNotEmpty
                            ? authHeaderAsync.when(
                                data: (headers) => Image.network(
                                  imageUrl,
                                  headers: headers.isNotEmpty ? headers : null,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    debugPrint(
                                      '[StoreCard] Image LOAD ERROR for "${store.displayName}": $error (URL: "$imageUrl")',
                                    );
                                    return _buildFallbackPlaceholder();
                                  },
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return _buildShimmerPlaceholder();
                                  },
                                ),
                                loading: () => _buildShimmerPlaceholder(),
                                error: (err, _) {
                                  debugPrint(
                                    '[StoreCard] Auth Header Provider Error for "${store.displayName}": $err',
                                  );
                                  return _buildFallbackPlaceholder();
                                },
                              )
                            : _buildFallbackPlaceholder(),
                      ),
                    ),
                  ),

                  // Status Review Banner with Yellow/Amber Gradient for Pending
                  if (statusText != null)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        decoration: BoxDecoration(
                          gradient: statusGradient,
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(6),
                            bottomRight: Radius.circular(6),
                          ),
                        ),
                        child: Text(
                          statusText,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),

                  // Rating Badge (matching @id/store_rating + rating_star)
                  if (hasRating && !isPendingReview)
                    Positioned(
                      left: 4,
                      bottom: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.18),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              store.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Color(0xFF212121),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(
                              Icons.star_rounded,
                              size: 11,
                              color: Color(0xFFFFB300),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Order / Notification Count Badge (matching @id/badge)
                  if (hasNewOrders)
                    Positioned(
                      top: 2,
                      right: 2,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE53935),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            store.newOrderCount > 99
                                ? '99+'
                                : '${store.newOrderCount}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 4),

            // Store Title (matching @id/title: 12dp, max 2 lines, centered)
            Flexible(
              child: Text(
                store.displayName,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? AppColors.primary : const Color(0xFF333333),
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackPlaceholder() {
    return Image.asset(
      'assets/images/icon_bg.webp',
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Center(
        child: Icon(
          store.isWholeSale
              ? Icons.storefront_rounded
              : (store.isRestaurant
                  ? Icons.restaurant_rounded
                  : Icons.shopping_bag_outlined),
          size: 32,
          color: const Color(0xFF9E9E9E),
        ),
      ),
    );
  }

  Widget _buildShimmerPlaceholder() {
    return Stack(
      children: [
        Image.asset(
          'assets/images/icon_bg.webp',
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
        Shimmer.fromColors(
          baseColor: Colors.transparent,
          highlightColor: Colors.white.withValues(alpha: 0.4),
          period: const Duration(milliseconds: 1200),
          child: Container(
            color: Colors.white.withValues(alpha: 0.15),
          ),
        ),
      ],
    );
  }
}
