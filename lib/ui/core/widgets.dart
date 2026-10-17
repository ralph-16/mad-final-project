import 'package:flutter/material.dart';

import '../../domain/models/event.dart';
import 'theme.dart';

/// Event card: full-bleed image with overlaid text and badges.
/// The image fills the entire card; text sits on a gradient scrim.
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

  static const _cardHeight = 220.0;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: _cardHeight,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _ImageHeader(event: event),
              // Bottom gradient scrim for text readability
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black87],
                      stops: [0.35, 1.0],
                    ),
                  ),
                ),
              ),
              // Top-left: category pill
              Positioned(
                top: 12,
                left: 12,
                child: _CategoryTag(label: event.category),
              ),
              // Top-right: status badge
              if (registered || event.isPast)
                Positioned(
                  top: 12,
                  right: 12,
                  child: _OverlayBadge(
                    child: registered
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle,
                                  size: 16, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                'Registered',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            'Ended',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontStyle: FontStyle.italic,
                              fontSize: 12,
                            ),
                          ),
                  ),
                ),
              // Bottom: event info overlaid on image
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      event.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.event_outlined,
                            size: 14, color: Colors.white70),
                        const SizedBox(width: 4),
                        Text(
                          '${formatEventDate(event.dateTime)} · ${formatEventTime(event.dateTime)}',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.place_outlined,
                            size: 14, color: Colors.white70),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.locationName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    if (event.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        event.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white60, fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Translucent dark pill for Registered/Ended floating over the image.
class _OverlayBadge extends StatelessWidget {
  const _OverlayBadge({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
      ),
      child: child,
    );
  }
}

class _ImageHeader extends StatelessWidget {
  const _ImageHeader({required this.event});
  final Event event;

  @override
  Widget build(BuildContext context) {
    if (event.imageUrl.isEmpty) {
      return Container(
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
        fit: BoxFit.cover,
        semanticLabel: '${event.name} image',
        errorBuilder: (c, e, s) => Container(
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
      fit: BoxFit.cover,
      semanticLabel: '${event.name} image',
      loadingBuilder: (c, child, progress) => progress == null
          ? child
          : const Center(child: CircularProgressIndicator()),
      errorBuilder: (c, e, s) => Container(
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: EventHubTheme.primary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
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
