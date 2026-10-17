import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Reminder contract. Registration still works when permission is denied;
/// the ViewModel then shows a notice instead of scheduling.
abstract class NotificationService {
  Future<bool> requestPermission();

  /// Shows a notification right away (e.g. registration confirmation).
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
  });

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

/// Distinct ID per event so confirmation and reminder don't collide.
int confirmationIdFor(String eventId) =>
    reminderIdFor(eventId) ^ 0x1fffffff;

/// Human phrase for how far from now [when] is, e.g. 'in 2 days'.
String timeUntilLabel(DateTime when) {
  final d = when.difference(DateTime.now());
  if (d.inMinutes < 1) return 'very soon';
  if (d.inMinutes < 60) return 'in ${d.inMinutes} min';
  if (d.inHours < 24) {
    final m = d.inMinutes % 60;
    final h = d.inHours;
    final hs = h == 1 ? '1 hr' : '$h hrs';
    return m == 0 ? 'in $hs' : 'in $hs ${m}min';
  }
  final days = d.inDays;
  return 'in $days day${days == 1 ? '' : 's'}';
}

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
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
  }) async {
    try {
      await _ensureReady();
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'eventhub_confirmations',
            'Registration confirmations',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    } catch (e) {
      debugPrint('Show notification failed: $e');
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
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
  }) async {}

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
