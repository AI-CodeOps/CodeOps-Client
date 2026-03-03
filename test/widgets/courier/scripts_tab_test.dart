// Widget tests for ScriptsTab.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/providers/courier_ui_providers.dart';
import 'package:codeops/widgets/courier/scripts_tab.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

Widget buildScriptsTab({List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: [
      scriptPreRequestProvider.overrideWith((ref) => ''),
      scriptPostResponseProvider.overrideWith((ref) => ''),
      scriptConsoleProvider.overrideWith((ref) => <ConsoleEntry>[]),
      ...overrides,
    ],
    child: const MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 1000,
          height: 700,
          child: ScriptsTab(),
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
  group('ScriptsTab', () {
    testWidgets('renders with sub-tab bar', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildScriptsTab());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('scripts_tab')), findsOneWidget);
      expect(find.byKey(const Key('scripts_sub_tab_bar')), findsOneWidget);
    });

    testWidgets('shows pre-request tab by default', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildScriptsTab());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('pre_request_tab')), findsOneWidget);
      expect(find.byKey(const Key('pre_request_editor')), findsOneWidget);
    });

    testWidgets('can switch to post-response tab', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildScriptsTab());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('post_response_tab')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('post_response_editor')), findsOneWidget);
    });

    testWidgets('shows snippet sidebar in pre-request', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildScriptsTab());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('snippet_sidebar')), findsOneWidget);
      expect(find.text('Set environment variable'), findsOneWidget);
      expect(find.text('Log to console'), findsOneWidget);
    });
  });
}
