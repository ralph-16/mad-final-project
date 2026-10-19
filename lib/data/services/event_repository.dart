import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/event.dart';
abstract class EventRepository {
  Stream<List<Event>> watchEvents();
  Future<List<Event>> fetchEvents();
}

class FirestoreEventRepository implements EventRepository {
  FirestoreEventRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('events');

  @override
  Stream<List<Event>> watchEvents() => _col
      .orderBy('dateTime')
      .snapshots()
      .map((s) => s.docs.map((d) => Event.fromMap(d.id, d.data())).toList());

  @override
  Future<List<Event>> fetchEvents() async {
    final s = await _col.orderBy('dateTime').get();
    return s.docs.map((d) => Event.fromMap(d.id, d.data())).toList();
  }
}class MockEventRepository implements EventRepository {
  List<Event> get _events {
    final now = DateTime.now();
    DateTime days(int d, int h) {
      final base = now.add(Duration(days: d));
      return DateTime(base.year, base.month, base.day, h);
    }

    return [
      Event(
        id: 'evt-seminar-web',
        name: 'Web Development Seminar',
        category: 'Seminar',
        dateTime: days(6, 9),
        locationName: 'School Auditorium',
        address: 'Main Campus, Building A',
        latitude: 14.5995,
        longitude: 120.9842,
        description:
            'An introduction to modern web development: HTML, CSS, and Flutter for the web.',
        imageUrl: 'assets/images/seminar-web.jpg',
      ),
      Event(
        id: 'evt-academic-quiz',
        name: 'Inter-School Quiz Bee',
        category: 'Academic',
        dateTime: days(3, 13),
        locationName: 'Library Hall',
        address: 'Main Campus, Library 2F',
        description:
            'Annual academic quiz competition. Teams of three, all year levels welcome.',
        imageUrl: 'assets/images/quiz-bee.jpg',
      ),
      Event(
        id: 'evt-sports-fest',
        name: 'Intramurals Basketball Finals',
        category: 'Sports',
        dateTime: days(9, 15),
        locationName: 'Covered Court',
        address: 'Sports Complex, Main Campus',
        latitude: 14.6000,
        longitude: 120.9850,
        description: 'Championship game plus awarding ceremony. Free admission.',
        imageUrl: 'assets/images/sports-fest.jpg',
      ),
      Event(
        id: 'evt-org-fair',
        name: 'Student Organization Fair',
        category: 'Organization',
        dateTime: days(2, 10),
        locationName: 'Student Plaza',
        address: 'Main Campus, Student Center',
        description:
            'Meet every recognized student org and sign up for memberships.',
        imageUrl: 'assets/images/org-fair.jpg',
      ),
      Event(
        id: 'evt-music-night',
        name: 'Acoustic Night',
        category: 'Entertainment',
        dateTime: days(12, 18),
        locationName: 'Amphitheater',
        address: 'Main Campus, Amphitheater',
        description: 'Student bands and open-mic performances under the stars.',
        imageUrl: 'assets/images/music-night.jpg',
      ),
      Event(
        id: 'evt-past-robotics',
        name: 'Robotics Workshop (Past)',
        category: 'Academic',
        dateTime: days(-4, 10),
        locationName: 'Engineering Lab 3',
        address: 'Main Campus, Engineering Bldg',
        description: 'Hands-on intro to Arduino and line-following robots.',
        imageUrl: 'assets/images/robotics-past.jpg',
      ),
    ];
  }

  @override
  Stream<List<Event>> watchEvents() async* {
    yield _events..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  @override
  Future<List<Event>> fetchEvents() async {
    final list = _events..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return list;
  }
}
