import '../models/account.dart';
import '../models/budget.dart';
import '../models/transaction.dart';
import 'database_service.dart';

/// Service for generating rich, realistic demonstration data across three months.
/// Only executed upon explicit user selection during onboarding.
class DemoDataService {
  DemoDataService._();

  /// Loads realistic accounts, transactions, and budgets spanning the current month,
  /// previous month, and two months ago.
  static Future<void> seedDemoData(DatabaseService dbService) async {
    final DateTime now = DateTime.now();
    final DateTime currentMonth = DateTime(now.year, now.month, 1);
    final DateTime lastMonth = DateTime(now.year, now.month - 1, 1);
    final DateTime twoMonthsAgo = DateTime(now.year, now.month - 2, 1);

    // 1. Seed Accounts
    final Account cashAccount = Account(
      id: 'acc_cash',
      name: 'Cash in Hand',
      accountType: AccountType.cash,
      openingBalancePaise: 350000, // ₹3,500
      createdAt: twoMonthsAgo,
    );

    final Account bankAccount = Account(
      id: 'acc_bank',
      name: 'HDFC Salary Account',
      accountType: AccountType.bank,
      openingBalancePaise: 4500000, // ₹45,000
      createdAt: twoMonthsAgo,
    );

    final Account walletAccount = Account(
      id: 'acc_wallet',
      name: 'PayTM / UPI Wallet',
      accountType: AccountType.wallet,
      openingBalancePaise: 150000, // ₹1,500
      createdAt: twoMonthsAgo,
    );

    await dbService.insertAccount(cashAccount);
    await dbService.insertAccount(bankAccount);
    await dbService.insertAccount(walletAccount);

    // 2. Helper to insert an income or expense
    Future<void> addTx({
      required String id,
      required String accountId,
      required String categoryId,
      required TransactionType type,
      required int amountPaise,
      required DateTime date,
      required String note,
    }) async {
      final TransactionItem item = TransactionItem(
        id: id,
        accountId: accountId,
        categoryId: categoryId,
        transactionType: type,
        amountPaise: amountPaise,
        transactionDate: date,
        note: note,
        createdAt: date,
        updatedAt: date,
      );
      await dbService.insertTransaction(item);
    }

    // 3. Helper to insert transfer
    Future<void> addTrf({
      required String fromAcc,
      required String toAcc,
      required int amountPaise,
      required DateTime date,
      required String note,
    }) async {
      await dbService.insertTransfer(
        fromAccountId: fromAcc,
        toAccountId: toAcc,
        amountPaise: amountPaise,
        date: date,
        note: note,
      );
    }

    // 4. Generate data for a month
    Future<void> seedMonthData(DateTime monthDate, String prefix) async {
      final int year = monthDate.year;
      final int month = monthDate.month;

      // Income
      await addTx(
        id: '${prefix}_salary',
        accountId: 'acc_bank',
        categoryId: 'cat_salary',
        type: TransactionType.income,
        amountPaise: 6500000, // ₹65,000
        date: DateTime(year, month, 1, 10, 0),
        note: 'Monthly Corporate Salary Credit',
      );

      await addTx(
        id: '${prefix}_freelance',
        accountId: 'acc_bank',
        categoryId: 'cat_freelance',
        type: TransactionType.income,
        amountPaise: 1800000, // ₹18,000
        date: DateTime(year, month, 14, 15, 30),
        note: 'Flutter App UI Design Project',
      );

      // Transfers
      await addTrf(
        fromAcc: 'acc_bank',
        toAcc: 'acc_cash',
        amountPaise: 800000, // ₹8,000
        date: DateTime(year, month, 3, 11, 0),
        note: 'Monthly ATM Cash Withdrawal',
      );

      await addTrf(
        fromAcc: 'acc_bank',
        toAcc: 'acc_wallet',
        amountPaise: 300000, // ₹3,000
        date: DateTime(year, month, 4, 18, 0),
        note: 'UPI Wallet Reload for Quick Payments',
      );

      // Expenses
      await addTx(
        id: '${prefix}_rent',
        accountId: 'acc_bank',
        categoryId: 'cat_rent',
        type: TransactionType.expense,
        amountPaise: 1800000, // ₹18,000
        date: DateTime(year, month, 5, 9, 0),
        note: 'Apartment Maintenance & Rent',
      );

      await addTx(
        id: '${prefix}_groceries_1',
        accountId: 'acc_bank',
        categoryId: 'cat_groceries',
        type: TransactionType.expense,
        amountPaise: 385000, // ₹3,850
        date: DateTime(year, month, 6, 17, 30),
        note: 'Supermarket Provisions & Dairy',
      );

      await addTx(
        id: '${prefix}_utilities',
        accountId: 'acc_bank',
        categoryId: 'cat_utilities',
        type: TransactionType.expense,
        amountPaise: 245000, // ₹2,450
        date: DateTime(year, month, 8, 12, 0),
        note: 'Electricity and Broadband Bill',
      );

      await addTx(
        id: '${prefix}_fuel_1',
        accountId: 'acc_wallet',
        categoryId: 'cat_transport',
        type: TransactionType.expense,
        amountPaise: 150000, // ₹1,500
        date: DateTime(year, month, 10, 8, 45),
        note: 'Vehicle Petrol Top-up',
      );

      await addTx(
        id: '${prefix}_dining',
        accountId: 'acc_cash',
        categoryId: 'cat_entertainment',
        type: TransactionType.expense,
        amountPaise: 145000, // ₹1,450
        date: DateTime(year, month, 12, 20, 15),
        note: 'Weekend Dinner with Colleagues',
      );

      await addTx(
        id: '${prefix}_groceries_2',
        accountId: 'acc_wallet',
        categoryId: 'cat_groceries',
        type: TransactionType.expense,
        amountPaise: 220000, // ₹2,200
        date: DateTime(year, month, 18, 16, 20),
        note: 'Fresh Fruits and Vegetables',
      );

      await addTx(
        id: '${prefix}_shopping',
        accountId: 'acc_bank',
        categoryId: 'cat_shopping',
        type: TransactionType.expense,
        amountPaise: 340000, // ₹3,400
        date: DateTime(year, month, 22, 14, 0),
        note: 'Work Shirts & Casual Shoes',
      );

      await addTx(
        id: '${prefix}_medical',
        accountId: 'acc_cash',
        categoryId: 'cat_healthcare',
        type: TransactionType.expense,
        amountPaise: 65000, // ₹650
        date: DateTime(year, month, 25, 11, 30),
        note: 'Pharmacy Prescription & Vitamins',
      );

      // Budgets for this month
      final List<Budget> monthBudgets = <Budget>[
        Budget(
          id: 'bgt_${year}_${month}_rent',
          categoryId: 'cat_rent',
          month: month,
          year: year,
          limitPaise: 1800000, // ₹18,000
        ),
        Budget(
          id: 'bgt_${year}_${month}_groceries',
          categoryId: 'cat_groceries',
          month: month,
          year: year,
          limitPaise: 800000, // ₹8,000
        ),
        Budget(
          id: 'bgt_${year}_${month}_utilities',
          categoryId: 'cat_utilities',
          month: month,
          year: year,
          limitPaise: 300000, // ₹3,000
        ),
        Budget(
          id: 'bgt_${year}_${month}_transport',
          categoryId: 'cat_transport',
          month: month,
          year: year,
          limitPaise: 300000, // ₹3,000
        ),
        Budget(
          id: 'bgt_${year}_${month}_dining',
          categoryId: 'cat_entertainment',
          month: month,
          year: year,
          limitPaise: 250000, // ₹2,500
        ),
      ];

      for (final Budget bgt in monthBudgets) {
        await dbService.setBudget(bgt);
      }
    }

    // Seed 3 full months
    await seedMonthData(twoMonthsAgo, 'm2');
    await seedMonthData(lastMonth, 'm1');
    await seedMonthData(currentMonth, 'm0');

    // Record preference that demo data has been loaded
    await dbService.setPreference('demoDataLoaded', 'true');
  }

  /// Seeds default empty accounts if the user selects "Start Empty".
  static Future<void> seedInitialEmptyAccounts(
      DatabaseService dbService) async {
    final DateTime now = DateTime.now();

    final Account cashAccount = Account(
      id: 'acc_cash_default',
      name: 'Cash in Hand',
      accountType: AccountType.cash,
      openingBalancePaise: 0,
      createdAt: now,
    );

    final Account bankAccount = Account(
      id: 'acc_bank_default',
      name: 'Primary Bank Account',
      accountType: AccountType.bank,
      openingBalancePaise: 0,
      createdAt: now,
    );

    await dbService.insertAccount(cashAccount);
    await dbService.insertAccount(bankAccount);
  }
}
