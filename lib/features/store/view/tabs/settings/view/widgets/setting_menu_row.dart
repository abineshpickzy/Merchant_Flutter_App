import 'package:flutter/material.dart';

/// 40dp navigation row matching Android shop_setting_fragment items
class SettingMenuRow extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final bool showDivider;

  const SettingMenuRow({
    super.key,
    required this.title,
    required this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.white,
          child: InkWell(
            onTap: onTap,
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black,
                        fontWeight: FontWeight.normal,
                      ),
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
        if (showDivider)
          const Divider(
            height: 1,
            thickness: 1,
            color: Color(0xFFEEEEEE),
          ),
      ],
    );
  }
}
