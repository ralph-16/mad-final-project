// Regression tests for the auth form: the password field must stay
// editable after a failed submission, and resubmission must work.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:final_project/data/services/auth_service.dart';
import 'package:final_project/ui/core/theme_controller.dart';
import 'package:final_project/ui/features/auth/view_models/auth_view_model.dart';
import 'package:final_project/ui/features/auth/views/auth_view.dart';

/// Fails the first sign-up (simulating e.g. email-already-in-use),
/// then succeeds — proving recovery without reopening the form.
class _FlakyAuth implements AuthService {
  final _controller = StreamController<String?>.broadcast();
  String? _uid;
  int signUpCalls = 0;
  bool failNextSignUp = true;

  @override
  Stream<String?> get userIdChanges async* {
    yield _uid;
    yield* _controller.stream;
  }

  @override
  String? get currentUserId => _uid;

  @override
  Future<void> signUp(String email, String password) async {
    signUpCalls++;
    if (failNextSignUp) {
      failNextSignUp = false;
      throw const FormatException('email-already-in-use');
    }
    _uid = 'uid-1';
    _controller.add(_uid);
  }

  @override
  Future<void> signIn(String email, String password) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<void> sendPasswordReset(String email) async {}
}

Future<void> _pumpAuth(WidgetTester tester, AuthService auth) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeController>(
            create: (_) => ThemeController()),
        ChangeNotifierProvider<AuthViewModel>(
          create: (_) => AuthViewModel(auth),
        ),
      ],
      child: const MaterialApp(home: AuthView()),
    ),
  );
  await tester.pumpAndSettle();
}

Finder get _passwordField => find.byType(TextField).at(1);

void main() {
  testWidgets('password stays editable after failed signup; resubmit works',
      (tester) async {
    final auth = _FlakyAuth();
    await _pumpAuth(tester, auth);

    await tester.tap(find.text('New here? Create an account'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'a@school.edu');
    await tester.enterText(_passwordField, 'secret123');
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    // Failure is reported…
    expect(
        find.text(
            'An account with this email already exists. Try logging in.'),
        findsOneWidget);
    // …but the password field is still enabled and accepts corrections.
    expect(tester.widget<TextField>(_passwordField).enabled, isTrue);
    await tester.enterText(_passwordField, 'brandnew1');
    await tester.pump();
    expect(tester.widget<TextField>(_passwordField).controller?.text,
        'brandnew1');

    // Correcting clears the stale error; resubmission succeeds.
    expect(find.textContaining('already exists'), findsNothing);
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();
    expect(auth.signUpCalls, 2);
    expect(find.textContaining('already exists'), findsNothing);
  });

  testWidgets('short passwords still rejected by validation',
      (tester) async {
    await _pumpAuth(tester, _FlakyAuth());
    await tester.tap(find.text('New here? Create an account'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'a@school.edu');
    await tester.enterText(_passwordField, 'abc');
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();
    expect(
        find.text('Password must be at least 6 characters.'), findsOneWidget);
  });

  testWidgets('forgot password dialog sends reset and reports success',
      (tester) async {
    final auth = MockAuthService();
    await _pumpAuth(tester, auth);

    await tester.enterText(find.byType(TextField).at(0), 'me@school.edu');
    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();
    expect(find.text('Reset password'), findsOneWidget);

    await tester.tap(find.text('Send reset link'));
    await tester.pumpAndSettle();
    expect(
        find.text('Password reset email sent. Check your inbox.'),
        findsOneWidget);
    expect(auth.resetSentTo, contains('me@school.edu'));

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('Reset password'), findsNothing);
  });
}
