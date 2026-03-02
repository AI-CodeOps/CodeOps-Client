// Widget tests for MetricBrowserTree.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/logger_enums.dart';
import 'package:codeops/models/logger_models.dart';
import 'package:codeops/widgets/logger/metric_browser_tree.dart';

void main() {
  final metrics = [
    MetricResponse(
      id: 'm-1',
      name: 'cpu_usage',
      metricType: MetricType.gauge,
      unit: 'percent',
      serviceName: 'api-gateway',
      teamId: 'team-1',
    ),
    MetricResponse(
      id: 'm-2',
      name: 'request_count',
      metricType: MetricType.counter,
      unit: 'requests',
      serviceName: 'api-gateway',
      teamId: 'team-1',
    ),
    MetricResponse(
      id: 'm-3',
      name: 'error_rate',
      metricType: MetricType.gauge,
      unit: 'percent',
      serviceName: 'auth-service',
      teamId: 'team-1',
    ),
    MetricResponse(
      id: 'm-4',
      name: 'latency_p99',
      metricType: MetricType.histogram,
      unit: 'ms',
      serviceName: 'auth-service',
      teamId: 'team-1',
    ),
  ];

  Widget createWidget({
    String? selectedId,
    ValueChanged<MetricResponse>? onSelect,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 280,
          height: 600,
          child: MetricBrowserTree(
            metrics: metrics,
            selectedId: selectedId,
            onSelect: onSelect ?? (_) {},
          ),
        ),
      ),
    );
  }

  group('MetricBrowserTree', () {
    testWidgets('renders metric list', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('cpu_usage'), findsOneWidget);
      expect(find.text('request_count'), findsOneWidget);
      expect(find.text('error_rate'), findsOneWidget);
      expect(find.text('latency_p99'), findsOneWidget);
    });

    testWidgets('groups metrics by service', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('api-gateway'), findsOneWidget);
      expect(find.text('auth-service'), findsOneWidget);
    });

    testWidgets('shows search field', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('filters metrics on search', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField),
        'cpu',
      );
      await tester.pumpAndSettle();

      expect(find.text('cpu_usage'), findsOneWidget);
      expect(find.text('request_count'), findsNothing);
      expect(find.text('error_rate'), findsNothing);
    });

    testWidgets('calls onSelect when metric tapped', (tester) async {
      MetricResponse? selected;
      await tester.pumpWidget(
        createWidget(onSelect: (m) => selected = m),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('cpu_usage'));
      await tester.pumpAndSettle();

      expect(selected?.id, 'm-1');
    });
  });
}
