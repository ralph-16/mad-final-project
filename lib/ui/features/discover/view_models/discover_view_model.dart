import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../data/services/event_repository.dart';
import '../../../../domain/models/event.dart';

/// Browse + filter UI state over [EventRepository].
class DiscoverViewModel extends ChangeNotifier {
  DiscoverViewModel(this._repo);

  final EventRepository _repo;
  StreamSubscription<List<Event>>? _sub;

  List<Event> _events = [];
  bool isLoading = true;
  String? errorMessage;
  String selectedCategory = Event.allCategory;

  List<String> get categories =>
      [Event.allCategory, ...Event.categories];

  List<Event> get filtered => selectedCategory == Event.allCategory
      ? _events
      : _events.where((e) => e.category == selectedCategory).toList();

  List<Event> get all => List.unmodifiable(_events);

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _sub?.cancel();
      _sub = _repo.watchEvents().listen(
        (events) {
          _events = events;
          isLoading = false;
          notifyListeners();
        },
        onError: (Object e) {
          errorMessage = 'Could not load events. Pull to refresh.';
          isLoading = false;
          notifyListeners();
        },
      );
    } catch (_) {
      errorMessage = 'Could not load events. Pull to refresh.';
      isLoading = false;
      notifyListeners();
    }
  }

  void setCategory(String category) {
    if (selectedCategory == category) return;
    selectedCategory = category;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
