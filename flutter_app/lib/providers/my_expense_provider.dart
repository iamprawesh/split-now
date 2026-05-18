import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/my_expense.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';

class MyExpenseState {
  final List<MyExpense> expenses;
  final bool isLoading;
  final String? error;
  final PersonalExpenseAnalytics? analytics;
  final bool analyticsLoading;
  final String? analyticsError;

  MyExpenseState({
    this.expenses = const [],
    this.isLoading = false,
    this.error,
    this.analytics,
    this.analyticsLoading = false,
    this.analyticsError,
  });

  MyExpenseState copyWith({
    List<MyExpense>? expenses,
    bool? isLoading,
    String? error,
    PersonalExpenseAnalytics? analytics,
    bool? analyticsLoading,
    String? analyticsError,
  }) {
    return MyExpenseState(
      expenses: expenses ?? this.expenses,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      analytics: analytics ?? this.analytics,
      analyticsLoading: analyticsLoading ?? this.analyticsLoading,
      analyticsError: analyticsError ?? this.analyticsError,
    );
  }

  double get totalAmount => expenses.fold(0.0, (sum, e) => sum + e.amount);

  double get monthlyTotal {
    final now = DateTime.now();
    return expenses
        .where((e) =>
            e.date.month == now.month && e.date.year == now.year)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  int get monthlyCount {
    final now = DateTime.now();
    return expenses
        .where((e) =>
            e.date.month == now.month && e.date.year == now.year)
        .length;
  }

  List<MyExpenseMonthlyGroup> get groupedByMonth {
    final sorted = List<MyExpense>.from(expenses)
      ..sort((a, b) => b.date.compareTo(a.date));

    final groups = <String, List<MyExpense>>{};
    for (final e in sorted) {
      final key = '${e.date.year}-${e.date.month.toString().padLeft(2, '0')}';
      groups.putIfAbsent(key, () => []).add(e);
    }

    final result = <MyExpenseMonthlyGroup>[];
    for (final entry in groups.entries) {
      final parts = entry.key.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final date = DateTime(year, month);
      final monthNames = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final total = entry.value.fold(0.0, (sum, e) => sum + e.amount);
      result.add(MyExpenseMonthlyGroup(
        label: '${monthNames[month]} $year',
        date: date,
        expenses: entry.value,
        total: total,
      ));
    }
    return result;
  }
}

class MyExpenseNotifier extends StateNotifier<MyExpenseState> {
  final ApiService _api;

  MyExpenseNotifier(this._api) : super(MyExpenseState());

  Future<void> loadExpenses() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.get('/me/expenses');
      final list = (response.data as List)
          .map((e) => MyExpense.fromJson(e))
          .toList();
      state = MyExpenseState(expenses: list);
      loadAnalytics();
    } catch (e) {
      state = MyExpenseState(error: e.toString());
    }
  }

  Future<void> addExpense(MyExpense expense) async {
    try {
      final response = await _api.post('/me/expenses', data: {
        'title': expense.title,
        'amount': expense.amount,
        'categoryId': expense.categoryId,
        'date': expense.date.toIso8601String(),
        'notes': expense.notes,
      });
      final created = MyExpense.fromJson(response.data);
      state = state.copyWith(expenses: [created, ...state.expenses]);
      loadAnalytics();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateExpense(MyExpense updated) async {
    try {
      final response = await _api.put('/me/expenses/${updated.id}', data: {
        'title': updated.title,
        'amount': updated.amount,
        'categoryId': updated.categoryId,
        'date': updated.date.toIso8601String(),
        'notes': updated.notes,
      });
      final saved = MyExpense.fromJson(response.data);
      state = state.copyWith(
        expenses: state.expenses.map((e) => e.id == saved.id ? saved : e).toList(),
      );
      loadAnalytics();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> loadAnalytics() async {
    state = state.copyWith(analyticsLoading: true, analyticsError: null);
    try {
      final response = await _api.get('/me/expenses/analytics');
      state = state.copyWith(
        analytics: PersonalExpenseAnalytics.fromJson(response.data),
        analyticsLoading: false,
      );
    } catch (e) {
      state = state.copyWith(analyticsLoading: false, analyticsError: e.toString());
    }
  }

  Future<void> deleteExpense(String id) async {
    state = state.copyWith(
      expenses: state.expenses.where((e) => e.id != id).toList(),
    );
    try {
      await _api.delete('/me/expenses/$id');
      await loadAnalytics();
    } catch (e) {
      await loadExpenses();
      state = state.copyWith(error: e.toString());
    }
  }
}

final myExpenseProvider =
    StateNotifierProvider<MyExpenseNotifier, MyExpenseState>((ref) {
  return MyExpenseNotifier(ref.watch(apiServiceProvider));
});
