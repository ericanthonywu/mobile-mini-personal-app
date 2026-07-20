import 'package:intl/intl.dart';

/// Date/time formatter utilities.
/// All dates in the app are stored and displayed in WIB (UTC+7).
class DateFormatter {
  DateFormatter._();

  static final DateFormat _full = DateFormat('dd MMM yyyy, HH:mm', 'en_US');
  static final DateFormat _date = DateFormat('dd MMM yyyy', 'en_US');
  static final DateFormat _short = DateFormat('dd MMM', 'en_US');
  static final DateFormat _dayName = DateFormat('EEE', 'en_US');
  static final DateFormat _monthYear = DateFormat('MMMM yyyy', 'en_US');

  /// Full date + time: "15 Jul 2026, 20:28"
  static String full(DateTime dt) => _full.format(dt);

  /// Date only: "15 Jul 2026"
  static String date(DateTime dt) => _date.format(dt);

  /// Short date: "15 Jul"
  static String short(DateTime dt) => _short.format(dt);

  /// Day name abbreviation: "Mon", "Tue", etc.
  static String dayName(DateTime dt) => _dayName.format(dt);

  /// Month + year: "July 2026"
  static String monthYear(DateTime dt) => _monthYear.format(dt);

  /// "Today, HH:mm", "Yesterday, HH:mm", or full date+time
  static String relativeWithTime(DateTime dt) {
    final local = dt.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(local.year, local.month, local.day);
    final diff = today.difference(d).inDays;
    final timeStr = DateFormat('HH:mm').format(local);

    if (diff == 0) return 'Today, $timeStr';
    if (diff == 1) return 'Yesterday, $timeStr';
    return full(local);
  }

  /// "Today", "Yesterday", or formatted date
  static String relative(DateTime dt) {
    final local = dt.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(local.year, local.month, local.day);
    final diff = today.difference(d).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return date(local);
  }
}
