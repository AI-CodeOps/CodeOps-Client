/// ER diagram page for the DataLens module.
///
/// Combines the [ErDiagramToolbar] and [ErDiagramCanvas] into a full-screen
/// page for viewing and interacting with entity-relationship diagrams.
/// Builds the diagram from schema metadata on load and supports notation
/// toggling, zoom/pan, table dragging, auto-layout, and PNG/SVG export.
library;

import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/datalens_er_models.dart';
import '../../providers/datalens_providers.dart';
import '../../services/datalens/er_export_service.dart';
import '../../theme/colors.dart';
import '../../widgets/datalens/er_diagram_canvas.dart';
import '../../widgets/datalens/er_diagram_toolbar.dart';

/// Full-screen ER diagram page with toolbar and interactive canvas.
///
/// Reads the selected connection and schema from providers, builds the
/// diagram via [ErDiagramService], and renders it with [ErDiagramCanvas].
/// Supports full-schema and single-table-related diagram scopes.
class ErDiagramPage extends ConsumerStatefulWidget {
  /// Optional table name for single-table-related mode.
  final String? focusTable;

  /// Creates an [ErDiagramPage].
  const ErDiagramPage({super.key, this.focusTable});

  @override
  ConsumerState<ErDiagramPage> createState() => _ErDiagramPageState();
}

class _ErDiagramPageState extends ConsumerState<ErDiagramPage> {
  final _canvasKey = GlobalKey<ErDiagramCanvasState>();
  final _exportService = const ErExportService();
  ErDiagramState? _diagramState;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _buildDiagram());
  }

  Future<void> _buildDiagram() async {
    final connectionId = ref.read(selectedConnectionIdProvider);
    final schema = ref.read(selectedSchemaProvider);
    if (connectionId == null || schema == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final erService = ref.read(datalensErDiagramServiceProvider);
      final state = widget.focusTable != null
          ? await erService.buildSingleTableDiagram(
              connectionId, schema, widget.focusTable!)
          : await erService.buildDiagram(connectionId, schema);
      if (mounted) setState(() => _diagramState = state);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onNotationChanged(ErNotation notation) {
    if (_diagramState == null) return;
    setState(() {
      _diagramState = _diagramState!.copyWith(notation: notation);
    });
  }

  void _onAutoLayout() {
    if (_diagramState == null) return;
    final erService = ref.read(datalensErDiagramServiceProvider);
    setState(() {
      _diagramState = erService.autoLayout(_diagramState!);
    });
    // Zoom to fit after layout.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final canvasState = _canvasKey.currentState;
      if (canvasState != null && canvasState.mounted) {
        canvasState.zoomToFit(
          (context.findRenderObject() as RenderBox?)?.size ?? Size.zero,
        );
      }
    });
  }

  Future<void> _onExportPng() async {
    if (_diagramState == null) return;
    final bytes = await _exportService.exportPng(_diagramState!);
    if (bytes.isEmpty || !mounted) return;
    final result = await FilePicker.platform.saveFile(
      dialogTitle: 'Export ER Diagram as PNG',
      fileName: 'er_diagram_${_diagramState!.schema}.png',
      type: FileType.custom,
      allowedExtensions: ['png'],
      bytes: bytes,
    );
    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PNG exported to $result'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _onExportSvg() async {
    if (_diagramState == null) return;
    final svg = _exportService.exportSvg(_diagramState!);
    if (!mounted) return;
    final result = await FilePicker.platform.saveFile(
      dialogTitle: 'Export ER Diagram as SVG',
      fileName: 'er_diagram_${_diagramState!.schema}.svg',
      type: FileType.custom,
      allowedExtensions: ['svg'],
      bytes: Uint8List.fromList(svg.codeUnits),
    );
    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('SVG exported to $result'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Toolbar.
        if (_diagramState != null)
          ErDiagramToolbar(
            notation: _diagramState!.notation,
            zoom: _diagramState!.zoom,
            onNotationChanged: _onNotationChanged,
            onAutoLayout: _onAutoLayout,
            onZoomToFit: () => _canvasKey.currentState?.zoomToFit(
              (context.findRenderObject() as RenderBox?)?.size ?? Size.zero,
            ),
            onZoomReset: () => _canvasKey.currentState?.resetView(),
            onExpandAll: () =>
                _canvasKey.currentState?.setAllExpanded(true),
            onCollapseAll: () =>
                _canvasKey.currentState?.setAllExpanded(false),
            onExportPng: _onExportPng,
            onExportSvg: _onExportSvg,
          ),
        if (_diagramState != null)
          const Divider(height: 1, color: CodeOpsColors.border),

        // Content.
        Expanded(child: _buildContent()),
      ],
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: CodeOpsColors.primary),
            SizedBox(height: 12),
            Text(
              'Building ER diagram...',
              style: TextStyle(
                fontSize: 13,
                color: CodeOpsColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: CodeOpsColors.error),
            const SizedBox(height: 12),
            Text(
              'Failed to build diagram',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: CodeOpsColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _error!,
              style: const TextStyle(
                fontSize: 12,
                color: CodeOpsColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _buildDiagram,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_diagramState == null || _diagramState!.tables.isEmpty) {
      return const Center(
        child: Text(
          'No tables found in schema',
          style: TextStyle(
            fontSize: 13,
            color: CodeOpsColors.textSecondary,
          ),
        ),
      );
    }

    return Container(
      color: CodeOpsColors.background,
      child: ErDiagramCanvas(
        key: _canvasKey,
        diagramState: _diagramState!,
        onStateChanged: (state) => setState(() => _diagramState = state),
      ),
    );
  }
}
