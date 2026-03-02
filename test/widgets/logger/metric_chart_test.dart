// Widget tests for MetricChart.
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/logger_models.dart';
import 'package:codeops/widgets/logger/metric_chart.dart';

void main() {
  final now = DateTime.utc(2026, 1, 15, 10, 0);

  final series = MetricTimeSeriesResponse(
    metricId: 'm-1',
    metricName: 'cpu_usage',
    serviceName: 'api-gateway',
    metricType: 'GAUGE',
    unit: 'percent',
    startTime: now.subtract(const Duration(hours: 1)),
    endTime: now,
    resolution: 60,
    dataPoints: [
      TimeSeriesDataPoint(
        timestamp: now.subtract(const Duration(minutes: 30)),
        value: 45.2,
      ),
      TimeSeriesDataPoint(
        timestamp: now.subtract(const Duration(minutes: 20)),
        value: 48.0,
      ),
      TimeSeriesDataPoint(
        timestamp: now.subtract(const Duration(minutes: 10)),
        value: 42.5,
      ),
      TimeSeriesDataPoint(timestamp: now, value: 50.1),
    ],
  );

  final overlaySeries = MetricTimeSeriesResponse(
    metricId: 'm-2',
    metricName: 'memory_usage',
    serviceName: 'api-gateway',
    metricType: 'GAUGE',
    unit: 'percent',
    startTime: now.subtract(const Duration(hours: 1)),
    endTime: now,
    resolution: 60,
    dataPoints: [
      TimeSeriesDataPoint(
        timestamp: now.subtract(const Duration(minutes: 30)),
        value: 60.0,
      ),
      TimeSeriesDataPoint(timestamp: now, value: 65.0),
    ],
  );

  Widget createWidget({
    MetricTimeSeriesResponse? data,
    List<MetricTimeSeriesResponse> overlays = const [],
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 800,
          height: 400,
          child: MetricChart(
            series: data,
            overlays: overlays,
          ),
        ),
      ),
    );
  }

  group('MetricChart', () {
    testWidgets('renders empty state when no data', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('No data to display'), findsOneWidget);
    });

    testWidgets('renders line chart with data', (tester) async {
      await tester.pumpWidget(createWidget(data: series));
      await tester.pumpAndSettle();

      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('renders with overlay series', (tester) async {
      await tester.pumpWidget(
        createWidget(data: series, overlays: [overlaySeries]),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('shows empty message for empty data points', (tester) async {
      final emptySeries = MetricTimeSeriesResponse(
        metricId: 'm-1',
        metricName: 'cpu_usage',
        serviceName: 'api-gateway',
        metricType: 'GAUGE',
        startTime: now.subtract(const Duration(hours: 1)),
        endTime: now,
        resolution: 60,
        dataPoints: [],
      );
      await tester.pumpWidget(createWidget(data: emptySeries));
      await tester.pumpAndSettle();

      expect(find.text('No data to display'), findsOneWidget);
    });

    testWidgets('handles single data point', (tester) async {
      final singlePoint = MetricTimeSeriesResponse(
        metricId: 'm-1',
        metricName: 'cpu_usage',
        serviceName: 'api-gateway',
        metricType: 'GAUGE',
        startTime: now.subtract(const Duration(hours: 1)),
        endTime: now,
        resolution: 60,
        dataPoints: [
          TimeSeriesDataPoint(timestamp: now, value: 42.0),
        ],
      );
      await tester.pumpWidget(createWidget(data: singlePoint));
      await tester.pumpAndSettle();

      expect(find.byType(LineChart), findsOneWidget);
    });
  });
}
