// Widget tests for TrapTestResults.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/logger_models.dart';
import 'package:codeops/widgets/logger/trap_test_results.dart';

void main() {
  final result = TrapTestResult(
    matchCount: 42,
    totalEvaluated: 1000,
    sampleMatchIds: [
      'abc12345-6789-0000-1111-222233334444',
      'def98765-4321-aaaa-bbbb-ccccddddeeee',
    ],
    evaluatedFrom: DateTime.utc(2026, 1, 1, 0, 0),
    evaluatedTo: DateTime.utc(2026, 1, 2, 0, 0),
    matchPercentage: 4.2,
  );

  Widget createWidget({TrapTestResult? testResult}) {
    return MaterialApp(
      home: Scaffold(
        body: TrapTestResults(result: testResult ?? result),
      ),
    );
  }

  group('TrapTestResults', () {
    testWidgets('renders header and match stats', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Test Results'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
      expect(find.text('1000'), findsOneWidget);
      expect(find.text('4.2%'), findsOneWidget);
    });

    testWidgets('renders stat labels', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Matches'), findsOneWidget);
      expect(find.text('Evaluated'), findsOneWidget);
      expect(find.text('Match Rate'), findsOneWidget);
    });

    testWidgets('renders sample match IDs', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Sample Match IDs'), findsOneWidget);
      // IDs are truncated to 8 chars + '...'.
      expect(find.text('abc12345...'), findsOneWidget);
      expect(find.text('def98765...'), findsOneWidget);
    });
  });
}
