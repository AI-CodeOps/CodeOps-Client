/// Job Progress page.
///
/// Shows real-time agent execution for a running job, completed
/// summary for finished jobs, and error banner for failed jobs.
/// Extracts `jobId` from route. Polls [jobDetailProvider] as fallback.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/enums.dart';
import '../providers/agent_providers.dart';
import '../providers/job_providers.dart';
import '../providers/wizard_providers.dart';
import '../services/orchestration/job_orchestrator.dart';
import '../theme/colors.dart';
import '../utils/constants.dart';
import '../utils/date_utils.dart';
import '../widgets/progress/agent_status_grid.dart';
import '../widgets/progress/elapsed_timer.dart';
import '../widgets/progress/job_progress_bar.dart';
import '../widgets/progress/live_findings_feed.dart';
import '../widgets/progress/phase_indicator.dart';
import '../widgets/progress/progress_summary_bar.dart';
import '../widgets/shared/error_panel.dart';
import '../widgets/shared/loading_overlay.dart';

/// Displays the progress or results of a specific job.
class JobProgressPage extends ConsumerStatefulWidget {
  /// The job UUID extracted from the route.
  final String jobId;

  /// Creates a [JobProgressPage].
  const JobProgressPage({super.key, required this.jobId});

  @override
  ConsumerState<JobProgressPage> createState() => _JobProgressPageState();
}

class _JobProgressPageState extends ConsumerState<JobProgressPage> {
  JobExecutionPhase _phase = JobExecutionPhase.creating;
  Timer? _pollTimer;
  DateTime _startTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _startPollFallback();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPollFallback() {
    _pollTimer = Timer.periodic(
      Duration(seconds: AppConstants.jobPollingIntervalSeconds),
      (_) => ref.invalidate(jobDetailProvider(widget.jobId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final jobAsync = ref.watch(jobDetailProvider(widget.jobId));
    final progressAsync = ref.watch(jobProgressProvider);
    final lifecycleAsync = ref.watch(jobLifecycleProvider);
    final agentProgressList = ref.watch(sortedAgentProgressProvider);
    final agentSummary = ref.watch(agentProgressSummaryProvider);

    // Map lifecycle events to phases.
    lifecycleAsync.whenData((event) {
      final newPhase = _mapEventToPhase(event);
      if (newPhase != _phase) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _phase = newPhase);
        });
      }
    });

