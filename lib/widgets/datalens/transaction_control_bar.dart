/// Transaction control bar for the DataLens SQL editor.
///
/// Provides auto-commit toggle, COMMIT/ROLLBACK buttons, and a
/// transaction status indicator. When auto-commit is ON (default),
/// every statement auto-commits and manual controls are hidden.
/// When auto-commit is OFF, users can manually COMMIT or ROLLBACK.
library;

import 'package:flutter/material.dart';

import '../../theme/colors.dart';

/// A compact toolbar row for controlling transactions.
///
/// Layout when auto-commit is ON:
/// ```
/// [Auto-commit: ON toggle]                          [Auto-commit]
/// ```
///
/// Layout when auto-commit is OFF:
/// ```
/// [Auto-commit: OFF toggle]  [COMMIT] [ROLLBACK]    [Transaction active]
/// ```
class TransactionControlBar extends StatelessWidget {
  /// Whether auto-commit mode is enabled.
  final bool autoCommit;

  /// Called when the auto-commit toggle changes.
  final ValueChanged<bool>? onAutoCommitChanged;

  /// Whether a transaction is currently active.
  final bool transactionActive;

  /// Called when the COMMIT button is tapped.
  final VoidCallback? onCommit;

  /// Called when the ROLLBACK button is tapped.
  final VoidCallback? onRollback;

  /// Creates a [TransactionControlBar].
  const TransactionControlBar({
    super.key,
    this.autoCommit = true,
    this.onAutoCommitChanged,
    this.transactionActive = false,
    this.onCommit,
    this.onRollback,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: CodeOpsColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Row(
        children: [
          // Auto-commit toggle
          const Icon(
            Icons.sync_alt,
            size: 14,
            color: CodeOpsColors.textSecondary,
          ),
          const SizedBox(width: 4),
          const Text(
            'Auto-commit',
            style: TextStyle(
              fontSize: 11,
              color: CodeOpsColors.textSecondary,
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            height: 20,
            width: 32,
            child: FittedBox(
              fit: BoxFit.contain,
              child: Switch(
                value: autoCommit,
                onChanged: onAutoCommitChanged,
                activeThumbColor: CodeOpsColors.success,
                inactiveThumbColor: CodeOpsColors.textTertiary,
                inactiveTrackColor: CodeOpsColors.border,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),

          // Manual transaction controls (visible only when auto-commit OFF)
          if (!autoCommit) ...[
            const SizedBox(width: 8),
            const _VerticalSeparator(),
            const SizedBox(width: 8),

            // COMMIT button
            _TransactionButton(
              label: 'COMMIT',
              icon: Icons.check_circle_outline,
              color: CodeOpsColors.success,
              onPressed: transactionActive ? onCommit : null,
              tooltip: 'Commit transaction',
            ),
            const SizedBox(width: 4),

            // ROLLBACK button
            _TransactionButton(
              label: 'ROLLBACK',
              icon: Icons.cancel_outlined,
              color: CodeOpsColors.error,
              onPressed: transactionActive ? onRollback : null,
              tooltip: 'Rollback transaction',
            ),
          ],

          const Spacer(),

          // Transaction status indicator
          if (!autoCommit) _buildStatusIndicator(),
        ],
      ),
    );
  }

  /// Builds the transaction status indicator badge.
  Widget _buildStatusIndicator() {
    final color = transactionActive
        ? CodeOpsColors.warning
        : CodeOpsColors.textTertiary;
    final text = transactionActive
        ? 'Transaction active'
        : 'No transaction';
    final icon = transactionActive
        ? Icons.pending_outlined
        : Icons.check_circle_outline;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(fontSize: 11, color: color),
        ),
      ],
    );
  }
}

/// A compact button for COMMIT/ROLLBACK actions.
class _TransactionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;
  final String tooltip;

  const _TransactionButton({
    required this.label,
    required this.icon,
    required this.color,
    this.onPressed,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = onPressed != null
        ? color
        : CodeOpsColors.textTertiary;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: effectiveColor),
              const SizedBox(width: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: effectiveColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Vertical separator between control groups.
class _VerticalSeparator extends StatelessWidget {
  const _VerticalSeparator();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 16,
      child: VerticalDivider(
        width: 1,
        color: CodeOpsColors.border,
      ),
    );
  }
}
