// Widget tests for BodyRawEditor.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/courier_enums.dart';
import 'package:codeops/widgets/courier/body_raw_editor.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

Widget buildRawEditor({
  String content = '',
  BodyType bodyType = BodyType.rawJson,
  ValueChanged<String>? onChanged,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 800,
        height: 600,
        child: BodyRawEditor(
          content: content,
          bodyType: bodyType,
          onChanged: onChanged ?? (_) {},
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
  group('BodyRawEditor', () {
    testWidgets('renders toolbar and editor', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildRawEditor());
      await tester.pumpAndSettle();

      expect(find.byType(BodyRawEditor), findsOneWidget);
      expect(find.byKey(const Key('raw_editor_toolbar')), findsOneWidget);
    });

    testWidgets('shows beautify/minify buttons for JSON', (tester) async {
      setSize(tester);
      await tester
          .pumpWidget(buildRawEditor(bodyType: BodyType.rawJson));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('beautify_button')), findsOneWidget);
      expect(find.byKey(const Key('minify_button')), findsOneWidget);
    });

    testWidgets('hides beautify/minify for non-JSON types',
        (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildRawEditor(bodyType: BodyType.rawXml));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('beautify_button')), findsNothing);
      expect(find.byKey(const Key('minify_button')), findsNothing);
    });

    testWidgets('shows word wrap and copy buttons', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildRawEditor());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('word_wrap_button')), findsOneWidget);
      expect(find.byKey(const Key('copy_button')), findsOneWidget);
    });

    testWidgets('displays body type label', (tester) async {
      setSize(tester);
      await tester
          .pumpWidget(buildRawEditor(bodyType: BodyType.rawJson));
      await tester.pumpAndSettle();

      expect(find.text('JSON'), findsOneWidget);
    });

    testWidgets('displays XML body type label', (tester) async {
      setSize(tester);
      await tester
          .pumpWidget(buildRawEditor(bodyType: BodyType.rawXml));
      await tester.pumpAndSettle();

      expect(find.text('XML'), findsOneWidget);
    });
  });
}
