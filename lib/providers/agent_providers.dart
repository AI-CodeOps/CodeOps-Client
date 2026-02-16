/// Riverpod providers for agent run data and orchestration state.
///
/// Exposes agent runs for a job, selected agent types, Claude Code
/// detector status, job progress streams, lifecycle events, and
/// dispatch configuration.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/agent_progress.dart';
import '../models/agent_run.dart';
import '../services/logging/log_service.dart';
import '../models/enums.dart';
import '../services/orchestration/agent_dispatcher.dart';
import '../services/orchestration/agent_monitor.dart';
import '../services/orchestration/bug_investigation_orchestrator.dart';
import '../services/orchestration/job_orchestrator.dart';
import '../services/orchestration/progress_aggregator.dart';
import '../services/orchestration/vera_manager.dart';
import '../services/agent/persona_manager.dart';
import '../services/agent/report_parser.dart';
import '../services/cloud/directive_api.dart';
import '../services/cloud/persona_api.dart';
import '../services/platform/claude_code_detector.dart';
import '../services/platform/process_manager.dart';
import '../utils/constants.dart';
import 'agent_progress_notifier.dart';
import 'auth_providers.dart';
import 'job_providers.dart';

/// Provides agent run data for a specific job.
final agentRunsProvider =
    FutureProvider.family<List<AgentRun>, String>((ref, jobId) async {
  log.d('AgentProviders', 'Loading agent runs for jobId=$jobId');
  final jobApi = ref.watch(jobApiProvider);
  return jobApi.getAgentRuns(jobId);
});

/// The set of selected agent types for a new job configuration.
///
/// Defaults to all agent types selected.
final selectedAgentTypesProvider = StateProvider<Set<AgentType>>(
  (ref) => AgentType.values.toSet(),
);

/// Provides [ClaudeCodeDetector] for checking CLI availability.
final claudeCodeDetectorProvider = Provider<ClaudeCodeDetector>(
  (ref) => ClaudeCodeDetector(),
);

/// Claude Code CLI availability status.
final claudeCodeStatusProvider =
    FutureProvider<ClaudeCodeStatus>((ref) async {
  log.d('AgentProviders', 'Validating Claude Code CLI status');
  final detector = ref.watch(claudeCodeDetectorProvider);
  return detector.validate();
});

/// Provides [ProcessManager] for subprocess lifecycle management.
final processManagerProvider = Provider<ProcessManager>(
  (ref) {
    final pm = ProcessManager();
    ref.onDispose(pm.dispose);
    return pm;
  },
);

/// Provides [PersonaManager] for prompt assembly.
final personaManagerProvider = Provider<PersonaManager>(
  (ref) => PersonaManager(
    personaApi: PersonaApi(ref.watch(apiClientProvider)),
    directiveApi: DirectiveApi(ref.watch(apiClientProvider)),
  ),
);

/// Provides [ReportParser] for parsing agent markdown reports.
final reportParserProvider = Provider<ReportParser>(
  (ref) => ReportParser(),
);

/// Provides [AgentDispatcher] for spawning Claude Code subprocesses.
final agentDispatcherProvider = Provider<AgentDispatcher>(
  (ref) => AgentDispatcher(
    processManager: ref.watch(processManagerProvider),
    personaManager: ref.watch(personaManagerProvider),
    claudeCodeDetector: ref.watch(claudeCodeDetectorProvider),
  ),
);

/// Provides [AgentMonitor] for process monitoring.
final agentMonitorProvider = Provider<AgentMonitor>(
  (ref) => AgentMonitor(processManager: ref.watch(processManagerProvider)),
);

/// Provides [ProgressAggregator] for real-time UI updates.
final progressAggregatorProvider = Provider<ProgressAggregator>(
  (ref) {
    final agg = ProgressAggregator();
    ref.onDispose(agg.dispose);
    return agg;
  },
);

/// Provides [VeraManager] for post-analysis consolidation.
final veraManagerProvider = Provider<VeraManager>(
  (ref) => VeraManager(),
);

/// Provides [JobOrchestrator] for driving complete job lifecycles.
final jobOrchestratorProvider = Provider<JobOrchestrator>(
  (ref) => JobOrchestrator(
    dispatcher: ref.watch(agentDispatcherProvider),
    monitor: ref.watch(agentMonitorProvider),
    vera: ref.watch(veraManagerProvider),
    progress: ref.watch(progressAggregatorProvider),
    parser: ref.watch(reportParserProvider),
    jobApi: ref.watch(jobApiProvider),
    findingApi: ref.watch(findingApiProvider),
    reportApi: ref.watch(reportApiProvider),
    agentProgressNotifier: ref.watch(agentProgressProvider.notifier),
  ),
);

