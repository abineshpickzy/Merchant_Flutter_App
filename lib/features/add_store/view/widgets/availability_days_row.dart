import 'package:flutter/material.dart';
import '../../../../core/constants/app_strings.dart';

/// Row of selectable day chips (Monday - Sunday).
class AvailabilityDaysRow extends StatelessWidget {
  final List<String> selectedDays;
  final ValueChanged<List<String>> onDaysChanged;

  static const List<String> allDays = [
    'Sun',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
  ];

  static const Map<String, String> shortLabels = {
    'Sunday': 'Sun',
    'Monday': 'Mon',
    'Tuesday': 'Tue',
    'Wednesday': 'Wed',
    'Thursday': 'Thu',
    'Friday': 'Fri',
    'Saturday': 'Sat',
    'Sun': 'Sun',
    'Mon': 'Mon',
    'Tue': 'Tue',
    'Wed': 'Wed',
    'Thu': 'Thu',
    'Fri': 'Fri',
    'Sat': 'Sat',
  };

  const AvailabilityDaysRow({
    super.key,
    required this.selectedDays,
    required this.onDaysChanged,
  });

  void _toggleDay(String day) {
    final shortDay = shortLabels[day] ?? day;
    final updated = selectedDays.map((d) => shortLabels[d] ?? d).toList();
    if (updated.contains(shortDay)) {
      if (updated.length > 1) {
        updated.remove(shortDay);
      }
    } else {
      updated.add(shortDay);
    }
    onDaysChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              AppStrings.storeWorkingDaysTitle,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF212121),
              ),
            ),
            Text(
              '${selectedDays.length} days selected',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: allDays.map((day) {
            final isSelected = selectedDays.any(
                (d) => d == day || (shortLabels[d] ?? d) == day);
            return FilterChip(
              label: Text(day),
              selected: isSelected,
              showCheckmark: false,
              selectedColor: const Color(0xFF1976D2),
              backgroundColor: const Color(0xFFF0F2F5),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF424242),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFF1976D2)
                      : const Color(0xFFE0E0E0),
                ),
              ),
              onSelected: (_) => _toggleDay(day),
            );
          }).toList(),
        ),
      ],
    );
  }
}
