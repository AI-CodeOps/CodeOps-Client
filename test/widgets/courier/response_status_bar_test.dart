// Widget tests for ResponseStatusBar.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/providers/courier_providers.dart';
import 'package:codeops/services/courier/http_execution_service.dart';
import 'package:codeops/widgets/courier/response_status_bar.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

Widget buildStatusBar({HttpExecutionResult? result}) {
  return ProviderScope(
    overrides: [
      executionResultProvider.overrideWith((ref) => result),
    ],
    child: const MaterialApp(
      home: Scaffold(
        body: SizedBox(width: 800, height: 40, child: ResponseStatusBar()),
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
  group('ResponseStatusBar', () {
    testWidgets('renders placeholder when no result', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildStatusBar());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('response_status_bar')), findsOneWidget);
      expect(find.byKey(const Key('status_placeholder')), findsOneWidget);
    });

    testWidgets('shows 200 status with green badge', (tester) async {
      setSize(tester);
      const result = HttpExecutionResult(
        statusCode: 200,
        statusText: 'OK',
        durationMs: 143,
        responseSize: 2456,
      );
      await tester.pumpWidget(buildStatusBar(result: result));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('status_badge')), findsOneWidget);
      expect(find.textContaining('200'), findsOneWidget);
    });

    testWidgets('shows response time', (tester) async {
      setSize(tester);
      const result = HttpExecutionResult(
        statusCode: 200,
        statusText: 'OK',
        durationMs: 256,
        responseSize: 1024,
      );
      await tester.pumpWidget(buildStatusBar(result: result));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('response_time')), findsOneWidget);
      expect(find.text('256 ms'), findsOneWidget);
    });

    testWidgets('shows formatted response size', (tester) async {
      setSize(tester);
      const result = HttpExecutionResult(
        statusCode: 200,
        statusText: 'OK',
        durationMs: 100,
        responseSize: 2560,
      );
      await tester.pumpWidget(buildStatusBar(result: result));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('response_size')), findsOneWidget);
      expect(find.text('2.5 KB'), findsOneWidget);
    });

    testWidgets('shows save dropdown', (tester) async {
      setSize(tester);
      const result = HttpExecutionResult(
        statusCode: 200,
        statusText: 'OK',
        durationMs: 100,
        responseSize: 100,
      );
      await tester.pumpWidget(buildStatusBar(result: result));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('save_response_dropdown')), findsOneWidget);
    });
  });
}
