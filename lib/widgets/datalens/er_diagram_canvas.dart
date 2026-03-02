/// Interactive ER diagram canvas with CustomPainter rendering.
///
/// Renders table boxes and relationship lines using [CustomPainter].
/// Supports Crow's Foot and IDEF1X notation styles, mouse-wheel zoom,
/// canvas pan, individual table dragging, and table selection.
library;

import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../models/datalens_er_models.dart';
import '../../theme/colors.dart';

/// Interactive ER diagram canvas with zoom, pan, and table dragging.
///
/// Renders table nodes as boxes with column metadata and relationship
/// lines with cardinality notation (Crow's Foot or IDEF1X).
/// Interactions:
/// - **Zoom**: mouse wheel / trackpad scroll
/// - **Pan**: drag on empty canvas area
/// - **Table drag**: drag on a table box to reposition
/// - **Select**: tap a table to highlight it
class ErDiagramCanvas extends StatefulWidget {
  /// The diagram state to render.
  final ErDiagramState diagramState;

  /// Called when the diagram state changes (node dragged, zoom/pan).
  final ValueChanged<ErDiagramState>? onStateChanged;

  /// Called when a table is selected (tapped).
  final ValueChanged<String?>? onTableSelected;

  /// Creates an [ErDiagramCanvas].
  const ErDiagramCanvas({
    super.key,
    required this.diagramState,
    this.onStateChanged,
    this.onTableSelected,
  });

  @override
  State<ErDiagramCanvas> createState() => ErDiagramCanvasState();
}

/// State for [ErDiagramCanvas].
///
/// Exposes [resetView] and [zoomToFit] for programmatic control
/// from toolbar buttons via a [GlobalKey].
class ErDiagramCanvasState extends State<ErDiagramCanvas> {
  /// Fixed width of each table box in logical pixels.
  static const double tableWidth = 200.0;

  /// Height of the table header row.
  static const double headerHeight = 28.0;

  /// Height of each column row.
  static const double rowHeight = 20.0;

  /// Minimum zoom level.
  static const double minZoom = 0.1;

  /// Maximum zoom level.
  static const double maxZoom = 4.0;

  double _zoom = 1.0;
  Offset _pan = Offset.zero;
  ErTableNode? _draggedTable;
  Offset? _dragStartCanvas;
  Offset? _dragStartTablePos;
  String? _selectedTable;

  @override
  void initState() {
    super.initState();
    _zoom = widget.diagramState.zoom;
    _pan = widget.diagramState.pan;
  }

