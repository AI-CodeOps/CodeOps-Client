// Tests for MarkdownRenderer.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/widgets/reports/markdown_renderer.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 600,
          height: 400,
          child: child,
        ),
      ),
    );
  }

  group('MarkdownRenderer', () {
    testWidgets('renders plain text', (tester) async {
      await tester.pumpWidget(wrap(
        const MarkdownRenderer(
          content: 'Hello world',
          shrinkWrap: true,
        ),
      ));
      await tester.pump();

      expect(find.text('Hello world'), findsOneWidget);
    });

    testWidgets('renders heading text', (tester) async {
      await tester.pumpWidget(wrap(
        const MarkdownRenderer(
          content: '# Main Heading',
          shrinkWrap: true,
        ),
      ));
      await tester.pump();

      expect(find.text('Main Heading'), findsOneWidget);
    });

    testWidgets('renders h2 heading', (tester) async {
      await tester.pumpWidget(wrap(
        const MarkdownRenderer(
          content: '## Section Title',
          shrinkWrap: true,
        ),
      ));
      await tester.pump();

      expect(find.text('Section Title'), findsOneWidget);
    });

    testWidgets('renders inline code', (tester) async {
      await tester.pumpWidget(wrap(
        const MarkdownRenderer(
          content: 'Use `flutter test` to run tests.',
          shrinkWrap: true,
        ),
      ));
      await tester.pump();

      expect(find.textContaining('flutter test'), findsOneWidget);
    });

    testWidgets('renders multiple paragraphs', (tester) async {
      await tester.pumpWidget(wrap(
        const MarkdownRenderer(
          content: 'First paragraph.\n\nSecond paragraph.',
          shrinkWrap: true,
        ),
      ));
      await tester.pump();

      expect(find.text('First paragraph.'), findsOneWidget);
      expect(find.text('Second paragraph.'), findsOneWidget);
    });

    testWidgets('renders with selectable false uses MarkdownBody',
        (tester) async {
      await tester.pumpWidget(wrap(
        const MarkdownRenderer(
          content: 'Body content',
          selectable: false,
          shrinkWrap: true,
        ),
      ));
      await tester.pump();

      expect(find.text('Body content'), findsOneWidget);
    });
  });
}
