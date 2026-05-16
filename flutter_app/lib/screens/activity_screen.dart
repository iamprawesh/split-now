import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/notification_provider.dart';
import '../widgets/loading_widgets.dart';
import '../main.dart';

class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key});

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(notificationProvider.notifier).loadNotifications();
      ref.read(notificationProvider.notifier).loadUnreadCount();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifState = ref.watch(notificationProvider);

    return Scaffold(
      backgroundColor: surfaceBg,
      appBar: AppBar(
        title: const Text('Activity'),
      ),
      body: notifState.isLoading
          ? _skeletonList()
          : notifState.notifications.isEmpty
              ? _emptyState()
              : _notificationList(notifState),
    );
  }

  Widget _skeletonList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      itemCount: 8,
      itemBuilder: (_, __) => const SkeletonNotificationTile(),
    );
  }

  Widget _emptyState() {
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
            child: const Icon(Icons.notifications_outlined,
                size: 28, color: accent),
          ),
          const SizedBox(height: 16),
          const Text('No activity yet',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textPrimary)),
          const SizedBox(height: 4),
          const Text('Expenses and payments will appear here.',
              style: TextStyle(fontSize: 13, color: textSecondary)),
        ],
      ),
    );
  }

  Widget _notificationList(NotificationState notifState) {
    return PullToRefresh(
      onRefresh: () =>
          ref.read(notificationProvider.notifier).loadNotifications(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        itemCount: notifState.notifications.length,
        itemBuilder: (context, index) {
          final n = notifState.notifications[index];
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
                    _icon(n.type),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(n.message,
                              style: const TextStyle(
                                  fontSize: 14,
                                  color: textPrimary,
                                  fontWeight: FontWeight.w500)),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('MMM d, h:mm a')
                                .format(n.createdAt),
                            style: const TextStyle(
                                fontSize: 12,
                                color: textSecondary),
                          ),
                        ],
                      ),
                    ),
                    if (!n.read)
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(left: 8),
                        decoration: const BoxDecoration(
                          color: accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _icon(String type) {
    IconData icon;
    Color color;
    switch (type) {
      case 'expense_added':
        icon = Icons.receipt_outlined;
        color = greenAccent;
        break;
      case 'settlement':
        icon = Icons.swap_horiz;
        color = accent;
        break;
      case 'member_joined':
        icon = Icons.person_add_outlined;
        color = const Color(0xFFF59E0B);
        break;
      default:
        icon = Icons.notifications_outlined;
        color = textSecondary;
    }
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }
}
