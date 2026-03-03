// Widget tests for ActivityFeedPage.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/health_snapshot.dart';
import 'package:codeops/models/mcp_enums.dart';
import 'package:codeops/models/mcp_models.dart';
import 'package:codeops/pages/mcp/activity_feed_page.dart';
import 'package:codeops/providers/mcp_activity_providers.dart';
import 'package:codeops/providers/team_providers.dart' show selectedTeamIdProvider;

void main() {
  const teamId = 'team-1';

  final entries = [
    ActivityFeedEntry(
      id: 'a1',
      activityType: ActivityType.sessionCompleted,
      title: 'Session completed',
      detail: 'Added auth module with JWT support',
      projectName: 'CodeOps-Server',
      actorName: 'Adam',
      sessionId: 'session-1',
      createdAt: DateTime.now(),
    ),
    ActivityFeedEntry(
      id: 'a2',
      activityType: ActivityType.documentUpdated,
      title: 'Audit regenerated',
      detail: 'Full codebase audit',
      projectName: 'CodeOps-Client',
      actorName: 'Claude',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    ActivityFeedEntry(
      id: 'a3',
      activityType: ActivityType.impactDetected,
      title: 'Cross-service impact',
      detail: 'Auth API changed',
      projectName: 'CodeOps-Server',
      impactedServiceIdsJson: '["svc-1", "svc-2"]',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    ActivityFeedEntry(
      id: 'a4',
      activityType: ActivityType.sessionFailed,
      title: 'Session failed',
      detail: 'Build error',
      projectName: 'CodeOps-Analytics',
      relayMessageId: 'relay-msg-1',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
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

  Widget createWidget({
    String? selectedTeamId = teamId,
    PageResponse<ActivityFeedEntry>? feed,
    bool feedLoading = false,
    bool feedError = false,
  }) {
    return ProviderScope(
      overrides: [
        selectedTeamIdProvider.overrideWith((ref) => selectedTeamId),
        mcpActivityFeedProvider.overrideWith((ref) {
          if (feedLoading) {
            return Completer<PageResponse<ActivityFeedEntry>>().future;
          }
          if (feedError) {
            return Future<PageResponse<ActivityFeedEntry>>.error(
                'Server error');
          }
          return Future.value(feed ?? feedPage);
        }),
        mcpActivityPollingProvider.overrideWith(
          (ref) => const Stream<List<ActivityFeedEntry>>.empty(),
        ),
      ],
      child: const MaterialApp(home: Scaffold(body: ActivityFeedPage())),
    );
  }

  group('ActivityFeedPage', () {
    testWidgets('renders page header', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Activity Feed'), findsOneWidget);
      expect(find.text('Dashboard'), findsOneWidget);
    });

    testWidgets('renders activity entries', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Session completed'), findsOneWidget);
      expect(find.text('Audit regenerated'), findsOneWidget);
      expect(find.text('Cross-service impact'), findsOneWidget);
      expect(find.text('Session failed'), findsOneWidget);
    });

    testWidgets('renders type labels and icons', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Session Completed'), findsWidgets);
      expect(find.text('Document Updated'), findsWidgets);
      expect(find.text('Impact Detected'), findsWidgets);
      expect(find.text('Session Failed'), findsWidgets);
      expect(find.byIcon(Icons.check_circle_outline), findsWidgets);
      expect(find.byIcon(Icons.description_outlined), findsWidgets);
      expect(find.byIcon(Icons.warning_amber), findsWidgets);
    });

    testWidgets('renders impact banner for entry with impact', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(
        find.text('Impact detected \u2014 view in Registry'),
        findsOneWidget,
      );
    });

    testWidgets('renders relay link for entry with relayMessageId',
        (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('View in Relay'), findsOneWidget);
    });

    testWidgets('expand entry shows detail', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Tap first entry to expand
      await tester.tap(find.text('Session completed'));
      await tester.pumpAndSettle();

      // Should show session link in expanded view
      expect(find.text('View Session \u2192'), findsOneWidget);
    });

    testWidgets('renders filter chips for activity types', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // All ActivityType filter chips should be present
      for (final type in ActivityType.values) {
        expect(find.text(type.displayName), findsWidgets);
      }
    });

    testWidgets('renders time range dropdown', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('All Time'), findsOneWidget);
    });

    testWidgets('renders empty state when no team selected', (tester) async {
      await tester.pumpWidget(createWidget(selectedTeamId: null));
      await tester.pumpAndSettle();

      expect(find.text('No team selected'), findsOneWidget);
    });

    testWidgets('renders loading state', (tester) async {
      await tester.pumpWidget(createWidget(feedLoading: true));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders error state with retry', (tester) async {
      await tester.pumpWidget(createWidget(feedError: true));
      await tester.pumpAndSettle();

      expect(find.text('Something Went Wrong'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('renders empty state when no entries', (tester) async {
      await tester.pumpWidget(createWidget(
        feed: PageResponse<ActivityFeedEntry>.empty(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('No activity found'), findsOneWidget);
    });
  });
}
