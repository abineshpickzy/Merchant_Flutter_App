import 'package:flutter/material.dart';

/// Section Header matching Android setting_bg_color bar
class SettingSectionHeader extends StatelessWidget {
  final String title;

  const SettingSectionHeader({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFEEEEEE),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }
}
