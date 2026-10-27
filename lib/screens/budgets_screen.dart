import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/budget.dart';
import '../models/category.dart';
import '../providers/finance_provider.dart';
import '../utils/currency_formatter.dart';
import '../widgets/budget_progress_card.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/month_selector_header.dart';

/// Screen for tracking and setting monthly category budgets with live spending alerts.
class BudgetsScreen extends StatelessWidget {
  const BudgetsScreen({super.key});

  void _showAddOrEditBudgetDialog(
    BuildContext context, {
    Budget? budgetToEdit,
    required DateTime selectedMonth,
  }) {
    final FinanceProvider finance = context.read<FinanceProvider>();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController limitController = TextEditingController(
      text: budgetToEdit != null
          ? CurrencyFormatter.paiseToEditableString(budgetToEdit.limitPaise)
          : '',
    );

    // Only expense categories can have budgets
    final List<Category> expenseCats = finance.categories
        .where((Category c) =>
            c.incomeOrExpense == IncomeExpenseType.expense && !c.isArchived)
        .toList();

    // Existing category IDs already budgeted for this month
    final Set<String> existingCategoryIds =
        finance.budgets.map((Budget b) => b.categoryId).toSet();

    String? selectedCategoryId = budgetToEdit?.categoryId ??
        (expenseCats.any((Category c) => !existingCategoryIds.contains(c.id))
            ? expenseCats
                .firstWhere((Category c) => !existingCategoryIds.contains(c.id))
                .id
            : null);

    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return AlertDialog(
              title: Text(
                  budgetToEdit != null ? 'Edit Budget' : 'Set Category Budget'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (budgetToEdit == null) ...<Widget>[
                        DropdownButtonFormField<String>(
                          value: selectedCategoryId,
                          decoration: const InputDecoration(
                            labelText: 'Expense Category',
                            border: OutlineInputBorder(),
                          ),
                          items: expenseCats.map((Category cat) {
                            final bool isAlreadyBudgeted =
                                existingCategoryIds.contains(cat.id);
                            return DropdownMenuItem<String>(
                              value: cat.id,
                              enabled: !isAlreadyBudgeted,
                              child: Text(
                                isAlreadyBudgeted
                                    ? '${cat.name} (Budgeted)'
                                    : cat.name,
                                style: TextStyle(
                                  color: isAlreadyBudgeted ? Colors.grey : null,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? val) {
                            if (val != null) {
                              setModalState(() => selectedCategoryId = val);
                            }
                          },
                          validator: (String? val) {
                            if (val == null || val.isEmpty) {
                              return 'Please select a category';
                            }
                            if (existingCategoryIds.contains(val)) {
                              return 'Budget already exists for this category';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                      TextFormField(
                        controller: limitController,
                        decoration: const InputDecoration(
                          labelText: 'Monthly Limit (₹)',
                          prefixText: '₹ ',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        validator: (String? val) {
                          final int? parsed =
                              CurrencyFormatter.parseToPaise(val);
                          if (parsed == null || parsed <= 0) {
                            return 'Enter a limit greater than 0';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final int? limitPaise =
                        CurrencyFormatter.parseToPaise(limitController.text);
                    if (limitPaise == null || selectedCategoryId == null)
                      return;

                    await finance.setBudget(
                      categoryId: selectedCategoryId!,
                      month: selectedMonth.month,
                      year: selectedMonth.year,
                      limitPaise: limitPaise,
                    );

                    if (context.mounted) {
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Budget saved successfully')),
                      );
                    }
                  },
                  child: const Text('Save Budget'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _copyPreviousMonthBudgets(BuildContext context) async {
    final FinanceProvider finance = context.read<FinanceProvider>();
    final int copied = await finance.copyPreviousMonthBudgets();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            copied > 0
                ? 'Successfully copied $copied budget(s) from previous month.'
                : 'No new budgets found from previous month to copy.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Consumer<FinanceProvider>(
      builder: (BuildContext context, FinanceProvider finance, Widget? child) {
        final List<Budget> budgets = finance.budgets;
        final DateTime selectedMonth = finance.selectedMonth;

        int totalBudgetedPaise = 0;
        int totalSpentPaise = 0;
        for (final Budget b in budgets) {
          totalBudgetedPaise += b.limitPaise;
          totalSpentPaise += b.spentPaise;
        }
        final int remainingBudgetPaise = totalBudgetedPaise - totalSpentPaise;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Budgets'),
            actions: <Widget>[
              IconButton(
                icon: const Icon(Icons.copy_all_outlined),
                tooltip: 'Copy from Last Month',
                onPressed: () => _copyPreviousMonthBudgets(context),
              ),
            ],
          ),
          body: Column(
            children: <Widget>[
              MonthSelectorHeader(
                selectedMonth: selectedMonth,
                onMonthChanged: (DateTime newMonth) {
                  finance.setSelectedMonth(newMonth);
                },
              ),

              // Total Budget Summary Banner
              if (budgets.isNotEmpty)
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      Column(
                        children: <Widget>[
                          Text(
                            'Budgeted',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            CurrencyFormatter.formatPaise(totalBudgetedPaise),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        height: 24,
                        width: 1,
                        color:
                            theme.colorScheme.outlineVariant.withOpacity(0.5),
                      ),
                      Column(
                        children: <Widget>[
                          Text(
                            'Spent',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            CurrencyFormatter.formatPaise(totalSpentPaise),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: totalSpentPaise > totalBudgetedPaise
                                  ? Colors.red
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        height: 24,
                        width: 1,
                        color:
                            theme.colorScheme.outlineVariant.withOpacity(0.5),
                      ),
                      Column(
                        children: <Widget>[
                          Text(
                            'Remaining',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            CurrencyFormatter.formatPaise(remainingBudgetPaise),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: remainingBudgetPaise < 0
                                  ? Colors.red
                                  : const Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              Expanded(
                child: budgets.isEmpty
                    ? EmptyStateView(
                        icon: Icons.pie_chart_outline,
                        title: 'No Budgets for this Month',
                        message:
                            'Set monthly limits for your categories or copy from last month.',
                        actionLabel: 'Set Budget',
                        onAction: () => _showAddOrEditBudgetDialog(
                          context,
                          selectedMonth: selectedMonth,
                        ),
                      )
                    : ListView.builder(
                        itemCount: budgets.length,
                        itemBuilder: (BuildContext context, int index) {
                          final Budget b = budgets[index];
                          return BudgetProgressCard(
                            budget: b,
                            onEdit: () => _showAddOrEditBudgetDialog(
                              context,
                              budgetToEdit: b,
                              selectedMonth: selectedMonth,
                            ),
                            onDelete: () async {
                              final bool confirmed = await ConfirmDialog.show(
                                context: context,
                                title: 'Delete Budget',
                                message:
                                    'Are you sure you want to delete the budget for ${b.categoryName}?',
                                confirmLabel: 'Delete',
                                isDestructive: true,
                              );
                              if (confirmed && context.mounted) {
                                await finance.deleteBudget(b.id);
                              }
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddOrEditBudgetDialog(
              context,
              selectedMonth: selectedMonth,
            ),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}
