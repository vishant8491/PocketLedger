import 'package:intl/intl.dart';

/// Helper methods for consistent local date handling, month boundaries, and UI formatting.
class DateHelper {
  DateHelper._();

  static final DateFormat _monthYearFormat = DateFormat('MMMM yyyy');
  static final DateFormat _shortMonthYearFormat = DateFormat('MMM yyyy');
  static final DateFormat _fullDateFormat = DateFormat('EEE, d MMM yyyy');
  static final DateFormat _dayMonthFormat = DateFormat('d MMM');
  static final DateFormat _isoFormat = DateFormat('yyyy-MM-dd');

  /// Returns the start boundary (00:00:00.000) for a given year and month in local time.
  static DateTime startOfMonth(int year, int month) {
    return DateTime(year, month, 1, 0, 0, 0, 0);
  }

  /// Returns the end boundary (23:59:59.999) for a given year and month in local time.
  static DateTime endOfMonth(int year, int month) {
    // Setting day to 0 of next month gives the last day of the current month.
    return DateTime(year, month + 1, 0, 23, 59, 59, 999);
  }

  /// Formats date for month selector header: e.g. "October 2026".
  static String formatMonthYear(DateTime date) {
    return _monthYearFormat.format(date);
  }

  /// Formats date for compact views: e.g. "Oct 2026".
  static String formatShortMonthYear(DateTime date) {
    return _shortMonthYearFormat.format(date);
  }

  /// Formats a full readable date: e.g. "Mon, 27 Oct 2026".
  static String formatFullDate(DateTime date) {
    return _fullDateFormat.format(date);
  }

  /// Formats day and month: e.g. "27 Oct".
  static String formatDayMonth(DateTime date) {
    return _dayMonthFormat.format(date);
  }

  /// Formats date to standard ISO format "yyyy-MM-dd".
  static String toIsoDate(DateTime date) {
    return _isoFormat.format(date);
  }

  /// Parses ISO format or fallback to DateTime.tryParse.
  static DateTime? parseIsoDate(String? isoString) {
    if (isoString == null || isoString.isEmpty) return null;
    return DateTime.tryParse(isoString);
  }

  /// Returns a user-friendly group header string:
  /// "Today - 27 Oct 2026", "Yesterday - 26 Oct 2026", or "25 Oct 2026".
  static String formatDateGroupHeader(DateTime date) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime target = DateTime(date.year, date.month, date.day);

    final int diffInDays = today.difference(target).inDays;

    if (diffInDays == 0) {
      return 'Today - ${_fullDateFormat.format(date)}';
    } else if (diffInDays == 1) {
      return 'Yesterday - ${_fullDateFormat.format(date)}';
    } else {
      return _fullDateFormat.format(date);
    }
  }

  /// Checks if two DateTimes fall on the exact same calendar day.
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
