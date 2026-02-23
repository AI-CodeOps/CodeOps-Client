// Tests for TopologyPage.
//
// Verifies loading, error, empty, data states, filter bar, stats panel,
// legend, stats toggle, and empty topology.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/registry_enums.dart';
import 'package:codeops/models/registry_models.dart';
import 'package:codeops/pages/registry/topology_page.dart';
import 'package:codeops/providers/registry_providers.dart';

const _node1 = TopologyNodeResponse(
  serviceId: 'svc-1',
  name: 'CodeOps Server',
  slug: 'codeops-server',
  serviceType: ServiceType.springBootApi,
  status: ServiceStatus.active,
  healthStatus: HealthStatus.up,
  upstreamDependencyCount: 0,
  downstreamDependencyCount: 2,
  solutionIds: ['sol-1'],
  layer: 'application',
);

const _node2 = TopologyNodeResponse(
  serviceId: 'svc-2',
  name: 'PostgreSQL',
  slug: 'postgresql',
  serviceType: ServiceType.databaseService,
  status: ServiceStatus.active,
  healthStatus: HealthStatus.up,
  upstreamDependencyCount: 1,
  downstreamDependencyCount: 0,
  solutionIds: ['sol-1'],
  layer: 'infrastructure',
);

const _testTopology = TopologyResponse(
  teamId: 'team-1',
  nodes: [_node1, _node2],
  edges: [
    DependencyEdgeResponse(
      sourceServiceId: 'svc-1',
      targetServiceId: 'svc-2',
      dependencyType: DependencyType.databaseShared,
      isRequired: true,
    ),
  ],
  solutionGroups: [
    TopologySolutionGroup(
      solutionId: 'sol-1',
      name: 'CodeOps Platform',
      slug: 'codeops-platform',
      status: SolutionStatus.active,
      memberCount: 2,
      serviceIds: ['svc-1', 'svc-2'],
    ),
  ],
  layers: [
    TopologyLayerResponse(
      layer: 'application',
      serviceCount: 1,
      serviceIds: ['svc-1'],
    ),
    TopologyLayerResponse(
      layer: 'infrastructure',
      serviceCount: 1,
      serviceIds: ['svc-2'],
    ),
  ],
);

const _emptyTopology = TopologyResponse(
  teamId: 'team-1',
  nodes: [],
  edges: [],
);

const _testStats = TopologyStatsResponse(
  totalServices: 2,
  totalDependencies: 1,
  totalSolutions: 1,
  servicesWithNoDependencies: 1,
  servicesWithNoConsumers: 1,
  orphanedServices: 0,
  maxDependencyDepth: 1,
);

void _setWideViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1600, 1000);
  tester.view.devicePixelRatio = 1.0;
}

Widget _buildPage({List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: const MaterialApp(
      home: Scaffold(body: TopologyPage()),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TopologyPage', () {
    testWidgets('renders loading state', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _buildPage(
          overrides: [
            registryTopologyProvider.overrideWith(
              (ref) => Completer<TopologyResponse?>().future,
            ),
          ],
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Ecosystem Topology'), findsOneWidget);
    });

    testWidgets('renders error state', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _buildPage(
          overrides: [
            registryTopologyProvider.overrideWith(
              (ref) => throw Exception('Network error'),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Failed to Load Topology'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('renders empty topology state', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _buildPage(
          overrides: [
            registryTopologyProvider
                .overrideWith((ref) async => _emptyTopology),
            registryEcosystemStatsProvider
                .overrideWith((ref) async => _testStats),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No services'), findsOneWidget);
    });

    testWidgets('renders canvas with nodes', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _buildPage(
          overrides: [
            registryTopologyProvider
                .overrideWith((ref) async => _testTopology),
            registryEcosystemStatsProvider
                .overrideWith((ref) async => _testStats),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('CodeOps Server'), findsWidgets);
      expect(find.text('PostgreSQL'), findsWidgets);
    });

    testWidgets('renders filter bar', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _buildPage(
          overrides: [
            registryTopologyProvider
                .overrideWith((ref) async => _testTopology),
            registryEcosystemStatsProvider
                .overrideWith((ref) async => _testStats),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Type:'), findsOneWidget);
      expect(find.text('Health:'), findsOneWidget);
      expect(find.text('Solution:'), findsOneWidget);
      expect(find.text('Search...'), findsOneWidget);
    });

    testWidgets('renders stats panel', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _buildPage(
          overrides: [
            registryTopologyProvider
                .overrideWith((ref) async => _testTopology),
            registryEcosystemStatsProvider
                .overrideWith((ref) async => _testStats),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Topology Stats'), findsOneWidget);
    });

    testWidgets('renders legend', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _buildPage(
          overrides: [
            registryTopologyProvider
                .overrideWith((ref) async => _testTopology),
            registryEcosystemStatsProvider
                .overrideWith((ref) async => _testStats),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Legend'), findsOneWidget);
    });

    testWidgets('stats toggle hides panel', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _buildPage(
          overrides: [
            registryTopologyProvider
                .overrideWith((ref) async => _testTopology),
            registryEcosystemStatsProvider
                .overrideWith((ref) async => _testStats),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Stats visible
      expect(find.text('Topology Stats'), findsOneWidget);

      // Tap stats toggle button
      await tester.tap(find.text('Stats'));
      await tester.pumpAndSettle();

      // Stats hidden
      expect(find.text('Topology Stats'), findsNothing);
    });

    testWidgets('zoom controls are present', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _buildPage(
          overrides: [
            registryTopologyProvider
                .overrideWith((ref) async => _testTopology),
            registryEcosystemStatsProvider
                .overrideWith((ref) async => _testStats),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byTooltip('Zoom in'), findsOneWidget);
      expect(find.byTooltip('Zoom out'), findsOneWidget);
      expect(find.byTooltip('Reset view'), findsOneWidget);
      expect(find.byTooltip('Fit to screen'), findsOneWidget);
    });

    testWidgets('cluster boundary rendered', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _buildPage(
          overrides: [
            registryTopologyProvider
                .overrideWith((ref) async => _testTopology),
            registryEcosystemStatsProvider
                .overrideWith((ref) async => _testStats),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('CodeOps Platform'), findsWidgets);
    });
  });
}
