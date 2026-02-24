/// Full detail/editor page for a single Vault secret (CVF-003).
///
/// Four tabs: **Value** (reveal + ScribeEditor + JSON detection + KV toggle +
/// edit mode), **Versions** (history + ScribeDiffEditor compare + restore +
/// destroy), **Metadata** (CRUD + replace all), **Settings** (name,
/// description, max versions, retention, expiry, active).
///
/// Header shows secret name, path, type badge, status badge, and an
/// actions dropdown (Edit Secret, Deactivate, Delete, Copy Path,
/// Copy Secret Value).
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/vault_models.dart';
import '../providers/vault_providers.dart';
import '../theme/colors.dart';
import '../utils/date_utils.dart';
import '../widgets/shared/confirm_dialog.dart';
import '../widgets/shared/error_panel.dart';
import '../widgets/vault/update_secret_dialog.dart';
import '../widgets/vault/vault_secret_metadata_tab.dart';
import '../widgets/vault/vault_secret_settings_tab.dart';
import '../widgets/vault/vault_secret_value_tab.dart';
import '../widgets/vault/vault_secret_versions_tab.dart';
import '../widgets/vault/vault_secret_status_badge.dart';
import '../widgets/vault/vault_secret_type_badge.dart';

/// The Vault secret detail/editor page.
///
/// Loaded at `/vault/secrets/:id` and displays full secret information
/// with editable tabs for value, versions, metadata, and settings.
class VaultSecretDetailPage extends ConsumerStatefulWidget {
  /// The secret ID from the route parameter.
  final String secretId;

  /// Creates a [VaultSecretDetailPage].
  const VaultSecretDetailPage({super.key, required this.secretId});

  @override
  ConsumerState<VaultSecretDetailPage> createState() =>
      _VaultSecretDetailPageState();
}

