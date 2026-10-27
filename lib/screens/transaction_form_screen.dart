import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/account.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../providers/finance_provider.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_helper.dart';
import '../widgets/category_icon.dart';
import '../widgets/confirm_dialog.dart';

/// Screen for creating or editing income, expense, and account transfer entries.
/// Enforces form validation, duplicate save prevention, and discard change confirmations.
class TransactionFormScreen extends StatefulWidget {
  final TransactionItem? transactionToEdit;
  final TransactionType initialType;
  final String? initialAccountId;

  const TransactionFormScreen({
    super.key,
    this.transactionToEdit,
    this.initialType = TransactionType.expense,
    this.initialAccountId,
  });

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late TransactionType _selectedType;
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  late DateTime _selectedDate;

  String? _selectedAccountId;
  String? _selectedToAccountId; // Used only for transfers
  String? _selectedCategoryId;

  bool _isSaving = false;
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();

    final TransactionItem? edit = widget.transactionToEdit;
    if (edit != null) {
      _selectedType = edit.transactionType;
      _amountController = TextEditingController(
        text: CurrencyFormatter.paiseToEditableString(edit.amountPaise),
      );
      _noteController = TextEditingController(text: edit.note ?? '');
      _selectedDate = edit.transactionDate;
      _selectedAccountId = edit.accountId;
      _selectedCategoryId = edit.categoryId;
    } else {
      _selectedType = widget.initialType;
      _amountController = TextEditingController();
      _noteController = TextEditingController();
      _selectedDate = DateTime.now();
      _selectedAccountId = widget.initialAccountId;
    }

    _amountController.addListener(_markDirty);
    _noteController.addListener(_markDirty);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final FinanceProvider finance = context.read<FinanceProvider>();

