/// Settings tab for the Vault secret detail page (CVF-003).
///
/// Form to edit secret settings: description, max versions, retention days,
/// expiry date, and active status. Saves changes via [VaultApi.updateSecret].
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/vault_models.dart';
import '../../providers/vault_providers.dart';
import '../../theme/colors.dart';

/// The Settings tab of the secret detail page.
///
/// Provides a form to edit the secret's description, max versions,
/// retention days, expiry date, and active status.
class VaultSecretSettingsTab extends ConsumerStatefulWidget {
  /// The secret whose settings to edit.
  final SecretResponse secret;

  /// Called after a mutation so the parent can refresh.
  final VoidCallback? onMutated;

  /// Creates a [VaultSecretSettingsTab].
  const VaultSecretSettingsTab({
    super.key,
    required this.secret,
    this.onMutated,
  });

  @override
  ConsumerState<VaultSecretSettingsTab> createState() =>
      _VaultSecretSettingsTabState();
}

class _VaultSecretSettingsTabState
    extends ConsumerState<VaultSecretSettingsTab> {
  late TextEditingController _descController;
  late TextEditingController _maxVersionsController;
  late TextEditingController _retentionController;
  DateTime? _expiresAt;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.secret;
    _descController = TextEditingController(text: s.description ?? '');
    _maxVersionsController =
        TextEditingController(text: s.maxVersions?.toString() ?? '');
    _retentionController =
        TextEditingController(text: s.retentionDays?.toString() ?? '');
    _expiresAt = s.expiresAt;
  }

  @override
  void didUpdateWidget(covariant VaultSecretSettingsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.secret.id != oldWidget.secret.id) {
      final s = widget.secret;
      _descController.text = s.description ?? '';
      _maxVersionsController.text = s.maxVersions?.toString() ?? '';
      _retentionController.text = s.retentionDays?.toString() ?? '';
      _expiresAt = s.expiresAt;
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    _maxVersionsController.dispose();
    _retentionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Info row.
        _readOnlyField('Name', widget.secret.name),
        _readOnlyField('Path', widget.secret.path),
        _readOnlyField('Type', widget.secret.secretType.displayName),
        const SizedBox(height: 16),
        const Divider(height: 1, color: CodeOpsColors.border),
        const SizedBox(height: 16),
        // Editable fields.
        _buildTextField(
          label: 'Description',
          controller: _descController,
          hintText: 'Enter description',
          maxLines: 3,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                label: 'Max Versions',
                controller: _maxVersionsController,
                hintText: 'Unlimited',
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                label: 'Retention (days)',
                controller: _retentionController,
                hintText: 'Forever',
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Expiry date picker.
        _buildExpiryPicker(),
        const SizedBox(height: 24),
        // Save button.
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            icon: _saving
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save, size: 16),
            label: const Text('Save Settings'),
            style: ElevatedButton.styleFrom(
              backgroundColor: CodeOpsColors.primary,
            ),
            onPressed: _saving ? null : _saveSettings,
          ),
        ),
      ],
    );
  }

  Widget _readOnlyField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: CodeOpsColors.textTertiary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: CodeOpsColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hintText,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: CodeOpsColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hintText,
            isDense: true,
            border: const OutlineInputBorder(),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
          style: const TextStyle(fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildExpiryPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Expiry Date',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: CodeOpsColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: CodeOpsColors.border),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _expiresAt != null
                      ? '${_expiresAt!.year}-${_expiresAt!.month.toString().padLeft(2, '0')}-${_expiresAt!.day.toString().padLeft(2, '0')}'
                      : 'No expiry set',
                  style: TextStyle(
                    fontSize: 13,
                    color: _expiresAt != null
                        ? CodeOpsColors.textPrimary
                        : CodeOpsColors.textTertiary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              icon: const Icon(Icons.calendar_today, size: 16),
              tooltip: 'Pick date',
              onPressed: _pickExpiryDate,
            ),
            if (_expiresAt != null)
              IconButton(
                icon: const Icon(Icons.close, size: 16),
                tooltip: 'Clear expiry',
                onPressed: () => setState(() => _expiresAt = null),
              ),
          ],
        ),
      ],
    );
  }

  // ─── Actions ───────────────────────────────────────────────────────────

  Future<void> _pickExpiryDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiresAt ?? now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 3650)),
    );
    if (picked != null) {
      setState(() => _expiresAt = picked);
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _saving = true);

    try {
      final api = ref.read(vaultApiProvider);
      final desc = _descController.text.trim();
      final maxV = int.tryParse(_maxVersionsController.text.trim());
      final retDays = int.tryParse(_retentionController.text.trim());

      await api.updateSecret(
        widget.secret.id,
        description: desc.isEmpty ? null : desc,
        maxVersions: maxV,
        retentionDays: retDays,
        expiresAt: _expiresAt,
      );

      ref.invalidate(vaultSecretDetailProvider(widget.secret.id));
      ref.invalidate(vaultSecretsProvider);
      widget.onMutated?.call();

      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    }
  }
}
