/// Center panel for channel messages in the Relay module.
///
/// Displays the channel header (name, topic, member count, actions),
/// message feed area, and message composer. Currently placeholder content —
/// RLF-003 and RLF-004 will implement the real message feed and composer.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/colors.dart';

/// Message panel showing channel header, message feed, and composer.
///
/// Takes a [channelId] to identify which channel's messages to display.
/// Currently renders placeholder content until RLF-003/RLF-004.
class RelayMessagePanel extends ConsumerWidget {
  /// UUID of the channel to display messages for.
  final String channelId;

  /// Creates a [RelayMessagePanel].
  const RelayMessagePanel({required this.channelId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        _buildChannelHeader(context, ref),
        const Divider(height: 1, color: CodeOpsColors.border),
        const Expanded(
          child: Center(
            child: Text(
              'Messages will appear here',
              style: TextStyle(color: CodeOpsColors.textTertiary),
            ),
          ),
        ),
        const Divider(height: 1, color: CodeOpsColors.border),
        Container(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Message #channel...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            enabled: false, // Placeholder — enabled in RLF-004
          ),
        ),
      ],
    );
  }

  /// Builds the channel header with name, topic, member count, and actions.
  Widget _buildChannelHeader(BuildContext context, WidgetRef ref) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(
            '# channel',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: CodeOpsColors.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Channel topic will appear here',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: CodeOpsColors.textTertiary,
              ),
            ),
          ),
          _buildHeaderAction(Icons.search, 'Search'),
          _buildHeaderAction(Icons.push_pin_outlined, 'Pins'),
          _buildHeaderAction(Icons.people_outline, 'Members'),
          _buildHeaderAction(Icons.settings_outlined, 'Settings'),
        ],
      ),
    );
  }

  /// Builds a disabled header action icon button.
  Widget _buildHeaderAction(IconData icon, String tooltip) {
    return IconButton(
      icon: Icon(icon, size: 18),
      color: CodeOpsColors.textTertiary,
      onPressed: null, // Placeholder — enabled in future RLF tasks
      tooltip: tooltip,
      padding: const EdgeInsets.all(6),
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    );
  }
}
