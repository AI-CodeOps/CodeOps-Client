// Widget tests for SpanDetailPanel.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/logger_enums.dart';
import 'package:codeops/models/logger_models.dart';
import 'package:codeops/widgets/logger/span_detail_panel.dart';

void main() {
  final span = WaterfallSpan(
    id: 's-1',
    spanId: 'span-abc-123',
    parentSpanId: 'span-parent-1',
    serviceName: 'api-gateway',
    operationName: 'GET /users',
    offsetMs: 10,
    durationMs: 120,
    status: SpanStatus.ok,
    statusMessage: 'Success',
    depth: 1,
    relatedLogIds: ['log-1', 'log-2'],
  );

  Widget createWidget({WaterfallSpan? data}) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 320,
          height: 600,
          child: SpanDetailPanel(span: data ?? span),
        ),
      ),
    );
  }

  group('SpanDetailPanel', () {
    testWidgets('renders header', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Span Detail'), findsOneWidget);
    });

    testWidgets('shows operation name and service', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('GET /users'), findsOneWidget);
      expect(find.text('api-gateway'), findsOneWidget);
    });

    testWidgets('shows duration and status', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('120ms'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);
    });

    testWidgets('shows span ID and parent span', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('span-abc-123'), findsOneWidget);
      expect(find.text('span-parent-1'), findsOneWidget);
    });

    testWidgets('shows related log IDs', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Related Log Entries'), findsOneWidget);
      expect(find.text('log-1'), findsOneWidget);
      expect(find.text('log-2'), findsOneWidget);
    });

    testWidgets('shows error status in red', (tester) async {
      final errorSpan = WaterfallSpan(
        id: 's-2',
        spanId: 'span-err',
        serviceName: 'auth-service',
        operationName: 'validateToken',
        offsetMs: 0,
        durationMs: 50,
        status: SpanStatus.error,
        statusMessage: 'Token expired',
        depth: 0,
        relatedLogIds: [],
      );
      await tester.pumpWidget(createWidget(data: errorSpan));
      await tester.pumpAndSettle();

      expect(find.text('Error'), findsOneWidget);
      expect(find.text('Token expired'), findsOneWidget);
    });
  });
}
