// Widget tests for AggregationPicker.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/widgets/logger/aggregation_picker.dart';

void main() {
  Widget createWidget({
    AggregationFunction aggregation = AggregationFunction.avg,
    TimeRange timeRange = TimeRange.h1,
    ValueChanged<AggregationFunction>? onAggregationChanged,
    ValueChanged<TimeRange>? onTimeRangeChanged,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: AggregationPicker(
          aggregation: aggregation,
          timeRange: timeRange,
          onAggregationChanged: onAggregationChanged ?? (_) {},
          onTimeRangeChanged: onTimeRangeChanged ?? (_) {},
        ),
      ),
    );
  }

  group('AggregationPicker', () {
    testWidgets('renders both dropdowns', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Aggregation: '), findsOneWidget);
      expect(find.text('Time Range: '), findsOneWidget);
    });

    testWidgets('shows current aggregation function', (tester) async {
      await tester.pumpWidget(
        createWidget(aggregation: AggregationFunction.p95),
      );
      await tester.pumpAndSettle();

      expect(find.text('P95'), findsOneWidget);
    });

    testWidgets('shows current time range', (tester) async {
      await tester.pumpWidget(
        createWidget(timeRange: TimeRange.h6),
      );
      await tester.pumpAndSettle();

      expect(find.text('6h'), findsOneWidget);
    });

    testWidgets('opens aggregation dropdown', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Tap the AVG dropdown.
      await tester.tap(find.text('AVG'));
      await tester.pumpAndSettle();

      // Should show all aggregation options.
      expect(find.text('SUM'), findsOneWidget);
      expect(find.text('MIN'), findsOneWidget);
      expect(find.text('MAX'), findsOneWidget);
    });
  });
}
