// Widget tests for AlertsPage.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:codeops/models/health_snapshot.dart';
import 'package:codeops/models/logger_enums.dart';
import 'package:codeops/models/logger_models.dart';
import 'package:codeops/pages/logger/alerts_page.dart';
import 'package:codeops/providers/logger_providers.dart';
import 'package:codeops/providers/team_providers.dart'
    show selectedTeamIdProvider;

void main() {
  const teamId = 'team-1';

  final rules = [
    AlertRuleResponse(
      id: 'rule-1',
      name: 'Error Spike Notifier',
      trapId: 'trap-1',
      trapName: 'Error Spike Detector',
      channelId: 'ch-1',
      channelName: 'Ops Email',
      severity: AlertSeverity.critical,
      isActive: true,
      throttleMinutes: 15,
      teamId: teamId,
    ),
    AlertRuleResponse(
      id: 'rule-2',
      name: 'Memory Alert',
      trapId: 'trap-2',
      trapName: 'Memory Threshold',
      channelId: 'ch-2',
      channelName: 'Slack Alerts',
      severity: AlertSeverity.warning,
      isActive: false,
      throttleMinutes: 30,
      teamId: teamId,
    ),
  ];

  final historyEntries = [
    AlertHistoryResponse(
      id: 'alert-1',
      ruleId: 'rule-1',
      ruleName: 'Error Spike Notifier',
      trapId: 'trap-1',
      trapName: 'Error Spike Detector',
      channelId: 'ch-1',
      channelName: 'Ops Email',
      severity: AlertSeverity.critical,
      status: AlertStatus.fired,
      message: 'Error count exceeded threshold',
      teamId: teamId,
      createdAt: DateTime.utc(2026, 1, 15, 10, 30),
    ),
    AlertHistoryResponse(
      id: 'alert-2',
      ruleId: 'rule-1',
      ruleName: 'Error Spike Notifier',
      trapId: 'trap-1',
      trapName: 'Error Spike Detector',
      channelId: 'ch-1',
      channelName: 'Ops Email',
      severity: AlertSeverity.warning,
      status: AlertStatus.acknowledged,
      message: 'Spike acknowledged by ops',
      teamId: teamId,
      createdAt: DateTime.utc(2026, 1, 15, 9, 0),
    ),
    AlertHistoryResponse(
      id: 'alert-3',
      ruleId: 'rule-2',
      ruleName: 'Memory Alert',
      trapId: 'trap-2',
      trapName: 'Memory Threshold',
      channelId: 'ch-2',
      channelName: 'Slack Alerts',
      severity: AlertSeverity.info,
      status: AlertStatus.resolved,
      message: 'Memory normalized',
      teamId: teamId,
      createdAt: DateTime.utc(2026, 1, 14, 8, 0),
    ),
  ];

  final historyPage = PageResponse<AlertHistoryResponse>(
    content: historyEntries,
    page: 0,
    size: 20,
    totalElements: 3,
    totalPages: 1,
    isLast: true,
  );

  final activeCounts = {'FIRED': 2, 'ACKNOWLEDGED': 1, 'RESOLVED': 5};

  Widget createWidget({
    String? selectedTeamId = teamId,
    List<AlertRuleResponse>? ruleList,
    PageResponse<AlertHistoryResponse>? history,
    Map<String, int>? counts,
    bool rulesLoading = false,
    bool historyLoading = false,
  }) {
    final router = GoRouter(
      initialLocation: '/logger/alerts',
      routes: [
        GoRoute(
          path: '/logger',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: Scaffold(body: Center(child: Text('Dashboard'))),
          ),
        ),
        GoRoute(
          path: '/logger/viewer',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: Center(child: Text('Viewer')),
          ),
        ),
        GoRoute(
          path: '/logger/search',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: Center(child: Text('Search')),
          ),
        ),
        GoRoute(
          path: '/logger/traps',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: Center(child: Text('Traps')),
          ),
        ),
        GoRoute(
          path: '/logger/alerts',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: Scaffold(body: AlertsPage()),
          ),
        ),
        GoRoute(
          path: '/logger/alerts/channels',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: Center(child: Text('Channels')),
          ),
        ),
        GoRoute(
          path: '/logger/dashboards',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: Center(child: Text('Dashboards')),
          ),
        ),
        GoRoute(
          path: '/logger/metrics',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: Center(child: Text('Metrics')),
          ),
        ),
        GoRoute(
          path: '/logger/traces',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: Center(child: Text('Traces')),
          ),
        ),
        GoRoute(
          path: '/logger/traces/:correlationId',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: Center(child: Text('Trace Detail')),
          ),
        ),
        GoRoute(
          path: '/logger/retention',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: Center(child: Text('Retention')),
          ),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        selectedTeamIdProvider.overrideWith((ref) => selectedTeamId),
        loggerAlertRulesProvider.overrideWith((ref) {
          if (rulesLoading) {
            return Completer<List<AlertRuleResponse>>().future;
          }
          return Future.value(ruleList ?? rules);
        }),
        loggerAlertHistoryProvider.overrideWith((ref) {
          if (historyLoading) {
            return Completer<PageResponse<AlertHistoryResponse>>().future;
          }
          return Future.value(history ?? historyPage);
        }),
        loggerActiveAlertCountsProvider.overrideWith((ref) {
          return Future.value(counts ?? activeCounts);
        }),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('AlertsPage', () {
    testWidgets('renders toolbar and sidebar', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Alerts'), findsAtLeastNWidgets(1));
      expect(find.text('LOGGER'), findsOneWidget);
    });

    testWidgets('shows Rules and History tabs', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Rules'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
    });

    testWidgets('shows rules in table', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Error Spike Notifier'), findsOneWidget);
      expect(find.text('Memory Alert'), findsOneWidget);
    });

    testWidgets('shows rule severity badges', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Critical'), findsOneWidget);
      // 'Warning' appears as both severity badge and sidebar text.
      expect(find.text('Warning'), findsAtLeastNWidgets(1));
    });

    testWidgets('switches to History tab', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Tap History tab.
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      // History table should show alert entries.
      expect(find.text('Error count exceeded threshold'), findsOneWidget);
      expect(find.text('Memory normalized'), findsOneWidget);
    });

    testWidgets('shows status badges in history', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Switch to History tab.
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      expect(find.text('Fired'), findsAtLeastNWidgets(1));
      expect(find.text('Acknowledged'), findsAtLeastNWidgets(1));
      expect(find.text('Resolved'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows Ack button for fired alerts', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      // Only the fired alert should have an Ack button.
      expect(find.text('Ack'), findsOneWidget);
    });

    testWidgets('shows badge counts', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      expect(find.text('Firing (2)'), findsOneWidget);
      expect(find.text('Acknowledged (1)'), findsOneWidget);
      expect(find.text('Resolved (5)'), findsOneWidget);
    });

    testWidgets('shows empty state when no team selected', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget(selectedTeamId: null));
      await tester.pumpAndSettle();

      expect(find.text('No team selected'), findsOneWidget);
    });
  });
}
