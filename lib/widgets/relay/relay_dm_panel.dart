/// Center panel for direct messages in the Relay module.
///
/// Displays the conversation header (participant names), scrollable
/// message feed with date separators, infinite scroll loading,
/// mark-as-read debouncing, and a DM composer with Enter-to-send.
/// Reuses [RelayMessageBubble] by adapting [DirectMessageResponse]
/// to [MessageResponse] via [DirectMessageResponseX.toMessageResponse].
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/relay_models.dart';
import '../../providers/auth_providers.dart';
import '../../providers/relay_providers.dart';
import '../../theme/colors.dart';
import '../../widgets/shared/error_panel.dart';
import 'relay_date_separator.dart';
import 'relay_message_bubble.dart';

/// Extension to adapt [DirectMessageResponse] to [MessageResponse] for
/// reuse of [RelayMessageBubble].
///
/// Maps DM-specific fields to their channel message equivalents.
/// Thread-related fields (parentId, replyCount, etc.) remain null.
extension DirectMessageResponseX on DirectMessageResponse {
  /// Converts this DM to a [MessageResponse] for bubble rendering.
  MessageResponse toMessageResponse() => MessageResponse(
        id: id,
        channelId: conversationId,
        senderId: senderId,
        senderDisplayName: senderDisplayName,
        content: content,
        messageType: messageType,
        isEdited: isEdited,
        editedAt: editedAt,
        isDeleted: isDeleted,
        reactions: reactions,
        attachments: attachments,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

/// DM panel showing conversation header, message feed, and composer.
///
/// Takes a [conversationId] to identify which conversation to display.
/// Uses [AccumulatedDmMessagesNotifier] for paginated message loading
/// with infinite scroll. Marks the conversation as read when the user
/// scrolls to the bottom.
class RelayDmPanel extends ConsumerStatefulWidget {
  /// UUID of the direct conversation to display.
  final String conversationId;

  /// Creates a [RelayDmPanel].
  const RelayDmPanel({required this.conversationId, super.key});

  @override
  ConsumerState<RelayDmPanel> createState() => _RelayDmPanelState();
}

class _RelayDmPanelState extends ConsumerState<RelayDmPanel> {
  final _scrollController = ScrollController();
  final _composerController = TextEditingController();
  final _composerFocusNode = FocusNode();
  Timer? _markReadTimer;
  bool _isAtBottom = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _composerController.dispose();
    _composerFocusNode.dispose();
    _markReadTimer?.cancel();
    super.dispose();
  }

  /// Handles scroll events for infinite scroll and mark-as-read.
  void _onScroll() {
    final position = _scrollController.position;

    // Infinite scroll: load more when near the top (older messages)
    if (position.pixels <= position.minScrollExtent + 200) {
      final notifier = ref.read(
        accumulatedDmMessagesProvider(widget.conversationId).notifier,
      );
      if (notifier.hasMore && !notifier.isLoadingMore) {
        notifier.loadNextPage();
      }
    }

    // Track if user is at the bottom for mark-as-read
    _isAtBottom = position.pixels >= position.maxScrollExtent - 50;
    if (_isAtBottom) {
      _scheduleMarkRead();
    }
  }

  /// Schedules a mark-as-read API call with 1-second debounce.
  void _scheduleMarkRead() {
    _markReadTimer?.cancel();
    _markReadTimer = Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      final api = ref.read(relayApiProvider);
      api.markConversationRead(widget.conversationId);
    });
  }

  /// Scrolls to the bottom of the feed.
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  /// Sends a direct message.
  Future<void> _sendMessage() async {
    final text = _composerController.text.trim();
    if (text.isEmpty) return;

    final api = ref.read(relayApiProvider);

    try {
      await api.sendDirectMessage(
        widget.conversationId,
        SendDirectMessageRequest(content: text),
      );

      _composerController.clear();

      // Refresh the DM feed
      ref
          .read(accumulatedDmMessagesProvider(widget.conversationId).notifier)
          .refresh();

      // Scroll to bottom after sending
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_isAtBottom) _scrollToBottom();
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send message'),
            backgroundColor: CodeOpsColors.error,
          ),
        );
      }
    }
  }

  /// Handles key events for Enter to send, Shift+Enter for newline.
  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    if (event.logicalKey == LogicalKeyboardKey.enter) {
      final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
      if (!isShiftPressed) {
        _sendMessage();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final conversationAsync = ref.watch(
      conversationDetailProvider(widget.conversationId),
    );
    final messagesAsync = ref.watch(
      accumulatedDmMessagesProvider(widget.conversationId),
    );
    final currentUser = ref.watch(currentUserProvider);

    return Column(
      children: [
        _buildHeader(conversationAsync),
        const Divider(height: 1, color: CodeOpsColors.border),
        Expanded(
          child: messagesAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => ErrorPanel.fromException(
              e,
              onRetry: () => ref
                  .read(
                    accumulatedDmMessagesProvider(widget.conversationId)
                        .notifier,
                  )
                  .refresh(),
            ),
            data: (messages) {
              if (messages.isEmpty) {
                return const Center(
                  child: Text(
                    'No messages yet',
                    style: TextStyle(
                      fontSize: 14,
                      color: CodeOpsColors.textTertiary,
                    ),
                  ),
                );
              }

              // Schedule scroll to bottom on first load
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_isAtBottom) _scrollToBottom();
              });

              return _buildMessageList(messages, currentUser?.id);
            },
          ),
        ),
        const Divider(height: 1, color: CodeOpsColors.border),
        _buildComposer(),
      ],
    );
  }

  /// Builds the conversation header with participant names.
  Widget _buildHeader(
    AsyncValue<DirectConversationResponse> conversationAsync,
  ) {
    final title = conversationAsync.when(
      loading: () => 'Direct Message',
      error: (_, __) => 'Direct Message',
      data: (convo) => convo.name ?? 'Direct Message',
    );

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.person_outline,
              size: 20, color: CodeOpsColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: CodeOpsColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the scrollable message list with date separators.
  Widget _buildMessageList(
    List<DirectMessageResponse> messages,
    String? userId,
  ) {
    final items = <Widget>[];
    DateTime? lastDate;

    for (final dm in messages) {
      final msgDate = dm.createdAt;
      if (msgDate != null) {
        final day = DateTime(msgDate.year, msgDate.month, msgDate.day);
        if (lastDate == null || day != lastDate) {
          items.add(RelayDateSeparator(date: msgDate));
          lastDate = day;
        }
      }

      items.add(
        RelayMessageBubble(
          key: ValueKey(dm.id),
          message: dm.toMessageResponse(),
          isOwnMessage: userId != null && dm.senderId == userId,
          showThreadIndicator: false,
        ),
      );
    }

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: items,
    );
  }

  /// Builds the DM composer row with text field and send button.
  Widget _buildComposer() {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Text input
          Expanded(
            child: KeyboardListener(
              focusNode: FocusNode(),
              onKeyEvent: _handleKeyEvent,
              child: TextField(
                controller: _composerController,
                focusNode: _composerFocusNode,
                maxLines: 5,
                minLines: 1,
                textInputAction: TextInputAction.newline,
                style: const TextStyle(
                  fontSize: 13,
                  color: CodeOpsColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Message...',
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: CodeOpsColors.textTertiary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: CodeOpsColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: CodeOpsColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: CodeOpsColors.primary),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),

          // Send button
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _composerController,
            builder: (context, value, _) {
              final hasText = value.text.trim().isNotEmpty;

              return IconButton(
                icon: const Icon(Icons.send, size: 20),
                color: hasText
                    ? CodeOpsColors.primary
                    : CodeOpsColors.textTertiary,
                tooltip: 'Send message',
                onPressed: hasText ? _sendMessage : null,
              );
            },
          ),
        ],
      ),
    );
  }
}
