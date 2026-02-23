/// Interactive ecosystem map canvas with solution clusters and dependency edges.
///
/// Builds on the same [InteractiveViewer] + [CustomPainter] approach from
/// CRF-007 but adds solution cluster boundaries and layer-based positioning.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../models/registry_enums.dart';
import '../../models/registry_models.dart';
import '../../theme/colors.dart';
import 'topology_cluster.dart';
import 'topology_node.dart';

/// Interactive ecosystem map canvas.
///
/// Positions topology nodes using layer-based Y positioning and solution
/// cluster grouping for X positioning. Renders edges with [_TopologyEdgePainter],
/// clusters with [TopologyCluster], and nodes with [TopologyNode].
/// Supports zoom/pan via [InteractiveViewer].
class TopologyCanvas extends StatefulWidget {
  /// The topology response data.
  final TopologyResponse topology;

  /// Set of visible (non-dimmed) node IDs after filtering.
  final Set<String> visibleNodeIds;

  /// Currently selected node ID.
  final String? selectedNodeId;

  /// Callback when a node is tapped.
  final ValueChanged<TopologyNodeResponse>? onNodeTap;

  /// Callback when a node is double-tapped.
  final ValueChanged<TopologyNodeResponse>? onNodeDoubleTap;

  /// Creates a [TopologyCanvas].
  const TopologyCanvas({
    super.key,
    required this.topology,
    required this.visibleNodeIds,
    this.selectedNodeId,
    this.onNodeTap,
    this.onNodeDoubleTap,
  });

  @override
  State<TopologyCanvas> createState() => _TopologyCanvasState();
}

class _TopologyCanvasState extends State<TopologyCanvas> {
  final TransformationController _transformCtrl = TransformationController();

  Map<String, Offset> _positions = {};
  Map<String, Rect> _clusterBounds = {};
  Size _canvasSize = Size.zero;

  static const double _nodeWidth = 140.0;
  static const double _nodeHeight = 60.0;
  static const double _horizontalGap = 60.0;
  static const double _verticalGap = 50.0;
  static const double _padding = 40.0;
  static const double _clusterPadding = 30.0;
  static const double _clusterHeaderHeight = 24.0;

  @override
  void initState() {
    super.initState();
    _computeLayout();
  }

