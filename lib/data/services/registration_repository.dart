import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/registration.dart';

/// Registration contract with duplicate guard via deterministic doc IDs.
abstract class RegistrationRepository {
  Stream<List<Registration>> watchForStudent(String studentId);
  Future<List<Registration>> fetchForStudent(String studentId);

  /// Throws [DuplicateRegistration] if already registered.
  Future<void> register(String studentId, String eventId);
  Future<void> cancel(String studentId, String eventId);
  Future<bool> isRegistered(String studentId, String eventId);
}

class DuplicateRegistration implements Exception {
  const DuplicateRegistration();
}

class FirestoreRegistrationRepository implements RegistrationRepository {
  FirestoreRegistrationRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('registrations');

  @override
  Stream<List<Registration>> watchForStudent(String studentId) => _col
      .where('studentId', isEqualTo: studentId)
      .snapshots()
      .map((s) =>
          s.docs.map((d) => Registration.fromMap(d.id, d.data())).toList());

  @override
  Future<List<Registration>> fetchForStudent(String studentId) async {
    final s = await _col.where('studentId', isEqualTo: studentId).get();
    return s.docs.map((d) => Registration.fromMap(d.id, d.data())).toList();
  }

  @override
  Future<void> register(String studentId, String eventId) async {
    final ref = _col.doc(Registration.docId(studentId, eventId));
    try {
      final existing = await ref.get();
      if (existing.exists) throw const DuplicateRegistration();
    } on FirebaseException catch (e) {
      // Old published rules deny get on not-yet-created docs.
      // Treat as not-registered and let create enforce ownership.
      if (e.code != 'permission-denied') rethrow;
    }
    await ref.set(Registration(
      id: ref.id,
      studentId: studentId,
      eventId: eventId,
      registeredAt: DateTime.now(),
      status: Registration.statusRegistered,
    ).toMap());
  }

  @override
  Future<void> cancel(String studentId, String eventId) async {
    await _col.doc(Registration.docId(studentId, eventId)).delete();
  }

  @override
  Future<bool> isRegistered(String studentId, String eventId) async {
    final existing =
        await _col.doc(Registration.docId(studentId, eventId)).get();
    return existing.exists;
  }
}

class MockRegistrationRepository implements RegistrationRepository {
  final _store = <String, Registration>{};
  final _listeners = <String, List<void Function()>>{};

  @override
  Stream<List<Registration>> watchForStudent(String studentId) async* {
    yield _for(studentId);
    // Re-emit is driven by fetch-after-mutate in the ViewModel,
    // keeping the mock dependency-free.
  }

  @override
  Future<List<Registration>> fetchForStudent(String studentId) async =>
      _for(studentId);

  @override
  Future<void> register(String studentId, String eventId) async {
    final id = Registration.docId(studentId, eventId);
    if (_store.containsKey(id)) throw const DuplicateRegistration();
    _store[id] = Registration(
      id: id,
      studentId: studentId,
      eventId: eventId,
      registeredAt: DateTime.now(),
      status: Registration.statusRegistered,
    );
    _notify(studentId);
  }

  @override
  Future<void> cancel(String studentId, String eventId) async {
    _store.remove(Registration.docId(studentId, eventId));
    _notify(studentId);
  }

  @override
  Future<bool> isRegistered(String studentId, String eventId) async =>
      _store.containsKey(Registration.docId(studentId, eventId));

  List<Registration> _for(String studentId) =>
      _store.values.where((r) => r.studentId == studentId).toList();

  void _notify(String studentId) {
    for (final fn in _listeners[studentId] ?? <void Function()>[]) {
      fn();
    }
  }
}
