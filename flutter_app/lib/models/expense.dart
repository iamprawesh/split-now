class ExpenseSplit {
  final String userId;
  final String name;
  final String avatar;
  final double value;
  final double amount;

  ExpenseSplit({
    required this.userId,
    required this.name,
    required this.avatar,
    required this.value,
    required this.amount,
  });

  factory ExpenseSplit.fromJson(Map<String, dynamic> json) {
    final user = json['user'] is Map ? json['user'] : {};
    return ExpenseSplit(
      userId: user['_id'] ?? user['id'] ?? json['user'] ?? '',
      name: user['name'] ?? '',
      avatar: user['avatar'] ?? '',
      value: (json['value'] ?? 0).toDouble(),
      amount: (json['amount'] ?? 0).toDouble(),
    );
  }
}

class Expense {
  final String id;
  final String group;
  final String title;
  final String description;
  final double amount;
  final String paidById;
  final String paidByName;
  final String paidByAvatar;
  final String splitType;
  final List<ExpenseSplit> splits;
  final DateTime date;

  Expense({
    required this.id,
    required this.group,
    required this.title,
    required this.description,
    required this.amount,
    required this.paidById,
    required this.paidByName,
    required this.paidByAvatar,
    required this.splitType,
    required this.splits,
    required this.date,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    final payer = json['paidBy'] is Map ? json['paidBy'] : {};
    return Expense(
      id: json['_id'] ?? json['id'] ?? '',
      group: json['group'] ?? '',
      title: json['title'] ?? json['description'] ?? '',
      description: json['description'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      paidById: payer['_id'] ?? payer['id'] ?? json['paidBy'] ?? '',
      paidByName: payer['name'] ?? '',
      paidByAvatar: payer['avatar'] ?? '',
      splitType: json['splitType'] ?? 'equal',
      splits: (json['splits'] as List<dynamic>?)
              ?.map((s) => ExpenseSplit.fromJson(s))
              .toList() ??
          [],
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
    );
  }
}

class Settlement {
  final String id;
  final String fromId;
  final String fromName;
  final String toId;
  final String toName;
  final double amount;
  final DateTime settledAt;

  Settlement({
    required this.id,
    required this.fromId,
    required this.fromName,
    required this.toId,
    required this.toName,
    required this.amount,
    required this.settledAt,
  });

  factory Settlement.fromJson(Map<String, dynamic> json) {
    final from = json['from'] is Map ? json['from'] : {};
    final to = json['to'] is Map ? json['to'] : {};
    return Settlement(
      id: json['_id'] ?? json['id'] ?? '',
      fromId: from['_id'] ?? from['id'] ?? '',
      fromName: from['name'] ?? '',
      toId: to['_id'] ?? to['id'] ?? '',
      toName: to['name'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      settledAt: json['settledAt'] != null
          ? DateTime.parse(json['settledAt'])
          : DateTime.now(),
    );
  }
}

class BalanceData {
  final Map<String, double> balances;
  final List<Transaction> transactions;

  BalanceData({required this.balances, required this.transactions});

  factory BalanceData.fromJson(Map<String, dynamic> json) {
    final balMap = json['balances'] as Map<String, dynamic>? ?? {};
    final txs = (json['transactions'] as List<dynamic>?)
            ?.map((t) => Transaction.fromJson(t))
            .toList() ??
        [];
    return BalanceData(
      balances: balMap.map((k, v) => MapEntry(k, (v as num).toDouble())),
      transactions: txs,
    );
  }
}

class Transaction {
  final String from;
  final String to;
  final double amount;

  Transaction({required this.from, required this.to, required this.amount});

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      from: json['from'] ?? '',
      to: json['to'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
    );
  }
}
