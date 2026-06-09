import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Thin wrapper around [FlutterLocalNotificationsPlugin] mirroring the RN app's
/// expo-notifications usage in `legacy_rn/app/notifications.tsx`.
///
/// Every plugin call is wrapped in try/catch so the UI stays usable on
/// platforms where notifications are unavailable (e.g. web) or the user has
/// denied permission. Methods that report success/failure return a bool.
class LocalNotifications {
  LocalNotifications._();

  static final LocalNotifications instance = LocalNotifications._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  static const int _dailyId = 0;
  static const int _testId = 99;

  /// Initialises the plugin + timezone database. Safe to call repeatedly.
  Future<void> init() async {
    if (_initialized) return;
    try {
      tzdata.initializeTimeZones();
    } catch (_) {
      // Timezone data may already be loaded — ignore.
    }
    try {
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwin = DarwinInitializationSettings();
      const settings =
          InitializationSettings(android: android, iOS: darwin, macOS: darwin);
      await _plugin.initialize(settings: settings);
      _initialized = true;
    } catch (_) {
      // Plugin unavailable (e.g. web/test) — leave uninitialised.
    }
  }

  /// Requests the OS notification permission. Returns true if granted (or if we
  /// can't determine, optimistically), false if explicitly denied/unavailable.
  Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        final granted = await android.requestNotificationsPermission();
        return granted ?? false;
      }
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        final granted = await ios.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
      final macos = _plugin.resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin>();
      if (macos != null) {
        final granted = await macos.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
    } catch (_) {
      return false;
    }
    return false;
  }

  NotificationDetails _details({
    required String channelId,
    required String channelName,
  }) {
    final android = AndroidNotificationDetails(
      channelId,
      channelName,
      importance: Importance.high,
      priority: Priority.high,
    );
    const darwin = DarwinNotificationDetails();
    return NotificationDetails(android: android, iOS: darwin, macOS: darwin);
  }

  /// Cancels any existing schedule, then (re)schedules the daily reminder for
  /// the next occurrence of [hour]:[minute], repeating every day.
  Future<void> scheduleDaily({required int hour, required int minute}) async {
    await init();
    try {
      await _plugin.cancelAll();
      await _plugin.zonedSchedule(
        id: _dailyId,
        title: 'Wealthify',
        body: "Don't forget to log today's spending.",
        scheduledDate: _nextInstanceOf(hour, minute),
        notificationDetails:
            _details(channelId: 'daily', channelName: 'Daily reminder'),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (_) {
      // Scheduling unavailable — swallow so the UI stays responsive.
    }
  }

  /// Cancels all scheduled notifications.
  Future<void> cancelAll() async {
    await init();
    try {
      await _plugin.cancelAll();
    } catch (_) {
      // ignore
    }
  }

  /// Shows an immediate test notification. Returns false if it threw.
  Future<bool> showTest() async {
    await init();
    try {
      await _plugin.show(
        id: _testId,
        title: 'Wealthify',
        body: 'This is a test reminder.',
        notificationDetails: _details(channelId: 'test', channelName: 'Test'),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// The next [hour]:[minute] in local time, today if still in the future,
  /// otherwise tomorrow.
  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
