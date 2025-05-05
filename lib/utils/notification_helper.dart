import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationHelper {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static void initialize() {
    final InitializationSettings initializationSettings =
        InitializationSettings(
            android:
                AndroidInitializationSettings("@drawable/notification_icon"));

    _notificationsPlugin.initialize(initializationSettings);
  }

  static void display(String title, String body) async {
    try {
      final NotificationDetails notificationDetails = NotificationDetails(
          android: AndroidNotificationDetails(
        "reclamationChannel",
        "Reclamation Notifications",
        importance: Importance.max,
        priority: Priority.high,
      ));

      await _notificationsPlugin.show(
        0,
        title,
        body,
        notificationDetails,
      );
    } catch (e) {
      print(e.toString());
    }
  }
}
