// Relay unread summary for the unified dashboard.
//
// Shows channels with unread message counts and click-through navigation.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/relay_providers.dart';
import '../../providers/team_providers.dart';
import '../../theme/colors.dart';

/// Compact relay unread summary for the home dashboard.
class RelayUnreadSummary extends ConsumerWidget {
  /// Creates a [RelayUnreadSummary].
  const RelayUnreadSummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamId = ref.watch(selectedTeamIdProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CodeOpsColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CodeOpsColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.forum_outlined, size: 18, color: CodeOpsColors.secondary),
              const SizedBox(width: 8),
              const Text(
                'Relay Unread',
                style: TextStyle(
                  color: CodeOpsColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => context.go('/relay'),
                  child: const Text(
                    'Open Relay',
                    style: TextStyle(
                      color: CodeOpsColors.secondary,
                      fontSize: 11,
                      decoration: TextDecoration.underline,
                      decorationColor: CodeOpsColors.secondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (teamId == null)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'No team selected',
                  style: TextStyle(
                    color: CodeOpsColors.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ),
            )
          else
            _UnreadContent(teamId: teamId),
        ],
      ),
    );
  }
}

class _UnreadContent extends ConsumerWidget {
  final String teamId;

  const _UnreadContent({required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadAsync = ref.watch(unreadCountsProvider(teamId));

    return unreadAsync.when(
      loading: () => const SizedBox(
        height: 60,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: CodeOpsColors.secondary,
            ),
          ),
        ),
      ),
      error: (_, __) => const Padding(
        padding: EdgeInsets.all(8),
        child: Text(
          'Failed to load unread counts',
          style: TextStyle(color: CodeOpsColors.error, fontSize: 12),
        ),
      ),
      data: (counts) {
        final withUnread =
            counts.where((c) => (c.unreadCount ?? 0) > 0).toList();
        final totalUnread =
            counts.fold<int>(0, (sum, c) => sum + (c.unreadCount ?? 0));

        if (withUnread.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'All caught up!',
              style: TextStyle(
                color: CodeOpsColors.textTertiary,
                fontSize: 12,
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Total unread badge.
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: CodeOpsColors.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$totalUnread unread message${totalUnread > 1 ? 's' : ''}',
                style: const TextStyle(
                  color: CodeOpsColors.secondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Channel list (max 5).
            for (var i = 0; i < withUnread.length && i < 5; i++) ...[
              if (i > 0)
                const Divider(height: 1, color: CodeOpsColors.divider),
              _ChannelRow(
                channelName: withUnread[i].channelName ?? 'Unknown',
                channelId: withUnread[i].channelId ?? '',
                unreadCount: withUnread[i].unreadCount ?? 0,
              ),
            ],
            if (withUnread.length > 5)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '+${withUnread.length - 5} more channels',
                  style: const TextStyle(
                    color: CodeOpsColors.textTertiary,
                    fontSize: 10,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ChannelRow extends StatelessWidget {
  final String channelName;
  final String channelId;
  final int unreadCount;

  const _ChannelRow({
    required this.channelName,
    required this.channelId,
    required this.unreadCount,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          if (channelId.isNotEmpty) {
            context.go('/relay/channel/$channelId');
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              const Icon(Icons.tag, size: 14, color: CodeOpsColors.textTertiary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  channelName,
                  style: const TextStyle(
                    color: CodeOpsColors.textPrimary,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: CodeOpsColors.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$unreadCount',
                  style: const TextStyle(
                    color: CodeOpsColors.secondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
