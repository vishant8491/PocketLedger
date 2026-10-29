import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'database_init_helper.dart';
import '../models/account.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../models/budget.dart';

/// Service responsible for managing SQLite database creation, migrations,
/// and parameterized queries. Ensures atomic transactions for transfers and financial consistency.
class DatabaseService {
  static const String _databaseName = 'pocket_ledger.db';
  static const int _databaseVersion = 1;

  Database? _database;

  /// Returns the singleton database instance, initializing it if necessary.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    await initDatabasePlatform();
    final String path = await resolveDatabasePath(_databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Creates initial tables and seeds default categories.
  Future<void> _onCreate(Database db, int version) async {
    // 1. Accounts Table
    await db.execute('''
      CREATE TABLE accounts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        accountType TEXT NOT NULL,
        openingBalancePaise INTEGER NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    // 2. Categories Table
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        incomeOrExpense TEXT NOT NULL,
        iconKey TEXT NOT NULL,
        colorValue INTEGER NOT NULL,
        isArchived INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // 3. Transactions Table
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        accountId TEXT NOT NULL,
        categoryId TEXT,
        transactionType TEXT NOT NULL,
        amountPaise INTEGER NOT NULL,
        transactionDate TEXT NOT NULL,
        note TEXT,
        transferGroupId TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY (accountId) REFERENCES accounts (id),
        FOREIGN KEY (categoryId) REFERENCES categories (id)
      )
    ''');

    // Indexes for fast querying & monthly report filtering
    await db.execute(
        'CREATE INDEX idx_transactions_account ON transactions(accountId)');
    await db.execute(
        'CREATE INDEX idx_transactions_category ON transactions(categoryId)');
    await db.execute(
        'CREATE INDEX idx_transactions_date ON transactions(transactionDate)');
    await db.execute(
        'CREATE INDEX idx_transactions_transfer ON transactions(transferGroupId)');

    // 4. Budgets Table (Unique category per month & year)
    await db.execute('''
      CREATE TABLE budgets (
        id TEXT PRIMARY KEY,
        categoryId TEXT NOT NULL,
        month INTEGER NOT NULL,
        year INTEGER NOT NULL,
        limitPaise INTEGER NOT NULL,
        UNIQUE(categoryId, month, year),
        FOREIGN KEY (categoryId) REFERENCES categories (id)
      )
    ''');

    // 5. App Preferences Table (Key-Value)
    await db.execute('''
      CREATE TABLE app_preferences (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // Seed default categories
    await _seedDefaultCategories(db);
  }

  /// Handles schema migrations across versions.
  /// Example for future migrations:
  /// if (oldVersion < 2) {
  ///   await db.execute('ALTER TABLE accounts ADD COLUMN currencyCode TEXT DEFAULT "INR"');
  /// }
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Currently at version 1. Future migrations will be added sequentially here.
  }

  /// Seeds realistic, standard default categories for income and expenses.
  Future<void> _seedDefaultCategories(DatabaseExecutor db) async {
    final List<Category> defaultCategories = <Category>[
      // Income
      const Category(
        id: 'cat_salary',
        name: 'Salary',
        incomeOrExpense: IncomeExpenseType.income,
        iconKey: 'work',
        colorValue: 0xFF10B981, // Emerald
      ),
      const Category(
        id: 'cat_freelance',
        name: 'Freelance & Business',
        incomeOrExpense: IncomeExpenseType.income,
        iconKey: 'laptop',
        colorValue: 0xFF0D9488, // Teal
      ),
      const Category(
        id: 'cat_investments',
        name: 'Investments & Dividends',
        incomeOrExpense: IncomeExpenseType.income,
        iconKey: 'trending_up',
        colorValue: 0xFF2563EB, // Blue
      ),
      const Category(
        id: 'cat_gifts',
        name: 'Gifts & Grants',
        incomeOrExpense: IncomeExpenseType.income,
        iconKey: 'card_giftcard',
        colorValue: 0xFFD97706, // Amber
      ),
      const Category(
        id: 'cat_other_income',
        name: 'Other Income',
        incomeOrExpense: IncomeExpenseType.income,
        iconKey: 'wallet',
        colorValue: 0xFF8B5CF6, // Purple
      ),

      // Expenses
      const Category(
        id: 'cat_groceries',
        name: 'Groceries & Food',
        incomeOrExpense: IncomeExpenseType.expense,
        iconKey: 'restaurant',
        colorValue: 0xFFEA580C, // Orange
      ),
      const Category(
        id: 'cat_rent',
        name: 'Housing & Rent',
        incomeOrExpense: IncomeExpenseType.expense,
        iconKey: 'home',
        colorValue: 0xFF4F46E5, // Indigo
      ),
      const Category(
        id: 'cat_utilities',
        name: 'Bills & Utilities',
        incomeOrExpense: IncomeExpenseType.expense,
        iconKey: 'lightbulb',
        colorValue: 0xFFCA8A04, // Yellow-Amber
      ),
      const Category(
        id: 'cat_transport',
        name: 'Transportation & Fuel',
        incomeOrExpense: IncomeExpenseType.expense,
        iconKey: 'directions_car',
        colorValue: 0xFF0284C7, // Sky Blue
      ),
      const Category(
        id: 'cat_shopping',
        name: 'Shopping & Clothes',
        incomeOrExpense: IncomeExpenseType.expense,
        iconKey: 'shopping_bag',
        colorValue: 0xFFDB2777, // Pink
      ),
      const Category(
        id: 'cat_entertainment',
        name: 'Entertainment & Outings',
        incomeOrExpense: IncomeExpenseType.expense,
        iconKey: 'movie',
        colorValue: 0xFF7C3AED, // Violet
      ),
      const Category(
        id: 'cat_healthcare',
        name: 'Healthcare & Medical',
        incomeOrExpense: IncomeExpenseType.expense,
        iconKey: 'local_hospital',
        colorValue: 0xFFDC2626, // Red
      ),
      const Category(
        id: 'cat_education',
        name: 'Education & Courses',
        incomeOrExpense: IncomeExpenseType.expense,
        iconKey: 'school',
        colorValue: 0xFF0891B2, // Cyan
      ),
      const Category(
        id: 'cat_personal',
        name: 'Personal Care & Spa',
        incomeOrExpense: IncomeExpenseType.expense,
        iconKey: 'spa',
        colorValue: 0xFF059669, // Emerald Dark
      ),
      const Category(
        id: 'cat_misc',
        name: 'Miscellaneous',
        incomeOrExpense: IncomeExpenseType.expense,
        iconKey: 'more_horiz',
        colorValue: 0xFF64748B, // Slate Grey
      ),
    ];

    final Batch batch = db.batch();
    for (final Category cat in defaultCategories) {
      batch.insert('categories', cat.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  // ==========================================
  // ACCOUNTS
  // ==========================================

  Future<List<Account>> getAllAccounts() async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'accounts',
      orderBy: 'createdAt ASC',
    );
    return maps.map((Map<String, dynamic> m) => Account.fromMap(m)).toList();
  }

  Future<Account?> getAccountById(String id) async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'accounts',
      where: 'id = ?',
      whereArgs: <Object>[id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Account.fromMap(maps.first);
  }

  Future<void> insertAccount(Account account) async {
    final Database db = await database;
    await db.insert(
      'accounts',
      account.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateAccount(Account account) async {
    final Database db = await database;
    await db.update(
      'accounts',
      account.toMap(),
      where: 'id = ?',
      whereArgs: <Object>[account.id],
    );
  }

  /// Deletes an account only if it has zero transactions.
  /// Throws an [Exception] if transactions are found.
  Future<void> deleteAccount(String accountId) async {
    final Database db = await database;
    final int count = await countTransactionsForAccount(accountId);
    if (count > 0) {
      throw Exception(
          'Cannot delete account because it contains $count transaction(s).');
    }
    await db.delete(
      'accounts',
      where: 'id = ?',
      whereArgs: <Object>[accountId],
    );
  }

  Future<int> countTransactionsForAccount(String accountId) async {
    final Database db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT COUNT(*) as total FROM transactions WHERE accountId = ?',
      <Object>[accountId],
    );
    if (result.isEmpty) return 0;
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Calculates the current balance of an account in paise using parameterized query.
  /// Balance = openingBalance + income - expense + transfer_in - transfer_out.
  Future<int> calculateAccountBalance(String accountId) async {
    final Database db = await database;
    final Account? account = await getAccountById(accountId);
    if (account == null) return 0;

    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT 
        COALESCE(SUM(CASE WHEN transactionType = 'income' THEN amountPaise ELSE 0 END), 0) AS totalIncome,
        COALESCE(SUM(CASE WHEN transactionType = 'expense' THEN amountPaise ELSE 0 END), 0) AS totalExpense,
        COALESCE(SUM(CASE WHEN transactionType = 'transfer_in' THEN amountPaise ELSE 0 END), 0) AS totalTransferIn,
        COALESCE(SUM(CASE WHEN transactionType = 'transfer_out' THEN amountPaise ELSE 0 END), 0) AS totalTransferOut
      FROM transactions
      WHERE accountId = ?
    ''', <Object>[accountId]);

    if (result.isEmpty) return account.openingBalancePaise;

    final Map<String, dynamic> row = result.first;
    final int totalIncome = row['totalIncome'] as int? ?? 0;
    final int totalExpense = row['totalExpense'] as int? ?? 0;
    final int totalTransferIn = row['totalTransferIn'] as int? ?? 0;
    final int totalTransferOut = row['totalTransferOut'] as int? ?? 0;

    return account.openingBalancePaise +
        totalIncome -
        totalExpense +
        totalTransferIn -
        totalTransferOut;
  }

  // ==========================================
  // CATEGORIES
  // ==========================================

  Future<List<Category>> getAllCategories(
      {bool includeArchived = false}) async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps;
    if (includeArchived) {
      maps = await db.query('categories', orderBy: 'name ASC');
    } else {
      maps = await db.query(
        'categories',
        where: 'isArchived = 0',
        orderBy: 'name ASC',
      );
    }
    return maps.map((Map<String, dynamic> m) => Category.fromMap(m)).toList();
  }

