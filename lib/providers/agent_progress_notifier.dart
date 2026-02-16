/// State notifier managing real-time agent progress for the active job.
///
/// Maintains a [Map] of [AgentProgress] keyed by agent run ID.
/// Updated by [JobOrchestrator] as dispatch, monitoring, and completion
/// events arrive. The UI watches derived providers to render agent cards.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/agent_progress.dart';
import '../models/agent_run.dart';
import '../models/enums.dart';
import '../services/logging/log_service.dart';

/// Manages real-time agent progress state for the active job.
///
/// Listens to [AgentDispatchEvent]s, process output, and [AgentRun] updates
/// to maintain a live map of agent progress keyed by agentRunId.
class AgentProgressNotifier extends StateNotifier<Map<String, AgentProgress>> {
  /// Creates an [AgentProgressNotifier] with empty initial state.
  AgentProgressNotifier() : super({});

  /// Initializes the progress map with agent runs when a job starts.
  ///
  /// Each agent is set to pending status with the given [maxTurns].
  /// [modelId] is the Claude model being used for this dispatch.
  void initializeAgents(
    List<AgentRun> agentRuns, {
    int maxTurns = 50,
    String? modelId,
  }) {
    final map = <String, AgentProgress>{};
    for (var i = 0; i < agentRuns.length; i++) {
      final run = agentRuns[i];
      map[run.id] = AgentProgress(
        agentRunId: run.id,
        agentType: run.agentType,
        status: AgentStatus.pending,
        maxTurns: maxTurns,
        queuePosition: i + 1,
        modelId: modelId,
      );
    }
    state = map;
    log.d('AgentProgressNotifier',
        'Initialized ${agentRuns.length} agents');
  }

  /// Marks an agent as started (status = running, sets startedAt).
  void markStarted(String agentRunId) {
    final current = state[agentRunId];
    if (current == null) return;
    state = {
      ...state,
      agentRunId: current.copyWith(
        status: AgentStatus.running,
        startedAt: DateTime.now(),
        queuePosition: 0,
      ),
    };
  }

  /// Marks an agent as completed with final results.
  void markCompleted(
    String agentRunId,
    AgentResult result, {
    int? score,
    int? findingsCount,
    int? criticalCount,
    int? highCount,
    int? mediumCount,
    int? lowCount,
  }) {
    final current = state[agentRunId];
    if (current == null) return;
    state = {
      ...state,
      agentRunId: current.copyWith(
        status: AgentStatus.completed,
        result: result,
        completedAt: DateTime.now(),
        progressPercent: 1.0,
        score: score,
        totalFindings: findingsCount ?? current.totalFindings,
        criticalCount: criticalCount ?? current.criticalCount,
        highCount: highCount ?? current.highCount,
        mediumCount: mediumCount ?? current.mediumCount,
        lowCount: lowCount ?? current.lowCount,
      ),
    };
  }

  /// Marks an agent as failed.
  void markFailed(String agentRunId, {String? error}) {
    final current = state[agentRunId];
    if (current == null) return;
    state = {
      ...state,
      agentRunId: current.copyWith(
        status: AgentStatus.failed,
        completedAt: DateTime.now(),
        errorMessage: error,
      ),
    };
  }

  /// Increments the finding count for a specific severity.
  void addFinding(String agentRunId, Severity severity) {
    final current = state[agentRunId];
    if (current == null) return;

    final updated = switch (severity) {
      Severity.critical => current.copyWith(
          criticalCount: current.criticalCount + 1,
          totalFindings: current.totalFindings + 1,
        ),
      Severity.high => current.copyWith(
          highCount: current.highCount + 1,
          totalFindings: current.totalFindings + 1,
        ),
      Severity.medium => current.copyWith(
          mediumCount: current.mediumCount + 1,
          totalFindings: current.totalFindings + 1,
        ),
      Severity.low => current.copyWith(
          lowCount: current.lowCount + 1,
          totalFindings: current.totalFindings + 1,
        ),
    };

    state = {...state, agentRunId: updated};
  }

  /// Updates the current activity text from process output parsing.
  void updateActivity(String agentRunId, String activity) {
    final current = state[agentRunId];
    if (current == null) return;
    state = {
      ...state,
      agentRunId: current.copyWith(currentActivity: activity),
    };
  }

  /// Updates progress from turn count or estimated completion.
  void updateProgress(
    String agentRunId, {
    int? currentTurn,
    double? progressPercent,
  }) {
    final current = state[agentRunId];
    if (current == null) return;

    final turn = currentTurn ?? current.currentTurn;
    final percent = progressPercent ??
        (current.maxTurns > 0 ? turn / current.maxTurns : 0.0);

    state = {
      ...state,
      agentRunId: current.copyWith(
        currentTurn: turn,
        progressPercent: percent.clamp(0.0, 1.0),
      ),
    };
  }

  /// Updates elapsed time for a running agent.
  void updateElapsed(String agentRunId, Duration elapsed) {
    final current = state[agentRunId];
    if (current == null) return;
    state = {
      ...state,
      agentRunId: current.copyWith(elapsed: elapsed),
    };
  }

  /// Appends an output line to the agent's output buffer.
  ///
  /// Keeps only the last 50 lines to prevent unbounded memory growth.
  void appendOutput(String agentRunId, String line) {
    final current = state[agentRunId];
    if (current == null) return;

    final lines = [...current.outputLines, line];
    final trimmed = lines.length > 50 ? lines.sublist(lines.length - 50) : lines;

    state = {
      ...state,
      agentRunId: current.copyWith(outputLines: trimmed),
    };
  }

  /// Increments the file count when a new file is analyzed.
  void incrementFilesAnalyzed(String agentRunId, String filePath) {
    final current = state[agentRunId];
    if (current == null) return;
    state = {
      ...state,
      agentRunId: current.copyWith(
        filesAnalyzed: current.filesAnalyzed + 1,
        lastFileAnalyzed: filePath,
      ),
    };
  }

  /// Updates queue positions for all pending agents.
  void updateQueuePositions() {
    var position = 1;
    final updated = Map<String, AgentProgress>.from(state);
    for (final entry in updated.entries) {
      if (entry.value.isQueued) {
        updated[entry.key] = entry.value.copyWith(queuePosition: position++);
      }
    }
    state = updated;
  }

  /// Clears all state (on job completion or navigation away).
  void reset() {
    state = {};
  }

  /// Finds the agent run ID for a given [AgentType].
  ///
  /// Returns `null` if no agent of that type exists.
  String? agentRunIdForType(AgentType agentType) {
    for (final entry in state.entries) {
      if (entry.value.agentType == agentType) return entry.key;
    }
    return null;
  }
}
