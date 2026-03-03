// Widget tests for the gateway health panel.
import 'dart:async';

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
  ];

  final health = GatewayHealth(
    isHealthy: true,
    sseStatus: 'Available',
    httpStatus: 'Available',
    protocolVersion: '2024-11-05',
    uptime: '2h 30m',
    activeSessions: 1,
  );

  Widget createWidget({
    bool loading = false,
    bool unhealthy = false,
  }) {
    return ProviderScope(
      overrides: [
        selectedTeamIdProvider.overrideWith((ref) => teamId),
        activeAgentSessionsProvider.overrideWith(
          (ref) => Future.value(activeSessions),
        ),
        gatewayHealthProvider.overrideWith((ref) {
          if (loading) return Completer<GatewayHealth>().future;
          if (unhealthy) {
            return Future.value(const GatewayHealth(
              isHealthy: false,
              sseStatus: 'Unavailable',
              httpStatus: 'Unavailable',
              protocolVersion: '—',
              uptime: '—',
              activeSessions: 0,
            ));
          }
          return Future.value(health);
        }),
        connectionHistoryProvider.overrideWith(
          (ref) => Future.value([]),
        ),
        rateLimitProvider.overrideWith(
          (ref) => Future.value(const RateLimitInfo(
            maxRequestsPerMinute: 60,
            currentRequestsPerMinute: 5,
            maxConcurrentSessions: 10,
            currentConcurrentSessions: 1,
            maxToolCallsPerSession: 200,
          )),
        ),
      ],
      child: const MaterialApp(
        home: Scaffold(body: McpConnectionStatusPage()),
      ),
    );
  }

  group('Gateway Health Panel', () {
    testWidgets('renders gateway health heading', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Gateway Health'), findsOneWidget);
    });

    testWidgets('renders healthy indicator when gateway is up', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Healthy'), findsOneWidget);
    });

    testWidgets('renders unreachable indicator when gateway is down',
        (tester) async {
      await tester.pumpWidget(createWidget(unhealthy: true));
      await tester.pumpAndSettle();

      expect(find.text('Unreachable'), findsOneWidget);
    });

    testWidgets('renders health metrics', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // SSE label appears in health metrics and agent transport badge
      expect(find.text('SSE'), findsWidgets);
      expect(find.text('Available'), findsWidgets);
      expect(find.text('Protocol'), findsOneWidget);
      expect(find.text('2024-11-05'), findsOneWidget);
      expect(find.text('Uptime'), findsOneWidget);
      expect(find.text('2h 30m'), findsOneWidget);
    });

    testWidgets('shows loading state', (tester) async {
      await tester.pumpWidget(createWidget(loading: true));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });
  });
}
