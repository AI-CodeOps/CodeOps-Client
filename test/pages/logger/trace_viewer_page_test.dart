// Widget tests for TraceViewerPage.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:codeops/models/health_snapshot.dart';
import 'package:codeops/models/logger_models.dart';
import 'package:codeops/pages/logger/trace_viewer_page.dart';
import 'package:codeops/providers/logger_providers.dart';
import 'package:codeops/providers/team_providers.dart'
    show selectedTeamIdProvider;

void main() {
  const teamId = 'team-1';

  final now = DateTime.utc(2026, 1, 15, 10, 0);

  final traces = [
    TraceListResponse(
      correlationId: 'corr-1',
      traceId: 'trace-1',
      rootService: 'api-gateway',
      rootOperation: 'GET /users',
      spanCount: 5,
      serviceCount: 3,
      totalDurationMs: 120,
      hasErrors: false,
      startTime: now.subtract(const Duration(minutes: 5)),
      endTime: now,
    ),
    TraceListResponse(
      correlationId: 'corr-2',
      traceId: 'trace-2',
      rootService: 'auth-service',
      rootOperation: 'POST /login',
      spanCount: 3,
      serviceCount: 2,
      totalDurationMs: 250,
      hasErrors: true,
      startTime: now.subtract(const Duration(minutes: 3)),
      endTime: now,
    ),
    TraceListResponse(
      correlationId: 'corr-3',
      traceId: 'trace-3',
      rootService: 'api-gateway',
      rootOperation: 'GET /orders',
      spanCount: 8,
      serviceCount: 4,
      totalDurationMs: 450,
      hasErrors: false,
      startTime: now.subtract(const Duration(minutes: 1)),
      endTime: now,
    ),
  ];

  Widget createWidget({
    String? selectedTeamId = teamId,
    List<TraceListResponse>? traceList,
    bool loading = false,
  }) {
    final pageResponse = PageResponse<TraceListResponse>(
      content: traceList ?? traces,
      page: 0,
      size: 20,
      totalElements: (traceList ?? traces).length,
      totalPages: 1,
      isLast: true,
    );

    final router = GoRouter(
      initialLocation: '/logger/traces',
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
            child: Center(child: Text('Alerts')),
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
            child: Scaffold(body: TraceViewerPage()),
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
        loggerTracesProvider.overrideWith((ref) {
          if (loading) {
            return Completer<PageResponse<TraceListResponse>>().future;
          }
          return Future.value(pageResponse);
        }),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('TraceViewerPage', () {
    testWidgets('renders toolbar and sidebar', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Trace Viewer'), findsOneWidget);
      expect(find.text('LOGGER'), findsOneWidget);
    });

    testWidgets('shows traces in data table', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('GET /users'), findsOneWidget);
      expect(find.text('POST /login'), findsOneWidget);
      expect(find.text('GET /orders'), findsOneWidget);
    });

    testWidgets('shows search field', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.search), findsAtLeastNWidgets(1));
    });

    testWidgets('shows errors only filter chip', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Errors Only'), findsOneWidget);
    });

    testWidgets('shows pagination info', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('3 traces'), findsOneWidget);
      expect(find.text('Page 1 of 1'), findsOneWidget);
    });

    testWidgets('shows empty state when no team selected', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget(selectedTeamId: null));
      await tester.pumpAndSettle();

      expect(find.text('No team selected'), findsOneWidget);
    });

    testWidgets('shows service names in table', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('api-gateway'), findsAtLeastNWidgets(1));
      expect(find.text('auth-service'), findsOneWidget);
    });
  });
}
