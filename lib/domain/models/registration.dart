import 'package:cloud_firestore/cloud_firestore.dart';
class Registration {
  Registration({
    required this.id,
    required this.studentId,
    required this.eventId,
    required this.registeredAt,
    required this.status,
  });

  final String id;
  final String studentId;
  final String eventId;
  final DateTime registeredAt;
  final String status;

  static const statusRegistered = 'registered';

  static String docId(String studentId, String eventId) =>
      '${studentId}_$eventId';

  factory Registration.fromMap(String id, Map<String, dynamic> map) {
    final raw = map['registeredAt'];
    return Registration(
      id: id,
      studentId: (map['studentId'] ?? '') as String,
      eventId: (map['eventId'] ?? '') as String,
      registeredAt:
          raw is Timestamp ? raw.toDate() : DateTime.now(),
      status: (map['status'] ?? statusRegistered) as String,
    );
  }

  Map<String, dynamic> toMap() => {
        'studentId': studentId,
        'eventId': eventId,
        'registeredAt': Timestamp.fromDate(registeredAt),
        'status': status,
      };
}
