import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/group_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/my_expense_provider.dart';
import 'auth_screen.dart';
import 'home_screen.dart';
import 'my_expense_screen.dart';
import 'activity_screen.dart';
import '../main.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _currentIndex = 0;

  void _onTabSelected(int i) {
    setState(() => _currentIndex = i);
    if (i == 0) {
      ref.read(groupProvider.notifier).loadGroups();
    } else if (i == 1) {
      ref.read(myExpenseProvider.notifier).loadExpenses();
    } else if (i == 2) {
      ref.read(notificationProvider.notifier).loadNotifications();
      ref.read(notificationProvider.notifier).loadUnreadCount();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (prev, next) {
      if (prev?.isAuthenticated == true && !next.isAuthenticated && !next.isLoading) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AuthScreen()),
        );
      }
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          HomeScreen(),
          MyExpenseScreen(),
          ActivityScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        height: 56,
        decoration: BoxDecoration(
          color: isDark ? cardBgDark : Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _navItem(Icons.groups_outlined, Icons.groups, 0, isDark),
            _navItem(Icons.receipt_long_outlined, Icons.receipt_long, 1, isDark),
            _navItem(Icons.notifications_outlined, Icons.notifications, 2, isDark),
          ],
        ),
      ),
    );
  }

  Widget _navItem(IconData outlined, IconData filled, int index, bool isDark) {
    final active = _currentIndex == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onTabSelected(index),
      child: SizedBox(
        width: 56,
        height: 56,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              active ? filled : outlined,
              size: 22,
              color: active ? accent : (isDark ? textSecondaryDark : textSecondary).withValues(alpha: 0.5),
            ),
            if (active)
              Positioned(
                bottom: 10,
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
