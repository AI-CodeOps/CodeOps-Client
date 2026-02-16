/// Card widget displaying the status of a single agent in a job.
///
/// Shows the agent type icon, name, current status, elapsed time,
/// progress bar, severity badges, score gauge, and expandable output
/// terminal. Color-coded by agent type and status.
library;

import 'package:flutter/material.dart';

import '../../models/agent_progress.dart';
import '../../models/enums.dart';
import '../../theme/colors.dart';
import '../../utils/date_utils.dart';
import 'agent_output_terminal.dart';

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

/// Displays the real-time status of a single agent within a job.
///
/// Enhanced version that consumes [AgentProgress] for rich detail:
/// progress bar, severity badges, score gauge, and expandable terminal.
class AgentCard extends StatefulWidget {
  /// The agent's real-time progress data.
  final AgentProgress progress;

  /// Creates an [AgentCard].
  const AgentCard({super.key, required this.progress});

  @override
  State<AgentCard> createState() => _AgentCardState();
}

class _AgentCardState extends State<AgentCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.progress;
    final meta = AgentTypeMetadata.all[p.agentType]!;
    final statusColor = _statusColor(p.status);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CodeOpsColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: p.isRunning
              ? p.agentColor.withValues(alpha: 0.5)
              : CodeOpsColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: icon + name + status badge + expand toggle
          Row(
            children: [
              Icon(meta.icon, size: 18, color: p.agentColor),
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
              _StatusBadge(status: p.status, color: statusColor),
              if (p.isRunning || p.outputLines.isNotEmpty) ...[
                const SizedBox(width: 6),
                InkWell(
                  onTap: () => setState(() => _expanded = !_expanded),
                  borderRadius: BorderRadius.circular(4),
                  child: Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: CodeOpsColors.textTertiary,
                  ),
                ),
              ],
            ],
          ),

          // Progress bar (when running)
          if (p.isRunning) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: p.progressPercent,
                minHeight: 3,
                backgroundColor: CodeOpsColors.border,
                color: p.progressColor,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  'Turn ${p.currentTurn}/${p.maxTurns}',
                  style: const TextStyle(
                    color: CodeOpsColors.textTertiary,
                    fontSize: 9,
                  ),
                ),
                const Spacer(),
                Text(
                  '${(p.progressPercent * 100).toInt()}%',
                  style: const TextStyle(
                    color: CodeOpsColors.textTertiary,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ],

          // Queue position (when pending)
          if (p.isQueued && p.queuePosition > 0) ...[
            const SizedBox(height: 6),
            Text(
              'Queue position: ${p.queuePosition}',
              style: const TextStyle(
                color: CodeOpsColors.textTertiary,
                fontSize: 10,
              ),
            ),
          ],

          const SizedBox(height: 6),

          // Elapsed time + model ID
          Row(
            children: [
              const Icon(Icons.timer_outlined,
                  size: 12, color: CodeOpsColors.textTertiary),
              const SizedBox(width: 4),
              Text(
                formatDuration(p.elapsed),
                style: const TextStyle(
                  color: CodeOpsColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              if (p.modelId != null) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    p.modelId!,
                    style: const TextStyle(
                      color: CodeOpsColors.textTertiary,
                      fontSize: 9,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),

          // Severity badges (when findings exist)
          if (p.totalFindings > 0) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                if (p.criticalCount > 0)
                  _SeverityBadge(
                    label: '${p.criticalCount} Critical',
                    color: CodeOpsColors.critical,
                  ),
                if (p.highCount > 0)
                  _SeverityBadge(
                    label: '${p.highCount} High',
                    color: CodeOpsColors.error,
                  ),
                if (p.mediumCount > 0)
                  _SeverityBadge(
                    label: '${p.mediumCount} Medium',
                    color: CodeOpsColors.warning,
                  ),
                if (p.lowCount > 0)
                  _SeverityBadge(
                    label: '${p.lowCount} Low',
                    color: CodeOpsColors.secondary,
                  ),
              ],
            ),
          ],

          // Score gauge (when complete with score)
          if (p.isComplete && p.score != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                _ScoreIndicator(score: p.score!, result: p.result),
                const SizedBox(width: 8),
                Text(
                  '${p.totalFindings} findings',
                  style: const TextStyle(
                    color: CodeOpsColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],

          // Error message (when failed)
          if (p.isFailed && p.errorMessage != null) ...[
            const SizedBox(height: 6),
            Text(
              p.errorMessage!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: CodeOpsColors.error,
                fontSize: 10,
              ),
            ),
          ],

          // Current activity (when running)
          if (p.isRunning && p.currentActivity != null) ...[
            const SizedBox(height: 4),
            Text(
              p.currentActivity!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: CodeOpsColors.textTertiary,
                fontSize: 10,
                fontFamily: 'monospace',
              ),
            ),
          ],

          // Expanded output terminal
          if (_expanded && p.outputLines.isNotEmpty) ...[
            const SizedBox(height: 8),
            AgentOutputTerminal(lines: p.outputLines),
          ],
        ],
      ),
    );
  }

  Color _statusColor(AgentStatus status) => switch (status) {
        AgentStatus.pending => CodeOpsColors.textTertiary,
        AgentStatus.running => CodeOpsColors.primary,
        AgentStatus.completed => CodeOpsColors.success,
        AgentStatus.failed => CodeOpsColors.error,
      };
}

class _StatusBadge extends StatelessWidget {
  final AgentStatus status;
  final Color color;

  const _StatusBadge({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      AgentStatus.pending => 'Queued',
      AgentStatus.running => 'Running',
      AgentStatus.completed => 'Done',
      AgentStatus.failed => 'Failed',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SeverityBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _SeverityBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ScoreIndicator extends StatelessWidget {
  final int score;
  final AgentResult? result;

  const _ScoreIndicator({required this.score, this.result});

  @override
  Widget build(BuildContext context) {
    final color = switch (result) {
      AgentResult.pass => CodeOpsColors.success,
      AgentResult.warn => CodeOpsColors.warning,
      AgentResult.fail => CodeOpsColors.error,
      null => CodeOpsColors.textTertiary,
    };

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Center(
        child: Text(
          '$score',
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
