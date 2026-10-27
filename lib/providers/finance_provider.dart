import 'package:flutter/material.dart';
import '../models/account.dart';
import '../models/budget.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';
import '../services/demo_data_service.dart';
import '../utils/date_helper.dart';

/// Central state management for accounts, transactions, categories, budgets, and dashboard totals.
/// Ensures proper sequence of updates and informs listeners cleanly.
class FinanceProvider extends ChangeNotifier {
  final DatabaseService _dbService;

  FinanceProvider(this._dbService);

  bool _isLoading = true;
  String? _errorMessage;
  bool _onboardingCompleted = false;

  List<Account> _accounts = <Account>[];
  Map<String, int> _accountBalances =
      <String, int>{}; // accountId -> balancePaise
  List<Category> _categories = <Category>[];
  List<TransactionItem> _allTransactions = <TransactionItem>[];
  List<Budget> _budgets = <Budget>[];

  // Selected date boundary for Dashboard, Budgets, and Insights
  DateTime _selectedMonth =
      DateTime(DateTime.now().year, DateTime.now().month, 1);

  // Aggregated totals for selected month (in paise)
  int _monthlyIncome = 0;
  int _monthlyExpense = 0;
  int _monthlyNet = 0;
  List<Map<String, dynamic>> _categorySpending = <Map<String, dynamic>>[];
  Map<int, int> _dailySpending = <int, int>{};

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get onboardingCompleted => _onboardingCompleted;

  List<Account> get accounts => List<Account>.unmodifiable(_accounts);
  Map<String, int> get accountBalances =>
      Map<String, int>.unmodifiable(_accountBalances);
  List<Category> get categories => List<Category>.unmodifiable(_categories);
  List<TransactionItem> get allTransactions =>
      List<TransactionItem>.unmodifiable(_allTransactions);
  List<Budget> get budgets => List<Budget>.unmodifiable(_budgets);

  DateTime get selectedMonth => _selectedMonth;
  int get monthlyIncome => _monthlyIncome;
  int get monthlyExpense => _monthlyExpense;
  int get monthlyNet => _monthlyNet;
  List<Map<String, dynamic>> get categorySpending =>
      List<Map<String, dynamic>>.unmodifiable(_categorySpending);
  Map<int, int> get dailySpending => Map<int, int>.unmodifiable(_dailySpending);

  /// Total current balance across all accounts combined (in paise).
  int get totalNetWorth {
    int total = 0;
    for (final int balance in _accountBalances.values) {
      total += balance;
    }
    return total;
  }

  /// Initial load called when the app starts.
  Future<void> loadInitialData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final String? onboardPref =
          await _dbService.getPreference('onboardingCompleted');
      _onboardingCompleted = onboardPref == 'true';

