import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_helper.dart';
import 'category_icon.dart';

/// Clean, high-legibility transaction row with visual indicators for income, expense, and transfers.
class TransactionListItem extends StatelessWidget {
  final TransactionItem item;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const TransactionListItem({
    super.key,
    required this.item,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final bool isIncome = item.transactionType == TransactionType.income;
    final bool isExpense = item.transactionType == TransactionType.expense;
    final bool isTransferIn =
        item.transactionType == TransactionType.transferIn;

    final Color amountColor;
    final String sign;

    if (isIncome) {
      amountColor = const Color(0xFF16A34A); // Emerald green
      sign = '+ ';
    } else if (isExpense) {
      amountColor = const Color(0xFFDC2626); // Rose red
      sign = '- ';
    } else if (isTransferIn) {
      amountColor = const Color(0xFF2563EB); // Blue
      sign = '+ ';
    } else {
      amountColor = const Color(0xFF475569); // Slate
      sign = '- ';
    }

    final String title;
    final IconData iconData;
    final Color iconColor;

    if (item.isTransfer) {
      title = isTransferIn ? 'Transfer Received' : 'Transfer Sent';
      iconData = Icons.swap_horiz;
      iconColor = const Color(0xFF2563EB);
    } else {
      title = item.categoryName ?? 'Uncategorized';
      iconData = _getIconData(item.categoryIconKey);
      iconColor = Color(item.categoryColorValue ?? 0xFF64748B);
    }

    return Dismissible(
      key: Key(item.id),
      direction: onDelete != null
          ? DismissDirection.endToStart
          : DismissDirection.none,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red.shade700,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (DismissDirection direction) async {
        if (onDelete != null) {
          onDelete!();
        }
        return false; // Let parent dialog handle state deletion
      },
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CategoryIcon(
          iconData: iconData,
          color: iconColor,
          size: 42,
        ),
        title: Text(
          title,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: <Widget>[
            Flexible(
              child: Text(
                item.note != null && item.note!.trim().isNotEmpty
                    ? '${item.accountName ?? "Account"} • ${item.note}'
                    : item.accountName ?? 'Account',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Text(
              '$sign${CurrencyFormatter.formatPaise(item.amountPaise)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: amountColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              DateHelper.formatDayMonth(item.transactionDate),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconData(String? key) {
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
