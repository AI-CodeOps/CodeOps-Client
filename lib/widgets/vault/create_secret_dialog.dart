/// Dialog for creating a new Vault secret.
///
/// Validates path format (must start with `/`), required fields (name, value),
/// and numeric ranges (maxVersions 1–1000). Supports optional metadata
/// key-value pairs, expiration date, and reference ARN (shown only for
/// REFERENCE type secrets).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/vault_enums.dart';
import '../../providers/vault_providers.dart';
import '../../theme/colors.dart';

/// A modal dialog for creating a new secret in CodeOps-Vault.
class CreateSecretDialog extends ConsumerStatefulWidget {
  /// Creates a [CreateSecretDialog].
  const CreateSecretDialog({super.key});

  @override
  ConsumerState<CreateSecretDialog> createState() => _CreateSecretDialogState();
}

class _CreateSecretDialogState extends ConsumerState<CreateSecretDialog> {
  final _formKey = GlobalKey<FormState>();
  final _pathController = TextEditingController();
  final _nameController = TextEditingController();
  final _valueController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _referenceArnController = TextEditingController();
  final _maxVersionsController = TextEditingController();
  final _retentionDaysController = TextEditingController();

  SecretType _secretType = SecretType.static_;
  DateTime? _expiresAt;
  bool _obscureValue = true;
  bool _submitting = false;
  final List<_MetadataEntry> _metadata = [];

  @override
  void dispose() {
    _pathController.dispose();
    _nameController.dispose();
    _valueController.dispose();
    _descriptionController.dispose();
    _referenceArnController.dispose();
    _maxVersionsController.dispose();
    _retentionDaysController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: CodeOpsColors.surface,
      title: const Text('Create Secret'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Path
                TextFormField(
                  controller: _pathController,
                  decoration: const InputDecoration(
                    labelText: 'Path *',
                    hintText: '/services/my-app/db-password',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Path is required';
                    if (!v.startsWith('/')) return 'Path must start with /';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                // Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name *',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  maxLength: 200,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Name is required';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                // Value
                TextFormField(
                  controller: _valueController,
                  obscureText: _obscureValue,
                  maxLines: _obscureValue ? 1 : 3,
                  decoration: InputDecoration(
                    labelText: 'Value *',
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
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Value is required';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                // Type
                DropdownButtonFormField<SecretType>(
                  initialValue: _secretType,
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: SecretType.values
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(t.displayName),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _secretType = v);
                  },
                  dropdownColor: CodeOpsColors.surface,
                ),
                const SizedBox(height: 12),
                // Reference ARN (only for Reference type)
                if (_secretType == SecretType.reference) ...[
                  TextFormField(
                    controller: _referenceArnController,
                    decoration: const InputDecoration(
                      labelText: 'Reference ARN',
                      hintText: 'arn:aws:secretsmanager:...',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
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
                // Max Versions + Retention Days row
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
                const SizedBox(height: 12),
                // Metadata
                _buildMetadataSection(),
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

  Widget _buildMetadataSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Metadata',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: CodeOpsColors.textPrimary,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 14),
              label: const Text('Add', style: TextStyle(fontSize: 12)),
              onPressed: () => setState(
                  () => _metadata.add(_MetadataEntry('', ''))),
            ),
          ],
        ),
        ..._metadata.asMap().entries.map((entry) {
          final i = entry.key;
          final m = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: TextEditingController(text: m.key)
                      ..selection = TextSelection.collapsed(offset: m.key.length),
                    onChanged: (v) => _metadata[i] = _MetadataEntry(v, m.value),
                    decoration: const InputDecoration(
                      hintText: 'Key',
                      isDense: true,
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: TextField(
                    controller: TextEditingController(text: m.value)
                      ..selection =
                          TextSelection.collapsed(offset: m.value.length),
                    onChanged: (v) => _metadata[i] = _MetadataEntry(m.key, v),
                    decoration: const InputDecoration(
                      hintText: 'Value',
                      isDense: true,
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 14),
                  onPressed: () => setState(() => _metadata.removeAt(i)),
                ),
              ],
            ),
          );
        }),
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

    final metadataMap = <String, String>{};
    for (final m in _metadata) {
      if (m.key.isNotEmpty && m.value.isNotEmpty) {
        metadataMap[m.key] = m.value;
      }
    }

    try {
      final api = ref.read(vaultApiProvider);
      await api.createSecret(
        path: _pathController.text.trim(),
        name: _nameController.text.trim(),
        value: _valueController.text,
        secretType: _secretType,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text.trim(),
        referenceArn: _referenceArnController.text.isEmpty
            ? null
            : _referenceArnController.text.trim(),
        maxVersions: _maxVersionsController.text.isEmpty
            ? null
            : int.parse(_maxVersionsController.text),
        retentionDays: _retentionDaysController.text.isEmpty
            ? null
            : int.parse(_retentionDaysController.text),
        expiresAt: _expiresAt,
        metadata: metadataMap.isEmpty ? null : metadataMap,
      );
      ref.invalidate(vaultSecretsProvider);
      ref.invalidate(vaultSecretStatsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Secret created')),
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

class _MetadataEntry {
  final String key;
  final String value;

  _MetadataEntry(this.key, this.value);
}
