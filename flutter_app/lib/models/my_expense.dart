class MyExpense {
  final String id;
  final String title;
  final double amount;
  final String categoryId;
  final DateTime date;
  final String notes;

  MyExpense({
    required this.id,
    required this.title,
    required this.amount,
    this.categoryId = 'other',
    required this.date,
    this.notes = '',
  });

  MyExpense copyWith({
    String? id,
    String? title,
    double? amount,
    String? categoryId,
    DateTime? date,
    String? notes,
  }) {
    return MyExpense(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      date: date ?? this.date,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'amount': amount,
    'categoryId': categoryId,
    'date': date.toIso8601String(),
    'notes': notes,
  };

  factory MyExpense.fromJson(Map<String, dynamic> json) {
    return MyExpense(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      categoryId: json['categoryId'] ?? 'other',
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      notes: json['notes'] ?? '',
    );
  }
}

class MyExpenseMonthlyGroup {
  final String label;
  final DateTime date;
  final List<MyExpense> expenses;
  final double total;

  MyExpenseMonthlyGroup({
    required this.label,
    required this.date,
    required this.expenses,
    required this.total,
  });
}

class CategoryAnalytics {
  final String categoryId;
  final double total;
  final int count;

  CategoryAnalytics({required this.categoryId, required this.total, required this.count});

  factory CategoryAnalytics.fromJson(Map<String, dynamic> json) {
    return CategoryAnalytics(
      categoryId: json['_id'] ?? '',
      total: (json['total'] ?? 0).toDouble(),
      count: json['count'] ?? 0,
    );
  }
}

class MonthlyAnalytics {
  final int year;
  final int month;
  final double total;
  final int count;

  MonthlyAnalytics({required this.year, required this.month, required this.total, required this.count});

  factory MonthlyAnalytics.fromJson(Map<String, dynamic> json) {
    return MonthlyAnalytics(
      year: json['_id']['year'] ?? 0,
      month: json['_id']['month'] ?? 0,
      total: (json['total'] ?? 0).toDouble(),
      count: json['count'] ?? 0,
    );
  }
}

class PersonalExpenseAnalytics {
  final double totalSpent;
  final int totalExpenses;
  final List<CategoryAnalytics> categoryTotals;
  final List<MonthlyAnalytics> monthlyTotals;

  PersonalExpenseAnalytics({
    required this.totalSpent,
    required this.totalExpenses,
    required this.categoryTotals,
    required this.monthlyTotals,
  });

  factory PersonalExpenseAnalytics.fromJson(Map<String, dynamic> json) {
    return PersonalExpenseAnalytics(
      totalSpent: (json['totalSpent'] ?? 0).toDouble(),
      totalExpenses: json['totalExpenses'] ?? 0,
      categoryTotals: (json['categoryTotals'] as List?)
              ?.map((e) => CategoryAnalytics.fromJson(e))
              .toList() ??
          [],
      monthlyTotals: (json['monthlyTotals'] as List?)
              ?.map((e) => MonthlyAnalytics.fromJson(e))
              .toList() ??
          [],
    );
  }
}
