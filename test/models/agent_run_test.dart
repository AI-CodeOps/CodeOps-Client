// Tests for AgentRun model serialization.
import 'package:flutter_test/flutter_test.dart';
import 'package:codeops/models/agent_run.dart';
import 'package:codeops/models/enums.dart';

void main() {
  group('AgentRun', () {
    test('fromJson with all fields', () {
      final json = {
        'id': 'ar-1',
        'jobId': 'j-1',
        'agentType': 'TEST_COVERAGE',
        'status': 'COMPLETED',
        'result': 'WARN',
        'score': 72,
        'findingsCount': 5,
        'criticalCount': 0,
        'highCount': 1,
        'startedAt': '2025-01-15T10:00:00.000Z',
        'completedAt': '2025-01-15T10:05:00.000Z',
      };
      final run = AgentRun.fromJson(json);
      expect(run.agentType, AgentType.testCoverage);
      expect(run.status, AgentStatus.completed);
      expect(run.result, AgentResult.warn);
      expect(run.score, 72);
    });

    test('toJson round-trip', () {
      final run = AgentRun(
        id: 'ar1',
        jobId: 'j1',
        agentType: AgentType.performance,
        status: AgentStatus.running,
      );
      final json = run.toJson();
      expect(json['agentType'], 'PERFORMANCE');
      expect(json['status'], 'RUNNING');
      final restored = AgentRun.fromJson(json);
      expect(restored.agentType, AgentType.performance);
    });
  });
}
