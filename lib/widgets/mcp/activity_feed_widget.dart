/// Reusable MCP activity feed widget.
///
/// An embeddable activity feed that can be placed in any page.
/// Supports filtering by [projectId], limiting results with [maxItems],
/// and optionally showing filter controls with [showFilters].
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/mcp_enums.dart';
import '../../models/mcp_models.dart';
import '../../pages/mcp/activity_feed_page.dart';
import '../../providers/mcp_activity_providers.dart';
import '../../providers/mcp_providers.dart';
import '../../theme/colors.dart';

/// A reusable activity feed widget.
///
/// Can be embedded in any page. When [projectId] is set, only shows
/// activity for that project. [maxItems] limits the number of entries.
/// [showFilters] toggles the filter toolbar.
class ActivityFeedWidget extends ConsumerWidget {
  /// Maximum number of entries to display.
  final int maxItems;

  /// Optional project ID to filter by.
  final String? projectId;

  /// Whether to show the filter toolbar.
  final bool showFilters;

  /// Creates an [ActivityFeedWidget].
  const ActivityFeedWidget({
    super.key,
    this.maxItems = 10,
    this.projectId,
    this.showFilters = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use project-specific or team-wide feed
    final feedAsync = projectId != null
        ? ref.watch(mcpProjectFeedProvider(projectId!))
        : ref.watch(mcpActivityFeedProvider);

    return feedAsync.when(
      loading: () => const SizedBox(
        height: 100,
        child: Center(
          child: CircularProgressIndicator(color: CodeOpsColors.primary),
        ),
      ),
      error: (_, __) => const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Failed to load activity',
          style: TextStyle(color: CodeOpsColors.textTertiary, fontSize: 12),
        ),
      ),
      data: (page) {
        var entries = page.content;

        // Apply type filters if showFilters is enabled
        if (showFilters) {
          final typeFilters = ref.watch(activityTypeFilterProvider);
          if (typeFilters.isNotEmpty) {
            entries = entries
                .where((e) =>
                    e.activityType != null &&
                    typeFilters.contains(e.activityType))
                .toList();
          }
        }

        // Limit entries
        if (entries.length > maxItems) {
          entries = entries.sublist(0, maxItems);
        }

        if (entries.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: Text(
                'No activity found',
                style: TextStyle(color: CodeOpsColors.textTertiary, fontSize: 12),
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showFilters) ...[
              _WidgetFilterBar(),
              const SizedBox(height: 12),
            ],
            for (var i = 0; i < entries.length; i++) ...[
              if (i > 0)
                const Divider(height: 1, color: CodeOpsColors.border),
              _CompactEntryTile(entry: entries[i]),
            ],
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Widget-level filter bar (simplified)
// ---------------------------------------------------------------------------

class _WidgetFilterBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typeFilters = ref.watch(activityTypeFilterProvider);

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final type in ActivityType.values)
          FilterChip(
            label: Text(type.displayName, style: const TextStyle(fontSize: 10)),
            selected: typeFilters.contains(type),
            onSelected: (selected) {
              final current =
                  Set<ActivityType>.from(ref.read(activityTypeFilterProvider));
              if (selected) {
                current.add(type);
              } else {
                current.remove(type);
              }
              ref.read(activityTypeFilterProvider.notifier).state = current;
            },
            selectedColor: CodeOpsColors.primary.withValues(alpha: 0.2),
            backgroundColor: CodeOpsColors.surface,
            side: BorderSide(
              color: typeFilters.contains(type)
                  ? CodeOpsColors.primary
                  : CodeOpsColors.border,
            ),
            showCheckmark: false,
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Compact Entry Tile (for embedded widget)
// ---------------------------------------------------------------------------

class _CompactEntryTile extends StatelessWidget {
  final ActivityFeedEntry entry;

  const _CompactEntryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final typeColor = activityTypeColor(entry.activityType);
    final typeIcon = activityTypeIcon(entry.activityType);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(typeIcon, size: 16, color: typeColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title ?? '',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: CodeOpsColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (entry.detail != null)
                  Text(
                    entry.detail!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: CodeOpsColors.textTertiary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (entry.projectName != null)
            Text(
              entry.projectName!,
              style: const TextStyle(
                fontSize: 10,
                color: CodeOpsColors.textTertiary,
              ),
            ),
          const SizedBox(width: 8),
          Text(
            _formatTimestamp(entry.createdAt),
            style: const TextStyle(
              fontSize: 10,
              fontFamily: 'monospace',
              color: CodeOpsColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  /// Formats a timestamp for display.
  static String _formatTimestamp(DateTime? ts) {
    if (ts == null) return '';
    return DateFormat.Hm().format(ts.toLocal());
  }
}
