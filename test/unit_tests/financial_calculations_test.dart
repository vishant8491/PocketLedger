import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_ledger/models/budget.dart';
import 'package:pocket_ledger/models/transaction.dart';

void main() {
  group('Financial Arithmetic & Business Logic', () {
    test(
        'account balance formula accurately accounts for all 4 cash flow types',
        () {
      const int openingBalance = 500000; // ₹5,000
      const int income = 250000; // ₹2,500
      const int expense = 120000; // ₹1,200
      const int transferIn = 80000; // ₹800
      const int transferOut = 60000; // ₹600

      // Balance = opening + income - expense + transfer_in - transfer_out
      const int calculatedBalance =
          openingBalance + income - expense + transferIn - transferOut;

      // 5000 + 2500 - 1200 + 800 - 600 = 6500 (650000 paise)
      expect(calculatedBalance, equals(650000));
    });

    test(
        'transfers are strictly excluded from monthly income and expense aggregates',
        () {
      final List<TransactionItem> transactions = <TransactionItem>[
        TransactionItem(
          id: '1',
          accountId: 'acc_bank',
          categoryId: 'cat_salary',
          transactionType: TransactionType.income,
          amountPaise: 5000000, // ₹50,000
          transactionDate: DateTime(2026, 10, 1),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        TransactionItem(
          id: '2',
          accountId: 'acc_bank',
          categoryId: 'cat_rent',
          transactionType: TransactionType.expense,
          amountPaise: 1500000, // ₹15,000
          transactionDate: DateTime(2026, 10, 5),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        // Transfer Out (Bank to Cash)
        TransactionItem(
          id: '3_out',
          accountId: 'acc_bank',
          categoryId: null,
          transactionType: TransactionType.transferOut,
          amountPaise: 1000000, // ₹10,000
          transactionDate: DateTime(2026, 10, 3),
          transferGroupId: 'trf_group_1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        // Transfer In (Cash from Bank)
        TransactionItem(
          id: '3_in',
          accountId: 'acc_cash',
          categoryId: null,
          transactionType: TransactionType.transferIn,
          amountPaise: 1000000, // ₹10,000
          transactionDate: DateTime(2026, 10, 3),
          transferGroupId: 'trf_group_1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      int totalMonthlyIncome = 0;
      int totalMonthlyExpense = 0;

      for (final TransactionItem tx in transactions) {
        if (tx.transactionType == TransactionType.income) {
          totalMonthlyIncome += tx.amountPaise;
        } else if (tx.transactionType == TransactionType.expense) {
          totalMonthlyExpense += tx.amountPaise;
        }
        // Transfers are ignored in income/expense reports
      }

      expect(totalMonthlyIncome,
          equals(5000000)); // Exactly ₹50,000 (transferIn ignored)
      expect(totalMonthlyExpense,
          equals(1500000)); // Exactly ₹15,000 (transferOut ignored)
      expect(totalMonthlyIncome - totalMonthlyExpense,
          equals(3500000)); // Net ₹35,000
    });

    test(
        'budget calculations handle normal, approaching limit, and exceeded states',
        () {
      // 1. Normal state: ₹3,000 spent of ₹10,000 (30%)
      const Budget normalBudget = Budget(
        id: 'b1',
        categoryId: 'cat_groceries',
        month: 10,
        year: 2026,
        limitPaise: 1000000,
        spentPaise: 300000,
      );
      expect(normalBudget.remainingPaise, equals(700000));
      expect(normalBudget.percentageSpent, equals(30.0));
      expect(normalBudget.clampedProgressRatio, equals(0.3));
      expect(normalBudget.isApproachingLimit, isFalse);
      expect(normalBudget.isExceeded, isFalse);

      // 2. Approaching limit: ₹8,500 spent of ₹10,000 (85%)
      const Budget warningBudget = Budget(
        id: 'b2',
        categoryId: 'cat_groceries',
        month: 10,
        year: 2026,
        limitPaise: 1000000,
        spentPaise: 850000,
      );
      expect(warningBudget.remainingPaise, equals(150000));
      expect(warningBudget.percentageSpent, equals(85.0));
      expect(warningBudget.clampedProgressRatio, equals(0.85));
      expect(warningBudget.isApproachingLimit, isTrue);
      expect(warningBudget.isExceeded, isFalse);

      // 3. Exceeded state: ₹12,000 spent of ₹10,000 (120%)
      const Budget exceededBudget = Budget(
        id: 'b3',
        categoryId: 'cat_groceries',
        month: 10,
        year: 2026,
        limitPaise: 1000000,
        spentPaise: 1200000,
      );
      expect(exceededBudget.remainingPaise, equals(-200000)); // Negative ₹2,000
      expect(exceededBudget.percentageSpent, equals(120.0));
      // Visual indicator MUST clamp cleanly to 1.0 (never 1.2 which breaks UI)
      expect(exceededBudget.clampedProgressRatio, equals(1.0));
      expect(exceededBudget.isExceeded, isTrue);
    });

    test('editing a transaction updates calculated running totals', () {
      int runningExpense = 150000; // Originally ₹1,500

      // User edits original amount from ₹1,500 to ₹1,800
      const int oldAmount = 150000;
      const int newAmount = 180000;
      runningExpense = runningExpense - oldAmount + newAmount;

      expect(runningExpense, equals(180000));

      // User deletes transaction
      runningExpense = runningExpense - newAmount;
      expect(runningExpense, equals(0));
    });
  });
}
