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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DiscoverViewModel>().load();
    });
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
            child: CategoryChips(
              options: vm.categories,
              selected: vm.selectedCategory,
              onSelected: vm.setCategory,
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
            const SliverFillRemaining(
              child: EmptyState(
                message: 'No events in this category yet.',
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
