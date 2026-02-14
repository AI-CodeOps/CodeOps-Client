/// Riverpod providers for agent run data and orchestration state.
///
/// Exposes agent runs for a job, selected agent types, Claude Code
/// detector status, job progress streams, lifecycle events, and
/// dispatch configuration.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/agent_run.dart';
import '../models/enums.dart';
import '../services/orchestration/agent_dispatcher.dart';
import '../services/orchestration/agent_monitor.dart';
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
import 'auth_providers.dart';
import 'job_providers.dart';

/// Provides agent run data for a specific job.
final agentRunsProvider =
    FutureProvider.family<List<AgentRun>, String>((ref, jobId) async {
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
  (ref) => VeraManager(
    personaManager: ref.watch(personaManagerProvider),
    agentDispatcher: ref.watch(agentDispatcherProvider),
    reportParser: ref.watch(reportParserProvider),
  ),
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
