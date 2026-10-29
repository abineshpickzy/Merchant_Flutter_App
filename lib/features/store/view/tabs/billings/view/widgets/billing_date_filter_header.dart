import 'package:flutter/material.dart';
import 'package:bayfay_merchant_flutter/core/widgets/app_date_range_filter_header.dart';
import '../../model/billing_model.dart';

/// Date range filter header matching Android fragment_store_billing.xml (balancer_header_txt)
/// Powered by core [AppDateRangeFilterHeader] for project-wide consistency
class BillingDateFilterHeader extends StatelessWidget {
  final BillingFilterType activeFilter;
  final DateTime fromDate;
  final DateTime toDate;
  final ValueChanged<BillingFilterType> onFilterSelected;
  final void Function(DateTime from, DateTime to) onCustomRangeSelected;

  const BillingDateFilterHeader({
    super.key,
    required this.activeFilter,
    required this.fromDate,
    required this.toDate,
    required this.onFilterSelected,
    required this.onCustomRangeSelected,
  });

  DateRangeFilterType _mapToCoreType(BillingFilterType filter) {
    switch (filter) {
      case BillingFilterType.today:
        return DateRangeFilterType.today;
      case BillingFilterType.sevenDays:
        return DateRangeFilterType.sevenDays;
      case BillingFilterType.thirtyDays:
        return DateRangeFilterType.thirtyDays;
      case BillingFilterType.custom:
        return DateRangeFilterType.custom;
    }
  }

  BillingFilterType _mapFromCoreType(DateRangeFilterType filter) {
    switch (filter) {
      case DateRangeFilterType.today:
        return BillingFilterType.today;
      case DateRangeFilterType.sevenDays:
        return BillingFilterType.sevenDays;
      case DateRangeFilterType.thirtyDays:
        return BillingFilterType.thirtyDays;
      case DateRangeFilterType.custom:
        return BillingFilterType.custom;
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
      onCustomRangeSelected: onCustomRangeSelected,
    );
  }
}
