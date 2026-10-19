import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:final_project/data/services/event_repository.dart';
import 'package:final_project/data/services/notification_service.dart';
import 'package:final_project/data/services/registration_repository.dart';
import 'package:final_project/ui/features/discover/view_models/discover_view_model.dart';
import 'package:final_project/ui/features/discover/views/discover_view.dart';
import 'package:final_project/ui/features/my_events/view_models/my_events_view_model.dart';

void main() {
  testWidgets('Discover shows events and filters by category',
      (WidgetTester tester) async {
    final discover = DiscoverViewModel(MockEventRepository());
    final mine = MyEventsViewModel(
      registrations: MockRegistrationRepository(),
      events: MockEventRepository(),
      notifications: NoopNotificationService(),
    );
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: discover),
          ChangeNotifierProvider.value(value: mine),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: DiscoverView(onOpenDetail: (_) {}),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Student Organization Fair'), findsOneWidget);

    discover.setCategory('Sports');
    await tester.pumpAndSettle();
    expect(find.text('Intramurals Basketball Finals'), findsOneWidget);
    expect(find.text('Student Organization Fair'), findsNothing);
  });
}
