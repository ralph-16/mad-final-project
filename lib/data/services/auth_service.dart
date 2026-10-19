import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';abstract class AuthService {
  Stream<String?> get userIdChanges;
  String? get currentUserId;
  Future<void> signUp(String email, String password);
  Future<void> signIn(String email, String password);
  Future<void> signOut();  Future<void> sendPasswordReset(String email);
}

String friendlyAuthError(Object e) {
  if (e is FirebaseAuthException) {
    switch (e.code) {
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account with this email already exists. Try logging in.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'network-request-failed':
        return 'No network connection. Check and try again.';
      default:
        return 'Authentication failed (${e.code}). Try again.';
    }
  }
  return 'Something went wrong. Try again.';
}
String friendlyResetError(Object e) {
  if (e is FormatException) {
    return 'Enter a valid email address.';
  }
  if (e is FirebaseAuthException) {
    switch (e.code) {
      case 'invalid-email':
      case 'missing-email':
        return 'Enter a valid email address.';
      case 'user-not-found':
        return 'If an account exists for this email, a reset link has been sent.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      case 'network-request-failed':
        return 'No network connection. Check and try again.';
      default:
        return 'Could not send reset email. Try again.';
    }
  }
  return 'Something went wrong. Try again.';
}

class FirebaseAuthService implements AuthService {
  FirebaseAuthService(this._auth);
  final FirebaseAuth _auth;

  @override
  Stream<String?> get userIdChanges =>
      _auth.authStateChanges().map((u) => u?.uid);

  @override
  String? get currentUserId => _auth.currentUser?.uid;

  @override
  Future<void> signUp(String email, String password) async {
    await _auth.createUserWithEmailAndPassword(
        email: email.trim(), password: password);
  }

  @override
  Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(
        email: email.trim(), password: password);
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());
}
class MockAuthService implements AuthService {
  final _controller = StreamController<String?>.broadcast();
  final _passwords = <String, String>{};
  final _uids = <String, String>{};
  String? _current;

  @override
  Stream<String?> get userIdChanges async* {
    yield _current;
    yield* _controller.stream;
  }

  @override
  String? get currentUserId => _current;

  @override
  Future<void> signUp(String email, String password) async {
    final key = email.trim().toLowerCase();
    if (!_isEmail(key)) throw const FormatException('invalid-email');
    if (password.length < 6) throw const FormatException('weak-password');
    if (_passwords.containsKey(key)) {
      throw const FormatException('email-already-in-use');
    }
    _passwords[key] = password;
    _uids[key] = 'mock-${key.hashCode}';
    _current = _uids[key];
    _controller.add(_current);
  }

  @override
  Future<void> signIn(String email, String password) async {
    final key = email.trim().toLowerCase();
    if (_passwords[key] != password) {
      throw const FormatException('invalid-credential');
    }
    _current = _uids[key];
    _controller.add(_current);
  }

  @override
  Future<void> signOut() async {
    _current = null;
    _controller.add(null);
  }  final resetSentTo = <String>[];

  @override
  Future<void> sendPasswordReset(String email) async {
    final key = email.trim().toLowerCase();
    if (!_isEmail(key)) throw const FormatException('invalid-email');
    resetSentTo.add(key);
  }

  bool _isEmail(String s) => s.contains('@') && s.contains('.');
}
