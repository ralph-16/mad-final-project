import 'package:flutter_test/flutter_test.dart';

import 'package:final_project/data/services/event_repository.dart';
import 'package:final_project/data/services/notification_service.dart';
import 'package:final_project/data/services/registration_repository.dart';
import 'package:final_project/domain/models/event.dart';
import 'package:final_project/ui/features/discover/view_models/discover_view_model.dart';
import 'package:final_project/ui/features/my_events/view_models/my_events_view_model.dart';

MyEventsViewModel _myEvents() => MyEventsViewModel(
      registrations: MockRegistrationRepository(),
      events: MockEventRepository(),
      notifications: NoopNotificationService(),
    );

void main() {
  group('Discover filter', () {
    test('All shows everything; category narrows; unknown is empty', () async {
      final vm = DiscoverViewModel(MockEventRepository());
      await vm.load();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(vm.filtered.length, greaterThanOrEqualTo(6));

      vm.setCategory('Sports');
      expect(vm.filtered.length, 1);
      expect(vm.filtered.first.category, 'Sports');

      vm.setCategory(Event.allCategory);
      expect(vm.filtered.length, greaterThanOrEqualTo(6));
    });
  });

  group('Registrations', () {
    test('register once succeeds; twice is guarded', () async {
      final vm = _myEvents();
      const uid = 'student-1';
      final event = (await MockEventRepository().fetchEvents())
          .firstWhere((e) => !e.isPast);

      expect(await vm.register(uid, event), isTrue);
      await vm.load(uid);
      expect(vm.upcoming.any((e) => e.id == event.id), isTrue);

      // Duplicate: repository throws, ViewModel reports notice.
      expect(await vm.register(uid, event), isFalse);
      expect(vm.takeNotice(), contains('already registered'));
    });

    test('cancel removes from upcoming', () async {
      final vm = _myEvents();
      const uid = 'student-2';
      final event = (await MockEventRepository().fetchEvents())
          .firstWhere((e) => !e.isPast);

      await vm.register(uid, event);
      expect(await vm.cancel(uid, event), isTrue);
      await vm.load(uid);
      expect(vm.upcoming.where((e) => e.id == event.id), isEmpty);
    });

    test('past events land in history, not upcoming', () async {
      const uid = 'student-3';
      final past = (await MockEventRepository().fetchEvents())
          .firstWhere((e) => e.isPast);

      // Past registration is closed via UI; seed repo directly instead.
      final repo = MockRegistrationRepository();
      final vm2 = MyEventsViewModel(
        registrations: repo,
        events: MockEventRepository(),
        notifications: NoopNotificationService(),
      );
      await repo.register(uid, past.id);
      await vm2.load(uid);
      expect(vm2.history.any((e) => e.id == past.id), isTrue);
      expect(vm2.upcoming.any((e) => e.id == past.id), isFalse);
    });

    test('registrations are per-student', () async {
      final repo = MockRegistrationRepository();
      final events = await MockEventRepository().fetchEvents();
      final upcoming = events.firstWhere((x) => !x.isPast);
      await repo.register('alice', upcoming.id);
      expect(
          (await repo.fetchForStudent('bob'))
              .where((r) => r.eventId == upcoming.id),
          isEmpty);
      expect(
          (await repo.fetchForStudent('alice'))
              .where((r) => r.eventId == upcoming.id),
          hasLength(1));
    });
  });
}
