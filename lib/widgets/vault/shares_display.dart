/// One-time display of generated Shamir key shares.
///
/// Shows a list of Base64-encoded shares with individual copy buttons,
/// a "Copy All" button, and a prominent warning that the shares
/// will not be shown again after dismissal.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/colors.dart';

/// Displays generated Shamir key shares with copy functionality and a warning.
///
/// The [shares] list contains Base64-encoded key share strings. Each share
/// is shown in a monospace font with an individual copy button. A "Copy All"
/// button is provided to copy all shares at once. A red warning banner
/// reminds the user to save shares securely before dismissing.
class SharesDisplay extends StatelessWidget {
  /// The list of Base64-encoded key share strings.
  final List<String> shares;

  /// Total number of shares generated.
  final int totalShares;

  /// Number of shares required to unseal.
  final int threshold;

  /// Called when the user dismisses the display.
  final VoidCallback onDismiss;

  /// Creates a [SharesDisplay].
  const SharesDisplay({
    super.key,
    required this.shares,
    required this.totalShares,
    required this.threshold,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CodeOpsColors.surface,
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: CodeOpsColors.warning.withValues(alpha: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Warning banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: CodeOpsColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: CodeOpsColors.error.withValues(alpha: 0.3),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    size: 18, color: CodeOpsColors.error),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'These shares will NOT be shown again. '
                    'Distribute them securely.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: CodeOpsColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Share info
          Text(
            'Total Shares: $totalShares  \u2022  Threshold: $threshold',
            style: const TextStyle(
              fontSize: 12,
              color: CodeOpsColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          // Share list
          ...shares.asMap().entries.map(
                (entry) => _ShareRow(
                  index: entry.key + 1,
                  share: entry.value,
                ),
              ),
          const SizedBox(height: 12),
          // Copy All + Dismiss
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.copy_all, size: 14),
                label: const Text('Copy All'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: CodeOpsColors.primary,
                  side: const BorderSide(color: CodeOpsColors.primary),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  textStyle: const TextStyle(fontSize: 12),
                ),
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(text: shares.join('\n')),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('All shares copied to clipboard'),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: onDismiss,
                child: const Text('Dismiss'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Share Row
// ---------------------------------------------------------------------------

class _ShareRow extends StatelessWidget {
  final int index;
  final String share;

  const _ShareRow({required this.index, required this.share});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              'Share $index',
              style: const TextStyle(
                fontSize: 11,
                color: CodeOpsColors.textTertiary,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              share,
              style: const TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: CodeOpsColors.textPrimary,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 14),
            tooltip: 'Copy share $index',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: share));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Share $index copied to clipboard')),
              );
            },
          ),
        ],
      ),
    );
  }
}
