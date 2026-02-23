/// Visual grouping boundary for a solution cluster in the topology.
///
/// Renders as a labeled rounded rectangle containing member service nodes.
/// Uses dashed border and semi-transparent fill.
library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../models/registry_models.dart';
import '../../theme/colors.dart';

/// Palette of colors auto-assigned to clusters.
const _clusterPalette = <Color>[
  Color(0xFF6C63FF), // indigo
  Color(0xFF00BCD4), // teal
  Color(0xFFF97316), // orange
  Color(0xFF14B8A6), // emerald
  Color(0xFFA855F7), // violet
  Color(0xFF3B82F6), // blue
  Color(0xFFEC4899), // pink
  Color(0xFFEAB308), // yellow
];

/// Returns a palette color for the given cluster index.
Color clusterColor(int index) =>
    _clusterPalette[index % _clusterPalette.length];

/// Visual grouping boundary for a solution cluster in the topology.
///
/// Renders a labeled rounded rectangle with dashed border, solution name
/// header with member count and status, and semi-transparent background.
class TopologyCluster extends StatelessWidget {
  /// The solution group data.
  final TopologySolutionGroup group;

  /// The bounding rectangle encompassing all member nodes.
  final Rect bounds;

  /// Palette index for color assignment.
  final int colorIndex;

  /// Creates a [TopologyCluster].
  const TopologyCluster({
    super.key,
    required this.group,
    required this.bounds,
    this.colorIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final color = clusterColor(colorIndex);
    final statusColor =
        CodeOpsColors.solutionStatusColors[group.status] ??
            CodeOpsColors.textTertiary;

    return CustomPaint(
      painter: _ClusterBorderPainter(color: color),
      child: Container(
        width: bounds.width,
        height: bounds.height,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 10, top: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  group.name,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${group.memberCount}',
                  style: TextStyle(
                    fontSize: 10,
                    color: color.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints a dashed rounded-rectangle border for the cluster.
class _ClusterBorderPainter extends CustomPainter {
  final Color color;

  _ClusterBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(12),
    );

    final path = ui.Path()..addRRect(rrect);
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      var distance = 0.0;
      const dashLength = 6.0;
      const gapLength = 4.0;
      while (distance < metric.length) {
        final end = (distance + dashLength).clamp(0.0, metric.length);
        final segment = metric.extractPath(distance, end);
        canvas.drawPath(segment, paint);
        distance = end + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(_ClusterBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}