  @override
  void didUpdateWidget(TopologyCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.topology != widget.topology) {
      _computeLayout();
    }
  }

  @override
  void dispose() {
    _transformCtrl.dispose();
    super.dispose();
  }

  /// Computes node positions using layer + cluster grouping.
  void _computeLayout() {
    final nodes = widget.topology.nodes;
    if (nodes.isEmpty) {
      _positions = {};
      _clusterBounds = {};
      _canvasSize = Size.zero;
      return;
    }

    final layers = widget.topology.layers ?? [];
    final groups = widget.topology.solutionGroups ?? [];

    // Build layer assignment map.
    final nodeLayer = <String, int>{};
    for (var i = 0; i < layers.length; i++) {
      for (final sid in layers[i].serviceIds) {
        nodeLayer[sid] = i;
      }
    }
    // Nodes without layer assignment get layer 0.
    for (final n in nodes) {
      nodeLayer.putIfAbsent(n.serviceId, () => 0);
    }

    // Build solution membership map.
    final nodeSolution = <String, String>{};
    for (final g in groups) {
      for (final sid in g.serviceIds) {
        nodeSolution[sid] = g.solutionId;
      }
    }

    // Group nodes: (solutionId, layerIndex) → [serviceIds]
    final grouped = <(String?, int), List<String>>{};
    for (final n in nodes) {
      final key = (nodeSolution[n.serviceId], nodeLayer[n.serviceId] ?? 0);
      (grouped[key] ??= []).add(n.serviceId);
    }

    // Sort keys: clusters first (grouped by solution), then orphans.
    final keys = grouped.keys.toList()
      ..sort((a, b) {
        // Null solutions (orphans) go last.
        if (a.$1 == null && b.$1 != null) return 1;
        if (a.$1 != null && b.$1 == null) return -1;
        final cmp = (a.$1 ?? '').compareTo(b.$1 ?? '');
        if (cmp != 0) return cmp;
        return a.$2.compareTo(b.$2);
      });

    // Position nodes row-by-row within layers.
    _positions = {};
    double currentX = _padding;
    final solutionXStart = <String, double>{};
    final solutionXEnd = <String, double>{};
    final solutionYStart = <String, double>{};
    final solutionYEnd = <String, double>{};

    String? lastSolution;
    for (final key in keys) {
      final (solutionId, layerIdx) = key;
      final nodeIds = grouped[key]!;

      // Start new cluster column group if solution changes.
      if (solutionId != lastSolution && lastSolution != null) {
        currentX += _clusterPadding;
      }
      lastSolution = solutionId;

      final y = _padding +
          _clusterHeaderHeight +
          layerIdx * (_nodeHeight + _verticalGap);

      for (var i = 0; i < nodeIds.length; i++) {
        final x = currentX + i * (_nodeWidth + _horizontalGap);
        _positions[nodeIds[i]] = Offset(x, y);

        // Track cluster bounds.
        if (solutionId != null) {
          final right = x + _nodeWidth;
          final bottom = y + _nodeHeight;
          solutionXStart[solutionId] = math.min(
            solutionXStart[solutionId] ?? double.infinity,
            x,
          );
          solutionXEnd[solutionId] = math.max(
            solutionXEnd[solutionId] ?? 0,
            right,
          );
          solutionYStart[solutionId] = math.min(
            solutionYStart[solutionId] ?? double.infinity,
            y,
          );
          solutionYEnd[solutionId] = math.max(
            solutionYEnd[solutionId] ?? 0,
            bottom,
          );
        }
      }

      currentX += nodeIds.length * (_nodeWidth + _horizontalGap);
    }

    // Build cluster bounds.
    _clusterBounds = {};
    for (final g in groups) {
      final sid = g.solutionId;
      if (solutionXStart.containsKey(sid)) {
        _clusterBounds[sid] = Rect.fromLTRB(
          solutionXStart[sid]! - _clusterPadding / 2,
          solutionYStart[sid]! - _clusterHeaderHeight - 4,
          solutionXEnd[sid]! + _clusterPadding / 2,
          solutionYEnd[sid]! + _clusterPadding / 2,
        );
      }
    }

    // Compute canvas size.
    double maxX = 0, maxY = 0;
    for (final pos in _positions.values) {
      if (pos.dx + _nodeWidth > maxX) maxX = pos.dx + _nodeWidth;
      if (pos.dy + _nodeHeight > maxY) maxY = pos.dy + _nodeHeight;
    }
    for (final r in _clusterBounds.values) {
      if (r.right > maxX) maxX = r.right;
      if (r.bottom > maxY) maxY = r.bottom;
    }
    _canvasSize = Size(maxX + _padding, maxY + _padding);
  }

  void _zoomIn() {
    final matrix = _transformCtrl.value.clone();
    // ignore: deprecated_member_use
    matrix.scale(1.2);
    _transformCtrl.value = matrix;
  }

  void _zoomOut() {
    final matrix = _transformCtrl.value.clone();
    // ignore: deprecated_member_use
    matrix.scale(1 / 1.2);
    _transformCtrl.value = matrix;
  }

  void _resetView() {
    _transformCtrl.value = Matrix4.identity();
  }

  void _fitToScreen() {
    if (_canvasSize == Size.zero) return;
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final viewSize = renderBox.size;

    final scaleX = viewSize.width / _canvasSize.width;
    final scaleY = viewSize.height / _canvasSize.height;
    final scale = math.min(scaleX, scaleY).clamp(0.3, 2.0);

    // ignore: deprecated_member_use
    final matrix = Matrix4.identity()..scale(scale);
    _transformCtrl.value = matrix;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.topology.nodes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.hub_outlined,
              size: 48,
              color: CodeOpsColors.textTertiary,
            ),
            SizedBox(height: 12),
            Text(
              'No services',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: CodeOpsColors.textSecondary,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Register services to see the topology.',
              style: TextStyle(
                fontSize: 13,
                color: CodeOpsColors.textTertiary,
              ),
            ),
          ],
        ),
      );
    }

    // Build highlighted edges for selected node.
    final highlightedEdges = <int>{};
    if (widget.selectedNodeId != null) {
      for (var i = 0; i < widget.topology.edges.length; i++) {
        final e = widget.topology.edges[i];
        if (e.sourceServiceId == widget.selectedNodeId ||
            e.targetServiceId == widget.selectedNodeId) {
          highlightedEdges.add(i);
        }
      }
    }

    final groups = widget.topology.solutionGroups ?? [];
    return Stack(
      children: [
        // Canvas with zoom/pan
        InteractiveViewer(
          transformationController: _transformCtrl,
          boundaryMargin: const EdgeInsets.all(200),
          minScale: 0.2,
          maxScale: 3.0,
          child: SizedBox(
            width: math.max(_canvasSize.width, 800),
            height: math.max(_canvasSize.height, 600),
            child: Stack(
              children: [
                // Edges (bottom layer)
                CustomPaint(
                  size: _canvasSize,
                  painter: _TopologyEdgePainter(
                    edges: widget.topology.edges,
                    positions: _positions,
                    nodeWidth: _nodeWidth,
                    nodeHeight: _nodeHeight,
                    highlightedEdges: highlightedEdges,
                    visibleNodeIds: widget.visibleNodeIds,
                  ),
                ),
                // Cluster boundaries (middle layer — ignore pointer)
                for (var i = 0; i < groups.length; i++)
                  if (_clusterBounds.containsKey(groups[i].solutionId))
                    Builder(builder: (context) {
                      final r = _clusterBounds[groups[i].solutionId]!;
                      return Positioned(
                        left: r.left,
                        top: r.top,
                        child: IgnorePointer(
                          child: TopologyCluster(
                            group: groups[i],
                            bounds: Rect.fromLTWH(0, 0, r.width, r.height),
                            colorIndex: i,
                          ),
                        ),
                      );
                    }),
                // Nodes (top layer)
                for (final node in widget.topology.nodes)
                  if (_positions.containsKey(node.serviceId))
                    Positioned(
                      left: _positions[node.serviceId]!.dx,
                      top: _positions[node.serviceId]!.dy,
                      child: TopologyNode(
                        node: node,
                        isSelected:
                            widget.selectedNodeId == node.serviceId,
                        isFiltered:
                            !widget.visibleNodeIds.contains(node.serviceId),
                        onTap: () => widget.onNodeTap?.call(node),
                        onDoubleTap: () =>
                            widget.onNodeDoubleTap?.call(node),
                      ),
                    ),
              ],
            ),
          ),
        ),
        // Zoom controls overlay
        Positioned(
          right: 12,
          bottom: 12,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ZoomButton(
                icon: Icons.add,
                tooltip: 'Zoom in',
                onPressed: _zoomIn,
              ),
              const SizedBox(height: 4),
              _ZoomButton(
                icon: Icons.remove,
                tooltip: 'Zoom out',
                onPressed: _zoomOut,
              ),
              const SizedBox(height: 4),
              _ZoomButton(
                icon: Icons.restart_alt,
                tooltip: 'Reset view',
                onPressed: _resetView,
              ),
              const SizedBox(height: 4),
              _ZoomButton(
                icon: Icons.fit_screen,
                tooltip: 'Fit to screen',
                onPressed: _fitToScreen,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Small zoom control button.
class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _ZoomButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: CodeOpsColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: const BorderSide(color: CodeOpsColors.border),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            width: 32,
            height: 32,
            child: Icon(icon, size: 16, color: CodeOpsColors.textSecondary),
          ),
        ),
      ),
    );
  }
}

