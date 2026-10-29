import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:bayfay_merchant_flutter/features/dashboard/model/store_model.dart';
import 'package:bayfay_merchant_flutter/features/store/controller/store_controller.dart';
import 'package:bayfay_merchant_flutter/features/store/model/dashboard_date_filter.dart';
import 'package:bayfay_merchant_flutter/features/store/model/store_dashboard_metrics_model.dart';
import 'package:bayfay_merchant_flutter/features/store/view/widgets/store_tab_app_bar.dart';

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

    if (!mounted) return;

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

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: StoreTabAppBar(
        title: widget.store.displayName,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(storeDashboardMetricsProvider(widget.store.id));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildDateFilterHeader(activeFilter),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: metricsAsync.when(
                  data: (metrics) => _buildPastelMetricsGrid(metrics),
                  loading: () => _buildShimmerLoadingGrid(),
                  error: (err, _) => _buildPastelMetricsGrid(
                    StoreDashboardMetricsModel.sampleForFilter(activeFilter),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
static const Color _blue = Color(0xFF2196F3);

Widget _buildDateFilterHeader(DashboardDateFilter activeFilter) {
  return Container(
    color: const Color(0xFFE0E0E0),
    padding: const EdgeInsets.all(10),
    child: Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _blue, width: 1.5),
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
        Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    _dateBox(_selectedFromDate, true),
    Container(
      width: 10,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: Colors.black,
    ),
    _dateBox(_selectedToDate, false),
    const SizedBox(width: 8),
    InkWell(
              onTap: _onGoPressed,
              child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFBDBDBD)),
                ),
                child: const Text(
                  'Go',
                  style: TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _dateBox(DateTime date, bool isFrom) {
  return InkWell(
    onTap: () => _selectDate(context, isFrom),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFBDBDBD)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Text(
              DateFormat('dd-MM-yyyy').format(date),
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ),
          Container(width: 1, height: 28, color: const Color(0xFFBDBDBD)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 5),
            child: Icon(Icons.calendar_month_outlined, size: 16, color: Colors.black54),
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
        ref.read(storeDashboardDateFilterProvider.notifier).state =
            DashboardDateFilter(type: type);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        color: isSelected ? _blue : Colors.white,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            
            fontSize: 14,
            color: isSelected ? Colors.white : _blue,
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

 Widget _buildPastelMetricsGrid(StoreDashboardMetricsModel m) {
  return LayoutBuilder(
    builder: (context, c) {
      final w = (c.maxWidth - 40) / 3;

      Widget card(String label, String value, int color) => _PastelMetricCard(
            width: w,
            label: label,
            value: value,
            backgroundColor: Color(color),
          );

      Widget row(List<Widget> cards) => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(width: 20),
                cards[i],
              ],
            ],
          );

      const gap = SizedBox(height: 20);
      const divider = Padding(
        padding: EdgeInsets.symmetric(vertical: 14),
        child: Divider(height: 1, color: Color(0xFFE0E0E0)),
      );
      final fd = m.financialBreakdown;
      final ro = m.refundOverview;

      return Column(
        children: [
          row([
            card('Users Visited', _safeNum(m.usersVisited), 0xFFFAB3AD),
            card('Users till cart', _safeNum(m.usersInCart), 0xFFF6A3C2),
            card('Number of orders', _safeNum(m.noOfOrders), 0xFFFFF59D),
          ]),
          gap,
          row([
            card('Order cancelled', _safeNum(ro.totalCancelledCount), 0xFFE1F5FE),
            card('Total Refund', _safeNum(ro.totalRefundedCount), 0xFF9BE3EC),
            card('Product Replaced', _safeNum(m.noOfReplacedProducts), 0xFFC5E1A5),
          ]),
          divider,
          row([
            card('COD Amount', _safeNum(fd.codPayment, isCurrency: true), 0xFFF5DEB8),
            card('Online Amount', _safeNum(fd.onlinePayment, isCurrency: true), 0xFFF8BBD9),
            card('Total Amount', _safeNum(fd.totalAmount, isCurrency: true), 0xFFCDE9F9),
          ]),
          gap,
          row([
            card('External Delivery Fee', _safeNum(fd.agencyDeliveryFee, isCurrency: true), 0xFFFFF59D),
            card('Payable to Merchant', _safeNum(fd.merchantPayable, isCurrency: true), 0xFFFAE8D2),
            card('Packaging Fee', _safeNum(fd.packagingFee, isCurrency: true), 0xFF9BE3EC),
          ]),
          divider,
          row([
            card('Cancelled Amount', _safeNum(ro.totalCancelledAmount, isCurrency: true), 0xFFCDEFF8),
            card('Refund Amount', _safeNum(ro.totalRefundedAmount, isCurrency: true), 0xFFE1D5D6),
          ]),
          gap,
          row([
            card('Escalated Orders', _safeNum(ro.totalEscalatedCount), 0xFFFAB3AD),
            card('Escalated Amount', _safeNum(ro.totalEscalatedAmount, isCurrency: true), 0xFFF8A5C2),
          ]),
        ],
      );
    },
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
                        height: 52,
                        decoration: BoxDecoration(
                          
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
                    if (c < (r < 4 ? 2 : 1)) const SizedBox(width: 20),
                  ],
                ],
              ),
             const SizedBox(height: 20),
            ],
          ],
        );
      },
    );
  }
}

class _PastelMetricCard extends StatelessWidget {
  final double width;
  final String label;
  final String value;
  final Color backgroundColor;

  const _PastelMetricCard({
    required this.width,
    required this.label,
    required this.value,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 52,
      color: backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: const TextStyle(

                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}