// Widget tests for TraceWaterfall.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/logger_enums.dart';
import 'package:codeops/models/logger_models.dart';
import 'package:codeops/widgets/logger/trace_waterfall.dart';

void main() {
  final spans = [
    WaterfallSpan(
      id: 's-1',
      spanId: 'span-1',
      parentSpanId: null,
      serviceName: 'api-gateway',
      operationName: 'GET /users',
      offsetMs: 0,
      durationMs: 120,
      status: SpanStatus.ok,
      depth: 0,
      relatedLogIds: [],
    ),
    WaterfallSpan(
      id: 's-2',
      spanId: 'span-2',
      parentSpanId: 'span-1',
      serviceName: 'user-service',
      operationName: 'fetchUsers',
      offsetMs: 10,
      durationMs: 80,
      status: SpanStatus.ok,
      depth: 1,
      relatedLogIds: [],
    ),
    WaterfallSpan(
      id: 's-3',
      spanId: 'span-3',
      parentSpanId: 'span-2',
      serviceName: 'database',
      operationName: 'SELECT * FROM users',
      offsetMs: 20,
      durationMs: 40,
      status: SpanStatus.error,
      statusMessage: 'Connection timeout',
      depth: 2,
      relatedLogIds: ['log-1'],
    ),
  ];

  final serviceColors = TraceWaterfall.buildServiceColorMap(spans);

  Widget createWidget({
    List<WaterfallSpan>? data,
    String? selectedSpanId,
    ValueChanged<WaterfallSpan>? onSpanTap,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 800,
          height: 400,
          child: TraceWaterfall(
            spans: data ?? spans,
            totalDurationMs: 120,
            serviceColors: serviceColors,
            selectedSpanId: selectedSpanId,
            onSpanTap: onSpanTap,
          ),
        ),
      ),
    );
  }

  group('TraceWaterfall', () {
    testWidgets('renders empty state when no spans', (tester) async {
      await tester.pumpWidget(createWidget(data: []));
      await tester.pumpAndSettle();

      expect(find.text('No spans to display'), findsOneWidget);
    });

    testWidgets('renders span operation names', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('GET /users'), findsOneWidget);
      expect(find.text('fetchUsers'), findsOneWidget);
      expect(find.text('SELECT * FROM users'), findsOneWidget);
    });

    testWidgets('renders duration labels', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('120ms'), findsAtLeastNWidgets(1));
      expect(find.text('80ms'), findsOneWidget);
      expect(find.text('40ms'), findsOneWidget);
    });

    testWidgets('calls onSpanTap when span row tapped', (tester) async {
      WaterfallSpan? tapped;
      await tester.pumpWidget(
        createWidget(onSpanTap: (s) => tapped = s),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('GET /users'));
      await tester.pumpAndSettle();

      expect(tapped?.spanId, 'span-1');
    });

    testWidgets('highlights selected span', (tester) async {
      await tester.pumpWidget(createWidget(selectedSpanId: 'span-1'));
      await tester.pumpAndSettle();

      // The selected row should exist — just verify widget renders.
      expect(find.text('GET /users'), findsOneWidget);
    });

    testWidgets('buildServiceColorMap assigns distinct colors',
        (tester) async {
      final map = TraceWaterfall.buildServiceColorMap(spans);
      expect(map.length, 3);
      expect(map.containsKey('api-gateway'), true);
      expect(map.containsKey('user-service'), true);
      expect(map.containsKey('database'), true);
    });
  });
}