/// Paints directed edges between topology nodes.
///
/// Reuses the CRF-007 edge painting approach with type-specific colors,
/// solid/dashed/dotted styles, and arrowheads. Dims edges to/from
/// non-visible (filtered) nodes.
class _TopologyEdgePainter extends CustomPainter {
  final List<DependencyEdgeResponse> edges;
  final Map<String, Offset> positions;
  final double nodeWidth;
  final double nodeHeight;
  final Set<int> highlightedEdges;
  final Set<String> visibleNodeIds;

  _TopologyEdgePainter({
    required this.edges,
    required this.positions,
    required this.nodeWidth,
    required this.nodeHeight,
    required this.highlightedEdges,
    required this.visibleNodeIds,
  });

  static Color _edgeColor(DependencyType type) => switch (type) {
        DependencyType.httpRest => const Color(0xFF2196F3),
        DependencyType.grpc => const Color(0xFF9C27B0),
        DependencyType.kafkaTopic => const Color(0xFFFF9800),
        DependencyType.databaseShared => const Color(0xFF4CAF50),
        DependencyType.redisShared => const Color(0xFFF44336),
        DependencyType.library_ => const Color(0xFF009688),
        DependencyType.gatewayRoute => const Color(0xFF3F51B5),
        DependencyType.websocket => const Color(0xFF00BCD4),
        DependencyType.fileSystem => const Color(0xFF795548),
        DependencyType.other => const Color(0xFF9E9E9E),
      };

