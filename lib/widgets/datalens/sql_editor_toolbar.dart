/// Toolbar for the DataLens SQL editor.
///
/// Provides action buttons for executing, cancelling, saving, explaining,
/// and formatting SQL queries. Receives callbacks from the parent
/// [SqlEditorPanel] and displays visual feedback for running queries.
library;

import 'package:flutter/material.dart';

import '../../theme/colors.dart';

/// Toolbar displayed above the SQL editor text area.
///
/// Contains buttons for:
/// - Execute (Ctrl+Enter)
/// - Cancel (while running)
/// - Save query
/// - EXPLAIN
/// - Format SQL
/// - Query history
class SqlEditorToolbar extends StatelessWidget {
  /// Called when the Execute button is tapped.
  final VoidCallback? onExecute;

  /// Called when the Cancel button is tapped.
  final VoidCallback? onCancel;

  /// Called when the Save button is tapped.
  final VoidCallback? onSave;

  /// Called when the Explain button is tapped.
  final VoidCallback? onExplain;

  /// Called when the Format button is tapped.
  final VoidCallback? onFormat;

  /// Called when the History button is tapped.
  final VoidCallback? onHistory;

  /// Whether a query is currently running.
  final bool isRunning;

  /// Creates a [SqlEditorToolbar].
  const SqlEditorToolbar({
    super.key,
    this.onExecute,
    this.onCancel,
    this.onSave,
    this.onExplain,
    this.onFormat,
    this.onHistory,
    this.isRunning = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: CodeOpsColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          // Execute
          _ToolbarButton(
            icon: Icons.play_arrow,
            tooltip: 'Execute (Ctrl+Enter)',
            onPressed: isRunning ? null : onExecute,
            color: CodeOpsColors.success,
          ),

          // Cancel
          if (isRunning)
            _ToolbarButton(
              icon: Icons.stop,
              tooltip: 'Cancel query',
              onPressed: onCancel,
              color: CodeOpsColors.error,
            ),

          const SizedBox(width: 4),
          const _VerticalSeparator(),
          const SizedBox(width: 4),

          // Save
          _ToolbarButton(
            icon: Icons.save_outlined,
            tooltip: 'Save query (Ctrl+S)',
            onPressed: onSave,
          ),

          // Explain
          _ToolbarButton(
            icon: Icons.analytics_outlined,
            tooltip: 'EXPLAIN query plan',
            onPressed: isRunning ? null : onExplain,
          ),

          // Format
          _ToolbarButton(
            icon: Icons.format_align_left,
            tooltip: 'Format SQL (Ctrl+Shift+F)',
            onPressed: onFormat,
          ),

          const SizedBox(width: 4),
          const _VerticalSeparator(),
          const SizedBox(width: 4),

          // History
          _ToolbarButton(
            icon: Icons.history,
            tooltip: 'Query history',
            onPressed: onHistory,
          ),

          const Spacer(),

          // Running indicator
          if (isRunning) ...[
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: CodeOpsColors.primary,
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              'Running...',
              style: TextStyle(
                fontSize: 11,
                color: CodeOpsColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A single toolbar icon button.
class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color color;

  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.color = CodeOpsColors.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 18),
      tooltip: tooltip,
      onPressed: onPressed,
      color: onPressed != null ? color : CodeOpsColors.textTertiary,
      splashRadius: 16,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      padding: EdgeInsets.zero,
    );
  }
}

/// Vertical separator between toolbar button groups.
class _VerticalSeparator extends StatelessWidget {
  const _VerticalSeparator();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 20,
      child: VerticalDivider(
        width: 1,
        color: CodeOpsColors.border,
      ),
    );
  }
}
