/// Real-time progress view model for a single agent during job execution.
///
/// Combines data from [AgentRun] (server record), process monitoring
/// (stdout parsing), and progress aggregation into a unified view model
/// consumed by agent cards in the Job Progress page.
library;

import 'dart:ui';

import '../theme/colors.dart';
import 'enums.dart';

/// Real-time progress state for a single agent during job execution.
///
/// This is a UI view model, not a persisted entity. It is assembled by
/// [AgentProgressNotifier] from orchestration events and kept in memory
/// for the duration of the active job.
class AgentProgress {
  /// Server-assigned agent run UUID.
  final String agentRunId;

  /// The type of agent (security, codeQuality, etc.).
  final AgentType agentType;

  /// Current lifecycle status.
  final AgentStatus status;

  /// Result after completion (pass/warn/fail).
  final AgentResult? result;

  /// Timestamp when the agent started executing.
  final DateTime? startedAt;

  /// Timestamp when the agent completed.
  final DateTime? completedAt;

  /// Wall-clock time since the agent started.
  final Duration elapsed;

  /// Estimated progress as a value between 0.0 and 1.0.
  final double progressPercent;

  /// Current turn number within the Claude Code session.
  final int currentTurn;

  /// Maximum allowed turns for this agent.
  final int maxTurns;

  /// Queue position (0 = running, >0 = waiting in queue).
  final int queuePosition;

  /// Count of critical-severity findings discovered so far.
  final int criticalCount;

  /// Count of high-severity findings discovered so far.
  final int highCount;

  /// Count of medium-severity findings discovered so far.
  final int mediumCount;

  /// Count of low-severity findings discovered so far.
  final int lowCount;

  /// Total findings discovered so far.
  final int totalFindings;

  /// Human-readable description of current activity.
  final String? currentActivity;

  /// Last file path mentioned in agent output.
  final String? lastFileAnalyzed;

  /// Count of unique files the agent has processed.
  final int filesAnalyzed;

  /// Numeric score (0-100), provisional during execution, final on completion.
  final int? score;

  /// The Claude model identifier being used.
  final String? modelId;

  /// Raw output lines from the agent process (last N lines).
  final List<String> outputLines;

  /// Error message if the agent failed.
  final String? errorMessage;

  /// Creates an [AgentProgress] instance.
  const AgentProgress({
    required this.agentRunId,
    required this.agentType,
    required this.status,
    this.result,
    this.startedAt,
    this.completedAt,
    this.elapsed = Duration.zero,
    this.progressPercent = 0.0,
    this.currentTurn = 0,
    this.maxTurns = 50,
    this.queuePosition = 0,
    this.criticalCount = 0,
    this.highCount = 0,
    this.mediumCount = 0,
    this.lowCount = 0,
    this.totalFindings = 0,
    this.currentActivity,
    this.lastFileAnalyzed,
    this.filesAnalyzed = 0,
    this.score,
    this.modelId,
    this.outputLines = const [],
    this.errorMessage,
  });

  /// The progress bar color based on current state and findings.
  Color get progressColor {
    if (status == AgentStatus.failed) return CodeOpsColors.error;
    if (result == AgentResult.fail) return CodeOpsColors.error;
    if (result == AgentResult.warn) return CodeOpsColors.warning;
    if (result == AgentResult.pass) return CodeOpsColors.success;
    if (criticalCount > 0) return CodeOpsColors.error;
    if (highCount > 0) return CodeOpsColors.warning;
    return CodeOpsColors.primary;
  }

  /// The accent color for this agent type.
  Color get agentColor =>
      CodeOpsColors.agentTypeColors[agentType] ?? CodeOpsColors.primary;

  /// Whether the agent is waiting in the dispatch queue.
  bool get isQueued => status == AgentStatus.pending;

  /// Whether the agent is actively running.
  bool get isRunning => status == AgentStatus.running;

  /// Whether the agent completed (any result).
  bool get isComplete =>
      status == AgentStatus.completed;

  /// Whether the agent failed or errored.
  bool get isFailed => status == AgentStatus.failed;

  /// Creates a copy with the given fields replaced.
  AgentProgress copyWith({
    String? agentRunId,
    AgentType? agentType,
    AgentStatus? status,
    AgentResult? result,
    DateTime? startedAt,
    DateTime? completedAt,
    Duration? elapsed,
    double? progressPercent,
    int? currentTurn,
    int? maxTurns,
    int? queuePosition,
    int? criticalCount,
    int? highCount,
    int? mediumCount,
    int? lowCount,
    int? totalFindings,
    String? currentActivity,
    String? lastFileAnalyzed,
    int? filesAnalyzed,
    int? score,
    String? modelId,
    List<String>? outputLines,
    String? errorMessage,
  }) {
    return AgentProgress(
      agentRunId: agentRunId ?? this.agentRunId,
      agentType: agentType ?? this.agentType,
      status: status ?? this.status,
      result: result ?? this.result,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      elapsed: elapsed ?? this.elapsed,
      progressPercent: progressPercent ?? this.progressPercent,
      currentTurn: currentTurn ?? this.currentTurn,
      maxTurns: maxTurns ?? this.maxTurns,
      queuePosition: queuePosition ?? this.queuePosition,
      criticalCount: criticalCount ?? this.criticalCount,
      highCount: highCount ?? this.highCount,
      mediumCount: mediumCount ?? this.mediumCount,
      lowCount: lowCount ?? this.lowCount,
      totalFindings: totalFindings ?? this.totalFindings,
      currentActivity: currentActivity ?? this.currentActivity,
      lastFileAnalyzed: lastFileAnalyzed ?? this.lastFileAnalyzed,
      filesAnalyzed: filesAnalyzed ?? this.filesAnalyzed,
      score: score ?? this.score,
      modelId: modelId ?? this.modelId,
      outputLines: outputLines ?? this.outputLines,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Aggregate statistics across all agents in a job.
class AgentProgressSummary {
  /// Total number of agents.
  final int total;

  /// Number of agents currently running.
  final int running;

  /// Number of agents waiting in the queue.
  final int queued;

  /// Number of agents that completed (any result).
  final int completed;

  /// Number of agents that failed.
  final int failed;

  /// Total findings across all agents.
  final int totalFindings;

  /// Total critical findings across all agents.
  final int totalCritical;

  /// Creates an [AgentProgressSummary].
  const AgentProgressSummary({
    this.total = 0,
    this.running = 0,
    this.queued = 0,
    this.completed = 0,
    this.failed = 0,
    this.totalFindings = 0,
    this.totalCritical = 0,
  });
}
