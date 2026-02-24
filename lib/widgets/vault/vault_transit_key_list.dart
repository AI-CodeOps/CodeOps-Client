/// Transit key list table with selection, pagination, and inline actions.
///
/// Displays a filterable, paginated list of [TransitKeyResponse] keys
/// with name, algorithm, version, capabilities, and active status.
/// Selecting a key populates the operations panel. Each selected key
/// shows action buttons for rotate, edit, and delete.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/health_snapshot.dart';
import '../../models/vault_models.dart';
import '../../providers/vault_providers.dart';
import '../../theme/colors.dart';
import '../shared/empty_state.dart';
import '../shared/error_panel.dart';
import 'vault_transit_key_dialog.dart';

/// A paginated key list with filter bar, actions, and selection.
class VaultTransitKeyList extends ConsumerWidget {
  /// Creates a [VaultTransitKeyList].
  const VaultTransitKeyList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keysAsync = ref.watch(vaultTransitKeysProvider);
    final selectedId = ref.watch(selectedVaultTransitKeyIdProvider);

    return Column(
      children: [
        _FilterBar(),
        Expanded(
          child: keysAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            error: (e, _) => ErrorPanel.fromException(
              e,
              onRetry: () => ref.invalidate(vaultTransitKeysProvider),
            ),
            data: (page) => _buildList(context, ref, page, selectedId),
          ),
        ),
      ],
    );
  }

  Widget _buildList(
    BuildContext context,
    WidgetRef ref,
    PageResponse<TransitKeyResponse> page,
    String? selectedId,
  ) {
    final keys = page.content;

    if (keys.isEmpty) {
      return const EmptyState(
        icon: Icons.vpn_key_off_outlined,
        title: 'No transit keys',
        subtitle: 'Create an encryption key to get started.',
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            itemCount: keys.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: CodeOpsColors.border),
            itemBuilder: (context, index) {
              final key = keys[index];
              final isSelected = key.id == selectedId;
              return _KeyRow(
                transitKey: key,
                isSelected: isSelected,
                onTap: () => ref
                    .read(selectedVaultTransitKeyIdProvider.notifier)
                    .state = key.id,
              );
            },
          ),
        ),
        _Pagination(page: page),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Filter Bar
// ---------------------------------------------------------------------------

