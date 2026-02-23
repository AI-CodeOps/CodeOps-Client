// Tests for TopologyFilterBar widget.
//
// Verifies type dropdown, health dropdown, solution dropdown,
// search field, and reset button rendering.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/registry_enums.dart';
import 'package:codeops/models/registry_models.dart';
import 'package:codeops/widgets/registry/topology_filter_bar.dart';

const _testGroups = [
  TopologySolutionGroup(
    solutionId: 'sol-1',
    name: 'CodeOps Platform',
    slug: 'codeops-platform',
    status: SolutionStatus.active,
    memberCount: 5,
    serviceIds: ['svc-1', 'svc-2'],
  ),
  TopologySolutionGroup(
    solutionId: 'sol-2',
    name: 'Analytics Suite',
    slug: 'analytics-suite',
    status: SolutionStatus.inDevelopment,
    memberCount: 3,
    serviceIds: ['svc-3'],
  ),
];

void _setWideViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1600, 900);
  tester.view.devicePixelRatio = 1.0;
}

Widget _buildFilterBar({
  List<TopologySolutionGroup> solutionGroups = _testGroups,
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      home: Scaffold(
        body: TopologyFilterBar(solutionGroups: solutionGroups),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TopologyFilterBar', () {
    testWidgets('renders type dropdown', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_buildFilterBar());
      await tester.pumpAndSettle();

      expect(find.text('Type:'), findsOneWidget);
      // "All" is displayed for each dropdown
      expect(find.text('All'), findsWidgets);
    });

    testWidgets('renders health dropdown', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_buildFilterBar());
      await tester.pumpAndSettle();

      expect(find.text('Health:'), findsOneWidget);
    });

    testWidgets('renders solution dropdown', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_buildFilterBar());
      await tester.pumpAndSettle();

      expect(find.text('Solution:'), findsOneWidget);
    });

    testWidgets('renders search field', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_buildFilterBar());
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search...'), findsOneWidget);
    });

    testWidgets('reset button present', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_buildFilterBar());
      await tester.pumpAndSettle();

      expect(find.byTooltip('Reset filters'), findsOneWidget);
    });
  });
}
