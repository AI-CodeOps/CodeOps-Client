/// End-to-end job lifecycle orchestrator.
///
/// Coordinates the full QA job lifecycle: server-side job creation, agent
/// dispatch, output monitoring, report parsing, Vera consolidation, findings
/// upload, and final status sync. Emits [JobLifecycleEvent]s on a broadcast
/// stream so the UI can track every phase transition.
library;

import 'dart:async';

import '../../models/enums.dart';
import '../../providers/agent_progress_notifier.dart';
import '../agent/report_parser.dart';
import '../cloud/finding_api.dart';
import '../cloud/job_api.dart';
import '../cloud/report_api.dart';
import '../logging/log_service.dart';
import 'agent_dispatcher.dart';
import 'agent_monitor.dart';
import 'progress_aggregator.dart';
import 'vera_manager.dart';

// ---------------------------------------------------------------------------
// JobLifecycleEvent hierarchy
// ---------------------------------------------------------------------------

/// Base class for events emitted during the job lifecycle.
sealed class JobLifecycleEvent {}

/// The job record has been created on the server.
class JobCreated extends JobLifecycleEvent {
  /// The server-assigned job UUID.
  final String jobId;

  /// Creates a [JobCreated] event.
  JobCreated({required this.jobId});
}

/// The job has transitioned to the RUNNING status on the server.
class JobStarted extends JobLifecycleEvent {
  /// The job UUID.
  final String jobId;

  /// Creates a [JobStarted] event.
  JobStarted({required this.jobId});
}

/// The agent dispatch phase has begun.
class AgentPhaseStarted extends JobLifecycleEvent {
  /// The job UUID.
  final String jobId;

  /// The total number of agents that will be dispatched.
  final int totalAgents;

  /// Creates an [AgentPhaseStarted] event.
  AgentPhaseStarted({required this.jobId, required this.totalAgents});
}

/// An incremental progress update from the agent dispatch/monitoring phase.
class AgentPhaseProgress extends JobLifecycleEvent {
  /// The current aggregated job progress snapshot.
  final JobProgress progress;

  /// Creates an [AgentPhaseProgress] event.
  AgentPhaseProgress({required this.progress});
}

/// The Vera consolidation phase has begun.
class ConsolidationStarted extends JobLifecycleEvent {
  /// The job UUID.
  final String jobId;

  /// Creates a [ConsolidationStarted] event.
  ConsolidationStarted({required this.jobId});
}

/// The server sync phase has begun (uploading findings and reports).
class SyncStarted extends JobLifecycleEvent {
  /// The job UUID.
  final String jobId;

  /// Creates a [SyncStarted] event.
  SyncStarted({required this.jobId});
}

/// The job completed successfully.
class JobCompleted extends JobLifecycleEvent {
  /// The job UUID.
  final String jobId;

  /// The consolidated Vera report.
  final VeraReport report;

  /// Creates a [JobCompleted] event.
  JobCompleted({required this.jobId, required this.report});
}

/// The job failed due to an unrecoverable error.
class JobFailed extends JobLifecycleEvent {
  /// The job UUID.
  final String jobId;

  /// A human-readable description of the failure.
  final String error;

  /// Creates a [JobFailed] event.
  JobFailed({required this.jobId, required this.error});
}

/// The job was cancelled by the user.
class JobCancelled extends JobLifecycleEvent {
  /// The job UUID.
  final String jobId;

  /// Creates a [JobCancelled] event.
  JobCancelled({required this.jobId});
}

// ---------------------------------------------------------------------------
// JobOrchestrator
// ---------------------------------------------------------------------------

/// Orchestrates the complete lifecycle of a QA job.
///
/// Coordinates [AgentDispatcher], [AgentMonitor], [VeraManager],
/// [ProgressAggregator], [ReportParser], [JobApi], [FindingApi], and
/// [ReportApi] through a 10-step lifecycle:
///
/// 1. Create job on server (PENDING)
/// 2. Create agent runs on server (batch)
/// 3. Update job status to RUNNING
/// 4. Dispatch all agents concurrently
/// 5. For each completed agent: parse report, upload, update agent run
/// 6. Run Vera consolidation
/// 7. Upload findings in batch
/// 8. Upload summary report
/// 9. Update job with final status, score, and counts
/// 10. Emit [JobCompleted] lifecycle event
class JobOrchestrator {
  final AgentDispatcher _dispatcher;
  // ignore: unused_field — part of the constructor contract for future use.
  final AgentMonitor _monitor;
  final VeraManager _vera;
  final ProgressAggregator _progress;
  final ReportParser _parser;
  final JobApi _jobApi;
  final FindingApi _findingApi;
  final ReportApi _reportApi;
  final AgentProgressNotifier? _agentProgress;