  Future<List<Category>> getCategoriesByType(IncomeExpenseType type,
      {bool includeArchived = false}) async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps;
    if (includeArchived) {
      maps = await db.query(
        'categories',
        where: 'incomeOrExpense = ?',
        whereArgs: <Object>[type.name],
        orderBy: 'name ASC',
      );
    } else {
      maps = await db.query(
        'categories',
        where: 'incomeOrExpense = ? AND isArchived = 0',
        whereArgs: <Object>[type.name],
        orderBy: 'name ASC',
      );
    }
    return maps.map((Map<String, dynamic> m) => Category.fromMap(m)).toList();
  }

  Future<void> insertCategory(Category category) async {
    final Database db = await database;
    await db.insert('categories', category.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateCategory(Category category) async {
    final Database db = await database;
    await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: <Object>[category.id],
    );
  }

  /// Archives a category instead of deleting if it is referenced in transactions or budgets.
  Future<void> archiveOrDeleteCategory(String categoryId) async {
    final Database db = await database;
    final List<Map<String, dynamic>> txCountResult = await db.rawQuery(
      'SELECT COUNT(*) as total FROM transactions WHERE categoryId = ?',
      <Object>[categoryId],
    );
    final int txCount = Sqflite.firstIntValue(txCountResult) ?? 0;

    final List<Map<String, dynamic>> budgetCountResult = await db.rawQuery(
      'SELECT COUNT(*) as total FROM budgets WHERE categoryId = ?',
      <Object>[categoryId],
    );
    final int budgetCount = Sqflite.firstIntValue(budgetCountResult) ?? 0;

    if (txCount > 0 || budgetCount > 0) {
      // Archive to preserve historical reporting and budget foreign-key integrity
      await db.update(
        'categories',
        <String, dynamic>{'isArchived': 1},
        where: 'id = ?',
        whereArgs: <Object>[categoryId],
      );
    } else {
      // Safe to delete if never referenced anywhere
      await db.delete(
        'categories',
        where: 'id = ?',
        whereArgs: <Object>[categoryId],
      );
    }
  }

  // ==========================================
  // TRANSACTIONS
  // ==========================================

  /// Inserts a standard income or expense transaction.
  Future<void> insertTransaction(TransactionItem item) async {
    final Database db = await database;
    await db.insert('transactions', item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Atomically inserts both sides of a transfer between two accounts.
  /// Neither side appears in income or expense reports.
  Future<void> insertTransfer({
    required String fromAccountId,
    required String toAccountId,
    required int amountPaise,
    required DateTime date,
    String? note,
  }) async {
    if (fromAccountId == toAccountId) {
      throw Exception('Source and destination accounts must be different.');
    }
    if (amountPaise <= 0) {
      throw Exception('Transfer amount must be strictly greater than zero.');
    }

    final Database db = await database;
    final DateTime now = DateTime.now();
    final String groupId =
        'trf_${now.millisecondsSinceEpoch}_${now.microsecond}';

    final String cleanNote = note != null ? note.trim() : '';

    final TransactionItem transferOut = TransactionItem(
      id: '${groupId}_out',
      accountId: fromAccountId,
      categoryId: null,
      transactionType: TransactionType.transferOut,
      amountPaise: amountPaise,
      transactionDate: date,
      note: cleanNote.isNotEmpty ? cleanNote : null,
      transferGroupId: groupId,
      createdAt: now,
      updatedAt: now,
    );

    final TransactionItem transferIn = TransactionItem(
      id: '${groupId}_in',
      accountId: toAccountId,
      categoryId: null,
      transactionType: TransactionType.transferIn,
      amountPaise: amountPaise,
      transactionDate: date,
      note: cleanNote.isNotEmpty ? cleanNote : null,
      transferGroupId: groupId,
      createdAt: now,
      updatedAt: now,
    );

    await db.transaction((Transaction txn) async {
      await txn.insert('transactions', transferOut.toMap());
      await txn.insert('transactions', transferIn.toMap());
    });
  }

  /// Updates an income or expense transaction.
  Future<void> updateTransaction(TransactionItem item) async {
    final Database db = await database;
    await db.update(
      'transactions',
      item.toMap(),
      where: 'id = ?',
      whereArgs: <Object>[item.id],
    );
  }

  /// Fetches both legs of a transfer group (transfer_out and transfer_in).
  Future<List<TransactionItem>> getTransferLegs(String transferGroupId) async {
    final Database db = await database;
    final List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT 
        t.*,
        a.name AS accountName,
        c.name AS categoryName,
        c.iconKey AS categoryIconKey,
        c.colorValue AS categoryColorValue
      FROM transactions t
      LEFT JOIN accounts a ON t.accountId = a.id
      LEFT JOIN categories c ON t.categoryId = c.id
      WHERE t.transferGroupId = ?
      ORDER BY t.transactionType ASC
    ''', <Object>[transferGroupId]);

    return results
        .map((Map<String, dynamic> row) => TransactionItem.fromMap(row))
        .toList();
  }

  /// Atomically updates both sides of a transfer.
  Future<void> updateTransfer({
    required String transferGroupId,
    required String fromAccountId,
    required String toAccountId,
    required int amountPaise,
    required DateTime date,
    String? note,
  }) async {
    if (fromAccountId == toAccountId) {
      throw Exception('Source and destination accounts must be different.');
    }
    if (amountPaise <= 0) {
      throw Exception('Transfer amount must be strictly greater than zero.');
    }

    final Database db = await database;
    final DateTime now = DateTime.now();
    final String cleanNote = note != null ? note.trim() : '';

    await db.transaction((Transaction txn) async {
      // Delete old transfer legs for this group
      await txn.delete(
        'transactions',
        where: 'transferGroupId = ?',
        whereArgs: <Object>[transferGroupId],
      );

      // Re-insert new legs atomically
      final TransactionItem transferOut = TransactionItem(
        id: '${transferGroupId}_out',
        accountId: fromAccountId,
        categoryId: null,
        transactionType: TransactionType.transferOut,
        amountPaise: amountPaise,
        transactionDate: date,
        note: cleanNote.isNotEmpty ? cleanNote : null,
        transferGroupId: transferGroupId,
        createdAt: now,
        updatedAt: now,
      );

      final TransactionItem transferIn = TransactionItem(
        id: '${transferGroupId}_in',
        accountId: toAccountId,
        categoryId: null,
        transactionType: TransactionType.transferIn,
        amountPaise: amountPaise,
        transactionDate: date,
        note: cleanNote.isNotEmpty ? cleanNote : null,
        transferGroupId: transferGroupId,
        createdAt: now,
        updatedAt: now,
      );

      await txn.insert('transactions', transferOut.toMap());
      await txn.insert('transactions', transferIn.toMap());
    });
  }

  /// Deletes a transaction. If it is part of a transfer group, deletes both sides atomically.
  Future<void> deleteTransaction(TransactionItem item) async {
    final Database db = await database;
    if (item.transferGroupId != null && item.transferGroupId!.isNotEmpty) {
      await db.delete(
        'transactions',
        where: 'transferGroupId = ?',
        whereArgs: <Object>[item.transferGroupId!],
      );
    } else {
      await db.delete(
        'transactions',
        where: 'id = ?',
        whereArgs: <Object>[item.id],
      );
    }
  }

  /// Fetches transactions with joined category and account details for clear UI presentation.
  Future<List<TransactionItem>> getTransactions({
    String? accountId,
    String? categoryId,
    TransactionType? type,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
    String orderBy = 't.transactionDate DESC, t.createdAt DESC',
  }) async {
    final Database db = await database;

    final List<String> whereClauses = <String>[];
    final List<Object> whereArgs = <Object>[];

    if (accountId != null && accountId.isNotEmpty) {
      whereClauses.add('t.accountId = ?');
      whereArgs.add(accountId);
    }

    if (categoryId != null && categoryId.isNotEmpty) {
      whereClauses.add('t.categoryId = ?');
      whereArgs.add(categoryId);
    }

    if (type != null) {
      whereClauses.add('t.transactionType = ?');
      whereArgs.add(type.dbValue);
    }

    if (startDate != null) {
      whereClauses.add('t.transactionDate >= ?');
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      whereClauses.add('t.transactionDate <= ?');
      whereArgs.add(endDate.toIso8601String());
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final String wildcard = '%${searchQuery.trim().toLowerCase()}%';
      whereClauses.add(
          '(LOWER(t.note) LIKE ? OR LOWER(c.name) LIKE ? OR LOWER(a.name) LIKE ?)');
      whereArgs.addAll(<Object>[wildcard, wildcard, wildcard]);
    }

    final String whereSql =
        whereClauses.isNotEmpty ? 'WHERE ${whereClauses.join(' AND ')}' : '';

    final String query = '''
      SELECT 
        t.*,
        a.name AS accountName,
        c.name AS categoryName,
        c.iconKey AS categoryIconKey,
        c.colorValue AS categoryColorValue
      FROM transactions t
      LEFT JOIN accounts a ON t.accountId = a.id
      LEFT JOIN categories c ON t.categoryId = c.id
      $whereSql
      ORDER BY $orderBy
    ''';

    final List<Map<String, dynamic>> results =
        await db.rawQuery(query, whereArgs);
    return results
        .map((Map<String, dynamic> row) => TransactionItem.fromMap(row))
        .toList();
  }

  // ==========================================
  // MONTHLY FINANCIAL AGGREGATIONS
  // ==========================================

  /// Calculates total income and expenses for a specific month.
  /// Explicitly excludes transfers (transfer_out, transfer_in) from calculations.
  Future<Map<String, int>> getMonthlyTotals(
      DateTime startOfMonth, DateTime startOfNextMonth) async {
    final Database db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT 
        COALESCE(SUM(CASE WHEN transactionType = 'income' THEN amountPaise ELSE 0 END), 0) AS totalIncome,
        COALESCE(SUM(CASE WHEN transactionType = 'expense' THEN amountPaise ELSE 0 END), 0) AS totalExpense
      FROM transactions
      WHERE transactionDate >= ? AND transactionDate < ?
    ''', <Object>[
      startOfMonth.toIso8601String(),
      startOfNextMonth.toIso8601String()
    ]);

    if (result.isEmpty) {
      return <String, int>{'income': 0, 'expense': 0, 'net': 0};
    }

    final int income = result.first['totalIncome'] as int? ?? 0;
    final int expense = result.first['totalExpense'] as int? ?? 0;
    return <String, int>{
      'income': income,
      'expense': expense,
      'net': income - expense,
    };
  }

  /// Calculates total spending grouped by expense category for a given month.
  Future<List<Map<String, dynamic>>> getCategorySpendingForMonth(
      DateTime startOfMonth, DateTime startOfNextMonth) async {
    final Database db = await database;
    final List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT 
        c.id AS categoryId,
        c.name AS categoryName,
        c.iconKey AS iconKey,
        c.colorValue AS colorValue,
        COALESCE(SUM(t.amountPaise), 0) AS spentPaise
      FROM categories c
      INNER JOIN transactions t ON t.categoryId = c.id
      WHERE t.transactionType = 'expense'
        AND t.transactionDate >= ? 
        AND t.transactionDate < ?
      GROUP BY c.id, c.name, c.iconKey, c.colorValue
      ORDER BY spentPaise DESC
    ''', <Object>[
      startOfMonth.toIso8601String(),
      startOfNextMonth.toIso8601String()
    ]);

    return results;
  }

  /// Calculates daily expense amounts for a given month (for trends and charts).
  Future<Map<int, int>> getDailySpendingForMonth(
      DateTime startOfMonth, DateTime startOfNextMonth) async {
    final Database db = await database;
    final List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT 
        t.transactionDate,
        t.amountPaise
      FROM transactions t
      WHERE t.transactionType = 'expense'
        AND t.transactionDate >= ?
        AND t.transactionDate < ?
      ORDER BY t.transactionDate ASC
    ''', <Object>[
      startOfMonth.toIso8601String(),
      startOfNextMonth.toIso8601String()
    ]);

    final Map<int, int> dailyTotals = <int, int>{};
    for (final Map<String, dynamic> row in results) {
      final DateTime date = DateTime.parse(row['transactionDate'] as String);
      final int amount = row['amountPaise'] as int;
      dailyTotals[date.day] = (dailyTotals[date.day] ?? 0) + amount;
    }

    return dailyTotals;
  }

  // ==========================================
  // BUDGETS
  // ==========================================

  Future<List<Budget>> getBudgetsForMonth(int month, int year) async {
    final Database db = await database;
    final String startIso = DateTime(year, month, 1, 0, 0, 0).toIso8601String();
    final String nextMonthIso =
        DateTime(year, month + 1, 1, 0, 0, 0).toIso8601String();

    final List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT 
        b.id,
        b.categoryId,
        b.month,
        b.year,
        b.limitPaise,
        c.name AS categoryName,
        c.iconKey AS categoryIconKey,
        c.colorValue AS categoryColorValue,
        COALESCE((
          SELECT SUM(t.amountPaise)
          FROM transactions t
          WHERE t.categoryId = b.categoryId
            AND t.transactionType = 'expense'
            AND t.transactionDate >= ?
            AND t.transactionDate < ?
        ), 0) AS spentPaise
      FROM budgets b
      INNER JOIN categories c ON b.categoryId = c.id
      WHERE b.month = ? AND b.year = ?
      ORDER BY b.limitPaise DESC
    ''', <Object>[startIso, nextMonthIso, month, year]);

    return results.map((Map<String, dynamic> r) {
      return Budget.fromMap(r, spentPaise: r['spentPaise'] as int? ?? 0);
    }).toList();
  }

  Future<void> setBudget(Budget budget) async {
    final Database db = await database;
    await db.insert(
      'budgets',
      budget.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteBudget(String budgetId) async {
    final Database db = await database;
    await db.delete('budgets', where: 'id = ?', whereArgs: <Object>[budgetId]);
  }

  /// Copies budgets from the previous month to the target month without overwriting existing budgets.
  Future<int> copyBudgetsFromPreviousMonth({
    required int targetMonth,
    required int targetYear,
  }) async {
    final int prevMonth = targetMonth == 1 ? 12 : targetMonth - 1;
    final int prevYear = targetMonth == 1 ? targetYear - 1 : targetYear;

    final Database db = await database;
    final List<Map<String, dynamic>> prevBudgets = await db.query(
      'budgets',
      where: 'month = ? AND year = ?',
      whereArgs: <Object>[prevMonth, prevYear],
    );

    if (prevBudgets.isEmpty) return 0;

    int copiedCount = 0;
    await db.transaction((Transaction txn) async {
      for (final Map<String, dynamic> row in prevBudgets) {
        final String categoryId = row['categoryId'] as String;
        final int limitPaise = row['limitPaise'] as int;

        // Check if already exists in target month
        final List<Map<String, dynamic>> existing = await txn.query(
          'budgets',
          where: 'categoryId = ? AND month = ? AND year = ?',
          whereArgs: <Object>[categoryId, targetMonth, targetYear],
        );

        if (existing.isEmpty) {
          final String newId = 'bgt_${targetYear}_${targetMonth}_$categoryId';
          await txn.insert('budgets', <String, dynamic>{
            'id': newId,
            'categoryId': categoryId,
            'month': targetMonth,
            'year': targetYear,
            'limitPaise': limitPaise,
          });
          copiedCount++;
        }
      }
    });

    return copiedCount;
  }

  // ==========================================
  // APP PREFERENCES
  // ==========================================

  Future<String?> getPreference(String key) async {
    final Database db = await database;
    final List<Map<String, dynamic>> results = await db.query(
      'app_preferences',
      where: 'key = ?',
      whereArgs: <Object>[key],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return results.first['value'] as String?;
  }

  Future<void> setPreference(String key, String value) async {
    final Database db = await database;
    await db.insert(
      'app_preferences',
      <String, dynamic>{'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ==========================================
  // RESET / CLEAR ALL DATA
  // ==========================================

  Future<void> clearAllData() async {
    final Database db = await database;
    await db.transaction((Transaction txn) async {
      await txn.delete('transactions');
      await txn.delete('budgets');
      await txn.delete('accounts');
      await txn.delete('categories');
      await txn.delete('app_preferences');

      // Re-seed default categories
      await _seedDefaultCategories(txn);
    });
  }
}