  static bool _isDashed(DependencyType type) => switch (type) {
        DependencyType.kafkaTopic ||
        DependencyType.websocket ||
        DependencyType.other => true,
        _ => false,
      };

  static bool _isDotted(DependencyType type) => switch (type) {
        DependencyType.library_ || DependencyType.fileSystem => true,
        _ => false,
      };

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < edges.length; i++) {
      final edge = edges[i];
      final sourcePos = positions[edge.sourceServiceId];
      final targetPos = positions[edge.targetServiceId];
      if (sourcePos == null || targetPos == null) continue;

      final isHighlighted = highlightedEdges.contains(i);
      final isOptional = edge.isRequired == false;
      final bothVisible =
          visibleNodeIds.contains(edge.sourceServiceId) &&
          visibleNodeIds.contains(edge.targetServiceId);

      final color = _edgeColor(edge.dependencyType);
      final alpha = isHighlighted
          ? 1.0
          : bothVisible
              ? 0.6
              : 0.15;

      final start = Offset(
        sourcePos.dx + nodeWidth,
        sourcePos.dy + nodeHeight / 2,
      );
      final end = Offset(
        targetPos.dx,
        targetPos.dy + nodeHeight / 2,
      );

      final paint = Paint()
        ..color = color.withValues(alpha: alpha)
        ..strokeWidth = isHighlighted
            ? 2.5
            : isOptional
                ? 1.0
                : 1.5
        ..style = PaintingStyle.stroke;

      final isDashed = _isDashed(edge.dependencyType) || isOptional;
      final isDotted = _isDotted(edge.dependencyType);

      if (isDashed || isDotted) {
        _drawDashedLine(canvas, start, end, paint,
            dashLength: isDotted ? 3.0 : 8.0,
            gapLength: isDotted ? 3.0 : 5.0);
      } else {
        canvas.drawLine(start, end, paint);
      }

      _drawArrowHead(canvas, start, end, paint..style = PaintingStyle.fill);
    }
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint, {
    double dashLength = 8.0,
    double gapLength = 5.0,
  }) {
    final delta = end - start;
    final totalLength = delta.distance;
    if (totalLength == 0) return;
    final direction = delta / totalLength;

    var drawn = 0.0;
    while (drawn < totalLength) {
      final segEnd = math.min(drawn + dashLength, totalLength);
      canvas.drawLine(
        start + direction * drawn,
        start + direction * segEnd,
        paint,
      );
      drawn = segEnd + gapLength;
    }
  }

  void _drawArrowHead(Canvas canvas, Offset from, Offset to, Paint paint) {
    const arrowSize = 8.0;
    final direction = to - from;
    final dist = direction.distance;
    if (dist == 0) return;
    final normalized = direction / dist;

    final tip = to;
    final perp = Offset(-normalized.dy, normalized.dx);

    final path = ui.Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(tip.dx - normalized.dx * arrowSize + perp.dx * arrowSize / 2,
          tip.dy - normalized.dy * arrowSize + perp.dy * arrowSize / 2)
      ..lineTo(tip.dx - normalized.dx * arrowSize - perp.dx * arrowSize / 2,
          tip.dy - normalized.dy * arrowSize - perp.dy * arrowSize / 2)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TopologyEdgePainter oldDelegate) =>
      oldDelegate.edges != edges ||
      oldDelegate.positions != positions ||
      oldDelegate.highlightedEdges != highlightedEdges ||
      oldDelegate.visibleNodeIds != visibleNodeIds;
}
