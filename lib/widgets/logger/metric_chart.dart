/// Time-series line chart for metric data with overlay support.
///
/// Uses [fl_chart] to render one or more [MetricTimeSeriesResponse]
/// as colored line series. Supports tooltips, grid lines, and
/// automatic axis labeling.
library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/logger_models.dart';
import '../../theme/colors.dart';

/// A time-series line chart for one or more metric series.
class MetricChart extends StatelessWidget {
  /// The primary time-series data.
  final MetricTimeSeriesResponse? series;

  /// Optional overlay series (rendered in different colors).
  final List<MetricTimeSeriesResponse> overlays;

  /// Creates a [MetricChart].
  const MetricChart({
    super.key,
    this.series,
    this.overlays = const [],
  });

  static const _lineColors = [
    CodeOpsColors.primary,
    CodeOpsColors.secondary,
    CodeOpsColors.success,
    CodeOpsColors.warning,
    CodeOpsColors.error,
  ];

  @override
  Widget build(BuildContext context) {
    final allSeries = <MetricTimeSeriesResponse>[
      if (series != null) series!,
      ...overlays,
    ];

    if (allSeries.isEmpty ||
        allSeries.every((s) => s.dataPoints.isEmpty)) {
      return const Center(
        child: Text(
          'No data to display',
          style: TextStyle(
            color: CodeOpsColors.textTertiary,
            fontSize: 13,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawHorizontalLine: true,
            drawVerticalLine: false,
            horizontalInterval: _calcHorizontalInterval(allSeries),
            getDrawingHorizontalLine: (_) => FlLine(
              color: CodeOpsColors.border,
              strokeWidth: 0.5,
            ),
          ),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: _bottomTitle,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 48,
                getTitlesWidget: (value, meta) => Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    _formatValue(value),
                    style: const TextStyle(
                      fontSize: 10,
                      color: CodeOpsColors.textTertiary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: const Border(
              bottom: BorderSide(color: CodeOpsColors.border),
              left: BorderSide(color: CodeOpsColors.border),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => CodeOpsColors.surface,
              getTooltipItems: (spots) => spots.map((s) {
                final ts = DateTime.fromMillisecondsSinceEpoch(
                  s.x.toInt(),
                  isUtc: true,
                );
                return LineTooltipItem(
                  '${DateFormat('HH:mm:ss').format(ts)}\n${_formatValue(s.y)}',
                  TextStyle(
                    color: _lineColors[s.barIndex % _lineColors.length],
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                );
              }).toList(),
            ),
          ),
          lineBarsData: [
            for (var i = 0; i < allSeries.length; i++)
              _buildLine(allSeries[i], _lineColors[i % _lineColors.length]),
          ],
        ),
      ),
    );
  }

  LineChartBarData _buildLine(
    MetricTimeSeriesResponse ts,
    Color color,
  ) {
    final spots = ts.dataPoints
        .map((dp) => FlSpot(
              dp.timestamp.millisecondsSinceEpoch.toDouble(),
              dp.value,
            ))
        .toList();

    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 2,
      dotData: FlDotData(
        show: spots.length <= 30,
        getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
          radius: 2,
          color: color,
          strokeWidth: 0,
        ),
      ),
      belowBarData: BarAreaData(
        show: true,
        color: color.withValues(alpha: 0.05),
      ),
    );
  }

  Widget _bottomTitle(double value, TitleMeta meta) {
    final ts = DateTime.fromMillisecondsSinceEpoch(
      value.toInt(),
      isUtc: true,
    );
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        DateFormat('HH:mm').format(ts),
        style: const TextStyle(
          fontSize: 10,
          color: CodeOpsColors.textTertiary,
        ),
      ),
    );
  }

  static String _formatValue(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }

  static double _calcHorizontalInterval(
    List<MetricTimeSeriesResponse> series,
  ) {
    double maxVal = 0;
    for (final s in series) {
      for (final dp in s.dataPoints) {
        if (dp.value > maxVal) maxVal = dp.value;
      }
    }
    if (maxVal <= 0) return 1;
    return (maxVal / 5).ceilToDouble().clamp(1, double.infinity);
  }
}
