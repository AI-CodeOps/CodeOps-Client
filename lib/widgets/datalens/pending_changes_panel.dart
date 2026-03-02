/// Bottom panel showing staged data changes for the DataLens data editor.
///
/// Displays a list of pending changes (edits, inserts, deletes) with
/// per-change revert buttons and a toolbar for applying or reverting all.
/// The panel appears when there are pending changes and can be collapsed.
library;

import 'package:flutter/material.dart';

import '../../services/datalens/data_editor_service.dart';
import '../../theme/colors.dart';

/// A collapsible bottom panel that shows pending data changes.
///
/// Displays a header with change count badge, Apply All and Revert All
/// buttons, and a scrollable list of individual changes with per-item
/// revert.
class PendingChangesPanel extends StatelessWidget {
  /// The list of pending row changes to display.
  final List<RowChange> changes;

  /// Called when the user taps Apply All.
  final VoidCallback? onApplyAll;

  /// Called when the user taps Revert All.
  final VoidCallback? onRevertAll;

  /// Called when the user taps Revert on a specific change by index.
  final ValueChanged<int>? onRevertChange;

  /// Creates a [PendingChangesPanel].
  const PendingChangesPanel({
    super.key,
    required this.changes,
    this.onApplyAll,
    this.onRevertAll,
    this.onRevertChange,
  });

  @override
  Widget build(BuildContext context) {
    if (changes.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: const BoxDecoration(
        color: CodeOpsColors.surface,
        border: Border(
          top: BorderSide(color: CodeOpsColors.border),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          const Divider(height: 1, color: CodeOpsColors.border),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 150),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: changes.length,
              itemBuilder: (context, index) =>
                  _buildChangeItem(changes[index], index),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the header with change count badge and action buttons.
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          const Icon(
            Icons.edit_note,
            size: 14,
            color: CodeOpsColors.warning,
          ),
          const SizedBox(width: 4),
          const Text(
            'Pending Changes',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: CodeOpsColors.textPrimary,
            ),
          ),
          const SizedBox(width: 6),

          // Change count badge.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: CodeOpsColors.warning.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${changes.length}',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: CodeOpsColors.warning,
              ),
            ),
          ),

          const Spacer(),

          // Apply All button.
          _ActionButton(
            label: 'Apply All',
            icon: Icons.check,
            color: CodeOpsColors.success,
            onPressed: onApplyAll,
          ),
          const SizedBox(width: 4),

          // Revert All button.
          _ActionButton(
            label: 'Revert All',
            icon: Icons.undo,
            color: CodeOpsColors.error,
            onPressed: onRevertAll,
          ),
        ],
      ),
    );
  }

  /// Builds a single change list item.
  Widget _buildChangeItem(RowChange change, int index) {
    final icon = _changeIcon(change.type);
    final color = _changeColor(change.type);
    final label = _changeLabel(change);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      color: index % 2 == 0
          ? Colors.transparent
          : CodeOpsColors.surfaceVariant.withValues(alpha: 0.3),
      child: Row(
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Text(
            _changeTypeLabel(change.type),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: CodeOpsColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Per-change revert button.
          InkWell(
            onTap: onRevertChange != null ? () => onRevertChange!(index) : null,
            borderRadius: BorderRadius.circular(4),
            child: const Padding(
              padding: EdgeInsets.all(2),
              child: Icon(
                Icons.close,
                size: 12,
                color: CodeOpsColors.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Returns the icon for a change type.
  IconData _changeIcon(RowChangeType type) {
    return switch (type) {
      RowChangeType.update => Icons.edit,
      RowChangeType.insert => Icons.add_circle_outline,
      RowChangeType.delete => Icons.remove_circle_outline,
      RowChangeType.duplicate => Icons.copy,
    };
  }

  /// Returns the color for a change type.
  Color _changeColor(RowChangeType type) {
    return switch (type) {
      RowChangeType.update => CodeOpsColors.warning,
      RowChangeType.insert => CodeOpsColors.success,
      RowChangeType.delete => CodeOpsColors.error,
      RowChangeType.duplicate => CodeOpsColors.secondary,
    };
  }

  /// Returns the label for a change type.
  String _changeTypeLabel(RowChangeType type) {
    return switch (type) {
      RowChangeType.update => 'UPDATE',
      RowChangeType.insert => 'INSERT',
      RowChangeType.delete => 'DELETE',
      RowChangeType.duplicate => 'DUPLICATE',
    };
  }

  /// Builds a summary label for a change.
  String _changeLabel(RowChange change) {
    switch (change.type) {
      case RowChangeType.update:
        final cols = change.cellChanges.map((c) => c.columnName).join(', ');
        final key = change.rowKey?.values.entries
                .map((e) => '${e.key}=${e.value}')
                .join(', ') ??
            '?';
        return '[$key] → $cols';
      case RowChangeType.insert:
      case RowChangeType.duplicate:
        final cols = change.rowData?.keys.take(3).join(', ') ?? '';
        final suffix = (change.rowData?.length ?? 0) > 3 ? '...' : '';
        return '($cols$suffix)';
      case RowChangeType.delete:
        final key = change.rowKey?.values.entries
                .map((e) => '${e.key}=${e.value}')
                .join(', ') ??
            '?';
        return '[$key]';
    }
  }
}

/// Compact action button used in the panel header.
class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = onPressed != null ? color : CodeOpsColors.textTertiary;

    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: effectiveColor),
              const SizedBox(width: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
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
