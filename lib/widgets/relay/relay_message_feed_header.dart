/// Header bar widget for the Relay message feed.
///
/// Displays the channel name, topic, member count, and action icons
/// (search, pins, members, settings). Fetches data reactively from
/// [channelDetailProvider].
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/relay_enums.dart';
import '../../providers/relay_providers.dart';
import '../../theme/colors.dart';
import 'channel_settings_dialog.dart';
import 'relay_event_feed.dart';
import 'relay_search_dialog.dart';

/// Header bar displaying channel info and action buttons.
///
/// Shows `# channel-name`, topic text, and icon buttons for search,
/// pins, members, and settings. Settings opens [ChannelSettingsDialog].
class RelayMessageFeedHeader extends ConsumerWidget {
  /// UUID of the channel.
  final String channelId;

  /// UUID of the team.
  final String teamId;

  /// Creates a [RelayMessageFeedHeader].
  const RelayMessageFeedHeader({
    required this.channelId,
    required this.teamId,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channelAsync = ref.watch(
      channelDetailProvider((channelId: channelId, teamId: teamId)),
    );

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: channelAsync.when(
        loading: () => const Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        error: (_, __) => const Center(
          child: Text(
            'Failed to load channel',
            style: TextStyle(fontSize: 13, color: CodeOpsColors.textTertiary),
          ),
        ),
        data: (channel) => Row(
          children: [
            _buildChannelIcon(channel.channelType),
            const SizedBox(width: 6),
            Text(
              channel.name ?? 'channel',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: CodeOpsColors.textPrimary,
              ),
            ),
            if (channel.topic != null && channel.topic!.isNotEmpty) ...[
              const SizedBox(width: 10),
              const Text(
                '|',
                style: TextStyle(color: CodeOpsColors.border),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  channel.topic!,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: CodeOpsColors.textTertiary,
                  ),
                ),
              ),
            ] else
              const Spacer(),
            if (channel.memberCount != null) ...[
              const Icon(Icons.people_outline,
                  size: 14, color: CodeOpsColors.textTertiary),
              const SizedBox(width: 4),
              Text(
                '${channel.memberCount}',
                style: const TextStyle(
                  fontSize: 12,
                  color: CodeOpsColors.textTertiary,
                ),
              ),
              const SizedBox(width: 12),
            ],
            _buildHeaderAction(
              Icons.search,
              'Search',
              () => _openSearch(context),
            ),
            _buildNotificationBell(context, ref),
            _buildHeaderAction(
              Icons.push_pin_outlined,
              'Pins',
              null, // Placeholder — enabled in RLF-005
            ),
            _buildHeaderAction(
              Icons.settings_outlined,
              'Settings',
              () => _openSettings(context),
            ),
          ],
        ),
      ),
    );
  }

  /// Returns the appropriate icon for the channel type.
  Widget _buildChannelIcon(ChannelType? type) {
    final icon = switch (type) {
      ChannelType.private => Icons.lock_outline,
      ChannelType.project => Icons.folder_outlined,
      ChannelType.service => Icons.dns_outlined,
      _ => Icons.tag,
    };

    return Icon(icon, size: 18, color: CodeOpsColors.textTertiary);
  }

  /// Builds a header action icon button.
  Widget _buildHeaderAction(
    IconData icon,
    String tooltip,
    VoidCallback? onPressed,
  ) {
    return IconButton(
      icon: Icon(icon, size: 18),
      color: CodeOpsColors.textTertiary,
      onPressed: onPressed,
      tooltip: tooltip,
      padding: const EdgeInsets.all(6),
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    );
  }

  /// Builds the notification bell icon with undelivered event badge.
  Widget _buildNotificationBell(BuildContext context, WidgetRef ref) {
    final count = ref.watch(undeliveredEventCountProvider(teamId));

    return SizedBox(
      width: 32,
      height: 32,
      child: Stack(
        children: [
          Center(
            child: IconButton(
              icon: const Icon(Icons.notifications_outlined, size: 18),
              color: CodeOpsColors.textTertiary,
              onPressed: () => _openEventFeed(context),
              tooltip: 'Events',
              padding: const EdgeInsets.all(6),
              constraints:
                  const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ),
          if (count > 0)
            Positioned(
              right: 2,
              top: 2,
              child: Container(
                padding: const EdgeInsets.all(2),
                constraints: const BoxConstraints(
                  minWidth: 14,
                  minHeight: 14,
                ),
                decoration: BoxDecoration(
                  color: CodeOpsColors.error,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Opens the event feed dialog.
  void _openEventFeed(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => const RelayEventFeed(),
    );
  }

  /// Opens the message search dialog.
  void _openSearch(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => RelaySearchDialog(channelId: channelId),
    );
  }

  /// Opens the channel settings dialog.
  void _openSettings(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => ChannelSettingsDialog(
        channelId: channelId,
        teamId: teamId,
      ),
    );
  }
}
