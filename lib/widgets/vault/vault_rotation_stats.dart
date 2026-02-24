/// Rotation statistics cards for a selected secret.
///
/// Displays four metric cards: total rotations, successful, failed,
/// and average duration, fetched from [vaultRotationStatsProvider].
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/vault_providers.dart';
import '../../theme/colors.dart';

/// A row of four rotation stat cards for a given [secretId].
class VaultRotationStats extends ConsumerWidget {
  /// The secret whose rotation stats are displayed.
  final String secretId;

  /// Creates a [VaultRotationStats].
  const VaultRotationStats({super.key, required this.secretId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(vaultRotationStatsProvider(secretId));

    return statsAsync.when(
      loading: () => const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (stats) => Row(
        children: [
          Expanded(
            child: _StatCard(
              label: 'Total',
              value: '${stats['total'] ?? 0}',
              icon: Icons.autorenew,
              color: CodeOpsColors.primary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatCard(
              label: 'Successful',
              value: '${stats['successful'] ?? 0}',
              icon: Icons.check_circle_outline,
              color: CodeOpsColors.success,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatCard(
              label: 'Failed',
              value: '${stats['failed'] ?? 0}',
              icon: Icons.error_outline,
              color: CodeOpsColors.error,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatCard(
              label: 'Avg Duration',
              value: _formatDuration(stats['averageDurationMs']),
              icon: Icons.timer_outlined,
              color: CodeOpsColors.secondary,
            ),
          ),
        ],
      ),
    );
  }

  /// Formats milliseconds to a human-readable duration.
  static String _formatDuration(int? ms) {
    if (ms == null || ms == 0) return '\u2014';
    if (ms < 1000) return '${ms}ms';
    return '${(ms / 1000).toStringAsFixed(1)}s';
  }
}

// ---------------------------------------------------------------------------
// Stat Card
// ---------------------------------------------------------------------------

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: CodeOpsColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CodeOpsColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: CodeOpsColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
