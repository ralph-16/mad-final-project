import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets.dart';
import '../../my_events/view_models/my_events_view_model.dart';
import '../view_models/discover_view_model.dart';

/// Browse events + category filter. Tapping a card opens detail.
class DiscoverView extends StatefulWidget {
  const DiscoverView({super.key, required this.onOpenDetail});
  final void Function(String eventId) onOpenDetail;

  @override
  State<DiscoverView> createState() => _DiscoverViewState();
}

class _DiscoverViewState extends State<DiscoverView> {
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DiscoverViewModel>().load();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _clearFilters(DiscoverViewModel vm) {
    _search.clear();
    vm.clearFilters();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DiscoverViewModel>();
    final mine = context.watch<MyEventsViewModel>();

    return RefreshIndicator(
      onRefresh: () => vm.load(),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextField(
                controller: _search,
                onChanged: vm.setSearchQuery,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search events…',
                  prefixIcon: const Icon(Icons.search_outlined),
                  suffixIcon: vm.searchQuery.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear_outlined),
                          tooltip: 'Clear search',
                          onPressed: () {
                            _search.clear();
                            vm.setSearchQuery('');
                          },
                        ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: CategoryChips(
              options: vm.categories,
              selected: vm.selectedCategory,
              onSelected: vm.setCategory,
              counts: vm.counts,
            ),
          ),
          if (vm.isLoading)
            const SliverFillRemaining(
                child: LoadingState(label: 'Loading events…'))
          else if (vm.errorMessage != null)
            SliverFillRemaining(
              child: EmptyState(
                message: vm.errorMessage!,
                icon: Icons.cloud_off_outlined,
              ),
            )
          else if (vm.filtered.isEmpty)
            SliverFillRemaining(
              child: EmptyState(
                message: vm.hasActiveFilters
                    ? 'No events found.'
                    : 'No events in this category yet.',
                details: vm.hasActiveFilters
                    ? 'Try a different search or category.'
                    : null,
                actionLabel:
                    vm.hasActiveFilters ? 'Clear filters' : null,
                onAction: vm.hasActiveFilters
                    ? () => _clearFilters(vm)
                    : null,
                icon: Icons.search_off_outlined,
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
              sliver: SliverList.separated(
                itemCount: vm.filtered.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final event = vm.filtered[i];
                  return EventCard(
                    event: event,
                    registered: mine.isRegistered(event.id),
                    onTap: () => widget.onOpenDetail(event.id),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
