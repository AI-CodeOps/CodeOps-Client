/// Card widget displaying the status of a single agent in a job.
///
/// Shows the agent type icon, name, current phase, elapsed time,
/// and score/findings when complete. Color-coded by phase.
library;

import 'package:flutter/material.dart';

import '../../models/enums.dart';
import '../../services/orchestration/progress_aggregator.dart';
import '../../theme/colors.dart';
import '../../utils/date_utils.dart';

/// Metadata for each agent type (icon, display name, description).
class AgentTypeMetadata {
  /// Material icon for the agent.
  final IconData icon;

  /// Display name.
  final String displayName;

  /// Short description of what the agent does.
  final String description;

  /// Creates an [AgentTypeMetadata].
  const AgentTypeMetadata({
    required this.icon,
    required this.displayName,
    required this.description,
  });

  /// Lookup map for all agent types.
  static const Map<AgentType, AgentTypeMetadata> all = {
    AgentType.security: AgentTypeMetadata(
      icon: Icons.shield,
      displayName: 'Security',
      description: 'Auth, injection, secrets, OWASP, CVEs',
    ),
    AgentType.codeQuality: AgentTypeMetadata(
      icon: Icons.auto_fix_high,
      displayName: 'Code Quality',
      description: 'Patterns, complexity, DRY, naming, SOLID',
    ),
    AgentType.buildHealth: AgentTypeMetadata(
      icon: Icons.build,
      displayName: 'Build Health',
      description: 'Configs, build stability, CI integration',
    ),
    AgentType.completeness: AgentTypeMetadata(
      icon: Icons.checklist,
      displayName: 'Completeness',
      description: 'TODOs, stubs, placeholders, dead code',
    ),
    AgentType.apiContract: AgentTypeMetadata(
      icon: Icons.api,
      displayName: 'API Contract',
      description: 'REST conventions, OpenAPI, request/response',
    ),
    AgentType.testCoverage: AgentTypeMetadata(
      icon: Icons.verified,
      displayName: 'Test Coverage',
      description: 'Test presence, quality, gaps, assertions',
    ),
    AgentType.uiUx: AgentTypeMetadata(
      icon: Icons.palette,
      displayName: 'UI/UX',
      description: 'Components, accessibility, responsiveness',
    ),
    AgentType.documentation: AgentTypeMetadata(
      icon: Icons.description,
      displayName: 'Documentation',
      description: 'README, inline docs, API docs, changelogs',
    ),
    AgentType.database: AgentTypeMetadata(
      icon: Icons.storage,
      displayName: 'Database',
      description: 'Schema, migrations, queries, indexing',
    ),
    AgentType.performance: AgentTypeMetadata(
      icon: Icons.speed,
      displayName: 'Performance',
      description: 'N+1, memory, blocking calls, resource leaks',
    ),
    AgentType.dependency: AgentTypeMetadata(
      icon: Icons.inventory_2,
      displayName: 'Dependency',
      description: 'Outdated versions, CVEs, license compliance',
    ),
    AgentType.architecture: AgentTypeMetadata(
      icon: Icons.account_tree,
      displayName: 'Architecture',
      description: 'Patterns, coupling, layering, modularity',
    ),
  };
}

/// Displays the status of a single agent within a job.
class AgentCard extends StatelessWidget {
  /// The agent's current progress status.
  final AgentProgressStatus status;

  /// Creates an [AgentCard].
  const AgentCard({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final meta = AgentTypeMetadata.all[status.agentType]!;
    final phaseColor = _phaseColor(status.phase);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CodeOpsColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: status.phase == AgentPhase.running
              ? CodeOpsColors.primary.withValues(alpha: 0.5)
              : CodeOpsColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: icon + name + phase badge
          Row(
            children: [
              Icon(meta.icon, size: 18, color: phaseColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  meta.displayName,
                  style: const TextStyle(
                    color: CodeOpsColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: phaseColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  status.phase.displayName,
                  style: TextStyle(
                    color: phaseColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Elapsed time
          Row(
            children: [
              const Icon(Icons.timer_outlined,
                  size: 12, color: CodeOpsColors.textTertiary),
              const SizedBox(width: 4),
              Text(
                formatDuration(status.elapsed),
                style: const TextStyle(
                  color: CodeOpsColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),

          // Findings count (when available)
          if (status.findingsCount != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.bug_report_outlined,
                    size: 12, color: CodeOpsColors.textTertiary),
                const SizedBox(width: 4),
                Text(
                  '${status.findingsCount} findings',
                  style: const TextStyle(
                    color: CodeOpsColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],

          // Last output line (when running)
          if (status.lastOutputLine != null &&
              status.phase == AgentPhase.running) ...[
            const SizedBox(height: 4),
            Text(
              status.lastOutputLine!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: CodeOpsColors.textTertiary,
                fontSize: 10,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _phaseColor(AgentPhase phase) => switch (phase) {
        AgentPhase.queued => CodeOpsColors.textTertiary,
        AgentPhase.running => CodeOpsColors.primary,
        AgentPhase.parsing => CodeOpsColors.secondary,
        AgentPhase.completed => CodeOpsColors.success,
        AgentPhase.failed => CodeOpsColors.error,
        AgentPhase.timedOut => CodeOpsColors.warning,
      };
}
