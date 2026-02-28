// Widget tests for ContainerDetailPage.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/fleet_enums.dart';
import 'package:codeops/models/fleet_models.dart';
import 'package:codeops/pages/fleet/container_detail_page.dart';
import 'package:codeops/providers/fleet_providers.dart' hide selectedTeamIdProvider;
import 'package:codeops/providers/team_providers.dart' show selectedTeamIdProvider;

void main() {
  const teamId = 'team-1';
  const containerId = 'c1';

  final detail = FleetContainerDetail(
    id: containerId,
    containerId: 'abc123def456',
    containerName: 'postgres-a1b2',
    serviceName: 'postgres',
    imageName: 'postgres',
    imageTag: '16',
    status: ContainerStatus.running,
    healthStatus: HealthStatus.healthy,
    restartPolicy: RestartPolicy.always,
    restartCount: 3,
    exitCode: null,
    cpuPercent: 12.5,
    memoryBytes: 256 * 1024 * 1024,
    memoryLimitBytes: 512 * 1024 * 1024,
    pid: 12345,
    startedAt: DateTime(2026, 2, 27, 10, 0),
    finishedAt: null,
    serviceProfileId: 'sp-1',
    serviceProfileName: 'Postgres Profile',
    teamId: teamId,
    createdAt: DateTime(2026, 2, 27, 9, 0),
    updatedAt: DateTime(2026, 2, 27, 10, 30),
  );

  final stoppedDetail = FleetContainerDetail(
    id: containerId,
    containerId: 'abc123def456',
    containerName: 'postgres-a1b2',
    serviceName: 'postgres',
    imageName: 'postgres',
    imageTag: '16',
    status: ContainerStatus.stopped,
    healthStatus: HealthStatus.none,
    restartPolicy: RestartPolicy.no,
    restartCount: 0,
    exitCode: 137,
    startedAt: DateTime(2026, 2, 27, 8, 0),
    finishedAt: DateTime(2026, 2, 27, 9, 0),
    teamId: teamId,
    createdAt: DateTime(2026, 2, 27, 7, 0),
  );

  final logs = [
    FleetContainerLog(
      id: 'l1',
      stream: 'stdout',
      content: 'database system is ready to accept connections',
      timestamp: DateTime(2026, 2, 27, 10, 0, 1),
      containerId: containerId,
    ),
    FleetContainerLog(
      id: 'l2',
      stream: 'stderr',
      content: 'FATAL: password authentication failed',
      timestamp: DateTime(2026, 2, 27, 10, 0, 2),
      containerId: containerId,
    ),
  ];

  final stats = FleetContainerStats(
    containerId: containerId,
    containerName: 'postgres-a1b2',
    cpuPercent: 12.5,
    memoryUsageBytes: 256 * 1024 * 1024,
    memoryLimitBytes: 512 * 1024 * 1024,
    networkRxBytes: 1024 * 1024,
    networkTxBytes: 512 * 1024,
    blockReadBytes: 2 * 1024 * 1024,
    blockWriteBytes: 1024 * 1024,
    pids: 8,
    timestamp: DateTime(2026, 2, 27, 10, 30),
  );

  final healthChecks = [
    FleetContainerHealthCheck(
      id: 'h1',
      status: HealthStatus.healthy,
      output: 'pg_isready: accepting connections',
      exitCode: 0,
      durationMs: 45,
      containerId: containerId,
      createdAt: DateTime(2026, 2, 27, 10, 30),
    ),
    FleetContainerHealthCheck(
      id: 'h2',
      status: HealthStatus.unhealthy,
      output: 'pg_isready: no response',
      exitCode: 1,
      durationMs: 5000,
      containerId: containerId,
      createdAt: DateTime(2026, 2, 27, 10, 25),
    ),
  ];

  /// Sets a wide viewport to avoid overflow in the desktop-oriented layout.
  void useWideViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Widget createWidget({
    String? selectedTeamId = teamId,
    FleetContainerDetail? containerDetail,
    bool loadingDetail = false,
    bool errorDetail = false,
    List<FleetContainerLog>? containerLogs,
    FleetContainerStats? containerStats,
    List<FleetContainerHealthCheck>? containerHealthChecks,
  }) {
    return ProviderScope(
      overrides: [
        selectedTeamIdProvider.overrideWith((ref) => selectedTeamId),
        fleetContainerDetailProvider.overrideWith(
          (ref, params) {
            if (loadingDetail) {
              return Completer<FleetContainerDetail>().future;
            }
            if (errorDetail) {
              return Future<FleetContainerDetail>.error('Server error');
            }
            return Future.value(containerDetail ?? detail);
          },
        ),
        fleetContainerLogsProvider.overrideWith(
          (ref, params) =>
              Future.value(containerLogs ?? logs),
        ),
        fleetContainerStatsProvider.overrideWith(
          (ref, params) =>
              Future.value(containerStats ?? stats),
        ),
        fleetHealthCheckHistoryProvider.overrideWith(
          (ref, cid) =>
              Future.value(containerHealthChecks ?? healthChecks),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: ContainerDetailPage(containerId: containerId),
        ),
      ),
    );
  }

  group('ContainerDetailPage', () {
    testWidgets('renders container name in header', (tester) async {
      useWideViewport(tester);
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Header + overview tab both show container name
      expect(find.text('postgres-a1b2'), findsAtLeastNWidgets(1));
    });

    testWidgets('renders image:tag in header', (tester) async {
      useWideViewport(tester);
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Header + overview tab both show image:tag
      expect(find.text('postgres:16'), findsAtLeastNWidgets(1));
    });

    testWidgets('renders all 5 tab labels', (tester) async {
      useWideViewport(tester);
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byWidgetPredicate((w) => w is Tab && w.text == 'Overview'),
          findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is Tab && w.text == 'Logs'),
          findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is Tab && w.text == 'Stats'),
          findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is Tab && w.text == 'Health'),
          findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is Tab && w.text == 'Exec'),
          findsOneWidget);
    });

    testWidgets('renders loading state', (tester) async {
      await tester.pumpWidget(createWidget(loadingDetail: true));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders error state with retry', (tester) async {
      await tester.pumpWidget(createWidget(errorDetail: true));
      await tester.pumpAndSettle();

      expect(find.text('Something Went Wrong'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('renders no team selected state', (tester) async {
      await tester.pumpWidget(createWidget(selectedTeamId: null));
      await tester.pumpAndSettle();

      expect(find.text('No team selected'), findsOneWidget);
    });

    // ───── Overview Tab ─────

    testWidgets('overview tab shows container info', (tester) async {
      useWideViewport(tester);
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Container Info'), findsOneWidget);
      expect(find.text('postgres'), findsOneWidget); // service name
      expect(find.text('abc123def456'), findsOneWidget); // container ID
    });

    testWidgets('overview tab shows stop button for running container',
        (tester) async {
      useWideViewport(tester);
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Stop'), findsOneWidget);
      expect(find.text('Restart'), findsOneWidget);
      expect(find.text('Remove'), findsOneWidget);
    });

    testWidgets('overview tab hides stop button for stopped container',
        (tester) async {
      useWideViewport(tester);
      await tester.pumpWidget(createWidget(containerDetail: stoppedDetail));
      await tester.pumpAndSettle();

      expect(find.text('Stop'), findsNothing);
      expect(find.text('Restart'), findsOneWidget);
      expect(find.text('Remove'), findsOneWidget);
    });

    testWidgets('overview tab shows exit code for stopped container',
        (tester) async {
      useWideViewport(tester);
      await tester.pumpWidget(createWidget(containerDetail: stoppedDetail));
      await tester.pumpAndSettle();

      expect(find.text('Exit Code'), findsOneWidget);
      expect(find.text('137'), findsOneWidget);
    });

    // ───── Logs Tab ─────

    testWidgets('logs tab renders log entries', (tester) async {
      useWideViewport(tester);
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Switch to Logs tab
      await tester.tap(find.text('Logs'));
      await tester.pumpAndSettle();

      expect(find.text('database system is ready to accept connections'),
          findsOneWidget);
      expect(find.text('FATAL: password authentication failed'),
          findsOneWidget);
    });

    testWidgets('logs tab shows empty state when no logs', (tester) async {
      useWideViewport(tester);
      await tester.pumpWidget(createWidget(containerLogs: []));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Logs'));
      await tester.pumpAndSettle();

      expect(find.text('No logs available'), findsOneWidget);
    });

    // ───── Stats Tab ─────

    testWidgets('stats tab renders resource gauges', (tester) async {
      useWideViewport(tester);
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Stats'));
      await tester.pumpAndSettle();

      expect(find.text('Resource Usage'), findsOneWidget);
      expect(find.text('12.5%'), findsOneWidget);
      expect(find.text('I/O'), findsOneWidget);
    });

    // ───── Health Tab ─────

    testWidgets('health tab renders health check history', (tester) async {
      useWideViewport(tester);
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byWidgetPredicate(
          (w) => w is Tab && w.text == 'Health'));
      await tester.pumpAndSettle();

      expect(find.text('Run Check'), findsOneWidget);
      expect(find.text('Healthy'), findsOneWidget);
      expect(find.text('Unhealthy'), findsOneWidget);
      expect(find.text('pg_isready: accepting connections'), findsOneWidget);
    });

    testWidgets('health tab shows empty state when no checks', (tester) async {
      useWideViewport(tester);
      await tester.pumpWidget(createWidget(containerHealthChecks: []));
      await tester.pumpAndSettle();

      await tester.tap(find.byWidgetPredicate(
          (w) => w is Tab && w.text == 'Health'));
      await tester.pumpAndSettle();

      expect(find.text('No health checks recorded'), findsOneWidget);
    });

    // ───── Exec Tab ─────

    testWidgets('exec tab shows command input when running', (tester) async {
      useWideViewport(tester);
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Exec'));
      await tester.pumpAndSettle();

      expect(find.text('\$'), findsOneWidget);
      expect(find.text('Enter a command below to execute in the container'),
          findsOneWidget);
    });

    testWidgets('exec tab shows not running message for stopped container',
        (tester) async {
      useWideViewport(tester);
      await tester.pumpWidget(createWidget(containerDetail: stoppedDetail));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Exec'));
      await tester.pumpAndSettle();

      expect(find.text('Container is not running'), findsOneWidget);
    });
  });
}
