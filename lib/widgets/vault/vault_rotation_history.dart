/// Rotation history timeline for a selected secret.
///
/// Displays a paginated, reverse-chronological list of
/// [RotationHistoryResponse] entries for a given secret ID.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/vault_models.dart';
import '../../providers/vault_providers.dart';
import '../../theme/colors.dart';
import '../../widgets/shared/error_panel.dart';

/// A timeline view of rotation history entries for a [secretId].
class VaultRotationHistory extends ConsumerWidget {
  /// The secret whose rotation history is shown.
  final String secretId;

  /// Creates a [VaultRotationHistory].
  const VaultRotationHistory({super.key, required this.secretId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(vaultRotationHistoryProvider(secretId));

    return historyAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (e, _) => ErrorPanel.fromException(
        e,
        onRetry: () => ref.invalidate(vaultRotationHistoryProvider(secretId)),
      ),
      data: (page) {
        if (page.content.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No rotation history',
                style: TextStyle(
                  fontSize: 13,
                  color: CodeOpsColors.textTertiary,
                ),
              ),
            ),
          );
        }
        return _buildTimeline(page.content);
      },
    );
  }

  Widget _buildTimeline(List<RotationHistoryResponse> entries) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return _HistoryEntry(entry: entry, isLast: index == entries.length - 1);
      },
    );
  }
}

// ---------------------------------------------------------------------------
// History Entry
// ---------------------------------------------------------------------------

class _HistoryEntry extends StatelessWidget {
  final RotationHistoryResponse entry;
  final bool isLast;

  const _HistoryEntry({required this.entry, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final isSuccess = entry.success;
    final color = isSuccess ? CodeOpsColors.success : CodeOpsColors.error;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: CodeOpsColors.border,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: CodeOpsColors.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: CodeOpsColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status + strategy
                    Row(
                      children: [
                        Icon(
                          isSuccess
                              ? Icons.check_circle
                              : Icons.cancel,
                          size: 14,
                          color: color,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isSuccess ? 'Success' : 'Failed',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: CodeOpsColors.rotationStrategyColors[
                                        entry.strategy]
                                    ?.withValues(alpha: 0.1) ??
                                CodeOpsColors.surface,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            entry.strategy.displayName,
                            style: TextStyle(
                              fontSize: 10,
                              color:
                                  CodeOpsColors.rotationStrategyColors[
                                      entry.strategy],
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (entry.durationMs != null)
                          Text(
                            '${entry.durationMs}ms',
                            style: const TextStyle(
                              fontSize: 10,
                              color: CodeOpsColors.textTertiary,
                              fontFamily: 'monospace',
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Version change
                    if (entry.previousVersion != null ||
                        entry.newVersion != null)
                      Text(
                        'v${entry.previousVersion ?? "?"} → '
                        'v${entry.newVersion ?? "?"}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: CodeOpsColors.textSecondary,
                          fontFamily: 'monospace',
                        ),
                      ),
                    // Error message
                    if (entry.errorMessage != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        entry.errorMessage!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: CodeOpsColors.error,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    // Timestamp
                    if (entry.createdAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _formatTimestamp(entry.createdAt!),
                        style: const TextStyle(
                          fontSize: 10,
                          color: CodeOpsColors.textTertiary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Formats a DateTime to a readable string.
  static String _formatTimestamp(DateTime dt) {
    final d = dt.toLocal();
    return '${d.year}-${_p(d.month)}-${_p(d.day)} '
        '${_p(d.hour)}:${_p(d.minute)}:${_p(d.second)}';
  }

  /// Zero-pads a number to 2 digits.
  static String _p(int n) => n.toString().padLeft(2, '0');
}
