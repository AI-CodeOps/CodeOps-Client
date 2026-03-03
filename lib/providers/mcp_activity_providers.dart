/// Activity feed providers for the MCP module.
///
/// Manages filter state, polling via the `/since` endpoint, and derived
/// views for the activity feed page and reusable widget.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/health_snapshot.dart';
import '../models/mcp_enums.dart';
import '../models/mcp_models.dart';
import 'mcp_providers.dart';
import 'team_providers.dart' show selectedTeamIdProvider;

// ─────────────────────────────────────────────────────────────────────────────
// Filter State Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Selected activity types for multi-select filtering.
///
/// Empty set means no filter (show all types).
final activityTypeFilterProvider =
    StateProvider.autoDispose<Set<ActivityType>>((ref) => {});

/// Time range filter for the activity feed.
enum ActivityTimeRange {
  /// Show entries from today.
  today,

  /// Show entries from the last 7 days.
  last7Days,

  /// Show entries from the last 30 days.
  last30Days,

  /// Show all entries.
  all;

  /// Human-readable display label.
  String get displayName => switch (this) {
        ActivityTimeRange.today => 'Today',
        ActivityTimeRange.last7Days => 'Last 7 Days',
        ActivityTimeRange.last30Days => 'Last 30 Days',
        ActivityTimeRange.all => 'All Time',
      };

  /// Returns the start [DateTime] cutoff for this range, or null for all.
  DateTime? get cutoff {
    final now = DateTime.now();
    return switch (this) {
      ActivityTimeRange.today => DateTime(now.year, now.month, now.day),
      ActivityTimeRange.last7Days => now.subtract(const Duration(days: 7)),
      ActivityTimeRange.last30Days => now.subtract(const Duration(days: 30)),
      ActivityTimeRange.all => null,
    };
  }
}

/// Selected time range filter.
final activityTimeRangeProvider =
    StateProvider.autoDispose<ActivityTimeRange>((ref) => ActivityTimeRange.all);

/// Project name filter for the activity feed.
final activityProjectFilterProvider =
    StateProvider.autoDispose<String?>((ref) => null);

/// Toggle to show only entries with impact (impactedServiceIdsJson set).
final activityImpactOnlyProvider =
    StateProvider.autoDispose<bool>((ref) => false);

/// Current page index for the activity feed (0-based).
final activityPageProvider = StateProvider.autoDispose<int>((ref) => 0);

// ─────────────────────────────────────────────────────────────────────────────
// Data Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Fetches the paginated team activity feed for the activity page.
///
/// Returns a large page (100 entries) so filters can be applied client-side.
final mcpActivityFeedProvider =
    FutureProvider.autoDispose<PageResponse<ActivityFeedEntry>>((ref) {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) {
    return Future.value(PageResponse<ActivityFeedEntry>.empty());
  }
  final api = ref.watch(mcpApiProvider);
  return api.getTeamFeed(teamId: teamId, size: 100);
});

// ─────────────────────────────────────────────────────────────────────────────
// Filtered / Derived Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Applies all filters to the activity feed entries.
final mcpFilteredActivityProvider =
    Provider.autoDispose<List<ActivityFeedEntry>>((ref) {
  final feedAsync = ref.watch(mcpActivityFeedProvider);
  final typeFilters = ref.watch(activityTypeFilterProvider);
  final timeRange = ref.watch(activityTimeRangeProvider);
  final projectFilter = ref.watch(activityProjectFilterProvider);
  final impactOnly = ref.watch(activityImpactOnlyProvider);

  final entries = feedAsync.whenOrNull(
        data: (page) => page.content,
      ) ??
      <ActivityFeedEntry>[];

  return entries.where((e) {
    // Type filter (multi-select — empty means all)
    if (typeFilters.isNotEmpty &&
        e.activityType != null &&
        !typeFilters.contains(e.activityType)) {
      return false;
    }

    // Time range filter
    final cutoff = timeRange.cutoff;
    if (cutoff != null && e.createdAt != null && e.createdAt!.isBefore(cutoff)) {
      return false;
    }

    // Project filter
    if (projectFilter != null &&
        projectFilter!.isNotEmpty &&
        e.projectName != projectFilter) {
      return false;
    }

    // Impact-only toggle
    if (impactOnly &&
        (e.impactedServiceIdsJson == null ||
            e.impactedServiceIdsJson!.isEmpty ||
            e.impactedServiceIdsJson == '[]')) {
      return false;
    }

    return true;
  }).toList();
});

/// Distinct project names from the activity feed for filter dropdown.
final activityProjectNamesProvider =
    Provider.autoDispose<List<String>>((ref) {
  final feedAsync = ref.watch(mcpActivityFeedProvider);
  final entries = feedAsync.whenOrNull(
        data: (page) => page.content,
      ) ??
      <ActivityFeedEntry>[];

  final names = entries
      .map((e) => e.projectName)
      .where((n) => n != null && n.isNotEmpty)
      .cast<String>()
      .toSet()
      .toList()
    ..sort();
  return names;
});

/// Page size for the activity feed.
const activityPageSize = 20;

/// Returns the total page count for the filtered activity list.
final mcpActivityPageCountProvider = Provider.autoDispose<int>((ref) {
  final filtered = ref.watch(mcpFilteredActivityProvider);
  return (filtered.length / activityPageSize).ceil().clamp(1, 999);
});

/// Returns the current page of filtered activity entries.
final mcpPagedActivityProvider =
    Provider.autoDispose<List<ActivityFeedEntry>>((ref) {
  final filtered = ref.watch(mcpFilteredActivityProvider);
  final page = ref.watch(activityPageProvider);
  final start = page * activityPageSize;
  if (start >= filtered.length) return [];
  final end = (start + activityPageSize).clamp(0, filtered.length);
  return filtered.sublist(start, end);
});

// ─────────────────────────────────────────────────────────────────────────────
// Polling Provider
// ─────────────────────────────────────────────────────────────────────────────

/// Polls `/activity/team/since` every 30 seconds for new entries.
///
/// Returns the count of new entries since the last poll.
/// The page listens to this and prepends new entries.
final mcpActivityPollingProvider =
    StreamProvider.autoDispose<List<ActivityFeedEntry>>((ref) {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) return const Stream.empty();

  final api = ref.watch(mcpApiProvider);
  var lastPoll = DateTime.now().toUtc();

  return Stream.periodic(const Duration(seconds: 30), (_) async {
    final since = lastPoll;
    lastPoll = DateTime.now().toUtc();
    return api.getTeamActivitySince(teamId: teamId, since: since);
  }).asyncMap((future) => future);
});

/// Count of new entries from polling, for badge display.
final mcpNewActivityCountProvider = Provider.autoDispose<int>((ref) {
  final pollingAsync = ref.watch(mcpActivityPollingProvider);
  return pollingAsync.whenOrNull(data: (entries) => entries.length) ?? 0;
});
