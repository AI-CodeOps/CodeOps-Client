// Widget tests for ResponseViewer.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/providers/courier_providers.dart';
import 'package:codeops/providers/courier_ui_providers.dart';
import 'package:codeops/services/courier/http_execution_service.dart';
import 'package:codeops/widgets/courier/response_viewer.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

Widget buildViewer({
  HttpExecutionResult? result,
  ExecutionState execState = const ExecutionState(),
}) {
  return ProviderScope(
    overrides: [
      executionResultProvider.overrideWith((ref) => result),
      executionStateProvider.overrideWith(
        (ref) {
          final n = ExecutionNotifier();
          if (execState.status == ExecutionStatus.running) n.setRunning();
          if (execState.status == ExecutionStatus.error) {
            n.setError(execState.error ?? 'Error');
          }
          if (execState.status == ExecutionStatus.done) n.setDone();
          return n;
        },
      ),
    ],
    child: const MaterialApp(
      home: Scaffold(
        body: SizedBox(width: 800, height: 600, child: ResponseViewer()),
      ),
    ),
  );
}

void setSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('ResponseViewer', () {
    testWidgets('renders with tab bar', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildViewer());
      await tester.pumpAndSettle();

      expect(find.byType(ResponseViewer), findsOneWidget);
      expect(find.byKey(const Key('response_tab_bar')), findsOneWidget);
    });

    testWidgets('shows empty state when no result', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildViewer());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('response_empty_state')), findsOneWidget);
      expect(find.text('Click Send to get a response'), findsOneWidget);
    });

    testWidgets('shows loading state when running', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildViewer(
        execState:
            const ExecutionState(status: ExecutionStatus.running),
      ));
      // Use pump() instead of pumpAndSettle() — CircularProgressIndicator
      // animates indefinitely, so pumpAndSettle will never settle.
      await tester.pump();

      expect(find.byKey(const Key('response_loading_state')), findsOneWidget);
      expect(find.text('Sending request...'), findsOneWidget);
    });

    testWidgets('shows error state with troubleshooting tip',
        (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildViewer(
        result: const HttpExecutionResult(
          durationMs: 0,
          error: 'Connection timed out',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('response_error_state')), findsOneWidget);
      expect(find.text('Connection timed out'), findsOneWidget);
      expect(find.byKey(const Key('error_tip')), findsOneWidget);
    });

    testWidgets('shows body tab with pretty view', (tester) async {
      setSize(tester);
      final json = jsonEncode({'name': 'test', 'id': 1});
      await tester.pumpWidget(buildViewer(
        result: HttpExecutionResult(
          statusCode: 200,
          statusText: 'OK',
          body: json,
          durationMs: 100,
          responseSize: json.length,
          responseHeaders: {'content-type': 'application/json'},
        ),
        execState: const ExecutionState(status: ExecutionStatus.done),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('response_body_tab')), findsOneWidget);
      expect(find.byKey(const Key('pretty_view')), findsOneWidget);
    });

    testWidgets('switches to raw view', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildViewer(
        result: const HttpExecutionResult(
          statusCode: 200,
          statusText: 'OK',
          body: 'plain text body',
          durationMs: 50,
          responseSize: 15,
        ),
        execState: const ExecutionState(status: ExecutionStatus.done),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('view_raw')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('raw_view')), findsOneWidget);
    });

    testWidgets('switches to preview view', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildViewer(
        result: const HttpExecutionResult(
          statusCode: 200,
          statusText: 'OK',
          body: '<html><body>Hello</body></html>',
          durationMs: 50,
          responseSize: 30,
          responseHeaders: {'content-type': 'text/html'},
        ),
        execState: const ExecutionState(status: ExecutionStatus.done),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('view_preview')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('preview_html')), findsOneWidget);
    });

    testWidgets('switches to visualize view with JSON array',
        (tester) async {
      setSize(tester);
      final jsonArray =
          jsonEncode([{'id': 1, 'name': 'Alice'}, {'id': 2, 'name': 'Bob'}]);
      await tester.pumpWidget(buildViewer(
        result: HttpExecutionResult(
          statusCode: 200,
          statusText: 'OK',
          body: jsonArray,
          durationMs: 50,
          responseSize: jsonArray.length,
          responseHeaders: {'content-type': 'application/json'},
        ),
        execState: const ExecutionState(status: ExecutionStatus.done),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('view_visualize')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('json_table')), findsOneWidget);
    });

    testWidgets('shows search field in body toolbar', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildViewer(
        result: const HttpExecutionResult(
          statusCode: 200,
          statusText: 'OK',
          body: '{"data": "test"}',
          durationMs: 50,
          responseSize: 16,
        ),
        execState: const ExecutionState(status: ExecutionStatus.done),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('body_search_field')), findsOneWidget);
    });

    testWidgets('word wrap toggle exists', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildViewer(
        result: const HttpExecutionResult(
          statusCode: 200,
          statusText: 'OK',
          body: 'test',
          durationMs: 50,
          responseSize: 4,
        ),
        execState: const ExecutionState(status: ExecutionStatus.done),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('word_wrap_toggle')), findsOneWidget);
    });

    testWidgets('copy body button exists', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildViewer(
        result: const HttpExecutionResult(
          statusCode: 200,
          statusText: 'OK',
          body: 'copy me',
          durationMs: 50,
          responseSize: 7,
        ),
        execState: const ExecutionState(status: ExecutionStatus.done),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('copy_body_button')), findsOneWidget);
    });
  });
}
