/// Riverpod providers for the Audit Wizard, Job History, and related state.
///
/// Contains the wizard state machine, job configuration models, filter
/// providers for job history, and derived providers that wrap existing
/// job/project data.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/enums.dart';
import '../models/project.dart';
import '../models/qa_job.dart';
import '../utils/constants.dart';
import 'job_providers.dart';

// ---------------------------------------------------------------------------
// JobConfig
// ---------------------------------------------------------------------------

/// Configuration parameters for a job launch.
class JobConfig {
  /// Maximum number of agents to run concurrently.
  final int maxConcurrentAgents;

  /// Maximum time each agent may run, in minutes.
  final int agentTimeoutMinutes;

  /// Claude model identifier for agent dispatch.
  final String claudeModel;

  /// Maximum agentic turns per agent.
  final int maxTurns;

  /// Health score threshold for a PASS result.
  final int passThreshold;

  /// Health score threshold for a WARN result.
  final int warnThreshold;

  /// Free-form additional context appended to agent prompts.
  final String additionalContext;

  /// Creates a [JobConfig] with sensible defaults.
  const JobConfig({
    this.maxConcurrentAgents = AppConstants.defaultMaxConcurrentAgents,
    this.agentTimeoutMinutes = AppConstants.defaultAgentTimeoutMinutes,
    this.claudeModel = AppConstants.defaultClaudeModelForDispatch,
    this.maxTurns = AppConstants.defaultMaxTurns,
    this.passThreshold = AppConstants.defaultPassThreshold,
    this.warnThreshold = AppConstants.defaultWarnThreshold,
    this.additionalContext = '',
  });

  /// Creates a copy with the given fields replaced.
  JobConfig copyWith({
    int? maxConcurrentAgents,
    int? agentTimeoutMinutes,
    String? claudeModel,
    int? maxTurns,
    int? passThreshold,
    int? warnThreshold,
    String? additionalContext,
  }) {
    return JobConfig(
      maxConcurrentAgents: maxConcurrentAgents ?? this.maxConcurrentAgents,
      agentTimeoutMinutes: agentTimeoutMinutes ?? this.agentTimeoutMinutes,
      claudeModel: claudeModel ?? this.claudeModel,
      maxTurns: maxTurns ?? this.maxTurns,
      passThreshold: passThreshold ?? this.passThreshold,
      warnThreshold: warnThreshold ?? this.warnThreshold,
      additionalContext: additionalContext ?? this.additionalContext,
    );
  }
}

// ---------------------------------------------------------------------------
// SpecFile
// ---------------------------------------------------------------------------

/// A specification file attached to a compliance job.
class SpecFile {
  /// Original file name.
  final String name;

  /// Local file path.
  final String path;

  /// File size in bytes.
  final int sizeBytes;

  /// MIME content type.
  final String contentType;

  /// Creates a [SpecFile].
  const SpecFile({
    required this.name,
    required this.path,
    required this.sizeBytes,
    required this.contentType,
  });
}

// ---------------------------------------------------------------------------
// JiraTicketData
// ---------------------------------------------------------------------------

/// Fetched Jira ticket data for bug investigation mode.
class JiraTicketData {
  /// Ticket key (e.g. 'PROJ-123').
  final String key;

  /// Ticket summary / title.
  final String summary;

  /// Full description.
  final String description;

  /// Ticket status.
  final String status;

  /// Priority level.
  final String priority;

  /// Assignee display name.
  final String? assignee;

  /// Reporter display name.
  final String? reporter;

  /// Number of comments on the ticket.
  final int commentCount;

  /// Number of attachments.
  final int attachmentCount;

  /// Number of linked issues.
  final int linkedIssueCount;

  /// Sprint name if assigned.
  final String? sprint;

  /// Creates a [JiraTicketData].
  const JiraTicketData({
    required this.key,
    required this.summary,
    required this.description,
    required this.status,
    required this.priority,
    this.assignee,
    this.reporter,
    this.commentCount = 0,
    this.attachmentCount = 0,
    this.linkedIssueCount = 0,
    this.sprint,
  });
}

// ---------------------------------------------------------------------------
// JobExecutionPhase
// ---------------------------------------------------------------------------

/// Phases of job execution as seen by the Job Progress page.
enum JobExecutionPhase {
  /// Job record is being created on the server.
  creating,

  /// Agent processes are being dispatched.
  dispatching,

  /// Agents are actively running.
  running,

  /// Vera consolidation is in progress.
  consolidating,

  /// Findings and reports are being synced to the server.
  syncing,

  /// Job completed successfully.
  complete,

  /// Job failed.
  failed,

  /// Job was cancelled.
  cancelled;

