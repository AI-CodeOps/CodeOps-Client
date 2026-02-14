/// A responsive grid of [AgentCard] widgets showing all agents in a job.
///
/// Agents are sorted by status: running first, then queued, then completed,
/// then failed. Uses a 3-column layout by default.
library;

import 'package:flutter/material.dart';

import '../../services/orchestration/progress_aggregator.dart';
import 'agent_card.dart';

/// Displays a grid of agent status cards for a running job.
class AgentStatusGrid extends StatelessWidget {
  /// The current job progress snapshot.
  final JobProgress progress;

  /// Number of columns in the grid.
  final int columns;

  /// Creates an [AgentStatusGrid].
  const AgentStatusGrid({
    super.key,
    required this.progress,
    this.columns = 3,
  });

  @override
  Widget build(BuildContext context) {
    final statuses = progress.agentStatuses.values.toList();

    // Sort: running → queued → completed → failed/timedOut.
    statuses.sort((a, b) {
      final order = _phaseOrder(a.phase).compareTo(_phaseOrder(b.phase));
      if (order != 0) return order;
      return a.agentType.name.compareTo(b.agentType.name);
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        final effectiveColumns = constraints.maxWidth < 600 ? 2 : columns;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: statuses.map((status) {
            final width =
                (constraints.maxWidth - (effectiveColumns - 1) * 8) /
                    effectiveColumns;
            return SizedBox(
              width: width,
              child: AgentCard(status: status),
            );
          }).toList(),
        );
      },
    );
  }

  int _phaseOrder(AgentPhase phase) => switch (phase) {
        AgentPhase.running => 0,
        AgentPhase.parsing => 0,
        AgentPhase.queued => 1,
        AgentPhase.completed => 2,
        AgentPhase.failed => 3,
        AgentPhase.timedOut => 3,
      };
}
