/// Sidebar panel showing topology statistics.
///
/// Displays total services, dependencies, solutions, orphaned services,
/// max dependency depth, and services with no deps/consumers.
library;

import 'package:flutter/material.dart';

import '../../models/registry_models.dart';
import '../../theme/colors.dart';

/// Sidebar panel showing topology statistics.
///
/// Maps each stat from [TopologyStatsResponse] to a labeled row.
/// Orphaned services are highlighted in red when > 0.
class TopologyStatsPanel extends StatelessWidget {
  /// The topology statistics data.
  final TopologyStatsResponse stats;

  /// Creates a [TopologyStatsPanel].
  const TopologyStatsPanel({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: CodeOpsColors.surface,
        border: Border(
          right: BorderSide(color: CodeOpsColors.divider),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Topology Stats',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: CodeOpsColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _StatRow(
            label: 'Total Services',
            value: '${stats.totalServices}',
          ),
          const SizedBox(height: 8),
          _StatRow(
            label: 'Dependencies',
            value: '${stats.totalDependencies}',
          ),
          const SizedBox(height: 8),
          _StatRow(
            label: 'Solutions',
            value: '${stats.totalSolutions}',
          ),
          const SizedBox(height: 8),
          _StatRow(
            label: 'No Dependencies',
            value: '${stats.servicesWithNoDependencies}',
          ),
          const SizedBox(height: 8),
          _StatRow(
            label: 'No Consumers',
            value: '${stats.servicesWithNoConsumers}',
          ),
          const SizedBox(height: 8),
          _StatRow(
            label: 'Orphaned',
            value: '${stats.orphanedServices}',
            valueColor: stats.orphanedServices > 0
                ? CodeOpsColors.error
                : null,
          ),
          const SizedBox(height: 8),
          _StatRow(
            label: 'Max Depth',
            value: '${stats.maxDependencyDepth}',
          ),
        ],
      ),
    );
  }
}

/// A labeled stat row.
class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _StatRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: CodeOpsColors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: valueColor ?? CodeOpsColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
