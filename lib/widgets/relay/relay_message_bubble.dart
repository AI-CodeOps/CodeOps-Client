/// Message bubble widget for the Relay message feed.
///
/// Renders individual messages with sender avatar, name, timestamp,
/// content (with Markdown), reactions, thread reply indicator, and
/// attachments. Handles TEXT, SYSTEM, PLATFORM_EVENT, and FILE types.
/// Reaction chips are tappable with optimistic toggle, and a `[+]`
/// button opens the curated emoji picker. File attachments display
/// image thumbnails with click-to-preview, file type icons, formatted
/// sizes, and click-to-download for non-image files.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/relay_enums.dart';
import '../../models/relay_models.dart';
import '../../providers/relay_providers.dart';
import '../../theme/colors.dart';
import '../../utils/date_utils.dart';
import 'relay_emoji_picker.dart';
import 'relay_event_style_helper.dart';
import 'relay_file_icon.dart';

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
      MessageType.platformEvent => _buildPlatformEventMessage(context, ref),
      MessageType.file => _buildFileMessage(context, ref),
      _ => _buildTextMessage(context, ref),
    };
  }

  /// Builds a standard text message with avatar, sender, timestamp, content.
  ///
  /// All non-deleted messages show a context menu on right-click /
  /// long-press with reaction and (for own messages) edit options.
  Widget _buildTextMessage(BuildContext context, WidgetRef ref) {
    final isDeleted = message.isDeleted ?? false;
    final messageId = message.id;

    // Read optimistic overrides if available.
    final optimistic = messageId != null
        ? ref.watch(optimisticReactionsProvider(messageId))
        : null;
    final reactions = optimistic ?? message.reactions ?? [];

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
                  if (reactions.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: _buildReactions(context, ref, reactions),
                    ),
                  if ((message.attachments ?? []).isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: _buildAttachments(context, ref),
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

    // Wrap all non-deleted messages with context menu.
    if (!isDeleted) {
      content = GestureDetector(
        onSecondaryTapUp: (details) {
          _showContextMenu(context, ref, details.globalPosition);
        },
        onLongPressStart: (details) {
          _showContextMenu(context, ref, details.globalPosition);
        },
        child: content,
      );
    }

    return content;
  }

  /// Shows the message context menu at the given position.
  ///
  /// All messages get "Add reaction"; own messages also get "Edit".
  void _showContextMenu(
      BuildContext context, WidgetRef ref, Offset position) {
    final items = <PopupMenuEntry<String>>[
      const PopupMenuItem<String>(
        value: 'react',
        child: Row(
          children: [
            Icon(Icons.add_reaction_outlined,
                size: 16, color: CodeOpsColors.textSecondary),
            SizedBox(width: 8),
            Text('Add reaction', style: TextStyle(fontSize: 13)),
          ],
        ),
      ),
    ];

    if (isOwnMessage) {
      items.add(const PopupMenuItem<String>(
        value: 'edit',
        child: Row(
          children: [
            Icon(Icons.edit, size: 16, color: CodeOpsColors.textSecondary),
            SizedBox(width: 8),
            Text('Edit', style: TextStyle(fontSize: 13)),
          ],
        ),
      ));
    }

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: items,
    ).then((value) {
      if (value == 'edit') {
        ref.read(editingMessageProvider.notifier).state = message;
      } else if (value == 'react') {
        _showEmojiPicker(context, ref);
      }
    });
  }

  /// Opens the emoji picker dialog and handles the selected emoji.
  void _showEmojiPicker(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: RelayEmojiPicker(
          onEmojiSelected: (emoji) => _toggleReaction(ref, emoji),
        ),
      ),
    );
  }

  /// Toggles a reaction with optimistic update.
  ///
  /// Immediately updates the local reaction state, fires the API
  /// call, then clears the optimistic override. On failure the
  /// override is cleared so the original state is restored.
  void _toggleReaction(WidgetRef ref, String emoji) {
    final messageId = message.id;
    if (messageId == null) return;

    // Compute optimistic reaction list.
    final current = ref.read(optimisticReactionsProvider(messageId)) ??
        message.reactions ??
        [];

    final existing = current.indexWhere((r) => r.emoji == emoji);
    List<ReactionSummaryResponse> updated;

    if (existing >= 0) {
      final r = current[existing];
      final wasActive = r.currentUserReacted ?? false;
      final newCount = (r.count ?? 0) + (wasActive ? -1 : 1);

      if (newCount <= 0) {
        // Remove the reaction entirely.
        updated = [...current]..removeAt(existing);
      } else {
        updated = [...current];
        updated[existing] = ReactionSummaryResponse(
          emoji: r.emoji,
          count: newCount,
          currentUserReacted: !wasActive,
          userIds: r.userIds,
        );
      }
    } else {
      // New reaction.
      updated = [
        ...current,
        ReactionSummaryResponse(
          emoji: emoji,
          count: 1,
          currentUserReacted: true,
        ),
      ];
    }

    // Set optimistic state.
    ref.read(optimisticReactionsProvider(messageId).notifier).state = updated;

    // Record in recents.
    ref.read(recentEmojisProvider.notifier).add(emoji);

    // Fire API call.
    final api = ref.read(relayApiProvider);
    api.toggleReaction(messageId, AddReactionRequest(emoji: emoji)).then((_) {
      // Clear optimistic override on success — next refetch picks up truth.
      ref.read(optimisticReactionsProvider(messageId).notifier).state = null;
    }).catchError((_) {
      // Revert on failure.
      ref.read(optimisticReactionsProvider(messageId).notifier).state = null;
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

  /// Builds a platform event message with typed icon, color, and label.
  ///
  /// If the message has a [MessageResponse.platformEventId], fetches the
  /// [PlatformEventResponse] to determine the event type, icon, label,
  /// and source entity link. Falls back to a generic style if the event
  /// data is unavailable.
  Widget _buildPlatformEventMessage(BuildContext context, WidgetRef ref) {
    final eventId = message.platformEventId;
    PlatformEventResponse? event;

    if (eventId != null) {
      final eventAsync = ref.watch(platformEventDetailProvider(eventId));
      event = eventAsync.valueOrNull;
    }

    final eventType = event?.eventType;
    final color = eventType != null
        ? RelayEventStyleHelper.borderColor(eventType)
        : CodeOpsColors.primary;
    final iconData = eventType != null
        ? RelayEventStyleHelper.icon(eventType)
        : Icons.bolt;
    final labelText = eventType != null
        ? RelayEventStyleHelper.label(eventType)
        : 'Platform Event';
    final route = event != null
        ? RelayEventStyleHelper.routeForEvent(event)
        : null;

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(iconData, size: 16, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    labelText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
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
            const SizedBox(height: 4),
            Text(
              event?.title ?? message.content ?? '',
              style: const TextStyle(
                fontSize: 13,
                color: CodeOpsColors.textPrimary,
              ),
            ),
            if (event?.detail != null && event!.detail!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                event.detail!,
                style: const TextStyle(
                  fontSize: 12,
                  color: CodeOpsColors.textSecondary,
                ),
              ),
            ],
            if (route != null) ...[
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () => _navigateToEvent(context, route),
                child: Text(
                  'View details \u2192',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: color,
                    decoration: TextDecoration.underline,
                    decorationColor: color,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Navigates to the source entity for a platform event.
  void _navigateToEvent(BuildContext context, String route) {
    context.go(route);
  }

  /// Builds a file attachment message.
  Widget _buildFileMessage(BuildContext context, WidgetRef ref) {
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
                _buildAttachments(context, ref),
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

  /// Builds the reaction chips row with tap-to-toggle and a `[+]` button.
  ///
  /// Each chip shows a tooltip on hover describing who reacted.
  /// Tapping a chip optimistically toggles the reaction via
  /// [_toggleReaction]. The trailing `[+]` button opens the
  /// emoji picker.
  Widget _buildReactions(
    BuildContext context,
    WidgetRef ref,
    List<ReactionSummaryResponse> reactions,
  ) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        ...reactions.map((r) {
          final isActive = r.currentUserReacted ?? false;

          return Tooltip(
            message: _reactionTooltip(r),
            waitDuration: const Duration(milliseconds: 400),
            child: GestureDetector(
              onTap: () => _toggleReaction(ref, r.emoji ?? ''),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
              ),
            ),
          );
        }),
        // [+] add reaction button
        GestureDetector(
          onTap: () => _showEmojiPicker(context, ref),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: CodeOpsColors.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.add,
              size: 14,
              color: CodeOpsColors.textTertiary,
            ),
          ),
        ),
      ],
    );
  }

  /// Builds a tooltip string for a reaction summary.
  String _reactionTooltip(ReactionSummaryResponse r) {
    final count = r.count ?? 0;
    final reacted = r.currentUserReacted ?? false;
    final emoji = r.emoji ?? '';

    if (count == 0) return emoji;

    if (reacted) {
      if (count == 1) return 'You reacted with $emoji';
      return 'You and ${count - 1} ${count - 1 == 1 ? 'other' : 'others'} reacted with $emoji';
    }

    return '$count ${count == 1 ? 'person' : 'people'} reacted with $emoji';
  }

  /// Builds the file attachment cards.
  ///
  /// Image attachments (content type starting with `image/`) render an
  /// inline thumbnail with click-to-preview. Non-image attachments render
  /// a file type icon with click-to-download.
  Widget _buildAttachments(BuildContext context, WidgetRef ref) {
    final attachments = message.attachments ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: attachments.map((a) {
        final isImage =
            a.contentType != null && a.contentType!.startsWith('image/');

        if (isImage) {
          return _buildImageAttachment(context, a);
        }
        return _buildFileAttachment(context, ref, a);
      }).toList(),
    );
  }

  /// Builds an image attachment with inline thumbnail.
  ///
  /// Tapping the thumbnail opens a full-size preview dialog.
  Widget _buildImageAttachment(
      BuildContext context, FileAttachmentResponse attachment) {
    final url = attachment.thumbnailUrl ?? attachment.downloadUrl;

    return GestureDetector(
      onTap: () => _showImagePreview(context, attachment),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        constraints: const BoxConstraints(maxWidth: 280, maxHeight: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: CodeOpsColors.border, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: url != null
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildFallbackImageCard(
                  attachment.fileName ?? 'Image',
                  attachment.fileSizeBytes,
                ),
              )
            : _buildFallbackImageCard(
                attachment.fileName ?? 'Image',
                attachment.fileSizeBytes,
              ),
      ),
    );
  }

  /// Fallback card when the image URL fails to load.
  Widget _buildFallbackImageCard(String fileName, int? sizeBytes) {
    return Container(
      width: 200,
      height: 80,
      color: CodeOpsColors.surfaceVariant,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.image, size: 24, color: CodeOpsColors.textTertiary),
          const SizedBox(height: 4),
          Text(
            fileName,
            overflow: TextOverflow.ellipsis,
            style:
                const TextStyle(fontSize: 11, color: CodeOpsColors.textPrimary),
          ),
          if (sizeBytes != null)
            Text(
              _formatFileSize(sizeBytes),
              style: const TextStyle(
                  fontSize: 10, color: CodeOpsColors.textTertiary),
            ),
        ],
      ),
    );
  }

  /// Opens a dialog showing the full-size image.
  void _showImagePreview(
      BuildContext context, FileAttachmentResponse attachment) {
    final url = attachment.downloadUrl ?? attachment.thumbnailUrl;
    if (url == null) return;

    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(url, fit: BoxFit.contain),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 24),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a non-image file attachment card.
  ///
  /// Tapping the card triggers a file download via the API.
  Widget _buildFileAttachment(
      BuildContext context, WidgetRef ref, FileAttachmentResponse attachment) {
    return GestureDetector(
      onTap: () => _downloadFile(context, ref, attachment),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: CodeOpsColors.surfaceVariant,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            RelayFileIcon(
              contentType: attachment.contentType,
              fileName: attachment.fileName,
              size: 16,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                attachment.fileName ?? 'Untitled',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: CodeOpsColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _formatFileSize(attachment.fileSizeBytes ?? 0),
              style: const TextStyle(
                fontSize: 11,
                color: CodeOpsColors.textTertiary,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.download,
                size: 14, color: CodeOpsColors.textTertiary),
          ],
        ),
      ),
    );
  }

  /// Downloads a file attachment to the user's downloads directory.
  Future<void> _downloadFile(BuildContext context, WidgetRef ref,
      FileAttachmentResponse attachment) async {
    if (attachment.id == null) return;

    final api = ref.read(relayApiProvider);
    try {
      final bytes = await api.downloadFile(attachment.id!);
      final dir = await getDownloadsDirectory() ??
          await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/${attachment.fileName ?? "download"}';
      await File(filePath).writeAsBytes(bytes);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Downloaded ${attachment.fileName}'),
            backgroundColor: CodeOpsColors.success,
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Download failed'),
            backgroundColor: CodeOpsColors.error,
          ),
        );
      }
    }
  }

  /// Formats a byte count into a human-readable size string.
  static String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
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

}
