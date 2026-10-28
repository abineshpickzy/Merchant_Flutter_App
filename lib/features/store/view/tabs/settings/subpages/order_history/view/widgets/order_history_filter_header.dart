import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../model/order_history_model.dart';

/// Date Filter Header matching Android order_history_fragment filter layout
class OrderHistoryFilterHeader extends StatefulWidget {
  final OrderHistoryFilterType activeFilter;
  final DateTime fromDate;
  final DateTime toDate;
  final ValueChanged<OrderHistoryFilterType> onFilterSelected;
  final Function(DateTime from, DateTime to) onCustomRangeApplied;

  const OrderHistoryFilterHeader({
    super.key,
    required this.activeFilter,
    required this.fromDate,
    required this.toDate,
    required this.onFilterSelected,
    required this.onCustomRangeApplied,
  });

  @override
  State<OrderHistoryFilterHeader> createState() => _OrderHistoryFilterHeaderState();
}

class _OrderHistoryFilterHeaderState extends State<OrderHistoryFilterHeader> {
  late DateTime _selectedFrom;
  late DateTime _selectedTo;
  final DateFormat _displayFormat = DateFormat('dd-MM-yyyy');

  @override
  void initState() {
    super.initState();
    _selectedFrom = widget.fromDate;
    _selectedTo = widget.toDate;
  }

  @override
  void didUpdateWidget(OrderHistoryFilterHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fromDate != widget.fromDate || oldWidget.toDate != widget.toDate) {
      _selectedFrom = widget.fromDate;
      _selectedTo = widget.toDate;
    }
  }

  Future<void> _pickDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? _selectedFrom : _selectedTo,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2196F3),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isFrom) {
          _selectedFrom = picked;
          if (_selectedFrom.isAfter(_selectedTo)) {
            _selectedTo = _selectedFrom;
          }
        } else {
          _selectedTo = picked;
          if (_selectedTo.isBefore(_selectedFrom)) {
            _selectedFrom = _selectedTo;
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Column(
        children: [
          // Row 1: 3 Segmented Quick Filter Tabs
          Row(
            children: [
              _buildSegmentTab(
                label: 'Today',
                filter: OrderHistoryFilterType.today,
              ),
              const SizedBox(width: 6),
              _buildSegmentTab(
                label: 'Last 7 Days',
                filter: OrderHistoryFilterType.sevenDays,
              ),
              const SizedBox(width: 6),
              _buildSegmentTab(
                label: 'Last 30 Days',
                filter: OrderHistoryFilterType.thirtyDays,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Row 2: Custom Date Pickers ("From", "To", "Go")
          Row(
            children: [
              // From Date Chip
              Expanded(
                flex: 5,
                child: InkWell(
                  onTap: () => _pickDate(true),
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFCCCCCC), width: 0.8),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _displayFormat.format(_selectedFrom),
                          style: const TextStyle(fontSize: 11, color: Colors.black87),
                        ),
                        const Icon(Icons.calendar_today, size: 14, color: Color(0xFF757575)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // To Date Chip
              Expanded(
                flex: 5,
                child: InkWell(
                  onTap: () => _pickDate(false),
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFCCCCCC), width: 0.8),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _displayFormat.format(_selectedTo),
                          style: const TextStyle(fontSize: 11, color: Colors.black87),
                        ),
                        const Icon(Icons.calendar_today, size: 14, color: Color(0xFF757575)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // "Go" Button
              SizedBox(
                height: 36,
                width: 48,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onCustomRangeApplied(_selectedFrom, _selectedTo);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                  ),
                  child: const Text(
                    'Go',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentTab({
    required String label,
    required OrderHistoryFilterType filter,
  }) {
    final isSelected = widget.activeFilter == filter;

    return Expanded(
      child: SizedBox(
        height: 34,
        child: OutlinedButton(
          onPressed: () => widget.onFilterSelected(filter),
          style: OutlinedButton.styleFrom(
            backgroundColor: isSelected ? const Color(0xFF2196F3) : Colors.transparent,
            foregroundColor: isSelected ? Colors.white : const Color(0xFF2196F3),
            side: const BorderSide(color: Color(0xFF2196F3), width: 1.0),
            padding: const EdgeInsets.symmetric(horizontal: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
