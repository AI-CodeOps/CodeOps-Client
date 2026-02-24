/// Vault Policies page with two-tab layout.
///
/// **Policies tab**: Master-detail layout with a filterable, paginated policy
/// list on the left and a [PolicyDetailPanel] on the right showing metadata,
/// permissions, and bindings.
///
/// **Evaluate Access tab**: An [AccessEvaluator] form for testing whether a
/// user or service has permission on a given path.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/health_snapshot.dart';
import '../models/vault_models.dart';
import '../providers/vault_providers.dart';
import '../theme/colors.dart';
import '../widgets/shared/empty_state.dart';
import '../widgets/shared/error_panel.dart';
import '../widgets/shared/loading_overlay.dart';
import '../widgets/vault/access_evaluator.dart';
import '../widgets/vault/permission_badge.dart';
import '../widgets/vault/policy_detail_panel.dart';
import '../widgets/vault/vault_policy_dialog.dart';

/// The Vault Policies page with Policies and Evaluate Access tabs.
class VaultPoliciesPage extends ConsumerStatefulWidget {
  /// Creates a [VaultPoliciesPage].
  const VaultPoliciesPage({super.key});

  @override
  ConsumerState<VaultPoliciesPage> createState() => _VaultPoliciesPageState();
}

class _VaultPoliciesPageState extends ConsumerState<VaultPoliciesPage>
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
        // Header with tabs
        _buildHeader(),
        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _PoliciesTab(),
              const AccessEvaluator(),
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
            'Policies',
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
                Tab(text: 'Policies'),
                Tab(text: 'Evaluate Access'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Policies Tab (master-detail)
// ---------------------------------------------------------------------------

class _PoliciesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final policiesAsync = ref.watch(vaultPoliciesProvider);
    final selectedId = ref.watch(selectedVaultPolicyIdProvider);

    return Column(
      children: [
        _PoliciesFilterBar(),
        Expanded(
          child: policiesAsync.when(
            loading: () =>
                const LoadingOverlay(message: 'Loading policies...'),
            error: (e, _) => ErrorPanel.fromException(
              e,
              onRetry: () => ref.invalidate(vaultPoliciesProvider),
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
    PageResponse<AccessPolicyResponse> page,
    String? selectedId,
  ) {
    final policies = page.content;

    if (policies.isEmpty) {
      return const EmptyState(
        icon: Icons.policy_outlined,
        title: 'No policies found',
        subtitle: 'Create an access policy or adjust your filters.',
      );
    }

    AccessPolicyResponse? selected;
    if (selectedId != null) {
      for (final p in policies) {
        if (p.id == selectedId) {
          selected = p;
          break;
        }
      }
    }

    return Row(
      children: [
        // Policy list
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: ListView.separated(
                  itemCount: policies.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: CodeOpsColors.border),
                  itemBuilder: (context, index) {
                    final policy = policies[index];
                    return _PolicyListItem(
                      policy: policy,
                      isSelected: policy.id == selectedId,
                      onTap: () {
                        ref
                            .read(selectedVaultPolicyIdProvider.notifier)
                            .state = policy.id;
                      },
                    );
                  },
                ),
              ),
              _PoliciesPagination(page: page),
            ],
          ),
        ),
        // Detail panel
        if (selected != null)
          PolicyDetailPanel(
            policy: selected,
            onClose: () =>
                ref.read(selectedVaultPolicyIdProvider.notifier).state = null,
            onMutated: () {
              ref.invalidate(vaultPoliciesProvider);
              ref.invalidate(vaultPolicyStatsProvider);
            },
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Filter Bar
// ---------------------------------------------------------------------------

class _PoliciesFilterBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeOnly = ref.watch(vaultPolicyActiveOnlyProvider);
    final sortBy = ref.watch(vaultPolicySortByProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: CodeOpsColors.divider),
        ),
      ),
      child: Row(
        children: [
          // Active toggle
          FilterChip(
            label: const Text('Active Only', style: TextStyle(fontSize: 11)),
            selected: activeOnly,
            onSelected: (v) =>
                ref.read(vaultPolicyActiveOnlyProvider.notifier).state = v,
            checkmarkColor: Colors.white,
            selectedColor: CodeOpsColors.primary,
            backgroundColor: CodeOpsColors.surface,
            side: const BorderSide(color: CodeOpsColors.border),
            padding: EdgeInsets.zero,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          const SizedBox(width: 12),
          // Sort dropdown
          const Text(
            'Sort:',
            style: TextStyle(fontSize: 11, color: CodeOpsColors.textTertiary),
          ),
          const SizedBox(width: 4),
          _SortChip(
            label: 'Name',
            isSelected: sortBy == 'name',
            onTap: () => _toggleSort(ref, 'name'),
          ),
          const SizedBox(width: 4),
          _SortChip(
            label: 'Created',
            isSelected: sortBy == 'createdAt',
            onTap: () => _toggleSort(ref, 'createdAt'),
          ),
          const Spacer(),
          // New Policy button
          ElevatedButton.icon(
            icon: const Icon(Icons.add, size: 16),
            label: const Text('New Policy'),
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

  void _toggleSort(WidgetRef ref, String field) {
    final currentSort = ref.read(vaultPolicySortByProvider);
    final currentDir = ref.read(vaultPolicySortDirProvider);
    if (currentSort == field) {
      ref.read(vaultPolicySortDirProvider.notifier).state =
          currentDir == 'asc' ? 'desc' : 'asc';
    } else {
      ref.read(vaultPolicySortByProvider.notifier).state = field;
      ref.read(vaultPolicySortDirProvider.notifier).state = 'asc';
    }
  }

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => const VaultPolicyDialog(),
    );
    if (result == true) {
      ref.invalidate(vaultPoliciesProvider);
      ref.invalidate(vaultPolicyStatsProvider);
    }
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SortChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? CodeOpsColors.primary.withValues(alpha: 0.15)
              : CodeOpsColors.surface,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected
                ? CodeOpsColors.primary.withValues(alpha: 0.4)
                : CodeOpsColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected
                ? CodeOpsColors.primary
                : CodeOpsColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pagination
// ---------------------------------------------------------------------------

class _PoliciesPagination extends ConsumerWidget {
  final PageResponse<AccessPolicyResponse> page;

  const _PoliciesPagination({required this.page});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPage = ref.watch(vaultPolicyPageProvider);
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
            '$totalElements policies',
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
    ref.read(vaultPolicyPageProvider.notifier).state = page;
  }
}

// ---------------------------------------------------------------------------
// Policy List Item
// ---------------------------------------------------------------------------

class _PolicyListItem extends StatelessWidget {
  final AccessPolicyResponse policy;
  final bool isSelected;
  final VoidCallback onTap;

  const _PolicyListItem({
    required this.policy,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onDoubleTap: () => context.go('/vault/policies/${policy.id}'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: isSelected
            ? CodeOpsColors.primary.withValues(alpha: 0.08)
            : null,
        child: Row(
          children: [
            // Policy icon
            Icon(
              policy.isDenyPolicy ? Icons.block : Icons.policy_outlined,
              size: 18,
              color: policy.isDenyPolicy
                  ? CodeOpsColors.error
                  : CodeOpsColors.primary,
            ),
            const SizedBox(width: 12),
            // Name + Path pattern
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          policy.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: CodeOpsColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (policy.isDenyPolicy) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color:
                                CodeOpsColors.error.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: const Text(
                            'DENY',
                            style: TextStyle(
                              color: CodeOpsColors.error,
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    policy.pathPattern,
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
            // Permission badges
            Wrap(
              spacing: 3,
              children: policy.permissions
                  .map((p) => PermissionBadge(permission: p))
                  .toList(),
            ),
            const SizedBox(width: 8),
            // Active indicator
            if (policy.isActive)
              const Icon(Icons.circle, size: 8, color: CodeOpsColors.success)
            else
              const Icon(Icons.circle, size: 8, color: CodeOpsColors.textTertiary),
            const SizedBox(width: 8),
            // Binding count
            Text(
              '${policy.bindingCount}',
              style: const TextStyle(
                fontSize: 11,
                color: CodeOpsColors.textTertiary,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.link, size: 12, color: CodeOpsColors.textTertiary),
            const SizedBox(width: 4),
            // Open detail page
            IconButton(
              icon: const Icon(Icons.open_in_new, size: 14),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              color: CodeOpsColors.textTertiary,
              tooltip: 'Open detail page',
              onPressed: () => context.go('/vault/policies/${policy.id}'),
            ),
          ],
        ),
      ),
    );
  }
}
