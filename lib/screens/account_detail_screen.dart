import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import '../providers/finance_provider.dart';
import '../utils/currency_formatter.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/transaction_list_item.dart';
import 'transaction_form_screen.dart';

/// Screen displaying details, balance, and isolated transaction history for a specific account.
/// Handles account editing and deletion with transaction-safety checks.
class AccountDetailScreen extends StatefulWidget {
  final Account account;

  const AccountDetailScreen({
    super.key,
    required this.account,
  });

  @override
  State<AccountDetailScreen> createState() => _AccountDetailScreenState();
}

class _AccountDetailScreenState extends State<AccountDetailScreen> {
  late Account _account;

  @override
  void initState() {
    super.initState();
    _account = widget.account;
  }

  void _showEditAccountDialog(BuildContext context) {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController nameController =
        TextEditingController(text: _account.name);
    final TextEditingController balanceController = TextEditingController(
      text:
          CurrencyFormatter.paiseToEditableString(_account.openingBalancePaise),
    );
    AccountType selectedType = _account.accountType;

    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return AlertDialog(
              title: const Text('Edit Account'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Account Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (String? val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter account name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<AccountType>(
                        value: selectedType,
                        decoration: const InputDecoration(
                          labelText: 'Account Type',
                          border: OutlineInputBorder(),
                        ),
                        items: AccountType.values.map((AccountType t) {
                          return DropdownMenuItem<AccountType>(
                            value: t,
                            child: Text(t.displayName),
                          );
                        }).toList(),
                        onChanged: (AccountType? val) {
                          if (val != null) {
                            setModalState(() => selectedType = val);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: balanceController,
                        decoration: const InputDecoration(
                          labelText: 'Opening Balance (₹)',
                          prefixText: '₹ ',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        validator: (String? val) {
                          final int? parsed =
                              CurrencyFormatter.parseToPaiseAllowZero(val);
                          if (parsed == null) {
                            return 'Enter a valid opening amount';
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
                    final int? newOpening =
                        CurrencyFormatter.parseToPaiseAllowZero(
                            balanceController.text);
                    if (newOpening == null) return;

                    final Account updated = _account.copyWith(
                      name: nameController.text.trim(),
                      accountType: selectedType,
                      openingBalancePaise: newOpening,
                    );

                    await context
                        .read<FinanceProvider>()
                        .updateAccount(updated);

                    if (mounted) {
                      setState(() => _account = updated);
                      Navigator.of(ctx).pop();
                    }
                  },
                  child: const Text('Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handleDelete(BuildContext context, int transactionCount) async {
    if (transactionCount > 0) {
      showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Cannot Delete Account'),
          content: Text(
            'This account has $transactionCount recorded transaction(s). '
            'To protect financial integrity, accounts with transaction history cannot be deleted. '
            'Please reassign or delete these transactions first.',
          ),
          actions: <Widget>[
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Understood'),
            ),
          ],
        ),
      );
      return;
    }

    final bool confirmed = await ConfirmDialog.show(
      context: context,
      title: 'Delete Account',
      message:
          'Are you sure you want to delete ${_account.name}? This cannot be undone.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );

    if (confirmed && mounted) {
      try {
        await context.read<FinanceProvider>().deleteAccount(_account.id);
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting account: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Consumer<FinanceProvider>(
      builder: (BuildContext context, FinanceProvider finance, Widget? child) {
        final int currentBalance = finance.accountBalances[_account.id] ??
            _account.openingBalancePaise;

        // Filter transactions for this specific account
        final List<TransactionItem> accountTransactions = finance
            .allTransactions
            .where((TransactionItem t) => t.accountId == _account.id)
            .toList();

        return Scaffold(
          appBar: AppBar(
            title: Text(_account.name),
            actions: <Widget>[
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit Account',
                onPressed: () => _showEditAccountDialog(context),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Delete Account',
                onPressed: () =>
                    _handleDelete(context, accountTransactions.length),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(vertical: 12),
            children: <Widget>[
              // Balance Overview Card
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
                color: theme.colorScheme.surfaceContainerHigh,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: <Widget>[
                      Text(
                        'CURRENT BALANCE',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        CurrencyFormatter.formatPaise(currentBalance),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: currentBalance < 0
                              ? Colors.red
                              : theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Divider(
                          color: theme.colorScheme.outlineVariant
                              .withOpacity(0.5)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: <Widget>[
                          Column(
                            children: <Widget>[
                              Text(
                                'Account Type',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _account.accountType.displayName,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            height: 28,
                            width: 1,
                            color: theme.colorScheme.outlineVariant
                                .withOpacity(0.5),
                          ),
                          Column(
                            children: <Widget>[
                              Text(
                                'Opening Balance',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                CurrencyFormatter.formatPaise(
                                    _account.openingBalancePaise),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      FilledButton.tonalIcon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => TransactionFormScreen(
                                initialType: TransactionType.transferOut,
                                initialAccountId: _account.id,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.swap_horiz),
                        label: const Text('Transfer from this Account'),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'TRANSACTION HISTORY (${accountTransactions.length})',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              if (accountTransactions.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: EmptyStateView(
                    icon: Icons.receipt_long_outlined,
                    title: 'No Transactions',
                    message:
                        'No recorded income, expenses, or transfers for this account.',
                  ),
                )
              else
                for (final TransactionItem item in accountTransactions)
                  Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color:
                            theme.colorScheme.outlineVariant.withOpacity(0.4),
                      ),
                    ),
                    child: TransactionListItem(
                      item: item,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                TransactionFormScreen(transactionToEdit: item),
                          ),
                        );
                      },
                      onDelete: () async {
                        final bool confirmed = await ConfirmDialog.show(
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
                  ),
            ],
          ),
        );
      },
    );
  }
}
