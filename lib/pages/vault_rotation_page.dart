/// Vault rotation dashboard page.
///
/// Two-tab layout: **Schedule** (rotation policy overview for all secrets)
/// and **Activity** (history timeline + activity feed for a selected
/// secret). Always-visible stats cards row and header with
/// "Add Rotation Policy" action. Composes seven child widgets:
/// [VaultRotationSchedule], [VaultRotationStatusBadge],
/// [VaultRotationStats], [VaultRotationHistory],
/// [VaultRotationActivityFeed], [VaultRotationPolicyDialog],
/// and [VaultManualRotateDialog].
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/vault_models.dart';
import '../providers/vault_providers.dart';
import '../theme/colors.dart';
import '../widgets/vault/vault_manual_rotate_dialog.dart';
import '../widgets/vault/vault_rotation_activity_feed.dart';
import '../widgets/vault/vault_rotation_history.dart';
import '../widgets/vault/vault_rotation_policy_dialog.dart';
import '../widgets/vault/vault_rotation_schedule.dart';
import '../widgets/vault/vault_rotation_stats.dart';
import '../widgets/vault/vault_rotation_status_badge.dart';

/// The Vault Rotation dashboard page.
class VaultRotationPage extends ConsumerStatefulWidget {
  /// Creates a [VaultRotationPage].
  const VaultRotationPage({super.key});

  @override
  ConsumerState<VaultRotationPage> createState() => _VaultRotationPageState();
}