  @override
  void didUpdateWidget(ErDiagramCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.diagramState.connectionId !=
            oldWidget.diagramState.connectionId ||
        widget.diagramState.schema != oldWidget.diagramState.schema) {
      _zoom = widget.diagramState.zoom;
      _pan = widget.diagramState.pan;
      _selectedTable = null;
    }
  }

  /// Converts a screen-space point to canvas-space coordinates.
  Offset screenToCanvas(Offset screen) => (screen - _pan) / _zoom;

  /// Calculates the rendered height of a table node.
  double tableHeight(ErTableNode table) =>
      headerHeight + table.displayColumns.length * rowHeight;

  /// Hit-tests against all tables, returning the topmost hit (or null).
  ErTableNode? hitTest(Offset canvasPoint) {
    for (final table in widget.diagramState.tables.reversed) {
      final rect = Rect.fromLTWH(
        table.position.dx,
        table.position.dy,
        tableWidth,
        tableHeight(table),
      );
      if (rect.contains(canvasPoint)) return table;
    }
    return null;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Gesture Handlers
  // ─────────────────────────────────────────────────────────────────────────

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      setState(() {
        final oldZoom = _zoom;
        final delta = -event.scrollDelta.dy * 0.001;
        _zoom = (_zoom + delta).clamp(minZoom, maxZoom);
        final focal = event.localPosition;
        _pan = focal - (focal - _pan) * (_zoom / oldZoom);
      });
    }
  }

  void _onPanStart(DragStartDetails details) {
    final canvasPoint = screenToCanvas(details.localPosition);
    final hit = hitTest(canvasPoint);
    if (hit != null) {
      _draggedTable = hit;
      _dragStartCanvas = canvasPoint;
      _dragStartTablePos = hit.position;
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      if (_draggedTable != null) {
        final canvasPoint = screenToCanvas(details.localPosition);
        _draggedTable!.position =
            _dragStartTablePos! + (canvasPoint - _dragStartCanvas!);
      } else {
        _pan = _pan + details.delta;
      }
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_draggedTable != null) {
      _draggedTable = null;
      _dragStartCanvas = null;
      _dragStartTablePos = null;
      _notifyChanged();
    }
  }

  void _onTapUp(TapUpDetails details) {
    final canvasPoint = screenToCanvas(details.localPosition);
    final hit = hitTest(canvasPoint);
    setState(() => _selectedTable = hit?.tableName);
    widget.onTableSelected?.call(_selectedTable);
  }

  void _notifyChanged() {
    widget.onStateChanged?.call(
      widget.diagramState.copyWith(zoom: _zoom, pan: _pan),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Public API (for toolbar)
  // ─────────────────────────────────────────────────────────────────────────

  /// Resets zoom to 1.0 and pan to origin.
  void resetView() {
    setState(() {
      _zoom = 1.0;
      _pan = Offset.zero;
    });
    _notifyChanged();
  }

  /// Zooms to fit all tables within the given [viewport].
  void zoomToFit(Size viewport) {
    if (widget.diagramState.tables.isEmpty) return;
    double minX = double.infinity, minY = double.infinity;
    double maxX = double.negativeInfinity, maxY = double.negativeInfinity;
    for (final t in widget.diagramState.tables) {
      minX = math.min(minX, t.position.dx);
      minY = math.min(minY, t.position.dy);
      maxX = math.max(maxX, t.position.dx + tableWidth);
      maxY = math.max(maxY, t.position.dy + tableHeight(t));
    }
    const pad = 50.0;
    final cw = maxX - minX + pad * 2;
    final ch = maxY - minY + pad * 2;
    final z = math.min(viewport.width / cw, viewport.height / ch)
        .clamp(minZoom, maxZoom);
    setState(() {
      _zoom = z;
      _pan = Offset(
        (viewport.width - cw * z) / 2 - (minX - pad) * z,
        (viewport.height - ch * z) / 2 - (minY - pad) * z,
      );
    });
    _notifyChanged();
  }

  /// Toggles expand/collapse on all table nodes.
  void setAllExpanded(bool expanded) {
    setState(() {
      for (final t in widget.diagramState.tables) {
        t.isExpanded = expanded;
      }
    });
    _notifyChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: _onPointerSignal,
      child: GestureDetector(
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        onTapUp: _onTapUp,
        child: ClipRect(
          child: CustomPaint(
            painter: ErDiagramPainter(
              tables: widget.diagramState.tables,
              relationships: widget.diagramState.relationships,
              notation: widget.diagramState.notation,
              zoom: _zoom,
              pan: _pan,
              selectedTable: _selectedTable,
            ),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CustomPainter
// ─────────────────────────────────────────────────────────────────────────────

/// Renders ER diagram tables and relationships on a canvas.
///
/// Table nodes are drawn as rounded rectangles with a colored header
/// and column rows. Relationships are drawn as lines with cardinality
/// markers in either Crow's Foot or IDEF1X notation.
class ErDiagramPainter extends CustomPainter {
  /// Table nodes to render.
  final List<ErTableNode> tables;

  /// Relationship lines to render.
  final List<ErRelationship> relationships;

  /// Notation style (Crow's Foot or IDEF1X).
  final ErNotation notation;

  /// Current zoom level.
  final double zoom;

  /// Current pan offset.
  final Offset pan;

  /// Currently selected table name (highlighted).
  final String? selectedTable;

  static const double _tw = ErDiagramCanvasState.tableWidth;
  static const double _hh = ErDiagramCanvasState.headerHeight;
  static const double _rh = ErDiagramCanvasState.rowHeight;

  /// Creates an [ErDiagramPainter].
  ErDiagramPainter({
    required this.tables,
    required this.relationships,
    required this.notation,
    required this.zoom,
    required this.pan,
    this.selectedTable,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(pan.dx, pan.dy);
    canvas.scale(zoom);

    final nodeMap = <String, ErTableNode>{};
    for (final t in tables) {
      nodeMap[t.tableName] = t;
    }

    // Relationship lines (below table boxes).
    for (final rel in relationships) {
      _drawRelationship(canvas, rel, nodeMap);
    }

    // Table boxes.
    for (final table in tables) {
      _drawTableNode(canvas, table, table.tableName == selectedTable);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ErDiagramPainter oldDelegate) => true;

  // ─────────────────────────────────────────────────────────────────────────
  // Table Rendering
  // ─────────────────────────────────────────────────────────────────────────

  void _drawTableNode(Canvas canvas, ErTableNode table, bool isSelected) {
    final cols = table.displayColumns;
    final h = _hh + cols.length * _rh;
    final rect = RRect.fromLTRBR(
      table.position.dx,
      table.position.dy,
      table.position.dx + _tw,
      table.position.dy + h,
      const Radius.circular(4),
    );

    // Shadow.
    canvas.drawRRect(
      rect.shift(const Offset(2, 2)),
      Paint()..color = const Color(0x40000000),
    );

    // Background.
    canvas.drawRRect(rect, Paint()..color = CodeOpsColors.surface);

    // Border.
    canvas.drawRRect(
      rect,
      Paint()
        ..color = isSelected ? CodeOpsColors.primary : CodeOpsColors.border
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 2 : 1,
    );

    // Header background.
    final headerRect = RRect.fromLTRBAndCorners(
      table.position.dx,
      table.position.dy,
      table.position.dx + _tw,
      table.position.dy + _hh,
      topLeft: const Radius.circular(4),
      topRight: const Radius.circular(4),
    );
    canvas.drawRRect(
      headerRect,
      Paint()
        ..color = table.isView
            ? CodeOpsColors.secondary.withValues(alpha: 0.2)
            : CodeOpsColors.primary.withValues(alpha: 0.2),
    );

    // Header divider.
    canvas.drawLine(
      Offset(table.position.dx, table.position.dy + _hh),
      Offset(table.position.dx + _tw, table.position.dy + _hh),
      Paint()..color = CodeOpsColors.border,
    );

    // Table name.
    _paintText(
      canvas,
      table.tableName,
      Offset(table.position.dx + 8, table.position.dy + 7),
      color:
          table.isView ? CodeOpsColors.secondary : CodeOpsColors.textPrimary,
      fontSize: 12,
      fontWeight: FontWeight.w600,
      maxWidth: _tw - (table.isView ? 44 : 16),
    );

    // View badge.
    if (table.isView) {
      _paintText(
        canvas,
        'VIEW',
        Offset(table.position.dx + _tw - 36, table.position.dy + 9),
        color: CodeOpsColors.secondary,
        fontSize: 9,
        fontWeight: FontWeight.w600,
      );
    }

    // Column rows.
    for (var i = 0; i < cols.length; i++) {
      _drawColumnRow(canvas, table.position, i, cols[i]);
    }
  }

  void _drawColumnRow(
    Canvas canvas,
    Offset tablePos,
    int index,
    ErColumn col,
  ) {
    final y = tablePos.dy + _hh + index * _rh;
    final x = tablePos.dx;

    // Zebra stripe.
    if (index.isOdd) {
      canvas.drawRect(
        Rect.fromLTWH(x, y, _tw, _rh),
        Paint()..color = CodeOpsColors.background.withValues(alpha: 0.3),
      );
    }

    // PK / FK badge.
    if (col.isPrimaryKey) {
      _paintText(canvas, 'PK', Offset(x + 4, y + 4),
          color: CodeOpsColors.warning,
          fontSize: 9,
          fontWeight: FontWeight.w700);
    } else if (col.isForeignKey) {
      _paintText(canvas, 'FK', Offset(x + 4, y + 4),
          color: CodeOpsColors.secondary,
          fontSize: 9,
          fontWeight: FontWeight.w700);
    }

    // Column name.
    final nameColor = col.isPrimaryKey
        ? CodeOpsColors.warning
        : col.isForeignKey
            ? CodeOpsColors.secondary
            : CodeOpsColors.textPrimary;
    _paintText(canvas, col.name, Offset(x + 24, y + 4),
        color: nameColor, fontSize: 10, maxWidth: _tw * 0.42);

    // Data type.
    _paintText(canvas, col.dataType, Offset(x + _tw * 0.58, y + 4),
        color: CodeOpsColors.textTertiary, fontSize: 10, maxWidth: _tw * 0.34);

    // NOT NULL indicator.
    if (!col.isNullable) {
      _paintText(canvas, '*', Offset(x + _tw - 12, y + 3),
          color: CodeOpsColors.error,
          fontSize: 10,
          fontWeight: FontWeight.w700);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Relationship Rendering
  // ─────────────────────────────────────────────────────────────────────────

  void _drawRelationship(
    Canvas canvas,
    ErRelationship rel,
    Map<String, ErTableNode> nodeMap,
  ) {
    final fromNode = nodeMap[rel.fromTable];
    final toNode = nodeMap[rel.toTable];
    if (fromNode == null || toNode == null) return;

    final fromRect = _getTableRect(fromNode);
    final toRect = _getTableRect(toNode);
    final fromPt = _getConnectionPoint(fromRect, toRect.center);
    final toPt = _getConnectionPoint(toRect, fromRect.center);

    final linePaint = Paint()
      ..color = CodeOpsColors.textTertiary
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Line style: IDEF1X uses dashed for optional (non-identifying).
    if (notation == ErNotation.idef1x && rel.isOptional) {
      _drawDashedLine(canvas, fromPt, toPt, linePaint);
    } else {
      canvas.drawLine(fromPt, toPt, linePaint);
    }

    // Direction from fromPt to toPt.
    final lineVec = toPt - fromPt;
    final lineLen = lineVec.distance;
    if (lineLen < 1) return;
    final dir = lineVec / lineLen;

    // Cardinality markers.
    if (notation == ErNotation.crowsFoot) {
      final (fromMany, toMany) = _cardinalityFlags(rel.cardinality);
      _drawCrowsFootEnd(
          canvas, fromPt, dir, fromMany, rel.isOptional, linePaint);
      _drawCrowsFootEnd(canvas, toPt, -dir, toMany, false, linePaint);
    } else {
      _drawIdef1xEnd(canvas, fromPt, dir, rel, linePaint);
    }

    // Label at midpoint.
    final mid = Offset(
      (fromPt.dx + toPt.dx) / 2,
      (fromPt.dy + toPt.dy) / 2,
    );
    _paintText(
      canvas,
      rel.cardinality.displayName,
      mid + const Offset(4, -12),
      color: CodeOpsColors.textTertiary,
      fontSize: 9,
    );
  }

  /// Returns (fromIsMany, toIsMany) for a given cardinality.
  (bool, bool) _cardinalityFlags(ErCardinality c) => switch (c) {
        ErCardinality.oneToOne => (false, false),
        ErCardinality.oneToMany => (false, true),
        ErCardinality.manyToOne => (true, false),
        ErCardinality.manyToMany => (true, true),
      };

  /// Draws a Crow's Foot end marker at [endPoint].
  ///
  /// [dirAway] points away from the table (into the line).
  /// If [isMany], draws a crow's foot; otherwise draws a bar.
  /// If [isOptional], adds a small circle.
  void _drawCrowsFootEnd(
    Canvas canvas,
    Offset endPoint,
    Offset dirAway,
    bool isMany,
    bool isOptional,
    Paint paint,
  ) {
    final perp = Offset(-dirAway.dy, dirAway.dx);
    const spread = 8.0;

    // Perpendicular bar — always drawn.
    final barPt = endPoint + dirAway * 10;
    canvas.drawLine(barPt + perp * spread, barPt - perp * spread, paint);

    if (isMany) {
      // Crow's foot: three prongs from a convergence point to table edge.
      final forkPt = endPoint + dirAway * 16;
      final tipBase = endPoint + dirAway * 2;
      canvas.drawLine(forkPt, tipBase + perp * spread, paint);
      canvas.drawLine(forkPt, tipBase, paint);
      canvas.drawLine(forkPt, tipBase - perp * spread, paint);
    }

    if (isOptional) {
      final circlePt = endPoint + dirAway * (isMany ? 24 : 18);
      canvas.drawCircle(
        circlePt,
        4,
        Paint()
          ..color = paint.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = paint.strokeWidth,
      );
    }
  }

  /// Draws an IDEF1X end marker (filled dot at the FK/child end).
  void _drawIdef1xEnd(
    Canvas canvas,
    Offset fromPt,
    Offset dir,
    ErRelationship rel,
    Paint paint,
  ) {
    canvas.drawCircle(
      fromPt + dir * 8,
      4,
      Paint()..color = paint.color,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Geometry Helpers
  // ─────────────────────────────────────────────────────────────────────────

  Rect _getTableRect(ErTableNode table) => Rect.fromLTWH(
        table.position.dx,
        table.position.dy,
        _tw,
        _hh + table.displayColumns.length * _rh,
      );

  /// Finds where a ray from [rect]'s center toward [target] exits [rect].
  Offset _getConnectionPoint(Rect rect, Offset target) {
    final center = rect.center;
    final dx = target.dx - center.dx;
    final dy = target.dy - center.dy;
    if (dx == 0 && dy == 0) return center;

    final halfW = rect.width / 2;
    final halfH = rect.height / 2;
    final sx = dx != 0 ? halfW / dx.abs() : double.infinity;
    final sy = dy != 0 ? halfH / dy.abs() : double.infinity;
    final s = math.min(sx, sy);
    return Offset(center.dx + dx * s, center.dy + dy * s);
  }

  /// Draws a dashed line from [from] to [to].
  void _drawDashedLine(Canvas canvas, Offset from, Offset to, Paint paint) {
    final vec = to - from;
    final len = vec.distance;
    if (len < 1) return;
    final dir = vec / len;
    const dashLen = 6.0;
    const gapLen = 4.0;
    var d = 0.0;
    while (d < len) {
      final start = from + dir * d;
      final end = from + dir * math.min(d + dashLen, len);
      canvas.drawLine(start, end, paint);
      d += dashLen + gapLen;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Text Rendering
  // ─────────────────────────────────────────────────────────────────────────

  void _paintText(
    Canvas canvas,
    String text,
    Offset position, {
    Color color = CodeOpsColors.textPrimary,
    double fontSize = 11,
    FontWeight fontWeight = FontWeight.normal,
    double? maxWidth,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '\u2026',
    )..layout(maxWidth: maxWidth ?? double.infinity);
    tp.paint(canvas, position);
  }
}
