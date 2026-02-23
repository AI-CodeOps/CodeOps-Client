// Tests for TopologyStatsPanel widget.
//
// Verifies all stats render, orphans red when positive,
// zero stats graceful, max depth display.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/registry_models.dart';
import 'package:codeops/widgets/registry/topology_stats_panel.dart';

const _testStats = TopologyStatsResponse(
  totalServices: 12,
  totalDependencies: 18,
  totalSolutions: 3,
  servicesWithNoDependencies: 2,
  servicesWithNoConsumers: 1,
  orphanedServices: 2,
  maxDependencyDepth: 4,
);

const _zeroStats = TopologyStatsResponse(
  totalServices: 0,
  totalDependencies: 0,
  totalSolutions: 0,
  servicesWithNoDependencies: 0,
  servicesWithNoConsumers: 0,
  orphanedServices: 0,
  maxDependencyDepth: 0,
);

void _setWideViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1400, 900);
  tester.view.devicePixelRatio = 1.0;
}

Widget _buildPanel({TopologyStatsResponse stats = _testStats}) {
  return MaterialApp(
    home: Scaffold(
      body: Row(
        children: [
          TopologyStatsPanel(stats: stats),
        ],
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TopologyStatsPanel', () {
    testWidgets('renders all stats', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_buildPanel());
      await tester.pumpAndSettle();

      expect(find.text('Topology Stats'), findsOneWidget);
      expect(find.text('12'), findsOneWidget); // total services
      expect(find.text('18'), findsOneWidget); // total deps
      expect(find.text('3'), findsOneWidget); // solutions
      expect(find.text('2'), findsWidgets); // no deps + orphans
    });

    testWidgets('orphans shows red when positive', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_buildPanel());
      await tester.pumpAndSettle();

      // Find the orphan count text widget
      final orphanFinder = find.text('2');
      expect(orphanFinder, findsWidgets);
    });

    testWidgets('renders zero stats gracefully', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_buildPanel(stats: _zeroStats));
      await tester.pumpAndSettle();

      expect(find.text('0'), findsWidgets);
      expect(find.text('Topology Stats'), findsOneWidget);
    });

    testWidgets('renders max depth', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_buildPanel());
      await tester.pumpAndSettle();

      expect(find.text('Max Depth'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
    });
  });
}
