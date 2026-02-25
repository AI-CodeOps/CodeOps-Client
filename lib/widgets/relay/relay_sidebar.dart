/// Channel and conversation sidebar for the Relay messaging module.
///
/// Displays categorized channel lists (Channels, Direct Messages)
/// with unread badges, search/filter, and channel management actions.
/// Replaces the placeholder sidebar from RLF-001 with fully wired data.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/relay_models.dart';
import '../../providers/relay_providers.dart';
import '../../providers/team_providers.dart';
import '../../theme/colors.dart';
import '../../widgets/shared/error_panel.dart';
import 'browse_channels_dialog.dart';
import 'channel_list_tile.dart';
import 'create_channel_dialog.dart';
import 'dm_list_tile.dart';
import 'new_dm_dialog.dart';

/// Channel and conversation sidebar for the Relay messaging module.
///
/// Displays categorized channel lists (Channels, Direct Messages)
/// with unread badges, and provides channel management actions.
class RelaySidebar extends ConsumerStatefulWidget {
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
  ConsumerState<RelaySidebar> createState() => _RelaySidebarState();
}

class _RelaySidebarState extends ConsumerState<RelaySidebar> {
  bool _channelsExpanded = true;
  bool _dmsExpanded = true;
  String _filterQuery = '';
  Timer? _debounceTimer;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// Resolves the current team ID from the selected team provider.
  String? _resolveTeamId(WidgetRef ref) {
    return ref.watch(selectedTeamIdProvider);
  }

