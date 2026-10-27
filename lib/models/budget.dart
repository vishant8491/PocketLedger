class Budget {
  final String id;
  final String categoryId;
  final int month;
  final int year;
  final int limitPaise;

  // Enriched fields calculated at runtime for UI
  final String? categoryName;
  final String? categoryIconKey;
  final int? categoryColorValue;
  final int spentPaise;

  const Budget({
    required this.id,
    required this.categoryId,
    required this.month,
    required this.year,
    required this.limitPaise,
    this.categoryName,
    this.categoryIconKey,
    this.categoryColorValue,
    this.spentPaise = 0,
  });

  /// The amount remaining under the budget limit in paise.
  int get remainingPaise => limitPaise - spentPaise;

  /// Percentage of the budget spent. Handles division safely.
  double get percentageSpent {
    if (limitPaise <= 0) return 0.0;
    return (spentPaise / limitPaise) * 100.0;
  }

  /// Clamped progress ratio between 0.0 and 1.0 for LinearProgressIndicator.
  /// Prevents widget assertion errors when spending exceeds 100%.
  double get clampedProgressRatio {
    if (limitPaise <= 0) return 0.0;
    final double ratio = spentPaise / limitPaise;
    if (ratio < 0.0) return 0.0;
    if (ratio > 1.0) return 1.0;
    return ratio;
  }

  /// Budget is at 80% or higher, but not yet exceeded.
  bool get isApproachingLimit =>
      percentageSpent >= 80.0 && spentPaise <= limitPaise;

  /// Budget has exceeded the allocated limit.
  bool get isExceeded => spentPaise > limitPaise;

  Budget copyWith({
    String? id,
    String? categoryId,
    int? month,
    int? year,
    int? limitPaise,
    String? categoryName,
    String? categoryIconKey,
    int? categoryColorValue,
    int? spentPaise,
  }) {
    return Budget(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      month: month ?? this.month,
      year: year ?? this.year,
      limitPaise: limitPaise ?? this.limitPaise,
      categoryName: categoryName ?? this.categoryName,
      categoryIconKey: categoryIconKey ?? this.categoryIconKey,
      categoryColorValue: categoryColorValue ?? this.categoryColorValue,
      spentPaise: spentPaise ?? this.spentPaise,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'categoryId': categoryId,
      'month': month,
      'year': year,
      'limitPaise': limitPaise,
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map, {int spentPaise = 0}) {
    return Budget(
      id: map['id'] as String,
      categoryId: map['categoryId'] as String,
      month: map['month'] as int,
      year: map['year'] as int,
      limitPaise: map['limitPaise'] as int,
      categoryName: map['categoryName'] as String?,
      categoryIconKey: map['categoryIconKey'] as String?,
      categoryColorValue: map['categoryColorValue'] as int?,
      spentPaise: spentPaise,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Budget &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          categoryId == other.categoryId &&
          month == other.month &&
          year == other.year &&
          limitPaise == other.limitPaise;

  @override
  int get hashCode =>
      id.hashCode ^
      categoryId.hashCode ^
      month.hashCode ^
      year.hashCode ^
      limitPaise.hashCode;
}
