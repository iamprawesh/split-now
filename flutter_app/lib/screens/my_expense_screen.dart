import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/my_expense.dart';
import '../models/currency.dart';
import '../models/expense_category.dart';
import '../providers/my_expense_provider.dart';
import '../providers/settings_provider.dart';
import '../services/app_constants.dart';
import '../main.dart';

enum _ViewMode { list, charts }

class MyExpenseScreen extends ConsumerStatefulWidget {
  const MyExpenseScreen({super.key});

  @override
  ConsumerState<MyExpenseScreen> createState() => _MyExpenseScreenState();
}

class _MyExpenseScreenState extends ConsumerState<MyExpenseScreen> {
  _ViewMode _viewMode = _ViewMode.list;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(myExpenseProvider.notifier).loadExpenses();
    });
  }

  void _showAddSheet({MyExpense? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => MyExpenseFormSheet(existing: existing),
    );
  }

  Future<void> _confirmDelete(MyExpense expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Expense'),
        content: Text('Delete "${expense.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(myExpenseProvider.notifier).deleteExpense(expense.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(myExpenseProvider);
    final currency = ref.watch(currentCurrencyProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Expenses'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: SegmentedButton<_ViewMode>(
              segments: const [
                ButtonSegment(value: _ViewMode.list, icon: Icon(Icons.list, size: 18)),
                ButtonSegment(value: _ViewMode.charts, icon: Icon(Icons.bar_chart, size: 18)),
              ],
              selected: {_viewMode},
              onSelectionChanged: (sel) {
                setState(() => _viewMode = sel.first);
                if (sel.first == _ViewMode.charts) {
                  ref.read(myExpenseProvider.notifier).loadAnalytics();
                }
              },
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
      body: _viewMode == _ViewMode.charts
          ? _analyticsView(state, currency, isDark)
          : state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : state.error != null
                  ? _errorState(state.error!, isDark)
                  : state.expenses.isEmpty
                      ? _emptyState(isDark)
                      : _expenseList(state, currency, isDark),
      floatingActionButton: _viewMode == _ViewMode.charts || state.isLoading
          ? null
          : FloatingActionButton(
              onPressed: () => _showAddSheet(),
              child: const Icon(Icons.add, size: 24),
            ),
    );
  }

  Widget _errorState(String error, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: redAccent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.error_outline, size: 28, color: redAccent),
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: isDark ? textPrimaryDark : textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                error,
                style: const TextStyle(fontSize: 13, color: textSecondary),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () => ref.read(myExpenseProvider.notifier).loadExpenses(),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.receipt_long_outlined, size: 36, color: accent),
            ),
            const SizedBox(height: 20),
            Text(
              'No expenses yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDark ? textPrimaryDark : textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to add your first personal expense',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? textSecondaryDark : textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _expenseList(MyExpenseState state, Currency currency, bool isDark) {
    final groups = state.groupedByMonth;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
      itemCount: groups.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) return _summaryCard(state, currency, isDark);
        final group = groups[index - 1];
        return _monthGroup(group, currency, isDark);
      },
    );
  }

  Widget _analyticsView(MyExpenseState state, Currency currency, bool isDark) {
    final bgColor = isDark ? cardBgDark : Colors.white;
    final borderCol = isDark ? borderDark : borderLight;
    final textCol = isDark ? textPrimaryDark : textPrimary;
    final subtextCol = isDark ? textSecondaryDark : textSecondary;

    if (state.analyticsLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.analyticsError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: redAccent, size: 40),
            const SizedBox(height: 12),
            Text(state.analyticsError!, style: TextStyle(color: subtextCol)),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => ref.read(myExpenseProvider.notifier).loadAnalytics(),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    final analytics = state.analytics;
    if (analytics == null) {
      return const Center(child: Text('No data'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _analyticsSummaryCard(analytics, currency, isDark),
          const SizedBox(height: 20),
          _sectionHeader('Spending by Category', isDark),
          const SizedBox(height: 12),
          _pieChart(analytics, isDark),
          const SizedBox(height: 24),
          _sectionHeader('Monthly Trend', isDark),
          const SizedBox(height: 12),
          _lineChart(analytics, currency, isDark),
          const SizedBox(height: 16),
          _categoryBreakdown(analytics, currency, isDark, bgColor, borderCol, textCol, subtextCol),
        ],
      ),
    );
  }

  Widget _analyticsSummaryCard(PersonalExpenseAnalytics analytics, Currency currency, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent, accent.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Spent',
            style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            currency.format(analytics.totalSpent),
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            '${analytics.totalExpenses} ${analytics.totalExpenses == 1 ? 'expense' : 'expenses'} overall',
            style: const TextStyle(color: Colors.white60, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: isDark ? textPrimaryDark : textPrimary,
      ),
    );
  }

  Widget _pieChart(PersonalExpenseAnalytics analytics, bool isDark) {
    final categories = analytics.categoryTotals;
    if (categories.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text('No data', style: TextStyle(color: isDark ? textSecondaryDark : textSecondary)),
        ),
      );
    }

    final colors = [
      const Color(0xFF6C63FF), const Color(0xFFFF6584), const Color(0xFF00C9A7),
      const Color(0xFFFFA726), const Color(0xFF42A5F5), const Color(0xFFAB47BC),
      const Color(0xFF26C6DA), const Color(0xFF8D6E63), const Color(0xFF78909C),
      const Color(0xFF66BB6A),
    ];

    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? cardBgDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? borderDark : borderLight),
      ),
      child: Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sections: categories.asMap().entries.map((e) {
                  final i = e.key;
                  final cat = e.value;
                  return PieChartSectionData(
                    color: colors[i % colors.length],
                    value: cat.total,
                    title: AppFormat.percentOf(cat.total, analytics.totalSpent, decimals: 0),
                    titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                    radius: 50,
                  );
                }).toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 30,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: categories.take(6).toList().asMap().entries.map((e) {
              final i = e.key;
              final cat = e.value;
              final c = ExpenseCategory.fromId(cat.categoryId);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10, height: 10,
                      decoration: BoxDecoration(
                        color: colors[i % colors.length],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(c.name, style: TextStyle(fontSize: 11, color: isDark ? textSecondaryDark : textSecondary)),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _lineChart(PersonalExpenseAnalytics analytics, Currency currency, bool isDark) {
    final monthly = analytics.monthlyTotals;
    if (monthly.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text('No data', style: TextStyle(color: isDark ? textSecondaryDark : textSecondary)),
        ),
      );
    }

    final spots = monthly.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.total);
    }).toList();

    final maxY = monthly.fold<double>(0, (m, v) => v.total > m ? v.total : m);
    final minY = monthly.fold<double>(double.infinity, (m, v) => v.total < m ? v.total : m);
    final yRange = (maxY - minY).clamp(1, double.infinity);

    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      decoration: BoxDecoration(
        color: isDark ? cardBgDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? borderDark : borderLight),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: yRange / 4,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: (isDark ? borderDark : borderLight).withValues(alpha: 0.5),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= monthly.length) return const SizedBox.shrink();
                  final m = monthly[i];
                  final labels = ['', 'J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '${labels[m.month]}\n${m.year.toString().substring(2)}',
                      style: TextStyle(fontSize: 9, color: isDark ? textSecondaryDark : textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: accent,
              barWidth: 2.5,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 3,
                    color: accent,
                    strokeWidth: 1.5,
                    strokeColor: isDark ? cardBgDark : Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: accent.withValues(alpha: 0.1),
              ),
            ),
          ],
          minY: (minY - yRange * 0.1).clamp(0, double.infinity),
          maxY: maxY + yRange * 0.1,
        ),
      ),
    );
  }

  Widget _categoryBreakdown(
    PersonalExpenseAnalytics analytics,
    Currency currency,
    bool isDark,
    Color bgColor,
    Color borderCol,
    Color textCol,
    Color subtextCol,
  ) {
    final categories = analytics.categoryTotals;
    if (categories.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Category Breakdown', isDark),
        const SizedBox(height: 12),
        ...categories.map((cat) {
          final c = ExpenseCategory.fromId(cat.categoryId);
          final pct = analytics.totalSpent > 0 ? cat.total / analytics.totalSpent * 100 : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderCol),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: c.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(c.icon, color: c.color, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textCol)),
                        const SizedBox(height: 2),
                        Text('${cat.count} ${cat.count == 1 ? 'entry' : 'entries'}', style: TextStyle(fontSize: 11, color: subtextCol)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(currency.format(cat.total), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textCol)),
                      Text(AppFormat.percent(pct), style: TextStyle(fontSize: 11, color: subtextCol)),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _summaryCard(MyExpenseState state, Currency currency, bool isDark) {
    final now = DateTime.now();
    final monthName = DateFormat('MMMM').format(now);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent,
            accent.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$monthName Summary',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${state.monthlyCount} ${state.monthlyCount == 1 ? 'entry' : 'entries'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            currency.format(state.monthlyTotal),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'All time: ${currency.format(state.totalAmount)}',
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _monthGroup(MyExpenseMonthlyGroup group, Currency currency, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, top: 8, bottom: 8),
          child: Row(
            children: [
              Text(
                group.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? textPrimaryDark : textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                currency.format(group.total),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? textSecondaryDark : textSecondary,
                ),
              ),
            ],
          ),
        ),
        ...group.expenses.map((e) => _expenseTile(e, currency, isDark)),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _expenseTile(MyExpense expense, Currency currency, bool isDark) {
    final cat = ExpenseCategory.fromId(expense.categoryId);
    final bgColor = isDark ? cardBgDark : Colors.white;
    final borderColor = isDark ? borderDark : borderLight;
    final textCol = isDark ? textPrimaryDark : textPrimary;
    final subtextCol = isDark ? textSecondaryDark : textSecondary;

    return Dismissible(
      key: Key(expense.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: redAccent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 22),
      ),
      confirmDismiss: (_) async {
        _confirmDelete(expense);
        return false;
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        child: Material(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _showAddSheet(existing: expense),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor, width: 0.5),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: cat.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(cat.icon, color: cat.color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          expense.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textCol,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          cat.name,
                          style: TextStyle(
                            fontSize: 11,
                            color: subtextCol,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        currency.format(expense.amount),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textCol,
                        ),
                      ),
                      Text(
                        DateFormat('MMM dd').format(expense.date),
                        style: TextStyle(
                          fontSize: 11,
                          color: subtextCol,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MyExpenseFormSheet extends ConsumerStatefulWidget {
  final MyExpense? existing;
  const MyExpenseFormSheet({super.key, this.existing});

  @override
  ConsumerState<MyExpenseFormSheet> createState() => _MyExpenseFormSheetState();
}

class _MyExpenseFormSheetState extends ConsumerState<MyExpenseFormSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _notesCtrl;
  late DateTime _selectedDate;
  late String _categoryId;
  bool _userSelectedCategory = false;
  bool _userEditedTitle = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _amountCtrl = TextEditingController(
      text: e != null ? AppFormat.number(e.amount) : '',
    );
    _notesCtrl = TextEditingController(text: e?.notes ?? '');
    _selectedDate = e?.date ?? DateTime.now();
    _categoryId = e?.categoryId ?? 'other';
    _userEditedTitle = e != null && e.title.isNotEmpty;

    _titleCtrl.addListener(() {
      _userEditedTitle = true;
      if (!_userSelectedCategory) {
        final detected = ExpenseCategory.detectCategory(_titleCtrl.text);
        if (detected.id != _categoryId) {
          setState(() => _categoryId = detected.id);
        }
      }
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.existing != null;

  void _submit() {
    final title = _titleCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (title.isEmpty || amount == null || amount <= 0) return;

    final expense = MyExpense(
      id: widget.existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      amount: amount,
      categoryId: _categoryId,
      date: _selectedDate,
      notes: _notesCtrl.text.trim(),
    );

    if (_isEditing) {
      ref.read(myExpenseProvider.notifier).updateExpense(expense);
    } else {
      ref.read(myExpenseProvider.notifier).addExpense(expense);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currentCurrencyProvider);
    final cat = ExpenseCategory.fromId(_categoryId);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? cardBgDark : Colors.white;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? borderDark : borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _isEditing ? 'Edit Expense' : 'New Expense',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? textPrimaryDark : textPrimary,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _selectCategory,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: cat.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: cat.color.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Icon(cat.icon, color: cat.color, size: 22),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _titleCtrl,
                autofocus: !_isEditing,
                decoration: InputDecoration(
                  labelText: 'Title',
                  hintText: 'e.g. Groceries',
                  suffixIcon: GestureDetector(
                    onTap: _selectCategory,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        cat.name,
                        style: TextStyle(
                          fontSize: 11,
                          color: cat.color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _amountCtrl,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixText: '${currency.symbol} ',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    suffixIcon: Icon(Icons.calendar_today, size: 18),
                  ),
                  child: Text(
                    DateFormat('MMM dd, yyyy').format(_selectedDate),
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? textPrimaryDark : textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  hintText: 'Add details...',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: Text(_isEditing ? 'Update' : 'Add Expense'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectCategory() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.only(top: 16, bottom: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Select Category',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(ctx).brightness == Brightness.dark ? textPrimaryDark : textPrimary,
                    ),
                  ),
                ),
                Flexible(
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shrinkWrap: true,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: ExpenseCategory.all.length,
                    itemBuilder: (_, i) {
                      final c = ExpenseCategory.all[i];
                      final sel = c.id == _categoryId;
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _categoryId = c.id;
                            _userSelectedCategory = true;
                          });
                          if (!_userEditedTitle) {
                            _titleCtrl.text = c.defaultTitle;
                          }
                          Navigator.pop(ctx);
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: c.color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: sel
                                    ? Border.all(color: c.color, width: 2)
                                    : null,
                              ),
                              child: Icon(c.icon, color: c.color, size: 20),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              c.name,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10,
                                height: 1.1,
                                fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                                color: sel ? c.color : (Theme.of(ctx).brightness == Brightness.dark ? textSecondaryDark : textPrimary),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }
}
