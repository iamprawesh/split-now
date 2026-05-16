import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';

class NotificationState {
  final bool isLoading;
  final List<AppNotification> notifications;
  final int unreadCount;
  final String? error;

  NotificationState({
    this.isLoading = false,
    this.notifications = const [],
    this.unreadCount = 0,
    this.error,
  });

  NotificationState copyWith({
    bool? isLoading,
    List<AppNotification>? notifications,
    int? unreadCount,
    String? error,
  }) {
    return NotificationState(
      isLoading: isLoading ?? this.isLoading,
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      error: error,
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  final ApiService _api;

  NotificationNotifier(this._api) : super(NotificationState());

  Future<void> loadNotifications() async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _api.get('/notifications');
      final notifications = (response.data as List)
          .map((n) => AppNotification.fromJson(n))
          .toList();
      state = state.copyWith(isLoading: false, notifications: notifications);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadUnreadCount() async {
    try {
      final response = await _api.get('/notifications/unread-count');
      state = state.copyWith(unreadCount: response.data['count'] ?? 0);
    } catch (_) {}
  }

  Future<void> markAsRead(List<String> ids) async {
    try {
      await _api.post('/notifications/read', data: {'ids': ids});
      await loadUnreadCount();
    } catch (_) {}
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  return NotificationNotifier(ref.watch(apiServiceProvider));
});
