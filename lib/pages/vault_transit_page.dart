/// Vault Transit Encryption page with two-tab layout.
///
/// **Keys tab**: Master-detail layout with a filterable, paginated transit
/// key list on the left and a [TransitKeyDetail] panel on the right showing
/// key metadata, version info, capabilities, and actions.
///
/// **Encryption Playground tab**: An [EncryptionPlayground] widget for
/// encrypting, decrypting, rewrapping data, and generating data keys.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/health_snapshot.dart';
import '../models/vault_models.dart';
import '../providers/vault_providers.dart';
import '../theme/colors.dart';
import '../widgets/shared/empty_state.dart';
import '../widgets/shared/error_panel.dart';
import '../widgets/shared/loading_overlay.dart';
import '../widgets/vault/create_transit_key_dialog.dart';
import '../widgets/vault/encryption_playground.dart';
import '../widgets/vault/transit_key_detail.dart';

/// The Vault Transit page with Keys and Encryption Playground tabs.
class VaultTransitPage extends ConsumerStatefulWidget {
  /// Creates a [VaultTransitPage].
  const VaultTransitPage({super.key});

  @override
  ConsumerState<VaultTransitPage> createState() => _VaultTransitPageState();
}

class _VaultTransitPageState extends ConsumerState<VaultTransitPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _KeysTab(),
              const EncryptionPlayground(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: CodeOpsColors.divider),
        ),
      ),
      child: Row(
        children: [
          const Text(
            'Transit',
            style: TextStyle(
              color: CodeOpsColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: CodeOpsColors.primary,
              unselectedLabelColor: CodeOpsColors.textTertiary,
              indicatorColor: CodeOpsColors.primary,
              labelStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              tabAlignment: TabAlignment.start,
              tabs: const [
                Tab(text: 'Keys'),
                Tab(text: 'Encryption Playground'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Keys Tab (master-detail)
// ---------------------------------------------------------------------------

class _KeysTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keysAsync = ref.watch(vaultTransitKeysProvider);
    final selectedId = ref.watch(selectedVaultTransitKeyIdProvider);

    return Column(
      children: [
        _KeysFilterBar(),
        Expanded(
          child: keysAsync.when(
            loading: () =>
                const LoadingOverlay(message: 'Loading transit keys...'),
            error: (e, _) => ErrorPanel.fromException(
              e,
              onRetry: () => ref.invalidate(vaultTransitKeysProvider),
            ),
            data: (page) => _buildMasterDetail(context, ref, page, selectedId),
          ),
        ),
      ],
    );
  }

  Widget _buildMasterDetail(
    BuildContext context,
    WidgetRef ref,
    PageResponse<TransitKeyResponse> page,
    String? selectedId,
  ) {
    final keys = page.content;

    if (keys.isEmpty) {
      return const EmptyState(
        icon: Icons.vpn_key_off_outlined,
        title: 'No transit keys found',
        subtitle: 'Create an encryption key to get started.',
      );
    }

    TransitKeyResponse? selected;
    if (selectedId != null) {
      for (final k in keys) {
        if (k.id == selectedId) {
          selected = k;
          break;
        }
      }
    }

    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: ListView.separated(
                  itemCount: keys.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: CodeOpsColors.border),
                  itemBuilder: (context, index) {
                    final key = keys[index];
                    return _TransitKeyListItem(
                      transitKey: key,
                      isSelected: key.id == selectedId,
                      onTap: () {
                        ref
                            .read(
                                selectedVaultTransitKeyIdProvider.notifier)
                            .state = key.id;
                      },
                    );
                  },
                ),
              ),
              _KeysPagination(page: page),
            ],
          ),
        ),
        if (selected != null)
          TransitKeyDetail(
            transitKey: selected,
            onClose: () => ref
                .read(selectedVaultTransitKeyIdProvider.notifier)
                .state = null,
            onMutated: () {
              ref.invalidate(vaultTransitKeysProvider);
              ref.invalidate(vaultTransitStatsProvider);
            },
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Filter Bar
// ---------------------------------------------------------------------------

class _KeysFilterBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeOnly = ref.watch(vaultTransitActiveOnlyProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: CodeOpsColors.divider),
        ),
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
            icon: const Icon(Icons.add, size: 16),
            label: const Text('New Key'),
            onPressed: () => _showCreateDialog(context, ref),
            style: ElevatedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              textStyle: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => const CreateTransitKeyDialog(),
    );
    if (result == true) {
      ref.invalidate(vaultTransitKeysProvider);
      ref.invalidate(vaultTransitStatsProvider);
    }
  }
}

