/// Summary bar displaying aggregate statistics for all agents in a job.
///
/// Shows counts for running, completed, failed agents, and total findings
/// with severity breakdown. Positioned above the agent card grid.
library;

import 'package:flutter/material.dart';

import '../../models/agent_progress.dart';
import '../../theme/colors.dart';

/// Displays a horizontal summary of agent progress statistics.
///
/// Shows running/completed/failed counts and finding severity totals
/// in a compact, information-dense bar.
class ProgressSummaryBar extends StatelessWidget {
  /// The aggregate summary statistics.
  final AgentProgressSummary summary;

  /// Creates a [ProgressSummaryBar].
  const ProgressSummaryBar({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: CodeOpsColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CodeOpsColors.border),
      ),
      child: Row(
        children: [
          // Agent status counts
          _StatusChip(
            icon: Icons.play_circle_outline,
            label: 'Running',
            value: summary.running,
            color: CodeOpsColors.primary,
          ),
          const SizedBox(width: 16),
          _StatusChip(
            icon: Icons.hourglass_empty,
            label: 'Queued',
            value: summary.queued,
            color: CodeOpsColors.textTertiary,
          ),
          const SizedBox(width: 16),
          _StatusChip(
            icon: Icons.check_circle_outline,
            label: 'Done',
            value: summary.completed,
            color: CodeOpsColors.success,
          ),
          if (summary.failed > 0) ...[
            const SizedBox(width: 16),
            _StatusChip(
              icon: Icons.error_outline,
              label: 'Failed',
              value: summary.failed,
              color: CodeOpsColors.error,
            ),
          ],

          const Spacer(),

          // Findings summary
          if (summary.totalFindings > 0) ...[
            const Icon(Icons.bug_report_outlined,
                size: 14, color: CodeOpsColors.textTertiary),
            const SizedBox(width: 4),
            Text(
              '${summary.totalFindings} findings',
              style: const TextStyle(
                color: CodeOpsColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (summary.totalCritical > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: CodeOpsColors.critical.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${summary.totalCritical} critical',
                  style: const TextStyle(
                    color: CodeOpsColors.critical,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],

          // Progress fraction
          const SizedBox(width: 16),
          Text(
            '${summary.completed + summary.failed}/${summary.total}',
            style: const TextStyle(
              color: CodeOpsColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;

  const _StatusChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          '$value',
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          label,
          style: TextStyle(
            color: color.withValues(alpha: 0.7),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