  final StreamController<JobLifecycleEvent> _lifecycleController =
      StreamController<JobLifecycleEvent>.broadcast();

  String? _activeJobId;
  bool _cancelling = false;

  /// Creates a [JobOrchestrator].
  JobOrchestrator({
    required AgentDispatcher dispatcher,
    required AgentMonitor monitor,
    required VeraManager vera,
    required ProgressAggregator progress,
    required ReportParser parser,
    required JobApi jobApi,
    required FindingApi findingApi,
    required ReportApi reportApi,
    AgentProgressNotifier? agentProgressNotifier,
  })  : _dispatcher = dispatcher,
        _monitor = monitor,
        _vera = vera,
        _progress = progress,
        _parser = parser,
        _jobApi = jobApi,
        _findingApi = findingApi,
        _reportApi = reportApi,
        _agentProgress = agentProgressNotifier;

  /// The UUID of the currently running job, or `null` if no job is active.
  String? get activeJobId => _activeJobId;

  /// Broadcast stream of [JobLifecycleEvent]s for the current job.
  Stream<JobLifecycleEvent> get lifecycleStream => _lifecycleController.stream;

  /// Executes the full job lifecycle from creation through completion.
  ///
  /// [projectId] is the UUID of the project to analyze.
  /// [projectName] is a human-readable label for reports and summaries.
  /// [projectPath] is the local filesystem path for agent working directories.
  /// [teamId] scopes persona and directive lookups.
  /// [branch] is the git branch being analyzed.
  /// [mode] determines which agents run and how prompts are assembled.
  /// [selectedAgents] is the list of agents to dispatch for this job.
  /// [config] governs concurrency, timeout, model, and turn limits.
  /// [jobName] is an optional human-readable job name.
  /// [additionalContext] is free-form text appended to agent prompts.
  /// [jiraTicketKey] is the Jira ticket key for bug-investigate mode.
  /// [jiraTicketData] is raw Jira ticket content for prompt injection.
  /// [specReferences] is a list of specification names/paths for compliance.
  ///
  /// Returns the overall [JobResult] after all phases complete.
  Future<JobResult> executeJob({
    required String projectId,
    required String projectName,
    required String projectPath,
    required String teamId,
    required String branch,
    required JobMode mode,
    required List<AgentType> selectedAgents,
    required AgentDispatchConfig config,
    String? jobName,
    String? additionalContext,
    String? jiraTicketKey,
    String? jiraTicketData,
    List<String>? specReferences,
  }) async {
    _cancelling = false;
    String? jobId;

    try {
      // Step 1: Create job on server.
      final job = await _jobApi.createJob(
        projectId: projectId,
        mode: mode,
        name: jobName,
        branch: branch,
        jiraTicketKey: jiraTicketKey,
      );
      jobId = job.id;
      _activeJobId = jobId;
      log.i('JobOrchestrator', 'Job created (jobId=$jobId, project=$projectId, agents=${selectedAgents.length})');
      _lifecycleController.add(JobCreated(jobId: jobId));

      if (_cancelling) {
        await _handleCancellation(jobId);
        return JobResult.fail;
      }

      // Step 2: Create agent runs on server.
      final agentRuns =
          await _jobApi.createAgentRunsBatch(jobId, selectedAgents);

      // Build a lookup map from AgentType to agent run ID.
      final agentRunIdsByType = <AgentType, String>{};
      for (final run in agentRuns) {
        agentRunIdsByType[run.agentType] = run.id;
      }

      // Initialize the agent progress notifier with created runs.
      _agentProgress?.initializeAgents(
        agentRuns,
        maxTurns: config.maxTurns,
        modelId: config.claudeModel,
      );

      // Step 3: Update job status to RUNNING.
      await _jobApi.updateJob(
        jobId,
        status: JobStatus.running,
        startedAt: DateTime.now(),
      );
      log.i('JobOrchestrator', 'Job started (jobId=$jobId)');
      _lifecycleController.add(JobStarted(jobId: jobId));

      if (_cancelling) {
        await _handleCancellation(jobId);
        return JobResult.fail;
      }

      // Step 4: Dispatch all agents.
      _progress.reset(selectedAgents);
      _lifecycleController.add(
        AgentPhaseStarted(jobId: jobId, totalAgents: selectedAgents.length),
      );

      final agentReports = <AgentType, ParsedReport>{};
      final agentStartTimes = <AgentType, DateTime>{};

      // Subscribe to progress updates and forward them.
      final progressSubscription = _progress.progressStream.listen((snapshot) {
        _lifecycleController.add(AgentPhaseProgress(progress: snapshot));
      });

      // Listen for dispatch events.
      final dispatchStream = _dispatcher.dispatchAll(
        agentTypes: selectedAgents,
        teamId: teamId,
        projectId: projectId,
        projectPath: projectPath,
        branch: branch,
        mode: mode,
        projectName: projectName,
        config: config,
        additionalContext: additionalContext,
        jiraTicketData: jiraTicketData,
        specReferences: specReferences,
      );

      await for (final event in dispatchStream) {
        if (_cancelling) break;

        switch (event) {
          case AgentQueued(:final agentType):
            _progress.updateAgentStatus(
              agentType,
              AgentProgressStatus(
                agentType: agentType,
                phase: AgentPhase.queued,
                elapsed: Duration.zero,
              ),
            );
            _agentProgress?.updateQueuePositions();

          case AgentStarted(:final agentType):
            agentStartTimes[agentType] = DateTime.now();
            _progress.updateAgentStatus(
              agentType,
              AgentProgressStatus(
                agentType: agentType,
                phase: AgentPhase.running,
                elapsed: Duration.zero,
              ),
            );
            // Update agent progress notifier.
            final startRunId = agentRunIdsByType[agentType];
            if (startRunId != null) {
              _agentProgress?.markStarted(startRunId);
              _agentProgress?.updateQueuePositions();
            }
            // Update agent run status on server.
            final runId = agentRunIdsByType[agentType];
            if (runId != null) {
              await _jobApi.updateAgentRun(
                runId,
                status: AgentStatus.running,
                startedAt: agentStartTimes[agentType],
              );
            }

          case AgentOutput(:final agentType, :final line):
            _progress.updateAgentStatus(
              agentType,
              AgentProgressStatus(
                agentType: agentType,
                phase: AgentPhase.running,
                elapsed: _elapsedSince(agentStartTimes[agentType]),
                lastOutputLine: line,
              ),
            );
            // Feed output to agent progress notifier.
            final outputRunId = agentRunIdsByType[agentType];
            if (outputRunId != null) {
              _agentProgress?.appendOutput(outputRunId, line);
              _agentProgress?.updateElapsed(
                outputRunId,
                _elapsedSince(agentStartTimes[agentType]),
              );
            }

          case AgentCompleted(
              :final agentType,
              :final exitCode,
              :final output
            ):
            // Step 5: Parse report.
            _progress.updateAgentStatus(
              agentType,
              AgentProgressStatus(
                agentType: agentType,
                phase: AgentPhase.parsing,
                elapsed: _elapsedSince(agentStartTimes[agentType]),
              ),
            );

            final parsedReport = _parser.parseReport(output);
            agentReports[agentType] = parsedReport;

            // Report live findings for real-time UI.
            for (final finding in parsedReport.findings) {
              _progress.reportLiveFinding(agentType, finding);
            }

            // Determine agent result.
            final agentResult = _agentResultFromExitCode(
              exitCode,
              parsedReport.findings,
            );

            // Upload agent report to server.
            final runId = agentRunIdsByType[agentType];
            if (runId != null) {
              final reportResponse = await _reportApi.uploadAgentReport(
                jobId,
                agentType,
                output,
              );
              final s3Key = reportResponse['s3Key'] as String?;

              final criticalCount = parsedReport.findings
                  .where((f) => f.severity == Severity.critical)
                  .length;
              final highCount = parsedReport.findings
                  .where((f) => f.severity == Severity.high)
                  .length;

              await _jobApi.updateAgentRun(
                runId,
                status: AgentStatus.completed,
                result: agentResult,
                reportS3Key: s3Key,
                score: parsedReport.metrics?.score,
                findingsCount: parsedReport.findings.length,
                criticalCount: criticalCount,
                highCount: highCount,
                completedAt: DateTime.now(),
              );
            }

            _progress.updateAgentStatus(
              agentType,
              AgentProgressStatus(
                agentType: agentType,
                phase: AgentPhase.completed,
                elapsed: _elapsedSince(agentStartTimes[agentType]),
                findingsCount: parsedReport.findings.length,
              ),
            );

            // Update agent progress notifier with completion data.
            if (runId != null) {
              final completedCritical = parsedReport.findings
                  .where((f) => f.severity == Severity.critical)
                  .length;
              final completedHigh = parsedReport.findings
                  .where((f) => f.severity == Severity.high)
                  .length;
              final completedMedium = parsedReport.findings
                  .where((f) => f.severity == Severity.medium)
                  .length;
              final completedLow = parsedReport.findings
                  .where((f) => f.severity == Severity.low)
                  .length;
              _agentProgress?.markCompleted(
                runId,
                agentResult,
                score: parsedReport.metrics?.score,
                findingsCount: parsedReport.findings.length,
                criticalCount: completedCritical,
                highCount: completedHigh,
                mediumCount: completedMedium,
                lowCount: completedLow,
              );
            }

          case AgentFailed(:final agentType, :final error):
            _progress.updateAgentStatus(
              agentType,
              AgentProgressStatus(
                agentType: agentType,
                phase: AgentPhase.failed,
                elapsed: _elapsedSince(agentStartTimes[agentType]),
              ),
            );
            final failedRunId = agentRunIdsByType[agentType];
            if (failedRunId != null) {
              _agentProgress?.markFailed(failedRunId, error: error);
              await _jobApi.updateAgentRun(
                failedRunId,
                status: AgentStatus.failed,
                result: AgentResult.fail,
                completedAt: DateTime.now(),
              );
            }

          case AgentTimedOut(:final agentType):
            _progress.updateAgentStatus(
              agentType,
              AgentProgressStatus(
                agentType: agentType,
                phase: AgentPhase.timedOut,
                elapsed: config.agentTimeout,
              ),
            );
            final timedOutRunId = agentRunIdsByType[agentType];
            if (timedOutRunId != null) {
              _agentProgress?.markFailed(
                timedOutRunId,
                error: 'Agent timed out after ${config.agentTimeout.inMinutes} minutes',
              );
              await _jobApi.updateAgentRun(
                timedOutRunId,
                status: AgentStatus.failed,
                result: AgentResult.fail,
                completedAt: DateTime.now(),
              );
            }
        }
      }

      await progressSubscription.cancel();

      if (_cancelling) {
        await _handleCancellation(jobId);
        return JobResult.fail;
      }

      // Step 6: Vera consolidation.
      log.d('JobOrchestrator', 'Agent phase complete, starting Vera consolidation (jobId=$jobId)');
      _lifecycleController.add(ConsolidationStarted(jobId: jobId));

      // Tag all findings with their source agent type before consolidation.
      final taggedReports = <AgentType, ParsedReport>{};
      for (final entry in agentReports.entries) {
        final agentType = entry.key;
        final report = entry.value;
        taggedReports[agentType] = ParsedReport(
          metadata: report.metadata,
          executiveSummary: report.executiveSummary,
          findings: report.findings
              .map((f) => f.withAgentType(agentType))
              .toList(),
          metrics: report.metrics,
          rawMarkdown: report.rawMarkdown,
        );
      }

      final veraReport = await _vera.consolidate(
        jobId: jobId,
        projectName: projectName,
        agentReports: taggedReports,
        mode: mode,
      );

      // Step 7: Upload findings in batch.
      _lifecycleController.add(SyncStarted(jobId: jobId));

      if (veraReport.deduplicatedFindings.isNotEmpty) {
        final findingMaps = veraReport.deduplicatedFindings.map((f) {
          final map = <String, dynamic>{
            'jobId': jobId,
            'agentType': (f.agentType ?? AgentType.codeQuality).toJson(),
            'severity': f.severity.toJson(),
            'title': f.title,
          };
          if (f.description != null) map['description'] = f.description;
          if (f.filePath != null) map['filePath'] = f.filePath;
          if (f.lineNumber != null) map['lineNumber'] = f.lineNumber;
          if (f.recommendation != null) {
            map['recommendation'] = f.recommendation;
          }
          if (f.evidence != null) map['evidence'] = f.evidence;
          if (f.effortEstimate != null) {
            map['effortEstimate'] = f.effortEstimate!.toJson();
          }
          if (f.debtCategory != null) {
            map['debtCategory'] = f.debtCategory!.toJson();
          }
          return map;
        }).toList();

        await _findingApi.createFindingsBatch(findingMaps);
      }

      // Step 8: Upload summary report.
      await _reportApi.uploadSummaryReport(
        jobId,
        veraReport.executiveSummaryMd,
      );

      // Step 9: Update job with final status, score, and counts.
      await _jobApi.updateJob(
        jobId,
        status: JobStatus.completed,
        summaryMd: veraReport.executiveSummaryMd,
        overallResult: veraReport.overallResult,
        healthScore: veraReport.healthScore,
        totalFindings: veraReport.totalFindings,
        criticalCount: veraReport.criticalCount,
        highCount: veraReport.highCount,
        mediumCount: veraReport.mediumCount,
        lowCount: veraReport.lowCount,
        completedAt: DateTime.now(),
      );

      // Step 10: Emit completion event.
      log.i('JobOrchestrator', 'Job completed (jobId=$jobId, score=${veraReport.healthScore}, findings=${veraReport.totalFindings})');
      _lifecycleController.add(
        JobCompleted(jobId: jobId, report: veraReport),
      );
      _activeJobId = null;

      return veraReport.overallResult;
    } catch (e) {
      log.e('JobOrchestrator', 'Job failed (jobId=$jobId)', e);
      // Wrap entire flow in error handling.
      if (jobId != null) {
        try {
          await _jobApi.updateJob(
            jobId,
            status: JobStatus.failed,
            completedAt: DateTime.now(),
          );
        } catch (_) {
          // Best-effort server update; swallow secondary errors.
        }
        _lifecycleController.add(
          JobFailed(jobId: jobId, error: e.toString()),
        );
      }
      _activeJobId = null;
      rethrow;
    }
  }