// ---------------------------------------------------------------------------
// Pagination
// ---------------------------------------------------------------------------

class _KeysPagination extends ConsumerWidget {
  final PageResponse<TransitKeyResponse> page;

  const _KeysPagination({required this.page});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPage = ref.watch(vaultTransitPageProvider);
    final totalPages = page.totalPages;
    final totalElements = page.totalElements;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: CodeOpsColors.border),
        ),
      ),
      child: Row(
        children: [
          Text(
            '$totalElements keys',
            style: const TextStyle(
              fontSize: 12,
              color: CodeOpsColors.textTertiary,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.first_page, size: 18),
            onPressed:
                currentPage > 0 ? () => _goToPage(ref, 0) : null,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 18),
            onPressed: currentPage > 0
                ? () => _goToPage(ref, currentPage - 1)
                : null,
          ),
          Text(
            'Page ${currentPage + 1} of $totalPages',
            style: const TextStyle(
              fontSize: 12,
              color: CodeOpsColors.textSecondary,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 18),
            onPressed: currentPage < totalPages - 1
                ? () => _goToPage(ref, currentPage + 1)
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.last_page, size: 18),
            onPressed: currentPage < totalPages - 1
                ? () => _goToPage(ref, totalPages - 1)
                : null,
          ),
        ],
      ),
    );
  }

  void _goToPage(WidgetRef ref, int page) {
    ref.read(vaultTransitPageProvider.notifier).state = page;
  }
}

// ---------------------------------------------------------------------------
// Transit Key List Item
// ---------------------------------------------------------------------------

class _TransitKeyListItem extends StatelessWidget {
  final TransitKeyResponse transitKey;
  final bool isSelected;
  final VoidCallback onTap;

  const _TransitKeyListItem({
    required this.transitKey,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: isSelected
            ? CodeOpsColors.primary.withValues(alpha: 0.08)
            : null,
        child: Row(
          children: [
            // Key icon
            const Icon(
              Icons.vpn_key_outlined,
              size: 18,
              color: CodeOpsColors.primary,
            ),
            const SizedBox(width: 12),
            // Name + Algorithm
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transitKey.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: CodeOpsColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    transitKey.algorithm,
                    style: const TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: CodeOpsColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
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
            const SizedBox(width: 8),
            // Capability icons
            if (transitKey.isDeletable)
              const Tooltip(
                message: 'Deletable',
                child: Icon(
                  Icons.delete_outline,
                  size: 14,
                  color: CodeOpsColors.textTertiary,
                ),
              ),
            if (transitKey.isExportable) ...[
              const SizedBox(width: 4),
              const Tooltip(
                message: 'Exportable',
                child: Icon(
                  Icons.file_download_outlined,
                  size: 14,
                  color: CodeOpsColors.textTertiary,
                ),
              ),
            ],
            const SizedBox(width: 8),
            // Active indicator
            if (transitKey.isActive)
              const Icon(
                Icons.circle,
                size: 8,
                color: CodeOpsColors.success,
              )
            else
              const Icon(
                Icons.circle,
                size: 8,
                color: CodeOpsColors.textTertiary,
              ),
          ],
        ),
      ),
    );
  }
}