      if (_onboardingCompleted) {
        await _refreshAllDataInternal();
      }
    } catch (e) {
      _errorMessage = 'Failed to load initial data: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Completes onboarding with either demo data or empty database.
  Future<void> completeOnboarding({required bool loadDemo}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (loadDemo) {
        await DemoDataService.seedDemoData(_dbService);
      } else {
        await DemoDataService.seedInitialEmptyAccounts(_dbService);
      }

      await _dbService.setPreference('onboardingCompleted', 'true');
      _onboardingCompleted = true;

      await _refreshAllDataInternal();
    } catch (e) {
      _errorMessage = 'Error setting up onboarding: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Changes the active reporting month and updates monthly aggregations.
  Future<void> setSelectedMonth(DateTime month) async {
    _selectedMonth = DateTime(month.year, month.month, 1);
    await _refreshMonthlyDataInternal();
    notifyListeners();
  }

  /// Refreshes all cached financial entities and aggregations.
  Future<void> refreshAll() async {
    try {
      await _refreshAllDataInternal();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error refreshing data: $e';
      notifyListeners();
    }
  }

  Future<void> _refreshAllDataInternal() async {
    // 1. Load accounts
    _accounts = await _dbService.getAllAccounts();

    // 2. Load account balances
    final Map<String, int> newBalances = <String, int>{};
    for (final Account acc in _accounts) {
      newBalances[acc.id] = await _dbService.calculateAccountBalance(acc.id);
    }
    _accountBalances = newBalances;

    // 3. Load categories
    _categories = await _dbService.getAllCategories(includeArchived: true);

    // 4. Load all transactions
    _allTransactions = await _dbService.getTransactions();

    // 5. Load monthly data
    await _refreshMonthlyDataInternal();
  }

  Future<void> _refreshMonthlyDataInternal() async {
    final DateTime start =
        DateHelper.startOfMonth(_selectedMonth.year, _selectedMonth.month);
    final DateTime end =
        DateHelper.endOfMonth(_selectedMonth.year, _selectedMonth.month);

    final Map<String, int> totals =
        await _dbService.getMonthlyTotals(start, end);
    _monthlyIncome = totals['income'] ?? 0;
    _monthlyExpense = totals['expense'] ?? 0;
    _monthlyNet = totals['net'] ?? 0;

    _categorySpending =
        await _dbService.getCategorySpendingForMonth(start, end);
    _dailySpending = await _dbService.getDailySpendingForMonth(start, end);
    _budgets = await _dbService.getBudgetsForMonth(
        _selectedMonth.month, _selectedMonth.year);
  }

  // ==========================================
  // ACCOUNT ACTIONS
  // ==========================================

  Future<void> addAccount({
    required String name,
    required AccountType type,
    required int openingBalancePaise,
  }) async {
    final Account account = Account(
      id: 'acc_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      accountType: type,
      openingBalancePaise: openingBalancePaise,
      createdAt: DateTime.now(),
    );

    await _dbService.insertAccount(account);
    await refreshAll();
  }

  Future<void> updateAccount(Account account) async {
    await _dbService.updateAccount(account);
    await refreshAll();
  }

  Future<void> deleteAccount(String accountId) async {
    await _dbService.deleteAccount(accountId);
    await refreshAll();
  }

  // ==========================================
  // TRANSACTION ACTIONS
  // ==========================================

  Future<void> addTransaction({
    required String accountId,
    required String categoryId,
    required TransactionType type,
    required int amountPaise,
    required DateTime date,
    String? note,
  }) async {
    final DateTime now = DateTime.now();
    final TransactionItem item = TransactionItem(
      id: 'tx_${now.millisecondsSinceEpoch}',
      accountId: accountId,
      categoryId: categoryId,
      transactionType: type,
      amountPaise: amountPaise,
      transactionDate: date,
      note: note,
      createdAt: now,
      updatedAt: now,
    );

    await _dbService.insertTransaction(item);
    await refreshAll();
  }

  Future<void> addTransfer({
    required String fromAccountId,
    required String toAccountId,
    required int amountPaise,
    required DateTime date,
    String? note,
  }) async {
    await _dbService.insertTransfer(
      fromAccountId: fromAccountId,
      toAccountId: toAccountId,
      amountPaise: amountPaise,
      date: date,
      note: note,
    );
    await refreshAll();
  }

  Future<void> updateTransaction(TransactionItem item) async {
    await _dbService
        .updateTransaction(item.copyWith(updatedAt: DateTime.now()));
    await refreshAll();
  }

  Future<void> updateTransfer({
    required String transferGroupId,
    required String fromAccountId,
    required String toAccountId,
    required int amountPaise,
    required DateTime date,
    String? note,
  }) async {
    await _dbService.updateTransfer(
      transferGroupId: transferGroupId,
      fromAccountId: fromAccountId,
      toAccountId: toAccountId,
      amountPaise: amountPaise,
      date: date,
      note: note,
    );
    await refreshAll();
  }

  Future<void> deleteTransaction(TransactionItem item) async {
    await _dbService.deleteTransaction(item);
    await refreshAll();
  }

  // ==========================================
  // CATEGORY ACTIONS
  // ==========================================

  Future<void> addCategory({
    required String name,
    required IncomeExpenseType type,
    required String iconKey,
    required int colorValue,
  }) async {
    final Category category = Category(
      id: 'cat_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      incomeOrExpense: type,
      iconKey: iconKey,
      colorValue: colorValue,
    );

    await _dbService.insertCategory(category);
    await refreshAll();
  }

  Future<void> updateCategory(Category category) async {
    await _dbService.updateCategory(category);
    await refreshAll();
  }

  Future<void> archiveOrDeleteCategory(String categoryId) async {
    await _dbService.archiveOrDeleteCategory(categoryId);
    await refreshAll();
  }

  // ==========================================
  // BUDGET ACTIONS
  // ==========================================

  Future<void> setBudget({
    required String categoryId,
    required int month,
    required int year,
    required int limitPaise,
  }) async {
    final Budget budget = Budget(
      id: 'bgt_${year}_${month}_$categoryId',
      categoryId: categoryId,
      month: month,
      year: year,
      limitPaise: limitPaise,
    );

    await _dbService.setBudget(budget);
    await _refreshMonthlyDataInternal();
    notifyListeners();
  }

  Future<void> deleteBudget(String budgetId) async {
    await _dbService.deleteBudget(budgetId);
    await _refreshMonthlyDataInternal();
    notifyListeners();
  }

  Future<int> copyPreviousMonthBudgets() async {
    final int count = await _dbService.copyBudgetsFromPreviousMonth(
      targetMonth: _selectedMonth.month,
      targetYear: _selectedMonth.year,
    );
    await _refreshMonthlyDataInternal();
    notifyListeners();
    return count;
  }

  // ==========================================
  // RESET ALL DATA
  // ==========================================

  Future<void> clearAllData() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _dbService.clearAllData();
      await _dbService.setPreference('onboardingCompleted', 'false');
      _onboardingCompleted = false;
      _accounts = <Account>[];
      _accountBalances = <String, int>{};
      _allTransactions = <TransactionItem>[];
      _budgets = <Budget>[];
      _categorySpending = <Map<String, dynamic>>[];
      _dailySpending = <int, int>{};
      _monthlyIncome = 0;
      _monthlyExpense = 0;
      _monthlyNet = 0;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
