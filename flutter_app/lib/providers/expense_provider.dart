import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expense.dart';
import '../models/my_expense.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';
import 'group_provider.dart';

class ExpenseState {
  final bool isLoading;
  final bool isCreating;
  final bool isSettling;
  final bool isDeleting;
  final List<Expense> expenses;
  final BalanceData? balanceData;
  final List<Settlement> settlements;
  final String? error;
  final PersonalExpenseAnalytics? analytics;
  final bool analyticsLoading;
  final String? analyticsError;

  ExpenseState({
    this.isLoading = false,
    this.isCreating = false,
    this.isSettling = false,
    this.isDeleting = false,
    this.expenses = const [],
    this.balanceData,
    this.settlements = const [],
    this.error,
    this.analytics,
    this.analyticsLoading = false,
    this.analyticsError,
  });

  ExpenseState copyWith({
    bool? isLoading,
    bool? isCreating,
    bool? isSettling,
    bool? isDeleting,
    List<Expense>? expenses,
    BalanceData? balanceData,
    List<Settlement>? settlements,
    String? error,
    PersonalExpenseAnalytics? analytics,
    bool? analyticsLoading,
    String? analyticsError,
  }) {
    return ExpenseState(
      isLoading: isLoading ?? this.isLoading,
      isCreating: isCreating ?? this.isCreating,
      isSettling: isSettling ?? this.isSettling,
      isDeleting: isDeleting ?? this.isDeleting,
      expenses: expenses ?? this.expenses,
      balanceData: balanceData ?? this.balanceData,
      settlements: settlements ?? this.settlements,
      error: error,
      analytics: analytics ?? this.analytics,
      analyticsLoading: analyticsLoading ?? this.analyticsLoading,
      analyticsError: analyticsError ?? this.analyticsError,
    );
  }
}

class ExpenseNotifier extends StateNotifier<ExpenseState> {
  final ApiService _api;
  final Ref _ref;

  ExpenseNotifier(this._api, this._ref) : super(ExpenseState());

  Future<void> loadGroupAnalytics(String groupId) async {
    state = state.copyWith(analyticsLoading: true, analyticsError: null);
    try {
      final response = await _api.get('/groups/$groupId/expenses/analytics');
      state = state.copyWith(
        analytics: PersonalExpenseAnalytics.fromJson(response.data),
        analyticsLoading: false,
      );
    } catch (e) {
      state = state.copyWith(analyticsLoading: false, analyticsError: e.toString());
    }
  }

  Future<void> loadExpenses(String groupId) async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _api.get('/groups/$groupId/expenses');
      final expenses = (response.data as List)
          .map((e) => Expense.fromJson(e))
          .toList();
      state = state.copyWith(isLoading: false, expenses: expenses);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> createExpense(
    String groupId, {
    required String title,
    required String description,
    required String category,
    required double amount,
    required String paidBy,
    required String splitType,
    required List<Map<String, dynamic>> splits,
    String? date,
  }) async {
    state = state.copyWith(isCreating: true);

    final members = _ref.read(groupProvider).selectedGroup?.members ?? [];
    final memberMap = {for (final m in members) m.userId: m};
    final payer = memberMap[paidBy];

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final totalSplits = splits.length;
    final equalShare = totalSplits > 0 ? amount / totalSplits : 0.0;

    final optimisticExpense = Expense(
      id: tempId,
      group: groupId,
      title: title,
      description: description,
      category: category,
      amount: amount,
      paidById: paidBy,
      paidByName: payer?.name ?? '',
      paidByAvatar: payer?.avatar ?? '',
      splitType: splitType,
      splits: splits.map((s) {
        final m = memberMap[s['user']];
        return ExpenseSplit(
          userId: s['user'],
          name: m?.name ?? '',
          avatar: m?.avatar ?? '',
          value: (s['value'] ?? 0).toDouble(),
          amount: (s['amount'] ?? equalShare).toDouble(),
        );
      }).toList(),
      date: date != null ? DateTime.parse(date) : DateTime.now(),
    );
    state = state.copyWith(
      expenses: [optimisticExpense, ...state.expenses],
      isCreating: false,
    );

    try {
      await _api.post('/groups/$groupId/expenses', data: {
        'title': title,
        'description': description,
        'category': category,
        'amount': amount,
        'paidBy': paidBy,
        'splitType': splitType,
        'splits': splits,
        if (date != null) 'date': date,
      });
      await loadExpenses(groupId);
      loadGroupAnalytics(groupId);
    } catch (e) {
      state = state.copyWith(
        expenses: state.expenses.where((e) => e.id != tempId).toList(),
        error: e.toString(),
      );
    }
  }

  Future<void> loadBalances(String groupId) async {
    try {
      final response = await _api.get('/groups/$groupId/expenses/balances');
      state = state.copyWith(
        balanceData: BalanceData.fromJson(response.data),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> loadSettlements(String groupId) async {
    try {
      final response = await _api.get('/groups/$groupId/settlements');
      final settlements = (response.data as List)
          .map((s) => Settlement.fromJson(s))
          .toList();
      state = state.copyWith(settlements: settlements);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> createSettlement(
    String groupId, {
    required String from,
    required String to,
    required double amount,
  }) async {
    state = state.copyWith(isSettling: true);
    try {
      await _api.post('/groups/$groupId/settlements', data: {
        'from': from,
        'to': to,
        'amount': amount,
      });
      state = state.copyWith(isSettling: false);
      await loadSettlements(groupId);
      await loadBalances(groupId);
    } catch (e) {
      state = state.copyWith(isSettling: false, error: e.toString());
    }
  }

  Future<void> updateExpense(
    String groupId,
    String expenseId, {
    required String title,
    required String description,
    required String category,
    required double amount,
    required String paidBy,
    required String splitType,
    required List<Map<String, dynamic>> splits,
    String? date,
  }) async {
    state = state.copyWith(isCreating: true);

    final oldExpenses = state.expenses;

    try {
      final response = await _api.put('/groups/$groupId/expenses/$expenseId', data: {
        'title': title,
        'description': description,
        'category': category,
        'amount': amount,
        'paidBy': paidBy,
        'splitType': splitType,
        'splits': splits,
        if (date != null) 'date': date,
      });
      final updated = Expense.fromJson(response.data);
      state = state.copyWith(
        expenses: state.expenses.map((e) => e.id == expenseId ? updated : e).toList(),
        isCreating: false,
      );
      _refreshAnalytics(groupId);
    } catch (e) {
      state = state.copyWith(
        isCreating: false,
        expenses: oldExpenses,
        error: e.toString(),
      );
    }
  }

  Future<void> _refreshAnalytics(String groupId) async {
    try {
      final response = await _api.get('/groups/$groupId/expenses/analytics');
      state = state.copyWith(
        analytics: PersonalExpenseAnalytics.fromJson(response.data),
      );
    } catch (_) {}
  }

  Future<void> deleteExpense(String groupId, String expenseId) async {
    state = state.copyWith(isDeleting: true);
    try {
      await _api.delete('/groups/$groupId/expenses/$expenseId');
      state = state.copyWith(isDeleting: false);
      await loadExpenses(groupId);
      _refreshAnalytics(groupId);
    } catch (e) {
      state = state.copyWith(isDeleting: false, error: e.toString());
    }
  }
}

final expenseProvider =
    StateNotifierProvider<ExpenseNotifier, ExpenseState>((ref) {
  return ExpenseNotifier(ref.watch(apiServiceProvider), ref);
});
