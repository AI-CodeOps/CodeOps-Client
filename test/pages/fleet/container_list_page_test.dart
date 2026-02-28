// Widget tests for ContainerListPage.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/fleet_enums.dart';
import 'package:codeops/models/fleet_models.dart';
import 'package:codeops/pages/fleet/container_list_page.dart';
import 'package:codeops/providers/fleet_providers.dart' hide selectedTeamIdProvider;
import 'package:codeops/providers/team_providers.dart' show selectedTeamIdProvider;
import 'package:codeops/widgets/fleet/container_list_toolbar.dart';

void main() {
  const teamId = 'team-1';

  final containers = [
    FleetContainerInstance(
      id: 'c1',
      containerId: 'abc123',
      containerName: 'postgres-a1b2',
      serviceName: 'postgres',
      imageName: 'postgres',
      imageTag: '16',
      status: ContainerStatus.running,
      healthStatus: HealthStatus.healthy,
      cpuPercent: 12.0,
      memoryBytes: 256 * 1024 * 1024,
      startedAt: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
    FleetContainerInstance(
      id: 'c2',
      containerId: 'def456',
      containerName: 'redis-c3d4',
      serviceName: 'redis',
      imageName: 'redis',
      imageTag: '7',
      status: ContainerStatus.running,
      cpuPercent: 2.0,
      memoryBytes: 64 * 1024 * 1024,
      startedAt: DateTime.now().subtract(const Duration(minutes: 10)),
    ),
    FleetContainerInstance(
      id: 'c3',
      containerId: 'ghi789',
      containerName: 'api-e5f6',
      serviceName: 'api',
      imageName: 'eclipse-temurin',
      imageTag: '21',
      status: ContainerStatus.exited,
      startedAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    FleetContainerInstance(
      id: 'c4',
      containerId: 'jkl012',
      containerName: 'nginx-g7h8',
      serviceName: 'nginx',
      imageName: 'nginx',
      imageTag: 'latest',
      status: ContainerStatus.stopped,
      startedAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    FleetContainerInstance(
      id: 'c5',
      containerId: 'mno345',
      containerName: 'kafka-i9j0',
      serviceName: 'kafka',
      imageName: 'confluentinc/cp-kafka',
      imageTag: '7.5',
      status: ContainerStatus.running,
      healthStatus: HealthStatus.unhealthy,
      cpuPercent: 45.0,
      memoryBytes: 512 * 1024 * 1024,
      startedAt: DateTime.now().subtract(const Duration(minutes: 30)),
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
    List<FleetContainerInstance>? containerList,
    bool loading = false,
    bool error = false,
  }) {
    return ProviderScope(
      overrides: [
        selectedTeamIdProvider.overrideWith((ref) => selectedTeamId),
        fleetContainersProvider.overrideWith(
          (ref, tid) {
            if (loading) {
              return Completer<List<FleetContainerInstance>>().future;
            }
            if (error) {
              return Future<List<FleetContainerInstance>>.error('Server error');
            }
            return Future.value(containerList ?? containers);
          },
        ),
      ],
      child: const MaterialApp(home: Scaffold(body: ContainerListPage())),
    );
  }

  group('ContainerListPage', () {
    testWidgets('renders header with container count', (tester) async {
      useWideViewport(tester);
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Containers'), findsOneWidget);
      expect(find.text('(5)'), findsOneWidget);
    });

    testWidgets('renders all container names in the table', (tester) async {
      useWideViewport(tester);
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('postgres-a1b2'), findsOneWidget);
      expect(find.text('redis-c3d4'), findsOneWidget);
      expect(find.text('api-e5f6'), findsOneWidget);
      expect(find.text('nginx-g7h8'), findsOneWidget);
      expect(find.text('kafka-i9j0'), findsOneWidget);
    });

    testWidgets('renders image names with tags', (tester) async {
      useWideViewport(tester);
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('postgres:16'), findsOneWidget);
      expect(find.text('redis:7'), findsOneWidget);
      expect(find.text('eclipse-temurin:21'), findsOneWidget);
    });

    testWidgets('renders status badges', (tester) async {
      useWideViewport(tester);
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // 3 running containers
      expect(find.text('Running'), findsNWidgets(3));
      expect(find.text('Exited'), findsOneWidget);
      expect(find.text('Stopped'), findsOneWidget);
    });

    testWidgets('renders loading state', (tester) async {
      await tester.pumpWidget(createWidget(loading: true));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders error state with retry', (tester) async {
      await tester.pumpWidget(createWidget(error: true));
      await tester.pumpAndSettle();

      expect(find.text('Something Went Wrong'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('renders empty state when no team selected', (tester) async {
      await tester.pumpWidget(createWidget(selectedTeamId: null));
      await tester.pumpAndSettle();

      expect(find.text('No team selected'), findsOneWidget);
    });

    testWidgets('renders empty state when no containers match', (tester) async {
      await tester.pumpWidget(createWidget(containerList: []));
      await tester.pumpAndSettle();

      expect(find.text('No containers found'), findsOneWidget);
    });

    testWidgets('renders toolbar with filter dropdown and search',
        (tester) async {
      useWideViewport(tester);
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Toolbar should exist
      expect(find.byType(ContainerListToolbar), findsOneWidget);
      // Default filter is "All"
      expect(find.text('All'), findsOneWidget);
      // Search bar should be present
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('renders column headers', (tester) async {
      useWideViewport(tester);
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Image'), findsOneWidget);
      expect(find.text('Status'), findsOneWidget);
      expect(find.text('CPU'), findsOneWidget);
      expect(find.text('Memory'), findsOneWidget);
      expect(find.text('Age'), findsOneWidget);
    });

    testWidgets('renders CPU percentages for running containers',
        (tester) async {
      useWideViewport(tester);
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('12.0%'), findsOneWidget);
      expect(find.text('2.0%'), findsOneWidget);
      expect(find.text('45.0%'), findsOneWidget);
    });

    testWidgets('renders checkboxes for selection', (tester) async {
      useWideViewport(tester);
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // 5 container rows + 1 header = 6 checkboxes
      expect(find.byType(Checkbox), findsNWidgets(6));
    });

    testWidgets('shows bulk actions when checkbox is selected',
        (tester) async {
      useWideViewport(tester);
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Initially no bulk actions visible
      expect(find.text('Start'), findsNothing);

      // Tap first container checkbox (skip header checkbox at index 0)
      final checkboxes = find.byType(Checkbox);
      await tester.tap(checkboxes.at(1));
      await tester.pumpAndSettle();

      // Bulk actions should appear
      expect(find.text('1 selected'), findsOneWidget);
      expect(find.text('Start'), findsOneWidget);
    });

    testWidgets('filter shows only running containers', (tester) async {
      useWideViewport(tester);
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Open the dropdown
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();

      // Select "Running"
      await tester.tap(find.text('Running').last);
      await tester.pumpAndSettle();

      // Should show 3 running containers
      expect(find.text('(3)'), findsOneWidget);
      expect(find.text('postgres-a1b2'), findsOneWidget);
      expect(find.text('redis-c3d4'), findsOneWidget);
      expect(find.text('kafka-i9j0'), findsOneWidget);
      // Stopped/exited should not be visible
      expect(find.text('api-e5f6'), findsNothing);
      expect(find.text('nginx-g7h8'), findsNothing);
    });

    testWidgets('filter shows only stopped containers', (tester) async {
      useWideViewport(tester);
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Open the dropdown
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();

      // Select "Stopped"
      await tester.tap(find.text('Stopped').last);
      await tester.pumpAndSettle();

      // Should show 2 containers (exited + stopped)
      expect(find.text('(2)'), findsOneWidget);
      expect(find.text('api-e5f6'), findsOneWidget);
      expect(find.text('nginx-g7h8'), findsOneWidget);
    });

    testWidgets('renders per-row action buttons', (tester) async {
      useWideViewport(tester);
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Running containers get Stop button, stopped get Start
      // All get Restart, Remove, View Logs
      expect(find.byIcon(Icons.stop), findsNWidgets(3)); // 3 running
      expect(find.byIcon(Icons.play_arrow), findsNWidgets(2)); // 2 stopped
      expect(find.byIcon(Icons.restart_alt), findsNWidgets(5)); // all 5
      expect(find.byIcon(Icons.delete_outline), findsNWidgets(5)); // all 5
      expect(find.byIcon(Icons.article_outlined), findsNWidgets(5)); // all 5
    });

    testWidgets('renders refresh button in toolbar', (tester) async {
      useWideViewport(tester);
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });
  });
}
