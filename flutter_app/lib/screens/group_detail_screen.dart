import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/group.dart';
import '../models/expense.dart';
import '../models/expense_category.dart';
import '../models/currency.dart';
import '../providers/group_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
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

    return Scaffold(
      backgroundColor: surfaceBg,
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
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18, color: textSecondary),
                      SizedBox(width: 10),
                      Text('Edit Group', style: TextStyle(color: textPrimary)),
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
            color: Colors.white,
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
          ? _skeletonTabs()
          : group == null
              ? const Center(
                  child: Text('Group not found',
                      style: TextStyle(color: textSecondary)))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _expensesTab(expenseState, group, currency, user?.id ?? ''),
                    _balancesTab(expenseState, group, user?.id ?? '', currency),
                    _membersTab(group, groupState),
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

  Widget _skeletonTabs() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: List.generate(6, (_) => const Padding(
        padding: EdgeInsets.only(bottom: 8),
        child: SkeletonExpenseCard(),
      )),
    );
  }

  Widget _expensesTab(ExpenseState expenseState, Group group, Currency currency, String userId) {
    if (expenseState.isLoading) {
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
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.receipt_long_outlined,
                  size: 28, color: accent),
            ),
            const SizedBox(height: 16),
            const Text('No expenses yet',
                style: TextStyle(fontSize: 16, color: textPrimary,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            const Text('Add your first expense to get started',
                style: TextStyle(fontSize: 13, color: textSecondary)),
          ],
        ),
      );
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
            for (final section in grouped) ...[
              _dateHeader(section.label),
              for (final exp in section.expenses)
                _expenseCard(exp, group, currency, userId),
            ],
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

  Widget _dateHeader(String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 6, left: 2),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: textSecondary,
        ),
      ),
    );
  }

  Widget _expenseCard(Expense exp, Group group, Currency currency, String userId) {
    final isAdminUser = _isAdmin(group, userId);
    final category = ExpenseCategory.fromId(exp.category);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
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
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: textPrimary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                          Text(currency.format(exp.amount),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              )),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.person_outline,
                              size: 13, color: textSecondary.withValues(alpha: 0.7)),
                          const SizedBox(width: 4),
                          Text('Paid by ${exp.paidByName}',
                              style: const TextStyle(
                                  fontSize: 13, color: textSecondary)),
                          const Spacer(),
                          Text(
                            _timeAgo(exp.date),
                            style: TextStyle(
                              fontSize: 11,
                              color: textSecondary.withValues(alpha: 0.6),
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

  Widget _balancesTab(ExpenseState expenseState, Group group, String userId, Currency currency) {
    final balances = expenseState.balanceData;

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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderLight, width: 0.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.swap_horiz, size: 18, color: accent),
                          SizedBox(width: 8),
                          Text('Suggested Payments',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary)),
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
                                        style: const TextStyle(
                                            fontSize: 13, color: textPrimary),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(currency.format(t.amount),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: textPrimary)),
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderLight, width: 0.5),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 40, color: greenAccent),
                      SizedBox(height: 12),
                      Text("All settled up!",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textPrimary)),
                      SizedBox(height: 4),
                      Text("No one owes anything.",
                          style: TextStyle(
                              fontSize: 13, color: textSecondary)),
                    ],
                  ),
                ),
              ],
            ] else ...[
              const Center(
                child: Text('No balances to show',
                    style: TextStyle(color: textSecondary)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _membersTab(Group group, GroupState groupState) {
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
          ...activeMembers.map((m) => _memberTile(m)),
          if (inactiveMembers.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 8),
              child: Text('Left the group',
                  style: TextStyle(fontSize: 12, color: textSecondary)),
            ),
            ...inactiveMembers.map((m) => _memberTile(m, inactive: true)),
          ],
        ],
      ),
    );
  }

  Widget _memberTile(GroupMember m, {bool inactive = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: inactive ? surfaceBg : Colors.white,
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
                        color: inactive ? textSecondary : textPrimary)),
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
