/// Left sidebar panel for the Relay messaging module.
///
/// Displays sections for Channels and Direct Messages with expand/collapse
/// headers, add buttons, and selection highlighting. Placeholder content
/// is shown until RLF-002 and RLF-006 implement real data binding.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/relay_providers.dart';
import '../../theme/colors.dart';

/// Sidebar listing channels and direct message conversations.
///
/// Calls [onChannelSelected] or [onConversationSelected] when the user
/// taps a channel or DM entry, allowing the parent [RelayPage] to update
/// route and provider state.
class RelaySidebar extends ConsumerWidget {
  /// Called when the user selects a channel.
  final ValueChanged<String> onChannelSelected;

  /// Called when the user selects a direct conversation.
  final ValueChanged<String> onConversationSelected;

  /// Creates a [RelaySidebar].
  const RelaySidebar({
    required this.onChannelSelected,
    required this.onConversationSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedChannel = ref.watch(selectedChannelIdProvider);
    ref.watch(selectedConversationIdProvider);

    return Container(
      color: CodeOpsColors.surface,
      child: Column(
        children: [
          _buildHeader(context),
          const Divider(height: 1, color: CodeOpsColors.border),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _RelaySectionHeader(
                  title: 'CHANNELS',
                  onAdd: () {
                    // RLF-002 will implement create channel dialog
                  },
                ),
                _RelaySidebarItem(
                  label: '# general',
                  selected: selectedChannel == 'placeholder-general',
                  unreadCount: 0,
                  onTap: () => onChannelSelected('placeholder-general'),
                ),
                _RelaySidebarItem(
                  label: '# engineering',
                  selected: selectedChannel == 'placeholder-engineering',
                  unreadCount: 0,
                  onTap: () => onChannelSelected('placeholder-engineering'),
                ),
                _RelaySidebarItem(
                  label: '# random',
                  selected: selectedChannel == 'placeholder-random',
                  unreadCount: 0,
                  onTap: () => onChannelSelected('placeholder-random'),
                ),
                const SizedBox(height: 16),
                _RelaySectionHeader(
                  title: 'DIRECT MESSAGES',
                  onAdd: () {
                    // RLF-006 will implement new DM dialog
                  },
                ),
                _RelaySidebarItem(
                  label: 'No conversations yet',
                  selected: false,
                  unreadCount: 0,
                  onTap: () {},
                  enabled: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the sidebar header with the team/module name.
  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: const Row(
        children: [
          Icon(Icons.forum_outlined, size: 20, color: CodeOpsColors.primary),
          SizedBox(width: 10),
          Text(
            'Relay',
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

/// Expandable section header with title and add button.
class _RelaySectionHeader extends StatefulWidget {
  final String title;
  final VoidCallback onAdd;

  const _RelaySectionHeader({required this.title, required this.onAdd});

  @override
  State<_RelaySectionHeader> createState() => _RelaySectionHeaderState();
}

class _RelaySectionHeaderState extends State<_RelaySectionHeader> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 8, top: 4, bottom: 2),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Icon(
              _expanded ? Icons.expand_more : Icons.chevron_right,
              size: 16,
              color: CodeOpsColors.textTertiary,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: CodeOpsColors.textTertiary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 24,
            height: 24,
            child: IconButton(
              icon: const Icon(Icons.add, size: 14),
              color: CodeOpsColors.textTertiary,
              padding: EdgeInsets.zero,
              onPressed: widget.onAdd,
              tooltip: 'Add',
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual channel or DM list item with selection and unread badge.
class _RelaySidebarItem extends StatelessWidget {
  final String label;
  final bool selected;
  final int unreadCount;
  final VoidCallback onTap;
  final bool enabled;

  const _RelaySidebarItem({
    required this.label,
    required this.selected,
    required this.unreadCount,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      decoration: BoxDecoration(
        color: selected
            ? CodeOpsColors.primary.withValues(alpha: 0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          (selected || unreadCount > 0) ? FontWeight.w600 : FontWeight.w400,
                      color: enabled
                          ? (selected
                              ? CodeOpsColors.textPrimary
                              : CodeOpsColors.textSecondary)
                          : CodeOpsColors.textTertiary,
                    ),
                  ),
                ),
                if (unreadCount > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: CodeOpsColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$unreadCount',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
