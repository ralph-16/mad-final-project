import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets.dart';
import '../../../../domain/models/event.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../view_models/my_events_view_model.dart';class RegistrationsList extends StatefulWidget {
  const RegistrationsList({
    super.key,
    required this.showPast,
    required this.onOpenDetail,
  });

  final bool showPast;
  final void Function(String eventId) onOpenDetail;

  @override
  State<RegistrationsList> createState() => _RegistrationsListState();
}

class _RegistrationsListState extends State<RegistrationsList> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  Future<void> _reload() async {
    final userId = context.read<AuthViewModel>().userId;
    if (userId != null && mounted) {
      await context.read<MyEventsViewModel>().load(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MyEventsViewModel>();
    final List<Event> items =
        widget.showPast ? vm.history : vm.upcoming;

    if (vm.isLoading) {
      return const LoadingState(label: 'Loading your events…');
    }
    if (vm.errorMessage != null) {
      return EmptyState(
          message: vm.errorMessage!, icon: Icons.cloud_off_outlined);
    }
    if (items.isEmpty) {
      return EmptyState(
        message: widget.showPast
            ? 'No past events yet. Events you attended will appear here.'
            : 'No upcoming events. Browse and register for one.',
      );
    }
    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final event = items[i];
          return Dismissible(
            key: ValueKey(event.id),
            direction: widget.showPast
                ? DismissDirection.none
                : DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              color: Theme.of(context).colorScheme.error,
              child: const Icon(Icons.delete_outline,
                  color: Colors.white,
                  semanticLabel: 'Cancel registration'),
            ),
            confirmDismiss: (_) => _confirmCancel(context, vm, event),
            child: EventCard(
              event: event,
              registered: true,
              onTap: () => widget.onOpenDetail(event.id),
            ),
          );
        },
      ),
    );
  }  Future<bool> _confirmCancel(
      BuildContext context, MyEventsViewModel vm, Event event) async {
    final confirmed = await confirmCancelRegistration(
      context,
      eventName: event.name,
    );
    if (!confirmed || !context.mounted) return false;
    final userId = context.read<AuthViewModel>().userId;
    if (userId == null || !context.mounted) return false;
    final ok = await vm.cancel(userId, event);
    if (context.mounted) {
      final msg = vm.takeNotice() ?? (ok ? 'Cancelled.' : 'Failed.');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
    }
    return ok;
  }
}
