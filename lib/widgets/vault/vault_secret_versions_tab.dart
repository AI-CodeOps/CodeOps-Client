/// Versions tab for the Vault secret detail page (CVF-003).
///
/// Displays paginated version history, allows selecting two versions for
/// side-by-side comparison via [ScribeDiffEditor], supports restoring a
/// version (re-saves its value as a new version), and destroying versions.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/health_snapshot.dart';
import '../../models/scribe_diff_models.dart';
import '../../models/vault_models.dart';
import '../../providers/scribe_providers.dart';
import '../../providers/vault_providers.dart';
import '../../theme/colors.dart';
import '../../utils/date_utils.dart';
import '../shared/confirm_dialog.dart';
import '../shared/error_panel.dart';
import '../scribe/scribe_diff_editor.dart';

/// The Versions tab of the secret detail page.
///
/// Shows a list of all secret versions. Users can select two versions
/// to compare them using the [ScribeDiffEditor], restore an older
/// version as a new version, or destroy a version.
class VaultSecretVersionsTab extends ConsumerStatefulWidget {
  /// The secret ID to show versions for.
  final String secretId;

  /// Creates a [VaultSecretVersionsTab].
  const VaultSecretVersionsTab({super.key, required this.secretId});

  @override
  ConsumerState<VaultSecretVersionsTab> createState() =>
      _VaultSecretVersionsTabState();
}

