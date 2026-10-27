enum TransactionType {
  income,
  expense,
  transferOut,
  transferIn;

  String get dbValue {
    switch (this) {
      case TransactionType.income:
        return 'income';
      case TransactionType.expense:
        return 'expense';
      case TransactionType.transferOut:
        return 'transfer_out';
      case TransactionType.transferIn:
        return 'transfer_in';
    }
  }

  String get displayName {
    switch (this) {
      case TransactionType.income:
        return 'Income';
      case TransactionType.expense:
        return 'Expense';
      case TransactionType.transferOut:
        return 'Transfer Out';
      case TransactionType.transferIn:
        return 'Transfer In';
    }
  }

  static TransactionType fromDbValue(String value) {
    switch (value.toLowerCase()) {
      case 'income':
        return TransactionType.income;
      case 'expense':
        return TransactionType.expense;
      case 'transfer_out':
        return TransactionType.transferOut;
      case 'transfer_in':
        return TransactionType.transferIn;
      default:
        return TransactionType.expense;
    }
  }
}

class TransactionItem {
  final String id;
  final String accountId;
  final String? categoryId;
  final TransactionType transactionType;
  final int amountPaise;
  final DateTime transactionDate;
  final String? note;
  final String? transferGroupId;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Optional join fields for convenient UI display without extra queries
  final String? accountName;
  final String? categoryName;
  final String? categoryIconKey;
  final int? categoryColorValue;

  const TransactionItem({
    required this.id,
    required this.accountId,
    this.categoryId,
    required this.transactionType,
    required this.amountPaise,
    required this.transactionDate,
    this.note,
    this.transferGroupId,
    required this.createdAt,
    required this.updatedAt,
    this.accountName,
    this.categoryName,
    this.categoryIconKey,
    this.categoryColorValue,
  });

  bool get isTransfer =>
      transactionType == TransactionType.transferOut ||
      transactionType == TransactionType.transferIn;

  bool get isExpense => transactionType == TransactionType.expense;
  bool get isIncome => transactionType == TransactionType.income;

  TransactionItem copyWith({
    String? id,
    String? accountId,
    String? categoryId,
    TransactionType? transactionType,
    int? amountPaise,
    DateTime? transactionDate,
    String? note,
    String? transferGroupId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? accountName,
    String? categoryName,
    String? categoryIconKey,
    int? categoryColorValue,
  }) {
    return TransactionItem(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      transactionType: transactionType ?? this.transactionType,
      amountPaise: amountPaise ?? this.amountPaise,
      transactionDate: transactionDate ?? this.transactionDate,
      note: note ?? this.note,
      transferGroupId: transferGroupId ?? this.transferGroupId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      accountName: accountName ?? this.accountName,
      categoryName: categoryName ?? this.categoryName,
      categoryIconKey: categoryIconKey ?? this.categoryIconKey,
      categoryColorValue: categoryColorValue ?? this.categoryColorValue,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'accountId': accountId,
      'categoryId': categoryId,
      'transactionType': transactionType.dbValue,
      'amountPaise': amountPaise,
      'transactionDate': transactionDate.toIso8601String(),
      'note': note,
      'transferGroupId': transferGroupId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory TransactionItem.fromMap(Map<String, dynamic> map) {
    return TransactionItem(
      id: map['id'] as String,
      accountId: map['accountId'] as String,
      categoryId: map['categoryId'] as String?,
      transactionType:
          TransactionType.fromDbValue(map['transactionType'] as String),
      amountPaise: map['amountPaise'] as int,
      transactionDate: DateTime.parse(map['transactionDate'] as String),
      note: map['note'] as String?,
      transferGroupId: map['transferGroupId'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      accountName: map['accountName'] as String?,
      categoryName: map['categoryName'] as String?,
      categoryIconKey: map['categoryIconKey'] as String?,
      categoryColorValue: map['categoryColorValue'] as int?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          accountId == other.accountId &&
          categoryId == other.categoryId &&
          transactionType == other.transactionType &&
          amountPaise == other.amountPaise &&
          transactionDate == other.transactionDate &&
          transferGroupId == other.transferGroupId;

  @override
  int get hashCode =>
      id.hashCode ^
      accountId.hashCode ^
      categoryId.hashCode ^
      transactionType.hashCode ^
      amountPaise.hashCode ^
      transactionDate.hashCode ^
      transferGroupId.hashCode;
}
