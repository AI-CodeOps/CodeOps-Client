// Widget tests for ResponseTestResultsTab.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/services/courier/script_engine.dart';
import 'package:codeops/widgets/courier/response_test_results_tab.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

Widget buildTestResults({List<TestResult> results = const []}) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 800,
        height: 600,
        child: ResponseTestResultsTab(results: results),
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
  group('ResponseTestResultsTab', () {
    testWidgets('shows empty message when no results', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildTestResults());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('test_results_empty')), findsOneWidget);
    });

    testWidgets('shows summary bar with pass count', (tester) async {
      setSize(tester);
      final results = [
        const TestResult(name: 'Status is 200', passed: true),
        const TestResult(name: 'Has body', passed: true),
        const TestResult(
          name: 'Fast response',
          passed: false,
          errorMessage: 'Expected < 100 but got 250',
        ),
      ];
      await tester.pumpWidget(buildTestResults(results: results));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('test_summary_bar')), findsOneWidget);
      expect(find.byKey(const Key('test_summary_text')), findsOneWidget);
      expect(find.text('2/3 tests passed'), findsOneWidget);
    });

    testWidgets('shows all-pass summary when all pass', (tester) async {
      setSize(tester);
      final results = [
        const TestResult(name: 'Test 1', passed: true),
        const TestResult(name: 'Test 2', passed: true),
      ];
      await tester.pumpWidget(buildTestResults(results: results));
      await tester.pumpAndSettle();

      expect(find.text('2/2 tests passed'), findsOneWidget);
    });

    testWidgets('displays passed and failed tests', (tester) async {
      setSize(tester);
      final results = [
        const TestResult(name: 'Status check', passed: true),
        const TestResult(
          name: 'Body check',
          passed: false,
          errorMessage: 'Missing property "user"',
        ),
      ];
      await tester.pumpWidget(buildTestResults(results: results));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('test_results_list')), findsOneWidget);
      expect(find.text('Status check'), findsOneWidget);
      expect(find.text('Body check'), findsOneWidget);
      expect(find.text('PASS'), findsOneWidget);
      expect(find.text('FAIL'), findsOneWidget);
    });

    testWidgets('shows error detail for failed test', (tester) async {
      setSize(tester);
      final results = [
        const TestResult(
          name: 'Schema check',
          passed: false,
          errorMessage: 'Missing property "id" in response',
        ),
      ];
      await tester.pumpWidget(buildTestResults(results: results));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('test_error_detail')), findsOneWidget);
      expect(
          find.text('Missing property "id" in response'), findsOneWidget);
    });
  });
}
