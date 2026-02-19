/// Tabbed detail panel for a Vault secret.
///
/// Four tabs: **Info** (metadata fields), **Value** (reveal + copy),
/// **Versions** (paginated list with destroy), **Metadata** (key-value CRUD).
/// Action buttons along the top for update, edit, soft-delete, and
/// permanent delete.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/vault_models.dart';
import '../../providers/vault_providers.dart';
import '../../theme/colors.dart';
import '../../utils/date_utils.dart';
import '../shared/confirm_dialog.dart';
import '../shared/error_panel.dart';
import 'update_secret_dialog.dart';

/// Displays full detail for a [SecretResponse] in a tabbed panel.
class SecretDetailPanel extends ConsumerStatefulWidget {
  /// The secret to display.
  final SecretResponse secret;

  /// Called when the panel should close.
  final VoidCallback? onClose;

  /// Called after a mutation so the parent can refresh.
  final VoidCallback? onMutated;

  /// Creates a [SecretDetailPanel].
  const SecretDetailPanel({
    super.key,
    required this.secret,
    this.onClose,
    this.onMutated,
  });

  @override
  ConsumerState<SecretDetailPanel> createState() => _SecretDetailPanelState();
}

class _SecretDetailPanelState extends ConsumerState<SecretDetailPanel>
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
    final secret = widget.secret;

    return Container(
      width: 420,
      decoration: const BoxDecoration(
        color: CodeOpsColors.surface,
        border: Border(left: BorderSide(color: CodeOpsColors.border)),
      ),
      child: Column(
        children: [
          // Header
          _PanelHeader(
            secret: secret,
            onClose: widget.onClose,
            onMutated: widget.onMutated,
          ),
          // Tabs
          TabBar(
            controller: _tabController,
            labelColor: CodeOpsColors.primary,
            unselectedLabelColor: CodeOpsColors.textTertiary,
            indicatorColor: CodeOpsColors.primary,
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            tabs: const [
              Tab(text: 'Info'),
              Tab(text: 'Value'),
              Tab(text: 'Versions'),
              Tab(text: 'Metadata'),
            ],
          ),
          const Divider(height: 1, color: CodeOpsColors.border),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _InfoTab(secret: secret),
                _ValueTab(secretId: secret.id),
                _VersionsTab(secretId: secret.id),
                _MetadataTab(
                  secretId: secret.id,
                  onMutated: widget.onMutated,
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
// Panel Header with action buttons
// ---------------------------------------------------------------------------

class _PanelHeader extends ConsumerWidget {
  final SecretResponse secret;
  final VoidCallback? onClose;
  final VoidCallback? onMutated;

  const _PanelHeader({
    required this.secret,
    this.onClose,
    this.onMutated,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  secret.name,
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
          Text(
            secret.path,
            style: const TextStyle(
              fontSize: 12,
              fontFamily: 'monospace',
              color: CodeOpsColors.textTertiary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _ActionButton(
                label: 'Update',
                icon: Icons.edit_outlined,
                onPressed: () => _showUpdateDialog(context, ref),
              ),
              _ActionButton(
                label: 'Soft Delete',
                icon: Icons.delete_outline,
                color: CodeOpsColors.warning,
                onPressed: () => _softDelete(context, ref),
              ),
              _ActionButton(
                label: 'Permanent Delete',
                icon: Icons.delete_forever,
                color: CodeOpsColors.error,
                onPressed: () => _hardDelete(context, ref),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showUpdateDialog(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => UpdateSecretDialog(secret: secret),
    );
    if (result == true) {
      ref.invalidate(vaultSecretsProvider);
      ref.invalidate(vaultSecretDetailProvider(secret.id));
      onMutated?.call();
    }
  }

  Future<void> _softDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Soft Delete Secret',
      message:
          'Are you sure you want to deactivate "${secret.name}"? '
          'It can be restored later.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (confirmed != true || !context.mounted) return;

    try {
      final api = ref.read(vaultApiProvider);
      await api.softDeleteSecret(secret.id);
      ref.invalidate(vaultSecretsProvider);
      onMutated?.call();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Secret deactivated')),
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

  Future<void> _hardDelete(BuildContext context, WidgetRef ref) async {
    // First confirmation
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

    // Second confirmation: type the secret name
    final nameConfirm = await showDialog<bool>(
      context: context,
      builder: (_) => _TypeToConfirmDialog(secretName: secret.name),
    );
    if (nameConfirm != true || !context.mounted) return;

    try {
      final api = ref.read(vaultApiProvider);
      await api.hardDeleteSecret(secret.id);
      ref.invalidate(vaultSecretsProvider);
      onMutated?.call();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Secret permanently deleted')),
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

// ---------------------------------------------------------------------------
// Info Tab
// ---------------------------------------------------------------------------

class _InfoTab extends StatelessWidget {
  final SecretResponse secret;

  const _InfoTab({required this.secret});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _field('Path', secret.path),
        _field('Name', secret.name),
        _field('Type', secret.secretType.displayName),
        _field('Active', secret.isActive ? 'Yes' : 'No'),
        _field('Current Version', 'v${secret.currentVersion}'),
        if (secret.description != null) _field('Description', secret.description!),
        if (secret.ownerUserId != null)
          _field('Owner', secret.ownerUserId!.substring(0, 8)),
        if (secret.maxVersions != null)
          _field('Max Versions', '${secret.maxVersions}'),
        if (secret.retentionDays != null)
          _field('Retention', '${secret.retentionDays} days'),
        if (secret.referenceArn != null)
          _field('Reference ARN', secret.referenceArn!),
        const Divider(height: 24, color: CodeOpsColors.border),
        _field('Created', formatDateTime(secret.createdAt)),
        _field('Updated', formatDateTime(secret.updatedAt)),
        _field('Last Accessed', formatDateTime(secret.lastAccessedAt)),
        _field('Last Rotated', formatDateTime(secret.lastRotatedAt)),
        if (secret.expiresAt != null) ...[
          const Divider(height: 24, color: CodeOpsColors.border),
          _expiryField(secret.expiresAt!),
        ],
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

  Widget _expiryField(DateTime expiresAt) {
    final remaining = expiresAt.difference(DateTime.now());
    final isUrgent = remaining.inHours < 24;
    final isWarning = remaining.inHours < 72;
    final color = remaining.isNegative
        ? CodeOpsColors.error
        : isUrgent
            ? CodeOpsColors.error
            : isWarning
                ? CodeOpsColors.warning
                : CodeOpsColors.success;
    final label = remaining.isNegative
        ? 'Expired'
        : remaining.inHours < 1
            ? '${remaining.inMinutes}m remaining'
            : remaining.inHours < 24
                ? '${remaining.inHours}h remaining'
                : '${remaining.inDays}d ${remaining.inHours.remainder(24)}h remaining';

    return Row(
      children: [
        Icon(Icons.schedule, size: 14, color: color),
        const SizedBox(width: 8),
        Text(
          'Expires: ${formatDateTime(expiresAt)} ($label)',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Value Tab
// ---------------------------------------------------------------------------

class _ValueTab extends ConsumerStatefulWidget {
  final String secretId;

  const _ValueTab({required this.secretId});

  @override
  ConsumerState<_ValueTab> createState() => _ValueTabState();
}

class _ValueTabState extends ConsumerState<_ValueTab> {
  String? _revealedValue;
  Timer? _autoHideTimer;
  bool _loading = false;

  @override
  void dispose() {
    _autoHideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_revealedValue != null) {
      return _buildRevealedView();
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.visibility_off, size: 48, color: CodeOpsColors.textTertiary),
          const SizedBox(height: 12),
          const Text(
            'Secret value is hidden',
            style: TextStyle(fontSize: 13, color: CodeOpsColors.textSecondary),
          ),
          const SizedBox(height: 4),
          const Text(
            'Value will auto-hide after 30 seconds',
            style: TextStyle(fontSize: 11, color: CodeOpsColors.textTertiary),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: _loading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.visibility, size: 16),
            label: const Text('Reveal Secret'),
            style: ElevatedButton.styleFrom(
              backgroundColor: CodeOpsColors.warning,
            ),
            onPressed: _loading ? null : _revealSecret,
          ),
        ],
      ),
    );
  }

  Widget _buildRevealedView() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber, size: 14, color: CodeOpsColors.warning),
              const SizedBox(width: 6),
              const Text(
                'Secret value revealed — auto-hides in 30s',
                style: TextStyle(fontSize: 11, color: CodeOpsColors.warning),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.copy, size: 16),
                tooltip: 'Copy to clipboard',
                onPressed: _copyToClipboard,
              ),
              IconButton(
                icon: const Icon(Icons.visibility_off, size: 16),
                tooltip: 'Hide',
                onPressed: _hideValue,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CodeOpsColors.background,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: CodeOpsColors.border),
            ),
            child: SelectableText(
              _revealedValue!,
              style: const TextStyle(
                fontSize: 13,
                fontFamily: 'monospace',
                color: CodeOpsColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _revealSecret() async {
    setState(() => _loading = true);
    try {
      final api = ref.read(vaultApiProvider);
      final value = await api.readSecretValue(widget.secretId);
      if (mounted) {
        setState(() {
          _revealedValue = value.value;
          _loading = false;
        });
        _startAutoHide();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reveal: $e')),
        );
      }
    }
  }

  void _startAutoHide() {
    _autoHideTimer?.cancel();
    _autoHideTimer = Timer(const Duration(seconds: 30), () {
      if (mounted) _hideValue();
    });
  }

  void _hideValue() {
    _autoHideTimer?.cancel();
    setState(() => _revealedValue = null);
  }

  void _copyToClipboard() {
    if (_revealedValue == null) return;
    Clipboard.setData(ClipboardData(text: _revealedValue!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Secret copied to clipboard')),
    );
  }
}

// ---------------------------------------------------------------------------
// Versions Tab
// ---------------------------------------------------------------------------

class _VersionsTab extends ConsumerWidget {
  final String secretId;

  const _VersionsTab({required this.secretId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final versionsAsync = ref.watch(vaultSecretVersionsProvider(secretId));

    return versionsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (error, _) => ErrorPanel.fromException(
        error,
        onRetry: () => ref.invalidate(vaultSecretVersionsProvider(secretId)),
      ),
      data: (page) {
        final versions = page.content;
        if (versions.isEmpty) {
          return const Center(
            child: Text(
              'No versions',
              style: TextStyle(fontSize: 13, color: CodeOpsColors.textTertiary),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(8),
          itemCount: versions.length,
          separatorBuilder: (_, __) =>
              const Divider(height: 1, color: CodeOpsColors.border),
          itemBuilder: (context, index) {
            final v = versions[index];
            return _VersionRow(secretId: secretId, version: v);
          },
        );
      },
    );
  }
}

class _VersionRow extends ConsumerWidget {
  final String secretId;
  final SecretVersionResponse version;

  const _VersionRow({required this.secretId, required this.version});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final destroyed = version.isDestroyed;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Row(
        children: [
          // Version number
          Container(
            width: 36,
            padding: const EdgeInsets.symmetric(vertical: 2),
            decoration: BoxDecoration(
              color: destroyed
                  ? CodeOpsColors.error.withValues(alpha: 0.1)
                  : CodeOpsColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'v${version.versionNumber}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: destroyed ? CodeOpsColors.error : CodeOpsColors.primary,
                decoration: destroyed ? TextDecoration.lineThrough : null,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 10),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  version.changeDescription ?? 'No description',
                  style: TextStyle(
                    fontSize: 12,
                    color: destroyed
                        ? CodeOpsColors.textTertiary
                        : CodeOpsColors.textPrimary,
                    decoration: destroyed ? TextDecoration.lineThrough : null,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  formatDateTime(version.createdAt),
                  style: const TextStyle(
                    fontSize: 10,
                    color: CodeOpsColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          // Destroy badge or action
          if (destroyed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: CodeOpsColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Destroyed',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: CodeOpsColors.error,
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 16),
              tooltip: 'Destroy version',
              onPressed: () => _destroyVersion(context, ref),
            ),
        ],
      ),
    );
  }

  Future<void> _destroyVersion(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Destroy Version',
      message:
          'Destroy v${version.versionNumber}? '
          'This is irreversible — the value will be zeroed.',
      confirmLabel: 'Destroy',
      destructive: true,
    );
    if (confirmed != true || !context.mounted) return;

    try {
      final api = ref.read(vaultApiProvider);
      await api.destroyVersion(secretId, version.versionNumber);
      ref.invalidate(vaultSecretVersionsProvider(secretId));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Version v${version.versionNumber} destroyed')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to destroy: $e')),
        );
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Metadata Tab
// ---------------------------------------------------------------------------

class _MetadataTab extends ConsumerStatefulWidget {
  final String secretId;
  final VoidCallback? onMutated;

  const _MetadataTab({required this.secretId, this.onMutated});

  @override
  ConsumerState<_MetadataTab> createState() => _MetadataTabState();
}

class _MetadataTabState extends ConsumerState<_MetadataTab> {
  final _keyController = TextEditingController();
  final _valueController = TextEditingController();

  @override
  void dispose() {
    _keyController.dispose();
    _valueController.dispose();
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
      data: (metadata) {
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            // Add new entry
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
            const Divider(height: 1, color: CodeOpsColors.border),
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
              ...metadata.entries.map((entry) => _MetadataRow(
                    metaKey: entry.key,
                    metaValue: entry.value,
                    onDelete: () => _removeEntry(entry.key),
                  )),
          ],
        );
      },
    );
  }

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
}

class _MetadataRow extends StatelessWidget {
  final String metaKey;
  final String metaValue;
  final VoidCallback onDelete;

  const _MetadataRow({
    required this.metaKey,
    required this.metaValue,
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
            icon: const Icon(Icons.close, size: 14),
            tooltip: 'Remove',
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
