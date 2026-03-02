/// Summary statistics bar for a trace.
///
/// Displays total duration, span count, service count, and error count
/// in a compact horizontal bar at the top of the trace detail view.
library;

import 'package:flutter/material.dart';

import '../../models/logger_models.dart';
import '../../theme/colors.dart';

/// Compact summary bar showing trace-level statistics.
class TraceSummaryBar extends StatelessWidget {
  /// The waterfall response containing trace metadata.
  final TraceWaterfallResponse waterfall;

  /// Creates a [TraceSummaryBar].
  const TraceSummaryBar({super.key, required this.waterfall});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: CodeOpsColors.surface,
        border: Border(bottom: BorderSide(color: CodeOpsColors.border)),
      ),
      child: Row(
        children: [
          _StatChip(
            icon: Icons.timer_outlined,
            label: 'Duration',
            value: _formatDuration(waterfall.totalDurationMs),
          ),
          const SizedBox(width: 24),
          _StatChip(
            icon: Icons.account_tree_outlined,
            label: 'Spans',
            value: '${waterfall.spanCount}',
          ),
          const SizedBox(width: 24),
          _StatChip(
            icon: Icons.dns_outlined,
            label: 'Services',
            value: '${waterfall.serviceCount}',
          ),
          const SizedBox(width: 24),
          _StatChip(
            icon: Icons.error_outline,
            label: 'Errors',
            value: waterfall.hasErrors ? 'Yes' : 'None',
            valueColor:
                waterfall.hasErrors ? CodeOpsColors.error : CodeOpsColors.success,
          ),
          const Spacer(),
          Text(
            'Trace ${waterfall.traceId.length > 8 ? waterfall.traceId.substring(0, 8) : waterfall.traceId}',
            style: const TextStyle(
              color: CodeOpsColors.textTertiary,
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  /// Formats milliseconds to a human-readable duration.
  String _formatDuration(int ms) {
    if (ms < 1000) return '${ms}ms';
    if (ms < 60000) return '${(ms / 1000).toStringAsFixed(1)}s';
    return '${(ms / 60000).toStringAsFixed(1)}m';
  }
}

/// A single statistic chip with icon, label, and value.
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: CodeOpsColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: const TextStyle(
            color: CodeOpsColors.textSecondary,
            fontSize: 11,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? CodeOpsColors.textPrimary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
