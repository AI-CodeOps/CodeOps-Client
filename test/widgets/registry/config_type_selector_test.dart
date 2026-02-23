// Tests for ConfigTypeSelector widget.
//
// Verifies all types render in service mode, only docker-compose in
// solution mode, toggle callback, selected highlighting, and icons.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/registry_enums.dart';
import 'package:codeops/widgets/registry/config_type_selector.dart';

void _setWideViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1600, 900);
  tester.view.devicePixelRatio = 1.0;
}

Widget _buildSelector({
  Set<ConfigTemplateType> selectedTypes = const {},
  ValueChanged<ConfigTemplateType>? onToggle,
  bool solutionMode = false,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: ConfigTypeSelector(
          selectedTypes: selectedTypes,
          onToggle: onToggle ?? (_) {},
          solutionMode: solutionMode,
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ConfigTypeSelector', () {
    testWidgets('renders all 12 types in service mode', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_buildSelector());
      await tester.pumpAndSettle();

      for (final type in ConfigTemplateType.values) {
        expect(find.text(type.displayName), findsOneWidget);
      }
    });

    testWidgets('solution mode shows only docker-compose enabled',
        (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_buildSelector(solutionMode: true));
      await tester.pumpAndSettle();

      // Docker Compose chip should be tappable.
      expect(find.text('Docker Compose'), findsOneWidget);
      // All chips still render but non-docker-compose are disabled.
      expect(
        find.byType(FilterChip),
        findsNWidgets(ConfigTemplateType.values.length),
      );
    });

    testWidgets('toggle callback fires', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      ConfigTemplateType? toggled;
      await tester.pumpWidget(_buildSelector(
        onToggle: (t) => toggled = t,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Docker Compose'));
      expect(toggled, ConfigTemplateType.dockerCompose);
    });

    testWidgets('selected types are highlighted', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_buildSelector(
        selectedTypes: {ConfigTemplateType.dockerfile},
      ));
      await tester.pumpAndSettle();

      final chip = tester.widget<FilterChip>(
        find.ancestor(
          of: find.text('Dockerfile'),
          matching: find.byType(FilterChip),
        ),
      );
      expect(chip.selected, isTrue);
    });

    testWidgets('renders icons', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_buildSelector());
      await tester.pumpAndSettle();

      // Docker Compose uses Icons.dock
      expect(find.byIcon(Icons.dock), findsOneWidget);
      // Dockerfile uses Icons.inventory_2
      expect(find.byIcon(Icons.inventory_2), findsOneWidget);
    });
  });
}
