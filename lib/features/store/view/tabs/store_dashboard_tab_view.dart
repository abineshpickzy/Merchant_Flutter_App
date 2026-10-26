import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:bayfay_merchant_flutter/app/theme/app_colors.dart';
import '../../../dashboard/model/store_model.dart';
import '../../controller/store_controller.dart';
import '../../model/dashboard_date_filter.dart';
import '../../model/store_dashboard_metrics_model.dart';

/// Legacy Native Parity Store Dashboard Overview Tab
///
/// Strictly displays:
/// - 3-Tab Period Filter Bar (`Today`, `7 Days`, `30 Days`)
/// - Custom Date Picker Row (`From Date`, `To Date`, `"Go"` button)
/// - Shimmer Loading Skeleton while fetching metrics
/// - Exactly 16 soft pastel metric cards in native grid arrangement
class StoreDashboardTabView extends ConsumerStatefulWidget {
  final StoreModel store;

  const StoreDashboardTabView({super.key, required this.store});

  @override
  ConsumerState<StoreDashboardTabView> createState() => _StoreDashboardTabViewState();
}

class _StoreDashboardTabViewState extends ConsumerState<StoreDashboardTabView>
    with SingleTickerProviderStateMixin {
  late DateTime _selectedFromDate;
  late DateTime _selectedToDate;
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedFromDate = DateTime(now.year, now.month, now.day);
    _selectedToDate = DateTime(now.year, now.month, now.day);

    _shimmerController = AnimationController.unbounded(vsync: this)
      ..repeat(min: -0.5, max: 1.5, period: const Duration(milliseconds: 1000));
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isFrom) async {
    final now = DateTime.now();
    final initialDate = isFrom ? _selectedFromDate : _selectedToDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: now,
    );

    if (picked != null) {
      setState(() {
        if (isFrom) {
          _selectedFromDate = picked;
        } else {
          _selectedToDate = picked;
        }
      });
    }
  }

  void _onGoPressed() {
    ref.read(storeDashboardDateFilterProvider.notifier).state = DashboardDateFilter(
      type: PeriodType.custom,
      customFrom: _selectedFromDate,
      customTo: _selectedToDate,
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeFilter = ref.watch(storeDashboardDateFilterProvider);
    final metricsAsync = ref.watch(storeDashboardMetricsProvider(widget.store.id));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(storeDashboardMetricsProvider(widget.store.id));
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Period Selector & Custom Date Picker Row
            _buildDateFilterHeader(activeFilter),
            const SizedBox(height: 12),

            // 2. Metrics Grid or Shimmer Loading State
            metricsAsync.when(
              data: (metrics) => _buildPastelMetricsGrid(metrics),
              loading: () => _buildShimmerLoadingGrid(),
              error: (err, _) => _buildPastelMetricsGrid(
                StoreDashboardMetricsModel.sampleForFilter(activeFilter),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateFilterHeader(DashboardDateFilter activeFilter) {
    final dateFormat = DateFormat('dd-MM-yyyy');

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            // Period Filter Tabs (Today | 7 Days | 30 Days)
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFEEEEEE),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  _buildPeriodTab('Today', PeriodType.today, activeFilter.type),
                  _buildPeriodTab('7 Days', PeriodType.sevenDays, activeFilter.type),
                  _buildPeriodTab('30 Days', PeriodType.thirtyDays, activeFilter.type),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Custom Date Range Row ([ From Date ] [ To Date ] [ Go ])
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, true),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFCCCCCC)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              dateFormat.format(_selectedFromDate),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, false),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFCCCCCC)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              dateFormat.format(_selectedToDate),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 60,
                  height: 36,
                  child: ElevatedButton(
                    onPressed: _onGoPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(60, 36),
                      maximumSize: const Size(60, 36),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Go',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodTab(String label, PeriodType type, PeriodType activeType) {
    final isSelected = activeType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          ref.read(storeDashboardDateFilterProvider.notifier).state = DashboardDateFilter(type: type);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  String _safeNum(num? value, {bool isCurrency = false}) {
    if (value == null) return isCurrency ? '₹ 0' : '0';
    if (isCurrency) {
      final formatted = value is int || value == value.roundToDouble()
          ? value.toInt().toString()
          : value.toStringAsFixed(2);
      return '₹ $formatted';
    }
    return value is double && value == value.roundToDouble()
        ? value.toInt().toString()
        : '$value';
  }

  Widget _buildPastelMetricsGrid(StoreDashboardMetricsModel metrics) {
    return Column(
      children: [
        // Row 1 (3 Columns)
        Row(
          children: [
            Expanded(
              child: _PastelMetricCard(
                label: 'Users Visited',
                value: _safeNum(metrics.usersVisited),
                backgroundColor: const Color(0xFFFFEBEE),
                borderColor: const Color(0xFFFFCDD2),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _PastelMetricCard(
                label: 'Users till cart',
                value: _safeNum(metrics.usersInCart),
                backgroundColor: const Color(0xFFFCE4EC),
                borderColor: const Color(0xFFF8BBD0),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _PastelMetricCard(
                label: 'Number of orders',
                value: _safeNum(metrics.noOfOrders),
                backgroundColor: const Color(0xFFFFF8E1),
                borderColor: const Color(0xFFFFECB3),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Row 2 (3 Columns)
        Row(
          children: [
            Expanded(
              child: _PastelMetricCard(
                label: 'Order cancelled',
                value: _safeNum(metrics.refundOverview.totalCancelledCount),
                backgroundColor: const Color(0xFFF5F5F5),
                borderColor: const Color(0xFFE0E0E0),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _PastelMetricCard(
                label: 'Total Refund',
                value: _safeNum(metrics.refundOverview.totalRefundedCount),
                backgroundColor: const Color(0xFFE0F7FA),
                borderColor: const Color(0xFFB2EBF2),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _PastelMetricCard(
                label: 'Product Replaced',
                value: _safeNum(metrics.noOfReplacedProducts),
                backgroundColor: const Color(0xFFE8F5E9),
                borderColor: const Color(0xFFC8E6C9),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Row 3 (3 Columns)
        Row(
          children: [
            Expanded(
              child: _PastelMetricCard(
                label: 'COD Amount',
                value: _safeNum(metrics.financialBreakdown.codPayment, isCurrency: true),
                backgroundColor: const Color(0xFFFFF8E1),
                borderColor: const Color(0xFFFFECB3),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _PastelMetricCard(
                label: 'Online Amount',
                value: _safeNum(metrics.financialBreakdown.onlinePayment, isCurrency: true),
                backgroundColor: const Color(0xFFFCE4EC),
                borderColor: const Color(0xFFF8BBD0),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _PastelMetricCard(
                label: 'Total Amount',
                value: _safeNum(metrics.financialBreakdown.totalAmount, isCurrency: true),
                backgroundColor: const Color(0xFFE3F2FD),
                borderColor: const Color(0xFFBBDEFB),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Row 4 (3 Columns)
        Row(
          children: [
            Expanded(
              child: _PastelMetricCard(
                label: 'External Delivery Fee',
                value: _safeNum(metrics.financialBreakdown.agencyDeliveryFee, isCurrency: true),
                backgroundColor: const Color(0xFFFFFDE7),
                borderColor: const Color(0xFFFFF59D),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _PastelMetricCard(
                label: 'Payable to Merchant',
                value: _safeNum(metrics.financialBreakdown.merchantPayable, isCurrency: true),
                backgroundColor: const Color(0xFFEFEBE9),
                borderColor: const Color(0xFFD7CCC8),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _PastelMetricCard(
                label: 'Packaging Fee',
                value: _safeNum(metrics.financialBreakdown.packagingFee, isCurrency: true),
                backgroundColor: const Color(0xFFE0F7FA),
                borderColor: const Color(0xFFB2EBF2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Row 5 (2 Columns)
        Row(
          children: [
            Expanded(
              child: _PastelMetricCard(
                label: 'Cancelled Amount',
                value: _safeNum(metrics.refundOverview.totalCancelledAmount, isCurrency: true),
                backgroundColor: const Color(0xFFE3F2FD),
                borderColor: const Color(0xFFBBDEFB),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _PastelMetricCard(
                label: 'Refund Amount',
                value: _safeNum(metrics.refundOverview.totalRefundedAmount, isCurrency: true),
                backgroundColor: const Color(0xFFF3E5F5),
                borderColor: const Color(0xFFE1BEE7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Row 6 (2 Columns)
        Row(
          children: [
            Expanded(
              child: _PastelMetricCard(
                label: 'Escalated Orders',
                value: _safeNum(metrics.refundOverview.totalEscalatedCount),
                backgroundColor: const Color(0xFFFBE9E7),
                borderColor: const Color(0xFFFFCCBC),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _PastelMetricCard(
                label: 'Escalated Amount',
                value: _safeNum(metrics.refundOverview.totalEscalatedAmount, isCurrency: true),
                backgroundColor: const Color(0xFFF3E5F5),
                borderColor: const Color(0xFFE1BEE7),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildShimmerLoadingGrid() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        final shimmerValue = _shimmerController.value;
        final stop1 = (shimmerValue - 0.3).clamp(0.0, 0.98);
        final stop2 = (shimmerValue).clamp(stop1 + 0.01, 0.99);
        final stop3 = (shimmerValue + 0.3).clamp(stop2 + 0.01, 1.0);

        return Column(
          children: [
            for (int r = 0; r < 6; r++) ...[
              Row(
                children: [
                  for (int c = 0; c < (r < 4 ? 3 : 2); c++) ...[
                    Expanded(
                      child: Container(
                        height: 70,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: const [
                              Color(0xFFE8E8E8),
                              Color(0xFFF5F5F5),
                              Color(0xFFE8E8E8),
                            ],
                            stops: [stop1, stop2, stop3],
                          ),
                        ),
                      ),
                    ),
                    if (c < (r < 4 ? 2 : 1)) const SizedBox(width: 8),
                  ],
                ],
              ),
              const SizedBox(height: 8),
            ],
          ],
        );
      },
    );
  }
}

class _PastelMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final Color backgroundColor;
  final Color borderColor;

  const _PastelMetricCard({
    required this.label,
    required this.value,
    required this.backgroundColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF424242),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
