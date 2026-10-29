import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_ledger/models/transaction.dart';
import 'package:pocket_ledger/services/export_service.dart';

void main() {
  group('ExportService - CSV Formatting & Formula Injection Prevention', () {
    test(
        'sanitizes strings starting with =, +, -, @ to prevent spreadsheet macro injection',
        () {
      expect(ExportService.sanitizeCsvField('=SUM(A1:A10)'),
          equals('"\'=SUM(A1:A10)"'));
      expect(ExportService.sanitizeCsvField('+12345'), equals('"\'+12345"'));
      expect(
          ExportService.sanitizeCsvField('-cmd|...'), equals('"\'-cmd|...\"'));
      expect(ExportService.sanitizeCsvField('@something'),
          equals('"\'@something"'));
    });

    test('escapes internal quotes and wraps regular text in quotes', () {
      expect(ExportService.sanitizeCsvField('Normal note'),
          equals('"Normal note"'));
      expect(ExportService.sanitizeCsvField('Item with "quotes" inside'),
          equals('"Item with ""quotes"" inside"'));
      expect(ExportService.sanitizeCsvField('Comma, separated, text'),
          equals('"Comma, separated, text"'));
      expect(ExportService.sanitizeCsvField(''), equals('""'));
    });

    test('generates valid RFC-4180 CSV with header row', () {
      final List<TransactionItem> items = <TransactionItem>[
        TransactionItem(
          id: '1',
          accountId: 'acc_1',
          accountName: 'Main Bank',
          categoryId: 'cat_1',
          categoryName: 'Salary',
          transactionType: TransactionType.income,
          amountPaise: 4500000, // ₹45,000
          transactionDate: DateTime(2026, 10, 1),
          note: 'October Salary',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final String csv = ExportService.generateTransactionsCsv(items);
      final List<String> lines = csv.trim().split('\n');

      expect(lines.length, equals(2));
      expect(lines[0].trim(),
          equals('Date,Type,Account,Category,Amount (INR),Note'));
      expect(lines[1].contains('2026-10-01'), isTrue);
      expect(lines[1].contains('Income'), isTrue);
      expect(lines[1].contains('45000'), isTrue);
      expect(lines[1].contains('October Salary'), isTrue);
    });
  });
}
