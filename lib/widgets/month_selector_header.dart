import 'package:flutter/material.dart';
import '../utils/date_helper.dart';

/// Month selector bar allowing seamless navigation between reporting months.
class MonthSelectorHeader extends StatelessWidget {
  final DateTime selectedMonth;
  final ValueChanged<DateTime> onMonthChanged;

  const MonthSelectorHeader({
    super.key,
    required this.selectedMonth,
    required this.onMonthChanged,
  });

  void _previousMonth() {
    final DateTime prev =
        DateTime(selectedMonth.year, selectedMonth.month - 1, 1);
    onMonthChanged(prev);
  }

  void _nextMonth() {
    final DateTime next =
        DateTime(selectedMonth.year, selectedMonth.month + 1, 1);
    onMonthChanged(next);
  }

  Future<void> _selectCustomMonth(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedMonth,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 2),
      helpText: 'Select Month',
      initialDatePickerMode: DatePickerMode.year,
    );

    if (picked != null) {
      onMonthChanged(DateTime(picked.year, picked.month, 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withOpacity(0.4),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Previous Month',
            onPressed: _previousMonth,
          ),
          InkWell(
            onTap: () => _selectCustomMonth(context),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    Icons.calendar_month_outlined,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateHelper.formatMonthYear(selectedMonth),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_drop_down,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Next Month',
            onPressed: _nextMonth,
          ),
        ],
      ),
    );
  }
}
