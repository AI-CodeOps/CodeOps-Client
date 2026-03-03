/// Dashboard-specific providers for the MCP module.
///
/// Provides aggregated metrics and filtered data for the MCP dashboard page.
/// Builds on top of the core [McpApiService] and existing MCP providers.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/health_snapshot.dart';
import '../models/mcp_enums.dart';
import '../models/mcp_models.dart';
import '../services/cloud/mcp_api.dart';
import 'mcp_providers.dart';
import 'team_providers.dart' show selectedTeamIdProvider;

// ─────────────────────────────────────────────────────────────────────────────
// Session Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Fetches the current user's sessions (large page) for dashboard metrics.
///
/// Returns up to 50 recent sessions so we can derive active count,
/// sessions today, and tool call totals.
final mcpDashboardSessionsProvider =
    FutureProvider.autoDispose<PageResponse<McpSession>>((ref) {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) return Future.value(PageResponse<McpSession>.empty());
  final api = ref.watch(mcpApiProvider);
  return api.getMySessions(teamId: teamId, size: 50);
});

/// Counts sessions in ACTIVE or INITIALIZING state from dashboard data.
final mcpActiveSessionCountProvider = Provider.autoDispose<int>((ref) {
  final sessionsAsync = ref.watch(mcpDashboardSessionsProvider);
  return sessionsAsync.whenOrNull(
        data: (page) => page.content
            .where((s) =>
                s.status == SessionStatus.active ||
                s.status == SessionStatus.initializing)
            .length,
      ) ??
      0;
});

/// Filters sessions started today.
final mcpSessionsTodayProvider =
    Provider.autoDispose<List<McpSession>>((ref) {
  final sessionsAsync = ref.watch(mcpDashboardSessionsProvider);
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  return sessionsAsync.whenOrNull(
        data: (page) => page.content
            .where((s) =>
                s.startedAt != null && s.startedAt!.isAfter(startOfDay))
            .toList(),
      ) ??
      [];
});

/// Sums tool calls across all sessions started today.
final mcpToolCallsTodayProvider = Provider.autoDispose<int>((ref) {
  final sessionsToday = ref.watch(mcpSessionsTodayProvider);
  return sessionsToday.fold<int>(
    0,
    (sum, s) => sum + (s.totalToolCalls ?? 0),
  );
});

/// Returns the 5 most recent sessions for display.
final mcpRecentSessionsProvider =
    Provider.autoDispose<List<McpSession>>((ref) {
  final sessionsAsync = ref.watch(mcpDashboardSessionsProvider);
  return sessionsAsync.whenOrNull(
        data: (page) => page.content.take(5).toList(),
      ) ??
      [];
});

// ─────────────────────────────────────────────────────────────────────────────
// Activity Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Fetches the 10 most recent team activity entries for the dashboard.
final mcpRecentActivityProvider =
    FutureProvider.autoDispose<List<ActivityFeedEntry>>((ref) async {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) return [];
  final api = ref.watch(mcpApiProvider);
  final page = await api.getTeamFeed(teamId: teamId, size: 10);
  return page.content;
});

// ─────────────────────────────────────────────────────────────────────────────
// Developer Profile Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Counts active developer profiles (connected agents) for the dashboard.
final mcpConnectedAgentsCountProvider = Provider.autoDispose<int>((ref) {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) return 0;
  final profilesAsync = ref.watch(mcpTeamProfilesProvider(teamId));
  return profilesAsync.whenOrNull(
        data: (profiles) =>
            profiles.where((p) => p.isActive == true).length,
      ) ??
      0;
});

// ─────────────────────────────────────────────────────────────────────────────
// Document Health
// ─────────────────────────────────────────────────────────────────────────────

/// Aggregated document health statistics for the dashboard.
class DocumentHealthStats {
  /// Number of fresh (unflagged) documents.
  final int fresh;

  /// Number of flagged (stale) documents.
  final int flagged;

  /// Total document count.
  final int total;

  /// Creates a [DocumentHealthStats].
  const DocumentHealthStats({
    required this.fresh,
    required this.flagged,
    required this.total,
  });
}
