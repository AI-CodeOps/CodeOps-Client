/// Save / edit query dialog for the DataLens module.
///
/// A modal dialog that lets users save a new query or edit an existing one.
/// Fields: name (required), description (optional), SQL (required), and
/// folder (optional — can pick from existing folders or create a new one).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/datalens_models.dart';
import '../../providers/datalens_providers.dart';
import '../../theme/colors.dart';

/// Dialog for saving or editing a SQL query.
///
/// When [existingQuery] is provided, the dialog pre-fills all fields and
/// calls [QueryHistoryService.updateSavedQuery] on save. Otherwise it calls
/// [QueryHistoryService.saveQuery].
class SaveQueryDialog extends ConsumerStatefulWidget {
  /// If editing, the existing query to populate from.
  final SavedQuery? existingQuery;

  /// Optional SQL to pre-fill when creating a new saved query.
  final String? initialSql;

  /// Creates a [SaveQueryDialog].
  const SaveQueryDialog({super.key, this.existingQuery, this.initialSql});

  @override
  ConsumerState<SaveQueryDialog> createState() => _SaveQueryDialogState();
}

class _SaveQueryDialogState extends ConsumerState<SaveQueryDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _sqlController;
  late final TextEditingController _folderController;
  bool _isSaving = false;

  bool get _isEditing => widget.existingQuery != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingQuery;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _descriptionController =
        TextEditingController(text: existing?.description ?? '');
    _sqlController = TextEditingController(
      text: existing?.sql ?? widget.initialSql ?? '',
    );
    _folderController = TextEditingController(text: existing?.folder ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _sqlController.dispose();
    _folderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: CodeOpsColors.surface,
      title: Text(
        _isEditing ? 'Edit Query' : 'Save Query',
        style: const TextStyle(color: CodeOpsColors.textPrimary, fontSize: 16),
      ),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Name field
              _buildField(
                controller: _nameController,
                label: 'Name',
                hint: 'My query',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Description field
              _buildField(
                controller: _descriptionController,
                label: 'Description',
                hint: 'Optional description',
                maxLines: 2,
              ),
              const SizedBox(height: 12),

              // SQL field
              _buildField(
                controller: _sqlController,
                label: 'SQL',
                hint: 'SELECT * FROM ...',
                maxLines: 4,
                monospace: true,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'SQL is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Folder field
              _buildField(
                controller: _folderController,
                label: 'Folder',
                hint: 'Optional folder name',
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _isSaving ? null : _onSave,
          style: TextButton.styleFrom(foregroundColor: CodeOpsColors.primary),
          child: Text(_isEditing ? 'Update' : 'Save'),
        ),
      ],
    );
  }

  /// Builds a labeled text form field.
  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    bool monospace = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: TextStyle(
        fontSize: 13,
        color: CodeOpsColors.textPrimary,
        fontFamily: monospace ? 'monospace' : null,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontSize: 12,
          color: CodeOpsColors.textSecondary,
        ),
        hintText: hint,
        hintStyle: const TextStyle(
          fontSize: 12,
          color: CodeOpsColors.textTertiary,
        ),
        border: const OutlineInputBorder(
          borderSide: BorderSide(color: CodeOpsColors.border),
        ),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: CodeOpsColors.border),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: CodeOpsColors.primary),
        ),
        errorBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: CodeOpsColors.error),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
        filled: true,
        fillColor: CodeOpsColors.background,
      ),
    );
  }

  /// Validates the form and saves the query.
  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    final connectionId = ref.read(selectedConnectionIdProvider);
    if (connectionId == null) return;

    setState(() => _isSaving = true);

    try {
      final service = ref.read(datalensHistoryServiceProvider);
      final name = _nameController.text.trim();
      final sql = _sqlController.text.trim();
      final description = _descriptionController.text.trim();
      final folder = _folderController.text.trim();

      if (_isEditing) {
        await service.updateSavedQuery(SavedQuery(
          id: widget.existingQuery!.id,
          connectionId: connectionId,
          name: name,
          sql: sql,
          description: description.isEmpty ? null : description,
          folder: folder.isEmpty ? null : folder,
        ));
      } else {
        await service.saveQuery(
          connectionId: connectionId,
          name: name,
          sql: sql,
          description: description.isEmpty ? null : description,
          folder: folder.isEmpty ? null : folder,
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } on Object catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
    }
  }
}
