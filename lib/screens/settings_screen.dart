import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';
import '../providers/theme_provider.dart';
import '../services/export_service.dart';
import '../widgets/confirm_dialog.dart';
import 'category_management_screen.dart';
import 'onboarding_screen.dart';

/// Settings screen for configuring app theme, managing categories, exporting data to CSV,
/// viewing privacy details, and performing explicit database resets.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _handleExport(BuildContext context) async {
    final FinanceProvider finance = context.read<FinanceProvider>();
    final List<dynamic> transactions = finance.allTransactions;

    if (transactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No transactions to export.')),
      );
      return;
    }

    try {
      await ExportService.exportAndShareTransactions(finance.allTransactions);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export CSV: $e')),
        );
      }
    }
  }

  Future<void> _handleClearData(BuildContext context) async {
    final bool firstConfirm = await ConfirmDialog.show(
      context: context,
      title: 'Reset All Data?',
      message:
          'This will permanently wipe all your accounts, transactions, and budgets. '
          'PocketLedger will return to its initial state. Are you sure?',
      cancelLabel: 'Keep Data',
      confirmLabel: 'Clear All Data',
      isDestructive: true,
    );

    if (!firstConfirm || !context.mounted) return;

    final bool secondConfirm = await ConfirmDialog.show(
      context: context,
      title: 'Final Confirmation',
      message:
          'This action is irreversible. All offline financial records on this device will be erased.',
      cancelLabel: 'Cancel',
      confirmLabel: 'Permanently Erase',
      isDestructive: true,
    );

    if (secondConfirm && context.mounted) {
      final FinanceProvider provider = context.read<FinanceProvider>();
      await provider.clearAllData();

      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => const OnboardingScreen()),
          (Route<dynamic> route) => false,
        );
      }
    }
  }

  void _showAboutDialog(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Row(
          children: <Widget>[
            Icon(Icons.shield_outlined, color: theme.colorScheme.primary),
            const SizedBox(width: 10),
            const Text('About PocketLedger'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'PocketLedger v1.0.0',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'PocketLedger is a private, 100% offline personal finance and expense manager. '
              'All account balances, transactions, and budgets remain strictly within local SQLite storage on this phone.',
              style: TextStyle(height: 1.4),
            ),
            const SizedBox(height: 12),
            Text(
              '• Zero internet permissions required\n'
              '• No cloud tracking or telemetry\n'
              '• Safe CSV data export anytime',
              style: TextStyle(
                height: 1.4,
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          ],
        ),
        actions: <Widget>[
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ThemeProvider themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: <Widget>[
          // Appearance Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'APPEARANCE',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
            ),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('System Default'),
            subtitle: const Text('Follows system brightness setting'),
            value: ThemeMode.system,
            groupValue: themeProvider.themeMode,
            onChanged: (ThemeMode? mode) {
              if (mode != null) themeProvider.setThemeMode(mode);
            },
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Light Mode'),
            subtitle: const Text('Clean navy and white palette'),
            value: ThemeMode.light,
            groupValue: themeProvider.themeMode,
            onChanged: (ThemeMode? mode) {
              if (mode != null) themeProvider.setThemeMode(mode);
            },
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Dark Mode'),
            subtitle: const Text('OLED friendly slate navy dark palette'),
            value: ThemeMode.dark,
            groupValue: themeProvider.themeMode,
            onChanged: (ThemeMode? mode) {
              if (mode != null) themeProvider.setThemeMode(mode);
            },
          ),

          const Divider(height: 28),

          // Data & Customization Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'PREFERENCES & DATA',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.category_outlined),
            title: const Text('Manage Categories'),
            subtitle: const Text('Add, rename, or archive spending categories'),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const CategoryManagementScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.file_download_outlined),
            title: const Text('Export to CSV'),
            subtitle:
                const Text('Share clean, spreadsheet-safe transaction records'),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () => _handleExport(context),
          ),

          const Divider(height: 28),

          // Security & Storage Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'SYSTEM & PRIVACY',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About PocketLedger'),
            subtitle: const Text('Offline privacy and application details'),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () => _showAboutDialog(context),
          ),
          ListTile(
            leading:
                Icon(Icons.delete_forever_outlined, color: Colors.red.shade700),
            title: Text(
              'Clear All Local Data',
              style: TextStyle(
                  color: Colors.red.shade700, fontWeight: FontWeight.bold),
            ),
            subtitle: const Text(
                'Permanently erase accounts, transactions, and budgets'),
            onTap: () => _handleClearData(context),
          ),
        ],
      ),
    );
  }
}
