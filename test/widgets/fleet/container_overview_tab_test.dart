// Widget tests for ContainerOverviewTab.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/fleet_enums.dart';
import 'package:codeops/models/fleet_models.dart';
import 'package:codeops/widgets/fleet/container_overview_tab.dart';

void main() {
  final runningDetail = FleetContainerDetail(
    id: 'c1',
    containerId: 'abc123',
    containerName: 'postgres-a1b2',
    serviceName: 'postgres',
    imageName: 'postgres',
    imageTag: '16',
    status: ContainerStatus.running,
    healthStatus: HealthStatus.healthy,
    restartPolicy: RestartPolicy.always,
    restartCount: 3,
    pid: 12345,
    startedAt: DateTime(2026, 2, 27, 10, 0),
    serviceProfileName: 'Postgres Profile',
    createdAt: DateTime(2026, 2, 27, 9, 0),
    updatedAt: DateTime(2026, 2, 27, 10, 30),
  );

  final stoppedDetail = FleetContainerDetail(
    id: 'c1',
    containerId: 'abc123',
    containerName: 'postgres-a1b2',
    serviceName: 'postgres',
    imageName: 'postgres',
    imageTag: '16',
    status: ContainerStatus.stopped,
    exitCode: 137,
    startedAt: DateTime(2026, 2, 27, 8, 0),
    finishedAt: DateTime(2026, 2, 27, 9, 0),
    createdAt: DateTime(2026, 2, 27, 7, 0),
  );

  void useWideViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Widget wrap({
    FleetContainerDetail? detail,
    VoidCallback? onStop,
    VoidCallback? onRestart,
    VoidCallback? onRemove,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: ContainerOverviewTab(
          detail: detail ?? runningDetail,
          callbacks: (
            onStop: onStop ?? () {},
            onRestart: onRestart ?? () {},
            onRemove: onRemove ?? () {},
          ),
        ),
      ),
    );
  }

  group('ContainerOverviewTab', () {
    testWidgets('renders container info card', (tester) async {
      useWideViewport(tester);
      await tester.pumpWidget(wrap());

      expect(find.text('Container Info'), findsOneWidget);
      expect(find.text('postgres-a1b2'), findsOneWidget);
      expect(find.text('postgres:16'), findsOneWidget);
      expect(find.text('abc123'), findsOneWidget);
    });

    testWidgets('renders service name', (tester) async {
      useWideViewport(tester);
      await tester.pumpWidget(wrap());

      expect(find.text('postgres'), findsOneWidget);
    });

    testWidgets('renders service profile name', (tester) async {
      useWideViewport(tester);
      await tester.pumpWidget(wrap());

      expect(find.text('Postgres Profile'), findsOneWidget);
    });

    testWidgets('shows stop button for running container', (tester) async {
      useWideViewport(tester);
      await tester.pumpWidget(wrap());

      expect(find.text('Stop'), findsOneWidget);
      expect(find.text('Restart'), findsOneWidget);
      expect(find.text('Remove'), findsOneWidget);
    });

    testWidgets('hides stop button for stopped container', (tester) async {
      useWideViewport(tester);
      await tester.pumpWidget(wrap(detail: stoppedDetail));

      expect(find.text('Stop'), findsNothing);
      expect(find.text('Restart'), findsOneWidget);
      expect(find.text('Remove'), findsOneWidget);
    });

    testWidgets('shows exit code for stopped container', (tester) async {
      useWideViewport(tester);
      await tester.pumpWidget(wrap(detail: stoppedDetail));

      expect(find.text('Exit Code'), findsOneWidget);
      expect(find.text('137'), findsOneWidget);
    });

    testWidgets('shows PID for running container', (tester) async {
      useWideViewport(tester);
      await tester.pumpWidget(wrap());

      expect(find.text('PID'), findsOneWidget);
      expect(find.text('12345'), findsOneWidget);
    });

    testWidgets('calls onStop when stop tapped', (tester) async {
      useWideViewport(tester);
      var called = false;
      await tester.pumpWidget(wrap(onStop: () => called = true));

      await tester.tap(find.text('Stop'));
      expect(called, isTrue);
    });

    testWidgets('calls onRestart when restart tapped', (tester) async {
      useWideViewport(tester);
      var called = false;
      await tester.pumpWidget(wrap(onRestart: () => called = true));

      await tester.tap(find.text('Restart'));
      expect(called, isTrue);
    });

    testWidgets('calls onRemove when remove tapped', (tester) async {
      useWideViewport(tester);
      var called = false;
      await tester.pumpWidget(wrap(onRemove: () => called = true));

      await tester.tap(find.text('Remove'));
      expect(called, isTrue);
    });
  });
}
