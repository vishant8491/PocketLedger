import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';
import '../services/database_service.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_helper.dart';
import '../widgets/category_icon.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/month_selector_header.dart';

/// Screen presenting financial analytics, category distributions, income vs expense comparisons,
/// and daily spending trends with text summaries and division-by-zero safety.
class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  int _prevMonthExpense = 0;

  @override
  void initState() {
    super.initState();
    _loadPreviousMonthData();
  }

  Future<void> _loadPreviousMonthData() async {
    final FinanceProvider finance = context.read<FinanceProvider>();
    final DateTime current = finance.selectedMonth;
    final int prevMonth = current.month == 1 ? 12 : current.month - 1;
    final int prevYear = current.month == 1 ? current.year - 1 : current.year;

    try {
      final DatabaseService db = DatabaseService();
      final DateTime start = DateHelper.startOfMonth(prevYear, prevMonth);
      final DateTime end = DateHelper.endOfMonth(prevYear, prevMonth);
      final Map<String, int> totals = await db.getMonthlyTotals(start, end);
      if (mounted) {
        setState(() {
          _prevMonthExpense = totals['expense'] ?? 0;
        });
      }
    } catch (_) {
      // Ignored
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights & Trends'),
      ),
      body: Consumer<FinanceProvider>(
        builder:
            (BuildContext context, FinanceProvider finance, Widget? child) {
          final int income = finance.monthlyIncome;
          final int expense = finance.monthlyExpense;
          final int net = finance.monthlyNet;
          final List<Map<String, dynamic>> categorySpend =
              finance.categorySpending;
          final Map<int, int> dailySpend = finance.dailySpending;

          // Safe savings rate calculation
          final double savingsRate =
              income > 0 ? ((net / income) * 100).clamp(-100.0, 100.0) : 0.0;

          // Safe previous month expense comparison
          final int expenseDifference = expense - _prevMonthExpense;
          final double expenseChangePercent = _prevMonthExpense > 0
              ? (expenseDifference / _prevMonthExpense) * 100
              : (expense > 0 ? 100.0 : 0.0);

          final bool hasData = income > 0 || expense > 0;

          return ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: <Widget>[
              MonthSelectorHeader(
                selectedMonth: finance.selectedMonth,
                onMonthChanged: (DateTime newMonth) {
                  finance.setSelectedMonth(newMonth);
                  _loadPreviousMonthData();
                },
              ),
              if (!hasData)
                const Padding(
                  padding: EdgeInsets.all(40.0),
                  child: EmptyStateView(
                    icon: Icons.insert_chart_outlined,
                    title: 'No Spending Data Yet',
                    message:
                        'Record expenses or income for this month to generate analytical breakdowns.',
                  ),
                )
              else ...<Widget>[
                // 1. Executive Summary Card
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            'MONTHLY CASH FLOW',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurfaceVariant,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: net >= 0
                                  ? const Color(0xFF10B981).withOpacity(0.15)
                                  : const Color(0xFFDC2626).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              net >= 0
                                  ? '${savingsRate.toStringAsFixed(0)}% Saved'
                                  : 'Deficit',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: net >= 0
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFDC2626),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Income',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  CurrencyFormatter.formatPaise(income),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Expenses',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  CurrencyFormatter.formatPaise(expense),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFDC2626),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Net Savings',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  CurrencyFormatter.formatPaise(net),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: net >= 0
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFDC2626),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 2. Previous Month Comparison Card
                Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: expenseDifference <= 0
                              ? const Color(0xFF10B981).withOpacity(0.12)
                              : const Color(0xFFDC2626).withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          expenseDifference <= 0
                              ? Icons.trending_down
                              : Icons.trending_up,
                          color: expenseDifference <= 0
                              ? const Color(0xFF10B981)
                              : const Color(0xFFDC2626),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Comparison to Last Month',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              expenseDifference <= 0
                                  ? 'Spent ${CurrencyFormatter.formatPaise(expenseDifference.abs())} less (${expenseChangePercent.abs().toStringAsFixed(1)}% reduction).'
                                  : 'Spent ${CurrencyFormatter.formatPaise(expenseDifference)} more (+${expenseChangePercent.toStringAsFixed(1)}% increase).',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 3. Category Spending Breakdown (Donut Chart)
                if (categorySpend.isNotEmpty) ...<Widget>[
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'SPENDING BY CATEGORY',
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
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color:
                            theme.colorScheme.outlineVariant.withOpacity(0.5),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: <Widget>[
                          SizedBox(
                            height: 180,
                            child: PieChart(
                              PieChartData(
                                sectionsSpace: 2,
                                centerSpaceRadius: 46,
                                sections: categorySpend
                                    .map((Map<String, dynamic> row) {
                                  final int spent = row['spentPaise'] as int;
                                  final double percent = expense > 0
                                      ? (spent / expense) * 100
                                      : 0.0;
                                  final Color color = Color(
                                      row['colorValue'] as int? ?? 0xFF64748B);
                                  return PieChartSectionData(
                                    color: color,
                                    value: spent.toDouble(),
                                    title: percent >= 8
                                        ? '${percent.toStringAsFixed(0)}%'
                                        : '',
                                    radius: 36,
                                    titleStyle: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...categorySpend.map((Map<String, dynamic> row) {
                            final int spent = row['spentPaise'] as int;
                            final double percent =
                                expense > 0 ? (spent / expense) * 100 : 0.0;
                            final Color color =
                                Color(row['colorValue'] as int? ?? 0xFF64748B);
                            final IconData icon =
                                _getIconData(row['iconKey'] as String?);

                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 6.0),
                              child: Row(
                                children: <Widget>[
                                  CategoryIcon(
                                      iconData: icon, color: color, size: 30),
                                  const SizedBox(width: 12),
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
                                    '${percent.toStringAsFixed(1)}%  •  ',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
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
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // 4. Daily Spending Trend (Bar Chart)
                if (dailySpend.isNotEmpty) ...<Widget>[
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'DAILY SPENDING TREND',
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
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color:
                            theme.colorScheme.outlineVariant.withOpacity(0.5),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Daily Expense Flow',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Track expenditure spikes across the calendar days of this month.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 180,
                            child: BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                maxY:
                                    _calculateMaxDailyPaise(dailySpend) * 1.15,
                                barTouchData: BarTouchData(
                                  enabled: true,
                                  touchTooltipData: BarTouchTooltipData(
                                    getTooltipItem: (
                                      BarChartGroupData group,
                                      int groupIndex,
                                      BarChartRodData rod,
                                      int rodIndex,
                                    ) {
                                      final int day = group.x;
                                      final int paise = rod.toY.toInt();
                                      return BarTooltipItem(
                                        'Day $day\n${CurrencyFormatter.formatPaise(paise)}',
                                        const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold),
                                      );
                                    },
                                  ),
                                ),
                                titlesData: FlTitlesData(
                                  leftTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget:
                                          (double value, TitleMeta meta) {
                                        final int day = value.toInt();
                                        if (day % 5 == 0 || day == 1) {
                                          return Padding(
                                            padding:
                                                const EdgeInsets.only(top: 4),
                                            child: Text(
                                              '$day',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: theme.colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                            ),
                                          );
                                        }
                                        return const SizedBox.shrink();
                                      },
                                    ),
                                  ),
                                ),
                                borderData: FlBorderData(show: false),
                                gridData: const FlGridData(show: false),
                                barGroups: List<BarChartGroupData>.generate(31,
                                    (int i) {
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
                                        width: 6,
                                        borderRadius: BorderRadius.circular(3),
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
              ],
            ],
          );
        },
      ),
    );
  }

  double _calculateMaxDailyPaise(Map<int, int> map) {
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
