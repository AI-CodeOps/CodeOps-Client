/// Vault Transit Encryption page with left/right layout.
///
/// **Left panel**: Filterable, paginated transit key list with
/// create, rotate, edit, and delete actions.
///
/// **Right panel**: Operations panel contextual to the selected key,
/// with four tabs: Encrypt, Decrypt, Rewrap, and Data Key. Includes
/// a summary stats bar and key action buttons.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/vault_models.dart';
import '../providers/vault_providers.dart';
import '../theme/colors.dart';
import '../widgets/shared/confirm_dialog.dart';
import '../widgets/vault/vault_transit_data_key.dart';
import '../widgets/vault/vault_transit_decrypt.dart';
import '../widgets/vault/vault_transit_encrypt.dart';
import '../widgets/vault/vault_transit_key_dialog.dart';
import '../widgets/vault/vault_transit_key_list.dart';
import '../widgets/vault/vault_transit_rewrap.dart';
import '../widgets/vault/vault_transit_stats.dart';

/// The Vault Transit page with key list (left) and operations panel (right).
class VaultTransitPage extends ConsumerWidget {
  /// Creates a [VaultTransitPage].
  const VaultTransitPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        _buildHeader(ref),
        const Expanded(
          child: Row(
            children: [
              // Left: Key list
              SizedBox(
                width: 340,
                child: VaultTransitKeyList(),
              ),
              VerticalDivider(width: 1, color: CodeOpsColors.border),
              // Right: Operations panel
              Expanded(child: _OperationsPanel()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: CodeOpsColors.divider)),
      ),
      child: const Row(
        children: [
          Text(
            'Transit',
            style: TextStyle(
              color: CodeOpsColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(width: 24),
          VaultTransitStats(),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Operations Panel
// ---------------------------------------------------------------------------

class _OperationsPanel extends ConsumerWidget {
  const _OperationsPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedId = ref.watch(selectedVaultTransitKeyIdProvider);
    final keysAsync = ref.watch(vaultTransitKeysProvider);

    if (selectedId == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.vpn_key_outlined,
              size: 48,
              color: CodeOpsColors.textTertiary,
            ),
            SizedBox(height: 12),
            Text(
              'Select a key to begin',
              style: TextStyle(
                fontSize: 14,
                color: CodeOpsColors.textTertiary,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Choose a transit key from the list to encrypt, decrypt, '
              'rewrap data, or generate data keys.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: CodeOpsColors.textTertiary,
              ),
            ),
          ],
        ),
      );
    }

    // Resolve the selected key from the cached list
    return keysAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (_, __) => const Center(
        child: Text(
          'Error loading keys',
          style: TextStyle(color: CodeOpsColors.error),
        ),
      ),
      data: (page) {
        TransitKeyResponse? selected;
        for (final k in page.content) {
          if (k.id == selectedId) {
            selected = k;
            break;
          }
        }
        if (selected == null) {
          return const Center(
            child: Text(
              'Selected key not found',
              style: TextStyle(color: CodeOpsColors.textTertiary),
            ),
          );
        }
        return _KeyOperations(transitKey: selected);
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Key Operations (selected key context)
// ---------------------------------------------------------------------------

class _KeyOperations extends ConsumerStatefulWidget {
  final TransitKeyResponse transitKey;

  const _KeyOperations({required this.transitKey});

  @override
  ConsumerState<_KeyOperations> createState() => _KeyOperationsState();
}

class _KeyOperationsState extends ConsumerState<_KeyOperations>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final key = widget.transitKey;

    return Column(
      children: [
        // Key info + actions bar
        _buildKeyBar(context, key),
        const Divider(height: 1, color: CodeOpsColors.border),
        // Operation tabs
        TabBar(
          controller: _tabController,
          labelColor: CodeOpsColors.primary,
          unselectedLabelColor: CodeOpsColors.textTertiary,
          indicatorColor: CodeOpsColors.primary,
          labelStyle:
              const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Encrypt'),
            Tab(text: 'Decrypt'),
            Tab(text: 'Rewrap'),
            Tab(text: 'Data Key'),
          ],
        ),
        const Divider(height: 1, color: CodeOpsColors.border),
        // Tab views
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              VaultTransitEncrypt(keyName: key.name),
              VaultTransitDecrypt(keyName: key.name),
              VaultTransitRewrap(keyName: key.name),
              VaultTransitDataKey(keyName: key.name),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKeyBar(BuildContext context, TransitKeyResponse key) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.vpn_key_outlined,
                size: 18,
                color: key.isActive
                    ? CodeOpsColors.primary
                    : CodeOpsColors.textTertiary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      key.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: CodeOpsColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${key.algorithm}  ·  v${key.currentVersion}'
                      '  ·  min decrypt: v${key.minDecryptionVersion}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        color: CodeOpsColors.textTertiary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Action buttons
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              _SmallButton(
                label: 'Rotate',
                icon: Icons.refresh,
                onPressed: () => _rotateKey(context, key),
              ),
              _SmallButton(
                label: 'Edit',
                icon: Icons.edit_outlined,
                onPressed: () => _editKey(context, key),
              ),
              if (key.isDeletable)
                _SmallButton(
                  label: 'Delete',
                  icon: Icons.delete_outline,
                  color: CodeOpsColors.error,
                  onPressed: () => _deleteKey(context, key),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _rotateKey(
    BuildContext context,
    TransitKeyResponse key,
  ) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Rotate Key',
      message:
          'Add a new version to "${key.name}"? '
          'Current version: v${key.currentVersion}.',
      confirmLabel: 'Rotate',
    );
    if (confirmed != true || !context.mounted) return;

    try {
      final api = ref.read(vaultApiProvider);
      await api.rotateTransitKey(key.id);
      ref.invalidate(vaultTransitKeysProvider);
      ref.invalidate(vaultTransitStatsProvider);
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

  Future<void> _editKey(
    BuildContext context,
    TransitKeyResponse key,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => VaultTransitKeyDialog(existingKey: key),
    );
    if (result == true) {
      ref.invalidate(vaultTransitKeysProvider);
      ref.invalidate(vaultTransitStatsProvider);
    }
  }

  Future<void> _deleteKey(
    BuildContext context,
    TransitKeyResponse key,
  ) async {
    final confirmed = await showTransitKeyDeleteDialog(context, key);
    if (confirmed != true || !context.mounted) return;

    try {
      final api = ref.read(vaultApiProvider);
      await api.deleteTransitKey(key.id);
      ref.read(selectedVaultTransitKeyIdProvider.notifier).state = null;
      ref.invalidate(vaultTransitKeysProvider);
      ref.invalidate(vaultTransitStatsProvider);
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
// Small Action Button
// ---------------------------------------------------------------------------

class _SmallButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? color;
  final VoidCallback onPressed;

  const _SmallButton({
    required this.label,
    required this.icon,
    this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? CodeOpsColors.primary;
    return OutlinedButton.icon(
      icon: Icon(icon, size: 13),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: c,
        side: BorderSide(color: c.withValues(alpha: 0.5)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        textStyle: const TextStyle(fontSize: 11),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: onPressed,
    );
  }
}