  /// Human-readable display label.
  String get displayName => switch (this) {
        JobExecutionPhase.creating => 'Creating',
        JobExecutionPhase.dispatching => 'Dispatching',
        JobExecutionPhase.running => 'Running',
        JobExecutionPhase.consolidating => 'Consolidating',
        JobExecutionPhase.syncing => 'Syncing',
        JobExecutionPhase.complete => 'Complete',
        JobExecutionPhase.failed => 'Failed',
        JobExecutionPhase.cancelled => 'Cancelled',
      };
}

// ---------------------------------------------------------------------------
// AuditWizardState
// ---------------------------------------------------------------------------

/// Immutable state for the Audit Wizard multi-step flow.
class AuditWizardState {
  /// The current step index (0-based).
  final int currentStep;

  /// The selected project, or `null` if none.
  final Project? selectedProject;

  /// The selected branch name.
  final String? selectedBranch;

  /// The set of selected agent types.
  final Set<AgentType> selectedAgents;

  /// Job configuration.
  final JobConfig config;

  /// Whether the wizard is currently launching a job.
  final bool isLaunching;

  /// Error message from a failed launch attempt.
  final String? launchError;

  /// Creates an [AuditWizardState].
  const AuditWizardState({
    this.currentStep = 0,
    this.selectedProject,
    this.selectedBranch,
    this.selectedAgents = const {},
    this.config = const JobConfig(),
    this.isLaunching = false,
    this.launchError,
  });

  /// Creates a copy with the given fields replaced.
  AuditWizardState copyWith({
    int? currentStep,
    Project? selectedProject,
    String? selectedBranch,
    Set<AgentType>? selectedAgents,
    JobConfig? config,
    bool? isLaunching,
    String? launchError,
  }) {
    return AuditWizardState(
      currentStep: currentStep ?? this.currentStep,
      selectedProject: selectedProject ?? this.selectedProject,
      selectedBranch: selectedBranch ?? this.selectedBranch,
      selectedAgents: selectedAgents ?? this.selectedAgents,
      config: config ?? this.config,
      isLaunching: isLaunching ?? this.isLaunching,
      launchError: launchError ?? this.launchError,
    );
  }
}

/// StateNotifier for managing the Audit Wizard flow.
class AuditWizardNotifier extends StateNotifier<AuditWizardState> {
  /// Creates an [AuditWizardNotifier] with all agents selected by default.
  AuditWizardNotifier()
      : super(AuditWizardState(
          selectedAgents: AgentType.values.toSet(),
        ));

  /// Moves to the next step.
  void nextStep() {
    state = state.copyWith(currentStep: state.currentStep + 1);
  }

  /// Moves to the previous step.
  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  /// Jumps to a specific step.
  void goToStep(int step) {
    state = state.copyWith(currentStep: step);
  }

  /// Sets the selected project and initializes the branch.
  void selectProject(Project project) {
    state = state.copyWith(
      selectedProject: project,
      selectedBranch: project.defaultBranch ?? 'main',
    );
  }

  /// Sets the selected branch.
  void selectBranch(String branch) {
    state = state.copyWith(selectedBranch: branch);
  }

  /// Toggles a single agent type selection.
  void toggleAgent(AgentType agent) {
    final updated = Set<AgentType>.from(state.selectedAgents);
    if (updated.contains(agent)) {
      updated.remove(agent);
    } else {
      updated.add(agent);
    }
    state = state.copyWith(selectedAgents: updated);
  }

  /// Selects all agent types.
  void selectAllAgents() {
    state = state.copyWith(selectedAgents: AgentType.values.toSet());
  }

  /// Deselects all agent types.
  void selectNoAgents() {
    state = state.copyWith(selectedAgents: <AgentType>{});
  }

  /// Sets the recommended agents for a given mode.
  void selectRecommendedAgents(JobMode mode) {
    state = state.copyWith(selectedAgents: _recommendedAgents(mode));
  }

  /// Updates the job configuration.
  void updateConfig(JobConfig config) {
    state = state.copyWith(config: config);
  }

  /// Marks the wizard as launching.
  void setLaunching(bool launching) {
    state = state.copyWith(isLaunching: launching, launchError: null);
  }

  /// Records a launch error.
  void setLaunchError(String error) {
    state = state.copyWith(isLaunching: false, launchError: error);
  }

  /// Resets the wizard to its initial state.
  void reset() {
    state = AuditWizardState(selectedAgents: AgentType.values.toSet());
  }

