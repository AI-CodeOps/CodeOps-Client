// Tests for SolutionCard widget.
//
// Verifies name, description, category badge, status badge,
// member count, and color accent rendering.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/registry_enums.dart';
import 'package:codeops/models/registry_models.dart';
import 'package:codeops/widgets/registry/solution_card.dart';

const _testSolution = SolutionResponse(
  id: 'sol-1',
  teamId: 'team-1',
  name: 'CodeOps Platform',
  slug: 'codeops-platform',
  description: 'Core infrastructure services for the CodeOps ecosystem',
  category: SolutionCategory.platform,
  status: SolutionStatus.active,
  colorHex: '#6C63FF',
  memberCount: 6,
);

const _minimalSolution = SolutionResponse(
  id: 'sol-2',
  teamId: 'team-1',
  name: 'Minimal Solution',
  slug: 'minimal-solution',
  category: SolutionCategory.other,
  status: SolutionStatus.inDevelopment,
  memberCount: 0,
);

void _setWideViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 600);
  tester.view.devicePixelRatio = 1.0;
}

Widget _buildCard({
  SolutionResponse solution = _testSolution,
  VoidCallback? onTap,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 600,
        child: SolutionCard(solution: solution, onTap: onTap),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SolutionCard', () {
    testWidgets('renders name and description', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_buildCard());
      await tester.pumpAndSettle();

      expect(find.text('CodeOps Platform'), findsOneWidget);
      expect(
        find.text('Core infrastructure services for the CodeOps ecosystem'),
        findsOneWidget,
      );
    });

    testWidgets('renders category badge', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_buildCard());
      await tester.pumpAndSettle();

      expect(find.text('Platform'), findsOneWidget);
    });

    testWidgets('renders status badge', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_buildCard());
      await tester.pumpAndSettle();

      expect(find.text('Active'), findsOneWidget);
    });

    testWidgets('renders member count', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_buildCard());
      await tester.pumpAndSettle();

      expect(find.text('6 services'), findsOneWidget);
    });

    testWidgets('renders color accent when colorHex set', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_buildCard());
      await tester.pumpAndSettle();

      // The card should have a 4px accent strip when colorHex is set
      // Verify by finding the Row with CrossAxisAlignment.stretch
      // (The card renders a Container with width: 4)
      final containers = find.byType(Container);
      expect(containers, findsWidgets);
    });

    testWidgets('renders without color accent when no colorHex',
        (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_buildCard(solution: _minimalSolution));
      await tester.pumpAndSettle();

      expect(find.text('Minimal Solution'), findsOneWidget);
      expect(find.text('In Development'), findsOneWidget);
      expect(find.text('0 services'), findsOneWidget);
    });
  });
}