    return jobAsync.when(
      loading: () => const LoadingOverlay(message: 'Loading job...'),
      error: (e, _) => ErrorPanel.fromException(e,
          onRetry: () => ref.invalidate(jobDetailProvider(widget.jobId))),
      data: (job) {
        // Derive phase from server status if lifecycle stream is not active.
        if (lifecycleAsync is! AsyncData) {
          final serverPhase = switch (job.status) {
            JobStatus.pending => JobExecutionPhase.creating,
            JobStatus.running => JobExecutionPhase.running,
            JobStatus.completed => JobExecutionPhase.complete,
            JobStatus.failed => JobExecutionPhase.failed,
            JobStatus.cancelled => JobExecutionPhase.cancelled,
          };
          if (serverPhase != _phase) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _phase = serverPhase);
            });
          }
        }

        if (job.startedAt != null) _startTime = job.startedAt!;

        final isRunning = _phase != JobExecutionPhase.complete &&
            _phase != JobExecutionPhase.failed &&
            _phase != JobExecutionPhase.cancelled;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.name ?? '${job.mode.displayName} - ${job.projectName ?? "Job"}',
                          style: const TextStyle(
                            color: CodeOpsColors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: CodeOpsColors.primary
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                job.mode.displayName,
                                style: const TextStyle(
                                  color: CodeOpsColors.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (job.branch != null) ...[
                              const SizedBox(width: 8),
                              Icon(Icons.call_split,
                                  size: 14,
                                  color: CodeOpsColors.textTertiary),
                              const SizedBox(width: 4),
                              Text(
                                job.branch!,
                                style: const TextStyle(
                                  color: CodeOpsColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  ElapsedTimer(
                    startTime: _startTime,
                    running: isRunning,
                  ),
                  if (isRunning) ...[
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () => _cancelJob(),
                      icon:
                          const Icon(Icons.stop, size: 16, color: CodeOpsColors.error),
                      label: const Text('Cancel'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: CodeOpsColors.error,
                        side: const BorderSide(color: CodeOpsColors.error),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 20),

              // Phase indicator
              PhaseIndicator(currentPhase: _phase),
              const SizedBox(height: 24),

              // Failed banner
              if (_phase == JobExecutionPhase.failed) ...[
                _ErrorBanner(
                  message: 'Job failed',
                  onRetry: () {
                    // Navigate back to audit wizard for retry.
                    context.go('/audit');
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Cancelled banner
              if (_phase == JobExecutionPhase.cancelled) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CodeOpsColors.textTertiary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color:
                          CodeOpsColors.textTertiary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.cancel_outlined,
                          size: 18, color: CodeOpsColors.textTertiary),
                      SizedBox(width: 8),
                      Text(
                        'This job was cancelled.',
                        style: TextStyle(
                          color: CodeOpsColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Completed summary card
              if (_phase == JobExecutionPhase.complete) ...[
                _CompletedSummary(
                  healthScore: job.healthScore,
                  totalFindings: job.totalFindings,
                  criticalCount: job.criticalCount,
                  highCount: job.highCount,
                  mediumCount: job.mediumCount,
                  lowCount: job.lowCount,
                  overallResult: job.overallResult,
                  duration: job.completedAt != null && job.startedAt != null
                      ? job.completedAt!.difference(job.startedAt!)
                      : null,
                ),
                const SizedBox(height: 12),
                // Action buttons
                Row(
                  children: [
                    FilledButton.icon(
                      onPressed: () =>
                          context.go('/jobs/${widget.jobId}/report'),
                      icon: const Icon(Icons.description, size: 16),
                      label: const Text('View Report'),
                      style: FilledButton.styleFrom(
                        backgroundColor: CodeOpsColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () =>
                          context.go('/jobs/${widget.jobId}/findings'),
                      icon: const Icon(Icons.bug_report, size: 16),
                      label: const Text('View Findings'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: CodeOpsColors.textSecondary,
                        side: const BorderSide(color: CodeOpsColors.border),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],

              // Progress bar (while running)
              if (isRunning)
                progressAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (progress) => Column(
                    children: [
                      JobProgressBar(progress: progress),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),

              // Progress summary bar (when agents are active)
              if (agentSummary.total > 0) ...[
                ProgressSummaryBar(summary: agentSummary),
                const SizedBox(height: 16),
              ],

              // Agent status grid (using new AgentProgress data)
              if (agentProgressList.isNotEmpty) ...[
                const Text(
                  'Agents',
                  style: TextStyle(
                    color: CodeOpsColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                AgentStatusGrid(
                  agents: agentProgressList,
                  phase: _phase,
                ),
              ],

              // Live findings feed (while running)
              if (isRunning)
                progressAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (progress) {
                    if (progress.liveFindings.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            const Text(
                              'Live Findings',
                              style: TextStyle(
                                color: CodeOpsColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: CodeOpsColors.primary
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${progress.liveFindings.length}',
                                style: const TextStyle(
                                  color: CodeOpsColors.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LiveFindingsFeed(
                          findings: progress.liveFindings,
                        ),
                      ],
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _cancelJob() async {
    final orchestrator = ref.read(jobOrchestratorProvider);
    await orchestrator.cancelJob(widget.jobId);
    setState(() => _phase = JobExecutionPhase.cancelled);
  }

  JobExecutionPhase _mapEventToPhase(JobLifecycleEvent event) {
    return switch (event) {
      JobCreated() => JobExecutionPhase.creating,
      JobStarted() => JobExecutionPhase.dispatching,
      AgentPhaseStarted() => JobExecutionPhase.running,
      AgentPhaseProgress() => JobExecutionPhase.running,
      ConsolidationStarted() => JobExecutionPhase.consolidating,
      SyncStarted() => JobExecutionPhase.syncing,
      JobCompleted() => JobExecutionPhase.complete,
      JobFailed() => JobExecutionPhase.failed,
      JobCancelled() => JobExecutionPhase.cancelled,
    };
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _ErrorBanner({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CodeOpsColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CodeOpsColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline,
              size: 18, color: CodeOpsColors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: CodeOpsColors.error,
                fontSize: 13,
              ),
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }
}

class _CompletedSummary extends StatelessWidget {
  final int? healthScore;
  final int? totalFindings;
  final int? criticalCount;
  final int? highCount;
  final int? mediumCount;
  final int? lowCount;
  final JobResult? overallResult;
  final Duration? duration;

  const _CompletedSummary({
    this.healthScore,
    this.totalFindings,
    this.criticalCount,
    this.highCount,
    this.mediumCount,
    this.lowCount,
    this.overallResult,
    this.duration,
  });

  @override
  Widget build(BuildContext context) {
    final resultColor = switch (overallResult) {
      JobResult.pass => CodeOpsColors.success,
      JobResult.warn => CodeOpsColors.warning,
      JobResult.fail => CodeOpsColors.error,
      null => CodeOpsColors.textTertiary,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: resultColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: resultColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          // Health score circle
          if (healthScore != null)
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: resultColor.withValues(alpha: 0.15),
                border: Border.all(color: resultColor, width: 2),
              ),
              child: Center(
                child: Text(
                  '$healthScore',
                  style: TextStyle(
                    color: resultColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          const SizedBox(width: 16),

          // Summary stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      overallResult?.displayName ?? 'Complete',
                      style: TextStyle(
                        color: resultColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (duration != null) ...[
                      const SizedBox(width: 12),
                      Text(
                        formatDuration(duration!),
                        style: const TextStyle(
                          color: CodeOpsColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  children: [
                    if (totalFindings != null)
                      _StatChip(
                        label: 'Total',
                        value: '$totalFindings',
                        color: CodeOpsColors.textSecondary,
                      ),
                    if (criticalCount != null && criticalCount! > 0)
                      _StatChip(
                        label: 'Critical',
                        value: '$criticalCount',
                        color: CodeOpsColors.critical,
                      ),
                    if (highCount != null && highCount! > 0)
                      _StatChip(
                        label: 'High',
                        value: '$highCount',
                        color: CodeOpsColors.error,
                      ),
                    if (mediumCount != null && mediumCount! > 0)
                      _StatChip(
                        label: 'Medium',
                        value: '$mediumCount',
                        color: CodeOpsColors.warning,
                      ),
                    if (lowCount != null && lowCount! > 0)
                      _StatChip(
                        label: 'Low',
                        value: '$lowCount',
                        color: CodeOpsColors.secondary,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$value $label',
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