  /// Returns the recommended agent set for a given job mode.
  static Set<AgentType> _recommendedAgents(JobMode mode) {
    return switch (mode) {
      JobMode.audit => AgentType.values.toSet(),
      JobMode.compliance => {
          AgentType.security,
          AgentType.apiContract,
          AgentType.documentation,
          AgentType.architecture,
        },
      JobMode.bugInvestigate => {
          AgentType.security,
          AgentType.codeQuality,
          AgentType.testCoverage,
          AgentType.performance,
        },
      JobMode.remediate => {
          AgentType.codeQuality,
          AgentType.testCoverage,
          AgentType.buildHealth,
        },
      JobMode.techDebt => {
          AgentType.codeQuality,
          AgentType.architecture,
          AgentType.documentation,
          AgentType.completeness,
        },
      JobMode.dependency => {
          AgentType.dependency,
          AgentType.security,
          AgentType.buildHealth,
        },
      JobMode.healthMonitor => {
          AgentType.security,
          AgentType.codeQuality,
          AgentType.buildHealth,
          AgentType.testCoverage,
          AgentType.performance,
        },
    };
  }
}

/// Provider for the Audit Wizard state.
final auditWizardStateProvider =
    StateNotifierProvider<AuditWizardNotifier, AuditWizardState>(
  (ref) => AuditWizardNotifier(),
);

// ---------------------------------------------------------------------------
// Job History Filters
// ---------------------------------------------------------------------------

/// Filter criteria for the Job History page.
class JobHistoryFilters {
  /// Filter by job mode.
  final JobMode? mode;

  /// Filter by job status.
  final JobStatus? status;

  /// Filter by job result.
  final JobResult? result;

  /// Search query (matches job name, project name).
  final String searchQuery;

  /// Start date for date range filter.
  final DateTime? dateFrom;

  /// End date for date range filter.
  final DateTime? dateTo;

  /// Creates [JobHistoryFilters].
  const JobHistoryFilters({
    this.mode,
    this.status,
    this.result,
    this.searchQuery = '',
    this.dateFrom,
    this.dateTo,
  });

  /// Creates a copy with the given fields replaced.
  JobHistoryFilters copyWith({
    JobMode? mode,
    JobStatus? status,
    JobResult? result,
    String? searchQuery,
    DateTime? dateFrom,
    DateTime? dateTo,
    bool clearMode = false,
    bool clearStatus = false,
    bool clearResult = false,
    bool clearDateFrom = false,
    bool clearDateTo = false,
  }) {
    return JobHistoryFilters(
      mode: clearMode ? null : (mode ?? this.mode),
      status: clearStatus ? null : (status ?? this.status),
      result: clearResult ? null : (result ?? this.result),
      searchQuery: searchQuery ?? this.searchQuery,
      dateFrom: clearDateFrom ? null : (dateFrom ?? this.dateFrom),
      dateTo: clearDateTo ? null : (dateTo ?? this.dateTo),
    );
  }

  /// Whether any filter is active.
  bool get hasActiveFilters =>
      mode != null ||
      status != null ||
      result != null ||
      searchQuery.isNotEmpty ||
      dateFrom != null ||
      dateTo != null;
}

/// Provider for job history filter state.
final jobHistoryFiltersProvider = StateProvider<JobHistoryFilters>(
  (ref) => const JobHistoryFilters(),
);

/// Provider that wraps [myJobsProvider] for the history page.
final jobHistoryProvider = FutureProvider<List<JobSummary>>((ref) async {
  final jobs = await ref.watch(myJobsProvider.future);
  return jobs;
});

/// Provider that applies [JobHistoryFilters] to [jobHistoryProvider].
final filteredJobHistoryProvider = Provider<AsyncValue<List<JobSummary>>>(
  (ref) {
    final jobsAsync = ref.watch(jobHistoryProvider);
    final filters = ref.watch(jobHistoryFiltersProvider);

    return jobsAsync.whenData((jobs) {
      var filtered = List<JobSummary>.from(jobs);

      // Filter by mode.
      if (filters.mode != null) {
        filtered = filtered.where((j) => j.mode == filters.mode).toList();
      }

      // Filter by status.
      if (filters.status != null) {
        filtered = filtered.where((j) => j.status == filters.status).toList();
      }

      // Filter by result.
      if (filters.result != null) {
        filtered =
            filtered.where((j) => j.overallResult == filters.result).toList();
      }

      // Filter by search query.
      if (filters.searchQuery.isNotEmpty) {
        final query = filters.searchQuery.toLowerCase();
        filtered = filtered.where((j) {
          return (j.name?.toLowerCase().contains(query) ?? false) ||
              (j.projectName?.toLowerCase().contains(query) ?? false);
        }).toList();
      }

      // Filter by date range.
      if (filters.dateFrom != null) {
        filtered = filtered.where((j) {
          final date = j.createdAt;
          return date != null && !date.isBefore(filters.dateFrom!);
        }).toList();
      }
      if (filters.dateTo != null) {
        filtered = filtered.where((j) {
          final date = j.createdAt;
          return date != null && !date.isAfter(filters.dateTo!);
        }).toList();
      }

      return filtered;
    });
  },
);
