import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../firebase_options.dart';
import 'api_service.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref.read(apiServiceProvider));
});

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

class NotificationService {
  final ApiService _api;
  final FlutterLocalNotificationsPlugin _localNotifications;
  bool _initialized = false;
  int _notifId = 0;

  NotificationService(this._api)
      : _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      const androidSettings = AndroidInitializationSettings('ic_notification');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );
      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (_) {},
      );
      debugPrint('[Notif] Local notifications initialized');

      final messaging = FirebaseMessaging.instance;

      final notifSettings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('[Notif] Permission: ${notifSettings.authorizationStatus}');

      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      debugPrint('[Notif] Background handler registered');

      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      debugPrint('[Notif] Foreground listener registered');

      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('[Notif] Had initial message');
        _handleNotificationTap(initialMessage);
      }

      await _registerToken();

      messaging.onTokenRefresh.listen(_registerToken);
      debugPrint('[Notif] Token refresh listener registered');
    } catch (e) {
      debugPrint('[Notif] Init error: $e');
    }
  }

  Future<void> _registerToken([String? token]) async {
    try {
      final fcmToken = token ?? await FirebaseMessaging.instance.getToken();
      debugPrint('[Notif] FCM token: ${fcmToken?.substring(0, 30)}...');
      if (fcmToken == null) {
        debugPrint('[Notif] FCM token is null');
        return;
      }
      await _api.post('/auth/fcm-token', data: {'fcmToken': fcmToken});
      debugPrint('[Notif] Token registered with backend');
    } catch (e) {
      debugPrint('[Notif] Token registration error: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('[Notif] Foreground message: ${message.notification?.title}');
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      _notifId++,
      notification.title ?? '',
      notification.body ?? '',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'splitEase_expenses',
          'Expenses',
          channelDescription: 'Expense and group activity notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_notification',
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
    debugPrint('[Notif] Local notification shown');
  }

  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('[Notif] Tapped: ${message.data}');
  }
}
