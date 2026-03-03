// Widget tests for the connected agents panel.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/mcp_enums.dart';
import 'package:codeops/models/mcp_models.dart';
import 'package:codeops/pages/mcp/mcp_connection_status_page.dart';
import 'package:codeops/providers/mcp_connection_providers.dart';
import 'package:codeops/providers/team_providers.dart'
    show selectedTeamIdProvider;

void main() {
  const teamId = 'team-1';

  final activeSessions = [
    McpSession(
      id: 'sess-1',
      status: SessionStatus.active,
      developerName: 'Adam',
      projectName: 'CodeOps-Server',
      transport: McpTransport.sse,
      startedAt: DateTime(2026, 3, 1, 8, 0),
      totalToolCalls: 12,
    ),
    McpSession(
      id: 'sess-2',
      status: SessionStatus.initializing,
      developerName: 'Claude',
      projectName: 'CodeOps-Client',
      transport: McpTransport.http,
      startedAt: DateTime(2026, 3, 1, 9, 30),
      totalToolCalls: 0,
    ),
  ];

  Widget createWidget({
    List<McpSession>? sessions,
    bool empty = false,
  }) {
    return ProviderScope(
      overrides: [
        selectedTeamIdProvider.overrideWith((ref) => teamId),
        activeAgentSessionsProvider.overrideWith(
          (ref) => Future.value(empty ? [] : (sessions ?? activeSessions)),
        ),
        gatewayHealthProvider.overrideWith(
          (ref) => Future.value(const GatewayHealth(
            isHealthy: true,
            sseStatus: 'Available',
            httpStatus: 'Available',
            protocolVersion: '2024-11-05',
            uptime: '1h',
            activeSessions: 2,
          )),
        ),
        connectionHistoryProvider.overrideWith(
          (ref) => Future.value([]),
        ),
        rateLimitProvider.overrideWith(
          (ref) => Future.value(const RateLimitInfo(
            maxRequestsPerMinute: 60,
            currentRequestsPerMinute: 10,
            maxConcurrentSessions: 10,
            currentConcurrentSessions: 2,
            maxToolCallsPerSession: 200,
          )),
        ),
      ],
      child: const MaterialApp(
        home: Scaffold(body: McpConnectionStatusPage()),
      ),
    );
  }

  group('Connected Agents Panel', () {
    testWidgets('renders panel heading with count badge', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Connected Agents'), findsOneWidget);
      // Count badge shows '2' — may appear alongside other text
      expect(find.text('2'), findsWidgets);
    });

    testWidgets('renders column headers', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Developer'), findsOneWidget);
      expect(find.text('Transport'), findsOneWidget);
      expect(find.text('Status'), findsOneWidget);
      expect(find.text('Connected Since'), findsOneWidget);
      expect(find.text('Tool Calls'), findsOneWidget);
      expect(find.text('Project'), findsOneWidget);
    });

    testWidgets('renders agent rows', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Adam'), findsOneWidget);
      expect(find.text('Claude'), findsOneWidget);
      expect(find.text('CodeOps-Server'), findsOneWidget);
      expect(find.text('CodeOps-Client'), findsOneWidget);
    });

    testWidgets('renders transport badges', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('SSE'), findsWidgets);
      expect(find.text('HTTP'), findsWidgets);
    });

    testWidgets('renders disconnect buttons', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Disconnect'), findsNWidgets(2));
    });

    testWidgets('shows empty state when no agents', (tester) async {
      await tester.pumpWidget(createWidget(empty: true));
      await tester.pumpAndSettle();

      expect(find.text('No active agents'), findsOneWidget);
    });

    testWidgets('shows no team state', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          selectedTeamIdProvider.overrideWith((ref) => null),
        ],
        child: const MaterialApp(
          home: Scaffold(body: McpConnectionStatusPage()),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('No team selected'), findsOneWidget);
    });
  });
}
