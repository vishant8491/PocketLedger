import 'package:flutter/material.dart';

enum IncomeExpenseType {
  income,
  expense;

  String get displayName {
    switch (this) {
      case IncomeExpenseType.income:
        return 'Income';
      case IncomeExpenseType.expense:
        return 'Expense';
    }
  }

  static IncomeExpenseType fromString(String value) {
    if (value.toLowerCase() == 'income') {
      return IncomeExpenseType.income;
    }
    return IncomeExpenseType.expense;
  }
}

class Category {
  final String id;
  final String name;
  final IncomeExpenseType incomeOrExpense;
  final String iconKey;
  final int colorValue;
  final bool isArchived;

  const Category({
    required this.id,
    required this.name,
    required this.incomeOrExpense,
    required this.iconKey,
    required this.colorValue,
    this.isArchived = false,
  });

  Category copyWith({
    String? id,
    String? name,
    IncomeExpenseType? incomeOrExpense,
    String? iconKey,
    int? colorValue,
    bool? isArchived,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      incomeOrExpense: incomeOrExpense ?? this.incomeOrExpense,
      iconKey: iconKey ?? this.iconKey,
      colorValue: colorValue ?? this.colorValue,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'incomeOrExpense': incomeOrExpense.name,
      'iconKey': iconKey,
      'colorValue': colorValue,
      'isArchived': isArchived ? 1 : 0,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as String,
      name: map['name'] as String,
      incomeOrExpense:
          IncomeExpenseType.fromString(map['incomeOrExpense'] as String),
      iconKey: map['iconKey'] as String,
      colorValue: map['colorValue'] as int,
      isArchived: (map['isArchived'] as int? ?? 0) == 1,
    );
  }

  /// Maps an iconKey string to standard Material IconData.
  static IconData iconDataFromKey(String? key) {
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
      case 'flight':
        return Icons.flight_outlined;
      case 'fitness':
        return Icons.fitness_center;
      case 'more_horiz':
      default:
        return Icons.category_outlined;
    }
  }

  /// Convenience getter for this category's icon.
  IconData get iconData => iconDataFromKey(iconKey);

  Color get color => Color(colorValue);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          incomeOrExpense == other.incomeOrExpense &&
          isArchived == other.isArchived;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      incomeOrExpense.hashCode ^
      isArchived.hashCode;
}
