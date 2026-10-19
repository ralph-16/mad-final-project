import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets.dart';
import '../../../../data/services/calendar_launcher.dart';
import '../../../../data/services/maps_launcher.dart';
import '../../../../domain/models/event.dart';
import '../../../core/theme.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../../discover/view_models/discover_view_model.dart';
import '../../my_events/view_models/my_events_view_model.dart';class DetailView extends StatelessWidget {
  const DetailView({super.key, required this.eventId});
  final String eventId;

  @override
  Widget build(BuildContext context) {
    final discover = context.watch<DiscoverViewModel>();
    final mine = context.watch<MyEventsViewModel>();
    Event? event;
    for (final e in [
      ...discover.all,
      ...mine.upcoming,
      ...mine.history
    ]) {
      if (e.id == eventId) {
        event = e;
        break;
      }
    }

    if (event == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Event')),
        body: const EmptyState(message: 'Event not found.'),
      );
    }
    final current = event;
    final registered = mine.isRegistered(current.id);
    final past = current.isPast;

    return Scaffold(
      appBar: AppBar(title: Text(current.category)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _HeroImage(event: current),
            const SizedBox(height: 16),
            Text(current.name,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            _InfoRow(
                icon: Icons.calendar_today_outlined,
                label:
                    '${formatEventDate(current.dateTime)} · ${formatEventTime(current.dateTime)}'),
            _InfoRow(
                icon: Icons.place_outlined,
                label: '${current.locationName}\n${current.address}'),
            const SizedBox(height: 8),
            Text(current.description),
            if (registered && !past) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.check_circle,
                      size: 20, color: EventHubTheme.success),
                  const SizedBox(width: 6),
                  Text(
                    'Registered',
                    style: TextStyle(
                      color: EventHubTheme.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _openMaps(context, current),
              icon: const Icon(Icons.map_outlined),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Open location in Maps'),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _openCalendar(context, current),
              icon: const Icon(Icons.calendar_month_outlined),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Add to Calendar'),
              ),
            ),
            const SizedBox(height: 8),
            if (past)
              const FilledButton(
                onPressed: null,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Registration closed — event has passed'),
                ),
              )
            else if (registered)
              FilledButton.tonal(
                onPressed: () => _cancel(context, mine, current),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Cancel registration'),
                ),
              )
            else
              FilledButton(
                onPressed: () => _register(context, mine, current),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Register for this event'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _register(BuildContext context, MyEventsViewModel mine,
      Event event) async {
    final userId = context.read<AuthViewModel>().userId;
    if (userId == null) return;
    final ok = await mine.register(userId, event);
    if (context.mounted) {
      final msg =
          mine.takeNotice() ?? (ok ? 'Registered.' : 'Registration failed.');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _cancel(BuildContext context, MyEventsViewModel mine,
      Event event) async {
    final confirmed = await confirmCancelRegistration(
      context,
      eventName: event.name,
    );
    if (!confirmed || !context.mounted) return;
    final userId = context.read<AuthViewModel>().userId;
    if (userId == null || !context.mounted) return;
    final ok = await mine.cancel(userId, event);
    if (context.mounted) {
      final msg = mine.takeNotice() ?? (ok ? 'Cancelled.' : 'Failed.');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _openMaps(BuildContext context, Event event) async {
    final ok = await MapsLauncher.openEvent(event);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open maps.')));
    }
  }

  Future<void> _openCalendar(BuildContext context, Event event) async {
    final ok = await CalendarLauncher.addEvent(event);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not open calendar on this device.')));
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage({required this.event});
  final Event event;

  @override
  Widget build(BuildContext context) {
    if (event.imageUrl.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
            child: Icon(Icons.event_outlined,
                size: 64, semanticLabel: 'Event image placeholder')),
      );
    }
    if (isAssetImage(event.imageUrl)) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(
          event.imageUrl,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
          semanticLabel: '${event.name} image',
          errorBuilder: (c, e, s) => Container(
            height: 200,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const Center(
                child: Icon(Icons.broken_image_outlined, size: 64)),
          ),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
        event.imageUrl,
        height: 200,
        fit: BoxFit.cover,
        semanticLabel: '${event.name} image',
        errorBuilder: (c, e, s) => Container(
          height: 200,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: const Center(
              child: Icon(Icons.broken_image_outlined, size: 64)),
        ),
      ),
    );
  }
}