      if (edit != null && edit.isTransfer && edit.transferGroupId != null) {
        final List<TransactionItem> legs =
            await finance.getTransferLegs(edit.transferGroupId!);
        if (legs.isNotEmpty && mounted) {
          final TransactionItem? outLeg =
              legs.cast<TransactionItem?>().firstWhere(
                    (TransactionItem? l) =>
                        l?.transactionType == TransactionType.transferOut,
                    orElse: () => null,
                  );
          final TransactionItem? inLeg =
              legs.cast<TransactionItem?>().firstWhere(
                    (TransactionItem? l) =>
                        l?.transactionType == TransactionType.transferIn,
                    orElse: () => null,
                  );
          setState(() {
            if (outLeg != null) _selectedAccountId = outLeg.accountId;
            if (inLeg != null) _selectedToAccountId = inLeg.accountId;
            if (outLeg?.note != null) _noteController.text = outLeg!.note!;
          });
        }
      } else {
        if (_selectedAccountId == null && finance.accounts.isNotEmpty) {
          setState(() => _selectedAccountId = finance.accounts.first.id);
        }
        if (_selectedCategoryId == null) {
          final IncomeExpenseType targetType =
              _selectedType == TransactionType.income
                  ? IncomeExpenseType.income
                  : IncomeExpenseType.expense;
          final List<Category> available = finance.categories
              .where((Category c) =>
                  c.incomeOrExpense == targetType && !c.isArchived)
              .toList();
          if (available.isNotEmpty) {
            setState(() => _selectedCategoryId = available.first.id);
          }
        }
      }
    });
  }

  void _markDirty() {
    if (!_isDirty) {
      setState(() => _isDirty = true);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Select Transaction Date',
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _isDirty = true;
      });
    }
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;

    final int? amountPaise =
        CurrencyFormatter.parseToPaise(_amountController.text);
    if (amountPaise == null || amountPaise <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter an amount greater than zero.')),
      );
      return;
    }

    if (_selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an account.')),
      );
      return;
    }

    final FinanceProvider provider = context.read<FinanceProvider>();
    setState(() => _isSaving = true);

    try {
      if (_selectedType == TransactionType.transferOut ||
          _selectedType == TransactionType.transferIn) {
        if (_selectedToAccountId == null) {
          throw Exception('Please select destination account.');
        }
        if (_selectedAccountId == _selectedToAccountId) {
          throw Exception('Source and destination accounts must be different.');
        }

        if (widget.transactionToEdit != null &&
            widget.transactionToEdit!.transferGroupId != null) {
          await provider.updateTransfer(
            transferGroupId: widget.transactionToEdit!.transferGroupId!,
            fromAccountId: _selectedAccountId!,
            toAccountId: _selectedToAccountId!,
            amountPaise: amountPaise,
            date: _selectedDate,
            note: _noteController.text.trim(),
          );
        } else {
          await provider.addTransfer(
            fromAccountId: _selectedAccountId!,
            toAccountId: _selectedToAccountId!,
            amountPaise: amountPaise,
            date: _selectedDate,
            note: _noteController.text.trim(),
          );
        }
      } else {
        // Income or Expense
        if (_selectedCategoryId == null) {
          throw Exception('Please select a category.');
        }

        if (widget.transactionToEdit != null) {
          final TransactionItem updated = widget.transactionToEdit!.copyWith(
            accountId: _selectedAccountId!,
            categoryId: _selectedCategoryId!,
            transactionType: _selectedType,
            amountPaise: amountPaise,
            transactionDate: _selectedDate,
            note: _noteController.text.trim().isEmpty
                ? null
                : _noteController.text.trim(),
          );
          await provider.updateTransaction(updated);
        } else {
          await provider.addTransaction(
            accountId: _selectedAccountId!,
            categoryId: _selectedCategoryId!,
            type: _selectedType,
            amountPaise: amountPaise,
            date: _selectedDate,
            note: _noteController.text.trim().isEmpty
                ? null
                : _noteController.text.trim(),
          );
        }
      }

      if (mounted) {
        setState(() => _isDirty = false);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.transactionToEdit != null
                  ? 'Transaction updated'
                  : 'Transaction saved',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (!_isDirty) return true;

    return await ConfirmDialog.show(
      context: context,
      title: 'Discard Changes?',
      message:
          'You have unsaved changes. Are you sure you want to discard them?',
      cancelLabel: 'Keep Editing',
      confirmLabel: 'Discard',
      isDestructive: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isEditing = widget.transactionToEdit != null;
    final bool isTransfer = _selectedType == TransactionType.transferOut ||
        _selectedType == TransactionType.transferIn;

    return PopScope(
      canPop: !_isDirty,
      onPopInvoked: (bool didPop) async {
        if (didPop) return;
        final bool shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          setState(() => _isDirty = false);
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEditing ? 'Edit Transaction' : 'Add Transaction'),
        ),
        body: Consumer<FinanceProvider>(
          builder:
              (BuildContext context, FinanceProvider finance, Widget? child) {
            final List<Account> accounts = finance.accounts;

            // Exclude archived categories from new selection unless already assigned
            final IncomeExpenseType activeIncomeOrExpense =
                _selectedType == TransactionType.income
                    ? IncomeExpenseType.income
                    : IncomeExpenseType.expense;

            final List<Category> availableCategories =
                finance.categories.where((Category cat) {
              if (cat.incomeOrExpense != activeIncomeOrExpense) return false;
              if (cat.isArchived && cat.id != _selectedCategoryId) return false;
              return true;
            }).toList();

            return Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: <Widget>[
                  // Type Selector (Segmented buttons)
                  if (!isEditing) ...<Widget>[
                    SegmentedButton<TransactionType>(
                      segments: const <ButtonSegment<TransactionType>>[
                        ButtonSegment<TransactionType>(
                          value: TransactionType.expense,
                          label: Text('Expense'),
                          icon: Icon(Icons.arrow_downward, color: Colors.red),
                        ),
                        ButtonSegment<TransactionType>(
                          value: TransactionType.income,
                          label: Text('Income'),
                          icon: Icon(Icons.arrow_upward, color: Colors.green),
                        ),
                        ButtonSegment<TransactionType>(
                          value: TransactionType.transferOut,
                          label: Text('Transfer'),
                          icon: Icon(Icons.swap_horiz, color: Colors.blue),
                        ),
                      ],
                      selected: <TransactionType>{_selectedType},
                      onSelectionChanged: (Set<TransactionType> newSelection) {
                        setState(() {
                          _selectedType = newSelection.first;
                          _selectedCategoryId = null;
                          _isDirty = true;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Amount Field
                  TextFormField(
                    controller: _amountController,
                    decoration: InputDecoration(
                      labelText: 'Amount (INR)',
                      prefixText: '₹ ',
                      prefixStyle: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      filled: true,
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                    validator: (String? value) {
                      final int? parsed = CurrencyFormatter.parseToPaise(value);
                      if (parsed == null) {
                        return 'Enter a valid amount greater than 0';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Account Picker
                  DropdownButtonFormField<String>(
                    value: _selectedAccountId,
                    decoration: InputDecoration(
                      labelText: isTransfer ? 'From Account' : 'Account',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.account_balance_outlined),
                    ),
                    items: accounts.map((Account acc) {
                      return DropdownMenuItem<String>(
                        value: acc.id,
                        child: Text(acc.name),
                      );
                    }).toList(),
                    onChanged: (String? val) {
                      if (val != null) {
                        setState(() {
                          _selectedAccountId = val;
                          _isDirty = true;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Destination Account Picker (for Transfers)
                  if (isTransfer) ...<Widget>[
                    DropdownButtonFormField<String>(
                      value: _selectedToAccountId,
                      decoration: InputDecoration(
                        labelText: 'To Account',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        prefixIcon:
                            const Icon(Icons.account_balance_wallet_outlined),
                      ),
                      items: accounts
                          .where((Account acc) => acc.id != _selectedAccountId)
                          .map((Account acc) {
                        return DropdownMenuItem<String>(
                          value: acc.id,
                          child: Text(acc.name),
                        );
                      }).toList(),
                      onChanged: (String? val) {
                        if (val != null) {
                          setState(() {
                            _selectedToAccountId = val;
                            _isDirty = true;
                          });
                        }
                      },
                      validator: (String? val) {
                        if (val == null || val.isEmpty) {
                          return 'Please select destination account';
                        }
                        if (val == _selectedAccountId) {
                          return 'Source and destination cannot be identical';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Category Picker (for Income / Expense)
                  if (!isTransfer) ...<Widget>[
                    DropdownButtonFormField<String>(
                      value: _selectedCategoryId,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.category_outlined),
                      ),
                      items: availableCategories.map((Category cat) {
                        return DropdownMenuItem<String>(
                          value: cat.id,
                          child: Row(
                            children: <Widget>[
                              CategoryIcon(
                                iconData: cat.iconData,
                                color: cat.color,
                                size: 24,
                              ),
                              const SizedBox(width: 10),
                              Text(cat.name),
                              if (cat.isArchived)
                                const Text(
                                  ' (Archived)',
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 11),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (String? val) {
                        if (val != null) {
                          setState(() {
                            _selectedCategoryId = val;
                            _isDirty = true;
                          });
                        }
                      },
                      validator: (String? val) {
                        if (val == null || val.isEmpty) {
                          return 'Please select a category';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Date Picker Field
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Date',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.calendar_today_outlined),
                      ),
                      child: Text(
                        DateHelper.formatFullDate(_selectedDate),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Optional Note Field
                  TextFormField(
                    controller: _noteController,
                    decoration: InputDecoration(
                      labelText: 'Note (Optional)',
                      hintText: 'e.g. Dinner with team, monthly wifi bill',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.notes_outlined),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 32),

                  // Submit Button
                  FilledButton(
                    onPressed: _isSaving ? null : _saveTransaction,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            isEditing ? 'Save Changes' : 'Record Transaction',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
