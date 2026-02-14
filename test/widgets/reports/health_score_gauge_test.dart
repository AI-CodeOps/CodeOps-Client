// Tests for HealthScoreGauge.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/widgets/reports/health_score_gauge.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  group('HealthScoreGauge', () {
    testWidgets('renders score text after animation', (tester) async {
      await tester.pumpWidget(wrap(
        const HealthScoreGauge(score: 85),
      ));

      // Allow animation to complete.
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('85'), findsOneWidget);
    });

    testWidgets('renders Health Score label when showLabel is true',
        (tester) async {
      await tester.pumpWidget(wrap(
        const HealthScoreGauge(score: 70, showLabel: true),
      ));

      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Health Score'), findsOneWidget);
    });

    testWidgets('hides label when showLabel is false', (tester) async {
      await tester.pumpWidget(wrap(
        const HealthScoreGauge(score: 70, showLabel: false),
      ));

      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Health Score'), findsNothing);
    });

    testWidgets('updates displayed score on widget rebuild', (tester) async {
      await tester.pumpWidget(wrap(
        const HealthScoreGauge(score: 40),
      ));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('40'), findsOneWidget);

      // Rebuild with a new score.
      await tester.pumpWidget(wrap(
        const HealthScoreGauge(score: 95),
      ));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('95'), findsOneWidget);
    });

    testWidgets('renders score of 0', (tester) async {
      await tester.pumpWidget(wrap(
        const HealthScoreGauge(score: 0),
      ));

      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('renders score of 100', (tester) async {
      await tester.pumpWidget(wrap(
        const HealthScoreGauge(score: 100),
      ));

      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('100'), findsOneWidget);
    });
  });
}
