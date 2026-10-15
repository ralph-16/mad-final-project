import 'package:flutter/material.dart';

import '../../domain/models/event.dart';
import 'theme.dart';

/// Event card: image, name, date/time, location, category.
/// 48dp targets, ripple feedback, no layout shift on press.
class EventCard extends StatelessWidget {
  const EventCard({
    super.key,
    required this.event,
    required this.registered,
    this.onTap,
  });

  final Event event;
  final bool registered;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ImageHeader(event: event),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _CategoryTag(label: event.category),
                      const Spacer(),
                      if (registered)
                        Semantics(
                          label: 'Registered',
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle,
                                  size: 18,
                                  color: EventHubTheme.success),
                              const SizedBox(width: 4),
                              Text(
                                'Registered',
                                style: TextStyle(
                                  color: EventHubTheme.success,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (event.isPast)
                        const Text('Ended',
                            style:
                                TextStyle(fontStyle: FontStyle.italic)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.name,
                    style: EventHubTheme.display(
                      context,
                      Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${formatEventDate(event.dateTime)} · ${formatEventTime(event.dateTime)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.place_outlined, size: 16),
                      const SizedBox(width: 4),
                      Expanded(child: Text(event.locationName)),
                    ],
                  ),
                  if (event.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      event.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style:
                          Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageHeader extends StatelessWidget {
  const _ImageHeader({required this.event});
  final Event event;

  @override
  Widget build(BuildContext context) {
    const height = 160.0;
    if (event.imageUrl.isEmpty) {
      return Container(
        height: height,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Center(
          child: Icon(Icons.event_outlined,
              size: 48, semanticLabel: 'Event image placeholder'),
        ),
      );
    }
    if (isAssetImage(event.imageUrl)) {
      return Image.asset(
        event.imageUrl,
        height: height,
        fit: BoxFit.cover,
        semanticLabel: '${event.name} image',
        errorBuilder: (c, e, s) => Container(
          height: height,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: const Center(
            child: Icon(Icons.broken_image_outlined,
                size: 48, semanticLabel: 'Event image unavailable'),
          ),
        ),
      );
    }
    return Image.network(
      event.imageUrl,
      height: height,
      fit: BoxFit.cover,
      semanticLabel: '${event.name} image',
      loadingBuilder: (c, child, progress) => progress == null
          ? child
          : const SizedBox(
              height: height,
              child: Center(child: CircularProgressIndicator())),
      errorBuilder: (c, e, s) => Container(
        height: height,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Center(
          child: Icon(Icons.broken_image_outlined,
              size: 48, semanticLabel: 'Event image unavailable'),
        ),
      ),
    );
  }
}

class _CategoryTag extends StatelessWidget {
  const _CategoryTag({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: TextStyle(color: scheme.primary)),
    );
  }
}

/// 48dp category filter chips in a horizontal list.
/// Pass [counts] (e.g. from DiscoverViewModel) to show per-category totals.
class CategoryChips extends StatelessWidget {
  const CategoryChips({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.counts,
  });

  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;
  final Map<String, int>? counts;

  String _label(String option) {
    final n = counts?[option];
    return n == null ? option : '$option ($n)';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final label = options[i];
          final isSelected = selected == label;
          return ChoiceChip(
            label: Text(
              _label(label),
              overflow: TextOverflow.ellipsis,
            ),
            selected: isSelected,
            labelStyle: TextStyle(
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimary
                  : null,
              fontWeight:
                  isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
            materialTapTargetSize: MaterialTapTargetSize.padded,
            onSelected: (_) => onSelected(label),
          );
        },
      ),
    );
  }
}

class LoadingState extends StatelessWidget {
  const LoadingState({super.key, this.label = 'Loading events…'});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 12),
          Text(label),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.message,
    this.icon,
    this.details,
    this.actionLabel,
    this.onAction,
  });
  final String message;
  final IconData? icon;

  /// Optional calm explanation shown under the message (e.g. how to recover).
  final String? details;

  /// Optional recovery action (e.g. "Clear filters").
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon ?? Icons.event_busy_outlined,
                size: 48, semanticLabel: 'No events'),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (details != null) ...[
              const SizedBox(height: 4),
              Text(
                details!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant,
                    ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.filter_alt_off_outlined),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Reusable cancellation confirmation. Returns true only on explicit
/// confirmation; dismissal or "Keep" leaves everything unchanged.
Future<bool> confirmCancelRegistration(
  BuildContext context, {
  required String eventName,
}) async {
  final scheme = Theme.of(context).colorScheme;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: const Text('Cancel Registration?'),
      content: Text(
        'Are you sure you want to cancel your registration for "$eventName"?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(c).pop(false),
          child: const Text('Keep Registration'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
          ),
          onPressed: () => Navigator.of(c).pop(true),
          child: const Text('Cancel Registration'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
