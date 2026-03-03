// Tests for MCP dashboard providers.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/health_snapshot.dart';
import 'package:codeops/models/mcp_enums.dart';
import 'package:codeops/models/mcp_models.dart';
import 'package:codeops/providers/mcp_dashboard_providers.dart';
import 'package:codeops/providers/mcp_providers.dart';
import 'package:codeops/providers/team_providers.dart' show selectedTeamIdProvider;

void main() {
  const teamId = 'team-1';
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);

  final sessions = [
    McpSession(
      id: 's1',
      status: SessionStatus.active,
      startedAt: now.subtract(const Duration(minutes: 5)),
      totalToolCalls: 10,
    ),
    McpSession(
      id: 's2',
      status: SessionStatus.initializing,
      startedAt: now.subtract(const Duration(minutes: 1)),
      totalToolCalls: 0,
    ),
    McpSession(
      id: 's3',
      status: SessionStatus.completed,
      startedAt: now.subtract(const Duration(hours: 2)),
      totalToolCalls: 25,
    ),
    McpSession(
      id: 's4',
      status: SessionStatus.failed,
      startedAt: now.subtract(const Duration(days: 1)),
      totalToolCalls: 3,
    ),
  ];

  final sessionsPage = PageResponse<McpSession>(
    content: sessions,
    page: 0,
    size: 50,
    totalElements: 4,
    totalPages: 1,
    isLast: true,
  );

  final activityEntries = [
    ActivityFeedEntry(
      id: 'a1',
      activityType: ActivityType.sessionCompleted,
      title: 'Session done',
    ),
    ActivityFeedEntry(
      id: 'a2',
      activityType: ActivityType.documentUpdated,
      title: 'Doc update',
    ),
  ];

  final profiles = [
    DeveloperProfile(id: 'dp-1', isActive: true),
    DeveloperProfile(id: 'dp-2', isActive: true),
    DeveloperProfile(id: 'dp-3', isActive: false),
  ];

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        selectedTeamIdProvider.overrideWith((ref) => teamId),
        mcpDashboardSessionsProvider.overrideWith(
          (ref) => Future.value(sessionsPage),
        ),
        mcpTeamProfilesProvider.overrideWith(
          (ref, tid) => Future.value(profiles),
        ),
        mcpRecentActivityProvider.overrideWith(
          (ref) => Future.value(activityEntries),
        ),
      ],
    );
  }

  group('mcpActiveSessionCountProvider', () {
    test('counts active and initializing sessions', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      // Wait for sessions to load
      await container.read(mcpDashboardSessionsProvider.future);

      final count = container.read(mcpActiveSessionCountProvider);
      // s1 = active, s2 = initializing → 2
      expect(count, 2);
    });
  });

  group('mcpSessionsTodayProvider', () {
    test('filters sessions started today', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      await container.read(mcpDashboardSessionsProvider.future);

      final todaySessions = container.read(mcpSessionsTodayProvider);
      // s1 (5min ago), s2 (1min ago), s3 (2hr ago) are today
      // s4 (1 day ago) is not today
      final expectedCount = sessions
          .where((s) =>
              s.startedAt != null && s.startedAt!.isAfter(startOfDay))
          .length;
      expect(todaySessions.length, expectedCount);
    });
  });

  group('mcpToolCallsTodayProvider', () {
    test('sums tool calls for sessions started today', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      await container.read(mcpDashboardSessionsProvider.future);

      final totalCalls = container.read(mcpToolCallsTodayProvider);
      // Only sessions started today contribute their tool calls
      final expectedCalls = sessions
          .where((s) =>
              s.startedAt != null && s.startedAt!.isAfter(startOfDay))
          .fold<int>(0, (sum, s) => sum + (s.totalToolCalls ?? 0));
      expect(totalCalls, expectedCalls);
    });
  });

  group('mcpRecentSessionsProvider', () {
    test('returns first 5 sessions', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      await container.read(mcpDashboardSessionsProvider.future);

      final recent = container.read(mcpRecentSessionsProvider);
      expect(recent.length, 4); // only 4 sessions in test data
      expect(recent.first.id, 's1');
    });
  });

  group('mcpRecentActivityProvider', () {
    test('returns activity entries', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      final activity =
          await container.read(mcpRecentActivityProvider.future);
      expect(activity.length, 2);
      expect(activity.first.title, 'Session done');
    });
  });

  group('mcpConnectedAgentsCountProvider', () {
    test('counts active developer profiles', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      // Wait for profiles to load
      await container.read(mcpTeamProfilesProvider(teamId).future);

      final count = container.read(mcpConnectedAgentsCountProvider);
      // dp-1 and dp-2 are active, dp-3 is not
      expect(count, 2);
    });
  });

  group('DocumentHealthStats', () {
    test('constructor creates valid stats', () {
      const stats = DocumentHealthStats(
        fresh: 5,
        flagged: 2,
        total: 7,
      );
      expect(stats.fresh, 5);
      expect(stats.flagged, 2);
      expect(stats.total, 7);
    });
  });
}
