// Widget tests for the setup instructions panel.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/pages/mcp/mcp_connection_status_page.dart';
import 'package:codeops/providers/mcp_connection_providers.dart';
import 'package:codeops/providers/team_providers.dart'
    show selectedTeamIdProvider;

void main() {
  const teamId = 'team-1';

  Widget createWidget() {
    return ProviderScope(
      overrides: [
        selectedTeamIdProvider.overrideWith((ref) => teamId),
        activeAgentSessionsProvider.overrideWith(
          (ref) => Future.value([]),
        ),
        gatewayHealthProvider.overrideWith(
          (ref) => Future.value(const GatewayHealth(
            isHealthy: true,
            sseStatus: 'Available',
            httpStatus: 'Available',
            protocolVersion: '2024-11-05',
            uptime: '1h',
            activeSessions: 0,
          )),
        ),
        connectionHistoryProvider.overrideWith(
          (ref) => Future.value([]),
        ),
        rateLimitProvider.overrideWith(
          (ref) => Future.value(const RateLimitInfo(
            maxRequestsPerMinute: 60,
            currentRequestsPerMinute: 0,
            maxConcurrentSessions: 10,
            currentConcurrentSessions: 0,
            maxToolCallsPerSession: 200,
          )),
        ),
      ],
      child: const MaterialApp(
        home: Scaffold(body: McpConnectionStatusPage()),
      ),
    );
  }

  group('Setup Instructions Panel', () {
    testWidgets('renders collapsed heading', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Setup Instructions'), findsOneWidget);
    });

    testWidgets('expands to show steps', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Scroll to and tap Setup Instructions
      await tester.scrollUntilVisible(
        find.text('Setup Instructions'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Setup Instructions'));
      await tester.pumpAndSettle();

      expect(find.text('Create an API Token'), findsOneWidget);
      expect(find.text('Configure Claude Code'), findsOneWidget);
      expect(find.text('Verify Connection'), findsOneWidget);
    });

    testWidgets('shows config template when expanded', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Setup Instructions'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Setup Instructions'));
      await tester.pumpAndSettle();

      expect(find.textContaining('mcpServers'), findsOneWidget);
      expect(find.textContaining('MCP_API_TOKEN'), findsOneWidget);
    });

    testWidgets('shows transport options when expanded', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Setup Instructions'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Setup Instructions'));
      await tester.pumpAndSettle();

      // Scroll down to see transport options
      await tester.scrollUntilVisible(
        find.text('Transport Options'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('Transport Options'), findsOneWidget);
    });
  });
}
