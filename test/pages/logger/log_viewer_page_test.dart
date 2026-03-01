// Widget tests for LogViewerPage.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:codeops/models/health_snapshot.dart';
import 'package:codeops/models/logger_enums.dart';
import 'package:codeops/models/logger_models.dart';
import 'package:codeops/pages/logger/log_viewer_page.dart';
import 'package:codeops/providers/logger_providers.dart';
import 'package:codeops/providers/team_providers.dart' show selectedTeamIdProvider;

void main() {
  const teamId = 'team-1';

  final sources = [
    LogSourceResponse(
      id: 's1',
      name: 'api-service',
      isActive: true,
      teamId: teamId,
      logCount: 1000,
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
  ];

  final logsPage = PageResponse<LogEntryResponse>(
    content: logEntries,
    page: 0,
    size: 20,
    totalElements: 2,
    totalPages: 1,
    isLast: true,
  );

  Widget createWidget({
    String? selectedTeamId = teamId,
    bool sourcesLoading = false,
    bool logsLoading = false,
  }) {
    final router = GoRouter(
      initialLocation: '/logger/viewer',
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
            child: Scaffold(body: LogViewerPage()),
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
        loggerSourcesProvider.overrideWith((ref) {
          if (sourcesLoading) {
            return Completer<List<LogSourceResponse>>().future;
          }
          return Future.value(sources);
        }),
        loggerLogsProvider.overrideWith((ref) {
          if (logsLoading) {
            return Completer<PageResponse<LogEntryResponse>>().future;
          }
          return Future.value(logsPage);
        }),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('LogViewerPage', () {
    testWidgets('renders header and sidebar', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Log Viewer'), findsAtLeastNWidgets(1));
      expect(find.text('LOGGER'), findsOneWidget);
      expect(find.text('Dashboard'), findsOneWidget);
    });

    testWidgets('renders filter bar with source dropdown', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('All Sources'), findsOneWidget);
      expect(find.text('All Levels'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('renders log entries', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(
        find.text('NullPointerException in UserService'),
        findsOneWidget,
      );
      expect(find.text('Server started on port 8090'), findsOneWidget);
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
