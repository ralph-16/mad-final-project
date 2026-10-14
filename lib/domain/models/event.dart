import 'package:cloud_firestore/cloud_firestore.dart';

/// Clean domain model for a school event.
///
/// Accepts both storage shapes so preloaded docs keep working:
/// a `dateTime` Timestamp, or legacy `date` + `startTime` strings.
class Event {
  Event({
    required this.id,
    required this.name,
    required this.category,
    required this.dateTime,
    required this.locationName,
    required this.address,
    required this.description,
    required this.imageUrl,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String name;
  final String category;
  final DateTime dateTime;
  final String locationName;
  final String address;
  final String description;
  final String imageUrl;
  final double? latitude;
  final double? longitude;

  static const categories = [
    'Academic',
    'Sports',
    'Seminar',
    'Organization',
    'Entertainment',
  ];
  static const allCategory = 'All';

  bool get isPast => dateTime.isBefore(DateTime.now());
  bool get hasCoordinates => latitude != null && longitude != null;

  factory Event.fromMap(String id, Map<String, dynamic> map) {
    DateTime? dt;
    final raw = map['dateTime'];
    if (raw is Timestamp) {
      dt = raw.toDate();
    } else if (raw is String) {
      dt = DateTime.tryParse(raw);
    }
    // Legacy shape: {date: '2026-11-15', startTime: '09:00'}.
    dt ??= _fromLegacy(map['date'] as String?, map['startTime'] as String?);
    return Event(
      id: id,
      name: (map['name'] ?? '') as String,
      category: (map['category'] ?? '') as String,
      dateTime: dt ?? DateTime.now(),
      locationName: (map['locationName'] ?? '') as String,
      address: (map['address'] ?? '') as String,
      description: (map['description'] ?? '') as String,
      imageUrl: (map['imageUrl'] ?? '') as String,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'category': category,
        'dateTime': Timestamp.fromDate(dateTime),
        'locationName': locationName,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'description': description,
        'imageUrl': imageUrl,
      };

  static DateTime? _fromLegacy(String? date, String? time) {
    if (date == null || date.isEmpty) return null;
    final t = (time == null || time.isEmpty) ? '00:00' : time;
    return DateTime.tryParse('${date}T$t:00');
  }
}

/// Local asset images live under assets/; anything else is a network URL.
bool isAssetImage(String path) => path.startsWith('assets/');

/// Short date/time text without adding an intl dependency.
String formatEventDate(DateTime dt) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
}

String formatEventTime(DateTime dt) {
  final h24 = dt.hour;
  final period = h24 >= 12 ? 'PM' : 'AM';
  final h12 = h24 % 12 == 0 ? 12 : h24 % 12;
  final mm = dt.minute.toString().padLeft(2, '0');
  return '$h12:$mm $period';
}
