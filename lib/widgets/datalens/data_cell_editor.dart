/// Inline cell editor for the DataLens data grid.
///
/// Provides type-aware editing widgets based on the column's PostgreSQL data
/// type. Supports text, numeric, boolean, date, timestamp, JSON, binary/LOB,
/// UUID, and enum column types. Appears as an overlay when the user
/// double-clicks a cell.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/colors.dart';

/// Callback when a cell value is committed.
typedef CellValueCallback = void Function(dynamic newValue);

/// Inline editor for a single data grid cell.
///
/// The editor type is chosen based on [dataType]:
/// - `boolean` / `bool` → Checkbox toggle
/// - `integer` / `bigint` / `smallint` / `int*` → Numeric text field
/// - `numeric` / `decimal` / `real` / `double*` / `float*` → Decimal text field
/// - `json` / `jsonb` → Multi-line JSON editor
/// - `bytea` → Read-only binary indicator
/// - `date` → Date picker
/// - `timestamp*` → DateTime picker
/// - `uuid` → UUID text field with validation
/// - Everything else → Single-line text field
class DataCellEditor extends StatefulWidget {
  /// The current cell value.
  final dynamic value;

  /// The PostgreSQL data type name (e.g., "text", "integer", "boolean").
  final String dataType;

  /// Whether the column allows NULL values.
  final bool isNullable;

  /// Called when the user commits a new value.
  final CellValueCallback? onCommit;

  /// Called when the user cancels editing.
  final VoidCallback? onCancel;

  /// Creates a [DataCellEditor].
  const DataCellEditor({
    super.key,
    required this.value,
    required this.dataType,
    this.isNullable = true,
    this.onCommit,
    this.onCancel,
  });

  @override
  State<DataCellEditor> createState() => _DataCellEditorState();
}

