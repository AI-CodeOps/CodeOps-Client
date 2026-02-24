/// Dialog for creating or editing a transit encryption key.
///
/// In create mode, provides fields for name, description, algorithm,
/// isDeletable, and isExportable. In edit mode, allows updating
/// description, minDecryptionVersion, isDeletable, isExportable,
/// and isActive.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/vault_models.dart';
import '../../providers/vault_providers.dart';
import '../../theme/colors.dart';

/// A modal dialog for creating or editing a transit encryption key.
class VaultTransitKeyDialog extends ConsumerStatefulWidget {
  /// Existing key to edit (null for create mode).
  final TransitKeyResponse? existingKey;

  /// Creates a [VaultTransitKeyDialog].
  const VaultTransitKeyDialog({super.key, this.existingKey});

  @override
  ConsumerState<VaultTransitKeyDialog> createState() =>
      _VaultTransitKeyDialogState();
}

class _VaultTransitKeyDialogState
    extends ConsumerState<VaultTransitKeyDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _algorithmController;
  late TextEditingController _minDecryptVersionController;

  late bool _isDeletable;
  late bool _isExportable;
  late bool _isActive;
  bool _submitting = false;

  bool get _isEdit => widget.existingKey != null;

  @override
  void initState() {
    super.initState();
    final k = widget.existingKey;
    _nameController = TextEditingController(text: k?.name ?? '');
    _descriptionController =
        TextEditingController(text: k?.description ?? '');
    _algorithmController =
        TextEditingController(text: k?.algorithm ?? 'AES-256-GCM');
    _minDecryptVersionController =
        TextEditingController(text: '${k?.minDecryptionVersion ?? 1}');
    _isDeletable = k?.isDeletable ?? false;
    _isExportable = k?.isExportable ?? false;
    _isActive = k?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _algorithmController.dispose();
    _minDecryptVersionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: CodeOpsColors.surface,
      title: Text(_isEdit ? 'Edit Transit Key' : 'Create Transit Key'),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name (read-only in edit mode)
                TextFormField(
                  controller: _nameController,
                  readOnly: _isEdit,
                  decoration: InputDecoration(
                    labelText: 'Name *',
                    hintText: 'my-encryption-key',
                    border: const OutlineInputBorder(),
                    isDense: true,
                    suffixIcon: _isEdit
                        ? const Icon(Icons.lock_outline, size: 16)
                        : null,
                  ),
                  maxLength: 200,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),

                // Algorithm (create only)
                if (!_isEdit) ...[
                  TextFormField(
                    controller: _algorithmController,
                    decoration: const InputDecoration(
                      labelText: 'Algorithm',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    maxLength: 30,
                  ),
                  const SizedBox(height: 12),
                ],

                // Min Decryption Version (edit only)
                if (_isEdit) ...[
                  TextFormField(
                    controller: _minDecryptVersionController,
                    decoration: InputDecoration(
                      labelText: 'Min Decryption Version',
                      border: const OutlineInputBorder(),
                      isDense: true,
                      helperText:
                          'Current version: v${widget.existingKey!.currentVersion}',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      final n = int.tryParse(v);
                      if (n == null || n < 1) return 'Must be at least 1';
                      if (n > widget.existingKey!.currentVersion) {
                        return 'Cannot exceed current version';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                ],

                // Flags
                Row(
                  children: [
                    Expanded(
                      child: CheckboxListTile(
                        title: const Text(
                          'Deletable',
                          style: TextStyle(fontSize: 13),
                        ),
                        value: _isDeletable,
                        onChanged: (v) =>
                            setState(() => _isDeletable = v ?? false),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ),
                    Expanded(
                      child: CheckboxListTile(
                        title: const Text(
                          'Exportable',
                          style: TextStyle(fontSize: 13),
                        ),
                        value: _isExportable,
                        onChanged: (v) =>
                            setState(() => _isExportable = v ?? false),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ),
                  ],
                ),

                // Active toggle (edit only)
                if (_isEdit)
                  CheckboxListTile(
                    title: const Text(
                      'Active',
                      style: TextStyle(fontSize: 13),
                    ),
                    value: _isActive,
                    onChanged: (v) =>
                        setState(() => _isActive = v ?? true),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(
            'Cancel',
            style: TextStyle(color: CodeOpsColors.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_isEdit ? 'Save' : 'Create'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    try {
      final api = ref.read(vaultApiProvider);

      if (_isEdit) {
        await api.updateTransitKey(
          widget.existingKey!.id,
          description: _descriptionController.text.isEmpty
              ? null
              : _descriptionController.text.trim(),
          minDecryptionVersion:
              int.tryParse(_minDecryptVersionController.text),
          isDeletable: _isDeletable,
          isExportable: _isExportable,
          isActive: _isActive,
        );
      } else {
        await api.createTransitKey(
          name: _nameController.text.trim(),
          description: _descriptionController.text.isEmpty
              ? null
              : _descriptionController.text.trim(),
          algorithm: _algorithmController.text.trim(),
          isDeletable: _isDeletable ? true : null,
          isExportable: _isExportable ? true : null,
        );
      }

      ref.invalidate(vaultTransitKeysProvider);
      ref.invalidate(vaultTransitStatsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit ? 'Key updated' : 'Transit key created'),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    }
  }
}
