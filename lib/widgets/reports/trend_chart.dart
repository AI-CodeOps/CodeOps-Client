/// Health trend chart widget.
///
/// Displays health score over time using fl_chart LineChart with
/// threshold bands and tooltips.
library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/health_snapshot.dart';
import '../../theme/colors.dart';
import '../../utils/constants.dart';

/// Displays a health score trend over time.
class TrendChart extends StatelessWidget {
  /// Health snapshots ordered by date.
  final List<HealthSnapshot> snapshots;

  /// Height of the chart.
  final double height;

  /// Called when a data point is tapped.
  final ValueChanged<HealthSnapshot>? onPointTap;

  /// Creates a [TrendChart].
  const TrendChart({
    super.key,
    required this.snapshots,
    this.height = 220,
    this.onPointTap,
  });

  @override
  Widget build(BuildContext context) {
    if (snapshots.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(
          child: Text(
            'No trend data available',
            style: TextStyle(
              color: CodeOpsColors.textTertiary,
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    final sorted = List.of(snapshots)
      ..sort((a, b) => (a.capturedAt ?? DateTime(0))
          .compareTo(b.capturedAt ?? DateTime(0)));

    final spots = <FlSpot>[];
    for (var i = 0; i < sorted.length; i++) {
      spots.add(FlSpot(i.toDouble(), sorted[i].healthScore.toDouble()));
    }

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 100,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 20,
            getDrawingHorizontalLine: (value) => FlLine(
              color: CodeOpsColors.border.withValues(alpha: 0.3),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 20,
                reservedSize: 32,
                getTitlesWidget: (value, meta) => Text(
                  '${value.toInt()}',
                  style: const TextStyle(
                    color: CodeOpsColors.textTertiary,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: _bottomInterval(sorted.length),
                reservedSize: 24,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= sorted.length) {
                    return const SizedBox.shrink();
                  }
                  final date = sorted[idx].capturedAt;
                  if (date == null) return const SizedBox.shrink();
                  return Text(
                    DateFormat('M/d').format(date),
                    style: const TextStyle(
                      color: CodeOpsColors.textTertiary,
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => CodeOpsColors.surfaceVariant,
              getTooltipItems: (spots) {
                return spots.map((spot) {
                  final idx = spot.x.toInt();
                  final snapshot =
                      idx < sorted.length ? sorted[idx] : null;
                  final date = snapshot?.capturedAt;
                  final dateStr = date != null
                      ? DateFormat('MMM d').format(date)
                      : '';
                  return LineTooltipItem(
                    '$dateStr\nScore: ${spot.y.toInt()}',
                    const TextStyle(
                      color: CodeOpsColors.textPrimary,
                      fontSize: 11,
                    ),
                  );
                }).toList();
              },
            ),
            touchCallback: (event, response) {
              if (event is FlTapUpEvent &&
                  response?.lineBarSpots != null &&
                  response!.lineBarSpots!.isNotEmpty &&
                  onPointTap != null) {
                final idx = response.lineBarSpots!.first.x.toInt();
                if (idx >= 0 && idx < sorted.length) {
                  onPointTap!(sorted[idx]);
                }
              }
            },
          ),
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: AppConstants.healthScoreGreenThreshold.toDouble(),
                color: CodeOpsColors.success.withValues(alpha: 0.3),
                strokeWidth: 1,
                dashArray: [4, 4],
              ),
              HorizontalLine(
                y: AppConstants.healthScoreYellowThreshold.toDouble(),
                color: CodeOpsColors.warning.withValues(alpha: 0.3),
                strokeWidth: 1,
                dashArray: [4, 4],
              ),
            ],
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              preventCurveOverShooting: true,
              color: CodeOpsColors.primary,
              barWidth: 2,
              dotData: FlDotData(
                show: sorted.length <= 30,
                getDotPainter: (spot, percent, bar, index) =>
                    FlDotCirclePainter(
                  radius: 3,
                  color: CodeOpsColors.primary,
                  strokeWidth: 1,
                  strokeColor: CodeOpsColors.surface,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: CodeOpsColors.primary.withValues(alpha: 0.08),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _bottomInterval(int count) {
    if (count <= 7) return 1;
    if (count <= 14) return 2;
    if (count <= 30) return 5;
    return (count / 6).ceilToDouble();
  }
}
