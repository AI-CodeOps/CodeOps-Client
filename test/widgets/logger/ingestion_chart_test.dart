// Widget tests for IngestionChart.
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/logger_models.dart';
import 'package:codeops/widgets/logger/ingestion_chart.dart';

void main() {
  final now = DateTime.utc(2026, 1, 15, 10, 0);

  final usage = StorageUsageResponse(
    totalLogEntries: 150000,
    totalMetricDataPoints: 50000,
    totalTraceSpans: 25000,
    logEntriesByService: {
      'api-gateway': 80000,
      'auth-service': 50000,
      'user-service': 20000,
    },
    logEntriesByLevel: {'INFO': 100000, 'ERROR': 30000, 'WARN': 20000},
    activeRetentionPolicies: 1,
    oldestLogEntry: now.subtract(const Duration(days: 90)),
    newestLogEntry: now,
  );

  Widget createWidget({StorageUsageResponse? data}) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 800,
          height: 600,
          child: IngestionChart(usage: data ?? usage),
        ),
      ),
    );
  }

  group('IngestionChart', () {
    testWidgets('renders bar chart', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byType(BarChart), findsOneWidget);
    });

    testWidgets('shows entries by level heading', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Entries by Level'), findsOneWidget);
    });

    testWidgets('shows top sources section', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Top Sources by Volume'), findsOneWidget);
      expect(find.text('api-gateway'), findsOneWidget);
    });
  });
}