class _FilterBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeOnly = ref.watch(vaultTransitActiveOnlyProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: CodeOpsColors.divider)),
      ),
      child: Row(
        children: [
          FilterChip(
            label: const Text('Active Only', style: TextStyle(fontSize: 11)),
            selected: activeOnly,
            onSelected: (v) =>
                ref.read(vaultTransitActiveOnlyProvider.notifier).state = v,
            checkmarkColor: Colors.white,
            selectedColor: CodeOpsColors.primary,
            backgroundColor: CodeOpsColors.surface,
            side: const BorderSide(color: CodeOpsColors.border),
            padding: EdgeInsets.zero,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          const Spacer(),
          ElevatedButton.icon(
            icon: const Icon(Icons.add, size: 14),
            label: const Text('New Key'),
            onPressed: () => _showCreateDialog(context, ref),
            style: ElevatedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              textStyle: const TextStyle(fontSize: 12),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => const VaultTransitKeyDialog(),
    );
    if (result == true) {
      ref.invalidate(vaultTransitKeysProvider);
      ref.invalidate(vaultTransitStatsProvider);
    }
  }
}

// ---------------------------------------------------------------------------
// Key Row
// ---------------------------------------------------------------------------

class _KeyRow extends StatelessWidget {
  final TransitKeyResponse transitKey;
  final bool isSelected;
  final VoidCallback onTap;

  const _KeyRow({
    required this.transitKey,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        color: isSelected
            ? CodeOpsColors.primary.withValues(alpha: 0.08)
            : null,
        child: Row(
          children: [
            Icon(
              Icons.vpn_key_outlined,
              size: 16,
              color: transitKey.isActive
                  ? CodeOpsColors.primary
                  : CodeOpsColors.textTertiary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transitKey.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: transitKey.isActive
                          ? CodeOpsColors.textPrimary
                          : CodeOpsColors.textTertiary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    transitKey.algorithm,
                    style: const TextStyle(
                      fontSize: 10,
                      fontFamily: 'monospace',
                      color: CodeOpsColors.textTertiary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            // Version badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: CodeOpsColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'v${transitKey.currentVersion}',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: CodeOpsColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 6),
            // Capability icons
            if (transitKey.isDeletable)
              const Tooltip(
                message: 'Deletable',
                child: Icon(
                  Icons.delete_outline,
                  size: 13,
                  color: CodeOpsColors.textTertiary,
                ),
              ),
            if (transitKey.isExportable) ...[
              const SizedBox(width: 4),
              const Tooltip(
                message: 'Exportable',
                child: Icon(
                  Icons.file_download_outlined,
                  size: 13,
                  color: CodeOpsColors.textTertiary,
                ),
              ),
            ],
            const SizedBox(width: 6),
            // Active indicator
            Icon(
              Icons.circle,
              size: 8,
              color: transitKey.isActive
                  ? CodeOpsColors.success
                  : CodeOpsColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pagination
// ---------------------------------------------------------------------------

class _Pagination extends ConsumerWidget {
  final PageResponse<TransitKeyResponse> page;

  const _Pagination({required this.page});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPage = ref.watch(vaultTransitPageProvider);
    final totalPages = page.totalPages;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: CodeOpsColors.border)),
      ),
      child: Row(
        children: [
          Text(
            '${page.totalElements} keys',
            style: const TextStyle(
              fontSize: 11,
              color: CodeOpsColors.textTertiary,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 16),
            onPressed: currentPage > 0
                ? () =>
                    ref.read(vaultTransitPageProvider.notifier).state =
                        currentPage - 1
                : null,
            visualDensity: VisualDensity.compact,
          ),
          Text(
            '${currentPage + 1}/$totalPages',
            style: const TextStyle(
              fontSize: 11,
              color: CodeOpsColors.textSecondary,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 16),
            onPressed: currentPage < totalPages - 1
                ? () =>
                    ref.read(vaultTransitPageProvider.notifier).state =
                        currentPage + 1
                : null,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

/// Shows a type-to-confirm delete dialog for a transit key.
///
/// Returns `true` if the user confirmed deletion, `false` otherwise.
Future<bool?> showTransitKeyDeleteDialog(
  BuildContext context,
  TransitKeyResponse key,
) {
  return showDialog<bool>(
    context: context,
    builder: (_) => _DeleteKeyDialog(transitKey: key),
  );
}

// ---------------------------------------------------------------------------
// Delete Key Dialog (type-to-confirm)
// ---------------------------------------------------------------------------

class _DeleteKeyDialog extends StatefulWidget {
  final TransitKeyResponse transitKey;

  const _DeleteKeyDialog({required this.transitKey});

  @override
  State<_DeleteKeyDialog> createState() => _DeleteKeyDialogState();
}

class _DeleteKeyDialogState extends State<_DeleteKeyDialog> {
  final _controller = TextEditingController();

  bool get _confirmed => _controller.text == widget.transitKey.name;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: CodeOpsColors.surface,
      title: const Text('Delete Transit Key'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Permanently delete "${widget.transitKey.name}"?',
              style: const TextStyle(color: CodeOpsColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: CodeOpsColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: CodeOpsColors.error.withValues(alpha: 0.3),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber, size: 16, color: CodeOpsColors.error),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Existing ciphertext encrypted with this key will '
                      'become permanently unrecoverable.',
                      style: TextStyle(
                        fontSize: 12,
                        color: CodeOpsColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Type the key name to confirm:',
              style: TextStyle(
                fontSize: 12,
                color: CodeOpsColors.textTertiary,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _controller,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: widget.transitKey.name,
                border: const OutlineInputBorder(),
                isDense: true,
                contentPadding: const EdgeInsets.all(10),
              ),
              style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
            ),
          ],
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
          onPressed: _confirmed
              ? () => Navigator.of(context).pop(true)
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: CodeOpsColors.error,
          ),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
