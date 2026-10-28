import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../model/billing_model.dart';

/// Date range filter header matching Android fragment_store_billing.xml (balancer_header_txt)
class BillingDateFilterHeader extends StatefulWidget {
  final BillingFilterType activeFilter;
  final DateTime fromDate;
  final DateTime toDate;
  final ValueChanged<BillingFilterType> onFilterSelected;
  final Function(DateTime from, DateTime to) onCustomRangeSelected;

  const BillingDateFilterHeader({
    super.key,
    required this.activeFilter,
    required this.fromDate,
    required this.toDate,
    required this.onFilterSelected,
    required this.onCustomRangeSelected,
  });

  @override
  State<BillingDateFilterHeader> createState() => _BillingDateFilterHeaderState();
}

class _BillingDateFilterHeaderState extends State<BillingDateFilterHeader> {
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
  void didUpdateWidget(covariant BillingDateFilterHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fromDate != widget.fromDate || oldWidget.toDate != widget.toDate) {
      _selectedFrom = widget.fromDate;
      _selectedTo = widget.toDate;
    }
  }

  Future<void> _pickDate(bool isFrom) async {
    final initialDate = isFrom ? _selectedFrom : _selectedTo;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isFrom) {
          _selectedFrom = picked;
        } else {
          _selectedTo = picked;
        }
      });
    }
  }

  void _onGoPressed() {
    if (_selectedFrom.isAfter(_selectedTo)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select valid From and To date'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    widget.onCustomRangeSelected(_selectedFrom, _selectedTo);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(5),
      padding: const EdgeInsets.all(5),
      color: const Color(0xFFE0E0E0), // Android balancer_header_txt bg
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: Segmented tab row (35dp height, matching Android linear & order_history_bg)
          Container(
            height: 35,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: const Color(0xFFC5C5C5), width: 1),
            ),
            child: Row(
              children: [
                _buildSegmentButton(
                  title: 'Today',
                  filterType: BillingFilterType.today,
                ),
                const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFC5C5C5)),
                _buildSegmentButton(
                  title: 'Last 7 Days',
                  filterType: BillingFilterType.sevenDays,
                ),
                const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFC5C5C5)),
                _buildSegmentButton(
                  title: 'Last 30 Days',
                  filterType: BillingFilterType.thirtyDays,
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),

          // Row 2: Custom Date Range Picker Row matching Android fromDate_tv & toDate_tv & btn_go
          Row(
            children: [
              // From Date Field
              Expanded(
                child: InkWell(
                  onTap: () => _pickDate(true),
                  child: Container(
                    height: 30,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFF9E9E9E), width: 0.5),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          'From: ',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            _displayFormat.format(_selectedFrom),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.calendar_month,
                          size: 14,
                          color: Color(0xFF616161),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // To Date Field
              Expanded(
                child: InkWell(
                  onTap: () => _pickDate(false),
                  child: Container(
                    height: 30,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFF9E9E9E), width: 0.5),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          'To: ',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            _displayFormat.format(_selectedTo),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.calendar_month,
                          size: 14,
                          color: Color(0xFF616161),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // Go Button matching Android btn_go
              InkWell(
                onTap: _onGoPressed,
                child: Container(
                  height: 30,
                  width: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFF9E9E9E), width: 1),
                  ),
                  child: const Text(
                    'Go',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton({
    required String title,
    required BillingFilterType filterType,
  }) {
    final isSelected = widget.activeFilter == filterType;
    return Expanded(
      child: InkWell(
        onTap: () => widget.onFilterSelected(filterType),
        child: Container(
          alignment: Alignment.center,
          color: isSelected ? const Color(0xFF2196F3) : Colors.transparent,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF2196F3),
            ),
          ),
        ),
      ),
    );
  }
}
