/// Metadata tab for the Vault secret detail page (CVF-003).
///
/// Lists existing key-value metadata pairs with add, inline edit,
/// delete, and replace-all capabilities. Uses [vaultSecretMetadataProvider]
/// for data and [VaultApi.setMetadata] / [VaultApi.removeMetadata] for
/// mutations.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/vault_providers.dart';
import '../../theme/colors.dart';
import '../shared/confirm_dialog.dart';
import '../shared/error_panel.dart';

/// The Metadata tab of the secret detail page.
///
/// Displays a key-value table of metadata entries with add, inline edit,
/// delete, and replace-all operations.
class VaultSecretMetadataTab extends ConsumerStatefulWidget {
  /// The secret ID to manage metadata for.
  final String secretId;

  /// Called after a mutation so the parent can refresh.
  final VoidCallback? onMutated;

  /// Creates a [VaultSecretMetadataTab].
  const VaultSecretMetadataTab({
    super.key,
    required this.secretId,
    this.onMutated,
  });

  @override
  ConsumerState<VaultSecretMetadataTab> createState() =>
      _VaultSecretMetadataTabState();
}

class _VaultSecretMetadataTabState
    extends ConsumerState<VaultSecretMetadataTab> {
  final _keyController = TextEditingController();
  final _valueController = TextEditingController();

  /// Key currently being edited inline (null = not editing).
  String? _editingKey;
  final _editValueController = TextEditingController();

  @override
  void dispose() {
    _keyController.dispose();
    _valueController.dispose();
    _editValueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final metadataAsync =
        ref.watch(vaultSecretMetadataProvider(widget.secretId));

    return metadataAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      error: (error, _) => ErrorPanel.fromException(
        error,
        onRetry: () =>
            ref.invalidate(vaultSecretMetadataProvider(widget.secretId)),
      ),
      data: (metadata) => _buildContent(metadata),
    );
  }

  Widget _buildContent(Map<String, String> metadata) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Add new entry row.
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _keyController,
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
                controller: _valueController,
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
            const SizedBox(width: 6),
            IconButton(
              icon: const Icon(Icons.add, size: 18),
              tooltip: 'Add metadata',
              onPressed: _addEntry,
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Replace all button.
        if (metadata.isNotEmpty)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              icon: const Icon(Icons.delete_sweep, size: 14),
              label: const Text('Remove All'),
              style: TextButton.styleFrom(
                foregroundColor: CodeOpsColors.error,
                textStyle: const TextStyle(fontSize: 11),
              ),
              onPressed: () => _removeAll(metadata),
            ),
          ),
        const Divider(height: 1, color: CodeOpsColors.border),
        // Metadata entries.
        if (metadata.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: Text(
                'No metadata entries',
                style: TextStyle(
                  fontSize: 13,
                  color: CodeOpsColors.textTertiary,
                ),
              ),
            ),
          )
        else
          ...metadata.entries.map((entry) {
            if (_editingKey == entry.key) {
              return _buildEditRow(entry.key);
            }
            return _MetadataRow(
              metaKey: entry.key,
              metaValue: entry.value,
              onEdit: () => _startEdit(entry.key, entry.value),
              onDelete: () => _removeEntry(entry.key),
            );
          }),
      ],
    );
  }

  Widget _buildEditRow(String key) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              key,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: CodeOpsColors.secondary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: TextField(
              controller: _editValueController,
              autofocus: true,
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              ),
              style: const TextStyle(fontSize: 12),
              onSubmitted: (_) => _saveEdit(key),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.check, size: 14),
            tooltip: 'Save',
            onPressed: () => _saveEdit(key),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 14),
            tooltip: 'Cancel',
            onPressed: _cancelEdit,
          ),
        ],
      ),
    );
  }

  // ─── Actions ───────────────────────────────────────────────────────────

  Future<void> _addEntry() async {
    final key = _keyController.text.trim();
    final value = _valueController.text.trim();
    if (key.isEmpty || value.isEmpty) return;

    try {
      final api = ref.read(vaultApiProvider);
      await api.setMetadata(widget.secretId, key, value);
      ref.invalidate(vaultSecretMetadataProvider(widget.secretId));
      _keyController.clear();
      _valueController.clear();
      widget.onMutated?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add: $e')),
        );
      }
    }
  }

  Future<void> _removeEntry(String key) async {
    try {
      final api = ref.read(vaultApiProvider);
      await api.removeMetadata(widget.secretId, key);
      ref.invalidate(vaultSecretMetadataProvider(widget.secretId));
      widget.onMutated?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove: $e')),
        );
      }
    }
  }

  Future<void> _removeAll(Map<String, String> metadata) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Remove All Metadata',
      message:
          'Are you sure you want to remove all ${metadata.length} metadata entries?',
      confirmLabel: 'Remove All',
      destructive: true,
    );
    if (confirmed != true || !context.mounted) return;

    try {
      final api = ref.read(vaultApiProvider);
      for (final key in metadata.keys) {
        await api.removeMetadata(widget.secretId, key);
      }
      ref.invalidate(vaultSecretMetadataProvider(widget.secretId));
      widget.onMutated?.call();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All metadata removed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove all: $e')),
        );
      }
    }
  }

  void _startEdit(String key, String value) {
    setState(() {
      _editingKey = key;
      _editValueController.text = value;
    });
  }

  void _cancelEdit() {
    setState(() => _editingKey = null);
  }

  Future<void> _saveEdit(String key) async {
    final value = _editValueController.text.trim();
    if (value.isEmpty) return;

    try {
      final api = ref.read(vaultApiProvider);
      await api.setMetadata(widget.secretId, key, value);
      ref.invalidate(vaultSecretMetadataProvider(widget.secretId));
      setState(() => _editingKey = null);
      widget.onMutated?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e')),
        );
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Metadata Row
// ---------------------------------------------------------------------------

class _MetadataRow extends StatelessWidget {
  final String metaKey;
  final String metaValue;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MetadataRow({
    required this.metaKey,
    required this.metaValue,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              metaKey,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: CodeOpsColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              metaValue,
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: CodeOpsColors.textSecondary,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, size: 14),
            tooltip: 'Edit',
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 14),
            tooltip: 'Remove',
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