/// Current job progress (reactive stream).
final jobProgressProvider = StreamProvider<JobProgress>((ref) {
  final aggregator = ref.watch(progressAggregatorProvider);
  return aggregator.progressStream;
});

/// Job lifecycle events stream.
final jobLifecycleProvider = StreamProvider<JobLifecycleEvent>((ref) {
  final orchestrator = ref.watch(jobOrchestratorProvider);
  return orchestrator.lifecycleStream;
});

/// Provides [AgentProgressNotifier] for real-time agent card state.
final agentProgressProvider = StateNotifierProvider<AgentProgressNotifier,
    Map<String, AgentProgress>>(
  (ref) => AgentProgressNotifier(),
);

/// Sorted list of [AgentProgress] values for rendering agent cards.
///
/// Sort order: running first, then queued (by queue position),
/// then completed, then failed.
final sortedAgentProgressProvider = Provider<List<AgentProgress>>((ref) {
  final map = ref.watch(agentProgressProvider);
  final values = map.values.toList();

  int statusOrder(AgentStatus status) => switch (status) {
        AgentStatus.running => 0,
        AgentStatus.pending => 1,
        AgentStatus.completed => 2,
        AgentStatus.failed => 3,
      };

  values.sort((a, b) {
    final cmp = statusOrder(a.status).compareTo(statusOrder(b.status));
    if (cmp != 0) return cmp;
    // Within pending, sort by queue position.
    if (a.status == AgentStatus.pending) {
      return a.queuePosition.compareTo(b.queuePosition);
    }
    return 0;
  });

  return values;
});

/// Aggregate summary statistics across all agents in the current job.
final agentProgressSummaryProvider = Provider<AgentProgressSummary>((ref) {
  final map = ref.watch(agentProgressProvider);
  final values = map.values;

  return AgentProgressSummary(
    total: values.length,
    running: values.where((a) => a.isRunning).length,
    queued: values.where((a) => a.isQueued).length,
    completed: values.where((a) => a.isComplete).length,
    failed: values.where((a) => a.isFailed).length,
    totalFindings: values.fold(0, (sum, a) => sum + a.totalFindings),
    totalCritical: values.fold(0, (sum, a) => sum + a.criticalCount),
  );
});

/// Provides [BugInvestigationOrchestrator] for launching bug investigations.
final bugInvestigationOrchestratorProvider =
    Provider<BugInvestigationOrchestrator>(
  (ref) => BugInvestigationOrchestrator(
    jobApi: ref.watch(jobApiProvider),
    jobOrchestrator: ref.watch(jobOrchestratorProvider),
  ),
);

/// Agent dispatch configuration (user-configurable).
final agentDispatchConfigProvider =
    StateNotifierProvider<AgentDispatchConfigNotifier, AgentDispatchConfig>(
  (ref) => AgentDispatchConfigNotifier(),
);

/// Notifier for [AgentDispatchConfig] state changes.
class AgentDispatchConfigNotifier extends StateNotifier<AgentDispatchConfig> {
  /// Creates a notifier with default configuration.
  AgentDispatchConfigNotifier()
      : super(const AgentDispatchConfig(
          maxConcurrent: AppConstants.defaultMaxConcurrentAgents,
          agentTimeout: Duration(
            minutes: AppConstants.defaultAgentTimeoutMinutes,
          ),
          claudeModel: AppConstants.defaultClaudeModelForDispatch,
          maxTurns: AppConstants.defaultMaxTurns,
        ));

  /// Updates the maximum number of concurrent agents.
  void setMaxConcurrent(int value) {
    state = AgentDispatchConfig(
      maxConcurrent: value,
      agentTimeout: state.agentTimeout,
      claudeModel: state.claudeModel,
      maxTurns: state.maxTurns,
    );
  }

  /// Updates the agent timeout duration.
  void setAgentTimeout(Duration value) {
    state = AgentDispatchConfig(
      maxConcurrent: state.maxConcurrent,
      agentTimeout: value,
      claudeModel: state.claudeModel,
      maxTurns: state.maxTurns,
    );
  }

  /// Updates the Claude model.
  void setClaudeModel(String value) {
    state = AgentDispatchConfig(
      maxConcurrent: state.maxConcurrent,
      agentTimeout: state.agentTimeout,
      claudeModel: value,
      maxTurns: state.maxTurns,
    );
  }

  /// Updates the maximum turns.
  void setMaxTurns(int value) {
    state = AgentDispatchConfig(
      maxConcurrent: state.maxConcurrent,
      agentTimeout: state.agentTimeout,
      claudeModel: state.claudeModel,
      maxTurns: value,
    );
  }
}
