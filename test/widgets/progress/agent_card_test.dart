import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/agent_progress.dart';
import 'package:codeops/models/enums.dart';
import 'package:codeops/widgets/progress/agent_card.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  group('AgentCard', () {
    testWidgets('shows agent name and status badge', (tester) async {
      await tester.pumpWidget(wrap(
        const AgentCard(
          progress: AgentProgress(
            agentRunId: 'run-1',
            agentType: AgentType.security,
            status: AgentStatus.running,
            elapsed: Duration(minutes: 2),
          ),
        ),
      ));

      expect(find.text('Security'), findsOneWidget);
      expect(find.text('Running'), findsOneWidget);
    });

    testWidgets('shows elapsed time', (tester) async {
      await tester.pumpWidget(wrap(
        const AgentCard(
          progress: AgentProgress(
            agentRunId: 'run-2',
            agentType: AgentType.codeQuality,
            status: AgentStatus.completed,
            elapsed: Duration(minutes: 5, seconds: 30),
          ),
        ),
      ));

      expect(find.text('Code Quality'), findsOneWidget);
      expect(find.textContaining('5m'), findsOneWidget);
    });

    testWidgets('shows severity badges when findings exist', (tester) async {
      await tester.pumpWidget(wrap(
        const AgentCard(
          progress: AgentProgress(
            agentRunId: 'run-3',
            agentType: AgentType.testCoverage,
            status: AgentStatus.completed,
            elapsed: Duration(minutes: 3),
            totalFindings: 7,
            criticalCount: 2,
            highCount: 3,
            mediumCount: 1,
            lowCount: 1,
          ),
        ),
      ));

      expect(find.text('2 Critical'), findsOneWidget);
      expect(find.text('3 High'), findsOneWidget);
      expect(find.text('1 Medium'), findsOneWidget);
      expect(find.text('1 Low'), findsOneWidget);
    });

    testWidgets('hides severity badges when no findings', (tester) async {
      await tester.pumpWidget(wrap(
        const AgentCard(
          progress: AgentProgress(
            agentRunId: 'run-4',
            agentType: AgentType.security,
            status: AgentStatus.running,
          ),
        ),
      ));

      expect(find.textContaining('Critical'), findsNothing);
      expect(find.textContaining('High'), findsNothing);
    });

    testWidgets('shows progress bar when running', (tester) async {
      await tester.pumpWidget(wrap(
        const AgentCard(
          progress: AgentProgress(
            agentRunId: 'run-5',
            agentType: AgentType.security,
            status: AgentStatus.running,
            currentTurn: 10,
            maxTurns: 50,
            progressPercent: 0.2,
          ),
        ),
      ));

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('Turn 10/50'), findsOneWidget);
      expect(find.text('20%'), findsOneWidget);
    });

    testWidgets('hides progress bar when not running', (tester) async {
      await tester.pumpWidget(wrap(
        const AgentCard(
          progress: AgentProgress(
            agentRunId: 'run-6',
            agentType: AgentType.security,
            status: AgentStatus.completed,
          ),
        ),
      ));

      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('shows queue position when pending', (tester) async {
      await tester.pumpWidget(wrap(
        const AgentCard(
          progress: AgentProgress(
            agentRunId: 'run-7',
            agentType: AgentType.architecture,
            status: AgentStatus.pending,
            queuePosition: 3,
          ),
        ),
      ));

      expect(find.text('Queue position: 3'), findsOneWidget);
      expect(find.text('Queued'), findsOneWidget);
    });

    testWidgets('shows score when complete with score', (tester) async {
      await tester.pumpWidget(wrap(
        const AgentCard(
          progress: AgentProgress(
            agentRunId: 'run-8',
            agentType: AgentType.security,
            status: AgentStatus.completed,
            result: AgentResult.pass,
            score: 92,
            totalFindings: 3,
          ),
        ),
      ));

      expect(find.text('92'), findsOneWidget);
      expect(find.text('3 findings'), findsOneWidget);
    });

    testWidgets('shows error message when failed', (tester) async {
      await tester.pumpWidget(wrap(
        const AgentCard(
          progress: AgentProgress(
            agentRunId: 'run-9',
            agentType: AgentType.security,
            status: AgentStatus.failed,
            errorMessage: 'Process timed out',
          ),
        ),
      ));

      expect(find.text('Failed'), findsOneWidget);
      expect(find.text('Process timed out'), findsOneWidget);
    });

    testWidgets('shows current activity when running', (tester) async {
      await tester.pumpWidget(wrap(
        const AgentCard(
          progress: AgentProgress(
            agentRunId: 'run-10',
            agentType: AgentType.security,
            status: AgentStatus.running,
            elapsed: Duration(minutes: 1),
            currentActivity: 'Scanning files...',
          ),
        ),
      ));

      expect(find.text('Scanning files...'), findsOneWidget);
    });

    testWidgets('shows model ID when available', (tester) async {
      await tester.pumpWidget(wrap(
        const AgentCard(
          progress: AgentProgress(
            agentRunId: 'run-11',
            agentType: AgentType.security,
            status: AgentStatus.running,
            modelId: 'claude-sonnet-4-5',
          ),
        ),
      ));

      expect(find.text('claude-sonnet-4-5'), findsOneWidget);
    });

    testWidgets('expand toggle shows output terminal', (tester) async {
      await tester.pumpWidget(wrap(
        const AgentCard(
          progress: AgentProgress(
            agentRunId: 'run-12',
            agentType: AgentType.security,
            status: AgentStatus.running,
            outputLines: ['line 1', 'line 2', 'line 3'],
          ),
        ),
      ));

      // Terminal not visible initially.
      expect(find.text('line 1'), findsNothing);

      // Tap expand toggle.
      await tester.tap(find.byIcon(Icons.expand_more));
      await tester.pumpAndSettle();

      // Terminal now visible.
      expect(find.text('line 1'), findsOneWidget);
      expect(find.text('line 2'), findsOneWidget);
    });
  });

  group('AgentTypeMetadata', () {
    test('has metadata for every AgentType', () {
      for (final agentType in AgentType.values) {
        expect(AgentTypeMetadata.all.containsKey(agentType), isTrue,
            reason: '$agentType should have metadata');
      }
    });

    test('all entries have non-empty fields', () {
      for (final entry in AgentTypeMetadata.all.entries) {
        expect(entry.value.displayName, isNotEmpty,
            reason: '${entry.key} displayName');
        expect(entry.value.description, isNotEmpty,
            reason: '${entry.key} description');
      }
    });
  });
}
