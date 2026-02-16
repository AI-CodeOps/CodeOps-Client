// Tests for AgentProgressNotifier.
//
// Verifies initialization, state transitions, and helper methods.
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/agent_run.dart';
import 'package:codeops/models/enums.dart';
import 'package:codeops/providers/agent_progress_notifier.dart';

void main() {
  late AgentProgressNotifier notifier;

  setUp(() {
    notifier = AgentProgressNotifier();
  });

  List<AgentRun> createRuns(int count) {
    return List.generate(count, (i) => AgentRun(
      id: 'run-$i',
      jobId: 'job-1',
      agentType: AgentType.values[i % AgentType.values.length],
      status: AgentStatus.pending,
    ));
  }

  group('AgentProgressNotifier', () {
    test('starts with empty state', () {
      expect(notifier.state, isEmpty);
    });

    test('initializeAgents populates map with correct count', () {
      final runs = createRuns(3);
      notifier.initializeAgents(runs, maxTurns: 30, modelId: 'test-model');

      expect(notifier.state.length, 3);
      expect(notifier.state['run-0'], isNotNull);
      expect(notifier.state['run-1'], isNotNull);
      expect(notifier.state['run-2'], isNotNull);
    });

    test('initializeAgents sets correct fields', () {
      final runs = createRuns(2);
      notifier.initializeAgents(runs, maxTurns: 25, modelId: 'claude-test');

      final first = notifier.state['run-0']!;
      expect(first.status, AgentStatus.pending);
      expect(first.maxTurns, 25);
      expect(first.modelId, 'claude-test');
      expect(first.queuePosition, 1);

      final second = notifier.state['run-1']!;
      expect(second.queuePosition, 2);
    });

    test('markStarted transitions agent to running', () {
      final runs = createRuns(1);
      notifier.initializeAgents(runs);

      notifier.markStarted('run-0');

      final agent = notifier.state['run-0']!;
      expect(agent.status, AgentStatus.running);
      expect(agent.startedAt, isNotNull);
      expect(agent.queuePosition, 0);
    });

    test('markStarted ignores unknown agent run ID', () {
      final runs = createRuns(1);
      notifier.initializeAgents(runs);

      notifier.markStarted('nonexistent');

      // State unchanged.
      expect(notifier.state.length, 1);
      expect(notifier.state['run-0']!.status, AgentStatus.pending);
    });

    test('markCompleted transitions to completed with results', () {
      final runs = createRuns(1);
      notifier.initializeAgents(runs);
      notifier.markStarted('run-0');

      notifier.markCompleted(
        'run-0',
        AgentResult.pass,
        score: 85,
        findingsCount: 5,
        criticalCount: 0,
        highCount: 1,
        mediumCount: 2,
        lowCount: 2,
      );

      final agent = notifier.state['run-0']!;
      expect(agent.status, AgentStatus.completed);
      expect(agent.result, AgentResult.pass);
      expect(agent.score, 85);
      expect(agent.totalFindings, 5);
      expect(agent.criticalCount, 0);
      expect(agent.highCount, 1);
      expect(agent.mediumCount, 2);
      expect(agent.lowCount, 2);
      expect(agent.progressPercent, 1.0);
      expect(agent.completedAt, isNotNull);
    });

    test('markFailed transitions to failed with error', () {
      final runs = createRuns(1);
      notifier.initializeAgents(runs);
      notifier.markStarted('run-0');

      notifier.markFailed('run-0', error: 'Timeout exceeded');

      final agent = notifier.state['run-0']!;
      expect(agent.status, AgentStatus.failed);
      expect(agent.errorMessage, 'Timeout exceeded');
      expect(agent.completedAt, isNotNull);
    });

    test('addFinding increments correct severity count', () {
      final runs = createRuns(1);
      notifier.initializeAgents(runs);
      notifier.markStarted('run-0');

      notifier.addFinding('run-0', Severity.critical);
      notifier.addFinding('run-0', Severity.critical);
      notifier.addFinding('run-0', Severity.high);
      notifier.addFinding('run-0', Severity.medium);
      notifier.addFinding('run-0', Severity.low);

      final agent = notifier.state['run-0']!;
      expect(agent.criticalCount, 2);
      expect(agent.highCount, 1);
      expect(agent.mediumCount, 1);
      expect(agent.lowCount, 1);
      expect(agent.totalFindings, 5);
    });

    test('updateActivity sets current activity text', () {
      final runs = createRuns(1);
      notifier.initializeAgents(runs);
      notifier.markStarted('run-0');

      notifier.updateActivity('run-0', 'Reading src/main.dart');

      expect(notifier.state['run-0']!.currentActivity,
          'Reading src/main.dart');
    });

    test('updateProgress sets turn and percentage', () {
      final runs = createRuns(1);
      notifier.initializeAgents(runs, maxTurns: 50);
      notifier.markStarted('run-0');

      notifier.updateProgress('run-0', currentTurn: 10);

      final agent = notifier.state['run-0']!;
      expect(agent.currentTurn, 10);
      expect(agent.progressPercent, closeTo(0.2, 0.01));
    });

    test('updateProgress clamps percentage to 0.0-1.0', () {
      final runs = createRuns(1);
      notifier.initializeAgents(runs, maxTurns: 10);
      notifier.markStarted('run-0');

      notifier.updateProgress('run-0', currentTurn: 15);

      expect(notifier.state['run-0']!.progressPercent, 1.0);
    });

    test('updateElapsed sets elapsed duration', () {
      final runs = createRuns(1);
      notifier.initializeAgents(runs);
      notifier.markStarted('run-0');

      notifier.updateElapsed('run-0', const Duration(minutes: 5));

      expect(notifier.state['run-0']!.elapsed,
          const Duration(minutes: 5));
    });

    test('appendOutput adds lines to output buffer', () {
      final runs = createRuns(1);
      notifier.initializeAgents(runs);
      notifier.markStarted('run-0');

      notifier.appendOutput('run-0', 'line 1');
      notifier.appendOutput('run-0', 'line 2');

      expect(notifier.state['run-0']!.outputLines, ['line 1', 'line 2']);
    });

    test('appendOutput trims to 50 lines', () {
      final runs = createRuns(1);
      notifier.initializeAgents(runs);
      notifier.markStarted('run-0');

      for (var i = 0; i < 60; i++) {
        notifier.appendOutput('run-0', 'line $i');
      }

      final lines = notifier.state['run-0']!.outputLines;
      expect(lines.length, 50);
      expect(lines.first, 'line 10');
      expect(lines.last, 'line 59');
    });

    test('incrementFilesAnalyzed increases count and sets path', () {
      final runs = createRuns(1);
      notifier.initializeAgents(runs);
      notifier.markStarted('run-0');

      notifier.incrementFilesAnalyzed('run-0', 'src/main.dart');
      notifier.incrementFilesAnalyzed('run-0', 'src/app.dart');

      final agent = notifier.state['run-0']!;
      expect(agent.filesAnalyzed, 2);
      expect(agent.lastFileAnalyzed, 'src/app.dart');
    });

    test('updateQueuePositions renumbers pending agents', () {
      final runs = createRuns(3);
      notifier.initializeAgents(runs);
      notifier.markStarted('run-0');

      notifier.updateQueuePositions();

      // run-0 is running, not pending.
      expect(notifier.state['run-0']!.queuePosition, 0);
      // run-1 and run-2 should be renumbered.
      expect(notifier.state['run-1']!.queuePosition, 1);
      expect(notifier.state['run-2']!.queuePosition, 2);
    });

    test('reset clears all state', () {
      final runs = createRuns(3);
      notifier.initializeAgents(runs);

      notifier.reset();

      expect(notifier.state, isEmpty);
    });

    test('agentRunIdForType finds correct ID', () {
      final runs = createRuns(3);
      notifier.initializeAgents(runs);

      final id = notifier.agentRunIdForType(runs[1].agentType);
      expect(id, 'run-1');
    });

    test('agentRunIdForType returns null for missing type', () {
      notifier.initializeAgents([]);

      final id = notifier.agentRunIdForType(AgentType.security);
      expect(id, isNull);
    });
  });
}
