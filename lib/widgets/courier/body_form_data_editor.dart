/// Form-data body editor for the Courier request builder.
///
/// Extends [KeyValueEditor] with a per-row Text/File type toggle, file picker
/// button, file size display, and content-type field for multipart form data
/// and URL-encoded form bodies.
library;

import 'dart:math';

import 'package:flutter/material.dart';

import '../../theme/colors.dart';
import 'key_value_editor.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FormDataEntry
// ─────────────────────────────────────────────────────────────────────────────

/// Type of value in a form data row.
enum FormDataValueType {
  /// Plain text value.
  text,

  /// File attachment.
  file,
}

/// A single form-data entry with text/file type, optional file metadata,
/// and content-type override.
class FormDataEntry {
  /// Client-generated unique identifier.
  final String id;

  /// The field name.
  final String key;

  /// The field value (text content or file path).
  final String value;

  /// Whether this entry is a text value or file attachment.
  final FormDataValueType valueType;

  /// MIME content-type override (e.g. `application/json` for a text field).
  final String contentType;

  /// File name (populated when [valueType] is [FormDataValueType.file]).
  final String fileName;

  /// File size in bytes (populated when [valueType] is [FormDataValueType.file]).
  final int fileSize;

  /// Whether this entry is included in the request.
  final bool enabled;

  /// Optional description.
  final String description;

  /// Creates a [FormDataEntry].
  const FormDataEntry({
    required this.id,
    this.key = '',
    this.value = '',
    this.valueType = FormDataValueType.text,
    this.contentType = '',
    this.fileName = '',
    this.fileSize = 0,
    this.enabled = true,
    this.description = '',
  });

  /// Returns a copy with optionally updated fields.
  FormDataEntry copyWith({
    String? id,
    String? key,
    String? value,
    FormDataValueType? valueType,
    String? contentType,
    String? fileName,
    int? fileSize,
    bool? enabled,
    String? description,
  }) {
    return FormDataEntry(
      id: id ?? this.id,
      key: key ?? this.key,
      value: value ?? this.value,
      valueType: valueType ?? this.valueType,
      contentType: contentType ?? this.contentType,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      enabled: enabled ?? this.enabled,
      description: description ?? this.description,
    );
  }

  /// Whether this row is empty (no key or value entered).
  bool get isEmpty => key.isEmpty && value.isEmpty && fileName.isEmpty;

