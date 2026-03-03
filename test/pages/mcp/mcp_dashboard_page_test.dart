// Widget tests for McpDashboardPage.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/health_snapshot.dart';
import 'package:codeops/models/mcp_enums.dart';
import 'package:codeops/models/mcp_models.dart';
import 'package:codeops/pages/mcp/mcp_dashboard_page.dart';
import 'package:codeops/providers/mcp_dashboard_providers.dart';
import 'package:codeops/providers/mcp_providers.dart';
import 'package:codeops/providers/team_providers.dart' show selectedTeamIdProvider;

void main() {
  const teamId = 'team-1';

  final sessionsPage = PageResponse<McpSession>(
    content: [
      McpSession(
        id: 's1',
        status: SessionStatus.active,
        projectName: 'CodeOps-Server',
        developerName: 'Adam',
        environment: McpEnvironment.local,
        transport: McpTransport.http,
        startedAt: DateTime.now().subtract(const Duration(minutes: 10)),
        totalToolCalls: 15,
        createdAt: DateTime.now(),
      ),
      McpSession(
        id: 's2',
        status: SessionStatus.completed,
        projectName: 'CodeOps-Client',
        developerName: 'Claude',
        environment: McpEnvironment.local,
        transport: McpTransport.sse,
        startedAt: DateTime.now().subtract(const Duration(hours: 1)),
        completedAt: DateTime.now().subtract(const Duration(minutes: 30)),
        totalToolCalls: 42,
        createdAt: DateTime.now(),
      ),
      McpSession(
        id: 's3',
        status: SessionStatus.failed,
        projectName: 'CodeOps-Analytics',
        developerName: 'Bot',
        environment: McpEnvironment.development,
        transport: McpTransport.http,
        startedAt: DateTime.now().subtract(const Duration(hours: 2)),
        completedAt: DateTime.now().subtract(const Duration(hours: 1)),
        totalToolCalls: 5,
        createdAt: DateTime.now(),
      ),
    ],
    page: 0,
    size: 50,
    totalElements: 3,
    totalPages: 1,
    isLast: true,
  );

  final activityEntries = [
    ActivityFeedEntry(
      id: 'a1',
      activityType: ActivityType.sessionCompleted,
      title: 'Session completed',
      detail: 'Added authentication module',
      projectName: 'CodeOps-Server',
      actorName: 'Adam',
      createdAt: DateTime.now(),
    ),
    ActivityFeedEntry(
      id: 'a2',
      activityType: ActivityType.documentUpdated,
      title: 'Audit updated',
      detail: 'Regenerated codebase audit',
      projectName: 'CodeOps-Client',
      actorName: 'Claude',
      createdAt: DateTime.now(),
    ),
  ];

  final profiles = [
    DeveloperProfile(
      id: 'dp-1',
      displayName: 'Adam',
      isActive: true,
      teamId: teamId,
      userId: 'u1',
    ),
    DeveloperProfile(
      id: 'dp-2',
      displayName: 'Claude',
      isActive: true,
      teamId: teamId,
      userId: 'u2',
    ),
  ];

  Widget createWidget({
    String? selectedTeamId = teamId,
    PageResponse<McpSession>? sessions,
    List<ActivityFeedEntry>? activity,
    List<DeveloperProfile>? profileList,
    bool sessionsLoading = false,
    bool sessionsError = false,
  }) {
    return ProviderScope(
      overrides: [
        selectedTeamIdProvider.overrideWith((ref) => selectedTeamId),
        mcpDashboardSessionsProvider.overrideWith((ref) {
          if (sessionsLoading) {
            return Completer<PageResponse<McpSession>>().future;
          }
          if (sessionsError) {
            return Future<PageResponse<McpSession>>.error('Server error');
          }
          return Future.value(sessions ?? sessionsPage);
        }),
        mcpRecentActivityProvider.overrideWith((ref) {
          return Future.value(activity ?? activityEntries);
        }),
        mcpTeamProfilesProvider.overrideWith((ref, tid) {
          return Future.value(profileList ?? profiles);
        }),
      ],
      child: const MaterialApp(home: Scaffold(body: McpDashboardPage())),
    );
  }

  group('McpDashboardPage', () {
    testWidgets('renders dashboard header', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('MCP Dashboard'), findsOneWidget);
    });

    testWidgets('renders active sessions stat card', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Active Sessions'), findsOneWidget);
      // 1 active session (s1)
      expect(find.text('1'), findsWidgets);
    });

    testWidgets('renders sessions today stat card', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Sessions Today'), findsOneWidget);
    });

    testWidgets('renders tool calls today stat card', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Tool Calls Today'), findsOneWidget);
    });

    testWidgets('renders connected agents stat card', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Connected Agents'), findsOneWidget);
    });

    testWidgets('renders recent sessions list', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Recent Sessions'), findsOneWidget);
      expect(find.text('Adam'), findsWidgets);
      expect(find.text('Claude'), findsWidgets);
      expect(find.text('CodeOps-Server'), findsOneWidget);
      expect(find.text('CodeOps-Client'), findsOneWidget);
    });

    testWidgets('renders recent activity feed', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Recent Activity'), findsOneWidget);
      expect(find.text('Session completed'), findsOneWidget);
      expect(find.text('Audit updated'), findsOneWidget);
    });

    testWidgets('renders status badges in session list', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Active'), findsWidgets);
      expect(find.text('Completed'), findsWidgets);
      expect(find.text('Failed'), findsOneWidget);
    });

    testWidgets('renders empty state when no team selected', (tester) async {
      await tester.pumpWidget(createWidget(selectedTeamId: null));
      await tester.pumpAndSettle();

      expect(find.text('No team selected'), findsOneWidget);
    });

    testWidgets('renders loading state', (tester) async {
      await tester.pumpWidget(createWidget(sessionsLoading: true));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders error state with retry', (tester) async {
      await tester.pumpWidget(createWidget(sessionsError: true));
      await tester.pumpAndSettle();

      expect(find.text('Something Went Wrong'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('renders empty sessions message when no sessions',
        (tester) async {
      await tester.pumpWidget(createWidget(
        sessions: PageResponse<McpSession>.empty(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('No sessions found'), findsOneWidget);
    });

    testWidgets('renders empty activity message when no activity',
        (tester) async {
      await tester.pumpWidget(createWidget(activity: []));
      await tester.pumpAndSettle();

      expect(find.text('No activity found'), findsOneWidget);
    });

    testWidgets('renders quick actions', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Quick Actions'), findsOneWidget);
      expect(find.text('Sessions'), findsOneWidget);
      expect(find.text('Activity Feed'), findsOneWidget);
      expect(find.text('Documents'), findsOneWidget);
      expect(find.text('Profiles'), findsOneWidget);
    });

    testWidgets('refresh button is visible', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('view all buttons are visible', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Two "View All →" buttons (sessions + activity)
      expect(find.text('View All \u2192'), findsNWidgets(2));
    });
  });
}
