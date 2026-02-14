// Tests for ProgressAggregator.
//
// Verifies agent status tracking, live finding accumulation, progress
// percentage calculation, stream emission, and lifecycle management.
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/enums.dart';
import 'package:codeops/services/agent/report_parser.dart';
import 'package:codeops/services/orchestration/progress_aggregator.dart';

void main() {
  late ProgressAggregator aggregator;

  setUp(() {
    aggregator = ProgressAggregator();
  });

  tearDown(() {
    aggregator.dispose();
  });

  // -----------------------------------------------------------------------
  // Helpers
  // -----------------------------------------------------------------------

  /// Creates an [AgentProgressStatus] with sensible defaults.
  AgentProgressStatus makeStatus(
    AgentType agentType, {
    AgentPhase phase = AgentPhase.running,
    Duration elapsed = Duration.zero,
    int? findingsCount,
    String? lastOutputLine,
  }) {
    return AgentProgressStatus(
      agentType: agentType,
      phase: phase,
      elapsed: elapsed,
      findingsCount: findingsCount,
      lastOutputLine: lastOutputLine,
    );
  }

  /// Creates a minimal [ParsedFinding] for testing.
  ParsedFinding makeFinding({
    Severity severity = Severity.medium,
    String title = 'Test finding',
  }) {
    return ParsedFinding(
      severity: severity,
      title: title,
    );
  }

  // -----------------------------------------------------------------------
  // reset
  // -----------------------------------------------------------------------

  group('reset', () {
    test('initializes all agents to queued phase', () {
      final agents = [
        AgentType.security,
        AgentType.codeQuality,
        AgentType.buildHealth,
      ];

      aggregator.reset(agents);

      final progress = aggregator.currentProgress;
      expect(progress.agentStatuses.length, 3);
      expect(progress.totalCount, 3);

      for (final agentType in agents) {
        final status = progress.agentStatuses[agentType];
        expect(status, isNotNull, reason: '$agentType should be present');
        expect(status!.phase, AgentPhase.queued);
        expect(status.agentType, agentType);
        expect(status.elapsed, Duration.zero);
      }
    });

    test('clears previous state', () {
      // First run with 3 agents and a live finding.
      aggregator.reset([
        AgentType.security,
        AgentType.codeQuality,
        AgentType.buildHealth,
      ]);
      aggregator.updateAgentStatus(
        AgentType.security,
        makeStatus(AgentType.security, phase: AgentPhase.completed),
      );
      aggregator.reportLiveFinding(
        AgentType.security,
        makeFinding(severity: Severity.high, title: 'SQL injection'),
      );

      // Verify state accumulated.
      var progress = aggregator.currentProgress;
      expect(progress.liveFindings, hasLength(1));
      expect(progress.completedCount, 1);

      // Reset with a different set of agents.
      aggregator.reset([AgentType.performance, AgentType.documentation]);

      progress = aggregator.currentProgress;
      expect(progress.agentStatuses.length, 2);
      expect(progress.totalCount, 2);
      expect(progress.liveFindings, isEmpty);
      expect(progress.completedCount, 0);

      // Previous agents should be gone.
      expect(progress.agentStatuses.containsKey(AgentType.security), isFalse);
      expect(
          progress.agentStatuses.containsKey(AgentType.codeQuality), isFalse);

      // New agents should be queued.
      expect(progress.agentStatuses[AgentType.performance]!.phase,
          AgentPhase.queued);
      expect(progress.agentStatuses[AgentType.documentation]!.phase,
          AgentPhase.queued);
    });
  });

  // -----------------------------------------------------------------------
  // updateAgentStatus
  // -----------------------------------------------------------------------

  group('updateAgentStatus', () {
    test('updates specific agent', () {
      aggregator.reset([AgentType.security, AgentType.codeQuality]);

      aggregator.updateAgentStatus(
        AgentType.security,
        makeStatus(
          AgentType.security,
          phase: AgentPhase.running,
          elapsed: const Duration(seconds: 5),
          lastOutputLine: 'Scanning...',
        ),
      );

      final progress = aggregator.currentProgress;
      final securityStatus = progress.agentStatuses[AgentType.security]!;
      expect(securityStatus.phase, AgentPhase.running);
      expect(securityStatus.elapsed, const Duration(seconds: 5));
      expect(securityStatus.lastOutputLine, 'Scanning...');

      // Other agent should remain unchanged.
      final cqStatus = progress.agentStatuses[AgentType.codeQuality]!;
      expect(cqStatus.phase, AgentPhase.queued);
    });

    test('emits snapshot on stream', () async {
      aggregator.reset([AgentType.security]);

      // Set up expectation before triggering.
      final future = aggregator.progressStream.first;

      aggregator.updateAgentStatus(
        AgentType.security,
        makeStatus(AgentType.security, phase: AgentPhase.running),
      );

      final snapshot = await future;
      expect(snapshot, isA<JobProgress>());
      expect(
          snapshot.agentStatuses[AgentType.security]!.phase, AgentPhase.running);
    });
  });

  // -----------------------------------------------------------------------
  // reportLiveFinding
  // -----------------------------------------------------------------------

  group('reportLiveFinding', () {
    test('adds to liveFindings list', () {
      aggregator.reset([AgentType.security]);

      aggregator.reportLiveFinding(
        AgentType.security,
        makeFinding(severity: Severity.critical, title: 'XSS vulnerability'),
      );
      aggregator.reportLiveFinding(
        AgentType.security,
        makeFinding(severity: Severity.low, title: 'Missing header'),
      );

      final progress = aggregator.currentProgress;
      expect(progress.liveFindings, hasLength(2));

      expect(progress.liveFindings[0].agentType, AgentType.security);
      expect(progress.liveFindings[0].severity, Severity.critical);
      expect(progress.liveFindings[0].title, 'XSS vulnerability');
      expect(progress.liveFindings[0].detectedAt, isA<DateTime>());

      expect(progress.liveFindings[1].severity, Severity.low);
      expect(progress.liveFindings[1].title, 'Missing header');
    });

    test('emits snapshot on stream', () async {
      aggregator.reset([AgentType.codeQuality]);

      final future = aggregator.progressStream.first;

      aggregator.reportLiveFinding(
        AgentType.codeQuality,
        makeFinding(title: 'Unused import'),
      );

      final snapshot = await future;
      expect(snapshot.liveFindings, hasLength(1));
      expect(snapshot.liveFindings.first.title, 'Unused import');
    });
  });

  // -----------------------------------------------------------------------
  // percentComplete
  // -----------------------------------------------------------------------

  group('percentComplete', () {
    test('0 of 3 completed = 0.0', () {
      aggregator.reset([
        AgentType.security,
        AgentType.codeQuality,
        AgentType.buildHealth,
      ]);

      final progress = aggregator.currentProgress;
      expect(progress.percentComplete, 0.0);
    });

    test('1 of 3 completed = ~0.33', () {
      aggregator.reset([
        AgentType.security,
        AgentType.codeQuality,
        AgentType.buildHealth,
      ]);

      aggregator.updateAgentStatus(
        AgentType.security,
        makeStatus(AgentType.security, phase: AgentPhase.completed),
      );

      final progress = aggregator.currentProgress;
      expect(progress.percentComplete, closeTo(1 / 3, 0.01));
    });

    test('all completed = 1.0', () {
      aggregator.reset([
        AgentType.security,
        AgentType.codeQuality,
        AgentType.buildHealth,
      ]);

      aggregator.updateAgentStatus(
        AgentType.security,
        makeStatus(AgentType.security, phase: AgentPhase.completed),
      );
      aggregator.updateAgentStatus(
        AgentType.codeQuality,
        makeStatus(AgentType.codeQuality, phase: AgentPhase.completed),
      );
      aggregator.updateAgentStatus(
        AgentType.buildHealth,
        makeStatus(AgentType.buildHealth, phase: AgentPhase.completed),
      );

      final progress = aggregator.currentProgress;
      expect(progress.percentComplete, 1.0);
    });

    test('zero total = 1.0 (avoid division by zero)', () {
      aggregator.reset([]);

      final progress = aggregator.currentProgress;
      expect(progress.totalCount, 0);
      expect(progress.percentComplete, 1.0);
    });
  });

  // -----------------------------------------------------------------------
  // currentProgress (immutable snapshot)
  // -----------------------------------------------------------------------

  group('currentProgress', () {
    test('returns immutable snapshot', () {
      aggregator.reset([AgentType.security]);

      final snapshot = aggregator.currentProgress;

      // The agentStatuses map should be unmodifiable.
      expect(
        () => snapshot.agentStatuses[AgentType.codeQuality] =
            makeStatus(AgentType.codeQuality),
        throwsA(isA<UnsupportedError>()),
      );

      // The liveFindings list should be unmodifiable.
      expect(
        () => snapshot.liveFindings.add(LiveFinding(
          agentType: AgentType.security,
          severity: Severity.low,
          title: 'nope',
          detectedAt: DateTime.now(),
        )),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });

  // -----------------------------------------------------------------------
  // dispose
  // -----------------------------------------------------------------------

  group('dispose', () {
    test('closes stream', () async {
      // Create a fresh aggregator for this test so tearDown does not
      // double-dispose.
      final localAggregator = ProgressAggregator();
      localAggregator.reset([AgentType.security]);

      // Subscribe to the broadcast stream BEFORE triggering further events.
      final streamDone = localAggregator.progressStream.toList();

      // Emit one more event so toList() captures it.
      localAggregator.updateAgentStatus(
        AgentType.security,
        makeStatus(AgentType.security, phase: AgentPhase.running),
      );

      localAggregator.dispose();

      // toList() completes when the stream closes, meaning dispose worked.
      final events = await streamDone;
      expect(events, hasLength(1));
    });
  });

  // -----------------------------------------------------------------------
  // completedCount — terminal phase detection
  // -----------------------------------------------------------------------

  group('completedCount', () {
    test('counts completed, failed, timedOut as terminal', () {
      aggregator.reset([
        AgentType.security,
        AgentType.codeQuality,
        AgentType.buildHealth,
        AgentType.performance,
        AgentType.documentation,
      ]);

      // completed — terminal
      aggregator.updateAgentStatus(
        AgentType.security,
        makeStatus(AgentType.security, phase: AgentPhase.completed),
      );

      // failed — terminal
      aggregator.updateAgentStatus(
        AgentType.codeQuality,
        makeStatus(AgentType.codeQuality, phase: AgentPhase.failed),
      );

      // timedOut — terminal
      aggregator.updateAgentStatus(
        AgentType.buildHealth,
        makeStatus(AgentType.buildHealth, phase: AgentPhase.timedOut),
      );

      // running — NOT terminal
      aggregator.updateAgentStatus(
        AgentType.performance,
        makeStatus(AgentType.performance, phase: AgentPhase.running),
      );

      // parsing — NOT terminal
      aggregator.updateAgentStatus(
        AgentType.documentation,
        makeStatus(AgentType.documentation, phase: AgentPhase.parsing),
      );

      final progress = aggregator.currentProgress;
      expect(progress.completedCount, 3);
      expect(progress.totalCount, 5);
      expect(progress.percentComplete, closeTo(3 / 5, 0.01));
    });
  });
}
