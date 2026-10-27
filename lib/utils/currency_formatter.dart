/// Utility class for safely parsing and formatting currency in Indian Rupees (INR).
/// All internal amounts are strictly stored as integer paise (1 INR = 100 paise).
class CurrencyFormatter {
  // Prevent instantiation.
  CurrencyFormatter._();

  static const String currencySymbol = '₹';

  /// Formats an integer amount in paise into an Indian Rupee string representation.
  /// Example: 125000 paise -> "₹1,250" (or "₹1,250.00" if showDecimals is true).
  /// Handles negative values cleanly for net savings calculations.
  static String formatPaise(
    int paise, {
    bool includeSymbol = true,
    bool showDecimals = false,
  }) {
    final bool isNegative = paise < 0;
    final int absPaise = paise.abs();

    final int rupees = absPaise ~/ 100;
    final int remainingPaise = absPaise % 100;

    final String formattedRupees = _formatIndianGrouping(rupees);

    final StringBuffer buffer = StringBuffer();
    if (isNegative) {
      buffer.write('-');
    }
    if (includeSymbol) {
      buffer.write(currencySymbol);
      buffer.write(' ');
    }
    buffer.write(formattedRupees);

    if (showDecimals || remainingPaise > 0) {
      buffer.write('.');
      buffer.write(remainingPaise.toString().padLeft(2, '0'));
    }

    return buffer.toString().trim();
  }

  /// Converts an entered user decimal string (e.g. "1250", "1250.50", "99.9")
  /// safely into integer paise without floating point inaccuracy.
  /// Returns null if the string is empty, invalid, or <= 0.
  static int? parseToPaise(String? input) {
    if (input == null) return null;
    final String clean = input.trim().replaceAll(',', '');
    if (clean.isEmpty) return null;

    // Max supported personal finance amount: 99 Crore, 99 Lakh, 99 Thousand, 999 INR
    const int maxRupees = 999999999;

    final String normalized = clean.startsWith('.') ? '0$clean' : clean;

    // Reject invalid characters or negative values.
    final RegExp validRegex = RegExp(r'^\d+(\.\d{1,2})?$');
    if (!validRegex.hasMatch(normalized)) return null;

    final List<String> parts = normalized.split('.');
    final int? rupees = int.tryParse(parts[0]);
    if (rupees == null || rupees > maxRupees) return null;
    int paise = 0;

    if (parts.length > 1) {
      final String decimalPart = parts[1];
      if (decimalPart.length == 1) {
        paise = (int.tryParse(decimalPart) ?? 0) * 10;
      } else if (decimalPart.length == 2) {
        paise = int.tryParse(decimalPart) ?? 0;
      }
    }

    final int totalPaise = (rupees * 100) + paise;
    if (totalPaise <= 0) return null;

    return totalPaise;
  }

  /// Parses an entered amount that may be zero (useful for opening balance).
  static int? parseToPaiseAllowZero(String? input) {
    if (input == null) return null;
    final String clean = input.trim().replaceAll(',', '');
    if (clean.isEmpty) return null;

    const int maxRupees = 999999999;
    final String normalized = clean.startsWith('.') ? '0$clean' : clean;

    final RegExp validRegex = RegExp(r'^\d+(\.\d{1,2})?$');
    if (!validRegex.hasMatch(normalized)) return null;

    final List<String> parts = normalized.split('.');
    final int? rupees = int.tryParse(parts[0]);
    if (rupees == null || rupees > maxRupees) return null;
    int paise = 0;

    if (parts.length > 1) {
      final String decimalPart = parts[1];
      if (decimalPart.length == 1) {
        paise = (int.tryParse(decimalPart) ?? 0) * 10;
      } else if (decimalPart.length == 2) {
        paise = int.tryParse(decimalPart) ?? 0;
      }
    }

    final int totalPaise = (rupees * 100) + paise;
    if (totalPaise < 0) return null;

    return totalPaise;
  }

  /// Formats integers according to the Indian numbering system:
  /// Last 3 digits grouped together, preceding digits grouped in 2s (e.g., 12,34,567).
  static String _formatIndianGrouping(int number) {
    final String s = number.toString();
    if (s.length <= 3) return s;

    final String lastThree = s.substring(s.length - 3);
    String remaining = s.substring(0, s.length - 3);

    final List<String> groups = <String>[];
    while (remaining.length > 2) {
      groups.add(remaining.substring(remaining.length - 2));
      remaining = remaining.substring(0, remaining.length - 2);
    }
    if (remaining.isNotEmpty) {
      groups.add(remaining);
    }

    final String prefix = groups.reversed.join(',');
    return '$prefix,$lastThree';
  }

  /// Converts paise to a clean editable decimal string (e.g. 125000 -> "1250").
  static String paiseToEditableString(int paise) {
    final int rupees = paise ~/ 100;
    final int remainder = paise % 100;
    if (remainder == 0) {
      return rupees.toString();
    }
    final String remainderStr = remainder.toString().padLeft(2, '0');
    return '$rupees.$remainderStr';
  }
}
