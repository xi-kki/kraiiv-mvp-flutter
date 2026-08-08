/// No-op fallback for platforms with no notification support.
class NotificationServicePlatform {
  static Future<void> initialize() async {}

  static Future<bool> enableDailyNudges() async => false;

  static Future<void> scheduleDailyReminder({
    required int hour,
    required String message,
  }) async {}

  static Future<void> scheduleStandardReminders() async {}

  static Future<void> cancelAll() async {}

  static Future<void> showTestNotification() async {}
}
