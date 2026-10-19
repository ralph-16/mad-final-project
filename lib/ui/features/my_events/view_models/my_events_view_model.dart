import 'package:flutter/foundation.dart';

import '../../../../data/services/event_repository.dart';
import '../../../../data/services/notification_service.dart';
import '../../../../data/services/registration_repository.dart';
import '../../../../domain/models/event.dart';
import '../../../../domain/models/registration.dart';class MyEventsViewModel extends ChangeNotifier {
  MyEventsViewModel({
    required this.registrations,
    required this.events,
    required this.notifications,
  });

  final RegistrationRepository registrations;
  final EventRepository events;
  final NotificationService notifications;

  List<Registration> _regs = [];
  Map<String, Event> _byId = {};
  bool isLoading = true;
  String? errorMessage;
  String? notice;
  bool remindersAvailable = true;

  List<Event> get upcoming => _joined(wherePast: false);
  List<Event> get history => _joined(wherePast: true);
  bool isRegistered(String eventId) =>
      _regs.any((r) => r.eventId == eventId);

  List<Event> _joined({required bool wherePast}) {
    final out = <Event>[];
    for (final r in _regs) {
      final e = _byId[r.eventId];
      if (e == null) continue;
      if (e.isPast == wherePast) out.add(e);
    }
    out.sort((a, b) => wherePast
        ? b.dateTime.compareTo(a.dateTime)
        : a.dateTime.compareTo(b.dateTime));
    return out;
  }

  Future<void> load(String studentId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        registrations.fetchForStudent(studentId),
        events.fetchEvents(),
      ]);
      _regs = results[0] as List<Registration>;
      final fetched = results[1] as List<Event>;
      _byId = {for (final e in fetched) e.id: e};
    } catch (_) {
      errorMessage = 'Could not load your events. Try again.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
  Future<bool> register(String studentId, Event event) async {
    if (event.isPast) {
      notice = 'Registration is closed: this event has passed.';
      notifyListeners();
      return false;
    }
    try {
      await registrations.register(studentId, event.id);
    } on DuplicateRegistration {
      notice = 'You are already registered for this event.';
      notifyListeners();
      return false;
    } catch (_) {
      notice = 'Registration failed. Try again.';
      notifyListeners();
      return false;
    }    final granted = await notifications.requestPermission();
    remindersAvailable = granted;
    if (granted) {      await notifications.showNow(
        id: confirmationIdFor(event.id),
        title: 'Registration confirmed',
        body:
            '${event.name} starts ${timeUntilLabel(event.dateTime)} — '
            '${formatReminderWhen(event.dateTime)} at ${event.locationName}',
      );
      await notifications.scheduleReminder(
        id: reminderIdFor(event.id),
        title: 'Upcoming: ${event.name}',
        body:
            '${formatReminderWhen(event.dateTime)} at ${event.locationName}',
        when: reminderTimeFor(event.dateTime),
      );
      notice = 'Registered. Reminder set for 1 hour before.';
    } else {
      notice = 'Registered. Enable notifications to get reminders.';
    }
    await load(studentId);
    return true;
  }

  Future<bool> cancel(String studentId, Event event) async {
    try {
      await registrations.cancel(studentId, event.id);
      await notifications.cancelReminder(reminderIdFor(event.id));
    } catch (_) {
      notice = 'Cancellation failed. Try again.';
      notifyListeners();
      return false;
    }
    notice = 'Registration cancelled.';
    await load(studentId);
    return true;
  }
  String? takeNotice() {
    final n = notice;
    notice = null;
    return n;
  }

  static String formatReminderWhen(DateTime dt) =>
      '${formatEventDate(dt)} ${formatEventTime(dt)}';
}
