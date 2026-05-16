import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/group.dart';
import '../models/expense.dart';
import '../models/currency.dart';
import '../providers/expense_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/loading_widgets.dart';
import '../providers/auth_provider.dart';
import '../main.dart';

class SettleUpScreen extends ConsumerStatefulWidget {
  final String groupId;
  final List<GroupMember> members;
  final List<Transaction> transactions;
  final String userId;

  const SettleUpScreen({
    super.key,
    required this.groupId,
    required this.members,
    required this.transactions,
    required this.userId,
  });

  @override
  ConsumerState<SettleUpScreen> createState() => _SettleUpScreenState();
}

class _SettleUpScreenState extends ConsumerState<SettleUpScreen> {
  final Set<String> _reminding = {};

  Future<void> _sendRemind(String userId, String userName) async {
    setState(() => _reminding.add(userId));
    try {
      final api = ref.read(apiServiceProvider);
      await api.post('/groups/${widget.groupId}/settlements/remind/$userId');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reminder sent to $userName')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send reminder: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _reminding.remove(userId));
    }
  }

  String _memberName(String id) {
    final m = widget.members.firstWhere(
      (m) => m.userId == id,
      orElse: () => widget.members.first,
    );
    return m.name;
  }

  @override
  Widget build(BuildContext context) {
    final expenseState = ref.watch(expenseProvider);
    final currency = ref.watch(currentCurrencyProvider);

    final relevant = widget.transactions
        .where((t) => t.from == widget.userId || t.to == widget.userId)
        .toList();

    final other = widget.transactions
        .where((t) => t.from != widget.userId && t.to != widget.userId)
        .toList();

    return Scaffold(
      backgroundColor: surfaceBg,
      appBar: AppBar(
        title: const Text('Settle Up'),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: LoadingOverlay(
        isLoading: expenseState.isSettling,
        message: 'Processing payment...',
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            if (relevant.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 12),
                child: Text('Your payments',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textSecondary)),
              ),
              ...relevant.map((tx) {
                final isOwing = tx.from == widget.userId;
                final otherName = isOwing ? _memberName(tx.to) : _memberName(tx.from);
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: isOwing
                                      ? redAccent.withValues(alpha: 0.08)
                                      : greenAccent.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  isOwing
                                      ? Icons.arrow_upward
                                      : Icons.arrow_downward,
                                  color: isOwing ? redAccent : greenAccent,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isOwing
                                          ? 'You owe $otherName'
                                          : '$otherName owes you',
                                      style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: textPrimary),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(currency.format(tx.amount),
                                        style: const TextStyle(
                                            fontSize: 14,
                                            color: textSecondary)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: isOwing
                                ? ElevatedButton(
                                    onPressed: expenseState.isSettling
                                        ? null
                                        : () => _confirm(tx, currency),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 10),
                                      backgroundColor: accent,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      textStyle: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600),
                                    ),
                                    child: expenseState.isSettling
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white),
                                          )
                                        : const Text('Pay'),
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ElevatedButton(
                                        onPressed: expenseState.isSettling
                                            ? null
                                            : () => _confirm(tx, currency),
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 14, vertical: 10),
                                          backgroundColor: greenAccent,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          textStyle: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600),
                                        ),
                                        child: const Text('Settle Up'),
                                      ),
                                      const SizedBox(width: 8),
                                      OutlinedButton.icon(
                                        onPressed: _reminding.contains(tx.from)
                                            ? null
                                            : () => _sendRemind(
                                                tx.from,
                                                _memberName(tx.from)),
                                        style: OutlinedButton.styleFrom(
                                          padding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 14,
                                                  vertical: 10),
                                          foregroundColor: textSecondary,
                                          side: BorderSide(
                                              color: textSecondary
                                                  .withValues(alpha: 0.3)),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          textStyle: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600),
                                        ),
                                        icon: _reminding.contains(tx.from)
                                            ? const SizedBox(
                                                width: 14,
                                                height: 14,
                                                child:
                                                    CircularProgressIndicator(
                                                        strokeWidth: 2),
                                              )
                                            : const Icon(
                                                Icons.notifications_none,
                                                size: 18),
                                        label: Text(_reminding.contains(
                                                tx.from)
                                            ? 'Sending'
                                            : 'Remind'),
                                      ),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
            if (other.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 12),
                child: Text('Other payments',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textSecondary)),
              ),
              ...other.map((tx) {
                final from = _memberName(tx.from);
                final to = _memberName(tx.to);
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          Text('$from → $to',
                              style: const TextStyle(
                                  fontSize: 14, color: textSecondary)),
                          const Spacer(),
                          Text(currency.format(tx.amount),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: textPrimary)),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
            if (relevant.isEmpty && other.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 60),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 48, color: greenAccent),
                      SizedBox(height: 16),
                      Text('No payments to show',
                          style: TextStyle(
                              fontSize: 16, color: textSecondary)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _confirm(Transaction tx, Currency currency) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.check_circle_outline, color: greenAccent),
              title: Text('Pay ${currency.format(tx.amount)} to ${_memberName(tx.to)}'),
              onTap: () {
                ref.read(expenseProvider.notifier).createSettlement(
                      widget.groupId,
                      from: tx.from,
                      to: tx.to,
                      amount: tx.amount,
                    );
                Navigator.pop(context);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.close, color: textSecondary),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
