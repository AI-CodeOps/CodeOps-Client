/// Dialog for creating or editing a rotation policy.
///
/// Renders strategy-specific fields depending on the selected
/// [RotationStrategy]: random length/charset for RANDOM_GENERATE,
/// external API URL for EXTERNAL_API, or script command for
/// CUSTOM_SCRIPT. Validates required fields before submission.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/vault_enums.dart';
import '../../models/vault_models.dart';
import '../../providers/vault_providers.dart';
import '../../theme/colors.dart';

/// A dialog for creating or editing a rotation policy for a secret.
class VaultRotationPolicyDialog extends ConsumerStatefulWidget {
  /// The secret ID to create/edit a policy for.
  final String secretId;

  /// The secret path (for display).
  final String secretPath;

  /// Existing policy to edit (null for create mode).
  final RotationPolicyResponse? existingPolicy;

  /// Creates a [VaultRotationPolicyDialog].
  const VaultRotationPolicyDialog({
    super.key,
    required this.secretId,
    required this.secretPath,
    this.existingPolicy,
  });

  @override
  ConsumerState<VaultRotationPolicyDialog> createState() =>
      _VaultRotationPolicyDialogState();
}

class _VaultRotationPolicyDialogState
    extends ConsumerState<VaultRotationPolicyDialog> {
  final _formKey = GlobalKey<FormState>();
  late RotationStrategy _strategy;
  late TextEditingController _intervalCtrl;
  late TextEditingController _randomLengthCtrl;
  late TextEditingController _randomCharsetCtrl;
  late TextEditingController _externalApiUrlCtrl;
  late TextEditingController _maxFailuresCtrl;
  bool _isSubmitting = false;

  bool get _isEdit => widget.existingPolicy != null;

  @override
  void initState() {
    super.initState();
    final p = widget.existingPolicy;
    _strategy = p?.strategy ?? RotationStrategy.randomGenerate;
    _intervalCtrl =
        TextEditingController(text: '${p?.rotationIntervalHours ?? 24}');
    _randomLengthCtrl =
        TextEditingController(text: '${p?.randomLength ?? 32}');
    _randomCharsetCtrl = TextEditingController(
      text: p?.randomCharset ?? 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789',
    );
    _externalApiUrlCtrl =
        TextEditingController(text: p?.externalApiUrl ?? '');
    _maxFailuresCtrl =
        TextEditingController(text: '${p?.maxFailures ?? 3}');
  }

  @override
  void dispose() {
    _intervalCtrl.dispose();
    _randomLengthCtrl.dispose();
    _randomCharsetCtrl.dispose();
    _externalApiUrlCtrl.dispose();
    _maxFailuresCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: CodeOpsColors.surface,
      title: Text(_isEdit ? 'Edit Rotation Policy' : 'Create Rotation Policy'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Secret path (read-only)
                Text(
                  'Secret: ${widget.secretPath}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: CodeOpsColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),

                // Strategy dropdown
                DropdownButtonFormField<RotationStrategy>(
                  initialValue: _strategy,
                  decoration: const InputDecoration(
                    labelText: 'Strategy *',
                    border: OutlineInputBorder(),
                  ),
                  items: RotationStrategy.values
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(s.displayName),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _strategy = v);
                  },
                ),
                const SizedBox(height: 12),

                // Rotation interval
                TextFormField(
                  controller: _intervalCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Interval (hours) *',
                    border: OutlineInputBorder(),
                    hintText: '24',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    final n = int.tryParse(v);
                    if (n == null || n < 1) return 'Must be at least 1';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Strategy-specific fields
                ..._buildStrategyFields(),

                const SizedBox(height: 12),

                // Max failures
                TextFormField(
                  controller: _maxFailuresCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Max Failures',
                    border: OutlineInputBorder(),
                    hintText: '3',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _onSubmit,
          child: _isSubmitting
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

  List<Widget> _buildStrategyFields() {
    switch (_strategy) {
      case RotationStrategy.randomGenerate:
        return [
          TextFormField(
            controller: _randomLengthCtrl,
            decoration: const InputDecoration(
              labelText: 'Random Length',
              border: OutlineInputBorder(),
              hintText: '32',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _randomCharsetCtrl,
            decoration: const InputDecoration(
              labelText: 'Character Set',
              border: OutlineInputBorder(),
            ),
          ),
        ];
      case RotationStrategy.externalApi:
        return [
          TextFormField(
            controller: _externalApiUrlCtrl,
            decoration: const InputDecoration(
              labelText: 'External API URL *',
              border: OutlineInputBorder(),
              hintText: 'https://api.example.com/rotate',
            ),
            validator: (v) {
              if (_strategy == RotationStrategy.externalApi &&
                  (v == null || v.isEmpty)) {
                return 'Required for External API strategy';
              }
              return null;
            },
          ),
        ];
      case RotationStrategy.customScript:
        return [
          const Text(
            'Custom scripts are configured server-side.',
            style: TextStyle(
              fontSize: 12,
              color: CodeOpsColors.textTertiary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ];
    }
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final api = ref.read(vaultApiProvider);
      final interval = int.parse(_intervalCtrl.text);
      final maxFailures = _maxFailuresCtrl.text.isNotEmpty
          ? int.tryParse(_maxFailuresCtrl.text)
          : null;

      if (_isEdit) {
        await api.updateRotationPolicy(
          widget.existingPolicy!.id,
          strategy: _strategy,
          rotationIntervalHours: interval,
          randomLength: _strategy == RotationStrategy.randomGenerate
              ? int.tryParse(_randomLengthCtrl.text)
              : null,
          randomCharset: _strategy == RotationStrategy.randomGenerate
              ? _randomCharsetCtrl.text
              : null,
          externalApiUrl: _strategy == RotationStrategy.externalApi
              ? _externalApiUrlCtrl.text
              : null,
          maxFailures: maxFailures,
        );
      } else {
        await api.createOrUpdateRotationPolicy(
          secretId: widget.secretId,
          strategy: _strategy,
          rotationIntervalHours: interval,
          randomLength: _strategy == RotationStrategy.randomGenerate
              ? int.tryParse(_randomLengthCtrl.text)
              : null,
          randomCharset: _strategy == RotationStrategy.randomGenerate
              ? _randomCharsetCtrl.text
              : null,
          externalApiUrl: _strategy == RotationStrategy.externalApi
              ? _externalApiUrlCtrl.text
              : null,
          maxFailures: maxFailures,
        );
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
