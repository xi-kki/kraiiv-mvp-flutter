import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Web implementation: the browser Notifications API.
///
/// Background scheduling requires a push server (FCM/VAPID) — post-MVP.
/// This wires the permission opt-in that onboarding step 5 and the
/// profile "Daily nudges" toggle surface, so the browser actually asks
/// the user instead of silently doing nothing.
class NotificationServicePlatform {
  static Future<void> initialize() async {}

  static Future<bool> enableDailyNudges() => requestPermission();

  static Future<bool> requestPermission() async {
    try {
      final status = await web.Notification.requestPermission().toDart;
      return status.toDart == 'granted';
    } catch (_) {
      // Notifications unsupported in this browser (e.g. some private modes).
      return false;
    }
  }

  static Future<void> scheduleDailyReminder({
    required int hour,
    required String message,
  }) async {
    await requestPermission();
  }

  static Future<void> scheduleStandardReminders() async {
    await requestPermission();
  }

  static Future<void> cancelAll() async {
    // Browser permission cannot be programmatically revoked; dropping the
    // preference in the app is the correct scope here.
  }

  static Future<void> showTestNotification() async {
    if (web.Notification.permission == 'granted') {
      web.Notification(
        'Kraiiv',
        web.NotificationOptions(body: 'This is a test notification.'),
      );
    }
  }
}
