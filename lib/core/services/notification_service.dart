import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:developer' as developer;

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  NotificationService() {
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(initSettings);
    developer.log('Notifications initialized', name: 'NotificationService');
  }

  Future<void> showNotification({
    required String title,
    required String body,
    int id = 0,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'reclamation_channel',
      'Reclamation Notifications',
      channelDescription: 'Notifications for reclamation updates',
      importance: Importance.max,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
    );
    developer.log('Notification shown: $title - $body',
        name: 'NotificationService');
  }

  void showLocalNotification({
    required String title,
    required String body,
    int id = 0,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'reclamation_channel',
      'Reclamation Notifications',
      channelDescription: 'Notifications for reclamation updates',
      importance: Importance.max,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
    );
    developer.log('Notification shown: $title - $body',
        name: 'NotificationService');
  }

  initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(initSettings);
    developer.log('Notifications initialized', name: 'NotificationService');
  }

  cancelAllNotifications() {}

  scheduleDailyReminder(int i, String s, String t, int hour, int minute) {}

  requestPermissions() {}
}
