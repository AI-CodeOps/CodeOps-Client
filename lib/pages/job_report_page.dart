/// Job Report page.
///
/// Displays the executive summary, per-agent report tabs, trend chart,
/// and export/navigation actions for a completed job.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/agent_run.dart';
import '../models/enums.dart';
import '../models/finding.dart';
import '../models/qa_job.dart';
import '../providers/job_providers.dart';
import '../providers/report_providers.dart';
import '../theme/colors.dart';
import '../widgets/reports/agent_report_tab.dart';
import '../widgets/reports/executive_summary_card.dart';
import '../widgets/reports/export_dialog.dart';
import '../widgets/reports/trend_chart.dart';
import '../widgets/shared/error_panel.dart';
import '../widgets/shared/loading_overlay.dart';

/// Displays the full report for a completed job.
class JobReportPage extends ConsumerStatefulWidget {
  /// The job UUID extracted from the route.
  final String jobId;

  /// Creates a [JobReportPage].
  const JobReportPage({super.key, required this.jobId});

  @override
  ConsumerState<JobReportPage> createState() => _JobReportPageState();
}

class _JobReportPageState extends ConsumerState<JobReportPage>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final jobAsync = ref.watch(jobDetailProvider(widget.jobId));
    final agentRunsAsync = ref.watch(agentRunsByJobProvider(widget.jobId));
    final findingsAsync = ref.watch(jobFindingsProvider(
        (jobId: widget.jobId, page: 0)));

    return jobAsync.when(
      loading: () => const LoadingOverlay(message: 'Loading report...'),
      error: (e, _) => ErrorPanel.fromException(e,
          onRetry: () => ref.invalidate(jobDetailProvider(widget.jobId))),
      data: (job) {
        return agentRunsAsync.when(
          loading: () => const LoadingOverlay(message: 'Loading agents...'),
          error: (e, _) => ErrorPanel.fromException(e,
              onRetry: () =>
                  ref.invalidate(agentRunsByJobProvider(widget.jobId))),
          data: (agentRuns) {
            // Initialize tab controller for agent tabs
            final completedRuns = agentRuns
                .where((r) => r.status == AgentStatus.completed)
                .toList();

            // Tabs: Overview + one per completed agent
            final tabCount = 1 + completedRuns.length;
            if (_tabController == null ||
                _tabController!.length != tabCount) {
              _tabController?.dispose();
              _tabController = TabController(
                length: tabCount,
                vsync: this,
              );
            }

            final findings = findingsAsync.valueOrNull?.content ?? [];

            return _ReportContent(
              job: job,
              agentRuns: agentRuns,
              completedRuns: completedRuns,
              findings: findings,
              tabController: _tabController!,
              jobId: widget.jobId,
            );
          },
        );
      },
    );
  }
}

class _ReportContent extends ConsumerWidget {
  final QaJob job;
  final List<AgentRun> agentRuns;
  final List<AgentRun> completedRuns;
  final List<Finding> findings;
  final TabController tabController;
  final String jobId;

  const _ReportContent({
    required this.job,
    required this.agentRuns,
    required this.completedRuns,
    required this.findings,
    required this.tabController,
    required this.jobId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fetch trend data if project ID available
    final trendAsync = ref.watch(projectTrendProvider(
        (projectId: job.projectId, days: 30)));

    return Column(
      children: [
        // Header bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: CodeOpsColors.divider),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back,
                    size: 18, color: CodeOpsColors.textSecondary),
                onPressed: () => context.go('/jobs/$jobId'),
                tooltip: 'Back to job',
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Report: ${job.name ?? job.mode.displayName}',
                  style: const TextStyle(
                    color: CodeOpsColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => context.go('/jobs/$jobId/findings'),
                icon: const Icon(Icons.bug_report, size: 14),
                label: const Text('View Findings'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: CodeOpsColors.textSecondary,
                  side: const BorderSide(color: CodeOpsColors.border),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () => showExportDialog(
                  context: context,
                  job: job,
                  agentRuns: agentRuns,
                  findings: findings,
                  summaryMd: job.summaryMd,
                ),
                icon: const Icon(Icons.download, size: 14),
                label: const Text('Export'),
                style: FilledButton.styleFrom(
                  backgroundColor: CodeOpsColors.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),

        // Tab bar
        Container(
          color: CodeOpsColors.surface,
          child: TabBar(
            controller: tabController,
            isScrollable: true,
            labelColor: CodeOpsColors.primary,
            unselectedLabelColor: CodeOpsColors.textSecondary,
            indicatorColor: CodeOpsColors.primary,
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
            tabs: [
              const Tab(text: 'Overview'),
              ...completedRuns.map(
                  (r) => Tab(text: r.agentType.displayName)),
            ],
          ),
        ),

        // Tab content
        Expanded(
          child: TabBarView(
            controller: tabController,
            children: [
              // Overview tab
              SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Executive summary
                    ExecutiveSummaryCard(
                      job: job,
                      agentRuns: agentRuns,
                      summaryMd: job.summaryMd,
                    ),
                    const SizedBox(height: 24),

                    // Health trend
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: CodeOpsColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: CodeOpsColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Health Trend (30 days)',
                            style: TextStyle(
                              color: CodeOpsColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          trendAsync.when(
                            loading: () => const SizedBox(
                              height: 220,
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: CodeOpsColors.primary,
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                            error: (_, __) => const SizedBox(
                              height: 220,
                              child: Center(
                                child: Text(
                                  'Failed to load trend data',
                                  style: TextStyle(
                                    color: CodeOpsColors.textTertiary,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            data: (snapshots) =>
                                TrendChart(snapshots: snapshots),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Agent report tabs
              ...completedRuns.map((run) => Padding(
                    padding: const EdgeInsets.all(16),
                    child: AgentReportTab(agentRun: run),
                  )),
            ],
          ),
        ),
      ],
    );
  }
}
