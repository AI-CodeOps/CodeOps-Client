/// Full detail page for a single Vault access policy (CVF-004).
///
/// Three tabs: **Overview** (policy metadata, permissions, deny/active status,
/// edit/delete/toggle actions), **Bindings** (CRUD table of user/team/service
/// bindings), **Impact Preview** (client-side path matching showing which
/// secrets the policy would affect and deny-override visualization).
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
import '../widgets/vault/create_binding_dialog.dart';
import '../widgets/vault/permission_badge.dart';
import '../widgets/vault/vault_policy_dialog.dart';
import '../widgets/vault/vault_policy_eval_preview.dart';

/// The Vault policy detail page.
///
/// Loaded at `/vault/policies/:policyId` and displays full policy information
/// with tabs for overview, bindings, and impact preview.
class VaultPolicyDetailPage extends ConsumerStatefulWidget {
  /// The policy ID from the route parameter.
  final String policyId;

  /// Creates a [VaultPolicyDetailPage].
  const VaultPolicyDetailPage({super.key, required this.policyId});

  @override
  ConsumerState<VaultPolicyDetailPage> createState() =>
      _VaultPolicyDetailPageState();
}

class _VaultPolicyDetailPageState extends ConsumerState<VaultPolicyDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _invalidateDetail() {
    ref.invalidate(vaultPolicyDetailProvider(widget.policyId));
    ref.invalidate(vaultPoliciesProvider);
    ref.invalidate(vaultPolicyStatsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(vaultPolicyDetailProvider(widget.policyId));

    return detailAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (error, _) => ErrorPanel.fromException(
        error,
        onRetry: () =>
            ref.invalidate(vaultPolicyDetailProvider(widget.policyId)),
      ),
      data: (policy) => _buildPage(policy),
    );
  }

  Widget _buildPage(AccessPolicyResponse policy) {
    return Column(
      children: [
        // Header
        _PolicyDetailHeader(
          policy: policy,
          onBack: () => context.go('/vault/policies'),
          onEdit: () => _editPolicy(policy),
          onDelete: () => _deletePolicy(policy),
          onToggleActive: () => _toggleActive(policy),
          onCopyPath: () => _copyPathPattern(policy),
        ),
        // Tab bar
        Container(
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: CodeOpsColors.divider),
            ),
          ),
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
              Tab(text: 'Overview'),
              Tab(text: 'Bindings'),
              Tab(text: 'Impact Preview'),
            ],
          ),
        ),
        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _OverviewTab(policy: policy, onMutated: _invalidateDetail),
              _BindingsTab(
                policyId: widget.policyId,
                onMutated: _invalidateDetail,
              ),
              VaultPolicyEvalPreview(policyId: widget.policyId),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Actions ─────────────────────────────────────────────────────────────

  Future<void> _editPolicy(AccessPolicyResponse policy) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => VaultPolicyDialog(policy: policy),
    );
    if (result == true) _invalidateDetail();
  }

  Future<void> _deletePolicy(AccessPolicyResponse policy) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete Policy',
      message:
          'Are you sure you want to delete "${policy.name}"? '
          'All bindings will also be removed.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (confirmed != true || !mounted) return;

    try {
      final api = ref.read(vaultApiProvider);
      await api.deletePolicy(policy.id);
      ref.invalidate(vaultPoliciesProvider);
      ref.invalidate(vaultPolicyStatsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Policy deleted')),
        );
        context.go('/vault/policies');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    }
  }

  Future<void> _toggleActive(AccessPolicyResponse policy) async {
    try {
      final api = ref.read(vaultApiProvider);
      await api.updatePolicy(policy.id, isActive: !policy.isActive);
      _invalidateDetail();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              policy.isActive ? 'Policy deactivated' : 'Policy activated',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e')),
        );
      }
    }
  }

  void _copyPathPattern(AccessPolicyResponse policy) {
    Clipboard.setData(ClipboardData(text: policy.pathPattern));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Path pattern copied')),
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _PolicyDetailHeader extends StatelessWidget {
  final AccessPolicyResponse policy;
  final VoidCallback onBack;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleActive;
  final VoidCallback onCopyPath;

  const _PolicyDetailHeader({
    required this.policy,
    required this.onBack,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
    required this.onCopyPath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: CodeOpsColors.surface,
        border: Border(bottom: BorderSide(color: CodeOpsColors.border)),
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 20),
            tooltip: 'Back to policies',
            onPressed: onBack,
          ),
          const SizedBox(width: 8),
          // Policy icon
          Icon(
            policy.isDenyPolicy ? Icons.block : Icons.policy_outlined,
            size: 22,
            color: policy.isDenyPolicy
                ? CodeOpsColors.error
                : CodeOpsColors.primary,
          ),
          const SizedBox(width: 10),
          // Name + path pattern
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
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: CodeOpsColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Deny badge
                    if (policy.isDenyPolicy)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: CodeOpsColors.error.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'DENY',
                          style: TextStyle(
                            color: CodeOpsColors.error,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    const SizedBox(width: 6),
                    // Active badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: (policy.isActive
                                ? CodeOpsColors.success
                                : CodeOpsColors.textTertiary)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        policy.isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          color: policy.isActive
                              ? CodeOpsColors.success
                              : CodeOpsColors.textTertiary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  policy.pathPattern,
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: CodeOpsColors.textTertiary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Binding count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: CodeOpsColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.link, size: 14, color: CodeOpsColors.primary),
                const SizedBox(width: 4),
                Text(
                  '${policy.bindingCount}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: CodeOpsColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Actions dropdown
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 20),
            tooltip: 'Actions',
            color: CodeOpsColors.surface,
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  onEdit();
                case 'toggle':
                  onToggleActive();
                case 'delete':
                  onDelete();
                case 'copy':
                  onCopyPath();
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 16),
                    SizedBox(width: 8),
                    Text('Edit Policy'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'toggle',
                child: Row(
                  children: [
                    Icon(
                      policy.isActive
                          ? Icons.pause_circle_outline
                          : Icons.play_circle_outline,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(policy.isActive ? 'Deactivate' : 'Activate'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'copy',
                child: Row(
                  children: [
                    Icon(Icons.copy, size: 16),
                    SizedBox(width: 8),
                    Expanded(child: Text('Copy Path Pattern')),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 16,
                        color: CodeOpsColors.error),
                    SizedBox(width: 8),
                    Text('Delete',
                        style: TextStyle(color: CodeOpsColors.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Overview Tab
// ---------------------------------------------------------------------------

class _OverviewTab extends StatelessWidget {
  final AccessPolicyResponse policy;
  final VoidCallback? onMutated;

  const _OverviewTab({required this.policy, this.onMutated});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Info section
        _buildSection('Details', [
          _field('Name', policy.name),
          _field('Path Pattern', policy.pathPattern),
          if (policy.description != null)
            _field('Description', policy.description!),
          _field('Type', policy.isDenyPolicy ? 'Deny' : 'Allow'),
          _field('Active', policy.isActive ? 'Yes' : 'No'),
          _field('Bindings', '${policy.bindingCount}'),
          if (policy.createdByUserId != null)
            _field('Created By', policy.createdByUserId!.substring(0, 8)),
          _field('Created', formatDateTime(policy.createdAt)),
          _field('Updated', formatDateTime(policy.updatedAt)),
        ]),
        const SizedBox(height: 20),
        // Permissions section
        _buildSection('Permissions', [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: policy.permissions
                .map((p) => PermissionBadge(permission: p))
                .toList(),
          ),
        ]),
        const SizedBox(height: 20),
        // Path pattern help
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: CodeOpsColors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: CodeOpsColors.primary.withValues(alpha: 0.15),
            ),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 14, color: CodeOpsColors.primary),
                  SizedBox(width: 6),
                  Text(
                    'Path Pattern Matching',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: CodeOpsColors.primary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6),
              Text(
                'Use * for single-segment wildcards. Example: /apps/*/secrets '
                'matches /apps/api/secrets but not /apps/api/v2/secrets.',
                style: TextStyle(
                  fontSize: 11,
                  color: CodeOpsColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: CodeOpsColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: CodeOpsColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: CodeOpsColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
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
            width: 110,
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
}

// ---------------------------------------------------------------------------
// Bindings Tab
// ---------------------------------------------------------------------------

class _BindingsTab extends ConsumerWidget {
  final String policyId;
  final VoidCallback? onMutated;

  const _BindingsTab({required this.policyId, this.onMutated});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bindingsAsync = ref.watch(vaultPolicyBindingsProvider(policyId));

    return Column(
      children: [
        // Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: CodeOpsColors.divider),
            ),
          ),
          child: Row(
            children: [
              const Text(
                'Policy Bindings',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: CodeOpsColors.textPrimary,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Binding'),
                onPressed: () => _addBinding(context, ref),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        // Bindings list
        Expanded(
          child: bindingsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            error: (error, _) => ErrorPanel.fromException(
              error,
              onRetry: () =>
                  ref.invalidate(vaultPolicyBindingsProvider(policyId)),
            ),
            data: (bindings) => _buildBindingsList(context, ref, bindings),
          ),
        ),
      ],
    );
  }

  Widget _buildBindingsList(
    BuildContext context,
    WidgetRef ref,
    List<PolicyBindingResponse> bindings,
  ) {
    if (bindings.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.link_off, size: 48, color: CodeOpsColors.textTertiary),
            SizedBox(height: 8),
            Text(
              'No bindings',
              style: TextStyle(
                fontSize: 14,
                color: CodeOpsColors.textTertiary,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Add a binding to apply this policy to a user, team, or service.',
              style: TextStyle(
                fontSize: 12,
                color: CodeOpsColors.textTertiary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(8),
      itemCount: bindings.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, color: CodeOpsColors.border),
      itemBuilder: (context, index) {
        final binding = bindings[index];
        return _BindingListRow(
          binding: binding,
          onDelete: () => _deleteBinding(context, ref, binding),
        );
      },
    );
  }

  Future<void> _addBinding(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => CreateBindingDialog(policyId: policyId),
    );
    if (result == true) {
      ref.invalidate(vaultPolicyBindingsProvider(policyId));
      ref.invalidate(vaultPoliciesProvider);
      onMutated?.call();
    }
  }

  Future<void> _deleteBinding(
    BuildContext context,
    WidgetRef ref,
    PolicyBindingResponse binding,
  ) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Remove Binding',
      message:
          'Remove ${binding.bindingType.displayName} binding '
          '"${binding.bindingTargetId.substring(0, 8)}..."?',
      confirmLabel: 'Remove',
      destructive: true,
    );
    if (confirmed != true || !context.mounted) return;

    try {
      final api = ref.read(vaultApiProvider);
      await api.deleteBinding(binding.id);
      ref.invalidate(vaultPolicyBindingsProvider(policyId));
      ref.invalidate(vaultPoliciesProvider);
      onMutated?.call();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Binding removed')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove: $e')),
        );
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Binding List Row
// ---------------------------------------------------------------------------

class _BindingListRow extends StatelessWidget {
  final PolicyBindingResponse binding;
  final VoidCallback onDelete;

  const _BindingListRow({required this.binding, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final typeColor = CodeOpsColors.bindingTypeColors[binding.bindingType] ??
        CodeOpsColors.textTertiary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Row(
        children: [
          // Type badge
          Container(
            width: 70,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: typeColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              binding.bindingType.toJson(),
              style: TextStyle(
                color: typeColor,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 12),
          // Target ID
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  binding.bindingTargetId,
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: CodeOpsColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Created ${formatTimeAgo(binding.createdAt)}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: CodeOpsColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          // Delete button
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 16),
            tooltip: 'Remove binding',
            color: CodeOpsColors.textTertiary,
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
