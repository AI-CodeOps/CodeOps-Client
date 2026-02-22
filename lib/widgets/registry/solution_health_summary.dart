/// Aggregated health display for a solution.
///
/// Shows the overall aggregated health status plus a breakdown of
/// individual service health counts (UP, DOWN, DEGRADED, UNKNOWN).
library;

import 'package:flutter/material.dart';

import '../../models/registry_models.dart';
import '../../theme/colors.dart';
import 'service_status_badge.dart';

/// Aggregated health summary for a solution.
///
/// Displays overall health badge and per-status count chips
/// (Total, UP, DOWN, DEGRADED, UNKNOWN) in a summary row.
class SolutionHealthSummary extends StatelessWidget {
  /// The solution health data.
  final SolutionHealthResponse health;

  /// Creates a [SolutionHealthSummary].
  const SolutionHealthSummary({super.key, required this.health});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CodeOpsColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CodeOpsColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.monitor_heart_outlined,
                  size: 16, color: CodeOpsColors.textSecondary),
              const SizedBox(width: 8),
              const Text(
                'Health Summary',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: CodeOpsColors.textPrimary,
                ),
              ),
              const Spacer(),
              HealthIndicator(status: health.aggregatedHealth),
            ],
          ),
          const SizedBox(height: 12),
          // Counts row
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _CountChip(
                label: 'Total',
                count: health.totalServices,
                color: CodeOpsColors.textSecondary,
              ),
              _CountChip(
                label: 'Up',
                count: health.servicesUp,
                color: CodeOpsColors.success,
              ),
              _CountChip(
                label: 'Down',
                count: health.servicesDown,
                color: CodeOpsColors.error,
              ),
              _CountChip(
                label: 'Degraded',
                count: health.servicesDegraded,
                color: CodeOpsColors.warning,
              ),
              _CountChip(
                label: 'Unknown',
                count: health.servicesUnknown,
                color: CodeOpsColors.textTertiary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Individual count chip with colored label.
class _CountChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _CountChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$label: $count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
