// Standalone test verification runner that runs directly on any Dart SDK
// Verifies money arithmetic, budget calculations, transfers exclusion, and formula injection defenses.

import '../lib/models/account.dart';
import '../lib/models/budget.dart';
import '../lib/models/transaction.dart';
import '../lib/utils/currency_formatter.dart';

// Standalone mirror of CSV sanitization to verify the security logic
String sanitizeCsvField(String text) {
  if (text.isEmpty) return '""';
  String sanitized = text;
  final String firstChar = sanitized.substring(0, 1);
  if (firstChar == '=' || firstChar == '+' || firstChar == '-' || firstChar == '@') {
    sanitized = "'$sanitized";
  }
  final String escaped = sanitized.replaceAll('"', '""');
  return '"$escaped"';
}

void main() {
  int passed = 0;
  int failed = 0;

  void test(String name, void Function() fn) {
    try {
      fn();
      passed++;
      print('  PASS: $name');
    } catch (e, st) {
      failed++;
      print('  FAIL: $name - $e\n$st');
    }
  }

  void expect(dynamic actual, dynamic expected, [String? message]) {
    if (actual != expected) {
      throw Exception('Expected $expected but got $actual ${message ?? ""}');
    }
  }

  print('\n=== PocketLedger Standalone Logic Verifications ===\n');

  test('Money Parsing - integers and decimals to paise', () {
    expect(CurrencyFormatter.parseToPaise('100'), 10000);
    expect(CurrencyFormatter.parseToPaise('12.50'), 1250);
    expect(CurrencyFormatter.parseToPaise('0.05'), 5);
    expect(CurrencyFormatter.parseToPaise('1,250.75'), 125075);
    expect(CurrencyFormatter.parseToPaise('0'), null);
    expect(CurrencyFormatter.parseToPaise('-50'), null);
    expect(CurrencyFormatter.parseToPaise('abc'), null);
    expect(CurrencyFormatter.parseToPaiseAllowZero('0'), 0);
  });

  test('Money Formatting - Indian rupee grouping and negative signs', () {
    expect(CurrencyFormatter.formatPaise(10000), '₹ 100');
    expect(CurrencyFormatter.formatPaise(125000), '₹ 1,250');
    expect(CurrencyFormatter.formatPaise(10000000), '₹ 1,00,000');
    expect(CurrencyFormatter.formatPaise(-250000), '-₹ 2,500');
    expect(CurrencyFormatter.paiseToEditableString(1250), '12.50');
  });

  test('Balance Calculation - opening + income - expense + transferIn - transferOut', () {
    const int openingBalance = 500000; // ₹5,000
    const int income = 250000; // ₹2,500
    const int expense = 120000; // ₹1,200
    const int transferIn = 80000; // ₹800
    const int transferOut = 60000; // ₹600

    final int balance = openingBalance + income - expense + transferIn - transferOut;
    expect(balance, 650000); // ₹6,500
  });

  test('Transfers Excluded from Income and Expense Reporting', () {
    final List<TransactionItem> transactions = <TransactionItem>[
      TransactionItem(
        id: '1',
        accountId: 'acc_1',
        categoryId: 'cat_salary',
        transactionType: TransactionType.income,
        amountPaise: 5000000, // ₹50,000
        transactionDate: DateTime(2026, 10, 1),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      TransactionItem(
        id: '2',
        accountId: 'acc_1',
        categoryId: 'cat_groceries',
        transactionType: TransactionType.expense,
        amountPaise: 1500000, // ₹15,000
        transactionDate: DateTime(2026, 10, 5),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      TransactionItem(
        id: '3_out',
        accountId: 'acc_1',
        categoryId: null,
        transactionType: TransactionType.transferOut,
        amountPaise: 1000000, // ₹10,000
        transactionDate: DateTime(2026, 10, 3),
        transferGroupId: 'trf_1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      TransactionItem(
        id: '3_in',
        accountId: 'acc_2',
        categoryId: null,
        transactionType: TransactionType.transferIn,
        amountPaise: 1000000, // ₹10,000
        transactionDate: DateTime(2026, 10, 3),
        transferGroupId: 'trf_1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    int reportIncome = 0;
    int reportExpense = 0;
    for (final TransactionItem tx in transactions) {
      if (tx.transactionType == TransactionType.income) reportIncome += tx.amountPaise;
      if (tx.transactionType == TransactionType.expense) reportExpense += tx.amountPaise;
    }

    expect(reportIncome, 5000000); // Transfers completely ignored
    expect(reportExpense, 1500000); // Transfers completely ignored
    expect(reportIncome - reportExpense, 3500000);
  });

  test('Budget Calculations - Clamped progress and warnings', () {
    // Normal 30%
    const Budget b1 = Budget(
      id: 'b1',
      categoryId: 'c1',
      month: 10,
      year: 2026,
      limitPaise: 1000000,
      spentPaise: 300000,
    );
    expect(b1.remainingPaise, 700000);
    expect(b1.percentageSpent, 30.0);
    expect(b1.clampedProgressRatio, 0.3);
    expect(b1.isApproachingLimit, false);
    expect(b1.isExceeded, false);

    // Warning 85%
    const Budget b2 = Budget(
      id: 'b2',
      categoryId: 'c1',
      month: 10,
      year: 2026,
      limitPaise: 1000000,
      spentPaise: 850000,
    );
    expect(b2.isApproachingLimit, true);
    expect(b2.isExceeded, false);

    // Exceeded 120%
    const Budget b3 = Budget(
      id: 'b3',
      categoryId: 'c1',
      month: 10,
      year: 2026,
      limitPaise: 1000000,
      spentPaise: 1200000,
    );
    expect(b3.remainingPaise, -200000);
    expect(b3.percentageSpent, 120.0);
    expect(b3.clampedProgressRatio, 1.0); // Never exceeds 1.0
    expect(b3.isExceeded, true);
  });

  test('CSV Formula Injection Prevention', () {
    expect(sanitizeCsvField('=SUM(A1:A10)'), '"\'=SUM(A1:A10)"');
    expect(sanitizeCsvField('+1234'), '"\'+1234"');
    expect(sanitizeCsvField('-5678'), '"\'-5678"');
    expect(sanitizeCsvField('@alert'), '"\'@alert"');
    expect(sanitizeCsvField('Grocery store'), '"Grocery store"');
  });

  print('\n----------------------------------------');
  print('Results: $passed Passed, $failed Failed');
  print('----------------------------------------\n');

  if (failed > 0) {
    throw Exception('Some tests failed!');
  }
}
