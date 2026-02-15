/// Health trend chart and sub-score cards panel.
///
/// Displays a time-range-selectable trend chart, sub-score cards
/// (tech debt, dependency, test coverage), and findings by severity.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/health_providers.dart';
import '../../theme/colors.dart';
import '../reports/trend_chart.dart';

/// Displays the health trend chart with time range selector and sub-scores.
class HealthTrendPanel extends ConsumerWidget {
  /// The project ID to display trends for.
  final String projectId;

  /// Creates a [HealthTrendPanel].
  const HealthTrendPanel({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = ref.watch(healthTrendRangeProvider);
    final trendAsync = ref.watch(healthTrendProvider(projectId));
    final snapshotAsync = ref.watch(latestSnapshotProvider(projectId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with time range selector
        Row(
          children: [
            Text(
              'Health Trend',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            _TimeRangeSelector(
              selected: days,
              onChanged: (value) {
                ref.read(healthTrendRangeProvider.notifier).state = value;
              },
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Trend chart
        trendAsync.when(
          loading: () => const SizedBox(
            height: 220,
            child: Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (e, _) => SizedBox(
            height: 220,
            child: Center(
              child: Text(
                'Failed to load trend: $e',
                style: const TextStyle(
                  color: CodeOpsColors.error,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          data: (snapshots) => TrendChart(snapshots: snapshots),
        ),
        const SizedBox(height: 24),

        // Sub-score cards and findings breakdown
        snapshotAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (snapshot) {
            if (snapshot == null) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sub-Scores',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _SubScoreCard(
                      label: 'Tech Debt',
                      value: snapshot.techDebtScore,
                      icon: Icons.architecture,
                    ),
                    _SubScoreCard(
                      label: 'Dependencies',
                      value: snapshot.dependencyScore,
                      icon: Icons.inventory_2_outlined,
                    ),
                    _SubScoreCard(
                      label: 'Test Coverage',
                      value: snapshot.testCoveragePercent?.round(),
                      icon: Icons.check_circle_outline,
                      suffix: '%',
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _FindingsBySection(
                  findingsBySeverity: snapshot.findingsBySeverity,
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Private widgets
// ---------------------------------------------------------------------------

class _TimeRangeSelector extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;

  const _TimeRangeSelector({
    required this.selected,
    required this.onChanged,
  });

  static const _ranges = [7, 14, 30, 60, 90];

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<int>(
      segments: _ranges
          .map((d) => ButtonSegment(
                value: d,
                label: Text('${d}d', style: const TextStyle(fontSize: 12)),
              ))
          .toList(),
      selected: {selected},
      onSelectionChanged: (s) => onChanged(s.first),
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 8),
        ),
      ),
    );
  }
}

class _SubScoreCard extends StatelessWidget {
  final String label;
  final int? value;
  final IconData icon;
  final String suffix;

  const _SubScoreCard({
    required this.label,
    required this.value,
    required this.icon,
    this.suffix = '',
  });

  @override
  Widget build(BuildContext context) {
    final displayValue = value != null ? '$value$suffix' : '-';
    final color = _colorForScore(value);

    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CodeOpsColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CodeOpsColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 8),
          Text(
            displayValue,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
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

  static Color _colorForScore(int? score) {
    if (score == null) return CodeOpsColors.textTertiary;
    if (score >= 80) return CodeOpsColors.success;
    if (score >= 60) return CodeOpsColors.warning;
    return CodeOpsColors.error;
  }
}

class _FindingsBySection extends StatelessWidget {
  final String? findingsBySeverity;

  const _FindingsBySection({required this.findingsBySeverity});

  @override
  Widget build(BuildContext context) {
    if (findingsBySeverity == null || findingsBySeverity!.isEmpty) {
      return const SizedBox.shrink();
    }

    Map<String, dynamic> parsed;
    try {
      parsed = jsonDecode(findingsBySeverity!) as Map<String, dynamic>;
    } catch (_) {
      return const SizedBox.shrink();
    }

    if (parsed.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Findings by Severity',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: parsed.entries.map((entry) {
            final severity = entry.key;
            final count = entry.value is int
                ? entry.value as int
                : int.tryParse(entry.value.toString()) ?? 0;
            return _SeverityChip(severity: severity, count: count);
          }).toList(),
        ),
      ],
    );
  }
}

class _SeverityChip extends StatelessWidget {
  final String severity;
  final int count;

  const _SeverityChip({required this.severity, required this.count});

  @override
  Widget build(BuildContext context) {
    final color = switch (severity.toUpperCase()) {
      'CRITICAL' => CodeOpsColors.critical,
      'HIGH' => CodeOpsColors.error,
      'MEDIUM' => CodeOpsColors.warning,
      'LOW' => CodeOpsColors.secondary,
      _ => CodeOpsColors.textTertiary,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
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
            '$severity: $count',
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