  /// Cancels the currently running job.
  ///
  /// Kills all running agent processes via [AgentDispatcher.cancelAll] and
  /// updates the job status to CANCELLED on the server.
  Future<void> cancelJob(String jobId) async {
    log.w('JobOrchestrator', 'Job cancellation requested (jobId=$jobId)');
    _cancelling = true;
    await _dispatcher.cancelAll();

    try {
      await _jobApi.updateJob(
        jobId,
        status: JobStatus.cancelled,
        completedAt: DateTime.now(),
      );
    } catch (_) {
      // Best-effort server update.
    }

    _agentProgress?.reset();
    _lifecycleController.add(JobCancelled(jobId: jobId));
    _activeJobId = null;
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Handles the cancellation flow during an in-progress job.
  Future<void> _handleCancellation(String jobId) async {
    await _dispatcher.cancelAll();
    try {
      await _jobApi.updateJob(
        jobId,
        status: JobStatus.cancelled,
        completedAt: DateTime.now(),
      );
    } catch (_) {
      // Best-effort.
    }
    _lifecycleController.add(JobCancelled(jobId: jobId));
    _activeJobId = null;
  }

  /// Calculates the elapsed duration since [startTime], or [Duration.zero]
  /// if [startTime] is `null`.
  Duration _elapsedSince(DateTime? startTime) {
    if (startTime == null) return Duration.zero;
    return DateTime.now().difference(startTime);
  }

  /// Derives an [AgentResult] from the process exit code and parsed findings.
  AgentResult _agentResultFromExitCode(
    int exitCode,
    List<ParsedFinding> findings,
  ) {
    if (exitCode != 0) return AgentResult.fail;
    if (findings.any((f) => f.severity == Severity.critical)) {
      return AgentResult.fail;
    }
    if (findings.any((f) => f.severity == Severity.high)) {
      return AgentResult.warn;
    }
    return AgentResult.pass;
  }
}
