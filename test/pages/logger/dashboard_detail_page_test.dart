// Widget tests for DashboardDetailPage.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:codeops/models/logger_enums.dart';
import 'package:codeops/models/logger_models.dart';
import 'package:codeops/pages/logger/dashboard_detail_page.dart';
import 'package:codeops/providers/logger_providers.dart';
import 'package:codeops/providers/team_providers.dart'
    show selectedTeamIdProvider;

void main() {
  const teamId = 'team-1';
  const dashboardId = 'dash-1';

  final widgets = [
    DashboardWidgetResponse(
      id: 'w-1',
      dashboardId: dashboardId,
      title: 'Error Count',
      widgetType: WidgetType.counter,
      configJson: '{"value":42,"label":"Total Errors"}',
      gridX: 0,
      gridY: 0,
      gridWidth: 4,
      gridHeight: 2,
      sortOrder: 0,
    ),
    DashboardWidgetResponse(
      id: 'w-2',
      dashboardId: dashboardId,
      title: 'Error Trend',
      widgetType: WidgetType.timeSeriesChart,
      configJson: '{"data":[10,20,15,30,25]}',
      gridX: 4,
      gridY: 0,
      gridWidth: 4,
      gridHeight: 2,
      sortOrder: 1,
    ),
    DashboardWidgetResponse(
      id: 'w-3',
      dashboardId: dashboardId,
      title: 'Level Distribution',
      widgetType: WidgetType.pieChart,
      configJson: '{"data":[40,30,20,10]}',
      gridX: 8,
      gridY: 0,
      gridWidth: 4,
      gridHeight: 2,
      sortOrder: 2,
    ),
  ];

  final dashboard = DashboardResponse(
    id: dashboardId,
    name: 'Error Overview',
    description: 'Tracks errors across services',
    teamId: teamId,
    createdBy: 'user-1',
    isShared: false,
    isTemplate: false,
    refreshIntervalSeconds: 30,
    widgets: widgets,
    createdAt: DateTime.utc(2026, 1, 10),
  );

  Widget createTestWidget({
    DashboardResponse? dashData,
    bool loading = false,
  }) {
    final router = GoRouter(
      initialLocation: '/logger/dashboards/$dashboardId',
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
            child: Center(child: Text('Dashboards List')),
          ),
        ),
        GoRoute(
          path: '/logger/dashboards/:id',
          pageBuilder: (context, state) => NoTransitionPage(
            child: Scaffold(
              body: DashboardDetailPage(
                dashboardId: state.pathParameters['id']!,
              ),
            ),
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
        selectedTeamIdProvider.overrideWith((ref) => teamId),
        loggerDashboardDetailProvider(dashboardId).overrideWith((ref) {
          if (loading) {
            return Completer<DashboardResponse>().future;
          }
          return Future.value(dashData ?? dashboard);
        }),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('DashboardDetailPage', () {
    testWidgets('renders toolbar with dashboard name', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Error Overview'), findsOneWidget);
    });

    testWidgets('shows widget titles', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Error Count'), findsOneWidget);
      expect(find.text('Error Trend'), findsOneWidget);
      expect(find.text('Level Distribution'), findsOneWidget);
    });

    testWidgets('shows toolbar buttons', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Edit Layout'), findsOneWidget);
      expect(find.text('Add Widget'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('shows add widget dialog', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add Widget'));
      await tester.pumpAndSettle();

      expect(find.text('Add Widget'), findsAtLeastNWidgets(1));
      expect(find.text('Widget Title'), findsOneWidget);
    });

    testWidgets('toggles edit mode', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Edit Layout'), findsOneWidget);

      await tester.tap(find.text('Edit Layout'));
      await tester.pumpAndSettle();

      expect(find.text('Lock Layout'), findsOneWidget);
    });

    testWidgets('shows save button', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('shows time range dropdown', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Time Range: '), findsOneWidget);
      expect(find.text('1h'), findsOneWidget);
    });

    testWidgets('shows auto-refresh dropdown', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Auto-Refresh: '), findsOneWidget);
      expect(find.text('30s'), findsOneWidget);
    });
  });
}
