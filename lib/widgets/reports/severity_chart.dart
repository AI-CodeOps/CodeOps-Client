/// Severity distribution chart widget.
///
/// Displays finding counts by severity in bar or donut mode using fl_chart.
library;

import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../models/enums.dart';
import '../../theme/colors.dart';

/// Display mode for the severity chart.
enum SeverityChartMode {
  /// Horizontal bar chart.
  bar,

  /// Donut/ring chart.
  donut,
}

/// Displays finding severity distribution as a bar or donut chart.
class SeverityChart extends StatelessWidget {
  /// Finding counts by severity.
  final Map<Severity, int> counts;

  /// Chart display mode.
  final SeverityChartMode mode;

  /// Height of the chart.
  final double height;

  /// Creates a [SeverityChart].
  const SeverityChart({
    super.key,
    required this.counts,
    this.mode = SeverityChartMode.bar,
    this.height = 200,
  });

  int get _total => counts.values.fold(0, (a, b) => a + b);

  @override
  Widget build(BuildContext context) {
    if (_total == 0) {
      return SizedBox(
        height: height,
        child: const Center(
          child: Text(
            'No findings',
            style: TextStyle(
              color: CodeOpsColors.textTertiary,
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: height,
      child: mode == SeverityChartMode.donut
          ? _buildDonutChart()
          : _buildBarChart(),
    );
  }

  Widget _buildDonutChart() {
    final sections = <PieChartSectionData>[];

    for (final severity in Severity.values) {
      final count = counts[severity] ?? 0;
      if (count == 0) continue;
      final percentage = (count / _total) * 100;

      sections.add(PieChartSectionData(
        color: CodeOpsColors.severityColors[severity]!,
        value: count.toDouble(),
        title: '${percentage.round()}%',
        titleStyle: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        radius: 40,
      ));
    }

    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 30,
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: Severity.values.map((severity) {
            final count = counts[severity] ?? 0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: CodeOpsColors.severityColors[severity],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${severity.displayName}: $count',
                    style: const TextStyle(
                      color: CodeOpsColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBarChart() {
    final maxCount = counts.values.fold(0, math.max);

    return Column(
      children: Severity.values.map((severity) {
        final count = counts[severity] ?? 0;
        final color = CodeOpsColors.severityColors[severity]!;
        final fraction = maxCount > 0 ? count / maxCount : 0.0;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: Row(
              children: [
                SizedBox(
                  width: 64,
                  child: Text(
                    severity.displayName,
                    style: const TextStyle(
                      color: CodeOpsColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        children: [
                          Container(
                            height: 16,
                            decoration: BoxDecoration(
                              color: CodeOpsColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: 16,
                            width: constraints.maxWidth * fraction,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 32,
                  child: Text(
                    '$count',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
