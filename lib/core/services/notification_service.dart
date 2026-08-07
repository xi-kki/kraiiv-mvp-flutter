import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone data
    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap
        debugPrint('Notification tapped: ${details.payload}');
      },
    );

    _initialized = true;
  }

  /// Schedule a daily reminder at the specified hour (24h format).
  static Future<void> scheduleDailyReminder({required int hour, required String message}) async {
    if (!_initialized) return;

    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, hour, 0, 0);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // Convert to TZDateTime
    final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

    const androidDetails = AndroidNotificationDetails(
      'kraiiv_reminders',
      'Meal Reminders',
      channelDescription: 'Daily reminders to log your meals',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );

    const details = NotificationDetails(android: androidDetails);

    await _plugin.zonedSchedule(
      hour, // notification id = hour
      'Kraiiv',
      message,
      tzScheduledDate,
      details,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'daily_reminder',
    );
  }

  /// Schedule standard daily reminders (9 AM, 1 PM, 7 PM)
  static Future<void> scheduleStandardReminders() async {
    final messages = [
      '🌅 Good morning! What\'s for breakfast today?',
      '🍲 Lunchtime! Don\'t forget to log your meal.',
      '🌆 Dinner time — what did you eat today?',
    ];

    final hours = [9, 13, 19]; // 9 AM, 1 PM, 7 PM

    for (int i = 0; i < hours.length; i++) {
      await scheduleDailyReminder(hour: hours[i], message: messages[i]);
    }
  }

  /// Cancel all scheduled reminders
  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /// Show an immediate test notification
  static Future<void> showTestNotification() async {
    if (!_initialized) return;

    const androidDetails = AndroidNotificationDetails(
      'kraiiv_reminders',
      'Meal Reminders',
      channelDescription: 'Daily reminders to log your meals',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const details = NotificationDetails(android: androidDetails);

    await _plugin.show(
      0,
      'Kraiiv 🌿',
      'This is a test notification — Klia is watching over your meals!',
      details,
    );
  }
}
