import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/group.dart';
import '../models/expense.dart';
import '../models/expense_category.dart';
import '../models/currency.dart';
import '../models/my_expense.dart';
import '../providers/group_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../services/app_constants.dart';
import '../widgets/loading_widgets.dart';
import '../main.dart';
import 'add_expense_screen.dart';
import 'create_group_screen.dart';
import 'settle_up_screen.dart';
import 'invite_screen.dart';

class GroupDetailScreen extends ConsumerStatefulWidget {
  final String groupId;
  const GroupDetailScreen({super.key, required this.groupId});

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showExpenseCharts = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    Future.microtask(() {
      ref.read(groupProvider.notifier).loadGroup(widget.groupId);
      ref.read(expenseProvider.notifier).loadExpenses(widget.groupId);
      ref.read(expenseProvider.notifier).loadBalances(widget.groupId);
    });
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      switch (_tabController.index) {
        case 0:
          ref.read(expenseProvider.notifier).loadExpenses(widget.groupId);
        case 1:
          ref.read(expenseProvider.notifier).loadBalances(widget.groupId);
      }
    }
  }

  bool _isAdmin(Group group, String userId) {
    return group.members.any(
      (m) => m.userId == userId && m.role == 'admin' && m.leftAt == null,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupState = ref.watch(groupProvider);
    final expenseState = ref.watch(expenseProvider);
    final group = groupState.selectedGroup;
    final user = ref.watch(authProvider).user;
    final currency = ref.watch(currentCurrencyProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(group?.name ?? ''),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (group != null && _isAdmin(group, user?.id ?? ''))
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 22),
              onSelected: (value) {
                if (value == 'edit') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreateGroupScreen(group: group),
                    ),
                  );
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18,
                          color: isDark ? textSecondaryDark : textSecondary),
                      const SizedBox(width: 10),
                      Text('Edit Group',
                          style: TextStyle(
                              color: isDark ? textPrimaryDark : textPrimary)),
                    ],
                  ),
                ),
              ],
            ),
          IconButton(
            icon: const Icon(Icons.share_outlined, size: 22),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => InviteScreen(groupId: widget.groupId),
                ),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: isDark ? cardBgDark : Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              labelPadding: const EdgeInsets.symmetric(vertical: 0),
              tabs: const [
                Tab(text: 'Expenses'),
                Tab(text: 'Balance'),
                Tab(text: 'Members'),
              ],
            ),
          ),
        ),
      ),
      body: groupState.isLoading
          ? _skeletonTabs(isDark)
          : group == null
              ? Center(
                  child: Text('Group not found',
                      style: TextStyle(
                          color: isDark ? textSecondaryDark : textSecondary)))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _expensesTab(expenseState, group, currency, user?.id ?? '', isDark),
                    _balancesTab(expenseState, group, user?.id ?? '', currency, isDark),
                    _membersTab(group, groupState, isDark),
                  ],
                ),
      floatingActionButton: group != null
          ? SizedBox(
              width: 52,
              height: 52,
              child: FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddExpenseScreen(
                        groupId: widget.groupId,
                        members: group.members,
                      ),
                    ),
                  );
                },
                child: const Icon(Icons.add, size: 24),
              ),
            )
          : null,
    );
  }

  Widget _skeletonTabs(bool isDark) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: List.generate(6, (_) => const Padding(
        padding: EdgeInsets.only(bottom: 8),
        child: SkeletonExpenseCard(),
      )),
    );
  }

  Widget _expensesTab(ExpenseState expenseState, Group group, Currency currency, String userId, bool isDark) {
    if (expenseState.isLoading && expenseState.expenses.isEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
        itemCount: 5,
        itemBuilder: (_, __) => const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: SkeletonExpenseCard(),
        ),
      );
    }
    if (expenseState.expenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.receipt_long_outlined, size: 28, color: accent),
            ),
            const SizedBox(height: 16),
            Text('No expenses yet',
                style: TextStyle(fontSize: 16,
                    color: isDark ? textPrimaryDark : textPrimary,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Add your first expense to get started',
                style: TextStyle(fontSize: 13,
                    color: isDark ? textSecondaryDark : textSecondary)),
          ],
        ),
      );
    }

    if (_showExpenseCharts) {
      return _groupAnalyticsView(expenseState, currency, isDark);
    }

    final grouped = _groupExpensesByDate(expenseState.expenses);
    return PullToRefresh(
      onRefresh: () async {
        await ref.read(expenseProvider.notifier).loadExpenses(widget.groupId);
      },
      child: LoadingOverlay(
        isLoading: expenseState.isDeleting,
        message: 'Removing expense...',
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
          children: [
            _viewToggle(expenseState, isDark),
            for (final section in grouped) ...[
              _dateHeader(section.label, isDark),
              for (final exp in section.expenses)
                _expenseCard(exp, group, currency, userId, isDark),
            ],
          ],
        ),
      ),
    );
  }

  Widget _viewToggle(ExpenseState expenseState, bool isDark) {
    final bgCol = isDark ? const Color(0xFF1E1E2C) : const Color(0xFFF1F3F5);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: bgCol,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          children: [
            _toggleBtn(Icons.list, 'List', _showExpenseCharts == false, false, isDark),
            const SizedBox(width: 2),
            _toggleBtn(Icons.bar_chart, 'Chart', _showExpenseCharts == true, true, isDark),
          ],
        ),
      ),
    );
  }

  Widget _toggleBtn(IconData icon, String label, bool active, bool charts, bool isDark) {
    return GestureDetector(
      onTap: () {
        setState(() => _showExpenseCharts = charts);
        if (charts) {
          ref.read(expenseProvider.notifier).loadGroupAnalytics(widget.groupId);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? accent : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15,
                color: active ? Colors.white : (isDark ? textSecondaryDark : const Color(0xFF6B7280))),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : (isDark ? textSecondaryDark : const Color(0xFF6B7280)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _dateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateDay = DateTime(date.year, date.month, date.day);
    final diff = today.difference(dateDay).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff <= 7) {
      switch (date.weekday) {
        case 1: return 'Monday';
        case 2: return 'Tuesday';
        case 3: return 'Wednesday';
        case 4: return 'Thursday';
        case 5: return 'Friday';
        case 6: return 'Saturday';
        case 7: return 'Sunday';
      }
    }

    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    if (date.year == now.year) {
      return '${months[date.month - 1]} ${date.day}';
    }
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  List<({String label, List<Expense> expenses})> _groupExpensesByDate(
      List<Expense> expenses) {
    final Map<int, List<Expense>> grouped = {};
    for (final exp in expenses) {
      final key = DateTime(exp.date.year, exp.date.month, exp.date.day)
          .millisecondsSinceEpoch;
      grouped.putIfAbsent(key, () => []).add(exp);
    }
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    return sortedKeys.map((key) {
      final date = DateTime.fromMillisecondsSinceEpoch(key);
      return (label: _dateLabel(date), expenses: grouped[key]!);
    }).toList();
  }

  Widget _dateHeader(String label, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 6, left: 2),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isDark ? textSecondaryDark : textSecondary,
        ),
      ),
    );
  }

  Widget _expenseCard(Expense exp, Group group, Currency currency, String userId, bool isDark) {
    final isAdminUser = _isAdmin(group, userId);
    final category = ExpenseCategory.fromId(exp.category);
    final bgColor = isDark ? cardBgDark : Colors.white;
    final textCol = isDark ? textPrimaryDark : textPrimary;
    final subtextCol = isDark ? textSecondaryDark : textSecondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.04),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: isAdminUser
              ? () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddExpenseScreen(
                        groupId: widget.groupId,
                        members: group.members,
                        expense: exp,
                      ),
                    ),
                  )
              : null,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    color: category.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(category.icon, color: category.color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(exp.title,
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: textCol),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                          Text(currency.format(exp.amount),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: textCol,
                              )),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.person_outline,
                              size: 13, color: subtextCol.withValues(alpha: 0.7)),
                          const SizedBox(width: 4),
                          Text('Paid by ${exp.paidByName}',
                              style: TextStyle(
                                  fontSize: 13, color: subtextCol)),
                          const Spacer(),
                          Text(
                            _timeAgo(exp.date),
                            style: TextStyle(
                              fontSize: 11,
                              color: subtextCol.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${diff.inDays ~/ 7}w ago';
  }

  Widget _groupAnalyticsView(ExpenseState expenseState, Currency currency, bool isDark) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: _viewToggle(expenseState, isDark),
        ),
        Expanded(
          child: _groupAnalyticsBody(expenseState, currency, isDark),
        ),
      ],
    );
  }

  Widget _groupAnalyticsBody(ExpenseState expenseState, Currency currency, bool isDark) {
    final bgColor = isDark ? cardBgDark : Colors.white;
    final borderCol = isDark ? borderDark : borderLight;
    final textCol = isDark ? textPrimaryDark : textPrimary;
    final subtextCol = isDark ? textSecondaryDark : textSecondary;

    if (expenseState.analyticsLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (expenseState.analyticsError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: redAccent, size: 40),
            const SizedBox(height: 12),
            Text(expenseState.analyticsError!, style: TextStyle(color: subtextCol)),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => ref.read(expenseProvider.notifier).loadGroupAnalytics(widget.groupId),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    final analytics = expenseState.analytics;
    if (analytics == null) {
      return const Center(child: Text('No data'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _groupAnalyticsSummary(analytics, currency, isDark),
          const SizedBox(height: 20),
          _sectionHeader('Spending by Category', isDark),
          const SizedBox(height: 12),
          _groupPieChart(analytics, isDark),
          const SizedBox(height: 24),
          _sectionHeader('Monthly Trend', isDark),
          const SizedBox(height: 12),
          _groupLineChart(analytics, currency, isDark),
          const SizedBox(height: 16),
          _groupCategoryBreakdown(analytics, currency, isDark, bgColor, borderCol, textCol, subtextCol),
        ],
      ),
    );
  }

  Widget _groupAnalyticsSummary(PersonalExpenseAnalytics analytics, Currency currency, bool isDark) {
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
          BoxShadow(color: accent.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total Spent', style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text(currency.format(analytics.totalSpent),
              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('${analytics.totalExpenses} ${analytics.totalExpenses == 1 ? 'expense' : 'expenses'} overall',
              style: const TextStyle(color: Colors.white60, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, bool isDark) {
    return Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
        color: isDark ? textPrimaryDark : textPrimary));
  }

  Widget _groupPieChart(PersonalExpenseAnalytics analytics, bool isDark) {
    final categories = analytics.categoryTotals;
    if (categories.isEmpty) {
      return SizedBox(height: 200,
          child: Center(child: Text('No data', style: TextStyle(color: isDark ? textSecondaryDark : textSecondary))));
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
                    Container(width: 10, height: 10,
                        decoration: BoxDecoration(color: colors[i % colors.length], borderRadius: BorderRadius.circular(2))),
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

  Widget _groupLineChart(PersonalExpenseAnalytics analytics, Currency currency, bool isDark) {
    final monthly = analytics.monthlyTotals;
    if (monthly.isEmpty) {
      return SizedBox(height: 200,
          child: Center(child: Text('No data', style: TextStyle(color: isDark ? textSecondaryDark : textSecondary))));
    }

    final spots = monthly.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.total)).toList();
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
            show: true, drawVerticalLine: false,
            horizontalInterval: yRange / 4,
            getDrawingHorizontalLine: (value) => FlLine(
              color: (isDark ? borderDark : borderLight).withValues(alpha: 0.5), strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true, reservedSize: 28, interval: 1,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= monthly.length) return const SizedBox.shrink();
                  final m = monthly[i];
                  final labels = ['', 'J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text('${labels[m.month]}\n${m.year.toString().substring(2)}',
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
              spots: spots, isCurved: true, color: accent, barWidth: 2.5,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                  radius: 3, color: accent, strokeWidth: 1.5,
                  strokeColor: isDark ? cardBgDark : Colors.white,
                ),
              ),
              belowBarData: BarAreaData(show: true, color: accent.withValues(alpha: 0.1)),
            ),
          ],
          minY: (minY - yRange * 0.1).clamp(0, double.infinity),
          maxY: maxY + yRange * 0.1,
        ),
      ),
    );
  }

  Widget _groupCategoryBreakdown(
    PersonalExpenseAnalytics analytics, Currency currency, bool isDark,
    Color bgColor, Color borderCol, Color textCol, Color subtextCol,
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
                color: bgColor, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderCol),
              ),
              child: Row(
                children: [
                  Container(width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: c.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10),
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
                        Text('${cat.count} ${cat.count == 1 ? 'entry' : 'entries'}',
                            style: TextStyle(fontSize: 11, color: subtextCol)),
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

  Widget _balancesTab(ExpenseState expenseState, Group group, String userId, Currency currency, bool isDark) {
    final balances = expenseState.balanceData;
    final bgColor = isDark ? cardBgDark : Colors.white;
    final textCol = isDark ? textPrimaryDark : textPrimary;
    final subtextCol = isDark ? textSecondaryDark : textSecondary;
    final borderCol = isDark ? borderDark : borderLight;

    return PullToRefresh(
      onRefresh: () async {
        await ref.read(expenseProvider.notifier).loadBalances(widget.groupId);
      },
      child: LoadingOverlay(
        isLoading: expenseState.isSettling,
        message: 'Processing payment...',
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
          children: [
            if (balances != null) ...[
              if (balances.transactions.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderCol, width: 0.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.swap_horiz, size: 18, color: accent),
                          const SizedBox(width: 8),
                          Text('Suggested Payments',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: textCol)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...balances.transactions.map((t) {
                        final fromMember = group.members.firstWhere(
                          (m) => m.userId == t.from,
                          orElse: () => group.members.first,
                        );
                        final toMember = group.members.firstWhere(
                          (m) => m.userId == t.to,
                          orElse: () => group.members.first,
                        );
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 14,
                                      backgroundColor:
                                          accent.withValues(alpha: 0.08),
                                      child: Text(
                                        fromMember.name.isNotEmpty
                                            ? fromMember.name[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                            color: accent,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 6),
                                      child: Icon(Icons.arrow_forward,
                                          size: 14, color: textSecondary),
                                    ),
                                    CircleAvatar(
                                      radius: 14,
                                      backgroundColor:
                                          greenAccent.withValues(alpha: 0.1),
                                      child: Text(
                                        toMember.name.isNotEmpty
                                            ? toMember.name[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                            color: greenAccent,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        '${fromMember.name} → ${toMember.name}',
                                        style: TextStyle(
                                            fontSize: 13, color: textCol),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(currency.format(t.amount),
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: textCol)),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SettleUpScreen(
                                  groupId: widget.groupId,
                                  members: group.members,
                                  transactions: balances.transactions,
                                  userId: userId,
                                ),
                              ),
                            );
                          },
                          child: const Text('Settle Up'),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderCol, width: 0.5),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.check_circle_outline,
                          size: 40, color: greenAccent),
                      const SizedBox(height: 12),
                      Text("All settled up!",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textCol)),
                      const SizedBox(height: 4),
                      Text("No one owes anything.",
                          style: TextStyle(
                              fontSize: 13, color: subtextCol)),
                    ],
                  ),
                ),
              ],
            ] else ...[
              Center(
                child: Text('No balances to show',
                    style: TextStyle(
                        color: isDark ? textSecondaryDark : textSecondary)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _membersTab(Group group, GroupState groupState, bool isDark) {
    final activeMembers =
        group.members.where((m) => m.leftAt == null).toList();
    final inactiveMembers =
        group.members.where((m) => m.leftAt != null).toList();

    return LoadingOverlay(
      isLoading: groupState.isTogglingMember,
      message: 'Updating members...',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          ...activeMembers.map((m) => _memberTile(m, isDark, inactive: false)),
          if (inactiveMembers.isNotEmpty) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text('Left the group',
                  style: TextStyle(fontSize: 12,
                      color: isDark ? textSecondaryDark : textSecondary)),
            ),
            ...inactiveMembers.map((m) => _memberTile(m, isDark, inactive: true)),
          ],
        ],
      ),
    );
  }

  Widget _memberTile(GroupMember m, bool isDark, {bool inactive = false}) {
    final bgColor = isDark ? (inactive ? surfaceBgDark : cardBgDark)
                           : (inactive ? surfaceBg : Colors.white);
    final textCol = isDark ? textPrimaryDark : textPrimary;
    final subtextCol = isDark ? textSecondaryDark : textSecondary;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: accent.withValues(alpha: 0.08),
                backgroundImage: m.avatar.isNotEmpty
                    ? NetworkImage(m.avatar)
                    : null,
                child: m.avatar.isEmpty
                    ? Text(m.name[0].toUpperCase(),
                        style: const TextStyle(
                            color: accent,
                            fontWeight: FontWeight.w600,
                            fontSize: 15))
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(m.name,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: inactive ? subtextCol : textCol)),
              ),
              if (m.role == 'admin')
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Admin',
                      style: TextStyle(
                          fontSize: 12,
                          color: accent,
                          fontWeight: FontWeight.w500)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