  /// Handles search input with 300ms debounce.
  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _filterQuery = value.trim().toLowerCase());
      }
    });
  }

  /// Builds the unread count lookup map from the unread counts response.
  Map<String, int> _buildUnreadMap(List<UnreadCountResponse>? counts) {
    if (counts == null) return {};
    final map = <String, int>{};
    for (final c in counts) {
      if (c.channelId != null && (c.unreadCount ?? 0) > 0) {
        map[c.channelId!] = c.unreadCount!;
      }
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final teamId = _resolveTeamId(ref);

    if (teamId == null) {
      return Container(
        color: CodeOpsColors.surface,
        child: const Center(
          child: Text(
            'Select a team to view channels',
            style: TextStyle(
              fontSize: 13,
              color: CodeOpsColors.textTertiary,
            ),
          ),
        ),
      );
    }

    final channelsAsync = ref.watch(teamChannelsProvider(teamId));
    final conversationsAsync = ref.watch(conversationsProvider(teamId));
    final unreadCountsAsync = ref.watch(unreadCountsProvider(teamId));
    final selectedChannel = ref.watch(selectedChannelIdProvider);
    final selectedConversation = ref.watch(selectedConversationIdProvider);

    return Container(
      color: CodeOpsColors.surface,
      child: Column(
        children: [
          _buildHeader(context, teamId),
          _buildSearchBar(context),
          const Divider(height: 1, color: CodeOpsColors.border),
          Expanded(
            child: channelsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorPanel.fromException(
                e,
                onRetry: () => ref.invalidate(teamChannelsProvider(teamId)),
              ),
              data: (channelsPage) => _buildChannelList(
                context,
                channelsPage.content,
                conversationsAsync,
                unreadCountsAsync,
                selectedChannel,
                selectedConversation,
                teamId,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the sidebar header with the team name and compose button.
  Widget _buildHeader(BuildContext context, String teamId) {
    final teamAsync = ref.watch(selectedTeamProvider);

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: CodeOpsColors.surfaceVariant,
      child: Row(
        children: [
          const Icon(Icons.forum_outlined,
              size: 20, color: CodeOpsColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              teamAsync.valueOrNull?.name ?? 'Relay',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: CodeOpsColors.textPrimary,
              ),
            ),
          ),
          SizedBox(
            width: 28,
            height: 28,
            child: IconButton(
              icon: const Icon(Icons.edit_outlined, size: 16),
              color: CodeOpsColors.textTertiary,
              padding: EdgeInsets.zero,
              onPressed: () => _showNewDmDialog(context, teamId),
              tooltip: 'New message',
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the search/filter bar.
  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SizedBox(
        height: 32,
        child: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          style: const TextStyle(
              fontSize: 12, color: CodeOpsColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Filter channels...',
            hintStyle: const TextStyle(
                fontSize: 12, color: CodeOpsColors.textTertiary),
            prefixIcon: const Icon(Icons.search,
                size: 16, color: CodeOpsColors.textTertiary),
            prefixIconConstraints:
                const BoxConstraints(minWidth: 32, minHeight: 16),
            suffixIcon: _filterQuery.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() => _filterQuery = '');
                    },
                    child: const Icon(Icons.close,
                        size: 14, color: CodeOpsColors.textTertiary),
                  )
                : null,
            suffixIconConstraints:
                const BoxConstraints(minWidth: 28, minHeight: 14),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide:
                  const BorderSide(color: CodeOpsColors.border, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide:
                  const BorderSide(color: CodeOpsColors.border, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide:
                  const BorderSide(color: CodeOpsColors.primary, width: 1),
            ),
            filled: true,
            fillColor: CodeOpsColors.background,
          ),
        ),
      ),
    );
  }

  /// Builds the scrollable channel + DM list content.
  Widget _buildChannelList(
    BuildContext context,
    List<ChannelSummaryResponse> channels,
    AsyncValue<List<DirectConversationSummaryResponse>> conversationsAsync,
    AsyncValue<List<UnreadCountResponse>> unreadCountsAsync,
    String? selectedChannel,
    String? selectedConversation,
    String teamId,
  ) {
    final unreadMap = _buildUnreadMap(unreadCountsAsync.valueOrNull);

    // Filter channels: non-archived, matching search query
    var filteredChannels = channels
        .where((c) => c.isArchived != true)
        .toList()
      ..sort((a, b) =>
          (a.name ?? '').toLowerCase().compareTo((b.name ?? '').toLowerCase()));

    if (_filterQuery.isNotEmpty) {
      filteredChannels = filteredChannels
          .where((c) =>
              (c.name ?? '').toLowerCase().contains(_filterQuery))
          .toList();
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        // ── Channels section ──
        _SectionHeader(
          title: 'CHANNELS',
          expanded: _channelsExpanded,
          onToggle: () =>
              setState(() => _channelsExpanded = !_channelsExpanded),
          onAdd: () => _showCreateChannelDialog(context, teamId),
        ),
        if (_channelsExpanded) ...[
          for (final channel in filteredChannels)
            ChannelListTile(
              channel: channel,
              isSelected: selectedChannel == channel.id,
              unreadCount: channel.unreadCount ??
                  (unreadMap[channel.id] ?? 0),
              onTap: () {
                if (channel.id != null) {
                  widget.onChannelSelected(channel.id!);
                }
              },
            ),
          _buildBrowseChannelsLink(context, teamId),
        ],

        const SizedBox(height: 12),

        // ── Direct Messages section ──
        _SectionHeader(
          title: 'DIRECT MESSAGES',
          expanded: _dmsExpanded,
          onToggle: () => setState(() => _dmsExpanded = !_dmsExpanded),
          onAdd: () => _showNewDmDialog(context, teamId),
        ),
        if (_dmsExpanded) ...[
          conversationsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            error: (_, __) => const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Failed to load conversations',
                style: TextStyle(
                    fontSize: 12, color: CodeOpsColors.textTertiary),
              ),
            ),
            data: (conversations) {
              var filtered = conversations;
              if (_filterQuery.isNotEmpty) {
                filtered = conversations.where((c) {
                  final name =
                      c.name?.toLowerCase() ?? '';
                  final participants =
                      (c.participantDisplayNames ?? [])
                          .join(' ')
                          .toLowerCase();
                  return name.contains(_filterQuery) ||
                      participants.contains(_filterQuery);
                }).toList();
              }

              // Sort by lastMessageAt descending
              filtered.sort((a, b) {
                final aTime = a.lastMessageAt ?? DateTime(2000);
                final bTime = b.lastMessageAt ?? DateTime(2000);
                return bTime.compareTo(aTime);
              });

              if (filtered.isEmpty) {
                return const Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'No conversations yet',
                    style: TextStyle(
                        fontSize: 12, color: CodeOpsColors.textTertiary),
                  ),
                );
              }

              return Column(
                children: [
                  for (final convo in filtered)
                    DmListTile(
                      conversation: convo,
                      isSelected: selectedConversation == convo.id,
                      onTap: () {
                        if (convo.id != null) {
                          widget.onConversationSelected(convo.id!);
                        }
                      },
                    ),
                ],
              );
            },
          ),
        ],
      ],
    );
  }

  /// Builds the "Browse channels" link at the bottom of the channels section.
  Widget _buildBrowseChannelsLink(BuildContext context, String teamId) {
    return Container(
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () => _showBrowseChannelsDialog(context, teamId),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(Icons.add, size: 14, color: CodeOpsColors.textTertiary),
                SizedBox(width: 6),
                Text(
                  'Browse channels',
                  style: TextStyle(
                    fontSize: 13,
                    color: CodeOpsColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Opens the create channel dialog.
  void _showCreateChannelDialog(BuildContext context, String teamId) {
    showDialog<ChannelResponse>(
      context: context,
      builder: (_) => CreateChannelDialog(teamId: teamId),
    ).then((result) {
      if (result != null && result.id != null) {
        ref.invalidate(teamChannelsProvider(teamId));
        widget.onChannelSelected(result.id!);
      }
    });
  }

  /// Opens the browse channels dialog.
  void _showBrowseChannelsDialog(BuildContext context, String teamId) {
    showDialog<void>(
      context: context,
      builder: (_) => BrowseChannelsDialog(teamId: teamId),
    ).then((_) {
      ref.invalidate(teamChannelsProvider(teamId));
    });
  }

  /// Opens the new DM dialog and navigates to the created conversation.
  void _showNewDmDialog(BuildContext context, String teamId) {
    showDialog<String>(
      context: context,
      builder: (_) => NewDmDialog(teamId: teamId),
    ).then((conversationId) {
      if (conversationId != null) {
        widget.onConversationSelected(conversationId);
      }
    });
  }
}

/// Expandable section header with title, chevron, and add button.
class _SectionHeader extends StatelessWidget {
  final String title;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onAdd;

  const _SectionHeader({
    required this.title,
    required this.expanded,
    required this.onToggle,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 8, top: 4, bottom: 2),
      child: Row(
        children: [
          GestureDetector(
            onTap: onToggle,
            child: Icon(
              expanded ? Icons.expand_more : Icons.chevron_right,
              size: 16,
              color: CodeOpsColors.textTertiary,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: GestureDetector(
              onTap: onToggle,
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: CodeOpsColors.textTertiary,
                  letterSpacing: 1.2,
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
              onPressed: onAdd,
              tooltip: 'Add',
            ),
          ),
        ],
      ),
    );
  }
}
