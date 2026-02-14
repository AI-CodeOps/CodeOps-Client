// Tests for SeverityChart.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/enums.dart';
import 'package:codeops/widgets/reports/severity_chart.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  group('SeverityChart — bar mode', () {
    testWidgets('renders severity display names as labels', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrap(
        SeverityChart(
          counts: const {
            Severity.critical: 2,
            Severity.high: 5,
            Severity.medium: 8,
            Severity.low: 3,
          },
          mode: SeverityChartMode.bar,
        ),
      ));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Critical'), findsOneWidget);
      expect(find.text('High'), findsOneWidget);
      expect(find.text('Medium'), findsOneWidget);
      expect(find.text('Low'), findsOneWidget);
    });

    testWidgets('renders count values', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrap(
        SeverityChart(
          counts: const {
            Severity.critical: 1,
            Severity.high: 3,
            Severity.medium: 4,
            Severity.low: 2,
          },
          mode: SeverityChartMode.bar,
        ),
      ));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('1'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });
  });

  group('SeverityChart — donut mode', () {
    testWidgets('renders without error in donut mode', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrap(
        SeverityChart(
          counts: const {
            Severity.critical: 25,
            Severity.high: 25,
            Severity.medium: 25,
            Severity.low: 25,
          },
          mode: SeverityChartMode.donut,
        ),
      ));
      await tester.pump(const Duration(milliseconds: 100));

      // Donut mode should not show "No findings".
      expect(find.text('No findings'), findsNothing);
    });

    testWidgets('renders legend with severity names and counts',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrap(
        SeverityChart(
          counts: const {
            Severity.critical: 2,
            Severity.high: 5,
            Severity.medium: 8,
            Severity.low: 3,
          },
          mode: SeverityChartMode.donut,
        ),
      ));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Critical: 2'), findsOneWidget);
      expect(find.text('High: 5'), findsOneWidget);
      expect(find.text('Medium: 8'), findsOneWidget);
      expect(find.text('Low: 3'), findsOneWidget);
    });
  });

  group('SeverityChart — empty state', () {
    testWidgets('shows "No findings" when all counts are zero',
        (tester) async {
      await tester.pumpWidget(wrap(
        SeverityChart(
          counts: const {
            Severity.critical: 0,
            Severity.high: 0,
            Severity.medium: 0,
            Severity.low: 0,
          },
        ),
      ));
      await tester.pump();

      expect(find.text('No findings'), findsOneWidget);
    });

    testWidgets('shows "No findings" when counts map is empty',
        (tester) async {
      await tester.pumpWidget(wrap(
        const SeverityChart(counts: {}),
      ));
      await tester.pump();

      expect(find.text('No findings'), findsOneWidget);
    });
  });
}
