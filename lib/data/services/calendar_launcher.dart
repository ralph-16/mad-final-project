import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/models/event.dart';class CalendarLauncher {  static const defaultEventDuration = Duration(hours: 2);
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
  static String _stamp(DateTime dt) {
    String p(int n, [int w = 2]) => n.toString().padLeft(w, '0');
    return '${p(dt.year, 4)}${p(dt.month)}${p(dt.day)}'
        'T${p(dt.hour)}${p(dt.minute)}${p(dt.second)}Z';
  }
}
