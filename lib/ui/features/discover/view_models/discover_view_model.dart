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
  String searchQuery = '';

  List<String> get categories =>
      [Event.allCategory, ...Event.categories];

  /// Live per-category totals over the loaded events (All = everything).
  Map<String, int> get counts {
    final map = <String, int>{Event.allCategory: _events.length};
    for (final c in Event.categories) {
      map[c] = _events.where((e) => e.category == c).length;
    }
    return map;
  }

  int countFor(String category) => counts[category] ?? 0;

  bool get hasActiveFilters =>
      selectedCategory != Event.allCategory || searchQuery.isNotEmpty;

  List<Event> get filtered {
    final q = searchQuery.trim().toLowerCase();
    return _events.where((e) {
      if (selectedCategory != Event.allCategory &&
          e.category != selectedCategory) {
        return false;
      }
      if (q.isEmpty) return true;
      return e.name.toLowerCase().contains(q) ||
          e.category.toLowerCase().contains(q) ||
          e.locationName.toLowerCase().contains(q) ||
          e.address.toLowerCase().contains(q) ||
          e.description.toLowerCase().contains(q);
    }).toList();
  }

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

  void setSearchQuery(String query) {
    if (searchQuery == query) return;
    searchQuery = query;
    notifyListeners();
  }

  /// Resets category to All and clears the search (used by Clear filters).
  void clearFilters() {
    if (!hasActiveFilters) return;
    selectedCategory = Event.allCategory;
    searchQuery = '';
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
