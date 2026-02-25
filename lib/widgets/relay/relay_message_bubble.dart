/// Message bubble widget for the Relay message feed.
///
/// Renders individual messages with sender avatar, name, timestamp,
/// content (with Markdown), reactions, thread reply indicator, and
/// attachments. Handles TEXT, SYSTEM, PLATFORM_EVENT, and FILE types.
library;

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/relay_enums.dart';
import '../../models/relay_models.dart';
import '../../providers/relay_providers.dart';
import '../../theme/colors.dart';
import '../../utils/date_utils.dart';

/// Renders a single message in the Relay message feed.
///
/// Dispatches to type-specific renderers based on [MessageResponse.messageType]:
/// - [MessageType.text] — standard chat bubble with Markdown
/// - [MessageType.system] — centered italic system notice
/// - [MessageType.platformEvent] — colored event card with icon
/// - [MessageType.file] — attachment card with file icon and size
class RelayMessageBubble extends ConsumerWidget {
  /// The message data to render.
  final MessageResponse message;

  /// Whether this message is from the current user.
  final bool isOwnMessage;

  /// Whether to show the thread reply indicator.
  ///
  /// Set to `false` in thread panels where the indicator is redundant
  /// (both the root message and replies should not show it).
  final bool showThreadIndicator;

  /// Callback when the user taps the thread reply indicator.
  final VoidCallback? onThreadTap;

