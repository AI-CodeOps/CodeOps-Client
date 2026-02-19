/// Dialog for creating a new transit encryption key.
///
/// Validates the required name field and provides optional description,
/// algorithm (defaults to AES-256-GCM), isDeletable, and isExportable toggles.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/vault_providers.dart';
import '../../theme/colors.dart';

/// A modal dialog for creating a new transit encryption key.
class CreateTransitKeyDialog extends ConsumerStatefulWidget {
  /// Creates a [CreateTransitKeyDialog].
  const CreateTransitKeyDialog({super.key});

  @override
  ConsumerState<CreateTransitKeyDialog> createState() =>
      _CreateTransitKeyDialogState();
}

class _CreateTransitKeyDialogState
    extends ConsumerState<CreateTransitKeyDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _algorithmController =
      TextEditingController(text: 'AES-256-GCM');

  bool _isDeletable = false;
  bool _isExportable = false;
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _algorithmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: CodeOpsColors.surface,
      title: const Text('Create Transit Key'),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name *',
                    hintText: 'my-encryption-key',
                    border: OutlineInputBorder(),
                    isDense: true,
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
                // Algorithm
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
              : const Text('Create'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    try {
      final api = ref.read(vaultApiProvider);
      await api.createTransitKey(
        name: _nameController.text.trim(),
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text.trim(),
        algorithm: _algorithmController.text.trim(),
        isDeletable: _isDeletable ? true : null,
        isExportable: _isExportable ? true : null,
      );
      ref.invalidate(vaultTransitKeysProvider);
      ref.invalidate(vaultTransitStatsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transit key created')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create: $e')),
        );
      }
    }
  }
}