class _VaultRotationPageState extends ConsumerState<VaultRotationPage>
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
    final selectedId = ref.watch(selectedRotationSecretIdProvider);

    return Column(
      children: [
        _buildHeader(),
        // Stats row — visible when a secret is selected.
        if (selectedId != null) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
            child: VaultRotationStats(secretId: selectedId),
          ),
        ],
        const SizedBox(height: 4),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _ScheduleTab(selectedId: selectedId),
              _ActivityTab(selectedId: selectedId),
            ],
          ),
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Header
  // ───────────────────────────────────────────────────────────────────────────

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
            'Rotation',
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
                Tab(text: 'Schedule'),
                Tab(text: 'Activity'),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add Rotation Policy'),
            onPressed: () => _showAddPolicyDialog(context),
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

  // ───────────────────────────────────────────────────────────────────────────
  // Add Policy Dialog
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> _showAddPolicyDialog(BuildContext context) async {
    // Show a secret picker first.
    final secretId = ref.read(selectedRotationSecretIdProvider);
    if (secretId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a secret from the schedule first.'),
        ),
      );
      return;
    }

    // Look up the secret detail for the dialog.
    final secretAsync = ref.read(vaultSecretDetailProvider(secretId));
    final secret = secretAsync.valueOrNull;
    if (secret == null) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => VaultRotationPolicyDialog(
        secretId: secretId,
        secretPath: secret.path,
      ),
    );

    if (result == true) {
      ref.invalidate(vaultRotationPolicyProvider(secretId));
      ref.invalidate(vaultRotationHistoryProvider(secretId));
      ref.invalidate(vaultRotationStatsProvider(secretId));
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Schedule Tab
// ─────────────────────────────────────────────────────────────────────────────

class _ScheduleTab extends ConsumerWidget {
  final String? selectedId;

  const _ScheduleTab({this.selectedId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        // Master — schedule table.
        Expanded(
          child: VaultRotationSchedule(
            selectedSecretId: selectedId,
            onSecretSelected: (id) {
              ref.read(selectedRotationSecretIdProvider.notifier).state = id;
              // Pre-fetch detail provider for the add-policy dialog.
              ref.read(vaultSecretDetailProvider(id));
            },
          ),
        ),
        // Detail — rotation policy detail panel.
        if (selectedId != null) _RotationDetailPanel(secretId: selectedId!),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Activity Tab
// ─────────────────────────────────────────────────────────────────────────────

class _ActivityTab extends ConsumerWidget {
  final String? selectedId;

  const _ActivityTab({this.selectedId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (selectedId == null) {
      return const Center(
        child: Text(
          'Select a secret from the Schedule tab to view activity.',
          style: TextStyle(
            fontSize: 13,
            color: CodeOpsColors.textTertiary,
          ),
        ),
      );
    }

    return Row(
      children: [
        // History timeline.
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Rotation History',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: CodeOpsColors.textPrimary,
                  ),
                ),
              ),
              const Divider(height: 1, color: CodeOpsColors.border),
              Expanded(
                child: VaultRotationHistory(secretId: selectedId!),
              ),
            ],
          ),
        ),
        // Activity feed sidebar.
        Container(
          width: 280,
          decoration: const BoxDecoration(
            border: Border(
              left: BorderSide(color: CodeOpsColors.border),
            ),
          ),
          child: VaultRotationActivityFeed(secretId: selectedId!),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Rotation Detail Panel (in Schedule tab)
// ─────────────────────────────────────────────────────────────────────────────

class _RotationDetailPanel extends ConsumerWidget {
  final String secretId;

  const _RotationDetailPanel({required this.secretId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final policyAsync = ref.watch(vaultRotationPolicyProvider(secretId));
    final secretAsync = ref.watch(vaultSecretDetailProvider(secretId));

    return Container(
      width: 340,
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(color: CodeOpsColors.border),
        ),
      ),
      child: Column(
        children: [
          // Panel header.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: CodeOpsColors.border),
              ),
            ),
            child: Row(
              children: [
                const Text(
                  'Rotation Details',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: CodeOpsColors.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: () => ref
                      .read(selectedRotationSecretIdProvider.notifier)
                      .state = null,
                  tooltip: 'Close',
                ),
              ],
            ),
          ),
          Expanded(
            child: policyAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (_, __) => _buildNoPolicy(context, ref, secretAsync),
              data: (policy) =>
                  _buildPolicyDetails(context, ref, policy, secretAsync),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoPolicy(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<SecretResponse> secretAsync,
  ) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.autorenew_outlined,
            size: 40,
            color: CodeOpsColors.textTertiary,
          ),
          const SizedBox(height: 12),
          const Text(
            'No rotation policy',
            style: TextStyle(
              fontSize: 13,
              color: CodeOpsColors.textTertiary,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => _showCreateDialog(context, ref, secretAsync),
            child: const Text('Create Policy'),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyDetails(
    BuildContext context,
    WidgetRef ref,
    RotationPolicyResponse policy,
    AsyncValue<SecretResponse> secretAsync,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status badge.
          VaultRotationStatusBadge(policy: policy),
          const SizedBox(height: 12),

          // Strategy.
          _detailRow('Strategy', policy.strategy.displayName),
          _detailRow('Interval', '${policy.rotationIntervalHours} hours'),
          if (policy.lastRotatedAt != null)
            _detailRow('Last Rotated', _formatDt(policy.lastRotatedAt!)),
          if (policy.nextRotationAt != null)
            _detailRow('Next Rotation', _formatDt(policy.nextRotationAt!)),
          _detailRow('Failure Count', '${policy.failureCount}'),
          if (policy.maxFailures != null)
            _detailRow('Max Failures', '${policy.maxFailures}'),
          if (policy.randomLength != null)
            _detailRow('Random Length', '${policy.randomLength}'),
          if (policy.externalApiUrl != null)
            _detailRow('External URL', policy.externalApiUrl!),

          const SizedBox(height: 16),
          const Divider(color: CodeOpsColors.border),
          const SizedBox(height: 8),

          // Action buttons.
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.edit, size: 14),
                  label: const Text('Edit'),
                  onPressed: () =>
                      _showEditDialog(context, ref, policy, secretAsync),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.autorenew, size: 14),
                  label: const Text('Rotate Now'),
                  onPressed: () =>
                      _showManualRotateDialog(context, ref, secretAsync),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CodeOpsColors.warning,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.delete_outline, size: 14),
              label: const Text('Delete Policy'),
              onPressed: () => _showDeleteConfirm(context, ref, policy),
              style: OutlinedButton.styleFrom(
                foregroundColor: CodeOpsColors.error,
                side: const BorderSide(color: CodeOpsColors.error),
                padding: const EdgeInsets.symmetric(vertical: 8),
                textStyle: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: CodeOpsColors.textTertiary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                color: CodeOpsColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateDialog(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<SecretResponse> secretAsync,
  ) async {
    final secret = secretAsync.valueOrNull;
    if (secret == null) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => VaultRotationPolicyDialog(
        secretId: secretId,
        secretPath: secret.path,
      ),
    );

    if (result == true) {
      ref.invalidate(vaultRotationPolicyProvider(secretId));
    }
  }

  Future<void> _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    RotationPolicyResponse policy,
    AsyncValue<SecretResponse> secretAsync,
  ) async {
    final secret = secretAsync.valueOrNull;

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => VaultRotationPolicyDialog(
        secretId: secretId,
        secretPath: secret?.path ?? secretId,
        existingPolicy: policy,
      ),
    );

    if (result == true) {
      ref.invalidate(vaultRotationPolicyProvider(secretId));
    }
  }

  Future<void> _showManualRotateDialog(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<SecretResponse> secretAsync,
  ) async {
    final secret = secretAsync.valueOrNull;
    if (secret == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => VaultManualRotateDialog(
        secretName: secret.name,
        secretPath: secret.path,
      ),
    );

    if (confirmed == true) {
      try {
        final api = ref.read(vaultApiProvider);
        await api.rotateSecret(secretId);
        ref.invalidate(vaultRotationPolicyProvider(secretId));
        ref.invalidate(vaultRotationHistoryProvider(secretId));
        ref.invalidate(vaultRotationStatsProvider(secretId));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Rotation triggered successfully.')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Rotation failed: $e')),
          );
        }
      }
    }
  }

  Future<void> _showDeleteConfirm(
    BuildContext context,
    WidgetRef ref,
    RotationPolicyResponse policy,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: CodeOpsColors.surface,
        title: const Text('Delete Rotation Policy'),
        content: const Text(
          'Are you sure you want to delete this rotation policy? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: CodeOpsColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final api = ref.read(vaultApiProvider);
        await api.deleteRotationPolicy(policy.id);
        ref.invalidate(vaultRotationPolicyProvider(secretId));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Rotation policy deleted.')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Delete failed: $e')),
          );
        }
      }
    }
  }

  /// Formats a DateTime for display.
  static String _formatDt(DateTime dt) {
    final d = dt.toLocal();
    return '${d.year}-${_p(d.month)}-${_p(d.day)} '
        '${_p(d.hour)}:${_p(d.minute)}';
  }

  /// Zero-pads a number to 2 digits.
  static String _p(int n) => n.toString().padLeft(2, '0');
}
