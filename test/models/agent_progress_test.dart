// Tests for AgentProgress model.
//
// Verifies computed properties, copyWith, and AgentProgressSummary.
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/agent_progress.dart';
import 'package:codeops/models/enums.dart';
import 'package:codeops/theme/colors.dart';

void main() {
  group('AgentProgress', () {
    test('isQueued returns true for pending status', () {
      const p = AgentProgress(
        agentRunId: 'r1',
        agentType: AgentType.security,
        status: AgentStatus.pending,
      );
      expect(p.isQueued, isTrue);
      expect(p.isRunning, isFalse);
      expect(p.isComplete, isFalse);
      expect(p.isFailed, isFalse);
    });

    test('isRunning returns true for running status', () {
      const p = AgentProgress(
        agentRunId: 'r1',
        agentType: AgentType.security,
        status: AgentStatus.running,
      );
      expect(p.isQueued, isFalse);
      expect(p.isRunning, isTrue);
      expect(p.isComplete, isFalse);
      expect(p.isFailed, isFalse);
    });

    test('isComplete returns true for completed status', () {
      const p = AgentProgress(
        agentRunId: 'r1',
        agentType: AgentType.security,
        status: AgentStatus.completed,
      );
      expect(p.isComplete, isTrue);
    });

    test('isFailed returns true for failed status', () {
      const p = AgentProgress(
        agentRunId: 'r1',
        agentType: AgentType.security,
        status: AgentStatus.failed,
      );
      expect(p.isFailed, isTrue);
    });

    test('progressColor returns error for failed status', () {
      const p = AgentProgress(
        agentRunId: 'r1',
        agentType: AgentType.security,
        status: AgentStatus.failed,
      );
      expect(p.progressColor, CodeOpsColors.error);
    });

    test('progressColor returns error for fail result', () {
      const p = AgentProgress(
        agentRunId: 'r1',
        agentType: AgentType.security,
        status: AgentStatus.completed,
        result: AgentResult.fail,
      );
      expect(p.progressColor, CodeOpsColors.error);
    });

    test('progressColor returns warning for warn result', () {
      const p = AgentProgress(
        agentRunId: 'r1',
        agentType: AgentType.security,
        status: AgentStatus.completed,
        result: AgentResult.warn,
      );
      expect(p.progressColor, CodeOpsColors.warning);
    });

    test('progressColor returns success for pass result', () {
      const p = AgentProgress(
        agentRunId: 'r1',
        agentType: AgentType.security,
        status: AgentStatus.completed,
        result: AgentResult.pass,
      );
      expect(p.progressColor, CodeOpsColors.success);
    });

    test('progressColor returns error when critical findings exist', () {
      const p = AgentProgress(
        agentRunId: 'r1',
        agentType: AgentType.security,
        status: AgentStatus.running,
        criticalCount: 1,
      );
      expect(p.progressColor, CodeOpsColors.error);
    });

    test('progressColor returns warning when high findings exist', () {
      const p = AgentProgress(
        agentRunId: 'r1',
        agentType: AgentType.security,
        status: AgentStatus.running,
        highCount: 2,
      );
      expect(p.progressColor, CodeOpsColors.warning);
    });

    test('progressColor returns primary when running with no findings', () {
      const p = AgentProgress(
        agentRunId: 'r1',
        agentType: AgentType.security,
        status: AgentStatus.running,
      );
      expect(p.progressColor, CodeOpsColors.primary);
    });

    test('agentColor returns the mapped color for the agent type', () {
      const p = AgentProgress(
        agentRunId: 'r1',
        agentType: AgentType.security,
        status: AgentStatus.running,
      );
      expect(p.agentColor, CodeOpsColors.agentTypeColors[AgentType.security]);
    });

    test('copyWith replaces specified fields', () {
      const original = AgentProgress(
        agentRunId: 'r1',
        agentType: AgentType.security,
        status: AgentStatus.pending,
        progressPercent: 0.0,
      );

      final updated = original.copyWith(
        status: AgentStatus.running,
        progressPercent: 0.5,
        currentTurn: 25,
      );

      expect(updated.agentRunId, 'r1');
      expect(updated.agentType, AgentType.security);
      expect(updated.status, AgentStatus.running);
      expect(updated.progressPercent, 0.5);
      expect(updated.currentTurn, 25);
    });

    test('copyWith preserves unspecified fields', () {
      const original = AgentProgress(
        agentRunId: 'r1',
        agentType: AgentType.codeQuality,
        status: AgentStatus.running,
        elapsed: Duration(minutes: 3),
        criticalCount: 2,
        modelId: 'test-model',
      );

      final updated = original.copyWith(progressPercent: 0.75);

      expect(updated.elapsed, const Duration(minutes: 3));
      expect(updated.criticalCount, 2);
      expect(updated.modelId, 'test-model');
    });

    test('default values are correct', () {
      const p = AgentProgress(
        agentRunId: 'r1',
        agentType: AgentType.security,
        status: AgentStatus.pending,
      );

      expect(p.elapsed, Duration.zero);
      expect(p.progressPercent, 0.0);
      expect(p.currentTurn, 0);
      expect(p.maxTurns, 50);
      expect(p.queuePosition, 0);
      expect(p.criticalCount, 0);
      expect(p.highCount, 0);
      expect(p.mediumCount, 0);
      expect(p.lowCount, 0);
      expect(p.totalFindings, 0);
      expect(p.filesAnalyzed, 0);
      expect(p.outputLines, isEmpty);
      expect(p.result, isNull);
      expect(p.startedAt, isNull);
      expect(p.completedAt, isNull);
      expect(p.currentActivity, isNull);
      expect(p.score, isNull);
      expect(p.modelId, isNull);
      expect(p.errorMessage, isNull);
    });
  });

  group('AgentProgressSummary', () {
    test('default values are all zero', () {
      const s = AgentProgressSummary();
      expect(s.total, 0);
      expect(s.running, 0);
      expect(s.queued, 0);
      expect(s.completed, 0);
      expect(s.failed, 0);
      expect(s.totalFindings, 0);
      expect(s.totalCritical, 0);
    });

    test('stores all provided values', () {
      const s = AgentProgressSummary(
        total: 12,
        running: 3,
        queued: 5,
        completed: 3,
        failed: 1,
        totalFindings: 42,
        totalCritical: 5,
      );
      expect(s.total, 12);
      expect(s.running, 3);
      expect(s.queued, 5);
      expect(s.completed, 3);
      expect(s.failed, 1);
      expect(s.totalFindings, 42);
      expect(s.totalCritical, 5);
    });
  });
}
