// Widget tests for ScriptEditor.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/widgets/courier/script_editor.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

Widget buildEditor({
  String content = '',
  List<ScriptSnippet> snippets = const [],
  ValueChanged<String>? onChanged,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 1000,
        height: 600,
        child: ScriptEditor(
          content: content,
          snippets: snippets,
          onChanged: onChanged,
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
  group('ScriptEditor', () {
    testWidgets('renders code editor', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildEditor());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('script_code_editor')), findsOneWidget);
    });

    testWidgets('shows snippet sidebar when snippets provided',
        (tester) async {
      setSize(tester);
      const snippets = [
        ScriptSnippet(label: 'Log', code: 'console.log("hi");'),
        ScriptSnippet(label: 'Set var', code: 'courier.environment.set("k", "v");'),
      ];
      await tester.pumpWidget(buildEditor(snippets: snippets));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('snippet_sidebar')), findsOneWidget);
      expect(find.text('Log'), findsOneWidget);
      expect(find.text('Set var'), findsOneWidget);
    });

    testWidgets('hides snippet sidebar when no snippets', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildEditor());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('snippet_sidebar')), findsNothing);
    });

    testWidgets('snippet sidebar toggles collapse', (tester) async {
      setSize(tester);
      const snippets = [
        ScriptSnippet(label: 'Test', code: 'code'),
      ];
      await tester.pumpWidget(buildEditor(snippets: snippets));
      await tester.pumpAndSettle();

      // Sidebar should be expanded showing snippet list.
      expect(find.byKey(const Key('snippet_list')), findsOneWidget);

      // Collapse.
      await tester.tap(find.byKey(const Key('snippet_toggle')));
      await tester.pumpAndSettle();

      // Snippet list should be gone when collapsed.
      expect(find.byKey(const Key('snippet_list')), findsNothing);
    });
  });
}
