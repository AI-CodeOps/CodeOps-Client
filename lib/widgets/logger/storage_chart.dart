/// Storage usage pie chart and breakdown panel.
///
/// Renders an fl_chart [PieChart] showing log entries by service,
/// plus summary statistics from [StorageUsageResponse].
library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../models/logger_models.dart';
import '../../theme/colors.dart';

/// Pre-defined palette for service slices.
const _sliceColors = <Color>[
  CodeOpsColors.primary,
  CodeOpsColors.secondary,
  Color(0xFFF97316),
  CodeOpsColors.success,
  Color(0xFFA855F7),
  Color(0xFFEC4899),
  Color(0xFF14B8A6),
  Color(0xFFEAB308),
  Color(0xFF3B82F6),
  Color(0xFF78716C),
];

/// Pie chart showing storage breakdown by service.
class StorageChart extends StatelessWidget {
  /// The storage usage response.
  final StorageUsageResponse usage;

  /// Creates a [StorageChart].
  const StorageChart({super.key, required this.usage});

  @override
  Widget build(BuildContext context) {
    final entries = usage.logEntriesByService.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Row(
      children: [
        // Pie chart.
        Expanded(
          flex: 2,
          child: entries.isEmpty
              ? const Center(
                  child: Text(
                    'No data',
                    style: TextStyle(
                      color: CodeOpsColors.textTertiary,
                      fontSize: 13,
                    ),
                  ),
                )
              : PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: entries
                        .asMap()
                        .entries
                        .map(
                          (e) => PieChartSectionData(
                            value: e.value.value.toDouble(),
                            color: _sliceColors[
                                e.key % _sliceColors.length],
                            radius: 60,
                            title: '',
                          ),
                        )
                        .toList(),
                  ),
                ),
        ),

        // Legend + stats.
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatRow(
                  label: 'Total Log Entries',
                  value: _formatCount(usage.totalLogEntries),
                ),
                _StatRow(
                  label: 'Metric Data Points',
                  value: _formatCount(usage.totalMetricDataPoints),
                ),
                _StatRow(
                  label: 'Trace Spans',
                  value: _formatCount(usage.totalTraceSpans),
                ),
                _StatRow(
                  label: 'Active Policies',
                  value: '${usage.activeRetentionPolicies}',
                ),
                const SizedBox(height: 12),
                const Text(
                  'By Service',
                  style: TextStyle(
                    color: CodeOpsColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                ...entries.asMap().entries.map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: _sliceColors[
                                    e.key % _sliceColors.length],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                e.value.key,
                                style: const TextStyle(
                                  color: CodeOpsColors.textPrimary,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            Text(
                              _formatCount(e.value.value),
                              style: const TextStyle(
                                color: CodeOpsColors.textPrimary,
                                fontSize: 11,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Formats a count with K/M suffixes.
  String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

/// A label–value stat row.
class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: CodeOpsColors.textSecondary,
              fontSize: 11,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: CodeOpsColors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
