// Widget tests for ContainerHealthTab.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/fleet_enums.dart';
import 'package:codeops/models/fleet_models.dart';
import 'package:codeops/widgets/fleet/container_health_tab.dart';

void main() {
  final checks = [
    FleetContainerHealthCheck(
      id: 'h1',
      status: HealthStatus.healthy,
      output: 'pg_isready: accepting connections',
      exitCode: 0,
      durationMs: 45,
      containerId: 'c1',
      createdAt: DateTime(2026, 2, 27, 10, 30),
    ),
    FleetContainerHealthCheck(
      id: 'h2',
      status: HealthStatus.unhealthy,
      output: 'pg_isready: no response',
      exitCode: 1,
      durationMs: 5000,
      containerId: 'c1',
      createdAt: DateTime(2026, 2, 27, 10, 25),
    ),
  ];

  void useWideViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Widget wrap({
    List<FleetContainerHealthCheck>? data,
    VoidCallback? onRunCheck,
    VoidCallback? onRefresh,
    bool isCheckRunning = false,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: ContainerHealthTab(
          checks: data ?? checks,
          onRunCheck: onRunCheck ?? () {},
          onRefresh: onRefresh ?? () {},
          isCheckRunning: isCheckRunning,
        ),
      ),
    );
  }

  group('ContainerHealthTab', () {
    testWidgets('renders health check history', (tester) async {
      useWideViewport(tester);
      await tester.pumpWidget(wrap());

      expect(find.text('Healthy'), findsOneWidget);
      expect(find.text('Unhealthy'), findsOneWidget);
      expect(find.text('pg_isready: accepting connections'), findsOneWidget);
      expect(find.text('pg_isready: no response'), findsOneWidget);
    });

    testWidgets('renders exit codes', (tester) async {
      useWideViewport(tester);
      await tester.pumpWidget(wrap());

      expect(find.text('0'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('renders durations', (tester) async {
      useWideViewport(tester);
      await tester.pumpWidget(wrap());

      expect(find.text('45ms'), findsOneWidget);
      expect(find.text('5000ms'), findsOneWidget);
    });

    testWidgets('renders column headers', (tester) async {
      useWideViewport(tester);
      await tester.pumpWidget(wrap());

      expect(find.text('Status'), findsOneWidget);
      expect(find.text('Output'), findsOneWidget);
      expect(find.text('Exit Code'), findsOneWidget);
      expect(find.text('Duration'), findsOneWidget);
      expect(find.text('Timestamp'), findsOneWidget);
    });

    testWidgets('renders Run Check button', (tester) async {
      useWideViewport(tester);
      await tester.pumpWidget(wrap());

      expect(find.text('Run Check'), findsOneWidget);
    });

    testWidgets('calls onRunCheck when tapped', (tester) async {
      useWideViewport(tester);
      var called = false;
      await tester.pumpWidget(wrap(onRunCheck: () => called = true));

      await tester.tap(find.text('Run Check'));
      expect(called, isTrue);
    });

    testWidgets('disables Run Check when check is running', (tester) async {
      useWideViewport(tester);
      await tester.pumpWidget(wrap(isCheckRunning: true));

      // Should show progress indicator instead of play icon
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty state when no checks', (tester) async {
      useWideViewport(tester);
      await tester.pumpWidget(wrap(data: []));

      expect(find.text('No health checks recorded'), findsOneWidget);
    });

    testWidgets('renders refresh button', (tester) async {
      useWideViewport(tester);
      await tester.pumpWidget(wrap());

      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('calls onRefresh when tapped', (tester) async {
      useWideViewport(tester);
      var called = false;
      await tester.pumpWidget(wrap(onRefresh: () => called = true));

      await tester.tap(find.byIcon(Icons.refresh));
      expect(called, isTrue);
    });
  });
}
