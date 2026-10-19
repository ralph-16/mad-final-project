import 'dart:async' show Timer;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;abstract class NotificationService {
  Future<bool> requestPermission();
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
int reminderIdFor(String eventId) => eventId.hashCode & 0x7fffffff;
DateTime reminderTimeFor(DateTime start) =>
    start.subtract(const Duration(hours: 1));
int confirmationIdFor(String eventId) =>
    reminderIdFor(eventId) ^ 0x1fffffff;
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
  bool _ready = false;  final Map<int, Timer> _webTimers = {};

  Future<bool> _ensureReady() async {
    if (_ready) return true;
    try {
      tzdata.initializeTimeZones();
    } catch (_) {    }
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings();
    try {
      final ok = await _plugin.initialize(
        settings: const InitializationSettings(android: android, iOS: darwin),
      );
      _ready = ok ?? true;
    } catch (e) {
      debugPrint('Notification init failed: $e');
    }
    return _ready;
  }

  @override
  Future<bool> requestPermission() async {
    try {
      if (!await _ensureReady()) return false;
      if (kIsWeb) {
        final web = _plugin.resolvePlatformSpecificImplementation<
            WebFlutterLocalNotificationsPlugin>();
        final granted = await web?.requestNotificationsPermission();
        return granted ?? false;
      }
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
    if (when.isBefore(DateTime.now())) return;
    if (kIsWeb) {      try {
        await _ensureReady();
        _webTimers.remove(id)?.cancel();
        _webTimers[id] = Timer(when.difference(DateTime.now()), () async {
          _webTimers.remove(id);
          await _plugin.show(id: id, title: title, body: body);
        });
      } catch (e) {
        debugPrint('Web reminder scheduling failed: $e');
      }
      return;
    }
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
    _webTimers.remove(id)?.cancel();
    try {
      await _plugin.cancel(id: id);
    } catch (e) {
      debugPrint('Cancel reminder failed: $e');
    }
  }
}
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
