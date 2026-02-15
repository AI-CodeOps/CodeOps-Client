/// Team overview and project cards grid for the health dashboard.
///
/// Displays aggregated team metrics and per-project health cards
/// with gauges, score deltas, and key metrics.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/health_providers.dart';
import '../../providers/project_providers.dart';
import '../../theme/colors.dart';
import '../reports/health_score_gauge.dart';

/// Displays the team overview metrics and per-project health cards.
class HealthOverviewPanel extends ConsumerWidget {
  /// Creates a [HealthOverviewPanel].
  const HealthOverviewPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamMetricsAsync = ref.watch(teamMetricsProvider);
    final projectsAsync = ref.watch(teamProjectsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Team overview cards
        Text('Team Overview',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        teamMetricsAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (e, _) => Text(
            'Failed to load team metrics: $e',
            style: const TextStyle(color: CodeOpsColors.error, fontSize: 13),
          ),
          data: (metrics) {
            if (metrics == null) {
              return const Text(
                'No team selected.',
                style: TextStyle(
                  color: CodeOpsColors.textTertiary,
                  fontSize: 13,
                ),
              );
            }
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _MetricCard(
                  label: 'Avg Score',
                  value: metrics.averageHealthScore?.toStringAsFixed(0) ?? '-',
                  icon: Icons.speed,
                  color: _scoreColor(metrics.averageHealthScore),
                ),
                _MetricCard(
                  label: 'Projects',
                  value: '${metrics.totalProjects ?? 0}',
                  icon: Icons.folder_outlined,
                  color: CodeOpsColors.primary,
                ),
                _MetricCard(
                  label: 'Below Threshold',
                  value: '${metrics.projectsBelowThreshold ?? 0}',
                  icon: Icons.warning_amber,
                  color: CodeOpsColors.warning,
                ),
                _MetricCard(
                  label: 'Open Criticals',
                  value: '${metrics.openCriticalFindings ?? 0}',
                  icon: Icons.error_outline,
                  color: CodeOpsColors.critical,
                ),
                _MetricCard(
                  label: 'Total Jobs',
                  value: '${metrics.totalJobs ?? 0}',
                  icon: Icons.work_outline,
                  color: CodeOpsColors.secondary,
                ),
                _MetricCard(
                  label: 'Total Findings',
                  value: '${metrics.totalFindings ?? 0}',
                  icon: Icons.search,
                  color: CodeOpsColors.textSecondary,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 32),

        // Project health cards
        Text('Project Health',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        projectsAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (e, _) => Text(
            'Failed to load projects: $e',
            style: const TextStyle(color: CodeOpsColors.error, fontSize: 13),
          ),
          data: (projects) {
            final active =
                projects.where((p) => p.isArchived != true).toList();
            if (active.isEmpty) {
              return const Text(
                'No projects found.',
                style: TextStyle(
                  color: CodeOpsColors.textTertiary,
                  fontSize: 13,
                ),
              );
            }
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: active.map((project) {
                return _ProjectHealthCard(
                  projectId: project.id,
                  projectName: project.name,
                  healthScore: project.healthScore,
                  onTap: () {
                    ref.read(selectedHealthProjectProvider.notifier).state =
                        project.id;
                  },
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  static Color _scoreColor(double? score) {
    if (score == null) return CodeOpsColors.textTertiary;
    if (score >= 80) return CodeOpsColors.success;
    if (score >= 60) return CodeOpsColors.warning;
    return CodeOpsColors.error;
  }
}

// ---------------------------------------------------------------------------
// Private widgets
// ---------------------------------------------------------------------------

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CodeOpsColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CodeOpsColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: CodeOpsColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectHealthCard extends ConsumerWidget {
  final String projectId;
  final String projectName;
  final int? healthScore;
  final VoidCallback onTap;

  const _ProjectHealthCard({
    required this.projectId,
    required this.projectName,
    required this.healthScore,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final delta = ref.watch(healthScoreDeltaProvider(projectId));
    final metricsAsync = ref.watch(projectMetricsProvider(projectId));
    final selectedId = ref.watch(selectedHealthProjectProvider);
    final isSelected = selectedId == projectId;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CodeOpsColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? CodeOpsColors.primary : CodeOpsColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              projectName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: CodeOpsColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                HealthScoreGauge(
                  score: healthScore ?? 0,
                  size: 64,
                  strokeWidth: 5,
                  showLabel: false,
                ),
                const SizedBox(width: 12),
                if (delta != null)
                  _DeltaChip(delta: delta),
              ],
            ),
            const SizedBox(height: 12),
            metricsAsync.when(
              loading: () => const SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(strokeWidth: 1),
              ),
              error: (_, __) => const SizedBox.shrink(),
              data: (metrics) {
                if (metrics == null) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MiniStat(
                      'Findings',
                      '${metrics.totalFindings ?? 0}',
                    ),
                    _MiniStat(
                      'Critical',
                      '${metrics.openCritical ?? 0}',
                    ),
                    if (metrics.lastAuditAt != null)
                      _MiniStat(
                        'Last Audit',
                        DateFormat('M/d HH:mm').format(metrics.lastAuditAt!),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DeltaChip extends StatelessWidget {
  final int delta;

  const _DeltaChip({required this.delta});

  @override
  Widget build(BuildContext context) {
    final isPositive = delta > 0;
    final isNeutral = delta == 0;
    final color = isNeutral
        ? CodeOpsColors.textTertiary
        : isPositive
            ? CodeOpsColors.success
            : CodeOpsColors.error;
    final icon = isNeutral
        ? Icons.remove
        : isPositive
            ? Icons.arrow_upward
            : Icons.arrow_downward;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 2),
        Text(
          isNeutral ? '0' : '${delta.abs()}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: CodeOpsColors.textTertiary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              color: CodeOpsColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
