/// Real-time progress aggregation for multi-agent QA jobs.
///
/// Tracks the phase, elapsed time, finding count, and latest output line
/// for each agent. Emits a [JobProgress] snapshot on a broadcast stream
/// whenever any agent's status changes or a live finding is reported.
/// The UI binds to [progressStream] to render a live dashboard.
library;

import 'dart:async';

import '../../models/enums.dart';
import '../agent/report_parser.dart';

// ---------------------------------------------------------------------------
// AgentPhase
// ---------------------------------------------------------------------------

/// Lifecycle phase of a single agent within a job.
enum AgentPhase {
  /// Agent is queued and waiting for a concurrency slot.
  queued,

  /// Agent is actively running as a subprocess.
  running,

  /// Agent has finished and its output is being parsed.
  parsing,

  /// Agent completed successfully.
  completed,

  /// Agent encountered an error.
  failed,

  /// Agent exceeded its timeout and was killed.
  timedOut;

  /// Human-readable display label.
  String get displayName => switch (this) {
        AgentPhase.queued => 'Queued',
        AgentPhase.running => 'Running',
        AgentPhase.parsing => 'Parsing',
        AgentPhase.completed => 'Completed',
        AgentPhase.failed => 'Failed',
        AgentPhase.timedOut => 'Timed Out',
      };
}

// ---------------------------------------------------------------------------
// AgentProgressStatus
// ---------------------------------------------------------------------------

/// Current progress status of a single agent.
class AgentProgressStatus {
  /// The type of agent this status describes.
  final AgentType agentType;

  /// The agent's current lifecycle phase.
  final AgentPhase phase;

  /// Wall-clock time elapsed since the agent was started.
  final Duration elapsed;

  /// Number of findings parsed so far, or `null` if not yet available.
  final int? findingsCount;

  /// The most recent line of stdout output, or `null` if none received.
  final String? lastOutputLine;

  /// Creates an [AgentProgressStatus].
  const AgentProgressStatus({
    required this.agentType,
    required this.phase,
    required this.elapsed,
    this.findingsCount,
    this.lastOutputLine,
  });
}

// ---------------------------------------------------------------------------
// LiveFinding
// ---------------------------------------------------------------------------

/// A finding detected in real time during agent execution.
///
/// These are surfaced to the UI before the full Vera consolidation pass
/// so users can see issues as they are discovered.
class LiveFinding {
  /// The agent that detected this finding.
  final AgentType agentType;

  /// Severity of the finding.
  final Severity severity;

  /// Short title describing the issue.
  final String title;

  /// Timestamp when the finding was first detected.
  final DateTime detectedAt;

  /// Creates a [LiveFinding].
  const LiveFinding({
    required this.agentType,
    required this.severity,
    required this.title,
    required this.detectedAt,
  });
}

// ---------------------------------------------------------------------------
// JobProgress
// ---------------------------------------------------------------------------

/// An immutable snapshot of overall job progress across all agents.
class JobProgress {
  /// Per-agent status keyed by [AgentType].
  final Map<AgentType, AgentProgressStatus> agentStatuses;

  /// Live findings detected so far, in discovery order.
  final List<LiveFinding> liveFindings;

  /// Number of agents that have reached a terminal phase.
  final int completedCount;

  /// Total number of agents in the job.
  final int totalCount;

  /// Wall-clock time elapsed since the job started.
  final Duration elapsed;

  /// Creates a [JobProgress] snapshot.
  const JobProgress({
    required this.agentStatuses,
    required this.liveFindings,
    required this.completedCount,
    required this.totalCount,
    required this.elapsed,
  });

  /// Completion percentage as a value between 0.0 and 1.0.
  ///
  /// Returns 1.0 when [totalCount] is zero to avoid division by zero.
  double get percentComplete =>
      totalCount == 0 ? 1.0 : completedCount / totalCount;
}

// ---------------------------------------------------------------------------
// ProgressAggregator
// ---------------------------------------------------------------------------

/// Aggregates real-time progress from multiple agents into a unified stream.
///
/// The UI layer subscribes to [progressStream] to receive [JobProgress]
/// snapshots. Service-layer code calls [updateAgentStatus] and
/// [reportLiveFinding] as events arrive from the dispatcher and monitor.
class ProgressAggregator {
  final StreamController<JobProgress> _controller =
      StreamController<JobProgress>.broadcast();

  final Map<AgentType, AgentProgressStatus> _agentStatuses = {};
  final List<LiveFinding> _liveFindings = [];
  final Stopwatch _stopwatch = Stopwatch();
  int _totalCount = 0;

  /// Broadcast stream of [JobProgress] snapshots.
  ///
  /// A new snapshot is emitted each time [updateAgentStatus] or
  /// [reportLiveFinding] is called.
  Stream<JobProgress> get progressStream => _controller.stream;

  /// Returns the current progress snapshot without waiting for a stream event.
  JobProgress get currentProgress => _buildSnapshot();

  /// Updates the status of a single agent and emits a new snapshot.
  ///
  /// [agentType] identifies which agent to update.
  /// [status] is the new progress status for that agent.
  void updateAgentStatus(AgentType agentType, AgentProgressStatus status) {
    _agentStatuses[agentType] = status;
    _emit();
  }

  /// Records a live finding and emits a new snapshot.
  ///
  /// [agentType] is the agent that discovered the finding.
  /// [finding] is the parsed finding to surface in real time.
  void reportLiveFinding(AgentType agentType, ParsedFinding finding) {
    _liveFindings.add(LiveFinding(
      agentType: agentType,
      severity: finding.severity,
      title: finding.title,
      detectedAt: DateTime.now(),
    ));
    _emit();
  }

  /// Resets all internal state for a new job run.
  ///
  /// [agents] is the list of agent types that will participate in the job.
  /// Each agent is initialized to [AgentPhase.queued] with zero elapsed time.
  /// The elapsed stopwatch is restarted from zero.
  void reset(List<AgentType> agents) {
    _agentStatuses.clear();
    _liveFindings.clear();
    _totalCount = agents.length;

    for (final agentType in agents) {
      _agentStatuses[agentType] = AgentProgressStatus(
        agentType: agentType,
        phase: AgentPhase.queued,
        elapsed: Duration.zero,
      );
    }

    _stopwatch
      ..reset()
      ..start();

    _emit();
  }

  /// Releases resources held by this aggregator.
  ///
  /// Stops the elapsed stopwatch and closes the stream controller.
  /// After calling [dispose], no further snapshots will be emitted.
  void dispose() {
    _stopwatch.stop();
    _controller.close();
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Builds an immutable snapshot from the current internal state.
  JobProgress _buildSnapshot() {
    final terminalPhases = {
      AgentPhase.completed,
      AgentPhase.failed,
      AgentPhase.timedOut,
    };

    final completedCount = _agentStatuses.values
        .where((s) => terminalPhases.contains(s.phase))
        .length;

    return JobProgress(
      agentStatuses: Map.unmodifiable(_agentStatuses),
      liveFindings: List.unmodifiable(_liveFindings),
      completedCount: completedCount,
      totalCount: _totalCount,
      elapsed: _stopwatch.elapsed,
    );
  }

  /// Emits a fresh [JobProgress] snapshot to the stream.
  void _emit() {
    if (!_controller.isClosed) {
      _controller.add(_buildSnapshot());
    }
  }
}
