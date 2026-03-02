/// Ingestion statistics chart and top sources table.
///
/// Renders an fl_chart [BarChart] showing log entries by log level,
/// a bar chart of entries by service, and summary statistics.
library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../models/logger_models.dart';
import '../../theme/colors.dart';

/// Level-based color mapping.
const _levelColors = <String, Color>{
  'TRACE': CodeOpsColors.textTertiary,
  'DEBUG': CodeOpsColors.secondary,
  'INFO': CodeOpsColors.success,
  'WARN': CodeOpsColors.warning,
  'ERROR': CodeOpsColors.error,
  'FATAL': CodeOpsColors.critical,
};

/// Bar chart showing log entries by level and top sources table.
class IngestionChart extends StatelessWidget {
  /// The storage usage response (used for by-level and by-service data).
  final StorageUsageResponse usage;

  /// Creates an [IngestionChart].
  const IngestionChart({super.key, required this.usage});

  @override
  Widget build(BuildContext context) {
    final levelEntries = usage.logEntriesByLevel.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final serviceEntries = usage.logEntriesByService.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: [
        // By-level bar chart.
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Entries by Level',
                  style: TextStyle(
                    color: CodeOpsColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: levelEntries.isEmpty
                      ? const Center(
                          child: Text(
                            'No data',
                            style: TextStyle(
                              color: CodeOpsColors.textTertiary,
                              fontSize: 13,
                            ),
                          ),
                        )
                      : BarChart(
                          BarChartData(
                            barGroups: levelEntries
                                .asMap()
                                .entries
                                .map(
                                  (e) => BarChartGroupData(
                                    x: e.key,
                                    barRods: [
                                      BarChartRodData(
                                        toY: e.value.value.toDouble(),
                                        color: _levelColors[
                                                e.value.key] ??
                                            CodeOpsColors.primary,
                                        width: 24,
                                        borderRadius:
                                            const BorderRadius.vertical(
                                          top: Radius.circular(4),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                .toList(),
                            titlesData: FlTitlesData(
                              topTitles: const AxisTitles(
                                  sideTitles:
                                      SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(
                                  sideTitles:
                                      SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (v, _) {
                                    final i = v.toInt();
                                    if (i < 0 ||
                                        i >= levelEntries.length) {
                                      return const SizedBox.shrink();
                                    }
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                          top: 4),
                                      child: Text(
                                        levelEntries[i].key,
                                        style: const TextStyle(
                                          fontSize: 9,
                                          color: CodeOpsColors
                                              .textSecondary,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              leftTitles: const AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 50,
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            gridData: const FlGridData(show: false),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1, color: CodeOpsColors.border),

        // Top sources table.
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Top Sources by Volume',
                  style: TextStyle(
                    color: CodeOpsColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: serviceEntries.isEmpty
                      ? const Center(
                          child: Text(
                            'No sources',
                            style: TextStyle(
                              color: CodeOpsColors.textTertiary,
                              fontSize: 13,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: serviceEntries.length,
                          itemBuilder: (ctx, i) {
                            final e = serviceEntries[i];
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 20,
                                    child: Text(
                                      '${i + 1}.',
                                      style: const TextStyle(
                                        color:
                                            CodeOpsColors.textTertiary,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      e.key,
                                      style: const TextStyle(
                                        color:
                                            CodeOpsColors.textPrimary,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    _formatCount(e.value),
                                    style: const TextStyle(
                                      color: CodeOpsColors.textPrimary,
                                      fontSize: 11,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
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
