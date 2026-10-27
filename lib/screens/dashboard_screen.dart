import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/budget.dart';
import '../models/transaction.dart';
import '../providers/finance_provider.dart';
import '../utils/currency_formatter.dart';
import '../widgets/category_icon.dart';
import '../widgets/month_selector_header.dart';
import '../widgets/summary_card.dart';
import '../widgets/transaction_list_item.dart';
import 'accounts_screen.dart';
import 'budgets_screen.dart';
import 'transaction_form_screen.dart';
import 'transactions_screen.dart';

/// The central dashboard screen showcasing current net worth, monthly cash flow metrics,
/// interactive spending chart, active budget warnings, and recent activity.
class DashboardScreen extends StatelessWidget {
  final ValueChanged<int>? onNavigateTab;

  const DashboardScreen({
    super.key,
    this.onNavigateTab,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PocketLedger'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.account_balance_outlined),
            tooltip: 'Manage Accounts',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const AccountsScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<FinanceProvider>(
        builder:
            (BuildContext context, FinanceProvider finance, Widget? child) {
          final int income = finance.monthlyIncome;
          final int expense = finance.monthlyExpense;
          final int net = finance.monthlyNet;
          final int netWorth = finance.totalNetWorth;
          final List<TransactionItem> allTxs = finance.allTransactions;
          final List<Map<String, dynamic>> categorySpend =
              finance.categorySpending;
          final Map<int, int> dailySpend = finance.dailySpending;
          final List<Budget> budgets = finance.budgets;

          // Find critical budget warnings (>= 80% used)
          final List<Budget> warningBudgets =
              budgets.where((Budget b) => b.percentageSpent >= 80.0).toList();

          final List<TransactionItem> recentTxs = allTxs.take(5).toList();

          return ListView(
            padding: const EdgeInsets.only(bottom: 80),
            children: <Widget>[
              // Month Selector Bar
              MonthSelectorHeader(
                selectedMonth: finance.selectedMonth,
                onMonthChanged: (DateTime newMonth) {
                  finance.setSelectedMonth(newMonth);
                },
              ),

              // Total Net Worth Card
              Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[
                      theme.colorScheme.primary,
                      theme.colorScheme.primary
                          .withBlue(theme.colorScheme.primary.blue + 35),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                          builder: (_) => const AccountsScreen()),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            'TOTAL NET BALANCE',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color:
                                  theme.colorScheme.onPrimary.withOpacity(0.8),
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: theme.colorScheme.onPrimary.withOpacity(0.8),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        CurrencyFormatter.formatPaise(netWorth),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap to inspect accounts & balances',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimary.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Monthly Summary Cards (Income, Expense, Net)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: SummaryCard(
                        title: 'Income',
                        amountText: CurrencyFormatter.formatPaise(income),
                        icon: Icons.arrow_upward_rounded,
                        iconColor: const Color(0xFF10B981),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const TransactionsScreen(
                                initialTypeFilter: TransactionType.income,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SummaryCard(
                        title: 'Expenses',
                        amountText: CurrencyFormatter.formatPaise(expense),
                        icon: Icons.arrow_downward_rounded,
                        iconColor: const Color(0xFFDC2626),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const TransactionsScreen(
                                initialTypeFilter: TransactionType.expense,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SummaryCard(
                        title: 'Savings',
                        amountText: CurrencyFormatter.formatPaise(net),
                        icon: Icons.savings_outlined,
                        iconColor: net >= 0
                            ? const Color(0xFF10B981)
                            : const Color(0xFFDC2626),
                      ),
                    ),
                  ],
                ),
              ),

              // Budget Alerts Banner
              if (warningBudgets.isNotEmpty) ...<Widget>[
                Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: const Color(0xFFDC2626).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: <Widget>[
                      const Icon(Icons.warning_amber_rounded,
                          color: Color(0xFFDC2626), size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${warningBudgets.length} budget(s) are near or over limit!',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFFDC2626),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          if (onNavigateTab != null) {
                            onNavigateTab!(2); // Navigate to Budgets tab
                          } else {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                  builder: (_) => const BudgetsScreen()),
                            );
                          }
                        },
                        child: const Text('Review',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ],

              // Monthly Spending Flow (Bar Chart)
              if (dailySpend.isNotEmpty) ...<Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'MONTHLY SPENDING PATTERN',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurfaceVariant,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(
                      color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Daily Outflow',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 120,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: _calcMaxDaily(dailySpend) * 1.2,
                              barTouchData: BarTouchData(
                                enabled: true,
                                touchTooltipData: BarTouchTooltipData(
                                  getTooltipItem: (
                                    BarChartGroupData group,
                                    int groupIndex,
                                    BarChartRodData rod,
                                    int rodIndex,
                                  ) {
                                    return BarTooltipItem(
                                      'Day ${group.x}\n${CurrencyFormatter.formatPaise(rod.toY.toInt())}',
                                      const TextStyle(
                                          color: Colors.white, fontSize: 11),
                                    );
                                  },
                                ),
                              ),
                              titlesData: const FlTitlesData(
                                leftTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                                rightTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                                topTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                                bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                              ),
                              borderData: FlBorderData(show: false),
                              gridData: const FlGridData(show: false),
                              barGroups:
                                  List<BarChartGroupData>.generate(31, (int i) {
                                final int day = i + 1;
                                final int paise = dailySpend[day] ?? 0;
                                return BarChartGroupData(
                                  x: day,
                                  barRods: <BarChartRodData>[
                                    BarChartRodData(
                                      toY: paise.toDouble(),
                                      color: paise > 0
                                          ? theme.colorScheme.primary
                                          : Colors.transparent,
                                      width: 4.5,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ],
                                );
                              }),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // Top Spending Categories
              if (categorySpend.isNotEmpty) ...<Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'TOP SPENDING CATEGORIES',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurfaceVariant,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(
                      color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children:
                          categorySpend.take(4).map((Map<String, dynamic> row) {
                        final int spent = row['spentPaise'] as int;
                        final double percent =
                            expense > 0 ? (spent / expense) : 0.0;
                        final Color color =
                            Color(row['colorValue'] as int? ?? 0xFF64748B);
                        final IconData icon =
                            _getIconData(row['iconKey'] as String?);

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  CategoryIcon(
                                      iconData: icon, color: color, size: 28),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      row['categoryName'] as String,
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    CurrencyFormatter.formatPaise(spent),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: percent.clamp(0.0, 1.0),
                                  minHeight: 5,
                                  backgroundColor:
                                      theme.colorScheme.surfaceContainerHighest,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(color),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],

              // Recent Transactions Section
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      'RECENT ACTIVITY',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurfaceVariant,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (allTxs.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          if (onNavigateTab != null) {
                            onNavigateTab!(1); // Go to Transactions tab
                          } else {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                  builder: (_) => const TransactionsScreen()),
                            );
                          }
                        },
                        child: const Text('View All'),
                      ),
                  ],
                ),
              ),

              if (recentTxs.isEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text('No transactions recorded yet.'),
                  ),
                )
              else
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(
                      color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                    ),
                  ),
                  child: Column(
                    children: recentTxs.map((TransactionItem item) {
                      return Column(
                        children: <Widget>[
                          TransactionListItem(
                            item: item,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => TransactionFormScreen(
                                      transactionToEdit: item),
                                ),
                              );
                            },
                          ),
                          if (item != recentTxs.last)
                            Divider(
                              height: 1,
                              indent: 68,
                              color: theme.colorScheme.outlineVariant
                                  .withOpacity(0.3),
                            ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const TransactionFormScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  double _calcMaxDaily(Map<int, int> map) {
    if (map.isEmpty) return 100000.0;
    int max = 0;
    for (final int v in map.values) {
      if (v > max) max = v;
    }
    return max <= 0 ? 100000.0 : max.toDouble();
  }

  static IconData _getIconData(String? key) {
    switch (key) {
      case 'work':
        return Icons.work_outline;
      case 'laptop':
        return Icons.laptop_mac;
      case 'trending_up':
        return Icons.trending_up;
      case 'card_giftcard':
        return Icons.card_giftcard;
      case 'wallet':
        return Icons.account_balance_wallet_outlined;
      case 'restaurant':
        return Icons.restaurant;
      case 'home':
        return Icons.home_outlined;
      case 'lightbulb':
        return Icons.lightbulb_outline;
      case 'directions_car':
        return Icons.directions_car_outlined;
      case 'shopping_bag':
        return Icons.shopping_bag_outlined;
      case 'movie':
        return Icons.movie_outlined;
      case 'local_hospital':
        return Icons.local_hospital_outlined;
      case 'school':
        return Icons.school_outlined;
      case 'spa':
        return Icons.spa_outlined;
      default:
        return Icons.category_outlined;
    }
  }
}
