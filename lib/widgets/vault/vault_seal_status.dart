/// Prominent seal status indicator for the Vault seal page.
///
/// Displays a large icon and message that changes color and text based on
/// the current seal state: SEALED (red), UNSEALED (green), or UNSEALING
/// (amber). Watches both the one-shot and polling seal status providers
/// for live updates.
library;

import 'package:flutter/material.dart';

import '../../models/vault_enums.dart';
import '../../models/vault_models.dart';
import '../../theme/colors.dart';

/// A prominent visual indicator of the current Vault seal state.
///
/// - **UNSEALED:** Green lock-open icon, "Vault is Unsealed"
/// - **SEALED:** Red lock icon, "Vault is Sealed — All operations unavailable"
/// - **UNSEALING:** Amber lock icon, "Unsealing in progress — N of M shares"
class VaultSealStatus extends StatelessWidget {
  /// The current seal status.
  final SealStatusResponse sealStatus;

  /// Creates a [VaultSealStatus].
  const VaultSealStatus({super.key, required this.sealStatus});

  @override
  Widget build(BuildContext context) {
    final color = CodeOpsColors.sealStatusColors[sealStatus.status] ??
        CodeOpsColors.textTertiary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(_icon, size: 56, color: color),
          const SizedBox(height: 12),
          Text(
            _title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: CodeOpsColors.textSecondary,
            ),
          ),
          // Progress bar for sealed/unsealing
          if (sealStatus.status != SealStatus.unsealed) ...[
            const SizedBox(height: 16),
            _buildProgressBar(color),
          ],
        ],
      ),
    );
  }

  IconData get _icon => switch (sealStatus.status) {
        SealStatus.sealed => Icons.lock,
        SealStatus.unsealed => Icons.lock_open,
        SealStatus.unsealing => Icons.hourglass_top,
      };

  String get _title => switch (sealStatus.status) {
        SealStatus.sealed => 'Vault is Sealed',
        SealStatus.unsealed => 'Vault is Unsealed',
        SealStatus.unsealing => 'Unsealing in Progress',
      };

  String get _subtitle => switch (sealStatus.status) {
        SealStatus.sealed =>
          'All vault operations are unavailable until unsealed.',
        SealStatus.unsealed => 'Vault is operational. All services available.',
        SealStatus.unsealing =>
          '${sealStatus.sharesProvided} of ${sealStatus.threshold} '
              'shares entered.',
      };

  Widget _buildProgressBar(Color color) {
    final progress = sealStatus.threshold > 0
        ? sealStatus.sharesProvided / sealStatus.threshold
        : 0.0;

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: CodeOpsColors.surfaceVariant,
            color: color,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${sealStatus.sharesProvided} of ${sealStatus.threshold} '
          'shares provided',
          style: const TextStyle(
            fontSize: 12,
            color: CodeOpsColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
