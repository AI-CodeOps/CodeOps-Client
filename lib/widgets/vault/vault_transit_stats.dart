/// Summary stats bar for the transit encryption dashboard.
///
/// Displays three stat cards: total keys, active keys, and total
/// versions across all keys. Watches [vaultTransitStatsProvider]
/// for reactive updates.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/vault_providers.dart';
import '../../theme/colors.dart';

/// A horizontal row of summary statistics for transit keys.
class VaultTransitStats extends ConsumerWidget {
  /// Creates a [VaultTransitStats].
  const VaultTransitStats({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(vaultTransitStatsProvider);

    return statsAsync.when(
      loading: () => const SizedBox(
        height: 56,
        child: Center(
          child: SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 1.5),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (stats) {
        final total = stats['total'] ?? 0;
        final active = stats['active'] ?? 0;
        final versions = stats['totalVersions'] ?? 0;

        return Row(
          children: [
            _StatChip(
              icon: Icons.vpn_key_outlined,
              label: 'Keys',
              value: '$total',
              color: CodeOpsColors.primary,
            ),
            const SizedBox(width: 12),
            _StatChip(
              icon: Icons.check_circle_outline,
              label: 'Active',
              value: '$active',
              color: CodeOpsColors.success,
            ),
            const SizedBox(width: 12),
            _StatChip(
              icon: Icons.layers_outlined,
              label: 'Versions',
              value: '$versions',
              color: CodeOpsColors.secondary,
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Stat Chip
// ---------------------------------------------------------------------------

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: CodeOpsColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