class _VaultSecretDetailPageState extends ConsumerState<VaultSecretDetailPage>
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

  void _invalidateDetail() {
    ref.invalidate(vaultSecretDetailProvider(widget.secretId));
    ref.invalidate(vaultSecretsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(vaultSecretDetailProvider(widget.secretId));

    return detailAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (error, _) => ErrorPanel.fromException(
        error,
        onRetry: () =>
            ref.invalidate(vaultSecretDetailProvider(widget.secretId)),
      ),
      data: (secret) => _buildContent(secret),
    );
  }

  Widget _buildContent(SecretResponse secret) {
    return Column(
      children: [
        // Header.
        _SecretDetailHeader(
          secret: secret,
          onMutated: _invalidateDetail,
        ),
        // Tab bar.
        Container(
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: CodeOpsColors.border),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: CodeOpsColors.primary,
            unselectedLabelColor: CodeOpsColors.textTertiary,
            indicatorColor: CodeOpsColors.primary,
            labelStyle:
                const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            tabs: const [
              Tab(text: 'Value'),
              Tab(text: 'Versions'),
              Tab(text: 'Metadata'),
              Tab(text: 'Settings'),
            ],
          ),
        ),
        // Tab content.
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              VaultSecretValueTab(secretId: secret.id),
              VaultSecretVersionsTab(secretId: secret.id),
              VaultSecretMetadataTab(
                secretId: secret.id,
                onMutated: _invalidateDetail,
              ),
              VaultSecretSettingsTab(
                secret: secret,
                onMutated: _invalidateDetail,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

/// Header bar showing secret name, path, badges, and actions dropdown.
class _SecretDetailHeader extends ConsumerWidget {
  final SecretResponse secret;
  final VoidCallback? onMutated;

  const _SecretDetailHeader({
    required this.secret,
    this.onMutated,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: CodeOpsColors.surface,
        border: Border(bottom: BorderSide(color: CodeOpsColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back + title row.
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, size: 18),
                tooltip: 'Back to secrets',
                onPressed: () => context.go('/vault/secrets'),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  secret.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: CodeOpsColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              VaultSecretTypeBadge(type: secret.secretType),
              const SizedBox(width: 6),
              VaultSecretStatusBadge(
                isActive: secret.isActive,
                expiresAt: secret.expiresAt,
              ),
              const SizedBox(width: 12),
              // Actions dropdown.
              _ActionsDropdown(secret: secret, onMutated: onMutated),
            ],
          ),
          const SizedBox(height: 4),
          // Path + version + dates.
          Padding(
            padding: const EdgeInsets.only(left: 40),
            child: Wrap(
              spacing: 16,
              children: [
                Text(
                  secret.path,
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: CodeOpsColors.textTertiary,
                  ),
                ),
                Text(
                  'v${secret.currentVersion}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: CodeOpsColors.primary,
                  ),
                ),
                if (secret.createdAt != null)
                  Text(
                    'Created ${formatDateTime(secret.createdAt)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: CodeOpsColors.textTertiary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Actions Dropdown
// ---------------------------------------------------------------------------

class _ActionsDropdown extends ConsumerWidget {
  final SecretResponse secret;
  final VoidCallback? onMutated;

  const _ActionsDropdown({required this.secret, this.onMutated});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 20),
      tooltip: 'Actions',
      onSelected: (action) => _handleAction(context, ref, action),
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'edit',
          child: _MenuRow(icon: Icons.edit_outlined, label: 'Edit Secret'),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'deactivate',
          child: _MenuRow(
            icon: Icons.pause_circle_outline,
            label: secret.isActive ? 'Deactivate' : 'Already Inactive',
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: _MenuRow(
            icon: Icons.delete_forever,
            label: 'Delete',
            color: CodeOpsColors.error,
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'copy_path',
          child: _MenuRow(icon: Icons.copy, label: 'Copy Path'),
        ),
        const PopupMenuItem(
          value: 'copy_value',
          child: _MenuRow(
            icon: Icons.content_copy,
            label: 'Copy Secret Value',
          ),
        ),
      ],
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    String action,
  ) async {
    switch (action) {
      case 'edit':
        final result = await showDialog<bool>(
          context: context,
          builder: (_) => UpdateSecretDialog(secret: secret),
        );
        if (result == true) onMutated?.call();
      case 'deactivate':
        if (!secret.isActive) return;
        await _softDelete(context, ref);
      case 'delete':
        await _hardDelete(context, ref);
      case 'copy_path':
        await Clipboard.setData(ClipboardData(text: secret.path));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Path copied to clipboard')),
          );
        }
      case 'copy_value':
        await _copyValue(context, ref);
    }
  }

  Future<void> _softDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Deactivate Secret',
      message:
          'Are you sure you want to deactivate "${secret.name}"? '
          'This will mark the secret as inactive.',
      confirmLabel: 'Deactivate',
      destructive: true,
    );
    if (confirmed != true || !context.mounted) return;

    try {
      final api = ref.read(vaultApiProvider);
      await api.softDeleteSecret(secret.id);
      onMutated?.call();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Secret deactivated')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to deactivate: $e')),
        );
      }
    }
  }

  Future<void> _hardDelete(BuildContext context, WidgetRef ref) async {
    // First confirmation.
    final firstConfirm = await showConfirmDialog(
      context,
      title: 'Permanent Delete',
      message:
          'This will permanently delete "${secret.name}" and ALL its versions. '
          'This action cannot be undone.',
      confirmLabel: 'Continue',
      destructive: true,
    );
    if (firstConfirm != true || !context.mounted) return;

    // Second confirmation: type secret name.
    final nameConfirm = await showDialog<bool>(
      context: context,
      builder: (_) => _TypeToConfirmDialog(secretName: secret.name),
    );
    if (nameConfirm != true || !context.mounted) return;

    try {
      final api = ref.read(vaultApiProvider);
      await api.hardDeleteSecret(secret.id);
      onMutated?.call();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Secret permanently deleted')),
        );
        context.go('/vault/secrets');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    }
  }

  Future<void> _copyValue(BuildContext context, WidgetRef ref) async {
    try {
      final api = ref.read(vaultApiProvider);
      final value = await api.readSecretValue(secret.id);
      await Clipboard.setData(ClipboardData(text: value.value));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Secret value copied to clipboard')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to copy value: $e')),
        );
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Menu Row
// ---------------------------------------------------------------------------

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _MenuRow({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? CodeOpsColors.textPrimary;
    return Row(
      children: [
        Icon(icon, size: 16, color: c),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 13, color: c)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Type-to-Confirm Dialog (for permanent delete)
// ---------------------------------------------------------------------------

class _TypeToConfirmDialog extends StatefulWidget {
  final String secretName;

  const _TypeToConfirmDialog({required this.secretName});

  @override
  State<_TypeToConfirmDialog> createState() => _TypeToConfirmDialogState();
}

class _TypeToConfirmDialogState extends State<_TypeToConfirmDialog> {
  final _controller = TextEditingController();
  bool _matches = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() => _matches = _controller.text == widget.secretName);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: CodeOpsColors.surface,
      title: const Text('Confirm Permanent Deletion'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Type "${widget.secretName}" to confirm:',
            style: const TextStyle(
              fontSize: 13,
              color: CodeOpsColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
              hintText: 'Type secret name here',
            ),
          ),
        ],
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
          onPressed: _matches ? () => Navigator.of(context).pop(true) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: CodeOpsColors.error,
          ),
          child: const Text('Delete Permanently'),
        ),
      ],
    );
  }
}
