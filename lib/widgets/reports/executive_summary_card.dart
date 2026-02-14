/// Executive summary card for job reports.
///
/// Displays job metadata, health gauge, severity counts, and markdown summary.
library;

import 'package:flutter/material.dart';

import '../../models/agent_run.dart';
import '../../models/enums.dart';
import '../../models/qa_job.dart';
import '../../theme/colors.dart';
import '../../utils/date_utils.dart';
import 'health_score_gauge.dart';
import 'markdown_renderer.dart';
import 'severity_chart.dart';

/// Executive summary card showing job overview and key metrics.
class ExecutiveSummaryCard extends StatelessWidget {
  /// The job being summarized.
  final QaJob job;

  /// Agent runs for this job.
  final List<AgentRun> agentRuns;

  /// Markdown summary content.
  final String? summaryMd;

  /// Creates an [ExecutiveSummaryCard].
  const ExecutiveSummaryCard({
    super.key,
    required this.job,
    required this.agentRuns,
    this.summaryMd,
  });

  @override
  Widget build(BuildContext context) {
    final severityCounts = <Severity, int>{
      Severity.critical: job.criticalCount ?? 0,
      Severity.high: job.highCount ?? 0,
      Severity.medium: job.mediumCount ?? 0,
      Severity.low: job.lowCount ?? 0,
    };

    final resultColor = switch (job.overallResult) {
      JobResult.pass => CodeOpsColors.success,
      JobResult.warn => CodeOpsColors.warning,
      JobResult.fail => CodeOpsColors.error,
      null => CodeOpsColors.textTertiary,
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CodeOpsColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CodeOpsColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: title + metadata
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.name ??
                          '${job.mode.displayName} - ${job.projectName ?? "Job"}',
                      style: const TextStyle(
                        color: CodeOpsColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        _MetaChip(
                          icon: Icons.folder_outlined,
                          label: job.projectName ?? 'N/A',
                        ),
                        if (job.branch != null)
                          _MetaChip(
                            icon: Icons.call_split,
                            label: job.branch!,
                          ),
                        _MetaChip(
                          icon: Icons.category_outlined,
                          label: job.mode.displayName,
                        ),
                        if (job.completedAt != null)
                          _MetaChip(
                            icon: Icons.schedule,
                            label: formatTimeAgo(job.completedAt!),
                          ),
                        if (job.startedByName != null)
                          _MetaChip(
                            icon: Icons.person_outline,
                            label: job.startedByName!,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Result badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: resultColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                      color: resultColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  job.overallResult?.displayName ?? 'N/A',
                  style: TextStyle(
                    color: resultColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: CodeOpsColors.divider, height: 1),
          const SizedBox(height: 20),

          // Metrics row: gauge + severity chart + agent stats
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Health score gauge
              if (job.healthScore != null)
                HealthScoreGauge(score: job.healthScore!),
              if (job.healthScore != null) const SizedBox(width: 24),

              // Severity breakdown
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Findings by Severity',
                      style: TextStyle(
                        color: CodeOpsColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SeverityChart(
                      counts: severityCounts,
                      mode: SeverityChartMode.bar,
                      height: 100,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),

              // Agent summary
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Agents',
                      style: TextStyle(
                        color: CodeOpsColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...agentRuns.map((run) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: _AgentRow(run: run),
                        )),
                  ],
                ),
              ),
            ],
          ),

          // Summary markdown
          if (summaryMd != null && summaryMd!.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Divider(color: CodeOpsColors.divider, height: 1),
            const SizedBox(height: 16),
            const Text(
              'Summary',
              style: TextStyle(
                color: CodeOpsColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            MarkdownRenderer(
              content: summaryMd!,
              shrinkWrap: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: CodeOpsColors.textTertiary),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: CodeOpsColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _AgentRow extends StatelessWidget {
  final AgentRun run;

  const _AgentRow({required this.run});

  @override
  Widget build(BuildContext context) {
    final resultColor = switch (run.result) {
      AgentResult.pass => CodeOpsColors.success,
      AgentResult.warn => CodeOpsColors.warning,
      AgentResult.fail => CodeOpsColors.error,
      null => CodeOpsColors.textTertiary,
    };

    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: resultColor,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            run.agentType.displayName,
            style: const TextStyle(
              color: CodeOpsColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
        Text(
          '${run.score ?? "-"}',
          style: TextStyle(
            color: resultColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
