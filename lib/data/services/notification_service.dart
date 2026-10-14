import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Reminder contract. Registration still works when permission is denied;
/// the ViewModel then shows a notice instead of scheduling.
abstract class NotificationService {
  Future<bool> requestPermission();
  Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime when,
  });
  Future<void> cancelReminder(int id);
}

/// Stable positive ID per event for schedule/cancel pairing.
int reminderIdFor(String eventId) => eventId.hashCode & 0x7fffffff;

/// One hour before start, per spec.
DateTime reminderTimeFor(DateTime start) =>
    start.subtract(const Duration(hours: 1));

class LocalNotificationService implements NotificationService {
  LocalNotificationService() : _plugin = FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _ready = false;

  Future<void> _ensureReady() async {
    if (_ready) return;
    try {
      tzdata.initializeTimeZones();
    } catch (_) {
      // Timezone DB init failure is non-fatal; local time is used.
    }
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings();
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: darwin),
    );
    _ready = true;
  }

  @override
  Future<bool> requestPermission() async {
    try {
      await _ensureReady();
      final android =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final aGranted = await android?.requestNotificationsPermission();
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final iGranted = await ios?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return (aGranted ?? true) && (iGranted ?? true);
    } catch (e) {
      debugPrint('Notification permission failed: $e');
      return false;
    }
  }

  @override
  Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime when,
  }) async {
    if (when.isBefore(DateTime.now())) return; // past: nothing to remind
    try {
      await _ensureReady();
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(when, tz.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'eventhub_reminders',
            'Event reminders',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('Schedule reminder failed: $e');
    }
  }

  @override
  Future<void> cancelReminder(int id) async {
    try {
      await _plugin.cancel(id: id);
    } catch (e) {
      debugPrint('Cancel reminder failed: $e');
    }
  }
}

/// Fallback used when permission is denied or plugins unavailable.
class NoopNotificationService implements NotificationService {
  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime when,
  }) async {}

  @override
  Future<void> cancelReminder(int id) async {}
}
