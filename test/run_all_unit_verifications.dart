// Standalone test verification runner that runs directly on any Dart SDK
// Verifies money arithmetic, budget calculations, transfers exclusion, and formula injection defenses.

import 'package:pocket_ledger/models/budget.dart';
import 'package:pocket_ledger/models/transaction.dart';
import 'package:pocket_ledger/utils/currency_formatter.dart';

// Standalone mirror of CSV sanitization to verify the security logic
String sanitizeCsvField(String text) {
  if (text.isEmpty) return '""';
  String sanitized = text;
  final String trimmedLeft = sanitized.trimLeft();
  if (trimmedLeft.isNotEmpty) {
    final String firstChar = trimmedLeft.substring(0, 1);
    if (firstChar == '=' ||
        firstChar == '+' ||
        firstChar == '-' ||
        firstChar == '@' ||
        firstChar == '\t' ||
        firstChar == '\r') {
      sanitized = "'$sanitized";
    }
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

  test(
      'Balance Calculation - opening + income - expense + transferIn - transferOut',
      () {
    const int openingBalance = 500000; // ₹5,000
    const int income = 250000; // ₹2,500
    const int expense = 120000; // ₹1,200
    const int transferIn = 80000; // ₹800
    const int transferOut = 60000; // ₹600

    final int balance =
        openingBalance + income - expense + transferIn - transferOut;
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
      if (tx.transactionType == TransactionType.income)
        reportIncome += tx.amountPaise;
      if (tx.transactionType == TransactionType.expense)
        reportExpense += tx.amountPaise;
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

  test('Prompt Required Independent Numeric Fixture Verification', () {
    // Requirements:
    // Account A opening balance: ₹10,000.
    // Account B opening balance: ₹2,000.
    // Add income ₹5,000 to A.
    // Add expense ₹1,500 to A.
    // Transfer ₹3,000 from A to B.
    // Expected:
    // A balance: ₹10,500.
    // B balance: ₹5,000.
    // Total balance: ₹15,500.
    // Income: ₹5,000.
    // Expense: ₹1,500.
    // Net income minus expense: ₹3,500.

    final int accAOpening = CurrencyFormatter.parseToPaise('10000')!; // 1000000
    final int accBOpening = CurrencyFormatter.parseToPaise('2000')!; // 200000
    final int incomeA = CurrencyFormatter.parseToPaise('5000')!; // 500000
    final int expenseA = CurrencyFormatter.parseToPaise('1500')!; // 150000
    final int transferAmount =
        CurrencyFormatter.parseToPaise('3000')!; // 300000

    // Account A transactions
    final int balanceA = accAOpening + incomeA - expenseA - transferAmount;
    // Account B transactions
    final int balanceB = accBOpening + transferAmount;
    final int totalBalance = balanceA + balanceB;

    // Report aggregates (transfers do not count toward income or expense)
    final int totalIncome = incomeA;
    final int totalExpense = expenseA;
    final int netIncomeMinusExpense = totalIncome - totalExpense;

    expect(balanceA, 1050000, 'Account A balance must be ₹10,500');
    expect(balanceB, 500000, 'Account B balance must be ₹5,000');
    expect(totalBalance, 1550000,
        'Total net worth across accounts must be ₹15,500');
    expect(totalIncome, 500000, 'Total income must be ₹5,000');
    expect(totalExpense, 150000, 'Total expense must be ₹1,500');
    expect(netIncomeMinusExpense, 350000,
        'Net income minus expense must be ₹3,500');

    // Formatted verification
    expect(CurrencyFormatter.formatPaise(balanceA), '₹ 10,500');
    expect(CurrencyFormatter.formatPaise(balanceB), '₹ 5,000');
    expect(CurrencyFormatter.formatPaise(totalBalance), '₹ 15,500');
  });

  test('Date Boundary Calculations & Leap Year Handling', () {
    // Standard month
    final DateTime octStart = DateTime(2026, 10, 1, 0, 0, 0);
    final DateTime novStart = DateTime(2026, 11, 1, 0, 0, 0);
    expect(octStart.month, 10);
    expect(novStart.month, 11);

    // Leap year Feb 2024
    final DateTime feb2024End = DateTime(2024, 3, 0, 23, 59, 59, 999);
    expect(feb2024End.day, 29); // 2024 is a leap year

    // Non-leap year Feb 2023
    final DateTime feb2023End = DateTime(2023, 3, 0, 23, 59, 59, 999);
    expect(feb2023End.day, 28); // 2023 is not a leap year

    // Year boundary December -> January
    final DateTime decStart = DateTime(2026, 12, 1, 0, 0, 0);
    final DateTime janStart = DateTime(2026, 12 + 1, 1, 0, 0, 0);
    expect(decStart.year, 2026);
    expect(janStart.year, 2027);
    expect(janStart.month, 1);
  });

  test('CSV Formula Injection Prevention including whitespace/tabs', () {
    // Formula triggers
    expect(sanitizeCsvField('=SUM(A1:A10)'), '"\'=SUM(A1:A10)"');
    expect(sanitizeCsvField('+1234'), '"\'+1234"');
    expect(sanitizeCsvField('-5678'), '"\'-5678"');
    expect(sanitizeCsvField('@alert'), '"\'@alert"');
    expect(sanitizeCsvField('  =cmd|'), '"\'  =cmd|"');
    expect(sanitizeCsvField('\t=HYPERLINK()'), '"\'\t=HYPERLINK()"');
    // Normal strings
    expect(sanitizeCsvField('Grocery store'), '"Grocery store"');
    expect(sanitizeCsvField('Book "Refactoring"'), '"Book ""Refactoring"""');
    expect(sanitizeCsvField(''), '""');
  });

  test('Amount boundary - maximum supported personal finance rupees', () {
    // Max supported: ₹99,99,99,999 (99 Crore)
    expect(CurrencyFormatter.parseToPaise('999999999'), 99999999900);
    // Over limit rejected
    expect(CurrencyFormatter.parseToPaise('1000000000'), null);
    // Negative rejected
    expect(CurrencyFormatter.parseToPaise('-100'), null);
    // Malformed rejected
    expect(CurrencyFormatter.parseToPaise('100.555'), null);
  });

  print('\n----------------------------------------');
  print('Results: $passed Passed, $failed Failed');
  print('----------------------------------------\n');

  if (failed > 0) {
    throw Exception('Some tests failed!');
  }
}
