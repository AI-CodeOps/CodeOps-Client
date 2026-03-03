// Widget tests for ScriptConsole.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/providers/courier_ui_providers.dart';
import 'package:codeops/widgets/courier/script_console.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

Widget buildConsole({List<ConsoleEntry> entries = const []}) {
  return ProviderScope(
    overrides: [
      scriptConsoleProvider.overrideWith((ref) => entries),
    ],
    child: const MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 800,
          height: 300,
          child: ScriptConsole(),
        ),
      ),
    ),
  );
}

void setSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('ScriptConsole', () {
    testWidgets('renders empty console', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildConsole());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('script_console')), findsOneWidget);
      expect(find.byKey(const Key('console_empty')), findsOneWidget);
      expect(find.text('No console output'), findsOneWidget);
    });

    testWidgets('shows log entries', (tester) async {
      setSize(tester);
      final entries = [
        ConsoleEntry(
          timestamp: DateTime(2026, 3, 2, 12, 0, 0),
          type: ConsoleEntryType.log,
          message: 'Hello from script',
        ),
      ];
      await tester.pumpWidget(buildConsole(entries: entries));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('console_list')), findsOneWidget);
      expect(find.text('Hello from script'), findsOneWidget);
    });

    testWidgets('shows test pass and fail results', (tester) async {
      setSize(tester);
      final entries = [
        ConsoleEntry(
          timestamp: DateTime(2026, 3, 2, 12, 0, 0),
          type: ConsoleEntryType.testPass,
          message: 'Status is 200',
        ),
        ConsoleEntry(
          timestamp: DateTime(2026, 3, 2, 12, 0, 1),
          type: ConsoleEntryType.testFail,
          message: 'Expected 404 but got 200',
        ),
      ];
      await tester.pumpWidget(buildConsole(entries: entries));
      await tester.pumpAndSettle();

      expect(find.text('Status is 200'), findsOneWidget);
      expect(find.text('Expected 404 but got 200'), findsOneWidget);
    });

    testWidgets('shows error entries', (tester) async {
      setSize(tester);
      final entries = [
        ConsoleEntry(
          timestamp: DateTime(2026, 3, 2, 12, 0, 0),
          type: ConsoleEntryType.error,
          message: 'ReferenceError: x is not defined',
        ),
      ];
      await tester.pumpWidget(buildConsole(entries: entries));
      await tester.pumpAndSettle();

      expect(find.text('ReferenceError: x is not defined'), findsOneWidget);
    });

    testWidgets('clear button resets console', (tester) async {
      setSize(tester);
      final entries = [
        ConsoleEntry(
          timestamp: DateTime(2026, 3, 2, 12, 0, 0),
          type: ConsoleEntryType.log,
          message: 'test message',
        ),
      ];
      await tester.pumpWidget(buildConsole(entries: entries));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('console_clear_button')), findsOneWidget);
      await tester.tap(find.byKey(const Key('console_clear_button')));
      await tester.pumpAndSettle();

      // After clearing, the empty message should appear.
      expect(find.byKey(const Key('console_empty')), findsOneWidget);
    });
  });
}
