// Widget tests for LogLine.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/widgets/fleet/log_line.dart';

void main() {
  Widget wrap(LogLine widget) {
    return MaterialApp(home: Scaffold(body: widget));
  }

  group('LogLine', () {
    testWidgets('renders content text', (tester) async {
      await tester.pumpWidget(wrap(
        const LogLine(content: 'Hello world'),
      ));

      expect(find.text('Hello world'), findsOneWidget);
    });

    testWidgets('renders timestamp when provided', (tester) async {
      await tester.pumpWidget(wrap(
        LogLine(
          content: 'log line',
          timestamp: DateTime(2026, 2, 27, 14, 30, 45, 123),
        ),
      ));

      expect(find.text('14:30:45.123'), findsOneWidget);
    });

    testWidgets('does not render timestamp when null', (tester) async {
      await tester.pumpWidget(wrap(
        const LogLine(content: 'no timestamp'),
      ));

      // Only the content should be rendered
      expect(find.text('no timestamp'), findsOneWidget);
      expect(find.byType(Text), findsOneWidget);
    });

    testWidgets('uses error color for stderr stream', (tester) async {
      await tester.pumpWidget(wrap(
        const LogLine(content: 'error line', stream: 'stderr'),
      ));

      final textWidget = tester.widget<Text>(find.text('error line'));
      final style = textWidget.style!;
      // stderr should use error red (0xFFEF4444)
      expect(style.color, const Color(0xFFEF4444));
    });

    testWidgets('uses default color for stdout stream', (tester) async {
      await tester.pumpWidget(wrap(
        const LogLine(content: 'normal line', stream: 'stdout'),
      ));

      final textWidget = tester.widget<Text>(find.text('normal line'));
      final style = textWidget.style!;
      // stdout should use textPrimary (0xFFE2E8F0)
      expect(style.color, const Color(0xFFE2E8F0));
    });
  });
}