  /// Creates a [RelayMessageBubble].
  const RelayMessageBubble({
    required this.message,
    this.isOwnMessage = false,
    this.showThreadIndicator = true,
    this.onThreadTap,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type = message.messageType ?? MessageType.text;

    return switch (type) {
      MessageType.system => _buildSystemMessage(),
      MessageType.platformEvent => _buildPlatformEventMessage(),
      MessageType.file => _buildFileMessage(),
      _ => _buildTextMessage(ref),
    };
  }

  /// Builds a standard text message with avatar, sender, timestamp, content.
  ///
  /// Own messages show a context menu on right-click / long-press with
  /// an "Edit" option that sets [editingMessageProvider].
  Widget _buildTextMessage(WidgetRef ref) {
    final isDeleted = message.isDeleted ?? false;

    Widget content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar(),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSenderRow(),
                const SizedBox(height: 2),
                if (isDeleted)
                  const Text(
                    'This message was deleted',
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: CodeOpsColors.textTertiary,
                    ),
                  )
                else ...[
                  _buildMarkdownContent(),
                  if ((message.reactions ?? []).isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: _buildReactions(),
                    ),
                  if ((message.attachments ?? []).isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: _buildAttachments(),
                    ),
                  if (showThreadIndicator && (message.replyCount ?? 0) > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: _buildThreadIndicator(),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    // Wrap own messages with context menu for editing
    if (isOwnMessage && !isDeleted) {
      content = GestureDetector(
        onSecondaryTapUp: (details) {
          _showContextMenu(ref, details.globalPosition);
        },
        onLongPressStart: (details) {
          _showContextMenu(ref, details.globalPosition);
        },
        child: content,
      );
    }

    return content;
  }

  /// Shows the message context menu at the given position.
  void _showContextMenu(WidgetRef ref, Offset position) {
    final context = ref.context;
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: [
        const PopupMenuItem<String>(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 16, color: CodeOpsColors.textSecondary),
              SizedBox(width: 8),
              Text('Edit', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == 'edit') {
        ref.read(editingMessageProvider.notifier).state = message;
      }
    });
  }

  /// Builds a centered system message (join, leave, topic change).
  Widget _buildSystemMessage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Center(
        child: Text(
          message.content ?? '',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            fontStyle: FontStyle.italic,
            color: CodeOpsColors.textTertiary,
          ),
        ),
      ),
    );
  }

  /// Builds a platform event message with colored accent.
  Widget _buildPlatformEventMessage() {
    final color = _platformEventColor(message.content);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: CodeOpsColors.surfaceVariant,
          borderRadius: BorderRadius.circular(6),
          border: Border(
            left: BorderSide(color: color, width: 3),
          ),
        ),
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Icon(Icons.bolt, size: 16, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Platform Event',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message.content ?? '',
                    style: const TextStyle(
                      fontSize: 13,
                      color: CodeOpsColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              formatTimeAgo(message.createdAt),
              style: const TextStyle(
                fontSize: 11,
                color: CodeOpsColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a file attachment message.
  Widget _buildFileMessage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar(),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSenderRow(),
                const SizedBox(height: 4),
                if (message.content != null && message.content!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      message.content!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: CodeOpsColors.textPrimary,
                      ),
                    ),
                  ),
                _buildAttachments(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the sender avatar circle.
  Widget _buildAvatar() {
    final name = message.senderDisplayName ?? '?';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return CircleAvatar(
      radius: 16,
      backgroundColor: CodeOpsColors.primary.withValues(alpha: 0.3),
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: CodeOpsColors.primary,
        ),
      ),
    );
  }

  /// Builds the sender name + timestamp row.
  Widget _buildSenderRow() {
    final isEdited = message.isEdited ?? false;

    return Row(
      children: [
        Text(
          message.senderDisplayName ?? 'Unknown',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isOwnMessage
                ? CodeOpsColors.primary
                : CodeOpsColors.textPrimary,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          formatTimeAgo(message.createdAt),
          style: const TextStyle(
            fontSize: 11,
            color: CodeOpsColors.textTertiary,
          ),
        ),
        if (isEdited) ...[
          const SizedBox(width: 6),
          const Text(
            '(edited)',
            style: TextStyle(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: CodeOpsColors.textTertiary,
            ),
          ),
        ],
      ],
    );
  }

  /// Builds Markdown-rendered message content.
  Widget _buildMarkdownContent() {
    return MarkdownBody(
      data: message.content ?? '',
      styleSheet: MarkdownStyleSheet(
        p: const TextStyle(
          fontSize: 13,
          color: CodeOpsColors.textPrimary,
          height: 1.4,
        ),
        code: const TextStyle(
          fontSize: 12,
          color: CodeOpsColors.secondary,
          backgroundColor: CodeOpsColors.surfaceVariant,
        ),
        codeblockDecoration: BoxDecoration(
          color: CodeOpsColors.surfaceVariant,
          borderRadius: BorderRadius.circular(6),
        ),
        a: const TextStyle(
          color: CodeOpsColors.primary,
          decoration: TextDecoration.underline,
        ),
        strong: const TextStyle(
          fontWeight: FontWeight.w600,
          color: CodeOpsColors.textPrimary,
        ),
        em: const TextStyle(
          fontStyle: FontStyle.italic,
          color: CodeOpsColors.textPrimary,
        ),
      ),
      shrinkWrap: true,
    );
  }

  /// Builds the reaction chips row.
  Widget _buildReactions() {
    final reactions = message.reactions ?? [];

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: reactions.map((r) {
        final isActive = r.currentUserReacted ?? false;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: isActive
                ? CodeOpsColors.primary.withValues(alpha: 0.2)
                : CodeOpsColors.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
            border: isActive
                ? Border.all(color: CodeOpsColors.primary, width: 1)
                : null,
          ),
          child: Text(
            '${r.emoji ?? ""} ${r.count ?? 0}',
            style: const TextStyle(fontSize: 12),
          ),
        );
      }).toList(),
    );
  }

  /// Builds the file attachment cards.
  Widget _buildAttachments() {
    final attachments = message.attachments ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: attachments.map((a) {
        final sizeKb = ((a.fileSizeBytes ?? 0) / 1024).toStringAsFixed(1);

        return Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: CodeOpsColors.surfaceVariant,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.attach_file,
                  size: 16, color: CodeOpsColors.textTertiary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  a.fileName ?? 'Untitled',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: CodeOpsColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${sizeKb}KB',
                style: const TextStyle(
                  fontSize: 11,
                  color: CodeOpsColors.textTertiary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Builds the thread reply indicator.
  Widget _buildThreadIndicator() {
    final count = message.replyCount ?? 0;

    return GestureDetector(
      onTap: onThreadTap,
      child: Text(
        '$count ${count == 1 ? 'reply' : 'replies'}',
        style: const TextStyle(
          fontSize: 12,
          color: CodeOpsColors.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// Returns a color based on platform event content keywords.
  Color _platformEventColor(String? content) {
    if (content == null) return CodeOpsColors.primary;
    final lower = content.toLowerCase();
    if (lower.contains('alert') || lower.contains('crash') ||
        lower.contains('critical')) {
      return CodeOpsColors.error;
    }
    if (lower.contains('audit') || lower.contains('build') ||
        lower.contains('deploy') || lower.contains('merge')) {
      return const Color(0xFF3B82F6); // blue
    }
    if (lower.contains('session')) return CodeOpsColors.success;
    if (lower.contains('rotat')) return CodeOpsColors.warning;
    if (lower.contains('register')) return const Color(0xFFA855F7); // purple
    return CodeOpsColors.primary;
  }
}
