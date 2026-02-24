/// Seal configuration info card.
///
/// Displays a read-only information card with the current seal
/// configuration: status, total shares, threshold, auto-unseal,
/// and sealed/unsealed timestamps.
library;

import 'package:flutter/material.dart';

import '../../models/vault_models.dart';
import '../../theme/colors.dart';
import '../../utils/date_utils.dart';

/// An information card showing the Vault seal configuration.
///
/// Shows:
/// - Status (SEALED / UNSEALED / UNSEALING)
/// - Total Shares
/// - Threshold
/// - Auto-Unseal (Enabled / Disabled)
/// - Sealed At / Unsealed At timestamps
class VaultSealInfo extends StatelessWidget {
  /// The current seal status response.
  final SealStatusResponse sealStatus;

  /// Creates a [VaultSealInfo].
  const VaultSealInfo({super.key, required this.sealStatus});

  @override
  Widget build(BuildContext context) {
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
            'Seal Information',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: CodeOpsColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _infoRow('Status', sealStatus.status.displayName),
          _infoRow('Total Shares', '${sealStatus.totalShares}'),
          _infoRow('Threshold', '${sealStatus.threshold}'),
          _infoRow(
            'Auto-Unseal',
            sealStatus.autoUnsealEnabled ? 'Enabled' : 'Disabled',
          ),
          if (sealStatus.sealedAt != null)
            _infoRow('Sealed At', formatDateTime(sealStatus.sealedAt)),
          if (sealStatus.unsealedAt != null)
            _infoRow('Unsealed At', formatDateTime(sealStatus.unsealedAt)),
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
}
