import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../core/api_client.dart';
import '../core/app_logger.dart';

/// Must be a top-level function (not a class method) - this is how the
/// Firebase Messaging plugin requires background handlers to be registered.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Nothing to do here beyond letting the OS show the system tray
  // notification automatically for a message with a "notification" block,
  // which is how the backend's NotificationService sends every push.
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // IMPORTANT: never eagerly grab FirebaseMessaging.instance as a field
  // initializer - that call throws immediately if Firebase.initializeApp()
  // hasn't succeeded yet (e.g. on web without firebase config, or on a
  // fresh install before google-services.json/GoogleService-Info.plist are
  // added). Access it lazily instead, only after confirming an app exists.
  FirebaseMessaging? get _messagingOrNull => Firebase.apps.isEmpty ? null : FirebaseMessaging.instance;

  final _localNotifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Call once after a successful login. Requests permission, sets up
  /// foreground notification display, and registers this device's FCM
  /// token with the backend so trip-assigned / expense-submitted pushes
  /// can reach it. No-ops quietly if Firebase isn't configured yet.
  Future<void> initAfterLogin() async {
    final messaging = _messagingOrNull;
    if (messaging == null) return;

    if (!_initialized) {
      await _setupLocalNotifications();
      FirebaseMessaging.onMessage.listen(_showForegroundNotification);
      _initialized = true;
    }

    try {
      await messaging.requestPermission(alert: true, badge: true, sound: true);

      final token = await messaging.getToken();
      if (token != null) {
        await _registerToken(token);
      }
      // Token can rotate (app reinstall, OS-level refresh) - keep the backend in sync.
      messaging.onTokenRefresh.listen(_registerToken);
    } catch (e) {
      AppLogger.w('Notifications', 'Push notification setup skipped', error: e);
    }
  }

  Future<void> _setupLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'logisticfleet_default',
      'Logistic Fleet notifications',
      channelDescription: 'Trip assignments and expense updates',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails, iOS: DarwinNotificationDetails());

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      notification.title,
      notification.body,
      details,
    );
  }

  Future<void> _registerToken(String token) async {
    try {
      await ApiClient.instance.dio.post('/notifications/register-token', data: {
        'fcmToken': token,
        'platform': defaultTargetPlatform.name,
      });
    } catch (_) {
      // Best-effort - a failed registration just means this device won't
      // get pushes until the next successful login/refresh.
    }
  }

  /// Call on logout so this device stops receiving the signed-out user's
  /// notifications. No-ops quietly if Firebase isn't configured yet.
  Future<void> unregister() async {
    final messaging = _messagingOrNull;
    if (messaging == null) return;

    try {
      final token = await messaging.getToken();
      if (token == null) return;
      await ApiClient.instance.dio.delete('/notifications/register-token', queryParameters: {'fcmToken': token});
    } catch (_) {
      // ignore - non-critical cleanup
    }
  }
}