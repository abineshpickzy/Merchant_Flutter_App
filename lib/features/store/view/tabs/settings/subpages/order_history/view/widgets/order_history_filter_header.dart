import 'package:flutter/material.dart';
import 'package:bayfay_merchant_flutter/core/widgets/app_date_range_filter_header.dart';
import '../../model/order_history_model.dart';

/// Date Filter Header matching Android order_history_fragment filter layout
/// Powered by core [AppDateRangeFilterHeader] for project-wide consistency
class OrderHistoryFilterHeader extends StatelessWidget {
  final OrderHistoryFilterType activeFilter;
  final DateTime fromDate;
  final DateTime toDate;
  final ValueChanged<OrderHistoryFilterType> onFilterSelected;
  final void Function(DateTime from, DateTime to) onCustomRangeApplied;

  const OrderHistoryFilterHeader({
    super.key,
    required this.activeFilter,
    required this.fromDate,
    required this.toDate,
    required this.onFilterSelected,
    required this.onCustomRangeApplied,
  });

  DateRangeFilterType _mapToCoreType(OrderHistoryFilterType filter) {
    switch (filter) {
      case OrderHistoryFilterType.today:
        return DateRangeFilterType.today;
      case OrderHistoryFilterType.sevenDays:
        return DateRangeFilterType.sevenDays;
      case OrderHistoryFilterType.thirtyDays:
        return DateRangeFilterType.thirtyDays;
      case OrderHistoryFilterType.custom:
        return DateRangeFilterType.custom;
    }
  }

  OrderHistoryFilterType _mapFromCoreType(DateRangeFilterType filter) {
    switch (filter) {
      case DateRangeFilterType.today:
        return OrderHistoryFilterType.today;
      case DateRangeFilterType.sevenDays:
        return OrderHistoryFilterType.sevenDays;
      case DateRangeFilterType.thirtyDays:
        return OrderHistoryFilterType.thirtyDays;
      case DateRangeFilterType.custom:
        return OrderHistoryFilterType.custom;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppDateRangeFilterHeader(
      activeFilter: _mapToCoreType(activeFilter),
      fromDate: fromDate,
      toDate: toDate,
      onFilterSelected: (coreFilter) =>
          onFilterSelected(_mapFromCoreType(coreFilter)),
      onCustomRangeSelected: onCustomRangeApplied,
    );
  }
}
