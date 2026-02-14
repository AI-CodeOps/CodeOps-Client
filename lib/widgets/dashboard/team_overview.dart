/// Team metrics overview card for the home dashboard.
///
/// Displays 6 stat cards sourced from [teamMetricsProvider]:
/// Projects, Total Jobs, Findings, Avg Health, Below Threshold, Open Critical.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/health_providers.dart';
import '../../theme/colors.dart';
import '../shared/error_panel.dart';

/// A row of team metric stat cards.
class TeamOverview extends ConsumerWidget {
  /// Creates a [TeamOverview] widget.
  const TeamOverview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(teamMetricsProvider);

    return metricsAsync.when(
      loading: () => const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (error, _) => ErrorPanel.fromException(
        error,
        onRetry: () => ref.invalidate(teamMetricsProvider),
      ),
      data: (metrics) {
        final avgHealth = metrics?.averageHealthScore;
        final belowThreshold = metrics?.projectsBelowThreshold;
        final openCritical = metrics?.openCriticalFindings;

        return Row(
          children: [
            _StatCard(
              label: 'Projects',
              value: _fmt(metrics?.totalProjects),
            ),
            const SizedBox(width: 12),
            _StatCard(
              label: 'Total Jobs',
              value: _fmt(metrics?.totalJobs),
            ),
            const SizedBox(width: 12),
            _StatCard(
              label: 'Findings',
              value: _fmt(metrics?.totalFindings),
            ),
            const SizedBox(width: 12),
            _StatCard(
              label: 'Avg Health',
              value: avgHealth != null
                  ? avgHealth.toStringAsFixed(0)
                  : '\u2014',
              valueColor: _healthColor(avgHealth),
            ),
            const SizedBox(width: 12),
            _StatCard(
              label: 'Below Threshold',
              value: _fmt(belowThreshold),
              valueColor: belowThreshold != null && belowThreshold > 0
                  ? CodeOpsColors.error
                  : null,
            ),
            const SizedBox(width: 12),
            _StatCard(
              label: 'Open Critical',
              value: _fmt(openCritical),
              valueColor: openCritical != null && openCritical > 0
                  ? CodeOpsColors.error
                  : null,
            ),
          ].map((child) {
            if (child is SizedBox) return child;
            return Expanded(child: child);
          }).toList(),
        );
      },
    );
  }

  static String _fmt(int? v) => v != null ? '$v' : '\u2014';

  static Color? _healthColor(double? score) {
    if (score == null) return null;
    if (score >= 80) return CodeOpsColors.success;
    if (score >= 60) return CodeOpsColors.warning;
    return CodeOpsColors.error;
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _StatCard({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: CodeOpsColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CodeOpsColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: valueColor,
                ),
          ),
        ],
      ),
    );
  }
}
