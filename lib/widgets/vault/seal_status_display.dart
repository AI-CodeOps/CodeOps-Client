/// Seal status display widget for the Vault seal management tab.
///
/// Shows a large visual indicator of the current seal state (sealed,
/// unsealed, or unsealing), a progress bar for unseal progress,
/// a key share input form, and action buttons for seal/unseal/generate.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/vault_enums.dart';
import '../../models/vault_models.dart';
import '../../providers/vault_providers.dart';
import '../../theme/colors.dart';
import '../../utils/date_utils.dart';
import 'shares_display.dart';

/// Displays the current seal status with actions and share input.
///
/// Renders one of three states:
/// - **SEALED**: Red lock icon, warning, key share input to begin unseal.
/// - **UNSEALING**: Amber hourglass, progress bar, key share input.
/// - **UNSEALED**: Green lock_open icon, operational message, seal button.
///
/// Also provides a "Generate New Shares" button that triggers share
/// generation and displays the resulting shares one time.
class SealStatusDisplay extends ConsumerStatefulWidget {
  /// The current seal status from the API.
  final SealStatusResponse sealStatus;

  /// Creates a [SealStatusDisplay].
  const SealStatusDisplay({super.key, required this.sealStatus});

  @override
  ConsumerState<SealStatusDisplay> createState() => _SealStatusDisplayState();
}

class _SealStatusDisplayState extends ConsumerState<SealStatusDisplay> {
  final _shareController = TextEditingController();
  bool _submitting = false;
  bool _sealing = false;
  bool _generating = false;

  // Generated shares (shown once)
  List<String>? _generatedShares;
  int? _generatedTotal;
  int? _generatedThreshold;

  @override
  void dispose() {
    _shareController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.sealStatus;
    final statusColor = CodeOpsColors.sealStatusColors[status.status] ??
        CodeOpsColors.textTertiary;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Status indicator
        Center(
          child: Column(
            children: [
              Icon(_statusIcon(status.status), size: 56, color: statusColor),
              const SizedBox(height: 12),
              Text(
                'Vault Status: ${status.status.displayName}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _statusMessage(status.status),
                style: const TextStyle(
                  fontSize: 13,
                  color: CodeOpsColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Progress bar for unsealing
        if (status.status == SealStatus.unsealing ||
            status.status == SealStatus.sealed) ...[
          _buildProgressBar(status),
          const SizedBox(height: 16),
        ],

        // Seal info fields
        _buildInfoSection(status),
        const SizedBox(height: 20),

        // Key share input (sealed/unsealing)
        if (status.status != SealStatus.unsealed) ...[
          _buildShareInput(),
          const SizedBox(height: 20),
        ],

        // Action buttons
        _buildActions(status),

        // Generated shares display
        if (_generatedShares != null) ...[
          const SizedBox(height: 20),
          SharesDisplay(
            shares: _generatedShares!,
            totalShares: _generatedTotal!,
            threshold: _generatedThreshold!,
            onDismiss: () => setState(() => _generatedShares = null),
          ),
        ],
      ],
    );
  }

  Widget _buildProgressBar(SealStatusResponse status) {
    final progress = status.threshold > 0
        ? status.sharesProvided / status.threshold
        : 0.0;

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: CodeOpsColors.surfaceVariant,
            color: CodeOpsColors.warning,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${status.sharesProvided} of ${status.threshold} shares provided',
          style: const TextStyle(
            fontSize: 12,
            color: CodeOpsColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(SealStatusResponse status) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CodeOpsColors.surfaceVariant.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CodeOpsColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Seal Info',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: CodeOpsColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          _infoRow('Total Shares', '${status.totalShares}'),
          _infoRow('Threshold', '${status.threshold}'),
          _infoRow('Shares Provided', '${status.sharesProvided}'),
          _infoRow(
            'Auto-Unseal',
            status.autoUnsealEnabled ? 'Enabled' : 'Disabled',
          ),
          if (status.sealedAt != null)
            _infoRow('Sealed At', formatDateTime(status.sealedAt)),
          if (status.unsealedAt != null)
            _infoRow('Unsealed At', formatDateTime(status.unsealedAt)),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 140,
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

  Widget _buildShareInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CodeOpsColors.surfaceVariant.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CodeOpsColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _shareController,
              decoration: const InputDecoration(
                labelText: 'Enter Key Share',
                hintText: 'Base64-encoded key share',
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _submitting ? null : _submitShare,
            child: _submitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Submit Share'),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(SealStatusResponse status) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
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
            onPressed: _sealing ? null : _showSealConfirmation,
          ),
        OutlinedButton.icon(
          icon: const Icon(Icons.vpn_key, size: 16),
          label: const Text('Generate New Shares'),
          style: OutlinedButton.styleFrom(
            foregroundColor: CodeOpsColors.primary,
            side: const BorderSide(color: CodeOpsColors.primary),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            textStyle: const TextStyle(fontSize: 12),
          ),
          onPressed: _generating ? null : _generateShares,
        ),
      ],
    );
  }

  Future<void> _submitShare() async {
    final share = _shareController.text.trim();
    if (share.isEmpty) return;

    setState(() => _submitting = true);
    try {
      final api = ref.read(vaultApiProvider);
      await api.unsealVault(action: 'UNSEAL', keyShare: share);
      ref.invalidate(sealStatusProvider);
      _shareController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Key share submitted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit share: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _showSealConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const _SealConfirmDialog(),
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
        setState(() {
          _generatedShares = shares;
          _generatedTotal = total;
          _generatedThreshold = thresh;
        });
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

  IconData _statusIcon(SealStatus status) => switch (status) {
        SealStatus.sealed => Icons.lock,
        SealStatus.unsealed => Icons.lock_open,
        SealStatus.unsealing => Icons.hourglass_top,
      };

  String _statusMessage(SealStatus status) => switch (status) {
        SealStatus.sealed =>
          'Vault is sealed \u2014 no operations available',
        SealStatus.unsealed => 'Vault is operational',
        SealStatus.unsealing => 'Unseal in progress',
      };
}

// ---------------------------------------------------------------------------
// Seal Confirmation Dialog
// ---------------------------------------------------------------------------

class _SealConfirmDialog extends StatefulWidget {
  const _SealConfirmDialog();

  @override
  State<_SealConfirmDialog> createState() => _SealConfirmDialogState();
}

class _SealConfirmDialogState extends State<_SealConfirmDialog> {
  final _controller = TextEditingController();
  bool _valid = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: CodeOpsColors.surface,
      title: const Text('Seal Vault'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This will make ALL vault operations unavailable.',
            style: TextStyle(color: CodeOpsColors.textSecondary),
          ),
          const SizedBox(height: 12),
          const Text(
            'Type SEAL to confirm:',
            style: TextStyle(
              fontSize: 12,
              color: CodeOpsColors.textTertiary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onChanged: (value) {
              setState(() => _valid = value.trim() == 'SEAL');
            },
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
          onPressed: _valid ? () => Navigator.of(context).pop(true) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: CodeOpsColors.error,
          ),
          child: const Text('Seal'),
        ),
      ],
    );
  }
}
