// Tests for TrendChart.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/health_snapshot.dart';
import 'package:codeops/widgets/reports/trend_chart.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 800,
          height: 400,
          child: child,
        ),
      ),
    );
  }

  group('TrendChart', () {
    testWidgets('empty state shows "No trend data available"', (tester) async {
      await tester.pumpWidget(wrap(
        const TrendChart(snapshots: []),
      ));
      await tester.pump();

      expect(find.text('No trend data available'), findsOneWidget);
    });

    testWidgets('renders without error with a single snapshot',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final snapshots = [
        HealthSnapshot(
          id: 's1',
          projectId: 'p1',
          healthScore: 85,
          capturedAt: DateTime(2026, 1, 1),
        ),
      ];

      await tester.pumpWidget(wrap(
        TrendChart(snapshots: snapshots),
      ));
      await tester.pump();

      // Chart should render (no "No trend data" message).
      expect(find.text('No trend data available'), findsNothing);
    });

    testWidgets('renders with multiple snapshots', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final snapshots = [
        HealthSnapshot(
          id: 's1',
          projectId: 'p1',
          healthScore: 85,
          capturedAt: DateTime(2026, 1, 1),
        ),
        HealthSnapshot(
          id: 's2',
          projectId: 'p1',
          healthScore: 78,
          capturedAt: DateTime(2026, 1, 8),
        ),
        HealthSnapshot(
          id: 's3',
          projectId: 'p1',
          healthScore: 92,
          capturedAt: DateTime(2026, 1, 15),
        ),
      ];

      await tester.pumpWidget(wrap(
        TrendChart(snapshots: snapshots),
      ));
      await tester.pump();

      // Chart is rendered; the empty state message should not appear.
      expect(find.text('No trend data available'), findsNothing);
    });

    testWidgets('renders Y-axis labels', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final snapshots = [
        HealthSnapshot(
          id: 's1',
          projectId: 'p1',
          healthScore: 50,
          capturedAt: DateTime(2026, 1, 1),
        ),
        HealthSnapshot(
          id: 's2',
          projectId: 'p1',
          healthScore: 70,
          capturedAt: DateTime(2026, 1, 5),
        ),
      ];

      await tester.pumpWidget(wrap(
        TrendChart(snapshots: snapshots),
      ));
      await tester.pump();

      // Y-axis shows intervals of 20: 0, 20, 40, 60, 80, 100.
      expect(find.text('0'), findsOneWidget);
      expect(find.text('20'), findsOneWidget);
      expect(find.text('40'), findsOneWidget);
      expect(find.text('60'), findsOneWidget);
      expect(find.text('80'), findsOneWidget);
      expect(find.text('100'), findsOneWidget);
    });

    testWidgets('respects custom height', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrap(
        const TrendChart(snapshots: [], height: 300),
      ));
      await tester.pump();

      // The empty state should still show the message.
      expect(find.text('No trend data available'), findsOneWidget);

      // Find the SizedBox that wraps the empty state with the custom height.
      final sizedBoxes = tester.widgetList<SizedBox>(
        find.ancestor(
          of: find.text('No trend data available'),
          matching: find.byType(SizedBox),
        ),
      );
      final hasCorrectHeight = sizedBoxes.any((sb) => sb.height == 300);
      expect(hasCorrectHeight, isTrue);
    });
  });
}
