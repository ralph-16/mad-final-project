import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:final_project/data/services/auth_service.dart';
import 'package:final_project/data/services/calendar_launcher.dart';
import 'package:final_project/data/services/event_repository.dart';
import 'package:final_project/domain/models/event.dart';
import 'package:final_project/ui/features/auth/view_models/auth_view_model.dart';
import 'package:final_project/ui/features/discover/view_models/discover_view_model.dart';

Future<DiscoverViewModel> _loadedDiscover() async {
  final vm = DiscoverViewModel(MockEventRepository());
  await vm.load();
  await Future<void>.delayed(const Duration(milliseconds: 50));
  return vm;
}

Event _event(String id, String category) => Event(
      id: id,
      name: 'Sample $id',
      category: category,
      dateTime: DateTime.now().add(const Duration(days: 5)),
      locationName: 'Hall',
      address: 'Campus',
      description: 'Desc',
      imageUrl: '',
    );

void main() {
  group('Discover counts', () {
    test('All equals total; per-category counts match events', () async {
      final vm = await _loadedDiscover();
      final counts = vm.counts;
      expect(counts[Event.allCategory], vm.all.length);
      expect(counts.values.skip(1).fold<int>(0, (a, b) => a + b),
          vm.all.length);
      expect(counts['Sports'], 1);
      expect(counts['Academic'], 2);
      for (final c in Event.categories) {
        expect(
          counts[c],
          vm.all.where((e) => e.category == c).length,
          reason: 'count for $c',
        );
      }
    });
  });

  group('Discover search', () {
    test('matches name case-insensitively', () async {
      final vm = await _loadedDiscover();
      vm.setSearchQuery('QUIZ');
      expect(vm.filtered.length, 1);
      expect(vm.filtered.first.name, contains('Quiz'));
    });

    test('matches venue and description', () async {
      final vm = await _loadedDiscover();
      vm.setSearchQuery('auditorium');
      expect(vm.filtered.map((e) => e.id), contains('evt-seminar-web'));
      vm.setSearchQuery('arduino');
      expect(vm.filtered.map((e) => e.id), contains('evt-past-robotics'));
    });

    test('combines with category; zero results possible', () async {
      final vm = await _loadedDiscover();
      vm.setCategory('Academic');
      vm.setSearchQuery('robotics');
      expect(vm.filtered.length, 1);
      vm.setSearchQuery('basketball');
      expect(vm.filtered, isEmpty);
    });

    test('clearFilters restores All and empties query', () async {
      final vm = await _loadedDiscover();
      vm.setCategory('Sports');
      vm.setSearchQuery('x');
      expect(vm.hasActiveFilters, isTrue);
      vm.clearFilters();
      expect(vm.selectedCategory, Event.allCategory);
      expect(vm.searchQuery, isEmpty);
      expect(vm.filtered.length, vm.all.length);
    });
  });

  group('Forgot password', () {
    test('valid email records reset and reports success', () async {
      final auth = MockAuthService();
      final vm = AuthViewModel(auth);
      expect(await vm.sendPasswordReset('student@school.edu'), isTrue);
      expect(auth.resetSentTo, contains('student@school.edu'));
      expect(vm.resetInfo, isNotNull);
      expect(vm.resetError, isNull);
      expect(vm.isLoading, isFalse);
    });

    test('invalid email fails without raw codes', () async {
      final vm = AuthViewModel(MockAuthService());
      expect(await vm.sendPasswordReset('not-an-email'), isFalse);
      expect(vm.resetInfo, isNull);
      expect(vm.resetError, 'Enter a valid email address.');
    });

    test('unknown address stays generic (no enumeration)', () {
      expect(
        friendlyResetError(
            FirebaseAuthException(code: 'user-not-found')),
        'If an account exists for this email, a reset link has been sent.',
      );
      expect(
        friendlyResetError(
            FirebaseAuthException(code: 'too-many-requests')),
        'Too many attempts. Try again later.',
      );
    });
  });

  group('Calendar URL', () {
    test('builds encoded Google template URL with 2h fallback end', () {
      final event = Event(
        id: 'e1',
        name: 'Web Dev & More?',
        category: 'Seminar',
        dateTime: DateTime.utc(2026, 11, 15, 9, 0),
        locationName: 'Hall',
        address: 'Campus & Annex',
        description: 'Intro <basics>',
        imageUrl: '',
      );
      final uri = CalendarLauncher.googleCalendarUrl(event);
      expect(uri.host, 'calendar.google.com');
      expect(uri.path, '/calendar/render');
      expect(uri.queryParameters['action'], 'TEMPLATE');
      expect(uri.queryParameters['dates'],
          '20261115T090000Z/20261115T110000Z');
      expect(uri.queryParameters['text'], 'Web Dev & More?');
      expect(uri.queryParameters['location'], 'Hall, Campus & Annex');
      expect(uri.queryParameters['details'], 'Intro <basics>');
    });

    test('omits empty optional fields without crashing', () {
      final uri = CalendarLauncher.googleCalendarUrl(
          _event('e2', 'Sports'));
      expect(uri.queryParameters['location'], 'Hall, Campus');
    });
  });
}
