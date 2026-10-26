import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Full-page shimmer skeleton that mirrors the [HomeBodyView] layout while
/// stores data is loading. A single top-level [Shimmer.fromColors] drives
/// the glare wave across every placeholder simultaneously.
class HomeSkeletonLoader extends StatelessWidget {
  const HomeSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      direction: ShimmerDirection.ltr,
      period: const Duration(milliseconds: 1200),
      child: SingleChildScrollView(
        // Non-scrollable — skeleton is purely decorative
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Section 1: Header gradient cards row ──────────────────────
            _buildHeaderCardsSkeleton(),

            const SizedBox(height: 10),

            // ── Section 2: Guaranteed Order / promo banner ────────────────
            _buildPromoBannerSkeleton(),

            const SizedBox(height: 6),

            // ── Section 3: "My Stores" grid (6 cards, 2 rows × 3 cols) ───
            _buildGridSectionSkeleton(cardCount: 6),

            const SizedBox(height: 12),

            // ── Section 4: "External Shops" grid (3 cards, 1 row × 3 cols)
            _buildGridSectionSkeleton(cardCount: 3),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Header: 3 equal card placeholders in a 125 px tall row ──────────────
  Widget _buildHeaderCardsSkeleton() {
    return SizedBox(
      height: 125,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _SkeletonBox(radius: 4)),
          const SizedBox(width: 8),
          Expanded(child: _SkeletonBox(radius: 4)),
          const SizedBox(width: 8),
          Expanded(child: _SkeletonBox(radius: 4)),
        ],
      ),
    );
  }

  // ── Promo banner: card-shaped horizontal placeholder ─────────────────────
  Widget _buildPromoBannerSkeleton() {
    return Container(
      height: 108,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Circular badge placeholder
          _SkeletonBox(width: 56, height: 56, radius: 28),
          const SizedBox(width: 12),
          // Text lines placeholder
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _SkeletonBox(height: 14, radius: 3),
                _SkeletonBox(height: 10, radius: 3),
                _SkeletonBox(height: 10, radius: 3),
                _SkeletonBox(height: 10, width: 120, radius: 3),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Grid section: label bar + NxM card skeleton grid ─────────────────────
  Widget _buildGridSectionSkeleton({required int cardCount}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title placeholder
        Padding(
          padding: const EdgeInsets.only(left: 4.0, top: 12.0, bottom: 8.0),
          child: _SkeletonBox(height: 18, width: 120, radius: 4),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.65,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
          ),
          itemCount: cardCount,
          itemBuilder: (_, __) => const _StoreCardSkeleton(),
        ),
      ],
    );
  }
}

/// Isolated shimmer skeleton specifically for the stores grid section
class StoresSectionSkeletonLoader extends StatelessWidget {
  final int cardCount;

  const StoresSectionSkeletonLoader({
    super.key,
    this.cardCount = 6,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      direction: ShimmerDirection.ltr,
      period: const Duration(milliseconds: 1200),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4.0, top: 12.0, bottom: 8.0),
            child: Container(
              width: 120,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.65,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
            ),
            itemCount: cardCount,
            itemBuilder: (_, __) => const _StoreCardSkeleton(),
          ),
        ],
      ),
    );
  }
}

// ── Skeleton card: mirrors StoreCard layout (square image + two text lines) ─
class _StoreCardSkeleton extends StatelessWidget {
  const _StoreCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Square image placeholder
          AspectRatio(
            aspectRatio: 1.0,
            child: _SkeletonBox(radius: 6),
          ),
          const SizedBox(height: 5),
          // Store name line 1
          _SkeletonBox(height: 10, radius: 3),
          const SizedBox(height: 4),
          // Store name line 2 (narrower)
          Center(child: _SkeletonBox(height: 10, width: 50, radius: 3)),
        ],
      ),
    );
  }
}

// ── Reusable solid white shimmer block ───────────────────────────────────────
class _SkeletonBox extends StatelessWidget {
  final double? width;
  final double? height;
  final double radius;

  const _SkeletonBox({this.width, this.height, this.radius = 3});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
