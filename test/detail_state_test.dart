import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:final_project/data/services/auth_service.dart';
import 'package:final_project/data/services/event_repository.dart';
import 'package:final_project/data/services/notification_service.dart';
import 'package:final_project/data/services/registration_repository.dart';
import 'package:final_project/main.dart';
import 'package:final_project/ui/core/theme_controller.dart';
import 'package:final_project/ui/features/auth/view_models/auth_view_model.dart';
import 'package:final_project/ui/features/detail/views/detail_view.dart';
import 'package:final_project/ui/features/discover/view_models/discover_view_model.dart';
import 'package:final_project/ui/features/my_events/view_models/my_events_view_model.dart';

void main() {
  testWidgets(
      'detail shows Cancel for pre-existing registrations right after login',
      (tester) async {
    final auth = MockAuthService();
    await auth.signUp('student@test.edu', 'secret123');
    final authVM = AuthViewModel(auth);
    final uid = authVM.userId!;
    final registrationRepository = MockRegistrationRepository();
    final event = (await MockEventRepository().fetchEvents())
        .firstWhere((e) => e.name == 'Student Organization Fair');
    await registrationRepository.register(uid, event.id);

    final mine = MyEventsViewModel(
      registrations: registrationRepository,
      events: MockEventRepository(),
      notifications: NoopNotificationService(),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: ThemeController()),
          ChangeNotifierProvider.value(value: authVM),
          ChangeNotifierProvider.value(value: DiscoverViewModel(
              MockEventRepository())),
          ChangeNotifierProvider.value(value: mine),
        ],
        child: MaterialApp(
          home: const AuthGate(),
          onGenerateRoute: (settings) {
            if (settings.name == '/detail' &&
                settings.arguments is String) {
              return MaterialPageRoute(
                builder: (_) =>
                    DetailView(eventId: settings.arguments as String),
              );
            }
            return null;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    final card = find.text('Student Organization Fair');
    await tester.ensureVisible(card);
    await tester.pumpAndSettle();
    await tester.tap(card);
    await tester.pumpAndSettle();
    expect(find.byType(DetailView), findsOneWidget);
    final cancel = find.text('Cancel registration');
    await tester.scrollUntilVisible(
      cancel,
      160,
      scrollable: find.descendant(
          of: find.byType(DetailView), matching: find.byType(Scrollable)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Registered'), findsOneWidget);
    expect(cancel, findsOneWidget);
    expect(find.text('Register for this event'), findsNothing);

    expect(find.text('Registered'), findsOneWidget);
    expect(find.text('Cancel registration'), findsOneWidget);
    expect(find.text('Register for this event'), findsNothing);
  });
}
