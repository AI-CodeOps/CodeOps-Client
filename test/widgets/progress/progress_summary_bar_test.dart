import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/agent_progress.dart';
import 'package:codeops/widgets/progress/progress_summary_bar.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  group('ProgressSummaryBar', () {
    testWidgets('shows running count', (tester) async {
      await tester.pumpWidget(wrap(
        const ProgressSummaryBar(
          summary: AgentProgressSummary(
            total: 6,
            running: 2,
            queued: 3,
            completed: 1,
          ),
        ),
      ));

      expect(find.text('2'), findsOneWidget); // running count
      expect(find.text('Running'), findsOneWidget);
    });

    testWidgets('shows queued count', (tester) async {
      await tester.pumpWidget(wrap(
        const ProgressSummaryBar(
          summary: AgentProgressSummary(
            total: 6,
            running: 2,
            queued: 3,
            completed: 1,
          ),
        ),
      ));

      expect(find.text('3'), findsOneWidget); // queued count
      expect(find.text('Queued'), findsOneWidget);
    });

    testWidgets('shows completed count', (tester) async {
      await tester.pumpWidget(wrap(
        const ProgressSummaryBar(
          summary: AgentProgressSummary(
            total: 6,
            running: 0,
            queued: 0,
            completed: 5,
            failed: 1,
          ),
        ),
      ));

      expect(find.text('5'), findsOneWidget); // done count
      expect(find.text('Done'), findsOneWidget);
    });

    testWidgets('shows failed count when > 0', (tester) async {
      await tester.pumpWidget(wrap(
        const ProgressSummaryBar(
          summary: AgentProgressSummary(
            total: 3,
            running: 0,
            queued: 0,
            completed: 2,
            failed: 1,
          ),
        ),
      ));

      expect(find.text('Failed'), findsOneWidget);
    });

    testWidgets('hides failed chip when count is 0', (tester) async {
      await tester.pumpWidget(wrap(
        const ProgressSummaryBar(
          summary: AgentProgressSummary(
            total: 3,
            running: 1,
            queued: 1,
            completed: 1,
            failed: 0,
          ),
        ),
      ));

      expect(find.text('Failed'), findsNothing);
    });

    testWidgets('shows total findings count', (tester) async {
      await tester.pumpWidget(wrap(
        const ProgressSummaryBar(
          summary: AgentProgressSummary(
            total: 3,
            running: 1,
            totalFindings: 15,
          ),
        ),
      ));

      expect(find.text('15 findings'), findsOneWidget);
    });

    testWidgets('shows critical count badge when > 0', (tester) async {
      await tester.pumpWidget(wrap(
        const ProgressSummaryBar(
          summary: AgentProgressSummary(
            total: 3,
            totalFindings: 10,
            totalCritical: 3,
          ),
        ),
      ));

      expect(find.text('3 critical'), findsOneWidget);
    });

    testWidgets('shows progress fraction', (tester) async {
      await tester.pumpWidget(wrap(
        const ProgressSummaryBar(
          summary: AgentProgressSummary(
            total: 6,
            completed: 4,
            failed: 1,
          ),
        ),
      ));

      expect(find.text('5/6'), findsOneWidget);
    });
  });
}
