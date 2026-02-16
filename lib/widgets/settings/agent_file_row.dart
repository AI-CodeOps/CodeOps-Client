/// Single file row in the agent detail panel's attached files section.
///
/// Displays file type icon, name, type badge, and action buttons.
library;

import 'package:flutter/material.dart';

import '../../database/database.dart';
import '../../theme/colors.dart';

/// A row representing an [AgentFile] with view/edit/delete actions.
class AgentFileRow extends StatelessWidget {
  /// The file to display.
  final AgentFile file;

  /// Called when the user taps View/Edit.
  final VoidCallback? onViewEdit;

  /// Called when the user taps Delete.
  final VoidCallback? onDelete;

  /// Creates an [AgentFileRow].
  const AgentFileRow({
    super.key,
    required this.file,
    this.onViewEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            _iconForType(file.fileType),
            size: 16,
            color: CodeOpsColors.textSecondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              file.fileName,
              style: const TextStyle(fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: CodeOpsColors.surfaceVariant,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              file.fileType,
              style: const TextStyle(
                fontSize: 10,
                color: CodeOpsColors.textTertiary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.edit_note, size: 16),
            onPressed: onViewEdit,
            tooltip: 'View / Edit',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 16),
            color: CodeOpsColors.error,
            onPressed: onDelete,
            tooltip: 'Delete',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
        ],
      ),
    );
  }

  static IconData _iconForType(String type) => switch (type) {
        'persona' => Icons.person_outline,
        'prompt' => Icons.chat_bubble_outline,
        'context' => Icons.description_outlined,
        _ => Icons.insert_drive_file_outlined,
      };
}
