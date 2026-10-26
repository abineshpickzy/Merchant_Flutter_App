import 'package:intl/intl.dart';

abstract final class DateFormatter {
  static final DateFormat _dateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');
  static final DateFormat _dateFormat = DateFormat('dd MMM yyyy');
  static final DateFormat _timeFormat = DateFormat('hh:mm a');

  static String formatDateTime(DateTime dateTime) => _dateTimeFormat.format(dateTime.toLocal());
  static String formatDate(DateTime dateTime) => _dateFormat.format(dateTime.toLocal());
  static String formatTime(DateTime dateTime) => _timeFormat.format(dateTime.toLocal());

  static String formatIso(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      return formatDateTime(dt);
    } catch (_) {
      return isoString;
    }
  }
}
