import 'package:equatable/equatable.dart';

enum PeriodType { today, sevenDays, thirtyDays, custom }

/// Data model representing active date filter selections (`today`, `sevenDays`, `thirtyDays`, or custom date range).
class DashboardDateFilter extends Equatable {
  final PeriodType type;
  final DateTime? customFrom;
  final DateTime? customTo;

  const DashboardDateFilter({
    this.type = PeriodType.today,
    this.customFrom,
    this.customTo,
  });

  Map<String, String> buildFilterDatePayload() {
    final now = DateTime.now();
    late DateTime fromDate;
    late DateTime toDate;

    switch (type) {
      case PeriodType.today:
        fromDate = DateTime(now.year, now.month, now.day, 0, 0, 0, 0);
        toDate = DateTime(now.year, now.month, now.day, 23, 59, 59, 0);
        break;
      case PeriodType.sevenDays:
        final start = now.subtract(const Duration(days: 7));
        fromDate = DateTime(start.year, start.month, start.day, 0, 0, 0, 0);
        toDate = DateTime(now.year, now.month, now.day, 23, 59, 59, 0);
        break;
      case PeriodType.thirtyDays:
        final start = now.subtract(const Duration(days: 30));
        fromDate = DateTime(start.year, start.month, start.day, 0, 0, 0, 0);
        toDate = DateTime(now.year, now.month, now.day, 23, 59, 59, 0);
        break;
      case PeriodType.custom:
        final f = customFrom ?? now;
        final t = customTo ?? now;
        fromDate = DateTime(f.year, f.month, f.day, 0, 0, 0, 0);
        toDate = DateTime(t.year, t.month, t.day, 23, 59, 59, 0);
        break;
    }

    String formatDate(DateTime dt) {
      final y = dt.year.toString().padLeft(4, '0');
      final m = dt.month.toString().padLeft(2, '0');
      final d = dt.day.toString().padLeft(2, '0');
      final hh = dt.hour.toString().padLeft(2, '0');
      final mm = dt.minute.toString().padLeft(2, '0');
      final ss = dt.second.toString().padLeft(2, '0');
      return '$y-$m-$d $hh:$mm:$ss.000';
    }

    return {
      'from': formatDate(fromDate),
      'to': formatDate(toDate),
    };
  }

  @override
  List<Object?> get props => [type, customFrom, customTo];
}
