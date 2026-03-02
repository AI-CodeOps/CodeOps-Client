// Widget tests for StorageChart.
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/logger_models.dart';
import 'package:codeops/widgets/logger/storage_chart.dart';

void main() {
  final now = DateTime.utc(2026, 1, 15, 10, 0);

  final usage = StorageUsageResponse(
    totalLogEntries: 150000,
    totalMetricDataPoints: 50000,
    totalTraceSpans: 25000,
    logEntriesByService: {'api-gateway': 80000, 'auth-service': 70000},
    logEntriesByLevel: {'INFO': 100000, 'ERROR': 30000, 'WARN': 20000},
    activeRetentionPolicies: 2,
    oldestLogEntry: now.subtract(const Duration(days: 90)),
    newestLogEntry: now,
  );

  Widget createWidget({StorageUsageResponse? data}) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 800,
          height: 400,
          child: StorageChart(usage: data ?? usage),
        ),
      ),
    );
  }

  group('StorageChart', () {
    testWidgets('renders pie chart', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byType(PieChart), findsOneWidget);
    });

    testWidgets('shows total log entries', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Total Log Entries'), findsOneWidget);
      expect(find.text('150.0K'), findsOneWidget);
    });

    testWidgets('shows service breakdown', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('By Service'), findsOneWidget);
      expect(find.text('api-gateway'), findsOneWidget);
      expect(find.text('auth-service'), findsOneWidget);
    });

    testWidgets('shows active policies count', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Active Policies'), findsOneWidget);
      expect(find.text('2'), findsAtLeastNWidgets(1));
    });
  });
}
