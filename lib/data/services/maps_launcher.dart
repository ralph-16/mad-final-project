import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/models/event.dart';

/// Opens the event location in a maps app/website.
/// Returns false when nothing could handle the URL.
class MapsLauncher {
  static Future<bool> openEvent(Event event) async {
    final Uri uri;
    if (event.hasCoordinates) {
      uri = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=${event.latitude},${event.longitude}');
    } else {
      final q = event.address.isNotEmpty
          ? event.address
          : event.locationName;
      uri = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(q)}');
    }
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Open maps failed: $e');
      return false;
    }
  }
}
