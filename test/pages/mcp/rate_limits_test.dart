// Widget tests for the rate limits panel.
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
            currentRequestsPerMinute: 15,
            maxConcurrentSessions: 10,
            currentConcurrentSessions: 3,
            maxToolCallsPerSession: 200,
          )),
        ),
      ],
      child: const MaterialApp(
        home: Scaffold(body: McpConnectionStatusPage()),
      ),
    );
  }

  group('Rate Limits Panel', () {
    testWidgets('renders panel heading', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Rate Limits'), findsOneWidget);
    });

    testWidgets('renders rate limit bars', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Requests / min'), findsOneWidget);
      expect(find.text('15 / 60'), findsOneWidget);
      expect(find.text('Concurrent Sessions'), findsOneWidget);
      expect(find.text('3 / 10'), findsOneWidget);
      expect(find.text('Tool Calls / Session'), findsOneWidget);
      expect(find.text('0 / 200'), findsOneWidget);
    });

    testWidgets('renders progress indicators', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byType(LinearProgressIndicator), findsNWidgets(3));
    });
  });
}
