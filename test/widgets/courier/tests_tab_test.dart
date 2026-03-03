// Widget tests for TestsTab.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/providers/courier_ui_providers.dart';
import 'package:codeops/widgets/courier/tests_tab.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

Widget buildTestsTab({List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: [
      scriptTestsProvider.overrideWith((ref) => ''),
      scriptConsoleProvider.overrideWith((ref) => <ConsoleEntry>[]),
      ...overrides,
    ],
    child: const MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 1000,
          height: 700,
          child: TestsTab(),
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
  group('TestsTab', () {
    testWidgets('renders tests editor', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildTestsTab());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('tests_tab')), findsOneWidget);
      expect(find.byKey(const Key('tests_editor')), findsOneWidget);
    });

    testWidgets('shows assertion snippet sidebar', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildTestsTab());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('snippet_sidebar')), findsOneWidget);
      expect(find.text('Status code is 200'), findsOneWidget);
      expect(find.text('Response time < 500ms'), findsOneWidget);
      expect(find.text('Body contains property'), findsOneWidget);
    });

    testWidgets('shows console panel', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildTestsTab());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('script_console')), findsOneWidget);
    });
  });
}