class _DataCellEditorState extends State<DataCellEditor> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isNull = false;

  @override
  void initState() {
    super.initState();
    _isNull = widget.value == null;
    _controller = TextEditingController(
      text: widget.value?.toString() ?? '',
    );
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.dataType.toLowerCase();

    return Container(
      constraints: const BoxConstraints(minWidth: 120, maxWidth: 300),
      decoration: BoxDecoration(
        color: CodeOpsColors.surface,
        border: Border.all(color: CodeOpsColors.primary, width: 1.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Null toggle (if column is nullable).
          if (widget.isNullable)
            _buildNullToggle(),

          // Editor content.
          if (!_isNull) _buildEditor(type),

          // Action buttons.
          _buildActions(),
        ],
      ),
    );
  }

  /// Builds a toggle row for setting the value to NULL.
  Widget _buildNullToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: Checkbox(
              value: _isNull,
              onChanged: (v) {
                setState(() {
                  _isNull = v ?? false;
                  if (_isNull) _controller.clear();
                });
              },
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              activeColor: CodeOpsColors.primary,
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            'NULL',
            style: TextStyle(
              fontSize: 10,
              color: CodeOpsColors.textTertiary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the type-appropriate editor widget.
  Widget _buildEditor(String type) {
    if (_isBooleanType(type)) return _buildBooleanEditor();
    if (_isIntegerType(type)) return _buildNumericEditor(decimal: false);
    if (_isDecimalType(type)) return _buildNumericEditor(decimal: true);
    if (_isJsonType(type)) return _buildJsonEditor();
    if (_isBinaryType(type)) return _buildBinaryIndicator();
    if (_isDateType(type)) return _buildDateEditor();
    if (_isTimestampType(type)) return _buildTimestampEditor();
    if (_isUuidType(type)) return _buildUuidEditor();
    return _buildTextEditor();
  }

  /// Standard single-line text editor.
  Widget _buildTextEditor() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: _handleKeyEvent,
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          style: const TextStyle(fontSize: 12, color: CodeOpsColors.textPrimary),
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            border: OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: CodeOpsColors.primary),
            ),
          ),
        ),
      ),
    );
  }

  /// Boolean checkbox editor.
  Widget _buildBooleanEditor() {
    final currentValue = widget.value is bool ? widget.value as bool : false;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Checkbox(
            value: _controller.text.toLowerCase() == 'true' ||
                (_controller.text.isEmpty && currentValue),
            onChanged: (v) {
              setState(() {
                _controller.text = (v ?? false).toString();
              });
            },
            activeColor: CodeOpsColors.primary,
          ),
          Text(
            _controller.text.isEmpty
                ? currentValue.toString()
                : _controller.text,
            style: const TextStyle(
              fontSize: 12,
              color: CodeOpsColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  /// Numeric text field (integer or decimal).
  Widget _buildNumericEditor({required bool decimal}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: _handleKeyEvent,
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          keyboardType: TextInputType.numberWithOptions(
            decimal: decimal,
            signed: true,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(
              decimal
                  ? RegExp(r'^-?\d*\.?\d*$')
                  : RegExp(r'^-?\d*$'),
            ),
          ],
          style: const TextStyle(
            fontSize: 12,
            color: CodeOpsColors.textPrimary,
            fontFamily: 'monospace',
          ),
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            border: OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: CodeOpsColors.primary),
            ),
          ),
        ),
      ),
    );
  }

  /// Multi-line JSON editor.
  Widget _buildJsonEditor() {
    // Format JSON if possible.
    if (_controller.text.isNotEmpty && _controller.selection.start == 0) {
      try {
        final parsed = json.decode(_controller.text);
        _controller.text = const JsonEncoder.withIndent('  ').convert(parsed);
      } on Object {
        // Not valid JSON — leave as-is.
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: SizedBox(
        height: 120,
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          maxLines: null,
          expands: true,
          style: const TextStyle(
            fontSize: 11,
            color: CodeOpsColors.textPrimary,
            fontFamily: 'monospace',
          ),
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.all(6),
            border: OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: CodeOpsColors.primary),
            ),
          ),
        ),
      ),
    );
  }

  /// Read-only binary data indicator.
  Widget _buildBinaryIndicator() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.data_object, size: 14, color: CodeOpsColors.textTertiary),
          SizedBox(width: 4),
          Text(
            '(binary data)',
            style: TextStyle(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: CodeOpsColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  /// Date picker editor.
  Widget _buildDateEditor() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: KeyboardListener(
              focusNode: FocusNode(),
              onKeyEvent: _handleKeyEvent,
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                style: const TextStyle(
                  fontSize: 12,
                  color: CodeOpsColors.textPrimary,
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  border: OutlineInputBorder(),
                  hintText: 'YYYY-MM-DD',
                  hintStyle: TextStyle(
                    fontSize: 11,
                    color: CodeOpsColors.textTertiary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: _pickDate,
            child: const Icon(
              Icons.calendar_today,
              size: 16,
              color: CodeOpsColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  /// Timestamp picker editor.
  Widget _buildTimestampEditor() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: KeyboardListener(
              focusNode: FocusNode(),
              onKeyEvent: _handleKeyEvent,
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                style: const TextStyle(
                  fontSize: 12,
                  color: CodeOpsColors.textPrimary,
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  border: OutlineInputBorder(),
                  hintText: 'YYYY-MM-DD HH:MM:SS',
                  hintStyle: TextStyle(
                    fontSize: 11,
                    color: CodeOpsColors.textTertiary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: _pickDate,
            child: const Icon(
              Icons.calendar_today,
              size: 16,
              color: CodeOpsColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  /// UUID text field with format validation hint.
  Widget _buildUuidEditor() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: _handleKeyEvent,
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          style: const TextStyle(
            fontSize: 12,
            color: CodeOpsColors.textPrimary,
            fontFamily: 'monospace',
          ),
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            border: OutlineInputBorder(),
            hintText: 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',
            hintStyle: TextStyle(
              fontSize: 10,
              color: CodeOpsColors.textTertiary,
            ),
          ),
        ),
      ),
    );
  }

  /// OK / Cancel action buttons.
  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: _commit,
            borderRadius: BorderRadius.circular(4),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                'OK',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: CodeOpsColors.success,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: widget.onCancel,
            borderRadius: BorderRadius.circular(4),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 11,
                  color: CodeOpsColors.textTertiary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Actions
  // ─────────────────────────────────────────────────────────────────────────

  /// Commits the edited value.
  void _commit() {
    if (_isNull) {
      widget.onCommit?.call(null);
      return;
    }

    final type = widget.dataType.toLowerCase();
    final text = _controller.text;

    if (_isBooleanType(type)) {
      widget.onCommit?.call(text.toLowerCase() == 'true');
    } else if (_isIntegerType(type)) {
      widget.onCommit?.call(int.tryParse(text) ?? text);
    } else if (_isDecimalType(type)) {
      widget.onCommit?.call(double.tryParse(text) ?? text);
    } else {
      widget.onCommit?.call(text);
    }
  }

  /// Opens a date picker dialog.
  Future<void> _pickDate() async {
    final initial = DateTime.tryParse(_controller.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() {
        _controller.text =
            '${picked.year}-${_pad(picked.month)}-${_pad(picked.day)}';
      });
    }
  }

  /// Handles keyboard shortcuts (Enter to commit, Escape to cancel).
  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.enter &&
          !_isJsonType(widget.dataType.toLowerCase())) {
        _commit();
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        widget.onCancel?.call();
      }
    }
  }

  /// Pads a number with a leading zero.
  String _pad(int n) => n.toString().padLeft(2, '0');

  // ─────────────────────────────────────────────────────────────────────────
  // Type Detection
  // ─────────────────────────────────────────────────────────────────────────

  /// Returns `true` if the type is boolean.
  static bool _isBooleanType(String type) =>
      type == 'boolean' || type == 'bool';

  /// Returns `true` if the type is an integer type.
  static bool _isIntegerType(String type) =>
      type == 'integer' ||
      type == 'bigint' ||
      type == 'smallint' ||
      type.startsWith('int');

  /// Returns `true` if the type is a decimal/floating type.
  static bool _isDecimalType(String type) =>
      type == 'numeric' ||
      type == 'decimal' ||
      type == 'real' ||
      type.startsWith('double') ||
      type.startsWith('float');

  /// Returns `true` if the type is JSON or JSONB.
  static bool _isJsonType(String type) =>
      type == 'json' || type == 'jsonb';

  /// Returns `true` if the type is binary.
  static bool _isBinaryType(String type) => type == 'bytea';

  /// Returns `true` if the type is a date (not timestamp).
  static bool _isDateType(String type) => type == 'date';

  /// Returns `true` if the type is a timestamp.
  static bool _isTimestampType(String type) => type.startsWith('timestamp');

  /// Returns `true` if the type is UUID.
  static bool _isUuidType(String type) => type == 'uuid';
}
