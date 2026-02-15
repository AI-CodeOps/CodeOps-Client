/// Tests for [PersonaTestRunner] dialog.
///
/// Covers dialog layout, run button state, and output display.
library;

import 'package:codeops/widgets/personas/persona_test_runner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _createWidget() {
  return ProviderScope(
    child: MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showPersonaTestRunner(
              context,
              personaName: 'Test Persona',
              personaContent: '## Identity\nTest content',
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('PersonaTestRunner', () {
    testWidgets('opens dialog with correct title', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Test: Test Persona'), findsOneWidget);
    });

    testWidgets('shows language dropdown', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Language'), findsOneWidget);
    });

    testWidgets('shows model input', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Model'), findsOneWidget);
    });

    testWidgets('shows max turns input', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Max Turns'), findsOneWidget);
    });

    testWidgets('shows code sample label', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Code Sample'), findsOneWidget);
    });

    testWidgets('shows Run Test button', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Run Test'), findsOneWidget);
    });

    testWidgets('shows Close button', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Close'), findsOneWidget);
    });

    testWidgets('shows output placeholder', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Run a test to see output here'), findsOneWidget);
    });

    testWidgets('closes dialog on Close tap', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(find.text('Test: Test Persona'), findsNothing);
    });
  });
}
