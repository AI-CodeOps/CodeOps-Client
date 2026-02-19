/// Vault Secrets page with master-detail layout.
///
/// Filterable, paginated list of secrets on the left with a detail panel
/// on the right. Supports type filter chips, active toggle, sort dropdown,
/// search, and pagination. Write operations are disabled when the vault
/// is sealed.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vault_enums.dart';
import '../models/vault_models.dart';
import '../providers/vault_providers.dart';
import '../theme/colors.dart';
import '../utils/date_utils.dart';
import '../widgets/shared/empty_state.dart';
import '../widgets/shared/error_panel.dart';
import '../widgets/shared/loading_overlay.dart';
import '../widgets/vault/create_secret_dialog.dart';
import '../widgets/vault/secret_detail_panel.dart';

/// The Vault Secrets list page with master-detail layout.
class VaultSecretsPage extends ConsumerStatefulWidget {
  /// Creates a [VaultSecretsPage].
  const VaultSecretsPage({super.key});

  @override
  ConsumerState<VaultSecretsPage> createState() => _VaultSecretsPageState();
}

class _VaultSecretsPageState extends ConsumerState<VaultSecretsPage> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final secretsAsync = ref.watch(vaultSecretsProvider);
    final searchQuery = ref.watch(vaultSecretSearchQueryProvider);
    final selectedId = ref.watch(selectedVaultSecretIdProvider);
    final sealAsync = ref.watch(sealStatusProvider);
    final isSealed = sealAsync.whenOrNull(
          data: (s) => s.status == SealStatus.sealed,
        ) ??
        false;

    return Column(
      children: [
        // Header
        _buildHeader(isSealed),
        // Sealed banner
        if (isSealed) _buildSealedBanner(),
        // Filter bar
        _buildFilterBar(),
        // Main content
        Expanded(
          child: _buildContent(secretsAsync, searchQuery, selectedId),
        ),
      ],
    );
  }

  Widget _buildHeader(bool isSealed) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: CodeOpsColors.divider),
        ),
      ),
      child: Row(
        children: [
          const Text(
            'Secrets',
            style: TextStyle(
              color: CodeOpsColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          // Search
          SizedBox(
            width: 240,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search secrets...',
                isDense: true,
                prefixIcon: const Icon(Icons.search, size: 18),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () {
                          _searchController.clear();
                          ref
                              .read(vaultSecretSearchQueryProvider.notifier)
                              .state = '';
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              style: const TextStyle(fontSize: 13),
              onChanged: _onSearchChanged,
            ),
          ),
          const SizedBox(width: 12),
          // Create button
          ElevatedButton.icon(
            icon: const Icon(Icons.add, size: 16),
            label: const Text('New Secret'),
            onPressed: isSealed ? null : _showCreateDialog,
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

  Widget _buildSealedBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      color: CodeOpsColors.error.withValues(alpha: 0.1),
      child: const Row(
        children: [
          Icon(Icons.lock, size: 14, color: CodeOpsColors.error),
          SizedBox(width: 8),
          Text(
            'Vault is sealed — write operations are disabled',
            style: TextStyle(fontSize: 12, color: CodeOpsColors.error),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final typeFilter = ref.watch(vaultSecretTypeFilterProvider);
    final activeOnly = ref.watch(vaultSecretActiveOnlyProvider);
    final sortBy = ref.watch(vaultSecretSortByProvider);
    final sortDir = ref.watch(vaultSecretSortDirProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: CodeOpsColors.divider),
        ),
      ),
      child: Row(
        children: [
          // Type chips
          _TypeChip(
            label: 'All',
            selected: typeFilter == null,
            onSelected: () =>
                ref.read(vaultSecretTypeFilterProvider.notifier).state = null,
          ),
          const SizedBox(width: 4),
          _TypeChip(
            label: 'Static',
            selected: typeFilter == SecretType.static_,
            onSelected: () => ref
                .read(vaultSecretTypeFilterProvider.notifier)
                .state = SecretType.static_,
          ),
          const SizedBox(width: 4),
          _TypeChip(
            label: 'Dynamic',
            selected: typeFilter == SecretType.dynamic_,
            onSelected: () => ref
                .read(vaultSecretTypeFilterProvider.notifier)
                .state = SecretType.dynamic_,
          ),
          const SizedBox(width: 4),
          _TypeChip(
            label: 'Reference',
            selected: typeFilter == SecretType.reference,
            onSelected: () => ref
                .read(vaultSecretTypeFilterProvider.notifier)
                .state = SecretType.reference,
          ),
          const SizedBox(width: 16),
          // Active toggle
          FilterChip(
            label: const Text('Active', style: TextStyle(fontSize: 11)),
            selected: activeOnly,
            onSelected: (v) =>
                ref.read(vaultSecretActiveOnlyProvider.notifier).state = v,
            checkmarkColor: Colors.white,
            selectedColor: CodeOpsColors.primary,
            backgroundColor: CodeOpsColors.surface,
            side: const BorderSide(color: CodeOpsColors.border),
            padding: EdgeInsets.zero,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          const Spacer(),
          // Sort dropdown
          DropdownButton<String>(
            value: sortBy,
            underline: const SizedBox.shrink(),
            isDense: true,
            style: const TextStyle(
              fontSize: 12,
              color: CodeOpsColors.textSecondary,
            ),
            dropdownColor: CodeOpsColors.surface,
            items: const [
              DropdownMenuItem(value: 'createdAt', child: Text('Created')),
              DropdownMenuItem(value: 'name', child: Text('Name')),
              DropdownMenuItem(value: 'path', child: Text('Path')),
              DropdownMenuItem(
                value: 'lastAccessedAt',
                child: Text('Accessed'),
              ),
            ],
            onChanged: (v) {
              if (v != null) {
                ref.read(vaultSecretSortByProvider.notifier).state = v;
              }
            },
          ),
          IconButton(
            icon: Icon(
              sortDir == 'asc' ? Icons.arrow_upward : Icons.arrow_downward,
              size: 16,
            ),
            tooltip: sortDir == 'asc' ? 'Ascending' : 'Descending',
            onPressed: () {
              ref.read(vaultSecretSortDirProvider.notifier).state =
                  sortDir == 'asc' ? 'desc' : 'asc';
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    AsyncValue<dynamic> secretsAsync,
    String searchQuery,
    String? selectedId,
  ) {
    // If searching, use the search provider
    if (searchQuery.length >= 2) {
      final searchAsync = ref.watch(vaultSecretSearchProvider(searchQuery));
      return _buildMasterDetail(searchAsync, selectedId, isSearch: true);
    }

    return _buildMasterDetail(secretsAsync, selectedId);
  }

  Widget _buildMasterDetail(
    AsyncValue<dynamic> asyncValue,
    String? selectedId, {
    bool isSearch = false,
  }) {
    return asyncValue.when(
      loading: () => const LoadingOverlay(message: 'Loading secrets...'),
      error: (e, _) => ErrorPanel.fromException(
        e,
        onRetry: () {
          if (isSearch) {
            ref.invalidate(vaultSecretSearchProvider);
          } else {
            ref.invalidate(vaultSecretsProvider);
          }
        },
      ),
      data: (pageResponse) {
        final page = pageResponse as dynamic;
        final secrets = (page.content as List).cast<SecretResponse>();

        if (secrets.isEmpty) {
          return const EmptyState(
            icon: Icons.key_off_outlined,
            title: 'No secrets found',
            subtitle: 'Create a secret or adjust your filters.',
          );
        }

        // Find the selected secret
        SecretResponse? selected;
        if (selectedId != null) {
          for (final s in secrets) {
            if (s.id == selectedId) {
              selected = s;
              break;
            }
          }
        }

        return Row(
          children: [
            // Secret list
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: ListView.separated(
                      itemCount: secrets.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: CodeOpsColors.border),
                      itemBuilder: (context, index) {
                        final secret = secrets[index];
                        final isActive = secret.id == selectedId;
                        return _SecretListItem(
                          secret: secret,
                          isSelected: isActive,
                          onTap: () {
                            ref
                                .read(selectedVaultSecretIdProvider.notifier)
                                .state = secret.id;
                          },
                        );
                      },
                    ),
                  ),
                  // Pagination
                  if (!isSearch) _buildPagination(page),
                ],
              ),
            ),
            // Detail panel
            if (selected != null)
              SecretDetailPanel(
                secret: selected,
                onClose: () => ref
                    .read(selectedVaultSecretIdProvider.notifier)
                    .state = null,
                onMutated: () {
                  ref.invalidate(vaultSecretsProvider);
                  ref.invalidate(vaultSecretStatsProvider);
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildPagination(dynamic page) {
    final currentPage = ref.watch(vaultSecretPageProvider);
    final totalPages = (page.totalPages as int?) ?? 1;
    final totalElements = (page.totalElements as int?) ?? 0;

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
            '$totalElements secrets',
            style: const TextStyle(
              fontSize: 12,
              color: CodeOpsColors.textTertiary,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.first_page, size: 18),
            onPressed:
                currentPage > 0 ? () => _goToPage(0) : null,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 18),
            onPressed:
                currentPage > 0 ? () => _goToPage(currentPage - 1) : null,
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
                ? () => _goToPage(currentPage + 1)
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.last_page, size: 18),
            onPressed: currentPage < totalPages - 1
                ? () => _goToPage(totalPages - 1)
                : null,
          ),
        ],
      ),
    );
  }

  void _goToPage(int page) {
    ref.read(vaultSecretPageProvider.notifier).state = page;
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(vaultSecretSearchQueryProvider.notifier).state = value.trim();
    });
  }

  Future<void> _showCreateDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => const CreateSecretDialog(),
    );
    if (result == true) {
      ref.invalidate(vaultSecretsProvider);
      ref.invalidate(vaultSecretStatsProvider);
    }
  }
}

// ---------------------------------------------------------------------------
// Type Filter Chip
// ---------------------------------------------------------------------------

class _TypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: CodeOpsColors.primary,
      backgroundColor: CodeOpsColors.surface,
      labelStyle: TextStyle(
        color: selected ? Colors.white : CodeOpsColors.textSecondary,
      ),
      side: const BorderSide(color: CodeOpsColors.border),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

// ---------------------------------------------------------------------------
// Secret List Item
// ---------------------------------------------------------------------------

class _SecretListItem extends StatelessWidget {
  final SecretResponse secret;
  final bool isSelected;
  final VoidCallback onTap;

  const _SecretListItem({
    required this.secret,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final expiresAt = secret.expiresAt;
    final remaining = expiresAt?.difference(DateTime.now());
    final isExpiring = remaining != null && remaining.inHours < 72;
    final isUrgent = remaining != null && remaining.inHours < 24;

    final typeIcon = switch (secret.secretType) {
      SecretType.static_ => Icons.key_outlined,
      SecretType.dynamic_ => Icons.refresh_outlined,
      SecretType.reference => Icons.link_outlined,
    };

    final typeColor =
        CodeOpsColors.secretTypeColors[secret.secretType] ??
            CodeOpsColors.textTertiary;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: isSelected
            ? CodeOpsColors.primary.withValues(alpha: 0.08)
            : null,
        child: Row(
          children: [
            // Type icon
            Icon(typeIcon, size: 18, color: typeColor),
            const SizedBox(width: 12),
            // Name + Path
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    secret.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: CodeOpsColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    secret.path,
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
            const SizedBox(width: 8),
            // Type badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                secret.secretType.displayName,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: typeColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Version
            Text(
              'v${secret.currentVersion}',
              style: const TextStyle(
                fontSize: 11,
                color: CodeOpsColors.textTertiary,
              ),
            ),
            const SizedBox(width: 8),
            // Expiry indicator
            if (isExpiring)
              Icon(
                Icons.schedule,
                size: 14,
                color: isUrgent ? CodeOpsColors.error : CodeOpsColors.warning,
              )
            else if (secret.isActive)
              const Icon(Icons.circle, size: 8, color: CodeOpsColors.success),
            const SizedBox(width: 8),
            // Last accessed
            Text(
              formatTimeAgo(secret.lastAccessedAt),
              style: const TextStyle(
                fontSize: 10,
                color: CodeOpsColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
