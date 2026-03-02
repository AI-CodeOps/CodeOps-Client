// Widget tests for TraceDetailPage.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:codeops/models/logger_enums.dart';
import 'package:codeops/models/logger_models.dart';
import 'package:codeops/pages/logger/trace_detail_page.dart';
import 'package:codeops/providers/logger_providers.dart';

void main() {
  const correlationId = 'corr-abc-123';

  final waterfall = TraceWaterfallResponse(
    correlationId: correlationId,
    traceId: 'trace-xyz-789',
    totalDurationMs: 200,
    spanCount: 3,
    serviceCount: 2,
    hasErrors: true,
    spans: [
      WaterfallSpan(
        id: 's-1',
        spanId: 'span-1',
        parentSpanId: null,
        serviceName: 'api-gateway',
        operationName: 'GET /users',
        offsetMs: 0,
        durationMs: 200,
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
        durationMs: 150,
        status: SpanStatus.ok,
        depth: 1,
        relatedLogIds: [],
      ),
      WaterfallSpan(
        id: 's-3',
        spanId: 'span-3',
        parentSpanId: 'span-2',
        serviceName: 'user-service',
        operationName: 'queryDB',
        offsetMs: 20,
        durationMs: 80,
        status: SpanStatus.error,
        statusMessage: 'Connection refused',
        depth: 2,
        relatedLogIds: ['log-1'],
      ),
    ],
  );

  Widget createWidget({
    TraceWaterfallResponse? data,
    bool loading = false,
  }) {
    final router = GoRouter(
      initialLocation: '/logger/traces/$correlationId',
      routes: [
        GoRoute(
          path: '/logger',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: Scaffold(body: Center(child: Text('Dashboard'))),
          ),
        ),
        GoRoute(
          path: '/logger/viewer',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: Center(child: Text('Viewer')),
          ),
        ),
        GoRoute(
          path: '/logger/search',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: Center(child: Text('Search')),
          ),
        ),
        GoRoute(
          path: '/logger/traps',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: Center(child: Text('Traps')),
          ),
        ),
        GoRoute(
          path: '/logger/alerts',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: Center(child: Text('Alerts')),
          ),
        ),
        GoRoute(
          path: '/logger/alerts/channels',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: Center(child: Text('Channels')),
          ),
        ),
        GoRoute(
          path: '/logger/dashboards',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: Center(child: Text('Dashboards')),
          ),
        ),
        GoRoute(
          path: '/logger/metrics',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: Center(child: Text('Metrics')),
          ),
        ),
        GoRoute(
          path: '/logger/traces',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: Center(child: Text('Trace List')),
          ),
        ),
        GoRoute(
          path: '/logger/traces/:correlationId',
          pageBuilder: (context, state) => NoTransitionPage(
            child: Scaffold(
              body: TraceDetailPage(
                correlationId: state.pathParameters['correlationId']!,
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/logger/retention',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: Center(child: Text('Retention')),
          ),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        loggerTraceWaterfallProvider(correlationId).overrideWith((ref) {
          if (loading) {
            return Completer<TraceWaterfallResponse>().future;
          }
          return Future.value(data ?? waterfall);
        }),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('TraceDetailPage', () {
    testWidgets('renders toolbar with back button', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.textContaining('Trace'), findsAtLeastNWidgets(1));
    });

    testWidgets('renders summary bar with stats', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Duration: '), findsOneWidget);
      expect(find.text('200ms'), findsAtLeastNWidgets(1));
      expect(find.text('Spans: '), findsOneWidget);
      expect(find.text('Services: '), findsAtLeastNWidgets(1));
    });

    testWidgets('renders service color legend', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Services: '), findsAtLeastNWidgets(1));
      expect(find.text('api-gateway'), findsAtLeastNWidgets(1));
      expect(find.text('user-service'), findsAtLeastNWidgets(1));
    });

    testWidgets('renders span operation names in waterfall', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('GET /users'), findsOneWidget);
      expect(find.text('fetchUsers'), findsOneWidget);
      expect(find.text('queryDB'), findsOneWidget);
    });

    testWidgets('shows span detail panel on span tap', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('GET /users'));
      await tester.pumpAndSettle();

      expect(find.text('Span Detail'), findsOneWidget);
      expect(find.text('span-1'), findsOneWidget);
    });

    testWidgets('shows loading indicator while fetching', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget(loading: true));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error indicators for failed spans', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // The waterfall has hasErrors: true
      expect(find.text('Yes'), findsOneWidget);
    });
  });
}
