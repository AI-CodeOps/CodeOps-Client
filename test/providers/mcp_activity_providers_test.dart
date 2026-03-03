// Tests for MCP activity feed providers.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/health_snapshot.dart';
import 'package:codeops/models/mcp_enums.dart';
import 'package:codeops/models/mcp_models.dart';
import 'package:codeops/providers/mcp_activity_providers.dart';
import 'package:codeops/providers/team_providers.dart' show selectedTeamIdProvider;

void main() {
  const teamId = 'team-1';

  final entries = [
    ActivityFeedEntry(
      id: 'a1',
      activityType: ActivityType.sessionCompleted,
      title: 'Session completed',
      detail: 'Auth module added',
      projectName: 'Server',
      createdAt: DateTime.now(),
    ),
    ActivityFeedEntry(
      id: 'a2',
      activityType: ActivityType.documentUpdated,
      title: 'Document updated',
      detail: 'Audit regenerated',
      projectName: 'Client',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    ActivityFeedEntry(
      id: 'a3',
      activityType: ActivityType.impactDetected,
      title: 'Impact detected',
      detail: 'Auth API changed',
      projectName: 'Server',
      impactedServiceIdsJson: '["svc-1"]',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    ActivityFeedEntry(
      id: 'a4',
      activityType: ActivityType.sessionFailed,
      title: 'Session failed',
      detail: 'Build error',
      projectName: 'Analytics',
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
  ];

  final feedPage = PageResponse<ActivityFeedEntry>(
    content: entries,
    page: 0,
    size: 100,
    totalElements: 4,
    totalPages: 1,
    isLast: true,
  );

  ProviderContainer createContainer({
    Set<ActivityType> typeFilters = const {},
    ActivityTimeRange timeRange = ActivityTimeRange.all,
    String? projectFilter,
    bool impactOnly = false,
    int page = 0,
  }) {
    return ProviderContainer(
      overrides: [
        selectedTeamIdProvider.overrideWith((ref) => teamId),
        mcpActivityFeedProvider.overrideWith(
          (ref) => Future.value(feedPage),
        ),
        if (typeFilters.isNotEmpty)
          activityTypeFilterProvider.overrideWith((ref) => typeFilters),
        if (timeRange != ActivityTimeRange.all)
          activityTimeRangeProvider.overrideWith((ref) => timeRange),
        if (projectFilter != null)
          activityProjectFilterProvider.overrideWith((ref) => projectFilter),
        if (impactOnly)
          activityImpactOnlyProvider.overrideWith((ref) => true),
        if (page > 0) activityPageProvider.overrideWith((ref) => page),
      ],
    );
  }

  group('mcpFilteredActivityProvider', () {
    test('returns all entries when no filters are set', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      await container.read(mcpActivityFeedProvider.future);

      final filtered = container.read(mcpFilteredActivityProvider);
      expect(filtered.length, 4);
    });

    test('filters by activity type', () async {
      final container = createContainer(
        typeFilters: {ActivityType.sessionCompleted},
      );
      addTearDown(container.dispose);

      await container.read(mcpActivityFeedProvider.future);

      final filtered = container.read(mcpFilteredActivityProvider);
      expect(filtered.length, 1);
      expect(filtered.first.id, 'a1');
    });

    test('filters by time range', () async {
      final container = createContainer(timeRange: ActivityTimeRange.last7Days);
      addTearDown(container.dispose);

      await container.read(mcpActivityFeedProvider.future);

      final filtered = container.read(mcpFilteredActivityProvider);
      // a4 is 10 days old, should be excluded
      expect(filtered.length, 3);
      expect(filtered.map((e) => e.id), isNot(contains('a4')));
    });

    test('filters by project name', () async {
      final container = createContainer(projectFilter: 'Server');
      addTearDown(container.dispose);

      await container.read(mcpActivityFeedProvider.future);

      final filtered = container.read(mcpFilteredActivityProvider);
      expect(filtered.length, 2);
      expect(filtered.every((e) => e.projectName == 'Server'), isTrue);
    });

    test('filters by impact only', () async {
      final container = createContainer(impactOnly: true);
      addTearDown(container.dispose);

      await container.read(mcpActivityFeedProvider.future);

      final filtered = container.read(mcpFilteredActivityProvider);
      expect(filtered.length, 1);
      expect(filtered.first.id, 'a3');
    });
  });

  group('activityProjectNamesProvider', () {
    test('returns distinct sorted project names', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      await container.read(mcpActivityFeedProvider.future);

      final names = container.read(activityProjectNamesProvider);
      expect(names, ['Analytics', 'Client', 'Server']);
    });
  });

  group('mcpNewActivityCountProvider', () {
    test('returns 0 when no polling data', () async {
      final container = ProviderContainer(
        overrides: [
          selectedTeamIdProvider.overrideWith((ref) => teamId),
          mcpActivityPollingProvider.overrideWith(
            (ref) => const Stream<List<ActivityFeedEntry>>.empty(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final count = container.read(mcpNewActivityCountProvider);
      expect(count, 0);
    });
  });
}
