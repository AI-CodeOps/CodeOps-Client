/// Tests for [PersonaPreview] widget.
///
/// Covers markdown rendering, section validation, and empty state.
library;

import 'package:codeops/widgets/personas/persona_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _createWidget({
  String content = '',
  bool showValidation = true,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 800,
        height: 800,
        child: PersonaPreview(
          content: content,
          showValidation: showValidation,
        ),
      ),
    ),
  );
}

void main() {
  group('PersonaPreview', () {
    testWidgets('shows empty state when content is empty', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget(content: ''));
      await tester.pumpAndSettle();

      expect(find.text('Preview will appear here...'), findsOneWidget);
    });

    testWidgets('renders markdown content', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
          _createWidget(content: '# Hello\n\nThis is a test.'));
      await tester.pumpAndSettle();

      expect(find.text('Hello'), findsOneWidget);
      expect(find.text('This is a test.'), findsOneWidget);
    });

    testWidgets('shows section validation when enabled', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget(
        content: '## Identity\nI am a persona.',
        showValidation: true,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Sections:'), findsOneWidget);
      // Section names may also appear in the markdown rendering.
      expect(find.text('Identity'), findsWidgets);
      expect(find.text('Focus Areas'), findsWidgets);
      expect(find.text('Severity Calibration'), findsWidgets);
      expect(find.text('Output Format'), findsWidgets);
    });

    testWidgets('shows check for present sections', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget(
        content: '## Identity\n\n## Focus Areas\n\n'
            '## Severity Calibration\n\n## Output Format',
      ));
      await tester.pumpAndSettle();

      // All 4 sections present — all check icons.
      expect(find.byIcon(Icons.check_circle), findsNWidgets(4));
      expect(find.byIcon(Icons.cancel), findsNothing);
    });

    testWidgets('shows X for missing sections', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget(
        content: '## Identity\n\nOnly identity is present.',
      ));
      await tester.pumpAndSettle();

      // 1 check, 3 cancel.
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byIcon(Icons.cancel), findsNWidgets(3));
    });

    testWidgets('hides validation panel when showValidation is false',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget(
        content: '# Test',
        showValidation: false,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Sections:'), findsNothing);
    });
  });
}
