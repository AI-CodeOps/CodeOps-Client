/// Dashboard widget card — container for a single widget within a dashboard grid.
///
/// Displays a title bar with the widget type icon, title text, and action
/// buttons (refresh, configure, remove). Renders visualization content
/// based on [WidgetType] (charts, counters, tables, log stream).
library;

import 'dart:convert';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../models/logger_enums.dart';
import '../../models/logger_models.dart';
import '../../theme/colors.dart';

/// A card container for a single dashboard widget.
///
/// Shows a title bar with type icon, title, and action buttons.
/// Renders the appropriate visualization for the widget type.
class DashboardWidgetCard extends StatelessWidget {
  /// The widget data to display.
  final DashboardWidgetResponse widget;

  /// Whether the parent dashboard is in edit mode.
  final bool isEditMode;

  /// Called when the refresh button is tapped.
  final VoidCallback? onRefresh;

  /// Called when the configure button is tapped.
  final VoidCallback? onConfigure;

  /// Called when the remove button is tapped.
  final VoidCallback? onRemove;

  /// Creates a [DashboardWidgetCard].
  const DashboardWidgetCard({
    super.key,
    required this.widget,
    this.isEditMode = false,
    this.onRefresh,
    this.onConfigure,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CodeOpsColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isEditMode
              ? CodeOpsColors.primary.withValues(alpha: 0.5)
              : CodeOpsColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTitleBar(context),
          const Divider(height: 1, color: CodeOpsColors.border),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  /// Builds the title bar with icon, title text, and action buttons.
  Widget _buildTitleBar(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Icon(
            _iconForType(widget.widgetType),
            size: 14,
            color: CodeOpsColors.primary,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              widget.title,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: CodeOpsColors.textPrimary,
              ),
            ),
          ),
          _ActionButton(
            icon: Icons.refresh,
            tooltip: 'Refresh',
            onTap: onRefresh,
          ),
          _ActionButton(
            icon: Icons.settings_outlined,
            tooltip: 'Configure',
            onTap: onConfigure,
          ),
          if (isEditMode)
            _ActionButton(
              icon: Icons.close,
              tooltip: 'Remove',
              onTap: onRemove,
            ),
        ],
      ),
    );
  }

  /// Renders the widget content based on type.
  Widget _buildContent() {
    switch (widget.widgetType) {
      case WidgetType.timeSeriesChart:
        return _TimeSeriesContent(widget: widget);
      case WidgetType.barChart:
        return _BarChartContent(widget: widget);
      case WidgetType.pieChart:
        return _PieChartContent(widget: widget);
      case WidgetType.counter:
        return _CounterContent(widget: widget);
      case WidgetType.gauge:
        return _GaugeContent(widget: widget);
      case WidgetType.table:
        return _TableContent(widget: widget);
      case WidgetType.logStream:
        return _LogStreamContent(widget: widget);
      case WidgetType.heatmap:
        return _HeatmapContent(widget: widget);
    }
  }

  /// Returns the icon for a widget type.
  static IconData _iconForType(WidgetType type) => switch (type) {
        WidgetType.timeSeriesChart => Icons.show_chart,
        WidgetType.barChart => Icons.bar_chart,
        WidgetType.pieChart => Icons.pie_chart_outline,
        WidgetType.counter => Icons.tag,
        WidgetType.gauge => Icons.speed,
        WidgetType.table => Icons.table_chart_outlined,
        WidgetType.logStream => Icons.terminal,
        WidgetType.heatmap => Icons.grid_on,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// Action Button
// ─────────────────────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.tooltip,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: IconButton(
        icon: Icon(icon, size: 14),
        color: CodeOpsColors.textTertiary,
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        onPressed: onTap,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget Content Renderers
// ─────────────────────────────────────────────────────────────────────────────

/// Extracts a list of numeric data points from configJson.
List<double> _extractDataPoints(DashboardWidgetResponse w) {
  if (w.configJson == null) return [];
  try {
    final config = json.decode(w.configJson!) as Map<String, dynamic>;
    final data = config['data'];
    if (data is List) {
      return data.map((e) => (e as num).toDouble()).toList();
    }
  } catch (_) {}
  return [];
}

/// Time-series line chart content.
class _TimeSeriesContent extends StatelessWidget {
  final DashboardWidgetResponse widget;
  const _TimeSeriesContent({required this.widget});

  @override
  Widget build(BuildContext context) {
    final data = _extractDataPoints(widget);
    if (data.isEmpty) {
      return const Center(
        child: Text('No data', style: TextStyle(color: CodeOpsColors.textTertiary, fontSize: 12)),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(12),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var i = 0; i < data.length; i++)
                  FlSpot(i.toDouble(), data[i]),
              ],
              isCurved: true,
              color: CodeOpsColors.primary,
              barWidth: 2,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: CodeOpsColors.primary.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bar chart content.
class _BarChartContent extends StatelessWidget {
  final DashboardWidgetResponse widget;
  const _BarChartContent({required this.widget});

  @override
  Widget build(BuildContext context) {
    final data = _extractDataPoints(widget);
    if (data.isEmpty) {
      return const Center(
        child: Text('No data', style: TextStyle(color: CodeOpsColors.textTertiary, fontSize: 12)),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(12),
      child: BarChart(
        BarChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: [
            for (var i = 0; i < data.length; i++)
              BarChartGroupData(x: i, barRods: [
                BarChartRodData(
                  toY: data[i],
                  color: CodeOpsColors.secondary,
                  width: 16,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ]),
          ],
        ),
      ),
    );
  }
}

/// Pie chart content.
class _PieChartContent extends StatelessWidget {
  final DashboardWidgetResponse widget;
  const _PieChartContent({required this.widget});

  static const _colors = [
    CodeOpsColors.primary,
    CodeOpsColors.secondary,
    CodeOpsColors.success,
    CodeOpsColors.warning,
    CodeOpsColors.error,
  ];

  @override
  Widget build(BuildContext context) {
    final data = _extractDataPoints(widget);
    if (data.isEmpty) {
      return const Center(
        child: Text('No data', style: TextStyle(color: CodeOpsColors.textTertiary, fontSize: 12)),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(12),
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 24,
          sections: [
            for (var i = 0; i < data.length; i++)
              PieChartSectionData(
                value: data[i],
                color: _colors[i % _colors.length],
                radius: 40,
                showTitle: false,
              ),
          ],
        ),
      ),
    );
  }
}

/// Counter / stat big-number content.
class _CounterContent extends StatelessWidget {
  final DashboardWidgetResponse widget;
  const _CounterContent({required this.widget});

  @override
  Widget build(BuildContext context) {
    String value = '--';
    String? label;
    if (widget.configJson != null) {
      try {
        final config = json.decode(widget.configJson!) as Map<String, dynamic>;
        value = config['value']?.toString() ?? '--';
        label = config['label'] as String?;
      } catch (_) {}
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: CodeOpsColors.primary,
            ),
          ),
          if (label != null)
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: CodeOpsColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}

/// Gauge visualization content.
class _GaugeContent extends StatelessWidget {
  final DashboardWidgetResponse widget;
  const _GaugeContent({required this.widget});

  @override
  Widget build(BuildContext context) {
    double percent = 0;
    if (widget.configJson != null) {
      try {
        final config = json.decode(widget.configJson!) as Map<String, dynamic>;
        percent = ((config['value'] as num?) ?? 0).toDouble();
      } catch (_) {}
    }
    final clamped = percent.clamp(0, 100);
    return Center(
      child: SizedBox(
        width: 80,
        height: 80,
        child: CustomPaint(
          painter: _GaugePainter(clamped / 100),
          child: Center(
            child: Text(
              '${clamped.toInt()}%',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: CodeOpsColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double fraction;
  _GaugePainter(this.fraction);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final bg = Paint()
      ..color = CodeOpsColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;
    canvas.drawArc(rect, -math.pi * 0.75, math.pi * 1.5, false, bg);

    final fg = Paint()
      ..color = CodeOpsColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      rect,
      -math.pi * 0.75,
      math.pi * 1.5 * fraction,
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) => old.fraction != fraction;
}

/// Table content — renders a simple data table from configJson rows.
class _TableContent extends StatelessWidget {
  final DashboardWidgetResponse widget;
  const _TableContent({required this.widget});

  @override
  Widget build(BuildContext context) {
    List<List<String>> rows = [];
    if (widget.configJson != null) {
      try {
        final config = json.decode(widget.configJson!) as Map<String, dynamic>;
        final data = config['rows'] as List?;
        if (data != null) {
          rows = data
              .map((r) =>
                  (r as List).map((c) => c.toString()).toList())
              .toList();
        }
      } catch (_) {}
    }
    if (rows.isEmpty) {
      return const Center(
        child: Text('No data', style: TextStyle(color: CodeOpsColors.textTertiary, fontSize: 12)),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: Table(
        border: TableBorder.all(color: CodeOpsColors.border, width: 0.5),
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          for (final row in rows)
            TableRow(
              children: [
                for (final cell in row)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    child: Text(
                      cell,
                      style: const TextStyle(
                        fontSize: 11,
                        color: CodeOpsColors.textPrimary,
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Log stream content — shows scrolling log lines.
class _LogStreamContent extends StatelessWidget {
  final DashboardWidgetResponse widget;
  const _LogStreamContent({required this.widget});

  @override
  Widget build(BuildContext context) {
    List<String> lines = [];
    if (widget.configJson != null) {
      try {
        final config = json.decode(widget.configJson!) as Map<String, dynamic>;
        final data = config['lines'] as List?;
        if (data != null) {
          lines = data.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }
    if (lines.isEmpty) {
      return const Center(
        child: Text(
          'Waiting for logs…',
          style: TextStyle(color: CodeOpsColors.textTertiary, fontSize: 12),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: lines.length,
      itemBuilder: (_, i) => Text(
        lines[i],
        style: const TextStyle(
          fontSize: 11,
          fontFamily: 'monospace',
          color: CodeOpsColors.textSecondary,
        ),
      ),
    );
  }
}

/// Heatmap content placeholder.
class _HeatmapContent extends StatelessWidget {
  final DashboardWidgetResponse widget;
  const _HeatmapContent({required this.widget});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Heatmap',
        style: TextStyle(color: CodeOpsColors.textTertiary, fontSize: 12),
      ),
    );
  }
}