  /// Converts to a [KeyValuePair] for serialization.
  KeyValuePair toKeyValuePair() {
    return KeyValuePair(
      id: id,
      key: key,
      value: valueType == FormDataValueType.file ? fileName : value,
      description: description,
      enabled: enabled,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BodyFormDataEditor
// ─────────────────────────────────────────────────────────────────────────────

/// Form-data body editor with per-row Text/File toggle, file picker, and
/// content-type field.
///
/// For multipart form data bodies, each row can be either a text field or a
/// file attachment. For URL-encoded bodies, all rows are text-only (no file
/// toggle is shown).
class BodyFormDataEditor extends StatefulWidget {
  /// Current list of form data entries.
  final List<FormDataEntry> entries;

  /// Called whenever the entry list changes.
  final ValueChanged<List<FormDataEntry>> onChanged;

  /// Whether to show file-type toggle (true for form-data, false for
  /// url-encoded).
  final bool allowFiles;

  /// Available variable names for `{{}}` autocomplete.
  final List<String> variableNames;

  /// Creates a [BodyFormDataEditor].
  const BodyFormDataEditor({
    super.key,
    required this.entries,
    required this.onChanged,
    this.allowFiles = true,
    this.variableNames = const [],
  });

  @override
  State<BodyFormDataEditor> createState() => _BodyFormDataEditorState();
}

class _BodyFormDataEditorState extends State<BodyFormDataEditor> {
  String _newId() =>
      'fd-${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(9999)}';

  List<FormDataEntry> _ensureTrailingEmpty(List<FormDataEntry> entries) {
    if (entries.isEmpty || !entries.last.isEmpty) {
      return [...entries, FormDataEntry(id: _newId())];
    }
    return entries;
  }

  void _emitChange(List<FormDataEntry> updated) {
    widget.onChanged(_ensureTrailingEmpty(updated));
  }

  void _updateEntry(int index, FormDataEntry updated) {
    final list = List<FormDataEntry>.from(widget.entries);
    list[index] = updated;
    _emitChange(list);
  }

  void _deleteEntry(int index) {
    final list = List<FormDataEntry>.from(widget.entries);
    list.removeAt(index);
    _emitChange(list);
  }

  void _toggleAll(bool enabled) {
    final list = widget.entries
        .map((e) => e.isEmpty ? e : e.copyWith(enabled: enabled))
        .toList();
    _emitChange(list);
  }

  @override
  Widget build(BuildContext context) {
    final entries = _ensureTrailingEmpty(widget.entries);
    final allNonEmpty = entries.where((e) => !e.isEmpty).toList();
    final allEnabled =
        allNonEmpty.isNotEmpty && allNonEmpty.every((e) => e.enabled);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header row.
        _FormDataHeader(
          allEnabled: allEnabled,
          onToggleAll: (v) => _toggleAll(v ?? true),
          showFileColumn: widget.allowFiles,
        ),
        const Divider(height: 1, thickness: 1, color: CodeOpsColors.border),
        // Data rows.
        Expanded(
          child: ListView.builder(
            key: const Key('form_data_list'),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              final isLast = entry.isEmpty && index == entries.length - 1;
              return _FormDataRow(
                key: ValueKey(entry.id),
                index: index,
                entry: entry,
                isLastEmpty: isLast,
                showFileToggle: widget.allowFiles,
                onChanged: (updated) => _updateEntry(index, updated),
                onDelete: () => _deleteEntry(index),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _FormDataHeader
// ─────────────────────────────────────────────────────────────────────────────

class _FormDataHeader extends StatelessWidget {
  final bool allEnabled;
  final ValueChanged<bool?> onToggleAll;
  final bool showFileColumn;

  const _FormDataHeader({
    required this.allEnabled,
    required this.onToggleAll,
    required this.showFileColumn,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: CodeOpsColors.surfaceVariant,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Row(
        children: [
          // Select-all checkbox.
          SizedBox(
            width: 32,
            child: Checkbox(
              key: const Key('form_data_select_all'),
              value: allEnabled,
              onChanged: onToggleAll,
              visualDensity: VisualDensity.compact,
              side: const BorderSide(color: CodeOpsColors.textTertiary),
              activeColor: CodeOpsColors.primary,
            ),
          ),
          const Expanded(
            flex: 3,
            child: Text(
              'Key',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: CodeOpsColors.textSecondary,
              ),
            ),
          ),
          const Expanded(
            flex: 3,
            child: Text(
              'Value',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: CodeOpsColors.textSecondary,
              ),
            ),
          ),
          if (showFileColumn)
            const SizedBox(
              width: 80,
              child: Text(
                'Type',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: CodeOpsColors.textSecondary,
                ),
              ),
            ),
          const Expanded(
            flex: 2,
            child: Text(
              'Content-Type',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: CodeOpsColors.textSecondary,
              ),
            ),
          ),
          // Delete button placeholder.
          const SizedBox(width: 36),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _FormDataRow
// ─────────────────────────────────────────────────────────────────────────────

class _FormDataRow extends StatelessWidget {
  final int index;
  final FormDataEntry entry;
  final bool isLastEmpty;
  final bool showFileToggle;
  final ValueChanged<FormDataEntry> onChanged;
  final VoidCallback onDelete;

  const _FormDataRow({
    super.key,
    required this.index,
    required this.entry,
    required this.isLastEmpty,
    required this.showFileToggle,
    required this.onChanged,
    required this.onDelete,
  });

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        fontSize: 12,
        color: CodeOpsColors.textTertiary,
      ),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      filled: true,
      fillColor: Colors.transparent,
      border: InputBorder.none,
    );
  }

  TextStyle _fieldStyle() {
    return TextStyle(
      fontSize: 12,
      fontFamily: 'monospace',
      color: entry.enabled
          ? CodeOpsColors.textPrimary
          : CodeOpsColors.textTertiary,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: Key('form_data_row_$index'),
      decoration: const BoxDecoration(
        border: Border(
            bottom: BorderSide(color: CodeOpsColors.border, width: 0.5)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        children: [
          // Enable/disable checkbox.
          SizedBox(
            width: 32,
            child: Checkbox(
              key: Key('form_data_enable_$index'),
              value: entry.enabled,
              onChanged: isLastEmpty
                  ? null
                  : (v) => onChanged(entry.copyWith(enabled: v ?? true)),
              visualDensity: VisualDensity.compact,
              side: const BorderSide(color: CodeOpsColors.textTertiary),
              activeColor: CodeOpsColors.primary,
            ),
          ),
          // Key field.
          Expanded(
            flex: 3,
            child: TextField(
              key: Key('form_data_key_$index'),
              controller: TextEditingController(text: entry.key)
                ..selection =
                    TextSelection.collapsed(offset: entry.key.length),
              style: _fieldStyle(),
              decoration: _fieldDecoration('Key'),
              onChanged: (v) => onChanged(entry.copyWith(key: v)),
            ),
          ),
          // Value field (text input or file display).
          Expanded(
            flex: 3,
            child: entry.valueType == FormDataValueType.file
                ? Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.fileName.isEmpty
                              ? 'No file selected'
                              : entry.fileName,
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                            color: entry.fileName.isEmpty
                                ? CodeOpsColors.textTertiary
                                : CodeOpsColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        key: Key('form_data_file_pick_$index'),
                        icon: const Icon(Icons.attach_file,
                            size: 14, color: CodeOpsColors.textSecondary),
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(maxWidth: 28, maxHeight: 28),
                        splashRadius: 14,
                        onPressed: () {
                          // File picker will be wired in execution phase.
                          // For now, stub with placeholder.
                        },
                        tooltip: 'Select file',
                      ),
                    ],
                  )
                : TextField(
                    key: Key('form_data_value_$index'),
                    controller: TextEditingController(text: entry.value)
                      ..selection =
                          TextSelection.collapsed(offset: entry.value.length),
                    style: _fieldStyle(),
                    decoration: _fieldDecoration('Value'),
                    onChanged: (v) => onChanged(entry.copyWith(value: v)),
                  ),
          ),
          // Text/File type toggle.
          if (showFileToggle)
            SizedBox(
              width: 80,
              child: isLastEmpty
                  ? const SizedBox.shrink()
                  : DropdownButtonHideUnderline(
                      child: DropdownButton<FormDataValueType>(
                        key: Key('form_data_type_$index'),
                        value: entry.valueType,
                        isDense: true,
                        dropdownColor: CodeOpsColors.surfaceVariant,
                        items: const [
                          DropdownMenuItem(
                            value: FormDataValueType.text,
                            child: Text('Text',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: CodeOpsColors.textSecondary)),
                          ),
                          DropdownMenuItem(
                            value: FormDataValueType.file,
                            child: Text('File',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: CodeOpsColors.textSecondary)),
                          ),
                        ],
                        onChanged: (v) {
                          if (v != null) {
                            onChanged(entry.copyWith(valueType: v));
                          }
                        },
                      ),
                    ),
            ),
          // Content-type field.
          Expanded(
            flex: 2,
            child: TextField(
              key: Key('form_data_content_type_$index'),
              controller: TextEditingController(text: entry.contentType)
                ..selection =
                    TextSelection.collapsed(offset: entry.contentType.length),
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: entry.enabled
                    ? CodeOpsColors.textSecondary
                    : CodeOpsColors.textTertiary,
              ),
              decoration: _fieldDecoration('auto'),
              onChanged: (v) => onChanged(entry.copyWith(contentType: v)),
            ),
          ),
          // Delete button.
          SizedBox(
            width: 36,
            child: isLastEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    key: Key('form_data_delete_$index'),
                    icon: const Icon(Icons.close,
                        size: 14, color: CodeOpsColors.textTertiary),
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(maxWidth: 28, maxHeight: 28),
                    splashRadius: 14,
                    onPressed: onDelete,
                  ),
          ),
        ],
      ),
    );
  }
}
