// Widget tests for CodeDisplayPanel.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/courier_enums.dart';
import 'package:codeops/widgets/courier/code_display_panel.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

const _sampleCode = '''curl -X GET 'https://api.example.com/users' \\
  -H 'Authorization: Bearer token123'
''';

Widget buildPanel({
  String code = _sampleCode,
  CodeLanguage language = CodeLanguage.curl,
  ValueChanged<bool>? onVariablesToggled,
  bool showResolved = false,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 900,
        height: 600,
        child: CodeDisplayPanel(
          code: code,
          language: language,
          onVariablesToggled: onVariablesToggled,
          showResolved: showResolved,
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
  group('CodeDisplayPanel', () {
    testWidgets('renders panel with code content', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildPanel());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('code_display_panel')), findsOneWidget);
      expect(find.byKey(const Key('code_content')), findsOneWidget);
    });

    testWidgets('shows copy button', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildPanel());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('copy_button')), findsOneWidget);
      expect(find.text('Copy'), findsOneWidget);
    });

    testWidgets('shows save button', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildPanel());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('save_button')), findsOneWidget);
    });

    testWidgets('shows variables toggle when callback provided', (tester) async {
      setSize(tester);
      bool toggled = false;
      await tester.pumpWidget(buildPanel(
        onVariablesToggled: (v) => toggled = v,
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('variables_toggle')), findsOneWidget);
      expect(find.text('Resolved'), findsOneWidget);
    });
  });
}
