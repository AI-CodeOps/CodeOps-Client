/// Schedule overview table for the rotation dashboard.
///
/// Lists all secrets from [vaultSecretsProvider] and shows each
/// secret's rotation policy status inline by watching
/// [vaultRotationPolicyProvider] per row. Secrets without a
/// rotation policy show a "No policy" indicator.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/vault_enums.dart';
import '../../models/vault_models.dart';
import '../../providers/vault_providers.dart';
import '../../theme/colors.dart';
import '../../widgets/shared/empty_state.dart';
import '../../widgets/shared/error_panel.dart';
import 'vault_rotation_status_badge.dart';

/// Tabular schedule overview showing secrets and their rotation policies.
class VaultRotationSchedule extends ConsumerWidget {
  /// Called when a secret row is tapped.
  final ValueChanged<String>? onSecretSelected;

  /// ID of the currently selected secret.
  final String? selectedSecretId;

  /// Creates a [VaultRotationSchedule].
  const VaultRotationSchedule({
    super.key,
    this.onSecretSelected,
    this.selectedSecretId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final secretsAsync = ref.watch(vaultSecretsProvider);

    return secretsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (e, _) => ErrorPanel.fromException(
        e,
        onRetry: () => ref.invalidate(vaultSecretsProvider),
      ),
      data: (page) {
        if (page.content.isEmpty) {
          return const EmptyState(
            icon: Icons.autorenew_outlined,
            title: 'No secrets found',
            subtitle: 'Create a secret first, then add a rotation policy.',
          );
        }
        return _buildTable(context, page.content);
      },
    );
  }

  Widget _buildTable(BuildContext context, List<SecretResponse> secrets) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: const BoxDecoration(
            color: CodeOpsColors.surfaceVariant,
            border: Border(
              bottom: BorderSide(color: CodeOpsColors.border),
            ),
          ),
          child: const Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  'Secret Path',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: CodeOpsColors.textTertiary,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Strategy',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: CodeOpsColors.textTertiary,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Interval',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: CodeOpsColors.textTertiary,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Status',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: CodeOpsColors.textTertiary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        // Rows
        Expanded(
          child: ListView.separated(
            itemCount: secrets.length,
            separatorBuilder: (_, __) => const Divider(
              height: 1,
              color: CodeOpsColors.border,
            ),
            itemBuilder: (context, index) => _ScheduleRow(
              secret: secrets[index],
              isSelected: secrets[index].id == selectedSecretId,
              onTap: () => onSecretSelected?.call(secrets[index].id),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Schedule Row (per-secret rotation policy)
// ---------------------------------------------------------------------------

class _ScheduleRow extends ConsumerWidget {
  final SecretResponse secret;
  final bool isSelected;
  final VoidCallback? onTap;

  const _ScheduleRow({
    required this.secret,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final policyAsync = ref.watch(vaultRotationPolicyProvider(secret.id));

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: isSelected
            ? CodeOpsColors.primary.withValues(alpha: 0.08)
            : null,
        child: policyAsync.when(
          loading: () => Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  secret.path,
                  style: const TextStyle(
                    fontSize: 12,
                    color: CodeOpsColors.textPrimary,
                    fontFamily: 'monospace',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Expanded(
                flex: 4,
                child: Center(
                  child: SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 1.5),
                  ),
                ),
              ),
            ],
          ),
          error: (_, __) => Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  secret.path,
                  style: const TextStyle(
                    fontSize: 12,
                    color: CodeOpsColors.textPrimary,
                    fontFamily: 'monospace',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Expanded(
                flex: 2,
                child: Text(
                  'No policy',
                  style: TextStyle(
                    fontSize: 11,
                    color: CodeOpsColors.textTertiary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const Expanded(child: SizedBox.shrink()),
              const Expanded(child: SizedBox.shrink()),
            ],
          ),
          data: (policy) => _buildPolicyRow(policy),
        ),
      ),
    );
  }

  Widget _buildPolicyRow(RotationPolicyResponse policy) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            secret.path,
            style: const TextStyle(
              fontSize: 12,
              color: CodeOpsColors.textPrimary,
              fontFamily: 'monospace',
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          flex: 2,
          child: Row(
            children: [
              Icon(
                _strategyIcon(policy.strategy),
                size: 14,
                color: CodeOpsColors.rotationStrategyColors[policy.strategy],
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  policy.strategy.displayName,
                  style: const TextStyle(
                    fontSize: 11,
                    color: CodeOpsColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Text(
            _formatInterval(policy.rotationIntervalHours),
            style: const TextStyle(
              fontSize: 11,
              color: CodeOpsColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: VaultRotationStatusBadge(policy: policy),
          ),
        ),
      ],
    );
  }

  /// Returns an icon for the rotation strategy.
  static IconData _strategyIcon(RotationStrategy strategy) =>
      switch (strategy) {
        RotationStrategy.randomGenerate => Icons.casino_outlined,
        RotationStrategy.externalApi => Icons.api_outlined,
        RotationStrategy.customScript => Icons.code_outlined,
      };

  /// Formats rotation interval hours to a readable string.
  static String _formatInterval(int hours) {
    if (hours < 24) return '${hours}h';
    final days = hours ~/ 24;
    final rem = hours % 24;
    if (rem == 0) return '${days}d';
    return '${days}d ${rem}h';
  }
}
