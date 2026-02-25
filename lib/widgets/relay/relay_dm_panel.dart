/// Center panel for direct messages in the Relay module.
///
/// Displays the conversation header (participant names), message feed area,
/// and message composer. Currently placeholder content — RLF-006 will
/// implement the real DM message feed and composer.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/colors.dart';

/// DM panel showing conversation header, message feed, and composer.
///
/// Takes a [conversationId] to identify which conversation to display.
/// Currently renders placeholder content until RLF-006.
class RelayDmPanel extends ConsumerWidget {
  /// UUID of the direct conversation to display.
  final String conversationId;

  /// Creates a [RelayDmPanel].
  const RelayDmPanel({required this.conversationId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        _buildHeader(context),
        const Divider(height: 1, color: CodeOpsColors.border),
        const Expanded(
          child: Center(
            child: Text(
              'Direct messages will appear here',
              style: TextStyle(color: CodeOpsColors.textTertiary),
            ),
          ),
        ),
        const Divider(height: 1, color: CodeOpsColors.border),
        Container(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Message...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            enabled: false, // Placeholder — enabled in RLF-006
          ),
        ),
      ],
    );
  }

  /// Builds the conversation header with participant names.
  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: const Row(
        children: [
          Icon(Icons.person_outline, size: 20, color: CodeOpsColors.textSecondary),
          SizedBox(width: 8),
          Text(
            'Direct Message',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: CodeOpsColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
