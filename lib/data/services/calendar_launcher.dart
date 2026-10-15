import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/models/event.dart';

/// Opens an event in the student's personal calendar.
///
/// Implementation: a prefilled Google Calendar template URL, which works on
/// Android, iOS (via browser), and web with no extra dependencies.
///
/// Assumption (documented): [Event] carries no end time, so the export uses
/// [defaultEventDuration] after the start. Change the constant — not the
/// model — if the school standardizes event lengths.
///
/// Apple Calendar / .ics export is intentionally out of scope: it needs file
/// writing + sharing (e.g. `share_plus`), disproportionate for this MVP.
/// Returns false when nothing could handle the URL; never claims success.
class CalendarLauncher {
  /// Fallback event length used only because the model has no end time.
  static const defaultEventDuration = Duration(hours: 2);

  /// Pure builder (unit-testable): Google Calendar template URL for [event].
  static Uri googleCalendarUrl(Event event, {DateTime? nowUtc}) {
    final start = event.dateTime.toUtc();
    final end = start.add(defaultEventDuration);
    final params = <String, String>{
      'action': 'TEMPLATE',
      'text': event.name,
      'dates': '${_stamp(start)}/${_stamp(end)}',
      if (event.description.isNotEmpty) 'details': event.description,
      if (event.address.isNotEmpty)
        'location': '${event.locationName}, ${event.address}'
      else if (event.locationName.isNotEmpty)
        'location': event.locationName,
    };
    return Uri.https(
      'calendar.google.com',
      '/calendar/render',
      params,
    );
  }

  static Future<bool> addEvent(Event event) async {
    final uri = googleCalendarUrl(event);
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Open calendar failed: $e');
      return false;
    }
  }

  /// UTC stamp in Google's `yyyyMMddTHHmmssZ` format (manual: no intl dep).
  static String _stamp(DateTime dt) {
    String p(int n, [int w = 2]) => n.toString().padLeft(w, '0');
    return '${p(dt.year, 4)}${p(dt.month)}${p(dt.day)}'
        'T${p(dt.hour)}${p(dt.minute)}${p(dt.second)}Z';
  }
}
