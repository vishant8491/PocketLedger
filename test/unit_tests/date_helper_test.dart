import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_ledger/utils/date_helper.dart';

void main() {
  group('DateHelper - Boundaries and Date Formatting', () {
    test('startOfMonth returns the first millisecond of the month', () {
      final DateTime start = DateHelper.startOfMonth(2026, 10);
      expect(start.year, equals(2026));
      expect(start.month, equals(10));
      expect(start.day, equals(1));
      expect(start.hour, equals(0));
      expect(start.minute, equals(0));
      expect(start.second, equals(0));
      expect(start.millisecond, equals(0));
    });

    test('endOfMonth returns 23:59:59.999 of the last day of the month', () {
      // October has 31 days
      final DateTime endOct = DateHelper.endOfMonth(2026, 10);
      expect(endOct.year, equals(2026));
      expect(endOct.month, equals(10));
      expect(endOct.day, equals(31));
      expect(endOct.hour, equals(23));
      expect(endOct.minute, equals(59));
      expect(endOct.second, equals(59));

      // February in non-leap year (2025 has 28 days)
      final DateTime endFeb2025 = DateHelper.endOfMonth(2025, 2);
      expect(endFeb2025.day, equals(28));

      // February in leap year (2024 has 29 days)
      final DateTime endFeb2024 = DateHelper.endOfMonth(2024, 2);
      expect(endFeb2024.day, equals(29));
    });

    test('toIsoDate formats into yyyy-MM-dd', () {
      final DateTime date = DateTime(2026, 10, 27, 14, 30);
      expect(DateHelper.toIsoDate(date), equals('2026-10-27'));
    });

    test('isSameDay accurately identifies identical calendar days', () {
      final DateTime d1 = DateTime(2026, 10, 27, 9, 0);
      final DateTime d2 = DateTime(2026, 10, 27, 23, 45);
      final DateTime d3 = DateTime(2026, 10, 28, 0, 1);

      expect(DateHelper.isSameDay(d1, d2), isTrue);
      expect(DateHelper.isSameDay(d1, d3), isFalse);
    });
  });
}
