/// Thread panel widget for the Relay module right column.
///
/// Displays the root message of a thread, a scrollable list of replies,
/// a reply composer with Enter-to-send, and an "Also send to channel"
/// checkbox for cross-posting. Replaces the placeholder [RelayDetailPanel]
/// in the three-column layout when a thread is opened.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/relay_models.dart';
import '../../providers/auth_providers.dart';
import '../../providers/relay_providers.dart';
import '../../providers/team_providers.dart';
import '../../theme/colors.dart';
import '../../widgets/shared/error_panel.dart';
import 'relay_message_bubble.dart';

/// Thread panel showing root message, replies, and reply composer.
///
/// Displayed in the right column of the Relay three-column layout
/// when a user opens a thread from the message feed or navigates
/// to `/relay/channel/:channelId/thread/:messageId`.
///
/// Fetches the root message via [messageByIdProvider] and replies
/// via [threadRepliesProvider]. The reply composer sends messages
/// with [SendMessageRequest.parentId] set to [rootMessageId].
class RelayThreadPanel extends ConsumerStatefulWidget {
  /// UUID of the channel containing the thread.
  final String channelId;

  /// UUID of the root message for the thread.
  final String rootMessageId;

  /// Called when the user closes the panel.
  final VoidCallback onClose;

  /// Creates a [RelayThreadPanel].
  const RelayThreadPanel({
    required this.channelId,
    required this.rootMessageId,
    required this.onClose,
    super.key,
  });

  @override
  ConsumerState<RelayThreadPanel> createState() => _RelayThreadPanelState();
}

class _RelayThreadPanelState extends ConsumerState<RelayThreadPanel> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();
  bool _alsoSendToChannel = false;

  /// Resolves the current team ID from the selected team provider.
  String? get _teamId => ref.read(selectedTeamIdProvider);

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Sends a reply to the thread.
  ///
  /// Posts a message with [parentId] set to the root message ID.
  /// If [_alsoSendToChannel] is checked, also sends a copy as a
  /// top-level channel message (no parentId).
  Future<void> _sendReply() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final teamId = _teamId;
    if (teamId == null) return;

    final api = ref.read(relayApiProvider);

    try {
      // Send as thread reply
      await api.sendMessage(
        widget.channelId,
        SendMessageRequest(
          content: text,
          parentId: widget.rootMessageId,
        ),
        teamId,
      );

      // Also send to channel if checked
      if (_alsoSendToChannel) {
        await api.sendMessage(
          widget.channelId,
          SendMessageRequest(content: text),
          teamId,
        );
      }

      _controller.clear();

      // Refresh thread replies
      ref.invalidate(threadRepliesProvider(
        (channelId: widget.channelId, parentId: widget.rootMessageId),
      ));

      // Refresh main feed too if also sent to channel
      if (_alsoSendToChannel) {
        ref
            .read(accumulatedMessagesProvider(
              (channelId: widget.channelId, teamId: teamId),
            ).notifier)
            .refresh();
      }

      // Scroll to bottom after reply
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send reply'),
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
        _sendReply();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rootMessageAsync = ref.watch(
      messageByIdProvider(
        (channelId: widget.channelId, messageId: widget.rootMessageId),
      ),
    );
    final repliesAsync = ref.watch(
      threadRepliesProvider(
        (channelId: widget.channelId, parentId: widget.rootMessageId),
      ),
    );
    final currentUser = ref.watch(currentUserProvider);

    return Container(
      color: CodeOpsColors.surface,
      child: Column(
        children: [
          _buildHeader(),
          const Divider(height: 1, color: CodeOpsColors.border),
          Expanded(
            child: rootMessageAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorPanel.fromException(
                e,
                onRetry: () => ref.invalidate(messageByIdProvider(
                  (
                    channelId: widget.channelId,
                    messageId: widget.rootMessageId,
                  ),
                )),
              ),
              data: (rootMessage) => _buildThreadContent(
                rootMessage,
                repliesAsync,
                currentUser?.id,
              ),
            ),
          ),
          const Divider(height: 1, color: CodeOpsColors.border),
          _buildAlsoSendToChannel(),
          _buildReplyComposer(),
        ],
      ),
    );
  }

  /// Builds the panel header with title and close button.
  Widget _buildHeader() {
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
            onPressed: widget.onClose,
            tooltip: 'Close',
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  /// Builds the scrollable thread content: root message + replies.
  Widget _buildThreadContent(
    MessageResponse rootMessage,
    AsyncValue<List<MessageResponse>> repliesAsync,
    String? userId,
  ) {
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        // Root message
        RelayMessageBubble(
          message: rootMessage,
          isOwnMessage: userId != null && rootMessage.senderId == userId,
          showThreadIndicator: false,
        ),

        // Reply separator
        _buildReplySeparator(repliesAsync),

        // Replies
        ...repliesAsync.when(
          loading: () => [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          ],
          error: (_, __) => [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'Failed to load replies',
                  style: TextStyle(
                    fontSize: 13,
                    color: CodeOpsColors.textTertiary,
                  ),
                ),
              ),
            ),
          ],
          data: (replies) => replies
              .map((reply) => RelayMessageBubble(
                    key: ValueKey(reply.id),
                    message: reply,
                    isOwnMessage:
                        userId != null && reply.senderId == userId,
                    showThreadIndicator: false,
                  ))
              .toList(),
        ),
      ],
    );
  }

  /// Builds the reply count separator between root message and replies.
  Widget _buildReplySeparator(
    AsyncValue<List<MessageResponse>> repliesAsync,
  ) {
    final count = repliesAsync.valueOrNull?.length ?? 0;
    final label = count == 0
        ? 'No replies yet'
        : '$count ${count == 1 ? 'reply' : 'replies'}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Expanded(
            child: Divider(height: 1, color: CodeOpsColors.border),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: CodeOpsColors.textTertiary,
              ),
            ),
          ),
          const Expanded(
            child: Divider(height: 1, color: CodeOpsColors.border),
          ),
        ],
      ),
    );
  }

  /// Builds the "Also send to channel" checkbox row.
  Widget _buildAlsoSendToChannel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: Checkbox(
              value: _alsoSendToChannel,
              onChanged: (value) {
                setState(() {
                  _alsoSendToChannel = value ?? false;
                });
              },
              activeColor: CodeOpsColors.primary,
              side: const BorderSide(color: CodeOpsColors.textTertiary),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Also send to channel',
            style: TextStyle(
              fontSize: 12,
              color: CodeOpsColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the reply composer row with text field and send button.
  Widget _buildReplyComposer() {
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
                controller: _controller,
                focusNode: _focusNode,
                maxLines: 3,
                minLines: 1,
                textInputAction: TextInputAction.newline,
                style: const TextStyle(
                  fontSize: 13,
                  color: CodeOpsColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Reply...',
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
            valueListenable: _controller,
            builder: (context, value, _) {
              final hasText = value.text.trim().isNotEmpty;

              return IconButton(
                icon: const Icon(Icons.send, size: 20),
                color: hasText
                    ? CodeOpsColors.primary
                    : CodeOpsColors.textTertiary,
                tooltip: 'Send reply',
                onPressed: hasText ? _sendReply : null,
              );
            },
          ),
        ],
      ),
    );
  }
}
