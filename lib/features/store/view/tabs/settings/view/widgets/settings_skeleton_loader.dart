import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Shimmer skeleton loader for Settings Tab
class SettingsSkeletonLoader extends StatelessWidget {
  const SettingsSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // Top 2 menu rows
        _buildShimmerMenuRow(),
        _buildShimmerMenuRow(),
        // Section Header bar placeholder
        Container(
          height: 32,
          width: double.infinity,
          color: Colors.grey.shade200,
        ),
        // Branded card placeholder
        Container(
          height: 120,
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 14, width: 140, color: Colors.white),
                      const SizedBox(height: 8),
                      Container(height: 12, width: 90, color: Colors.white),
                      const SizedBox(height: 8),
                      Container(height: 12, width: 70, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFEEEEEE)),
        // Remaining 5 menu rows
        _buildShimmerMenuRow(),
        _buildShimmerMenuRow(),
        _buildShimmerMenuRow(),
        _buildShimmerMenuRow(),
        _buildShimmerMenuRow(),
      ],
    );
  }

  Widget _buildShimmerMenuRow() {
    return Column(
      children: [
        Container(
          height: 42,
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: Container(
                  height: 12,
                  width: 130,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.chevron_right,
                size: 20,
                color: Color(0xFFE0E0E0),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFEEEEEE)),
      ],
    );
  }
}
