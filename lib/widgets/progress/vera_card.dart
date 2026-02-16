/// Card widget representing the Vera consolidation agent.
///
/// Displayed at the top of the agent card grid during the consolidation
/// and syncing phases. Shows an animated indicator while active.
library;

import 'package:flutter/material.dart';

import '../../providers/wizard_providers.dart';
import '../../theme/colors.dart';

/// Displays the status of the Vera consolidation phase.
///
/// Vera is not a regular agent — it runs after all agents complete to
/// deduplicate findings, calculate health scores, and build the
/// executive summary. This card appears only during consolidation/syncing.
class VeraCard extends StatelessWidget {
  /// The current job execution phase.
  final JobExecutionPhase phase;

  /// Creates a [VeraCard].
  const VeraCard({super.key, required this.phase});

  @override
  Widget build(BuildContext context) {
    final isActive = phase == JobExecutionPhase.consolidating ||
        phase == JobExecutionPhase.syncing;
    final isComplete = phase == JobExecutionPhase.complete;

    final statusText = switch (phase) {
      JobExecutionPhase.consolidating => 'Consolidating findings...',
      JobExecutionPhase.syncing => 'Syncing results to server...',
      JobExecutionPhase.complete => 'Analysis complete',
      _ => 'Waiting for agents to finish',
    };

    final statusColor = isComplete
        ? CodeOpsColors.success
        : isActive
            ? CodeOpsColors.secondary
            : CodeOpsColors.textTertiary;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CodeOpsColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive
              ? CodeOpsColors.secondary.withValues(alpha: 0.5)
              : CodeOpsColors.border,
        ),
        gradient: isActive
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  CodeOpsColors.surface,
                  CodeOpsColors.secondary.withValues(alpha: 0.05),
                ],
              )
            : null,
      ),
      child: Row(
        children: [
          // Vera icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: statusColor.withValues(alpha: 0.15),
            ),
            child: Icon(
              isComplete ? Icons.verified : Icons.hub,
              size: 18,
              color: statusColor,
            ),
          ),
          const SizedBox(width: 12),

          // Label and status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Vera',
                  style: TextStyle(
                    color: CodeOpsColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // Activity indicator
          if (isActive)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: CodeOpsColors.secondary,
              ),
            ),
          if (isComplete)
            const Icon(Icons.check_circle, size: 18, color: CodeOpsColors.success),
        ],
      ),
    );
  }
}