class _VaultSecretVersionsTabState
    extends ConsumerState<VaultSecretVersionsTab> {
  /// Selected version numbers for comparison (max 2).
  final Set<int> _selectedVersions = {};

  /// Whether a diff comparison is active.
  bool _comparing = false;

  /// The computed diff state (when comparing).
  DiffState? _diffState;
  DiffViewMode _viewMode = DiffViewMode.sideBySide;
  bool _collapseUnchanged = true;
  bool _loadingDiff = false;

  @override
  Widget build(BuildContext context) {
    if (_comparing && _diffState != null) {
      return _buildCompareView();
    }

    final versionsAsync =
        ref.watch(vaultSecretVersionsProvider(widget.secretId));

    return versionsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (error, _) => ErrorPanel.fromException(
        error,
        onRetry: () =>
            ref.invalidate(vaultSecretVersionsProvider(widget.secretId)),
      ),
      data: (page) => _buildVersionList(page),
    );
  }

  // ─── Version list ──────────────────────────────────────────────────────

  Widget _buildVersionList(PageResponse<SecretVersionResponse> page) {
    final versions = page.content;

    if (versions.isEmpty) {
      return const Center(
        child: Text(
          'No versions',
          style: TextStyle(fontSize: 13, color: CodeOpsColors.textTertiary),
        ),
      );
    }

    return Column(
      children: [
        // Compare toolbar.
        if (_selectedVersions.isNotEmpty) _buildCompareToolbar(),
        // Version list.
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(8),
            itemCount: versions.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: CodeOpsColors.border),
            itemBuilder: (context, index) {
              final v = versions[index];
              return _VersionRow(
                secretId: widget.secretId,
                version: v,
                isSelected: _selectedVersions.contains(v.versionNumber),
                canSelect: _selectedVersions.length < 2 ||
                    _selectedVersions.contains(v.versionNumber),
                onToggleSelect: v.isDestroyed
                    ? null
                    : () => _toggleVersionSelection(v.versionNumber),
                onRestore: v.isDestroyed ? null : () => _restoreVersion(v),
                onDestroy: v.isDestroyed ? null : () => _destroyVersion(v),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCompareToolbar() {
    final sortedVersions = _selectedVersions.toList()..sort();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: CodeOpsColors.surface,
      child: Row(
        children: [
          Icon(Icons.compare_arrows, size: 16, color: CodeOpsColors.primary),
          const SizedBox(width: 6),
          Text(
            _selectedVersions.length == 1
                ? 'v${sortedVersions[0]} selected — pick another to compare'
                : 'v${sortedVersions[0]} ↔ v${sortedVersions[1]}',
            style: const TextStyle(
              fontSize: 12,
              color: CodeOpsColors.textSecondary,
            ),
          ),
          const Spacer(),
          if (_selectedVersions.length == 2)
            ElevatedButton.icon(
              icon: _loadingDiff
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.compare, size: 16),
              label: const Text('Compare'),
              style: ElevatedButton.styleFrom(
                backgroundColor: CodeOpsColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                textStyle: const TextStyle(fontSize: 12),
              ),
              onPressed: _loadingDiff ? null : _startCompare,
            ),
          const SizedBox(width: 6),
          TextButton(
            onPressed: () => setState(() => _selectedVersions.clear()),
            child: const Text(
              'Clear',
              style: TextStyle(fontSize: 12, color: CodeOpsColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Compare view ──────────────────────────────────────────────────────

  Widget _buildCompareView() {
    final diffService = ref.read(scribeDiffServiceProvider);
    final displayLines = _collapseUnchanged
        ? diffService.collapseUnchanged(_diffState!.lines)
        : _diffState!.lines;

    return Column(
      children: [
        // Close compare toolbar.
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          color: CodeOpsColors.surface,
          child: Row(
            children: [
              const Icon(Icons.compare_arrows,
                  size: 16, color: CodeOpsColors.primary),
              const SizedBox(width: 6),
              Text(
                'Comparing v${_diffState!.leftTabId} ↔ v${_diffState!.rightTabId}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: CodeOpsColors.textPrimary,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                icon: const Icon(Icons.close, size: 14),
                label: const Text('Close'),
                style: TextButton.styleFrom(
                  foregroundColor: CodeOpsColors.textSecondary,
                  textStyle: const TextStyle(fontSize: 12),
                ),
                onPressed: _closeCompare,
              ),
            ],
          ),
        ),
        // Diff editor.
        Expanded(
          child: ScribeDiffEditor(
            diffState: _diffState!,
            viewMode: _viewMode,
            collapseUnchanged: _collapseUnchanged,
            displayLines: displayLines,
            onViewModeChanged: (mode) => setState(() => _viewMode = mode),
            onCollapseChanged: (value) =>
                setState(() => _collapseUnchanged = value),
            leftTitle: 'v${_diffState!.leftTabId}',
            rightTitle: 'v${_diffState!.rightTabId}',
          ),
        ),
      ],
    );
  }

  // ─── Actions ───────────────────────────────────────────────────────────

  void _toggleVersionSelection(int versionNumber) {
    setState(() {
      if (_selectedVersions.contains(versionNumber)) {
        _selectedVersions.remove(versionNumber);
      } else if (_selectedVersions.length < 2) {
        _selectedVersions.add(versionNumber);
      }
    });
  }

  Future<void> _startCompare() async {
    if (_selectedVersions.length != 2) return;

    setState(() => _loadingDiff = true);

    try {
      final api = ref.read(vaultApiProvider);
      final sorted = _selectedVersions.toList()..sort();

      final leftValue = await api.readSecretVersionValue(
        widget.secretId,
        sorted[0],
      );
      final rightValue = await api.readSecretVersionValue(
        widget.secretId,
        sorted[1],
      );

      final diffService = ref.read(scribeDiffServiceProvider);
      final diffState = diffService.computeDiff(
        leftTabId: '${sorted[0]}',
        rightTabId: '${sorted[1]}',
        leftText: leftValue.value,
        rightText: rightValue.value,
      );

      if (mounted) {
        setState(() {
          _diffState = diffState;
          _comparing = true;
          _loadingDiff = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingDiff = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load versions for comparison: $e')),
        );
      }
    }
  }

  void _closeCompare() {
    setState(() {
      _comparing = false;
      _diffState = null;
      _selectedVersions.clear();
    });
  }

  Future<void> _restoreVersion(SecretVersionResponse version) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Restore Version',
      message:
          'Restore v${version.versionNumber}? This will create a new version '
          'with the same value.',
      confirmLabel: 'Restore',
    );
    if (confirmed != true || !mounted) return;

    try {
      final api = ref.read(vaultApiProvider);

      // Read the version's value.
      final versionValue = await api.readSecretVersionValue(
        widget.secretId,
        version.versionNumber,
      );

      // Create a new version with that value.
      await api.updateSecret(
        widget.secretId,
        value: versionValue.value,
        changeDescription: 'Restored from v${version.versionNumber}',
      );

      ref.invalidate(vaultSecretVersionsProvider(widget.secretId));
      ref.invalidate(vaultSecretDetailProvider(widget.secretId));
      ref.invalidate(vaultSecretsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Restored v${version.versionNumber} as new version',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to restore: $e')),
        );
      }
    }
  }

  Future<void> _destroyVersion(SecretVersionResponse version) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Destroy Version',
      message:
          'Destroy v${version.versionNumber}? '
          'This is irreversible — the value will be zeroed.',
      confirmLabel: 'Destroy',
      destructive: true,
    );
    if (confirmed != true || !mounted) return;

    try {
      final api = ref.read(vaultApiProvider);
      await api.destroyVersion(widget.secretId, version.versionNumber);
      ref.invalidate(vaultSecretVersionsProvider(widget.secretId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Version v${version.versionNumber} destroyed'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to destroy: $e')),
        );
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Version Row
// ---------------------------------------------------------------------------

class _VersionRow extends StatelessWidget {
  final String secretId;
  final SecretVersionResponse version;
  final bool isSelected;
  final bool canSelect;
  final VoidCallback? onToggleSelect;
  final VoidCallback? onRestore;
  final VoidCallback? onDestroy;

  const _VersionRow({
    required this.secretId,
    required this.version,
    required this.isSelected,
    required this.canSelect,
    this.onToggleSelect,
    this.onRestore,
    this.onDestroy,
  });

  @override
  Widget build(BuildContext context) {
    final destroyed = version.isDestroyed;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Row(
        children: [
          // Selection checkbox.
          if (!destroyed)
            Checkbox(
              value: isSelected,
              onChanged: canSelect || isSelected
                  ? (_) => onToggleSelect?.call()
                  : null,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            )
          else
            const SizedBox(width: 40),
          // Version number badge.
          Container(
            width: 36,
            padding: const EdgeInsets.symmetric(vertical: 2),
            decoration: BoxDecoration(
              color: destroyed
                  ? CodeOpsColors.error.withValues(alpha: 0.1)
                  : isSelected
                      ? CodeOpsColors.primary.withValues(alpha: 0.2)
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
          // Details.
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
          // Status / actions.
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
          else ...[
            IconButton(
              icon: const Icon(Icons.restore, size: 16),
              tooltip: 'Restore version',
              onPressed: onRestore,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 16),
              tooltip: 'Destroy version',
              onPressed: onDestroy,
            ),
          ],
        ],
      ),
    );
  }
}
