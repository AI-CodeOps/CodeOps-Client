// Widget tests for AnomalyReportPanel.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/logger_models.dart';
import 'package:codeops/widgets/logger/anomaly_report_panel.dart';

void main() {
  final now = DateTime.utc(2026, 1, 15, 10, 0);

  final anomalyCheck = AnomalyCheckResponse(
    serviceName: 'api-gateway',
    metricName: 'cpu_usage',
    currentValue: 95.0,
    baselineValue: 45.0,
    standardDeviation: 10.0,
    deviationThreshold: 2.0,
    zScore: 5.0,
    isAnomaly: true,
    direction: 'above',
    checkedAt: now,
  );

  final normalCheck = AnomalyCheckResponse(
    serviceName: 'auth-service',
    metricName: 'memory_usage',
    currentValue: 50.0,
    baselineValue: 48.0,
    standardDeviation: 8.0,
    deviationThreshold: 2.0,
    zScore: 0.25,
    isAnomaly: false,
    direction: 'above',
    checkedAt: now,
  );

  final report = AnomalyReportResponse(
    teamId: 'team-1',
    generatedAt: now,
    totalBaselines: 2,
    anomaliesDetected: 1,
    anomalies: [anomalyCheck],
    allChecks: [anomalyCheck, normalCheck],
  );

  Widget createWidget({AnomalyReportResponse? data}) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 500,
          height: 400,
          child: AnomalyReportPanel(report: data ?? report),
        ),
      ),
    );
  }

  group('AnomalyReportPanel', () {
    testWidgets('renders summary chips', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Baselines: '), findsOneWidget);
      expect(find.text('Anomalies: '), findsOneWidget);
      expect(find.text('Checks: '), findsOneWidget);
    });

    testWidgets('shows anomaly status badges', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('ANOMALY'), findsOneWidget);
      expect(find.text('NORMAL'), findsOneWidget);
    });

    testWidgets('shows service and metric names', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(
        find.text('api-gateway / cpu_usage'),
        findsOneWidget,
      );
      expect(
        find.text('auth-service / memory_usage'),
        findsOneWidget,
      );
    });

    testWidgets('shows z-score values', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('z=5.00'), findsOneWidget);
      expect(find.text('z=0.25'), findsOneWidget);
    });
  });
}
