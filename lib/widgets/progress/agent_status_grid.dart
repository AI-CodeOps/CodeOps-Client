/// A responsive grid of [AgentCard] widgets showing all agents in a job.
///
/// Uses [sortedAgentProgressProvider] for rich real-time data. Optionally
/// displays a [VeraCard] at the top during consolidation/syncing phases.
library;

import 'package:flutter/material.dart';

import '../../models/agent_progress.dart';
import '../../providers/wizard_providers.dart';
import 'agent_card.dart';
import 'vera_card.dart';

/// Displays a grid of agent status cards for a running job.
///
/// Consumes a sorted list of [AgentProgress] from the provider layer.
/// Shows a [VeraCard] at the top when the job phase is consolidation
/// or later.
class AgentStatusGrid extends StatelessWidget {
  /// Sorted list of agent progress data.
  final List<AgentProgress> agents;

  /// The current job execution phase (controls Vera card visibility).
  final JobExecutionPhase phase;

  /// Number of columns in the grid.
  final int columns;

  /// Creates an [AgentStatusGrid].
  const AgentStatusGrid({
    super.key,
    required this.agents,
    required this.phase,
    this.columns = 3,
  });

  @override
  Widget build(BuildContext context) {
    final showVera = phase == JobExecutionPhase.consolidating ||
        phase == JobExecutionPhase.syncing ||
        phase == JobExecutionPhase.complete;

    return LayoutBuilder(
      builder: (context, constraints) {
        final effectiveColumns = constraints.maxWidth < 600 ? 2 : columns;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Vera consolidation card
            if (showVera) ...[
              VeraCard(phase: phase),
              const SizedBox(height: 8),
            ],

            // Agent card grid
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: agents.map((progress) {
                final width =
                    (constraints.maxWidth - (effectiveColumns - 1) * 8) /
                        effectiveColumns;
                return SizedBox(
                  width: width,
                  child: AgentCard(progress: progress),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}
