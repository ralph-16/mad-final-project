import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../data/services/auth_service.dart';

/// Auth UI state. Errors are user-facing strings, never raw codes.
class AuthViewModel extends ChangeNotifier {
  AuthViewModel(this._auth) {
    _sub = _auth.userIdChanges.listen((id) {
      userId = id;
      notifyListeners();
    });
    userId = _auth.currentUserId;
  }

  final AuthService _auth;
  StreamSubscription<String?>? _sub;

  String? userId;
  bool get signedIn => userId != null;

  bool isLoading = false;
  String? errorMessage;

  /// Password-reset flow state. Kept separate from [errorMessage] so the
  /// reset dialog shows its own inline result without touching the form.
  String? resetError;
  String? resetInfo;

  /// Clears a stale form error as soon as the user starts correcting input
  /// (or switches modes), so old messages never linger over fresh typing.
  void clearError() {
    if (errorMessage != null) {
      errorMessage = null;
      notifyListeners();
    }
  }

  void clearResetMessages() {
    resetError = null;
    resetInfo = null;
  }

  Future<bool> signIn(String email, String password) =>
      _run(() => _auth.signIn(email, password));

  Future<bool> signUp(String email, String password) =>
      _run(() => _auth.signUp(email, password));

  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Sends a password-reset email. Returns true when the request was
  /// accepted. Loading always resets so the form stays usable.
  Future<bool> sendPasswordReset(String email) async {
    resetError = null;
    resetInfo = null;
    isLoading = true;
    notifyListeners();
    try {
      await _auth.sendPasswordReset(email);
      resetInfo = 'Password reset email sent. Check your inbox.';
      return true;
    } catch (e) {
      resetError = friendlyResetError(e);
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> _run(Future<void> Function() call) async {
    errorMessage = null;
    isLoading = true;
    notifyListeners();
    try {
      await call();
      return true;
    } on FormatException catch (e) {
      errorMessage = _mockMessage(e.message);
    } catch (e) {
      errorMessage = friendlyAuthError(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
    return false;
  }

  String _mockMessage(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'email-already-in-use':
        return 'An account with this email already exists. Try logging in.';
      default:
        return 'Incorrect email or password.';
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
