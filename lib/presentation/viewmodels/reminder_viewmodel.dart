import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/notification_service.dart';

class ReminderViewModel extends ChangeNotifier {
  final NotificationService _notificationService;
  final SharedPreferences _prefs;
  
  TimeOfDay? _reminderTime;
  bool _remindersEnabled = false;

  ReminderViewModel({
    required NotificationService notificationService,
    required SharedPreferences prefs,
  })  : _notificationService = notificationService,
        _prefs = prefs {
    _loadReminderSettings();
  }

  bool get remindersEnabled => _remindersEnabled;
  TimeOfDay? get reminderTime => _reminderTime;

  Future<void> _loadReminderSettings() async {
    final hour = _prefs.getInt('reminder_hour');
    final minute = _prefs.getInt('reminder_minute');
    _remindersEnabled = _prefs.getBool('reminders_enabled') ?? false;

    if (hour != null && minute != null) {
      _reminderTime = TimeOfDay(hour: hour, minute: minute);
    }
    notifyListeners();
  }

  Future<void> setReminderTime(TimeOfDay time, bool enabled) async {
    _reminderTime = time;
    _remindersEnabled = enabled;
    
    // Save to persistent storage
    await _prefs.setInt('reminder_hour', time.hour);
    await _prefs.setInt('reminder_minute', time.minute);
    await _prefs.setBool('reminders_enabled', enabled);

    // Update notifications
    if (enabled) {
      await _scheduleReminders(time);
    } else {
      await _notificationService.cancelAllNotifications();
    }
    
    notifyListeners();
  }

  Future<void> toggleReminders(bool enabled) async {
    if (enabled && _reminderTime == null) {
      // Set default time if none exists
      await setReminderTime(const TimeOfDay(hour: 20, minute: 0), true);
      return;
    }
    
    await setReminderTime(_reminderTime!, enabled);
  }

  Future<void> _scheduleReminders(TimeOfDay time) async {
    await _notificationService.cancelAllNotifications();
    await _notificationService.scheduleDailyReminder(
      1, // Notification ID
      'SkillGenie ', // Title
      'Time to practice your skills!', // Body
      time.hour, 
      time.minute,
    );
  }

  String get formattedTime {
    if (_reminderTime == null) return 'Not set';
    final hour = _reminderTime!.hourOfPeriod;
    final minute = _reminderTime!.minute.toString().padLeft(2, '0');
    final period = _reminderTime!.period.name.toUpperCase();
    return '$hour:$minute $period';
  }

  Future<void> updateNotificationContent() async {
    if (_remindersEnabled && _reminderTime != null) {
      await _scheduleReminders(_reminderTime!);
    }
  }

  Future<void> cancelAllReminders() async {
    await _notificationService.cancelAllNotifications();
    await _prefs.remove('reminder_hour');
    await _prefs.remove('reminder_minute');
    await _prefs.setBool('reminders_enabled', false);
    _remindersEnabled = false;
    _reminderTime = null;
    notifyListeners();
  }
}