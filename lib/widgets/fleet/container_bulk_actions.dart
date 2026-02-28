/// Bulk action bar for selected containers in the list.
///
/// Appears when one or more containers are selected via checkbox.
/// Provides Start, Stop, and Remove actions for the selected set.
library;

import 'package:flutter/material.dart';

import '../../theme/colors.dart';

/// Bulk action bar for container selection.
class ContainerBulkActions extends StatelessWidget {
  /// Number of selected containers.
  final int selectedCount;

  /// Called when the Start action is tapped.
  final VoidCallback onStart;

  /// Called when the Stop action is tapped.
  final VoidCallback onStop;

  /// Called when the Remove action is tapped.
  final VoidCallback onRemove;

  /// Creates [ContainerBulkActions].
  const ContainerBulkActions({
    super.key,
    required this.selectedCount,
    required this.onStart,
    required this.onStop,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: CodeOpsColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CodeOpsColors.border),
      ),
      child: Row(
        children: [
          Text(
            '$selectedCount selected',
            style: const TextStyle(
              color: CodeOpsColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 16),
          OutlinedButton.icon(
            onPressed: onStart,
            icon: const Icon(Icons.play_arrow, size: 16),
            label: const Text('Start'),
            style: OutlinedButton.styleFrom(
              foregroundColor: CodeOpsColors.success,
              side: const BorderSide(color: CodeOpsColors.border),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: onStop,
            icon: const Icon(Icons.stop, size: 16),
            label: const Text('Stop'),
            style: OutlinedButton.styleFrom(
              foregroundColor: CodeOpsColors.warning,
              side: const BorderSide(color: CodeOpsColors.border),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline, size: 16),
            label: const Text('Remove'),
            style: OutlinedButton.styleFrom(
              foregroundColor: CodeOpsColors.error,
              side: const BorderSide(color: CodeOpsColors.border),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
          ),
        ],
      ),
    );
  }
}
