// Widget tests for ActivityFeedWidget.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/health_snapshot.dart';
import 'package:codeops/models/mcp_enums.dart';
import 'package:codeops/models/mcp_models.dart';
import 'package:codeops/providers/mcp_activity_providers.dart';
import 'package:codeops/providers/mcp_providers.dart';
import 'package:codeops/providers/team_providers.dart' show selectedTeamIdProvider;
import 'package:codeops/widgets/mcp/activity_feed_widget.dart';

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
      activityType: ActivityType.sessionFailed,
      title: 'Session failed',
      detail: 'Build error',
      projectName: 'Analytics',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
  ];

  final feedPage = PageResponse<ActivityFeedEntry>(
    content: entries,
    page: 0,
    size: 100,
    totalElements: 3,
    totalPages: 1,
    isLast: true,
  );

  Widget createWidget({
    int maxItems = 10,
    String? projectId,
    bool showFilters = false,
  }) {
    return ProviderScope(
      overrides: [
        selectedTeamIdProvider.overrideWith((ref) => teamId),
        mcpActivityFeedProvider.overrideWith(
          (ref) => Future.value(feedPage),
        ),
        mcpProjectFeedProvider.overrideWith(
          (ref, pid) => Future.value(feedPage),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: ActivityFeedWidget(
            maxItems: maxItems,
            projectId: projectId,
            showFilters: showFilters,
          ),
        ),
      ),
    );
  }

  group('ActivityFeedWidget', () {
    testWidgets('renders activity entries', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Session completed'), findsOneWidget);
      expect(find.text('Document updated'), findsOneWidget);
      expect(find.text('Session failed'), findsOneWidget);
    });

    testWidgets('respects maxItems limit', (tester) async {
      await tester.pumpWidget(createWidget(maxItems: 2));
      await tester.pumpAndSettle();

      expect(find.text('Session completed'), findsOneWidget);
      expect(find.text('Document updated'), findsOneWidget);
      // Third entry should not be visible
      expect(find.text('Session failed'), findsNothing);
    });

    testWidgets('shows filter bar when showFilters is true', (tester) async {
      await tester.pumpWidget(createWidget(showFilters: true));
      await tester.pumpAndSettle();

      // Filter chips for each activity type should appear
      for (final type in ActivityType.values) {
        expect(find.text(type.displayName), findsWidgets);
      }
    });

    testWidgets('uses project feed when projectId is set', (tester) async {
      await tester.pumpWidget(createWidget(projectId: 'proj-1'));
      await tester.pumpAndSettle();

      // Should still render entries (from project feed provider)
      expect(find.text('Session completed'), findsOneWidget);
    });
  });
}
