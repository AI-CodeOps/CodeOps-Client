/// Waterfall timeline visualization for distributed traces.
///
/// Uses [CustomPainter] to render horizontal span bars positioned by
/// offset and sized by duration. Each service is assigned a distinct
/// color for visual grouping. Tapping a span bar invokes [onSpanTap].
library;

import 'package:flutter/material.dart';

import '../../models/logger_enums.dart';
import '../../models/logger_models.dart';
import '../../theme/colors.dart';

/// Pre-defined palette for service-based coloring.
const _serviceColors = <Color>[
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

/// Row height for each span bar in the waterfall.
const double _rowHeight = 28.0;

/// Left margin reserved for the operation label.
const double _labelWidth = 200.0;

/// Waterfall timeline of trace spans.
class TraceWaterfall extends StatelessWidget {
  /// All spans in waterfall order.
  final List<WaterfallSpan> spans;

  /// Total trace duration in milliseconds.
  final int totalDurationMs;

  /// Map of service name to assigned color.
  final Map<String, Color> serviceColors;

  /// Currently selected span ID, if any.
  final String? selectedSpanId;

  /// Callback when a span is tapped.
  final ValueChanged<WaterfallSpan>? onSpanTap;

  /// Creates a [TraceWaterfall].
  const TraceWaterfall({
    super.key,
    required this.spans,
    required this.totalDurationMs,
    required this.serviceColors,
    this.selectedSpanId,
    this.onSpanTap,
  });

  /// Builds a service-to-color map from a list of spans.
  static Map<String, Color> buildServiceColorMap(List<WaterfallSpan> spans) {
    final services = spans.map((s) => s.serviceName).toSet().toList()..sort();
    final map = <String, Color>{};
    for (var i = 0; i < services.length; i++) {
      map[services[i]] = _serviceColors[i % _serviceColors.length];
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    if (spans.isEmpty) {
      return const Center(
        child: Text(
          'No spans to display',
          style: TextStyle(
            color: CodeOpsColors.textTertiary,
            fontSize: 13,
          ),
        ),
      );
    }

    final totalHeight = spans.length * _rowHeight;

    return SingleChildScrollView(
      child: SizedBox(
        height: totalHeight,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final barAreaWidth = constraints.maxWidth - _labelWidth;
            return Stack(
              children: [
                // Background painter for grid lines.
                Positioned.fill(
                  child: CustomPaint(
                    painter: _WaterfallGridPainter(
                      spanCount: spans.length,
                      totalDurationMs: totalDurationMs,
                      labelWidth: _labelWidth,
                    ),
                  ),
                ),
                // Span rows.
                for (var i = 0; i < spans.length; i++)
                  Positioned(
                    top: i * _rowHeight,
                    left: 0,
                    right: 0,
                    height: _rowHeight,
                    child: _SpanRow(
                      span: spans[i],
                      totalDurationMs: totalDurationMs,
                      barAreaWidth: barAreaWidth,
                      color: serviceColors[spans[i].serviceName] ??
                          CodeOpsColors.textTertiary,
                      isSelected: spans[i].spanId == selectedSpanId,
                      onTap: onSpanTap != null
                          ? () => onSpanTap!(spans[i])
                          : null,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// A single row in the waterfall: label on the left, bar on the right.
class _SpanRow extends StatelessWidget {
  final WaterfallSpan span;
  final int totalDurationMs;
  final double barAreaWidth;
  final Color color;
  final bool isSelected;
  final VoidCallback? onTap;

  const _SpanRow({
    required this.span,
    required this.totalDurationMs,
    required this.barAreaWidth,
    required this.color,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final offsetFraction =
        totalDurationMs > 0 ? span.offsetMs / totalDurationMs : 0.0;
    final widthFraction =
        totalDurationMs > 0 ? span.durationMs / totalDurationMs : 0.0;
    final barLeft = _labelWidth + (offsetFraction * barAreaWidth);
    final barWidth = (widthFraction * barAreaWidth).clamp(2.0, barAreaWidth);

    return InkWell(
      onTap: onTap,
      child: Container(
        height: _rowHeight,
        decoration: BoxDecoration(
          color: isSelected
              ? CodeOpsColors.primary.withValues(alpha: 0.15)
              : null,
          border: const Border(
            bottom: BorderSide(
              color: CodeOpsColors.border,
              width: 0.5,
            ),
          ),
        ),
        child: Stack(
          children: [
            // Operation label.
            Positioned(
              left: span.depth * 12.0,
              top: 0,
              bottom: 0,
              width: _labelWidth - (span.depth * 12.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 4, right: 4),
                  child: Text(
                    span.operationName,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 11,
                      color: span.status == SpanStatus.error
                          ? CodeOpsColors.error
                          : CodeOpsColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
            // Duration bar.
            Positioned(
              left: barLeft,
              top: 6,
              width: barWidth,
              height: _rowHeight - 12,
              child: Tooltip(
                message:
                    '${span.serviceName} — ${span.operationName}\n${span.durationMs}ms',
                child: Container(
                  decoration: BoxDecoration(
                    color: span.status == SpanStatus.error
                        ? CodeOpsColors.error.withValues(alpha: 0.8)
                        : color.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            // Duration text.
            Positioned(
              left: barLeft + barWidth + 4,
              top: 0,
              bottom: 0,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${span.durationMs}ms',
                  style: const TextStyle(
                    fontSize: 10,
                    color: CodeOpsColors.textSecondary,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Paints vertical grid lines and time markers on the waterfall background.
class _WaterfallGridPainter extends CustomPainter {
  final int spanCount;
  final int totalDurationMs;
  final double labelWidth;

  _WaterfallGridPainter({
    required this.spanCount,
    required this.totalDurationMs,
    required this.labelWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = CodeOpsColors.border.withValues(alpha: 0.5)
      ..strokeWidth = 0.5;

    final barAreaWidth = size.width - labelWidth;

    // Draw 4 vertical grid lines.
    for (var i = 1; i <= 4; i++) {
      final x = labelWidth + (barAreaWidth * i / 5);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Label line at left edge of bar area.
    canvas.drawLine(
      Offset(labelWidth, 0),
      Offset(labelWidth, size.height),
      paint..color = CodeOpsColors.border,
    );
  }

  @override
  bool shouldRepaint(covariant _WaterfallGridPainter oldDelegate) =>
      oldDelegate.spanCount != spanCount ||
      oldDelegate.totalDurationMs != totalDurationMs;
}
