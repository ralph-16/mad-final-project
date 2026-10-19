import 'package:flutter_test/flutter_test.dart';

import 'package:final_project/data/services/event_repository.dart';
import 'package:final_project/data/services/notification_service.dart';
import 'package:final_project/data/services/registration_repository.dart';
import 'package:final_project/ui/features/my_events/view_models/my_events_view_model.dart';

MyEventsViewModel _myEvents(RegistrationRepository repo) =>
    MyEventsViewModel(
      registrations: repo,
      events: MockEventRepository(),
      notifications: NoopNotificationService(),
    );

void main() {
  group('Demo history + live registration', () {
    test('one student sees past in history and future in upcoming',
        () async {
      final repo = MockRegistrationRepository();
      final events = await MockEventRepository().fetchEvents();
      final past = events.firstWhere((e) => e.isPast);
      final future = events.firstWhere((e) => !e.isPast);

      await repo.register('demo-student', past.id);
      await repo.register('demo-student', future.id);

      final vm = _myEvents(repo);
      await vm.load('demo-student');

      expect(vm.history.map((e) => e.id), contains(past.id));
      expect(vm.upcoming.map((e) => e.id), contains(future.id));
      expect(vm.upcoming.map((e) => e.id), isNot(contains(past.id)));
      expect(vm.history.map((e) => e.id), isNot(contains(future.id)));
    });

    test('live registration preserves existing history', () async {
      final repo = MockRegistrationRepository();
      final events = await MockEventRepository().fetchEvents();
      final past = events.firstWhere((e) => e.isPast);
      final future = events.firstWhere((e) => !e.isPast);
      await repo.register('demo-student', past.id);

      final vm = _myEvents(repo);
      expect(await vm.register('demo-student', future), isTrue);
      await vm.load('demo-student');

      expect(vm.upcoming.map((e) => e.id), contains(future.id));
      expect(vm.history.map((e) => e.id), contains(past.id));
      expect(vm.history, hasLength(1));
    });

    test('registering a past event is rejected without side effects',
        () async {
      final vm = _myEvents(MockRegistrationRepository());
      const uid = 'demo-student';
      final past = (await MockEventRepository().fetchEvents())
          .firstWhere((e) => e.isPast);

      expect(await vm.register(uid, past), isFalse);
      expect(vm.takeNotice(), contains('passed'));

      await vm.load(uid);
      expect(vm.upcoming, isEmpty);
      expect(vm.history, isEmpty);
    });
  });
}
