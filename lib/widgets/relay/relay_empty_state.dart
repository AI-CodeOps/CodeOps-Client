/// Empty state widget for the Relay message center panel.
///
/// Shown when no channel or DM conversation is selected. Provides
/// a centered messaging icon with instructional text and placeholder
/// quick-action buttons.
library;

import 'package:flutter/material.dart';

import '../../theme/colors.dart';

/// Centered empty state shown when no channel or DM is selected.
///
/// Displays a messaging icon, instructional text, and two disabled
/// quick-action buttons that will be enabled in future RLF tasks.
class RelayEmptyState extends StatelessWidget {
  /// Creates a [RelayEmptyState].
  const RelayEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.forum_outlined,
            size: 64,
            color: CodeOpsColors.textTertiary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'Select a channel or conversation to start messaging',
            style: TextStyle(
              fontSize: 14,
              color: CodeOpsColors.textTertiary,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton.icon(
                onPressed: null, // Placeholder — RLF-002
                icon: const Icon(Icons.tag, size: 16),
                label: const Text('Browse Channels'),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: null, // Placeholder — RLF-006
                icon: const Icon(Icons.chat_bubble_outline, size: 16),
                label: const Text('Start a DM'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
