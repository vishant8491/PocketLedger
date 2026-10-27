enum AccountType {
  cash,
  bank,
  wallet;

  String get displayName {
    switch (this) {
      case AccountType.cash:
        return 'Cash';
      case AccountType.bank:
        return 'Bank Account';
      case AccountType.wallet:
        return 'Digital Wallet';
    }
  }

  static AccountType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'bank':
        return AccountType.bank;
      case 'wallet':
        return AccountType.wallet;
      case 'cash':
      default:
        return AccountType.cash;
    }
  }
}

class Account {
  final String id;
  final String name;
  final AccountType accountType;
  final int openingBalancePaise;
  final DateTime createdAt;

  const Account({
    required this.id,
    required this.name,
    required this.accountType,
    required this.openingBalancePaise,
    required this.createdAt,
  });

  Account copyWith({
    String? id,
    String? name,
    AccountType? accountType,
    int? openingBalancePaise,
    DateTime? createdAt,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      accountType: accountType ?? this.accountType,
      openingBalancePaise: openingBalancePaise ?? this.openingBalancePaise,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'accountType': accountType.name,
      'openingBalancePaise': openingBalancePaise,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'] as String,
      name: map['name'] as String,
      accountType: AccountType.fromString(map['accountType'] as String),
      openingBalancePaise: map['openingBalancePaise'] as int,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Account &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          accountType == other.accountType &&
          openingBalancePaise == other.openingBalancePaise;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      accountType.hashCode ^
      openingBalancePaise.hashCode;
}
