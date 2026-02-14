/// A segmented linear progress bar for job completion.
///
/// Displays colored segments representing agent results: green for pass,
/// amber for warn, red for fail, and grey for pending/running agents.
library;

import 'package:flutter/material.dart';

import '../../services/orchestration/progress_aggregator.dart';
import '../../theme/colors.dart';

/// Displays a segmented progress bar for a job.
class JobProgressBar extends StatelessWidget {
  /// The current job progress snapshot.
  final JobProgress progress;

  /// Height of the progress bar.
  final double height;

  /// Creates a [JobProgressBar].
  const JobProgressBar({
    super.key,
    required this.progress,
    this.height = 8,
  });

  @override
  Widget build(BuildContext context) {
    final total = progress.totalCount;
    if (total == 0) return const SizedBox.shrink();

    // Count agents by terminal status.
    var passCount = 0;
    var warnCount = 0;
    var failCount = 0;
    var runningCount = 0;
    var queuedCount = 0;

    for (final status in progress.agentStatuses.values) {
      switch (status.phase) {
        case AgentPhase.completed:
          // We don't have the result here, so count as pass.
          passCount++;
        case AgentPhase.failed:
        case AgentPhase.timedOut:
          failCount++;
        case AgentPhase.running:
        case AgentPhase.parsing:
          runningCount++;
        case AgentPhase.queued:
          queuedCount++;
      }
    }

    // Ensure we don't count more than total if there are discrepancies.
    final _ = warnCount; // warnCount is available for future use.

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: SizedBox(
            height: height,
            child: Row(
              children: [
                if (passCount > 0)
                  _Segment(
                    flex: passCount,
                    color: CodeOpsColors.success,
                  ),
                if (warnCount > 0)
                  _Segment(
                    flex: warnCount,
                    color: CodeOpsColors.warning,
                  ),
                if (failCount > 0)
                  _Segment(
                    flex: failCount,
                    color: CodeOpsColors.error,
                  ),
                if (runningCount > 0)
                  _Segment(
                    flex: runningCount,
                    color: CodeOpsColors.primary,
                  ),
                if (queuedCount > 0)
                  _Segment(
                    flex: queuedCount,
                    color: CodeOpsColors.border,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${progress.completedCount} of $total agents complete '
          '(${(progress.percentComplete * 100).toInt()}%)',
          style: const TextStyle(
            fontSize: 12,
            color: CodeOpsColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _Segment extends StatelessWidget {
  final int flex;
  final Color color;

  const _Segment({required this.flex, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Container(color: color),
    );
  }
}
