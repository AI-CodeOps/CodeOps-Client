/// Dialog for updating an existing Vault secret.
///
/// Pre-populated with the current secret values. Supports updating the
/// description, max versions, retention days, expiry, and optionally
/// creating a new version by providing a new value with change description.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/vault_models.dart';
import '../../providers/vault_providers.dart';
import '../../theme/colors.dart';

/// A modal dialog for updating an existing secret.
class UpdateSecretDialog extends ConsumerStatefulWidget {
  /// The secret to update.
  final SecretResponse secret;

  /// Creates an [UpdateSecretDialog].
  const UpdateSecretDialog({super.key, required this.secret});

  @override
  ConsumerState<UpdateSecretDialog> createState() => _UpdateSecretDialogState();
}

class _UpdateSecretDialogState extends ConsumerState<UpdateSecretDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _valueController;
  late final TextEditingController _changeDescController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _maxVersionsController;
  late final TextEditingController _retentionDaysController;

  DateTime? _expiresAt;
  bool _obscureValue = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _valueController = TextEditingController();
    _changeDescController = TextEditingController();
    _descriptionController =
        TextEditingController(text: widget.secret.description ?? '');
    _maxVersionsController = TextEditingController(
      text: widget.secret.maxVersions?.toString() ?? '',
    );
    _retentionDaysController = TextEditingController(
      text: widget.secret.retentionDays?.toString() ?? '',
    );
    _expiresAt = widget.secret.expiresAt;
  }

  @override
  void dispose() {
    _valueController.dispose();
    _changeDescController.dispose();
    _descriptionController.dispose();
    _maxVersionsController.dispose();
    _retentionDaysController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: CodeOpsColors.surface,
      title: Text('Update: ${widget.secret.name}'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // New Value (optional — creates new version)
                const Text(
                  'New Value (optional — creates new version)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: CodeOpsColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _valueController,
                  obscureText: _obscureValue,
                  maxLines: _obscureValue ? 1 : 3,
                  decoration: InputDecoration(
                    hintText: 'Leave empty to keep current value',
                    border: const OutlineInputBorder(),
                    isDense: true,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureValue ? Icons.visibility : Icons.visibility_off,
                        size: 18,
                      ),
                      onPressed: () =>
                          setState(() => _obscureValue = !_obscureValue),
                    ),
                  ),
                ),
                // Change Description (shown when value is entered)
                if (_valueController.text.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _changeDescController,
                    decoration: const InputDecoration(
                      labelText: 'Change Description',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                const Divider(height: 1, color: CodeOpsColors.border),
                const SizedBox(height: 16),
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
                // Max Versions + Retention Days
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _maxVersionsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Max Versions',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return null;
                          final n = int.tryParse(v);
                          if (n == null || n < 1 || n > 1000) {
                            return '1–1000';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _retentionDaysController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Retention Days',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return null;
                          final n = int.tryParse(v);
                          if (n == null || n < 1) return 'Must be >= 1';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Expires At
                Row(
                  children: [
                    const Text(
                      'Expires At:',
                      style: TextStyle(
                        fontSize: 12,
                        color: CodeOpsColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: _pickExpiry,
                      child: Text(
                        _expiresAt != null
                            ? '${_expiresAt!.year}-${_expiresAt!.month.toString().padLeft(2, '0')}-${_expiresAt!.day.toString().padLeft(2, '0')}'
                            : 'Not set',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    if (_expiresAt != null)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 14),
                        onPressed: () => setState(() => _expiresAt = null),
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
              : const Text('Update'),
        ),
      ],
    );
  }

  Future<void> _pickExpiry() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _expiresAt ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_expiresAt ?? DateTime.now()),
      );
      if (mounted) {
        setState(() {
          _expiresAt = DateTime(
            date.year,
            date.month,
            date.day,
            time?.hour ?? 0,
            time?.minute ?? 0,
          );
        });
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    try {
      final api = ref.read(vaultApiProvider);
      await api.updateSecret(
        widget.secret.id,
        value: _valueController.text.isEmpty ? null : _valueController.text,
        changeDescription: _changeDescController.text.isEmpty
            ? null
            : _changeDescController.text.trim(),
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text.trim(),
        maxVersions: _maxVersionsController.text.isEmpty
            ? null
            : int.parse(_maxVersionsController.text),
        retentionDays: _retentionDaysController.text.isEmpty
            ? null
            : int.parse(_retentionDaysController.text),
        expiresAt: _expiresAt,
      );
      ref.invalidate(vaultSecretsProvider);
      ref.invalidate(vaultSecretDetailProvider(widget.secret.id));
      ref.invalidate(vaultSecretVersionsProvider(widget.secret.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Secret updated')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e')),
        );
      }
    }
  }
}
