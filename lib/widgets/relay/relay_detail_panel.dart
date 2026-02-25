/// Right detail panel for the Relay module.
///
/// Shows thread replies or member list depending on context.
/// Currently placeholder content — RLF-005 will implement threads
/// and member list views.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/colors.dart';

/// Collapsible right panel for thread replies or member list.
///
/// Calls [onClose] when the user taps the close button, allowing
/// the parent [RelayPage] to hide the panel and clear thread state.
class RelayDetailPanel extends ConsumerWidget {
  /// Called when the user closes the panel.
  final VoidCallback onClose;

  /// Creates a [RelayDetailPanel].
  const RelayDetailPanel({required this.onClose, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: CodeOpsColors.surface,
      child: Column(
        children: [
          _buildHeader(context),
          const Divider(height: 1, color: CodeOpsColors.border),
          const Expanded(
            child: Center(
              child: Text(
                'Thread content will appear here',
                style: TextStyle(color: CodeOpsColors.textTertiary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the panel header with title and close button.
  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Text(
            'Thread',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: CodeOpsColors.textPrimary,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            color: CodeOpsColors.textSecondary,
            onPressed: onClose,
            tooltip: 'Close',
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}
