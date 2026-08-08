import 'notification_platform_stub.dart'
    if (dart.library.js_interop) 'notification_platform_web.dart'
    if (dart.library.io) 'notification_platform_mobile.dart' as platform;

/// Cross-platform notifications.
///
/// Mobile (Android/iOS): local scheduled reminders via
/// flutter_local_notifications. Web: the browser Notifications API — the
/// opt-in permission request is wired into onboarding step 5 and the
/// profile "Daily nudges" toggle. True background push on web needs a
/// push server (FCM/VAPID) and is post-MVP.
class NotificationService {
  static Future<void> initialize() => platform.NotificationServicePlatform.initialize();

  /// Platform-appropriate daily nudges: mobile schedules the standard
  /// local reminders; web requests browser permission (background
  /// scheduling is not possible without a push server).
  static Future<bool> enableDailyNudges() =>
      platform.NotificationServicePlatform.enableDailyNudges();

  static Future<void> scheduleDailyReminder({
    required int hour,
    required String message,
  }) =>
      platform.NotificationServicePlatform.scheduleDailyReminder(
        hour: hour,
        message: message,
      );

  static Future<void> scheduleStandardReminders() =>
      platform.NotificationServicePlatform.scheduleStandardReminders();

  static Future<void> cancelAll() =>
      platform.NotificationServicePlatform.cancelAll();

  static Future<void> showTestNotification() =>
      platform.NotificationServicePlatform.showTestNotification();
}
