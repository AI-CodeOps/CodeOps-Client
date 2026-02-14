import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/widgets/progress/elapsed_timer.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  group('ElapsedTimer', () {
    testWidgets('renders HH:MM:SS format', (tester) async {
      await tester.pumpWidget(wrap(
        ElapsedTimer(
          startTime: DateTime.now().subtract(const Duration(hours: 1, minutes: 23, seconds: 45)),
          running: false,
        ),
      ));

      // Should display time in HH:MM:SS format
      expect(find.textContaining(':'), findsOneWidget);
    });

    testWidgets('shows timer icon when running', (tester) async {
      await tester.pumpWidget(wrap(
        ElapsedTimer(startTime: DateTime.now(), running: true),
      ));

      expect(find.byIcon(Icons.timer), findsOneWidget);
    });

    testWidgets('shows timer_off icon when stopped', (tester) async {
      await tester.pumpWidget(wrap(
        ElapsedTimer(startTime: DateTime.now(), running: false),
      ));

      expect(find.byIcon(Icons.timer_off), findsOneWidget);
    });

    testWidgets('displays 00:00:00 for just-started timer', (tester) async {
      await tester.pumpWidget(wrap(
        ElapsedTimer(startTime: DateTime.now(), running: false),
      ));

      expect(find.text('00:00:00'), findsOneWidget);
    });
  });
}
