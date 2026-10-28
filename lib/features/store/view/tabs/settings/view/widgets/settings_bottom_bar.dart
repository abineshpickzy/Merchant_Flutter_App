import 'package:flutter/material.dart';

/// Fixed Bottom Bar matching Android layout_shop_open_close
class SettingsBottomBar extends StatelessWidget {
  final bool isOpen;
  final bool isBusy;
  final bool isEnabled;
  final ValueChanged<bool> onToggleOpen;
  final ValueChanged<bool> onToggleBusy;

  const SettingsBottomBar({
    super.key,
    required this.isOpen,
    required this.isBusy,
    this.isEnabled = true,
    required this.onToggleOpen,
    required this.onToggleBusy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            offset: const Offset(0, -2),
            blurRadius: 4,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          // Left: Busy Switch (Android SwitchThemeShopBusy: red active color)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Busy',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 4),
              Switch(
                value: isBusy,
                activeColor: const Color(0xFFD32F2F), // Red
                onChanged: isEnabled ? onToggleBusy : null,
              ),
            ],
          ),
          const Spacer(),
          // Right: Shop Close / Open Switch (Android SwitchTheme: #148E13 green active color)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Shop Close',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: !isOpen ? const Color(0xFFD32F2F) : Colors.black87,
                ),
              ),
              const SizedBox(width: 4),
              Switch(
                value: isOpen,
                activeColor: const Color(0xFF148E13), // #148E13 Android Green
                onChanged: isEnabled ? onToggleOpen : null,
              ),
              const SizedBox(width: 4),
              Text(
                'Open',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isOpen ? const Color(0xFF148E13) : Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
