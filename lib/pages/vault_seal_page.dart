/// Vault Seal/Unseal management page.
///
/// Single-page layout with state-dependent content:
/// - **UNSEALED**: Seal info card, Generate Key Shares button, Seal Vault button.
/// - **SEALED/UNSEALING**: Status indicator, unseal form with progress bar and
///   share submission log.
///
/// Polls seal status every 10 seconds for live updates.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/vault_enums.dart';
import '../models/vault_models.dart';
import '../providers/vault_providers.dart';
import '../theme/colors.dart';
import '../widgets/vault/vault_generate_shares_dialog.dart';
import '../widgets/vault/vault_seal_dialog.dart';
import '../widgets/vault/vault_seal_info.dart';
import '../widgets/vault/vault_seal_status.dart';
import '../widgets/vault/vault_unseal_form.dart';

/// The Vault Seal/Unseal management page.
///
/// Displays the current seal status with state-dependent content: when
/// unsealed shows seal info and action buttons; when sealed or unsealing
/// shows the unseal form with progress tracking.
class VaultSealPage extends ConsumerStatefulWidget {
  /// Creates a [VaultSealPage].
  const VaultSealPage({super.key});

  @override
  ConsumerState<VaultSealPage> createState() => _VaultSealPageState();
}

class _VaultSealPageState extends ConsumerState<VaultSealPage> {
  bool _sealing = false;
  bool _generating = false;

  @override
  Widget build(BuildContext context) {
    final sealAsync = ref.watch(sealStatusProvider);

    // Also listen to polling updates to keep the status fresh.
    ref.listen(sealStatusPollingProvider, (_, next) {
      next.whenData((polled) => ref.invalidate(sealStatusProvider));
    });

    return sealAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: CodeOpsColors.primary,
        ),
      ),
      error: (e, _) => _buildError(e),
      data: (status) => _buildContent(status),
    );
  }

  Widget _buildError(Object error) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline,
              size: 48, color: CodeOpsColors.error),
          const SizedBox(height: 16),
          Text(
            'Failed to load seal status',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: CodeOpsColors.textPrimary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '$error',
            style: const TextStyle(
              fontSize: 12,
              color: CodeOpsColors.textTertiary,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => ref.invalidate(sealStatusProvider),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(SealStatusResponse status) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page title
          Text(
            'Seal Management',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: CodeOpsColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 20),

          // Status indicator
          VaultSealStatus(sealStatus: status),
          const SizedBox(height: 20),

          // Seal info card
          VaultSealInfo(sealStatus: status),
          const SizedBox(height: 20),

          // Unseal form (sealed/unsealing only)
          if (status.status != SealStatus.unsealed) ...[
            VaultUnsealForm(sealStatus: status),
            const SizedBox(height: 20),
          ],

          // Action buttons
          _buildActions(status),
        ],
      ),
    );
  }

  Widget _buildActions(SealStatusResponse status) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // Generate Key Shares (only when unsealed)
        if (status.status == SealStatus.unsealed)
          OutlinedButton.icon(
            icon: const Icon(Icons.vpn_key, size: 16),
            label: const Text('Generate Key Shares'),
            style: OutlinedButton.styleFrom(
              foregroundColor: CodeOpsColors.primary,
              side: const BorderSide(color: CodeOpsColors.primary),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              textStyle: const TextStyle(fontSize: 12),
            ),
            onPressed: _generating ? null : _generateShares,
          ),

        // Seal Vault (only when unsealed)
        if (status.status == SealStatus.unsealed)
          OutlinedButton.icon(
            icon: const Icon(Icons.lock, size: 16),
            label: const Text('Seal Vault'),
            style: OutlinedButton.styleFrom(
              foregroundColor: CodeOpsColors.error,
              side: const BorderSide(color: CodeOpsColors.error),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              textStyle: const TextStyle(fontSize: 12),
            ),
            onPressed: _sealing ? null : () => _showSealConfirmation(status),
          ),
      ],
    );
  }

  Future<void> _showSealConfirmation(SealStatusResponse status) async {
    final confirmed = await showVaultSealDialog(
      context,
      threshold: status.threshold,
      totalShares: status.totalShares,
    );
    if (confirmed != true || !mounted) return;
    await _sealVault();
  }

  Future<void> _sealVault() async {
    setState(() => _sealing = true);
    try {
      final api = ref.read(vaultApiProvider);
      await api.sealVault();
      ref.invalidate(sealStatusProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vault sealed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to seal vault: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sealing = false);
    }
  }

  Future<void> _generateShares() async {
    setState(() => _generating = true);
    try {
      final api = ref.read(vaultApiProvider);
      final result = await api.generateShares();
      final shares = (result['shares'] as List).cast<String>();
      final total = (result['totalShares'] as num).toInt();
      final thresh = (result['threshold'] as num).toInt();
      if (mounted) {
        await showGenerateSharesDialog(
          context,
          shares: shares,
          totalShares: total,
          threshold: thresh,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate shares: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }
}
