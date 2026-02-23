/// Card displaying a workstation profile summary.
///
/// Shows name, default star indicator, service count, startup order
/// preview, health summary, and optional solution source.
library;

import 'package:flutter/material.dart';

import '../../models/registry_enums.dart';
import '../../models/registry_models.dart';
import '../../theme/colors.dart';

/// Workstation profile summary card.
///
/// Tapping the card calls [onTap]. The [onStartAll] button shows the
/// startup intent (informational — actual start is OS-level).
class WorkstationCard extends StatelessWidget {
  /// The workstation profile to display.
  final WorkstationProfileResponse profile;

  /// Called when the card is tapped.
  final VoidCallback? onTap;

  /// Called when the Start All button is tapped.
  final VoidCallback? onStartAll;

  /// Creates a [WorkstationCard].
  const WorkstationCard({
    super.key,
    required this.profile,
    this.onTap,
    this.onStartAll,
  });

  @override
  Widget build(BuildContext context) {
    final services = profile.services ?? [];
    final serviceCount = services.length;
    final isDefault = profile.isDefault == true;

    return Card(
      color: CodeOpsColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isDefault
              ? CodeOpsColors.primary.withValues(alpha: 0.5)
              : CodeOpsColors.border,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: name + default star + service count
              Row(
                children: [
                  if (isDefault) ...[
                    const Icon(Icons.star, size: 18,
                        color: CodeOpsColors.warning),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Text(
                      profile.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: CodeOpsColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    '$serviceCount service${serviceCount == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: CodeOpsColors.textTertiary,
                    ),
                  ),
                ],
              ),

              // Subtitle: default + solution source
              if (isDefault || profile.solutionId != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (isDefault)
                      const Text(
                        'Default profile',
                        style: TextStyle(
                          fontSize: 12,
                          color: CodeOpsColors.textTertiary,
                        ),
                      ),
                    if (isDefault && profile.solutionId != null)
                      const Text(
                        ' · ',
                        style: TextStyle(
                          fontSize: 12,
                          color: CodeOpsColors.textTertiary,
                        ),
                      ),
                    if (profile.solutionId != null)
                      const Text(
                        'Created from solution',
                        style: TextStyle(
                          fontSize: 12,
                          color: CodeOpsColors.textTertiary,
                        ),
                      ),
                  ],
                ),
              ],

              if (services.isNotEmpty) ...[
                const SizedBox(height: 10),
                // Startup sequence preview
                Text(
                  _startupSequence(services),
                  style: const TextStyle(
                    fontSize: 12,
                    color: CodeOpsColors.textSecondary,
                    fontFamily: 'monospace',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                // Health summary + Start All
                Row(
                  children: [
                    _HealthSummary(services: services),
                    const Spacer(),
                    if (onStartAll != null)
                      TextButton.icon(
                        onPressed: onStartAll,
                        icon: const Icon(Icons.play_arrow, size: 16),
                        label: const Text('Start All',
                            style: TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(
                          foregroundColor: CodeOpsColors.success,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _startupSequence(List<WorkstationServiceEntry> services) {
    final ordered = List<WorkstationServiceEntry>.from(services);
    ordered.sort((a, b) =>
        (a.startupPosition ?? 999).compareTo(b.startupPosition ?? 999));
    return ordered.map((s) => s.name).join(' → ');
  }
}

class _HealthSummary extends StatelessWidget {
  final List<WorkstationServiceEntry> services;

  const _HealthSummary({required this.services});

  @override
  Widget build(BuildContext context) {
    final upCount =
        services.where((s) => s.healthStatus == HealthStatus.up).length;
    final degradedCount =
        services.where((s) => s.healthStatus == HealthStatus.degraded).length;
    final downCount =
        services.where((s) => s.healthStatus == HealthStatus.down).length;

    String label;
    Color color;

    if (downCount > 0) {
      label = '$downCount down';
      color = CodeOpsColors.error;
    } else if (degradedCount > 0) {
      label = '$degradedCount degraded';
      color = CodeOpsColors.warning;
    } else if (upCount == services.length) {
      label = 'All healthy';
      color = CodeOpsColors.success;
    } else {
      label = '$upCount/${services.length} healthy';
      color = CodeOpsColors.textTertiary;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: color),
        ),
      ],
    );
  }
}
