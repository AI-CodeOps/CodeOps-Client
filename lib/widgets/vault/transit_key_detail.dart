/// Detail panel for a Vault transit encryption key.
///
/// Displays key metadata (name, algorithm, version, min decryption version,
/// deletable/exportable flags, active status, timestamps) and action buttons
/// for rotate, update, and delete operations.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/vault_models.dart';
import '../../providers/vault_providers.dart';
import '../../theme/colors.dart';
import '../../utils/date_utils.dart';
import '../shared/confirm_dialog.dart';

/// Displays full detail for a [TransitKeyResponse] with action buttons.
class TransitKeyDetail extends ConsumerWidget {
  /// The transit key to display.
  final TransitKeyResponse transitKey;

  /// Called when the panel should close.
  final VoidCallback? onClose;

  /// Called after a mutation so the parent can refresh.
  final VoidCallback? onMutated;

  /// Creates a [TransitKeyDetail].
  const TransitKeyDetail({
    super.key,
    required this.transitKey,
    this.onClose,
    this.onMutated,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: 420,
      decoration: const BoxDecoration(
        color: CodeOpsColors.surface,
        border: Border(left: BorderSide(color: CodeOpsColors.border)),
      ),
      child: Column(
        children: [
          _buildHeader(context, ref),
          const Divider(height: 1, color: CodeOpsColors.border),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildInfoSection(),
                const SizedBox(height: 16),
                _buildFlagsSection(),
                const SizedBox(height: 16),
                _buildTimestamps(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  transitKey.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: CodeOpsColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onClose != null)
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onClose,
                  tooltip: 'Close',
                ),
            ],
          ),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: CodeOpsColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  transitKey.algorithm,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: CodeOpsColors.primary,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'v${transitKey.currentVersion}',
                style: const TextStyle(
                  fontSize: 12,
                  color: CodeOpsColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _ActionButton(
                label: 'Rotate',
                icon: Icons.refresh,
                onPressed: () => _rotateKey(context, ref),
              ),
              _ActionButton(
                label: transitKey.isActive ? 'Deactivate' : 'Activate',
                icon: transitKey.isActive
                    ? Icons.pause_circle_outline
                    : Icons.play_circle_outline,
                color: transitKey.isActive
                    ? CodeOpsColors.warning
                    : CodeOpsColors.success,
                onPressed: () => _toggleActive(context, ref),
              ),
              if (transitKey.isDeletable)
                _ActionButton(
                  label: 'Delete',
                  icon: Icons.delete_outline,
                  color: CodeOpsColors.error,
                  onPressed: () => _deleteKey(context, ref),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _field('Name', transitKey.name),
        _field('Algorithm', transitKey.algorithm),
        _field('Current Version', 'v${transitKey.currentVersion}'),
        _field(
          'Min Decrypt Version',
          'v${transitKey.minDecryptionVersion}',
        ),
        if (transitKey.description != null)
          _field('Description', transitKey.description!),
        _field('Active', transitKey.isActive ? 'Yes' : 'No'),
      ],
    );
  }

  Widget _buildFlagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Capabilities',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: CodeOpsColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            _flagBadge('Deletable', transitKey.isDeletable),
            const SizedBox(width: 8),
            _flagBadge('Exportable', transitKey.isExportable),
          ],
        ),
      ],
    );
  }

  Widget _buildTimestamps() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 24, color: CodeOpsColors.border),
        if (transitKey.createdByUserId != null)
          _field(
            'Created By',
            transitKey.createdByUserId!.substring(0, 8),
          ),
        _field('Created', formatDateTime(transitKey.createdAt)),
        _field('Updated', formatDateTime(transitKey.updatedAt)),
      ],
    );
  }

  Widget _field(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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

  Widget _flagBadge(String label, bool enabled) {
    final color = enabled ? CodeOpsColors.success : CodeOpsColors.textTertiary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            enabled ? Icons.check_circle : Icons.cancel,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  Future<void> _rotateKey(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Rotate Key',
      message:
          'Add a new version to "${transitKey.name}"? '
          'Current version: v${transitKey.currentVersion}.',
      confirmLabel: 'Rotate',
    );
    if (confirmed != true || !context.mounted) return;

    try {
      final api = ref.read(vaultApiProvider);
      await api.rotateTransitKey(transitKey.id);
      ref.invalidate(vaultTransitKeysProvider);
      ref.invalidate(vaultTransitKeyDetailProvider(transitKey.id));
      onMutated?.call();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Key rotated')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to rotate: $e')),
        );
      }
    }
  }

  Future<void> _toggleActive(BuildContext context, WidgetRef ref) async {
    try {
      final api = ref.read(vaultApiProvider);
      await api.updateTransitKey(
        transitKey.id,
        isActive: !transitKey.isActive,
      );
      ref.invalidate(vaultTransitKeysProvider);
      ref.invalidate(vaultTransitKeyDetailProvider(transitKey.id));
      onMutated?.call();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              transitKey.isActive ? 'Key deactivated' : 'Key activated',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e')),
        );
      }
    }
  }

  Future<void> _deleteKey(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete Key',
      message:
          'Permanently delete "${transitKey.name}"? '
          'Existing ciphertext encrypted with this key will become unrecoverable.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (confirmed != true || !context.mounted) return;

    try {
      final api = ref.read(vaultApiProvider);
      await api.deleteTransitKey(transitKey.id);
      ref.invalidate(vaultTransitKeysProvider);
      ref.invalidate(vaultTransitStatsProvider);
      onMutated?.call();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Key deleted')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Action Button
// ---------------------------------------------------------------------------

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? CodeOpsColors.primary;
    return OutlinedButton.icon(
      icon: Icon(icon, size: 14),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: c,
        side: BorderSide(color: c),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        textStyle: const TextStyle(fontSize: 11),
      ),
      onPressed: onPressed,
    );
  }
}
