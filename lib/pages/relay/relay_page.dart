/// Main Relay messaging shell page with three-column layout.
///
/// Renders a channel/DM sidebar (left), message feed (center), and
/// collapsible thread/detail panel (right). Route parameters drive
/// which channel, DM, or thread is selected via Riverpod providers.
/// WebSocket connection is established on mount for real-time updates.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_providers.dart';
import '../../providers/relay_providers.dart';
import '../../widgets/relay/relay_detail_panel.dart';
import '../../widgets/relay/relay_dm_panel.dart';
import '../../widgets/relay/relay_empty_state.dart';
import '../../widgets/relay/relay_message_panel.dart';
import '../../widgets/relay/relay_sidebar.dart';

/// The main Relay messaging page with three-column layout.
///
/// All Relay routes (`/relay`, `/relay/channel/:id`, `/relay/dm/:id`,
/// `/relay/channel/:id/thread/:msgId`) render this page. Route parameters
/// are processed in [initState] and pushed into Riverpod state providers
/// so child widgets react accordingly.
class RelayPage extends ConsumerStatefulWidget {
  /// Optional channel ID from the route to select on mount.
  final String? initialChannelId;

  /// Optional conversation ID from the route to select on mount.
  final String? initialConversationId;

  /// Optional thread root message ID from the route to open on mount.
  final String? initialThreadMessageId;

  /// Creates a [RelayPage].
  const RelayPage({
    this.initialChannelId,
    this.initialConversationId,
    this.initialThreadMessageId,
    super.key,
  });

  @override
  ConsumerState<RelayPage> createState() => _RelayPageState();
}

class _RelayPageState extends ConsumerState<RelayPage> {
  @override
  void initState() {
    super.initState();
    // Process route params into provider state after the first frame
    if (widget.initialChannelId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(selectedChannelIdProvider.notifier).state =
            widget.initialChannelId;
        ref.read(selectedConversationIdProvider.notifier).state = null;
        if (widget.initialThreadMessageId != null) {
          ref.read(threadRootMessageIdProvider.notifier).state =
              widget.initialThreadMessageId;
          ref.read(showThreadPanelProvider.notifier).state = true;
        }
      });
    } else if (widget.initialConversationId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(selectedConversationIdProvider.notifier).state =
            widget.initialConversationId;
        ref.read(selectedChannelIdProvider.notifier).state = null;
      });
    }

    _connectWebSocket();
  }

  /// Establishes the Relay WebSocket connection.
  ///
  /// Retrieves the JWT token from secure storage and connects.
  /// Failures are handled gracefully — the UI still works via REST.
  Future<void> _connectWebSocket() async {
    try {
      final storage = ref.read(secureStorageProvider);
      final token = await storage.getAuthToken();
      if (token != null && mounted) {
        ref.read(relayWebSocketProvider).connect(token);
      }
    } catch (_) {
      // WebSocket is optional — REST polling will still work
    }
  }

  @override
  Widget build(BuildContext context) {
    final showThread = ref.watch(showThreadPanelProvider);
    final selectedChannel = ref.watch(selectedChannelIdProvider);
    final selectedConversation = ref.watch(selectedConversationIdProvider);

    return Scaffold(
      body: Row(
        children: [
          // LEFT: Channel/DM list sidebar
          SizedBox(
            width: 260,
            child: RelaySidebar(
              onChannelSelected: (channelId) {
                ref.read(selectedChannelIdProvider.notifier).state = channelId;
                ref.read(selectedConversationIdProvider.notifier).state = null;
                ref.read(showThreadPanelProvider.notifier).state = false;
                ref.read(threadRootMessageIdProvider.notifier).state = null;
                context.go('/relay/channel/$channelId');
              },
              onConversationSelected: (conversationId) {
                ref.read(selectedConversationIdProvider.notifier).state =
                    conversationId;
                ref.read(selectedChannelIdProvider.notifier).state = null;
                ref.read(showThreadPanelProvider.notifier).state = false;
                ref.read(threadRootMessageIdProvider.notifier).state = null;
                context.go('/relay/dm/$conversationId');
              },
            ),
          ),

          const VerticalDivider(width: 1),

          // CENTER: Message feed (or empty state)
          Expanded(
            child: _buildCenterPanel(selectedChannel, selectedConversation),
          ),

          // RIGHT: Thread/detail panel (conditional)
          if (showThread) ...[
            const VerticalDivider(width: 1),
            SizedBox(
              width: 340,
              child: RelayDetailPanel(
                onClose: () {
                  ref.read(showThreadPanelProvider.notifier).state = false;
                  ref.read(threadRootMessageIdProvider.notifier).state = null;
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Builds the center panel based on the current selection.
  Widget _buildCenterPanel(String? channelId, String? conversationId) {
    if (channelId != null) {
      return RelayMessagePanel(channelId: channelId);
    } else if (conversationId != null) {
      return RelayDmPanel(conversationId: conversationId);
    } else {
      return const RelayEmptyState();
    }
  }
}
