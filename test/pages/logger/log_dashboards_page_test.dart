// Widget tests for LogDashboardsPage.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:codeops/models/logger_models.dart';
import 'package:codeops/pages/logger/log_dashboards_page.dart';
import 'package:codeops/providers/logger_providers.dart';
import 'package:codeops/providers/team_providers.dart'
    show selectedTeamIdProvider;

void main() {
  const teamId = 'team-1';

  final dashboards = [
    DashboardResponse(
      id: 'dash-1',
      name: 'Error Overview',
      description: 'Tracks error rates across services',
      teamId: teamId,
      createdBy: 'user-1',
      isShared: false,
      isTemplate: false,
      refreshIntervalSeconds: 30,
      widgets: [],
      createdAt: DateTime.utc(2026, 1, 10),
      updatedAt: DateTime.utc(2026, 1, 15),
    ),
    DashboardResponse(
      id: 'dash-2',
      name: 'Performance Metrics',
      description: 'Latency and throughput dashboard',
      teamId: teamId,
      createdBy: 'user-1',
      isShared: true,
      isTemplate: false,
      refreshIntervalSeconds: 60,
      widgets: [],
      createdAt: DateTime.utc(2026, 1, 12),
    ),
  ];

  final sharedDashboards = [
    DashboardResponse(
      id: 'dash-3',
      name: 'Team Status Board',
      teamId: teamId,
      createdBy: 'user-2',
      isShared: true,
      isTemplate: false,
      refreshIntervalSeconds: 30,
      widgets: [],
    ),
  ];

  final templates = [
    DashboardResponse(
      id: 'tmpl-1',
      name: 'Default Template',
      teamId: teamId,
      createdBy: 'user-1',
      isShared: false,
      isTemplate: true,
      refreshIntervalSeconds: 30,
      widgets: [],
    ),
  ];

  Widget createWidget({
    String? selectedTeamId = teamId,
    List<DashboardResponse>? myList,
    List<DashboardResponse>? sharedList,
    List<DashboardResponse>? templateList,
    bool loading = false,
  }) {
    final router = GoRouter(
      initialLocation: '/logger/dashboards',
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
            child: Scaffold(body: LogDashboardsPage()),
          ),
        ),
        GoRoute(
          path: '/logger/dashboards/:id',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: Center(child: Text('Dashboard Detail')),
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
        loggerMyDashboardsProvider.overrideWith((ref) {
          if (loading) {
            return Completer<List<DashboardResponse>>().future;
          }
          return Future.value(myList ?? dashboards);
        }),
        loggerSharedDashboardsProvider.overrideWith((ref) {
          if (loading) {
            return Completer<List<DashboardResponse>>().future;
          }
          return Future.value(sharedList ?? sharedDashboards);
        }),
        loggerDashboardTemplatesProvider.overrideWith((ref) {
          if (loading) {
            return Completer<List<DashboardResponse>>().future;
          }
          return Future.value(templateList ?? templates);
        }),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('LogDashboardsPage', () {
    testWidgets('renders toolbar and sidebar', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Dashboards'), findsAtLeastNWidgets(1));
      expect(find.text('LOGGER'), findsOneWidget);
    });

    testWidgets('shows three tabs', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('My Dashboards'), findsOneWidget);
      // 'Shared' appears as tab text and as an info chip on shared dashboards.
      expect(find.text('Shared'), findsAtLeastNWidgets(1));
      expect(find.text('Templates'), findsOneWidget);
    });

    testWidgets('shows my dashboards list', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Error Overview'), findsOneWidget);
      expect(find.text('Performance Metrics'), findsOneWidget);
    });

    testWidgets('switches to shared dashboards tab', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Tap the 'Shared' tab specifically (not the info chip).
      await tester.tap(find.descendant(
        of: find.byType(TabBar),
        matching: find.text('Shared'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Team Status Board'), findsOneWidget);
    });

    testWidgets('switches to templates tab', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Templates'));
      await tester.pumpAndSettle();

      expect(find.text('Default Template'), findsOneWidget);
    });

    testWidgets('shows create button', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('New Dashboard'), findsOneWidget);
    });

    testWidgets('shows from template button', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('From Template'), findsOneWidget);
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
