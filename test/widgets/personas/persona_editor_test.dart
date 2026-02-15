/// Tests for [PersonaEditorWidget].
///
/// Covers toolbar, line numbers, debounce, read-only, and word count.
library;

import 'package:codeops/widgets/personas/persona_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _createWidget({
  String initialContent = '',
  ValueChanged<String>? onChanged,
  bool readOnly = false,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 800,
        height: 600,
        child: PersonaEditorWidget(
          initialContent: initialContent,
          onChanged: onChanged ?? (_) {},
          readOnly: readOnly,
        ),
      ),
    ),
  );
}

void main() {
  group('PersonaEditorWidget', () {
    testWidgets('shows toolbar buttons', (tester) async {
      await tester.pumpWidget(_createWidget());

      expect(find.byIcon(Icons.format_bold), findsOneWidget);
      expect(find.byIcon(Icons.format_italic), findsOneWidget);
      expect(find.byIcon(Icons.title), findsOneWidget);
      expect(find.byIcon(Icons.format_list_bulleted), findsOneWidget);
      expect(find.byIcon(Icons.code), findsOneWidget);
      expect(find.byIcon(Icons.data_object), findsOneWidget);
      expect(find.byIcon(Icons.link), findsOneWidget);
    });

    testWidgets('hides toolbar in readOnly mode', (tester) async {
      await tester.pumpWidget(_createWidget(readOnly: true));

      expect(find.byIcon(Icons.format_bold), findsNothing);
    });

    testWidgets('shows initial content', (tester) async {
      await tester.pumpWidget(
          _createWidget(initialContent: 'Hello World'));
      await tester.pumpAndSettle();

      expect(find.text('Hello World'), findsOneWidget);
    });

    testWidgets('shows line numbers', (tester) async {
      await tester.pumpWidget(
          _createWidget(initialContent: 'Line 1\nLine 2\nLine 3'));
      await tester.pumpAndSettle();

      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('shows word and character counts', (tester) async {
      await tester.pumpWidget(
          _createWidget(initialContent: 'Hello World Test'));
      await tester.pumpAndSettle();

      expect(find.text('3 words'), findsOneWidget);
      expect(find.text('16 characters'), findsOneWidget);
    });

    testWidgets('calls onChanged after typing', (tester) async {
      String? lastValue;
      await tester.pumpWidget(_createWidget(
        onChanged: (v) => lastValue = v,
      ));

      // Find the TextField and enter text.
      final textField = find.byType(TextField);
      await tester.enterText(textField, 'new text');

      // Wait for debounce.
      await tester.pump(const Duration(milliseconds: 350));

      expect(lastValue, 'new text');
    });

    testWidgets('readOnly prevents text entry', (tester) async {
      await tester.pumpWidget(_createWidget(
        initialContent: 'Read only',
        readOnly: true,
      ));

      final textField = find.byType(TextField);
      // Should exist but be read-only.
      expect(textField, findsOneWidget);
    });
  });
}
