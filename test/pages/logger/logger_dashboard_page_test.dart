// Widget tests for LoggerDashboardPage.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:codeops/models/health_snapshot.dart';
import 'package:codeops/models/logger_enums.dart';
import 'package:codeops/models/logger_models.dart';
import 'package:codeops/pages/logger/logger_dashboard_page.dart';
import 'package:codeops/providers/logger_providers.dart';
import 'package:codeops/providers/team_providers.dart' show selectedTeamIdProvider;

void main() {
  const teamId = 'team-1';

  final sources = [
    LogSourceResponse(
      id: 's1',
      name: 'api-service',
      description: 'API service logs',
      teamId: teamId,
      isActive: true,
      logCount: 1000,
    ),
    LogSourceResponse(
      id: 's2',
      name: 'worker-service',
      description: 'Worker logs',
      teamId: teamId,
      isActive: true,
      logCount: 500,
    ),
  ];

  final traps = [
    LogTrapResponse(
      id: 't1',
      name: 'Error trap',
      description: 'Catches errors',
      trapType: TrapType.pattern,
      isActive: true,
      teamId: teamId,
      createdBy: 'user-1',
      triggerCount: 0,
      conditions: [],
    ),
  ];

  final logEntries = [
    LogEntryResponse(
      id: 'log1',
      sourceId: 's1',
      sourceName: 'api-service',
      level: LogLevel.error,
      message: 'NullPointerException in UserService',
      timestamp: DateTime.utc(2026, 1, 1, 12, 30, 15),
      serviceName: 'api-service',
      teamId: teamId,
    ),
    LogEntryResponse(
      id: 'log2',
      sourceId: 's1',
      sourceName: 'api-service',
      level: LogLevel.info,
      message: 'Server started on port 8090',
      timestamp: DateTime.utc(2026, 1, 1, 12, 30, 10),
      serviceName: 'api-service',
      teamId: teamId,
    ),
    LogEntryResponse(
      id: 'log3',
      sourceId: 's2',
      sourceName: 'worker-service',
      level: LogLevel.warn,
      message: 'Queue backlog exceeded threshold',
      timestamp: DateTime.utc(2026, 1, 1, 12, 29, 55),
      serviceName: 'worker-service',
      teamId: teamId,
    ),
  ];

  final logsPage = PageResponse<LogEntryResponse>(
    content: logEntries,
    page: 0,
    size: 20,
    totalElements: 3,
    totalPages: 1,
    isLast: true,
  );

  final alertCounts = <String, int>{'critical': 1, 'warning': 2};

  Widget createWidget({
    String? selectedTeamId = teamId,
    List<LogSourceResponse>? sourceList,
    List<LogTrapResponse>? trapList,
    PageResponse<LogEntryResponse>? logs,
    Map<String, int>? alerts,
    bool sourcesLoading = false,
  }) {
    final router = GoRouter(
      initialLocation: '/logger',
      routes: [
        GoRoute(
          path: '/logger',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: Scaffold(body: LoggerDashboardPage()),
          ),
        ),
        GoRoute(
          path: '/logger/viewer',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: Center(child: Text('Log Viewer')),
          ),
        ),
        GoRoute(
          path: '/logger/search',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: Center(child: Text('Log Search')),
          ),
        ),
        GoRoute(
          path: '/logger/traps',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: Center(child: Text('Log Traps')),
          ),
        ),
        GoRoute(
          path: '/logger/alerts',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: Center(child: Text('Alerts')),
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
        loggerSourcesProvider.overrideWith((ref) {
          if (sourcesLoading) {
            return Completer<List<LogSourceResponse>>().future;
          }
          return Future.value(sourceList ?? sources);
        }),
        loggerTrapsProvider.overrideWith(
          (ref) => Future.value(trapList ?? traps),
        ),
        loggerActiveAlertCountsProvider.overrideWith(
          (ref) => Future.value(alerts ?? alertCounts),
        ),
        loggerLogsProvider.overrideWith(
          (ref) => Future.value(logs ?? logsPage),
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('LoggerDashboardPage', () {
    testWidgets('renders dashboard with stat cards', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Logger Dashboard'), findsOneWidget);
      expect(find.text('Active Sources'), findsOneWidget);
      expect(find.text('Active Traps'), findsOneWidget);
      expect(find.text('Active Alerts'), findsOneWidget);
      expect(find.text('Total Logs'), findsOneWidget);
      expect(find.text('Error Rate'), findsOneWidget);
    });

    testWidgets('shows stat card values from providers', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // 2 sources
      expect(find.text('2'), findsOneWidget);
      // 1 trap
      expect(find.text('1'), findsOneWidget);
      // 3 total alerts
      expect(find.text('3'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows recent activity with log entries', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Recent Activity'), findsOneWidget);
      expect(find.text('NullPointerException in UserService'), findsOneWidget);
      expect(find.text('Server started on port 8090'), findsOneWidget);
      expect(
        find.text('Queue backlog exceeded threshold'),
        findsOneWidget,
      );
    });

    testWidgets('shows quick action buttons', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Quick Actions'), findsOneWidget);
      expect(find.text('Open Log Viewer'), findsOneWidget);
      expect(find.text('Search Logs'), findsOneWidget);
      expect(find.text('Manage Traps'), findsOneWidget);
      expect(find.text('View Metrics'), findsOneWidget);
      expect(find.text('Trace Explorer'), findsOneWidget);
    });

    testWidgets('shows time range selector', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Last 1 hour'), findsOneWidget);
    });

    testWidgets('shows logger sidebar with nav items', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('LOGGER'), findsOneWidget);
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Log Viewer'), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);
      expect(find.text('Traps'), findsOneWidget);
      expect(find.text('Alerts'), findsOneWidget);
      expect(find.text('Dashboards'), findsOneWidget);
      expect(find.text('Metrics'), findsOneWidget);
      expect(find.text('Traces'), findsOneWidget);
      expect(find.text('Retention'), findsOneWidget);
    });
  });
}
