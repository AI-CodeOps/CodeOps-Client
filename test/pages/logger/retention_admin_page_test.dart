// Widget tests for RetentionAdminPage.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:codeops/models/logger_enums.dart';
import 'package:codeops/models/logger_models.dart';
import 'package:codeops/pages/logger/retention_admin_page.dart';
import 'package:codeops/providers/logger_providers.dart';
import 'package:codeops/providers/team_providers.dart'
    show selectedTeamIdProvider;

void main() {
  const teamId = 'team-1';

  final now = DateTime.utc(2026, 1, 15, 10, 0);

  final policies = [
    RetentionPolicyResponse(
      id: 'p-1',
      name: 'Purge old debug logs',
      sourceName: 'api-gateway',
      retentionDays: 30,
      action: RetentionAction.purge,
      isActive: true,
      teamId: teamId,
      createdBy: 'user-1',
      lastExecutedAt: now.subtract(const Duration(hours: 2)),
      createdAt: now.subtract(const Duration(days: 30)),
    ),
    RetentionPolicyResponse(
      id: 'p-2',
      name: 'Archive production logs',
      retentionDays: 90,
      action: RetentionAction.archive,
      archiveDestination: 's3://logs-archive',
      isActive: false,
      teamId: teamId,
      createdBy: 'user-1',
      createdAt: now.subtract(const Duration(days: 60)),
    ),
  ];

  final storage = StorageUsageResponse(
    totalLogEntries: 150000,
    totalMetricDataPoints: 50000,
    totalTraceSpans: 25000,
    logEntriesByService: {'api-gateway': 80000, 'auth-service': 70000},
    logEntriesByLevel: {'INFO': 100000, 'ERROR': 30000, 'WARN': 20000},
    activeRetentionPolicies: 1,
    oldestLogEntry: now.subtract(const Duration(days: 90)),
    newestLogEntry: now,
  );

  final baselines = [
    AnomalyBaselineResponse(
      id: 'b-1',
      serviceName: 'api-gateway',
      metricName: 'cpu_usage',
      baselineValue: 45.0,
      standardDeviation: 10.0,
      sampleCount: 1000,
      windowStartTime: now.subtract(const Duration(hours: 24)),
      windowEndTime: now,
      deviationThreshold: 2.0,
      isActive: true,
      teamId: teamId,
    ),
  ];

  Widget createWidget({
    String? selectedTeamId = teamId,
    List<RetentionPolicyResponse>? policyList,
    StorageUsageResponse? storageData,
    List<AnomalyBaselineResponse>? baselineList,
    bool loading = false,
  }) {
    final router = GoRouter(
      initialLocation: '/logger/retention',
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
            child: Scaffold(body: RetentionAdminPage()),
          ),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        selectedTeamIdProvider.overrideWith((ref) => selectedTeamId),
        loggerRetentionPoliciesProvider.overrideWith((ref) {
          if (loading) {
            return Completer<List<RetentionPolicyResponse>>().future;
          }
          return Future.value(policyList ?? policies);
        }),
        loggerStorageUsageProvider.overrideWith((ref) {
          return Future.value(storageData ?? storage);
        }),
        loggerBaselinesProvider.overrideWith((ref) {
          return Future.value(baselineList ?? baselines);
        }),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('RetentionAdminPage', () {
    testWidgets('renders toolbar and sidebar', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Retention & Admin'), findsOneWidget);
      expect(find.text('LOGGER'), findsOneWidget);
    });

    testWidgets('shows retention policies tab', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Retention Policies'), findsOneWidget);
    });

    testWidgets('shows storage tab', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Storage & Ingestion'), findsOneWidget);
    });

    testWidgets('shows policy names in table', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Purge old debug logs'), findsOneWidget);
      expect(find.text('Archive production logs'), findsOneWidget);
    });

    testWidgets('shows create policy button', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Create Policy'), findsOneWidget);
    });

    testWidgets('shows active toggle for policies', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byType(Switch), findsAtLeastNWidgets(1));
    });

    testWidgets('shows execute button for policies', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.play_arrow), findsAtLeastNWidgets(1));
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
