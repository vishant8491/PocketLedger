import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_ledger/models/account.dart';
import 'package:pocket_ledger/models/category.dart';
import 'package:pocket_ledger/providers/finance_provider.dart';
import 'package:pocket_ledger/screens/transaction_form_screen.dart';
import 'package:pocket_ledger/services/database_service.dart';
import 'package:provider/provider.dart';

// Fake DatabaseService to provide static accounts and categories without opening native SQLite
class FakeDatabaseService extends DatabaseService {
  @override
  Future<List<Account>> getAllAccounts() async {
    return <Account>[
      Account(
        id: 'acc_test',
        name: 'Test Bank',
        accountType: AccountType.bank,
        openingBalancePaise: 100000,
        createdAt: DateTime.now(),
      ),
    ];
  }

  @override
  Future<List<Category>> getAllCategories(
      {bool includeArchived = false}) async {
    return <Category>[
      const Category(
        id: 'cat_test',
        name: 'Groceries',
        incomeOrExpense: IncomeExpenseType.expense,
        iconKey: 'restaurant',
        colorValue: 0xFF10B981,
      ),
    ];
  }
}

void main() {
  testWidgets(
      'TransactionForm shows inline validation error on empty or zero amount submission',
      (
    WidgetTester tester,
  ) async {
    final FakeDatabaseService fakeDb = FakeDatabaseService();
    final FinanceProvider financeProvider = FinanceProvider(fakeDb);
    await financeProvider.loadInitialData();

    await tester.pumpWidget(
      ChangeNotifierProvider<FinanceProvider>.value(
        value: financeProvider,
        child: const MaterialApp(
          home: TransactionFormScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify form rendered with submit button
    final Finder submitButton = find.text('Record Transaction');
    expect(submitButton, findsOneWidget);

    // Tap submit without entering an amount
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    // Check for inline validation error message
    expect(find.text('Enter a valid amount greater than 0'), findsOneWidget);

    // Now enter 0
    final Finder amountField = find.byType(TextFormField).first;
    await tester.enterText(amountField, '0');
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    // Inline validation error must still be visible
    expect(find.text('Enter a valid amount greater than 0'), findsOneWidget);
  });
}
