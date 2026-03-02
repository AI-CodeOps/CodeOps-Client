/// Export service for ER diagrams.
///
/// Supports exporting the diagram as PNG (raster via [PictureRecorder]) or
/// SVG (vector markup string). Uses the same [ErDiagramPainter] for PNG
/// rendering to guarantee visual fidelity with the canvas display.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../../models/datalens_er_models.dart';
import '../../theme/colors.dart';
import '../../widgets/datalens/er_diagram_canvas.dart';
import '../logging/log_service.dart';

/// Exports ER diagrams as PNG bytes or SVG markup.
///
/// PNG export uses [ErDiagramPainter] with a [PictureRecorder] to render
/// the diagram identically to the on-screen canvas. SVG export generates
/// markup manually from the diagram state.
class ErExportService {
  static const String _tag = 'ErExportService';

  static const double _tw = ErDiagramCanvasState.tableWidth;
  static const double _hh = ErDiagramCanvasState.headerHeight;
  static const double _rh = ErDiagramCanvasState.rowHeight;

  /// Creates an [ErExportService].
  const ErExportService();

  // ─────────────────────────────────────────────────────────────────────────
  // PNG Export
  // ─────────────────────────────────────────────────────────────────────────

  /// Exports the diagram as PNG bytes.
  ///
  /// [scale] controls the output resolution (2.0 = 2x for retina).
  /// Returns an empty [Uint8List] if the diagram has no tables.
  Future<Uint8List> exportPng(
    ErDiagramState state, {
    double scale = 2.0,
  }) async {
    if (state.tables.isEmpty) return Uint8List(0);
    log.d(_tag, 'exportPng(${state.tables.length} tables, scale=$scale)');

    final (minX, minY, maxX, maxY) = _boundingBox(state);
    const pad = 50.0;
    final width = ((maxX - minX + pad * 2) * scale).ceil();
    final height = ((maxY - minY + pad * 2) * scale).ceil();

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    // Use the same painter with adjusted zoom/pan for export framing.
    final painter = ErDiagramPainter(
      tables: state.tables,
      relationships: state.relationships,
      notation: state.notation,
      zoom: scale,
      pan: Offset((pad - minX) * scale, (pad - minY) * scale),
      selectedTable: null,
    );
    painter.paint(canvas, Size(width.toDouble(), height.toDouble()));

    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SVG Export
  // ─────────────────────────────────────────────────────────────────────────

  /// Exports the diagram as an SVG markup string.
  ///
  /// Returns a minimal empty SVG if the diagram has no tables.
  String exportSvg(ErDiagramState state) {
    if (state.tables.isEmpty) {
      return '<svg xmlns="http://www.w3.org/2000/svg"/>';
    }
    log.d(_tag, 'exportSvg(${state.tables.length} tables)');

    final (minX, minY, maxX, maxY) = _boundingBox(state);
    const pad = 50.0;
    final w = maxX - minX + pad * 2;
    final h = maxY - minY + pad * 2;
    final ox = pad - minX;
    final oy = pad - minY;

    final buf = StringBuffer()
      ..writeln('<svg xmlns="http://www.w3.org/2000/svg" '
          'width="${w.ceil()}" height="${h.ceil()}" '
          'viewBox="0 0 ${w.ceil()} ${h.ceil()}">')
      ..writeln(
          '<rect width="100%" height="100%" fill="${_hex(CodeOpsColors.background)}"/>')
      ..writeln('<g font-family="monospace, sans-serif">');

    // Relationship lines (below tables).
    for (final rel in state.relationships) {
      _svgRelationship(buf, rel, state, ox, oy);
    }

    // Table boxes.
    for (final table in state.tables) {
      _svgTable(buf, table, ox, oy);
    }

    buf
      ..writeln('</g>')
      ..writeln('</svg>');
    return buf.toString();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SVG — Tables
  // ─────────────────────────────────────────────────────────────────────────

  void _svgTable(StringBuffer buf, ErTableNode table, double ox, double oy) {
    final x = table.position.dx + ox;
    final y = table.position.dy + oy;
    final cols = table.displayColumns;
    final h = _hh + cols.length * _rh;

    // Shadow.
    buf.writeln('<rect x="${x + 2}" y="${y + 2}" width="$_tw" '
        'height="$h" rx="4" fill="rgba(0,0,0,0.25)"/>');

    // Background.
    buf.writeln('<rect x="$x" y="$y" width="$_tw" height="$h" rx="4" '
        'fill="${_hex(CodeOpsColors.surface)}" '
        'stroke="${_hex(CodeOpsColors.border)}"/>');

    // Header.
    final headerFill = table.isView
        ? 'rgba(0,217,255,0.2)'
        : 'rgba(108,99,255,0.2)';
    buf.writeln('<rect x="$x" y="$y" width="$_tw" height="$_hh" rx="4" '
        'fill="$headerFill"/>');
    buf.writeln('<line x1="$x" y1="${y + _hh}" x2="${x + _tw}" '
        'y2="${y + _hh}" stroke="${_hex(CodeOpsColors.border)}"/>');

    // Table name.
    final nameColor =
        table.isView ? CodeOpsColors.secondary : CodeOpsColors.textPrimary;
    buf.writeln('<text x="${x + 8}" y="${y + 18}" fill="${_hex(nameColor)}" '
        'font-size="12" font-weight="600">${_esc(table.tableName)}</text>');

    // Columns.
    for (var i = 0; i < cols.length; i++) {
      final col = cols[i];
      final cy = y + _hh + i * _rh;

      // Badge.
      if (col.isPrimaryKey) {
        buf.writeln('<text x="${x + 4}" y="${cy + 14}" '
            'fill="${_hex(CodeOpsColors.warning)}" font-size="9" '
            'font-weight="700">PK</text>');
      } else if (col.isForeignKey) {
        buf.writeln('<text x="${x + 4}" y="${cy + 14}" '
            'fill="${_hex(CodeOpsColors.secondary)}" font-size="9" '
            'font-weight="700">FK</text>');
      }

      // Name.
      final nc = col.isPrimaryKey
          ? CodeOpsColors.warning
          : col.isForeignKey
              ? CodeOpsColors.secondary
              : CodeOpsColors.textPrimary;
      buf.writeln('<text x="${x + 24}" y="${cy + 14}" fill="${_hex(nc)}" '
          'font-size="10">${_esc(col.name)}</text>');

      // Type.
      buf.writeln('<text x="${x + _tw * 0.58}" y="${cy + 14}" '
          'fill="${_hex(CodeOpsColors.textTertiary)}" '
          'font-size="10">${_esc(col.dataType)}</text>');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SVG — Relationships
  // ─────────────────────────────────────────────────────────────────────────

  void _svgRelationship(
    StringBuffer buf,
    ErRelationship rel,
    ErDiagramState state,
    double ox,
    double oy,
  ) {
    final fromNode =
        state.tables.where((t) => t.tableName == rel.fromTable).firstOrNull;
    final toNode =
        state.tables.where((t) => t.tableName == rel.toTable).firstOrNull;
    if (fromNode == null || toNode == null) return;

    final fromRect = Rect.fromLTWH(
      fromNode.position.dx + ox,
      fromNode.position.dy + oy,
      _tw,
      _tableHeight(fromNode),
    );
    final toRect = Rect.fromLTWH(
      toNode.position.dx + ox,
      toNode.position.dy + oy,
      _tw,
      _tableHeight(toNode),
    );
    final from = _connPt(fromRect, toRect.center);
    final to = _connPt(toRect, fromRect.center);

    final dashAttr =
        (state.notation == ErNotation.idef1x && rel.isOptional)
            ? ' stroke-dasharray="6,4"'
            : '';
    final lineColor = _hex(CodeOpsColors.textTertiary);
    buf.writeln('<line x1="${from.dx.toStringAsFixed(1)}" '
        'y1="${from.dy.toStringAsFixed(1)}" '
        'x2="${to.dx.toStringAsFixed(1)}" '
        'y2="${to.dy.toStringAsFixed(1)}" '
        'stroke="$lineColor" stroke-width="1.5"$dashAttr/>');

    // Label.
    final mx = ((from.dx + to.dx) / 2 + 4).toStringAsFixed(1);
    final my = ((from.dy + to.dy) / 2 - 4).toStringAsFixed(1);
    buf.writeln('<text x="$mx" y="$my" fill="$lineColor" '
        'font-size="9">${rel.cardinality.displayName}</text>');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  double _tableHeight(ErTableNode table) =>
      _hh + table.displayColumns.length * _rh;

  /// Calculates the content bounding box (minX, minY, maxX, maxY).
  (double, double, double, double) _boundingBox(ErDiagramState state) {
    double minX = double.infinity, minY = double.infinity;
    double maxX = double.negativeInfinity, maxY = double.negativeInfinity;
    for (final t in state.tables) {
      minX = math.min(minX, t.position.dx);
      minY = math.min(minY, t.position.dy);
      maxX = math.max(maxX, t.position.dx + _tw);
      maxY = math.max(maxY, t.position.dy + _tableHeight(t));
    }
    return (minX, minY, maxX, maxY);
  }

  /// Finds where a ray from [rect]'s center toward [target] exits [rect].
  Offset _connPt(Rect rect, Offset target) {
    final center = rect.center;
    final dx = target.dx - center.dx;
    final dy = target.dy - center.dy;
    if (dx == 0 && dy == 0) return center;
    final sx = dx != 0 ? (rect.width / 2) / dx.abs() : double.infinity;
    final sy = dy != 0 ? (rect.height / 2) / dy.abs() : double.infinity;
    final s = math.min(sx, sy);
    return Offset(center.dx + dx * s, center.dy + dy * s);
  }

  /// Converts a [Color] to a hex string (e.g., "#1A1B2E").
  String _hex(ui.Color c) =>
      '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

  /// Escapes special characters for SVG text content.
  String _esc(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');
}
