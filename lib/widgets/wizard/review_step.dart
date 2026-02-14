/// Review step for the wizard.
///
/// Read-only summary cards showing Source, Agents, Configuration,
/// and Additional Context. Checks Claude Code status. Includes
/// estimated time calculation. Always valid.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/enums.dart';
import '../../models/project.dart';
import '../../providers/agent_providers.dart';
import '../../providers/wizard_providers.dart';
import '../../services/platform/claude_code_detector.dart';
import '../../theme/colors.dart';
import '../progress/agent_card.dart';

/// Review step for the wizard flow.
class ReviewStep extends ConsumerWidget {
  /// The selected project.
  final Project? project;

  /// The selected branch.
  final String? branch;

  /// The set of selected agents.
  final Set<AgentType> selectedAgents;

  /// The job configuration.
  final JobConfig config;

  /// Optional additional info widget for mode-specific data.
  final Widget? additionalInfo;

  /// Creates a [ReviewStep].
  const ReviewStep({
    super.key,
    this.project,
    this.branch,
    required this.selectedAgents,
    required this.config,
    this.additionalInfo,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final claudeStatus = ref.watch(claudeCodeStatusProvider);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Review & Launch',
            style: TextStyle(
              color: CodeOpsColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Confirm your configuration before launching.',
            style: TextStyle(
              color: CodeOpsColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),

          // Claude Code status check
          claudeStatus.when(
            loading: () => _StatusBanner(
              icon: Icons.hourglass_empty,
              color: CodeOpsColors.textTertiary,
              message: 'Checking Claude Code CLI...',
            ),
            error: (e, _) => _StatusBanner(
              icon: Icons.error_outline,
              color: CodeOpsColors.error,
              message: 'Claude Code CLI not available: $e',
            ),
            data: (status) => status == ClaudeCodeStatus.available
                ? _StatusBanner(
                    icon: Icons.check_circle_outline,
                    color: CodeOpsColors.success,
                    message:
                        'Claude Code CLI detected (${status.displayName})',
                  )
                : _StatusBanner(
                    icon: Icons.warning_amber,
                    color: CodeOpsColors.warning,
                    message:
                        'Claude Code CLI: ${status.displayName}. Please install it.',
                  ),
          ),
          const SizedBox(height: 16),

          // Source card
          _SummaryCard(
            title: 'Source',
            icon: Icons.folder_outlined,
            children: [
              _SummaryRow(
                label: 'Project',
                value: project?.name ?? 'Not selected',
              ),
              _SummaryRow(
                label: 'Branch',
                value: branch ?? 'Not selected',
              ),
              if (project?.techStack != null)
                _SummaryRow(
                  label: 'Tech Stack',
                  value: project!.techStack!,
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Agents card
          _SummaryCard(
            title: 'Agents',
            icon: Icons.smart_toy_outlined,
            children: [
              _SummaryRow(
                label: 'Selected',
                value:
                    '${selectedAgents.length} of ${AgentType.values.length}',
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: selectedAgents.map((agent) {
                  final meta = AgentTypeMetadata.all[agent]!;
                  return Chip(
                    avatar: Icon(meta.icon, size: 14),
                    label: Text(
                      meta.displayName,
                      style: const TextStyle(fontSize: 11),
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    backgroundColor: CodeOpsColors.surfaceVariant,
                    side: BorderSide.none,
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Configuration card
          _SummaryCard(
            title: 'Configuration',
            icon: Icons.tune,
            children: [
              _SummaryRow(
                label: 'Concurrent Agents',
                value: '${config.maxConcurrentAgents}',
              ),
              _SummaryRow(
                label: 'Agent Timeout',
                value: '${config.agentTimeoutMinutes} minutes',
              ),
              _SummaryRow(
                label: 'Max Turns',
                value: '${config.maxTurns}',
              ),
              _SummaryRow(
                label: 'Claude Model',
                value: config.claudeModel,
              ),
              _SummaryRow(
                label: 'Pass Threshold',
                value: '${config.passThreshold}',
              ),
              _SummaryRow(
                label: 'Warn Threshold',
                value: '${config.warnThreshold}',
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Additional Context card (if present)
          if (config.additionalContext.isNotEmpty) ...[
            _SummaryCard(
              title: 'Additional Context',
              icon: Icons.notes,
              children: [
                Text(
                  config.additionalContext,
                  style: const TextStyle(
                    color: CodeOpsColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // Mode-specific additional info
          if (additionalInfo != null) ...[
            additionalInfo!,
            const SizedBox(height: 12),
          ],

          // Estimated time
          _EstimatedTime(
            agentCount: selectedAgents.length,
            maxConcurrent: config.maxConcurrentAgents,
            timeoutMinutes: config.agentTimeoutMinutes,
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String message;

  const _StatusBanner({
    required this.icon,
    required this.color,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SummaryCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CodeOpsColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CodeOpsColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: CodeOpsColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: CodeOpsColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                color: CodeOpsColors.textTertiary,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: CodeOpsColors.textPrimary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EstimatedTime extends StatelessWidget {
  final int agentCount;
  final int maxConcurrent;
  final int timeoutMinutes;

  const _EstimatedTime({
    required this.agentCount,
    required this.maxConcurrent,
    required this.timeoutMinutes,
  });

  @override
  Widget build(BuildContext context) {
    final batches = (agentCount / maxConcurrent).ceil();
    final estimatedMinutes = batches * (timeoutMinutes ~/ 3); // ~1/3 of max

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CodeOpsColors.secondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: CodeOpsColors.secondary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule, size: 16, color: CodeOpsColors.secondary),
          const SizedBox(width: 8),
          Text(
            'Estimated time: ~$estimatedMinutes minutes',
            style: const TextStyle(
              color: CodeOpsColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
