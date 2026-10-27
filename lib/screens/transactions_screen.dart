import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/account.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../providers/finance_provider.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_helper.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/transaction_list_item.dart';
import 'transaction_form_screen.dart';

enum SortOption {
  newestFirst,
  oldestFirst,
  highestAmount,
  lowestAmount;

  String get displayName {
    switch (this) {
      case SortOption.newestFirst:
        return 'Newest First';
      case SortOption.oldestFirst:
        return 'Oldest First';
      case SortOption.highestAmount:
        return 'Highest Amount';
      case SortOption.lowestAmount:
        return 'Lowest Amount';
    }
  }
}

/// Screen displaying transaction history with real-time search, multi-factor filtering,
/// sort options, and date-based group headers.
class TransactionsScreen extends StatefulWidget {
  final TransactionType? initialTypeFilter;

  const TransactionsScreen({
    super.key,
    this.initialTypeFilter,
  });

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  TransactionType? _typeFilter;
  String? _accountFilter;
  String? _categoryFilter;
  SortOption _currentSort = SortOption.newestFirst;

  @override
  void initState() {
    super.initState();
    _typeFilter = widget.initialTypeFilter;
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _typeFilter = null;
      _accountFilter = null;
      _categoryFilter = null;
      _currentSort = SortOption.newestFirst;
    });
  }

  void _showFilterSheet(BuildContext context, FinanceProvider finance) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      const Text(
                        'Filter Transactions',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () {
                          _clearFilters();
                          Navigator.of(ctx).pop();
                        },
                        child: const Text('Reset All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String?>(
                    value: _accountFilter,
                    decoration: const InputDecoration(
                      labelText: 'Account',
                      border: OutlineInputBorder(),
                    ),
                    items: <DropdownMenuItem<String?>>[
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All Accounts'),
                      ),
                      ...finance.accounts.map((Account acc) {
                        return DropdownMenuItem<String?>(
                          value: acc.id,
                          child: Text(acc.name),
                        );
                      }),
                    ],
                    onChanged: (String? val) {
                      setModalState(() => _accountFilter = val);
                      setState(() => _accountFilter = val);
                    },
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String?>(
                    value: _categoryFilter,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items: <DropdownMenuItem<String?>>[
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All Categories'),
                      ),
                      ...finance.categories.map((Category cat) {
                        return DropdownMenuItem<String?>(
                          value: cat.id,
                          child: Text(cat.name),
                        );
                      }),
                    ],
                    onChanged: (String? val) {
                      setModalState(() => _categoryFilter = val);
                      setState(() => _categoryFilter = val);
                    },
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<SortOption>(
                    value: _currentSort,
                    decoration: const InputDecoration(
                      labelText: 'Sort Order',
                      border: OutlineInputBorder(),
                    ),
                    items: SortOption.values.map((SortOption sort) {
                      return DropdownMenuItem<SortOption>(
                        value: sort,
                        child: Text(sort.displayName),
                      );
                    }).toList(),
                    onChanged: (SortOption? val) {
                      if (val != null) {
                        setModalState(() => _currentSort = val);
                        setState(() => _currentSort = val);
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Apply Filters'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.tune_outlined),
            tooltip: 'Filter & Sort',
            onPressed: () =>
                _showFilterSheet(context, context.read<FinanceProvider>()),
          ),
        ],
      ),
      body: Consumer<FinanceProvider>(
        builder:
            (BuildContext context, FinanceProvider finance, Widget? child) {
          final List<TransactionItem> all = finance.allTransactions;

          if (all.isEmpty) {
            return EmptyStateView(
              icon: Icons.receipt_long_outlined,
              title: 'No Transactions Yet',
              message: 'Add an income, expense, or transfer between accounts.',
              actionLabel: 'Add Transaction',
              onAction: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const TransactionFormScreen(),
                  ),
                );
              },
            );
          }

          // Apply filters
          List<TransactionItem> filtered = all.where((TransactionItem t) {
            // Type filter
            if (_typeFilter != null) {
              if (_typeFilter == TransactionType.transferOut ||
                  _typeFilter == TransactionType.transferIn) {
                if (!t.isTransfer) return false;
              } else if (t.transactionType != _typeFilter) {
                return false;
              }
            }

            // Account filter
            if (_accountFilter != null && t.accountId != _accountFilter) {
              return false;
            }

            // Category filter
            if (_categoryFilter != null && t.categoryId != _categoryFilter) {
              return false;
            }

            // Search query (notes, category name, account name)
            if (_searchQuery.isNotEmpty) {
              final String note = (t.note ?? '').toLowerCase();
              final String cat = (t.categoryName ?? '').toLowerCase();
              final String acc = (t.accountName ?? '').toLowerCase();
              if (!note.contains(_searchQuery) &&
                  !cat.contains(_searchQuery) &&
                  !acc.contains(_searchQuery)) {
                return false;
              }
            }

            return true;
          }).toList();

          // Apply sorting
          filtered.sort((TransactionItem a, TransactionItem b) {
            switch (_currentSort) {
              case SortOption.newestFirst:
                return b.transactionDate.compareTo(a.transactionDate);
              case SortOption.oldestFirst:
                return a.transactionDate.compareTo(b.transactionDate);
              case SortOption.highestAmount:
                return b.amountPaise.compareTo(a.amountPaise);
              case SortOption.lowestAmount:
                return a.amountPaise.compareTo(b.amountPaise);
            }
          });

          // Group by Date
          final Map<String, List<TransactionItem>> grouped =
              <String, List<TransactionItem>>{};
          for (final TransactionItem item in filtered) {
            final String dateKey = DateHelper.toIsoDate(item.transactionDate);
            grouped.putIfAbsent(dateKey, () => <TransactionItem>[]).add(item);
          }

          final List<String> sortedGroupKeys = grouped.keys.toList();

          return Column(
            children: <Widget>[
              // Search Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: SearchBar(
                  controller: _searchController,
                  hintText: 'Search note, category, or account...',
                  leading: const Icon(Icons.search, size: 20),
                  trailing: _searchQuery.isNotEmpty
                      ? <Widget>[
                          IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => _searchController.clear(),
                          ),
                        ]
                      : null,
                  elevation: const WidgetStatePropertyAll<double>(0),
                  shape: WidgetStatePropertyAll<OutlinedBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color:
                            theme.colorScheme.outlineVariant.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
              ),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: <Widget>[
                    FilterChip(
                      label: const Text('All'),
                      selected: _typeFilter == null,
                      onSelected: (_) => setState(() => _typeFilter = null),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Expenses'),
                      selected: _typeFilter == TransactionType.expense,
                      onSelected: (_) =>
                          setState(() => _typeFilter = TransactionType.expense),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Income'),
                      selected: _typeFilter == TransactionType.income,
                      onSelected: (_) =>
                          setState(() => _typeFilter = TransactionType.income),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Transfers'),
                      selected: _typeFilter == TransactionType.transferOut,
                      onSelected: (_) => setState(
                          () => _typeFilter = TransactionType.transferOut),
                    ),
                  ],
                ),
              ),

              // Transaction List or Empty Search
              Expanded(
                child: filtered.isEmpty
                    ? EmptyStateView(
                        icon: Icons.search_off_outlined,
                        title: 'No Matching Transactions',
                        message:
                            'Try adjusting your search query or reset active filters.',
                        actionLabel: 'Reset Filters',
                        onAction: _clearFilters,
                      )
                    : ListView.builder(
                        itemCount: sortedGroupKeys.length,
                        itemBuilder: (BuildContext context, int groupIndex) {
                          final String key = sortedGroupKeys[groupIndex];
                          final List<TransactionItem> dayItems = grouped[key]!;
                          final DateTime groupDate =
                              dayItems.first.transactionDate;

                          // Compute day total (expenses vs income)
                          int dayIncome = 0;
                          int dayExpense = 0;
                          for (final TransactionItem t in dayItems) {
                            if (t.transactionType == TransactionType.income) {
                              dayIncome += t.amountPaise;
                            } else if (t.transactionType ==
                                TransactionType.expense) {
                              dayExpense += t.amountPaise;
                            }
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              // Group Header
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                color: theme.colorScheme.surfaceContainerLow
                                    .withOpacity(0.5),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    Text(
                                      DateHelper.formatDateGroupHeader(
                                          groupDate),
                                      style:
                                          theme.textTheme.labelMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    if (dayExpense > 0 || dayIncome > 0)
                                      Text(
                                        'Spent: ${CurrencyFormatter.formatPaise(dayExpense)}',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                          color: theme.colorScheme.outline,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                              // Items in group
                              ...dayItems.map((TransactionItem item) {
                                return Column(
                                  children: <Widget>[
                                    TransactionListItem(
                                      item: item,
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute<void>(
                                            builder: (_) =>
                                                TransactionFormScreen(
                                              transactionToEdit: item,
                                            ),
                                          ),
                                        );
                                      },
                                      onDelete: () async {
                                        final bool confirmed =
                                            await ConfirmDialog.show(
                                          context: context,
                                          title: 'Delete Transaction',
                                          message:
                                              'Are you sure you want to delete this transaction?',
                                          confirmLabel: 'Delete',
                                          isDestructive: true,
                                        );
                                        if (confirmed && context.mounted) {
                                          await context
                                              .read<FinanceProvider>()
                                              .deleteTransaction(item);
                                        }
                                      },
                                    ),
                                    Divider(
                                      height: 1,
                                      indent: 68,
                                      color: theme.colorScheme.outlineVariant
                                          .withOpacity(0.3),
                                    ),
                                  ],
                                );
                              }),
                            ],
                          );
                        },
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
}
