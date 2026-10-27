import 'package:flutter/material.dart';
import '../models/budget.dart';
import '../utils/currency_formatter.dart';
import 'category_icon.dart';

/// Renders category budget progress with safe clamping, warning states, and clear remaining balances.
class BudgetProgressCard extends StatelessWidget {
  final Budget budget;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const BudgetProgressCard({
    super.key,
    required this.budget,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final Color statusColor;
    final String statusLabel;

    if (budget.isExceeded) {
      statusColor = const Color(0xFFDC2626); // Red
      final int overPaise = budget.spentPaise - budget.limitPaise;
      statusLabel = '${CurrencyFormatter.formatPaise(overPaise)} over budget';
    } else if (budget.isApproachingLimit) {
      statusColor = const Color(0xFFD97706); // Amber
      statusLabel =
          '${CurrencyFormatter.formatPaise(budget.remainingPaise)} left (approaching limit)';
    } else {
      statusColor = const Color(0xFF10B981); // Emerald
      statusLabel =
          '${CurrencyFormatter.formatPaise(budget.remainingPaise)} remaining';
    }

    final IconData iconData = _getIconData(budget.categoryIconKey);
    final Color catColor = Color(budget.categoryColorValue ?? 0xFF64748B);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                CategoryIcon(iconData: iconData, color: catColor, size: 38),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        budget.categoryName ?? 'Category',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${CurrencyFormatter.formatPaise(budget.spentPaise)} spent of ${CurrencyFormatter.formatPaise(budget.limitPaise)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onSelected: (String action) {
                    if (action == 'edit' && onEdit != null) {
                      onEdit!();
                    } else if (action == 'delete' && onDelete != null) {
                      onDelete!();
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: <Widget>[
                          Icon(Icons.edit_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Edit Limit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: <Widget>[
                          Icon(Icons.delete_outline,
                              size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete Budget',
                              style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Progress bar strictly clamped to 1.0 to prevent visual and layout errors
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: budget.clampedProgressRatio,
                minHeight: 8,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  '${budget.percentageSpent.toStringAsFixed(0)}% used',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                Text(
                  statusLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
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
