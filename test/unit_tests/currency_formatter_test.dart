import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_ledger/utils/currency_formatter.dart';

void main() {
  group('CurrencyFormatter - Money Parsing & Safety', () {
    test('parses integer rupee strings into paise accurately', () {
      expect(CurrencyFormatter.parseToPaise('100'), equals(10000));
      expect(CurrencyFormatter.parseToPaise('1'), equals(100));
      expect(CurrencyFormatter.parseToPaise('5000'), equals(500000));
    });

    test('parses decimal rupee strings into paise without float errors', () {
      expect(CurrencyFormatter.parseToPaise('12.50'), equals(1250));
      expect(CurrencyFormatter.parseToPaise('99.9'), equals(9990));
      expect(CurrencyFormatter.parseToPaise('0.05'), equals(5));
      expect(CurrencyFormatter.parseToPaise('100.01'), equals(10001));
    });

    test('ignores comma separators cleanly', () {
      expect(CurrencyFormatter.parseToPaise('1,250.50'), equals(125050));
      expect(CurrencyFormatter.parseToPaise('10,00,000'), equals(100000000));
    });

    test('rejects negative, zero, or non-numeric amounts for transactions', () {
      expect(CurrencyFormatter.parseToPaise('0'), isNull);
      expect(CurrencyFormatter.parseToPaise('0.00'), isNull);
      expect(CurrencyFormatter.parseToPaise('-50'), isNull);
      expect(CurrencyFormatter.parseToPaise('abc'), isNull);
      expect(CurrencyFormatter.parseToPaise(''), isNull);
      expect(CurrencyFormatter.parseToPaise('  '), isNull);
      expect(CurrencyFormatter.parseToPaise('12.345'),
          isNull); // More than 2 decimal digits
    });

    test('parseToPaiseAllowZero allows zero for opening balances', () {
      expect(CurrencyFormatter.parseToPaiseAllowZero('0'), equals(0));
      expect(CurrencyFormatter.parseToPaiseAllowZero('0.00'), equals(0));
      expect(CurrencyFormatter.parseToPaiseAllowZero('-10'), isNull);
      expect(CurrencyFormatter.parseToPaiseAllowZero('500'), equals(50000));
    });

    test('formats paise into Indian numbering grouping', () {
      expect(CurrencyFormatter.formatPaise(10000), equals('₹ 100'));
      expect(CurrencyFormatter.formatPaise(125000), equals('₹ 1,250'));
      expect(CurrencyFormatter.formatPaise(10000000), equals('₹ 1,00,000'));
      expect(
          CurrencyFormatter.formatPaise(1000000000), equals('₹ 1,00,00,000'));
    });

    test('formats negative amounts with leading minus sign', () {
      expect(CurrencyFormatter.formatPaise(-250000), equals('-₹ 2,500'));
    });

    test('converts paise to clean editable decimal strings', () {
      expect(CurrencyFormatter.paiseToEditableString(10000), equals('100'));
      expect(CurrencyFormatter.paiseToEditableString(1250), equals('12.50'));
      expect(CurrencyFormatter.paiseToEditableString(5), equals('0.05'));
    });
  });
}
