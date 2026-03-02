/// Widget configuration dialog for creating or editing a dashboard widget.
///
/// Presents a form with widget title, type selector, query configuration,
/// and display options. Used from the dashboard detail page when adding
/// or editing widgets.
library;

import 'package:flutter/material.dart';

import '../../models/logger_enums.dart';
import '../../theme/colors.dart';

/// Dialog for creating or editing a dashboard widget.
class WidgetConfigDialog extends StatefulWidget {
  /// Initial title (when editing).
  final String? initialTitle;

  /// Initial widget type (when editing).
  final WidgetType? initialType;

  /// Initial query JSON (when editing).
  final String? initialQueryJson;

  /// Creates a [WidgetConfigDialog].
  const WidgetConfigDialog({
    super.key,
    this.initialTitle,
    this.initialType,
    this.initialQueryJson,
  });

  @override
  State<WidgetConfigDialog> createState() => _WidgetConfigDialogState();
}

class _WidgetConfigDialogState extends State<WidgetConfigDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _queryController;
  late WidgetType _selectedType;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
    _queryController =
        TextEditingController(text: widget.initialQueryJson ?? '');
    _selectedType = widget.initialType ?? WidgetType.counter;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialTitle != null;

    return AlertDialog(
      backgroundColor: CodeOpsColors.surface,
      title: Text(
        isEditing ? 'Edit Widget' : 'Add Widget',
        style: const TextStyle(color: CodeOpsColors.textPrimary),
      ),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title field
              const _FieldLabel('Widget Title'),
              const SizedBox(height: 4),
              TextFormField(
                controller: _titleController,
                style: const TextStyle(color: CodeOpsColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'e.g., Error Count Over Time',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Title required' : null,
              ),
              const SizedBox(height: 16),

              // Type selector
              const _FieldLabel('Widget Type'),
              const SizedBox(height: 4),
              DropdownButtonFormField<WidgetType>(
                value: _selectedType,
                dropdownColor: CodeOpsColors.surface,
                style: const TextStyle(color: CodeOpsColors.textPrimary),
                items: WidgetType.values
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(t.displayName),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedType = v);
                },
              ),
              const SizedBox(height: 16),

              // Query config
              const _FieldLabel('Data Query (JSON)'),
              const SizedBox(height: 4),
              TextFormField(
                controller: _queryController,
                style: const TextStyle(
                  color: CodeOpsColors.textPrimary,
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: '{"metric":"error_count","interval":"1m"}',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _onSave,
          child: Text(isEditing ? 'Save' : 'Add'),
        ),
      ],
    );
  }

  /// Validates and returns the widget configuration.
  void _onSave() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop({
      'title': _titleController.text.trim(),
      'widgetType': _selectedType,
      'queryJson': _queryController.text.trim().isEmpty
          ? null
          : _queryController.text.trim(),
    });
  }
}

/// Small label for form fields.
class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: CodeOpsColors.textSecondary,
      ),
    );
  }
}
