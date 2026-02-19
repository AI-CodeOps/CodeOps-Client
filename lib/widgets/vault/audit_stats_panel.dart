/// Compact audit statistics panel for the Vault audit log tab.
///
/// Displays total entries, success rate, and top operations from
/// [vaultAuditStatsProvider] in a compact row of stat chips.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/vault_providers.dart';
import '../../theme/colors.dart';

/// Displays compact audit log statistics.
///
/// Shows total entries, success rate percentage, and counts for
/// read/write/delete operations in a horizontal row of chips.
class AuditStatsPanel extends ConsumerWidget {
  /// Creates an [AuditStatsPanel].
  const AuditStatsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(vaultAuditStatsProvider);

    return statsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (stats) {
        final total = stats['totalEntries'] ?? 0;
        final failed = stats['failedEntries'] ?? 0;
        final reads = stats['readOperations'] ?? 0;
        final writes = stats['writeOperations'] ?? 0;
        final deletes = stats['deleteOperations'] ?? 0;
        final successRate =
            total > 0 ? ((total - failed) / total * 100).toStringAsFixed(1) : '0';

        return Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _StatChip(
              label: 'Total',
              value: '$total',
              color: CodeOpsColors.primary,
            ),
            _StatChip(
              label: 'Success',
              value: '$successRate%',
              color: CodeOpsColors.success,
            ),
            _StatChip(
              label: 'Reads',
              value: '$reads',
              color: const Color(0xFF3B82F6),
            ),
            _StatChip(
              label: 'Writes',
              value: '$writes',
              color: CodeOpsColors.secondary,
            ),
            _StatChip(
              label: 'Deletes',
              value: '$deletes',
              color: CodeOpsColors.error,
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
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
