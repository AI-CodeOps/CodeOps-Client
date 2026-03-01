// Widget tests for LogEntryDetail.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:codeops/models/logger_enums.dart';
import 'package:codeops/models/logger_models.dart';
import 'package:codeops/widgets/logger/log_entry_detail.dart';

void main() {
  final basicEntry = LogEntryResponse(
    id: 'entry-1',
    sourceId: 'source-1234-abcd',
    sourceName: 'api-service',
    level: LogLevel.error,
    message: 'NullPointerException in UserService',
    timestamp: DateTime.utc(2026, 1, 15, 10, 30, 45),
    serviceName: 'api-service',
    teamId: 'team-1',
  );

  final fullEntry = LogEntryResponse(
    id: 'entry-2',
    sourceId: 'source-5678-efgh',
    sourceName: 'worker-service',
    level: LogLevel.fatal,
    message: 'OutOfMemoryError in batch processor',
    timestamp: DateTime.utc(2026, 1, 15, 11, 0, 0),
    serviceName: 'worker-service',
    correlationId: 'corr-abc-123',
    traceId: 'trace-xyz-789',
    spanId: 'span-111',
    loggerName: 'com.codeops.BatchProcessor',
    threadName: 'worker-thread-1',
    exceptionClass: 'java.lang.OutOfMemoryError',
    exceptionMessage: 'Java heap space',
    stackTrace: 'java.lang.OutOfMemoryError: Java heap space\n'
        '  at com.codeops.BatchProcessor.process(BatchProcessor.java:42)',
    customFields: '{"batchId":"batch-99","itemCount":5000}',
    hostName: 'worker-node-1',
    ipAddress: '10.0.0.5',
    teamId: 'team-1',
  );

  Widget createWidget(LogEntryResponse entry) {
    final router = GoRouter(
      initialLocation: '/detail',
      routes: [
        GoRoute(
          path: '/detail',
          pageBuilder: (context, state) => NoTransitionPage(
            child: Scaffold(
              body: SingleChildScrollView(
                child: LogEntryDetail(entry: entry),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/logger/traces/:correlationId',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: Scaffold(body: Center(child: Text('Trace Page'))),
          ),
        ),
      ],
    );
    return MaterialApp.router(routerConfig: router);
  }

  group('LogEntryDetail', () {
    testWidgets('shows message and metadata', (tester) async {
      await tester.pumpWidget(createWidget(basicEntry));
      await tester.pumpAndSettle();

      expect(find.text('NullPointerException in UserService'), findsOneWidget);
      expect(find.textContaining('api-service'), findsAtLeastNWidgets(1));
      expect(find.textContaining('2026-01-15'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows stack trace section when present', (tester) async {
      await tester.pumpWidget(createWidget(fullEntry));
      await tester.pumpAndSettle();

      expect(find.text('Stack Trace'), findsOneWidget);
      expect(
        find.textContaining('BatchProcessor.java:42'),
        findsOneWidget,
      );
    });

    testWidgets('shows custom fields section when present', (tester) async {
      await tester.pumpWidget(createWidget(fullEntry));
      await tester.pumpAndSettle();

      expect(find.text('Custom Fields'), findsOneWidget);
      expect(find.textContaining('batchId'), findsOneWidget);
    });

    testWidgets('shows correlation ID link when present', (tester) async {
      await tester.pumpWidget(createWidget(fullEntry));
      await tester.pumpAndSettle();

      expect(find.textContaining('Correlation: corr-abc-123'), findsOneWidget);
      expect(find.textContaining('Trace: trace-xyz-789'), findsOneWidget);
      expect(find.textContaining('Span: span-111'), findsOneWidget);
    });

    testWidgets('has copy button', (tester) async {
      await tester.pumpWidget(createWidget(basicEntry));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.copy), findsOneWidget);
      expect(find.byTooltip('Copy log entry'), findsOneWidget);
    });
  });
}
