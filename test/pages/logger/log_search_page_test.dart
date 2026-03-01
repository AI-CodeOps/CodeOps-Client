// Widget tests for LogSearchPage.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:codeops/models/health_snapshot.dart';
import 'package:codeops/models/logger_models.dart';
import 'package:codeops/pages/logger/log_search_page.dart';
import 'package:codeops/providers/logger_providers.dart';
import 'package:codeops/providers/team_providers.dart' show selectedTeamIdProvider;

void main() {
  const teamId = 'team-1';

  final savedQueries = [
    SavedQueryResponse(
      id: 'sq-1',
      name: 'Error logs',
      queryJson: '{"level":"ERROR"}',
      teamId: teamId,
      createdBy: 'user-1',
      isShared: false,
      executionCount: 5,
    ),
  ];

  final queryHistory = PageResponse<QueryHistoryResponse>(
    content: [
      QueryHistoryResponse(
        id: 'qh-1',
        queryJson: '{"level":"ERROR"}',
        resultCount: 42,
        executionTimeMs: 120,
        createdBy: 'user-1',
      ),
    ],
    page: 0,
    size: 20,
    totalElements: 1,
    totalPages: 1,
    isLast: true,
  );

  Widget createWidget({
    String? selectedTeamId = teamId,
  }) {
    final router = GoRouter(
      initialLocation: '/logger/search',
      routes: [
        GoRoute(
          path: '/logger',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: Scaffold(body: Center(child: Text('Dashboard'))),
          ),
        ),
        GoRoute(
          path: '/logger/search',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: Scaffold(body: LogSearchPage()),
          ),
        ),
        GoRoute(
          path: '/logger/viewer',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: Center(child: Text('Viewer')),
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
        loggerSavedQueriesProvider.overrideWith(
          (ref) => Future.value(savedQueries),
        ),
        loggerQueryHistoryProvider.overrideWith(
          (ref) => Future.value(queryHistory),
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('LogSearchPage', () {
    testWidgets('renders header and sidebar', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Log Search'), findsOneWidget);
      expect(find.text('LOGGER'), findsOneWidget);
      expect(find.text('Dashboard'), findsOneWidget);
    });

    testWidgets('renders query builder', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Query Builder'), findsOneWidget);
      expect(find.text('Search'), findsAtLeastNWidgets(1));
      expect(find.text('Visual Mode'), findsOneWidget);
    });

    testWidgets('shows empty search state initially', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Search Logs'), findsOneWidget);
      expect(
        find.text('Build a query above and click Search to find log entries.'),
        findsOneWidget,
      );
    });

    testWidgets('shows saved queries and history in bottom bar',
        (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Saved Queries (1)'), findsOneWidget);
      expect(find.text('History (1)'), findsOneWidget);
    });
  });
}
