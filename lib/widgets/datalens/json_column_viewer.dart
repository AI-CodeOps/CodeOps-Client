/// JSON column viewer/editor dialog for the DataLens data grid.
///
/// Displays JSON/JSONB cell values in a formatted, scrollable view with
/// tree-view toggle, validation, and optional editing. Opens as a dialog
/// when the user clicks a JSON cell.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/colors.dart';

/// A dialog for viewing and optionally editing JSON column data.
///
/// Features:
/// - Formatted JSON display with syntax-like coloring
/// - Toggle between raw text and tree view
/// - JSON validation with error display
/// - Copy to clipboard
/// - Optional edit mode with save callback
class JsonColumnViewer extends StatefulWidget {
  /// The JSON string to display.
  final String jsonString;

  /// Column name for the dialog title.
  final String columnName;

  /// Whether editing is allowed.
  final bool editable;

  /// Called when the user saves edited JSON.
  final ValueChanged<String>? onSave;

  /// Creates a [JsonColumnViewer].
  const JsonColumnViewer({
    super.key,
    required this.jsonString,
    required this.columnName,
    this.editable = false,
    this.onSave,
  });

  @override
  State<JsonColumnViewer> createState() => _JsonColumnViewerState();
}

class _JsonColumnViewerState extends State<JsonColumnViewer> {
  late TextEditingController _controller;
  bool _treeView = false;
  String? _validationError;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _formatJson(widget.jsonString));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: CodeOpsColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: CodeOpsColors.border),
      ),
      child: SizedBox(
        width: 600,
        height: 500,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTitleBar(),
            const Divider(height: 1, color: CodeOpsColors.border),
            _buildToolbar(),
            const Divider(height: 1, color: CodeOpsColors.border),
            Expanded(child: _buildContent()),
            if (_validationError != null) _buildValidationError(),
            const Divider(height: 1, color: CodeOpsColors.border),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  /// Builds the dialog title bar.
  Widget _buildTitleBar() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const Icon(Icons.data_object, size: 16, color: CodeOpsColors.secondary),
          const SizedBox(width: 8),
          Text(
            widget.columnName,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: CodeOpsColors.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: CodeOpsColors.secondary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'JSON',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: CodeOpsColors.secondary,
              ),
            ),
          ),
          const Spacer(),
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            child: const Icon(
              Icons.close,
              size: 16,
              color: CodeOpsColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the toolbar with view mode toggle and actions.
  Widget _buildToolbar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          // Raw / Tree toggle.
          _ToggleChip(
            label: 'Raw',
            selected: !_treeView,
            onTap: () => setState(() => _treeView = false),
          ),
          const SizedBox(width: 4),
          _ToggleChip(
            label: 'Tree',
            selected: _treeView,
            onTap: () => setState(() => _treeView = true),
          ),
          const Spacer(),
          // Copy button.
          _ToolbarButton(
            icon: Icons.copy,
            tooltip: 'Copy to clipboard',
            onTap: _copyToClipboard,
          ),
          if (widget.editable) ...[
            const SizedBox(width: 4),
            _ToolbarButton(
              icon: _editing ? Icons.visibility : Icons.edit,
              tooltip: _editing ? 'View mode' : 'Edit mode',
              onTap: () => setState(() => _editing = !_editing),
            ),
          ],
          const SizedBox(width: 4),
          _ToolbarButton(
            icon: Icons.format_align_left,
            tooltip: 'Format JSON',
            onTap: _formatContent,
          ),
          const SizedBox(width: 4),
          _ToolbarButton(
            icon: Icons.check_circle_outline,
            tooltip: 'Validate JSON',
            onTap: _validate,
          ),
        ],
      ),
    );
  }

  /// Builds the main content area.
  Widget _buildContent() {
    if (_treeView) return _buildTreeView();
    return _buildRawView();
  }

  /// Raw text view (read-only or editable).
  Widget _buildRawView() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: TextField(
        controller: _controller,
        readOnly: !_editing,
        maxLines: null,
        expands: true,
        style: const TextStyle(
          fontSize: 12,
          color: CodeOpsColors.textPrimary,
          fontFamily: 'monospace',
          height: 1.4,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: CodeOpsColors.background,
          contentPadding: const EdgeInsets.all(8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: CodeOpsColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: CodeOpsColors.primary),
          ),
        ),
      ),
    );
  }

  /// Tree view rendering of parsed JSON.
  Widget _buildTreeView() {
    try {
      final parsed = json.decode(_controller.text);
      return SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: _buildJsonNode(parsed, 0),
      );
    } on Object catch (e) {
      return Center(
        child: Text(
          'Invalid JSON: $e',
          style: const TextStyle(color: CodeOpsColors.error, fontSize: 12),
        ),
      );
    }
  }

  /// Recursively builds a tree view node.
  Widget _buildJsonNode(dynamic value, int depth) {
    final indent = depth * 16.0;

    if (value == null) {
      return Padding(
        padding: EdgeInsets.only(left: indent),
        child: const Text(
          'null',
          style: TextStyle(
            fontSize: 12,
            fontStyle: FontStyle.italic,
            color: CodeOpsColors.textTertiary,
            fontFamily: 'monospace',
          ),
        ),
      );
    }

    if (value is bool) {
      return Padding(
        padding: EdgeInsets.only(left: indent),
        child: Text(
          value.toString(),
          style: TextStyle(
            fontSize: 12,
            color: value ? CodeOpsColors.success : CodeOpsColors.error,
            fontFamily: 'monospace',
          ),
        ),
      );
    }

    if (value is num) {
      return Padding(
        padding: EdgeInsets.only(left: indent),
        child: Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 12,
            color: CodeOpsColors.warning,
            fontFamily: 'monospace',
          ),
        ),
      );
    }

    if (value is String) {
      return Padding(
        padding: EdgeInsets.only(left: indent),
        child: Text(
          '"$value"',
          style: const TextStyle(
            fontSize: 12,
            color: CodeOpsColors.success,
            fontFamily: 'monospace',
          ),
        ),
      );
    }

    if (value is List) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: indent),
            child: Text(
              'Array [${value.length}]',
              style: const TextStyle(
                fontSize: 12,
                color: CodeOpsColors.textSecondary,
                fontFamily: 'monospace',
              ),
            ),
          ),
          ...value.asMap().entries.map((entry) => Padding(
                padding: EdgeInsets.only(left: indent + 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${entry.key}: ',
                      style: const TextStyle(
                        fontSize: 12,
                        color: CodeOpsColors.textTertiary,
                        fontFamily: 'monospace',
                      ),
                    ),
                    Expanded(child: _buildJsonNode(entry.value, 0)),
                  ],
                ),
              )),
        ],
      );
    }

    if (value is Map) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: indent),
            child: Text(
              'Object {${value.length}}',
              style: const TextStyle(
                fontSize: 12,
                color: CodeOpsColors.textSecondary,
                fontFamily: 'monospace',
              ),
            ),
          ),
          ...value.entries.map((entry) => Padding(
                padding: EdgeInsets.only(left: indent + 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '"${entry.key}": ',
                      style: const TextStyle(
                        fontSize: 12,
                        color: CodeOpsColors.primary,
                        fontFamily: 'monospace',
                      ),
                    ),
                    Expanded(child: _buildJsonNode(entry.value, 0)),
                  ],
                ),
              )),
        ],
      );
    }

    return Padding(
      padding: EdgeInsets.only(left: indent),
      child: Text(
        value.toString(),
        style: const TextStyle(
          fontSize: 12,
          color: CodeOpsColors.textPrimary,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  /// Shows validation error below the content.
  Widget _buildValidationError() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      color: CodeOpsColors.error.withValues(alpha: 0.1),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 12, color: CodeOpsColors.error),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              _validationError!,
              style: const TextStyle(
                fontSize: 11,
                color: CodeOpsColors.error,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the footer with size info and save button.
  Widget _buildFooter() {
    final byteSize = utf8.encode(_controller.text).length;
    final sizeLabel = byteSize > 1024
        ? '${(byteSize / 1024).toStringAsFixed(1)} KB'
        : '$byteSize bytes';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Text(
            'Size: $sizeLabel',
            style: const TextStyle(
              fontSize: 11,
              color: CodeOpsColors.textTertiary,
            ),
          ),
          const Spacer(),
          if (_editing && widget.onSave != null)
            TextButton(
              onPressed: _save,
              child: const Text(
                'Save',
                style: TextStyle(fontSize: 12, color: CodeOpsColors.success),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Close',
              style: TextStyle(fontSize: 12, color: CodeOpsColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Actions
  // ─────────────────────────────────────────────────────────────────────────

  /// Formats the JSON content.
  void _formatContent() {
    try {
      final parsed = json.decode(_controller.text);
      setState(() {
        _controller.text = const JsonEncoder.withIndent('  ').convert(parsed);
        _validationError = null;
      });
    } on Object catch (e) {
      setState(() => _validationError = e.toString());
    }
  }

  /// Validates the JSON content.
  void _validate() {
    try {
      json.decode(_controller.text);
      setState(() => _validationError = null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Valid JSON'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } on Object catch (e) {
      setState(() => _validationError = e.toString());
    }
  }

  /// Copies content to clipboard.
  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _controller.text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Copied to clipboard'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  /// Saves edited JSON.
  void _save() {
    try {
      // Validate before saving.
      json.decode(_controller.text);
      setState(() => _validationError = null);
      widget.onSave?.call(_controller.text);
      Navigator.of(context).pop();
    } on Object catch (e) {
      setState(() => _validationError = 'Cannot save invalid JSON: $e');
    }
  }

  /// Formats a JSON string with indentation.
  String _formatJson(String input) {
    try {
      final parsed = json.decode(input);
      return const JsonEncoder.withIndent('  ').convert(parsed);
    } on Object {
      return input;
    }
  }
}

/// A small toggle chip for the toolbar.
class _ToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _ToggleChip({
    required this.label,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: selected
              ? CodeOpsColors.primary.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: selected ? CodeOpsColors.primary : CodeOpsColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            color: selected
                ? CodeOpsColors.primary
                : CodeOpsColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// A small icon button for the toolbar.
class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 14, color: CodeOpsColors.textSecondary),
        ),
      ),
    );
  }
}
