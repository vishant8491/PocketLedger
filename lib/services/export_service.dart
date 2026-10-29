import '../models/transaction.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_helper.dart';
import 'csv_export_helper.dart';

/// Service for exporting transaction history to a CSV file and sharing via Android Share Sheet or Web download.
/// Implements RFC-4180 CSV quoting and sanitizes against CSV Formula Injection.
class ExportService {
  ExportService._();

  /// Converts a list of transactions into a CSV formatted string,
  /// saves it to a cache file, and opens the system share dialog or browser download.
  static Future<void> exportAndShareTransactions(
      List<TransactionItem> transactions) async {
    final String csvContent = generateTransactionsCsv(transactions);

    final String timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    final String fileName = 'PocketLedger_Export_$timestamp.csv';

    await exportAndShareCsv(
      csvContent: csvContent,
      fileName: fileName,
      subject: 'PocketLedger Transactions Export',
      text: 'Exported ${transactions.length} transaction(s) from PocketLedger.',
    );
  }

  /// Generates the raw CSV string with proper escaping and formula injection protection.
  static String generateTransactionsCsv(List<TransactionItem> transactions) {
    final StringBuffer buffer = StringBuffer();

    // CSV Header row
    buffer.writeln('Date,Type,Account,Category,Amount (INR),Note');

    for (final TransactionItem item in transactions) {
      final String dateStr = DateHelper.toIsoDate(item.transactionDate);
      final String typeStr = sanitizeCsvField(item.transactionType.displayName);
      final String accountStr =
          sanitizeCsvField(item.accountName ?? 'Unknown Account');
      final String categoryStr = sanitizeCsvField(item.categoryName ??
          (item.isTransfer ? 'Transfer' : 'Uncategorized'));
      final String amountStr =
          CurrencyFormatter.paiseToEditableString(item.amountPaise);
      final String noteStr = sanitizeCsvField(item.note ?? '');

      buffer.writeln(
          '$dateStr,$typeStr,$accountStr,$categoryStr,$amountStr,$noteStr');
    }

    return buffer.toString();
  }

  /// Sanitizes text against CSV Formula Injection (Excel / Google Sheets / LibreOffice).
  /// If text starts with =, +, -, or @, it prefixes with a single apostrophe (').
  /// Also properly escapes quotes and commas per standard RFC-4180 rules.
  static String sanitizeCsvField(String text) {
    if (text.isEmpty) return '""';

    String sanitized = text;

    // Check for formula injection triggers (including leading whitespace/tabs)
    final String trimmedLeft = sanitized.trimLeft();
    if (trimmedLeft.isNotEmpty) {
      final String firstChar = trimmedLeft.substring(0, 1);
      if (firstChar == '=' ||
          firstChar == '+' ||
          firstChar == '-' ||
          firstChar == '@' ||
          firstChar == '\t' ||
          firstChar == '\r') {
        sanitized = "'$sanitized";
      }
    }

    // Escape double quotes by doubling them (""")
    final String escaped = sanitized.replaceAll('"', '""');

    // Always enclose in quotes for CSV consistency
    return '"$escaped"';
  }
}
