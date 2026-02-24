/// Compact activity feed of recent rotation events for a secret.
///
/// Displays the most recent rotation history entries in a
/// condensed list format suitable for a dashboard sidebar.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/vault_models.dart';
import '../../providers/vault_providers.dart';
import '../../theme/colors.dart';
import '../../widgets/shared/error_panel.dart';

/// A compact activity feed showing recent rotation events for [secretId].
class VaultRotationActivityFeed extends ConsumerWidget {
  /// The secret whose activity is shown.
  final String secretId;

  /// Creates a [VaultRotationActivityFeed].
  const VaultRotationActivityFeed({super.key, required this.secretId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(vaultRotationHistoryProvider(secretId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Recent Activity',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: CodeOpsColors.textPrimary,
            ),
          ),
        ),
        const Divider(height: 1, color: CodeOpsColors.border),
        Expanded(
          child: historyAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            error: (e, _) => ErrorPanel.fromException(
              e,
              onRetry: () =>
                  ref.invalidate(vaultRotationHistoryProvider(secretId)),
            ),
            data: (page) {
              if (page.content.isEmpty) {
                return const Center(
                  child: Text(
                    'No activity yet',
                    style: TextStyle(
                      fontSize: 12,
                      color: CodeOpsColors.textTertiary,
                    ),
                  ),
                );
              }
              // Show up to 10 recent entries.
              final entries = page.content.take(10).toList();
              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: entries.length,
                separatorBuilder: (_, __) => const Divider(
                  height: 1,
                  color: CodeOpsColors.border,
                ),
                itemBuilder: (_, i) => _ActivityItem(entry: entries[i]),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Activity Item
// ---------------------------------------------------------------------------

class _ActivityItem extends StatelessWidget {
  final RotationHistoryResponse entry;

  const _ActivityItem({required this.entry});

  @override
  Widget build(BuildContext context) {
    final color =
        entry.success ? CodeOpsColors.success : CodeOpsColors.error;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Icon(
            entry.success ? Icons.check_circle : Icons.cancel,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.success ? 'Rotation succeeded' : 'Rotation failed',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
                if (entry.createdAt != null)
                  Text(
                    _timeAgo(entry.createdAt!),
                    style: const TextStyle(
                      fontSize: 10,
                      color: CodeOpsColors.textTertiary,
                    ),
                  ),
              ],
            ),
          ),
          if (entry.newVersion != null)
            Text(
              'v${entry.newVersion}',
              style: const TextStyle(
                fontSize: 10,
                fontFamily: 'monospace',
                color: CodeOpsColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }

  /// Produces a relative time string (e.g., "5m ago", "2h ago").
  static String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
