/// MCP activity feed page.
///
/// Displays at `/mcp/activity` with a vertical timeline of team activity,
/// filter toolbar (type multi-select, time range, project, impact-only),
/// expandable entries with detail/stats, impact banners, relay links,
/// and 30-second polling for new entries via `/since`.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/mcp_enums.dart';
import '../../models/mcp_models.dart';
import '../../providers/mcp_activity_providers.dart';
import '../../providers/team_providers.dart' show selectedTeamIdProvider;
import '../../theme/colors.dart';
import '../../widgets/shared/empty_state.dart';
import '../../widgets/shared/error_panel.dart';

/// The MCP activity feed page.
class ActivityFeedPage extends ConsumerStatefulWidget {
  /// Creates an [ActivityFeedPage].
  const ActivityFeedPage({super.key});

  @override
  ConsumerState<ActivityFeedPage> createState() => _ActivityFeedPageState();
}

class _ActivityFeedPageState extends ConsumerState<ActivityFeedPage> {
  final List<ActivityFeedEntry> _polledEntries = [];
  Timer? _pollTimer;
  DateTime _lastPollTime = DateTime.now().toUtc();

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  /// Starts the 30-second polling timer.
  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) => _poll());
  }

  /// Polls for new entries since the last check.
  Future<void> _poll() async {
    final teamId = ref.read(selectedTeamIdProvider);
    if (teamId == null) return;
    try {
      final api = ref.read(mcpActivityFeedProvider);
      // Only poll if we have loaded data successfully
      if (!api.hasValue) return;
      final since = _lastPollTime;
      _lastPollTime = DateTime.now().toUtc();
      // Use the polling provider stream — just read latest
      final pollingAsync = ref.read(mcpActivityPollingProvider);
      pollingAsync.whenData((entries) {
        if (entries.isNotEmpty && mounted) {
          setState(() {
            _polledEntries.insertAll(0, entries);
          });
        }
      });
    } catch (_) {
      // Silently ignore poll errors
    }
  }

  /// Refreshes all activity feed data.
  void _refresh() {
    setState(() => _polledEntries.clear());
    _lastPollTime = DateTime.now().toUtc();
    ref.invalidate(mcpActivityFeedProvider);
  }

  @override
  Widget build(BuildContext context) {
    final teamId = ref.watch(selectedTeamIdProvider);

    if (teamId == null) {
      return const EmptyState(
        icon: Icons.group_outlined,
        title: 'No team selected',
        subtitle: 'Select a team to view the activity feed.',
      );
    }

    final feedAsync = ref.watch(mcpActivityFeedProvider);

    // Listen to polling for new entries
    ref.listen(mcpActivityPollingProvider, (_, next) {
      next.whenData((entries) {
        if (entries.isNotEmpty && mounted) {
          setState(() {
            for (final e in entries) {
              if (!_polledEntries.any((p) => p.id == e.id)) {
                _polledEntries.insert(0, e);
              }
            }
          });
        }
      });
    });

    return feedAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: CodeOpsColors.primary),
      ),
      error: (error, _) => ErrorPanel.fromException(
        error,
        onRetry: _refresh,
      ),
      data: (_) {
        final pagedEntries = ref.watch(mcpPagedActivityProvider);
        // Merge polled entries at top, dedup by id
        final allEntries = <ActivityFeedEntry>[
          ..._polledEntries,
          ...pagedEntries.where(
            (e) => !_polledEntries.any((p) => p.id == e.id),
          ),
        ];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _HeaderRow(
                onRefresh: _refresh,
                newCount: _polledEntries.length,
              ),
              const SizedBox(height: 20),

              // Filter toolbar
              const _FilterToolbar(),
              const SizedBox(height: 16),

              // New entries banner
              if (_polledEntries.isNotEmpty)
                _NewEntriesBanner(
                  count: _polledEntries.length,
                  onDismiss: () => setState(() => _polledEntries.clear()),
                ),

              // Timeline
              if (allEntries.isEmpty)
                const EmptyState(
                  icon: Icons.rss_feed_outlined,
                  title: 'No activity found',
                  subtitle: 'Adjust your filters or check back later.',
                )
              else
                _ActivityTimeline(entries: allEntries),

              const SizedBox(height: 16),

              // Pagination
              const _PaginationBar(),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Header Row
// ---------------------------------------------------------------------------

class _HeaderRow extends StatelessWidget {
  final VoidCallback onRefresh;
  final int newCount;

  const _HeaderRow({required this.onRefresh, required this.newCount});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: () => context.go('/mcp'),
          borderRadius: BorderRadius.circular(4),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_back, size: 18, color: CodeOpsColors.primary),
              SizedBox(width: 4),
              Text(
                'Dashboard',
                style: TextStyle(fontSize: 12, color: CodeOpsColors.primary),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Text(
          'Activity Feed',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        if (newCount > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: CodeOpsColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$newCount new',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh',
          onPressed: onRefresh,
          color: CodeOpsColors.textSecondary,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// New Entries Banner
// ---------------------------------------------------------------------------

class _NewEntriesBanner extends StatelessWidget {
  final int count;
  final VoidCallback onDismiss;

  const _NewEntriesBanner({required this.count, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: CodeOpsColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: CodeOpsColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.notifications_active_outlined,
            size: 16,
            color: CodeOpsColors.primary,
          ),
          const SizedBox(width: 8),
          Text(
            '$count new ${count == 1 ? 'entry' : 'entries'}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: CodeOpsColors.primary,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: onDismiss,
            child: const Text(
              'Dismiss',
              style: TextStyle(fontSize: 11, color: CodeOpsColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter Toolbar
// ---------------------------------------------------------------------------

class _FilterToolbar extends ConsumerWidget {
  const _FilterToolbar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typeFilters = ref.watch(activityTypeFilterProvider);
    final timeRange = ref.watch(activityTimeRangeProvider);
    final projectFilter = ref.watch(activityProjectFilterProvider);
    final impactOnly = ref.watch(activityImpactOnlyProvider);
    final projectNames = ref.watch(activityProjectNamesProvider);

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Activity type multi-select chips
        for (final type in ActivityType.values)
          FilterChip(
            label: Text(
              type.displayName,
              style: const TextStyle(fontSize: 11),
            ),
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
              ref.read(activityPageProvider.notifier).state = 0;
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
          ),

        // Divider
        Container(width: 1, height: 24, color: CodeOpsColors.border),

        // Time range dropdown
        _TimeRangeDropdown(
          value: timeRange,
          onChanged: (v) {
            ref.read(activityTimeRangeProvider.notifier).state =
                v ?? ActivityTimeRange.all;
            ref.read(activityPageProvider.notifier).state = 0;
          },
        ),

        // Project dropdown
        if (projectNames.isNotEmpty)
          _ProjectDropdown(
            value: projectFilter,
            projects: projectNames,
            onChanged: (v) {
              ref.read(activityProjectFilterProvider.notifier).state = v;
              ref.read(activityPageProvider.notifier).state = 0;
            },
          ),

        // Impact-only toggle
        FilterChip(
          label: const Text(
            'Impact Only',
            style: TextStyle(fontSize: 11),
          ),
          selected: impactOnly,
          onSelected: (v) {
            ref.read(activityImpactOnlyProvider.notifier).state = v;
            ref.read(activityPageProvider.notifier).state = 0;
          },
          selectedColor: CodeOpsColors.warning.withValues(alpha: 0.2),
          backgroundColor: CodeOpsColors.surface,
          side: BorderSide(
            color: impactOnly ? CodeOpsColors.warning : CodeOpsColors.border,
          ),
          avatar: impactOnly
              ? Icon(Icons.warning_amber, size: 14, color: CodeOpsColors.warning)
              : null,
          showCheckmark: false,
          visualDensity: VisualDensity.compact,
        ),

        // Clear all
        if (typeFilters.isNotEmpty ||
            timeRange != ActivityTimeRange.all ||
            projectFilter != null ||
            impactOnly)
          TextButton(
            onPressed: () {
              ref.read(activityTypeFilterProvider.notifier).state = {};
              ref.read(activityTimeRangeProvider.notifier).state =
                  ActivityTimeRange.all;
              ref.read(activityProjectFilterProvider.notifier).state = null;
              ref.read(activityImpactOnlyProvider.notifier).state = false;
              ref.read(activityPageProvider.notifier).state = 0;
            },
            child: const Text(
              'Clear Filters',
              style: TextStyle(fontSize: 12, color: CodeOpsColors.primary),
            ),
          ),
      ],
    );
  }
}

class _TimeRangeDropdown extends StatelessWidget {
  final ActivityTimeRange value;
  final ValueChanged<ActivityTimeRange?> onChanged;

  const _TimeRangeDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: CodeOpsColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CodeOpsColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ActivityTimeRange>(
          value: value,
          dropdownColor: CodeOpsColors.surface,
          style:
              const TextStyle(fontSize: 11, color: CodeOpsColors.textPrimary),
          isDense: true,
          items: [
            for (final range in ActivityTimeRange.values)
              DropdownMenuItem(
                value: range,
                child: Text(range.displayName, style: const TextStyle(fontSize: 11)),
              ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _ProjectDropdown extends StatelessWidget {
  final String? value;
  final List<String> projects;
  final ValueChanged<String?> onChanged;

  const _ProjectDropdown({
    required this.value,
    required this.projects,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: CodeOpsColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CodeOpsColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: value,
          hint: const Text(
            'All Projects',
            style: TextStyle(fontSize: 11, color: CodeOpsColors.textTertiary),
          ),
          dropdownColor: CodeOpsColors.surface,
          style:
              const TextStyle(fontSize: 11, color: CodeOpsColors.textPrimary),
          isDense: true,
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text(
                'All Projects',
                style:
                    TextStyle(fontSize: 11, color: CodeOpsColors.textSecondary),
              ),
            ),
            for (final name in projects)
              DropdownMenuItem<String?>(
                value: name,
                child: Text(name, style: const TextStyle(fontSize: 11)),
              ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Activity Timeline
// ---------------------------------------------------------------------------

class _ActivityTimeline extends StatefulWidget {
  final List<ActivityFeedEntry> entries;

  const _ActivityTimeline({required this.entries});

  @override
  State<_ActivityTimeline> createState() => _ActivityTimelineState();
}

class _ActivityTimelineState extends State<_ActivityTimeline> {
  final Set<String> _expandedIds = {};

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < widget.entries.length; i++)
          _TimelineEntryTile(
            entry: widget.entries[i],
            isLast: i == widget.entries.length - 1,
            isExpanded: _expandedIds.contains(widget.entries[i].id),
            onToggleExpand: () {
              setState(() {
                final id = widget.entries[i].id;
                if (id == null) return;
                if (_expandedIds.contains(id)) {
                  _expandedIds.remove(id);
                } else {
                  _expandedIds.add(id);
                }
              });
            },
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Timeline Entry Tile
// ---------------------------------------------------------------------------

class _TimelineEntryTile extends StatelessWidget {
  final ActivityFeedEntry entry;
  final bool isLast;
  final bool isExpanded;
  final VoidCallback onToggleExpand;

  const _TimelineEntryTile({
    required this.entry,
    required this.isLast,
    required this.isExpanded,
    required this.onToggleExpand,
  });

  @override
  Widget build(BuildContext context) {
    final typeColor = activityTypeColor(entry.activityType);
    final typeIcon = activityTypeIcon(entry.activityType);
    final hasImpact = entry.impactedServiceIdsJson != null &&
        entry.impactedServiceIdsJson!.isNotEmpty &&
        entry.impactedServiceIdsJson != '[]';
    final hasRelay = entry.relayMessageId != null;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline rail
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: typeColor.withValues(alpha: 0.15),
                  ),
                  child: Icon(typeIcon, size: 14, color: typeColor),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: CodeOpsColors.border),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main card
                  InkWell(
                    onTap: onToggleExpand,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: CodeOpsColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: CodeOpsColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Type label + timestamp
                          Row(
                            children: [
                              Text(
                                entry.activityType?.displayName ?? 'Unknown',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: typeColor,
                                ),
                              ),
                              if (entry.projectName != null) ...[
                                const SizedBox(width: 8),
                                Text(
                                  entry.projectName!,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: CodeOpsColors.textTertiary,
                                  ),
                                ),
                              ],
                              const Spacer(),
                              Text(
                                _formatTimestamp(entry.createdAt),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontFamily: 'monospace',
                                  color: CodeOpsColors.textTertiary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                isExpanded
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                size: 16,
                                color: CodeOpsColors.textTertiary,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // Title
                          Text(
                            entry.title ?? '',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: CodeOpsColors.textPrimary,
                            ),
                          ),
                          // Detail preview (when not expanded)
                          if (!isExpanded && entry.detail != null) ...[
                            const SizedBox(height: 4),
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
                          // Actor
                          if (entry.actorName != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.person_outline,
                                  size: 12,
                                  color: CodeOpsColors.textTertiary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  entry.actorName!,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: CodeOpsColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Expanded detail
                  if (isExpanded) _ExpandedDetail(entry: entry),

                  // Impact banner
                  if (hasImpact)
                    _ImpactBanner(
                      impactJson: entry.impactedServiceIdsJson!,
                    ),

                  // Relay link
                  if (hasRelay)
                    _RelayLink(relayMessageId: entry.relayMessageId!),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Formats a timestamp for display.
  static String _formatTimestamp(DateTime? ts) {
    if (ts == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (ts.isAfter(today)) {
      return DateFormat.Hm().format(ts.toLocal());
    }
    return DateFormat('MMM d, HH:mm').format(ts.toLocal());
  }
}

// ---------------------------------------------------------------------------
// Expanded Detail
// ---------------------------------------------------------------------------

class _ExpandedDetail extends StatelessWidget {
  final ActivityFeedEntry entry;

  const _ExpandedDetail({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CodeOpsColors.surface,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
        border: Border.all(color: CodeOpsColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (entry.detail != null) ...[
            Text(
              entry.detail!,
              style: const TextStyle(
                fontSize: 12,
                height: 1.5,
                color: CodeOpsColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
          ],
          // Metadata rows
          if (entry.sourceModule != null)
            _MetaRow(label: 'Module', value: entry.sourceModule!),
          if (entry.sourceEntityId != null)
            _MetaRow(label: 'Entity ID', value: entry.sourceEntityId!),
          if (entry.sessionId != null)
            _MetaRow(label: 'Session', value: entry.sessionId!),
          if (entry.projectId != null)
            _MetaRow(label: 'Project ID', value: entry.projectId!),
          // Session link
          if (entry.sessionId != null) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: () =>
                  context.go('/mcp/sessions/${entry.sessionId}'),
              child: const Text(
                'View Session \u2192',
                style: TextStyle(
                  fontSize: 11,
                  color: CodeOpsColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetaRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: CodeOpsColors.textTertiary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 10,
                fontFamily: 'monospace',
                color: CodeOpsColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Impact Banner
// ---------------------------------------------------------------------------

class _ImpactBanner extends StatelessWidget {
  final String impactJson;

  const _ImpactBanner({required this.impactJson});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: CodeOpsColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: CodeOpsColors.warning.withValues(alpha: 0.3),
        ),
      ),
      child: InkWell(
        onTap: () => context.go('/registry/dependencies/impact'),
        child: Row(
          children: [
            Icon(
              Icons.warning_amber,
              size: 14,
              color: CodeOpsColors.warning,
            ),
            const SizedBox(width: 6),
            const Text(
              'Impact detected — view in Registry',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: CodeOpsColors.warning,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward,
              size: 12,
              color: CodeOpsColors.warning,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Relay Link
// ---------------------------------------------------------------------------

class _RelayLink extends StatelessWidget {
  final String relayMessageId;

  const _RelayLink({required this.relayMessageId});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: InkWell(
        onTap: () => context.go('/relay'),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline, size: 12, color: CodeOpsColors.secondary),
            SizedBox(width: 4),
            Text(
              'View in Relay',
              style: TextStyle(
                fontSize: 10,
                color: CodeOpsColors.secondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pagination Bar
// ---------------------------------------------------------------------------

class _PaginationBar extends ConsumerWidget {
  const _PaginationBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = ref.watch(activityPageProvider);
    final pageCount = ref.watch(mcpActivityPageCountProvider);
    final totalFiltered = ref.watch(mcpFilteredActivityProvider).length;

    if (totalFiltered <= activityPageSize) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left, size: 20),
          onPressed: page > 0
              ? () => ref.read(activityPageProvider.notifier).state = page - 1
              : null,
          color: CodeOpsColors.textSecondary,
        ),
        Text(
          'Page ${page + 1} of $pageCount',
          style: const TextStyle(
            fontSize: 12,
            color: CodeOpsColors.textSecondary,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right, size: 20),
          onPressed: page < pageCount - 1
              ? () => ref.read(activityPageProvider.notifier).state = page + 1
              : null,
          color: CodeOpsColors.textSecondary,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Shared Activity Type Helpers
// ---------------------------------------------------------------------------

/// Returns the icon for the given [ActivityType].
IconData activityTypeIcon(ActivityType? type) {
  return switch (type) {
    ActivityType.sessionCompleted => Icons.check_circle_outline,
    ActivityType.sessionFailed => Icons.error_outline,
    ActivityType.documentUpdated => Icons.description_outlined,
    ActivityType.conventionChanged => Icons.rule,
    ActivityType.directiveChanged => Icons.tune,
    ActivityType.impactDetected => Icons.warning_amber,
    null => Icons.circle_outlined,
  };
}

/// Returns the color for the given [ActivityType].
Color activityTypeColor(ActivityType? type) {
  return switch (type) {
    ActivityType.sessionCompleted => CodeOpsColors.success,
    ActivityType.sessionFailed => CodeOpsColors.error,
    ActivityType.documentUpdated => const Color(0xFFA855F7),
    ActivityType.conventionChanged => CodeOpsColors.primary,
    ActivityType.directiveChanged => CodeOpsColors.warning,
    ActivityType.impactDetected => CodeOpsColors.error,
    null => CodeOpsColors.textTertiary,
  };
}
