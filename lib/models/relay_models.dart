/// Model classes for the CodeOps-Relay module.
///
/// Maps to response and request DTOs defined in the Relay controllers.
/// All classes use [JsonSerializable] with generated `fromJson` / `toJson`
/// methods via build_runner.
///
/// Organized by domain:
/// - Channels (4 classes)
/// - Messages (3 classes)
/// - Direct Messages (3 classes)
/// - Reactions (2 classes)
/// - Files (1 class)
/// - Presence (1 class)
/// - Pins & Receipts (3 classes)
/// - Platform Events (1 class)
/// - Request DTOs (13 classes)
/// - WebSocket models (2 classes)
library;

import 'package:json_annotation/json_annotation.dart';

import 'relay_enums.dart';

part 'relay_models.g.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Channels
// ─────────────────────────────────────────────────────────────────────────────

/// Full channel response with metadata and counts.
@JsonSerializable()
class ChannelResponse {
  /// Unique identifier (UUID).
  final String? id;

  /// Channel name.
  final String? name;

  /// URL-safe slug derived from name.
  final String? slug;

  /// Optional description.
  final String? description;

  /// Channel topic.
  final String? topic;

  /// Channel type.
  @ChannelTypeConverter()
  final ChannelType? channelType;

  /// UUID of the owning team.
  final String? teamId;

  /// UUID of the associated project (for project channels).
  final String? projectId;

  /// UUID of the associated service (for service channels).
  final String? serviceId;

  /// Whether the channel is archived.
  final bool? isArchived;

  /// UUID of the user who created the channel.
  final String? createdBy;

  /// Number of members in the channel.
  final int? memberCount;

  /// Timestamp when the channel was created.
  final DateTime? createdAt;

  /// Timestamp when the channel was last updated.
  final DateTime? updatedAt;

  /// Creates a [ChannelResponse] instance.
  const ChannelResponse({
    this.id,
    this.name,
    this.slug,
    this.description,
    this.topic,
    this.channelType,
    this.teamId,
    this.projectId,
    this.serviceId,
    this.isArchived,
    this.createdBy,
    this.memberCount,
    this.createdAt,
    this.updatedAt,
  });

  /// Deserializes a [ChannelResponse] from a JSON map.
  factory ChannelResponse.fromJson(Map<String, dynamic> json) =>
      _$ChannelResponseFromJson(json);

  /// Serializes this [ChannelResponse] to a JSON map.
  Map<String, dynamic> toJson() => _$ChannelResponseToJson(this);
}

/// Summary channel response for list views.
@JsonSerializable()
class ChannelSummaryResponse {
  /// Unique identifier (UUID).
  final String? id;

  /// Channel name.
  final String? name;

  /// URL-safe slug.
  final String? slug;

  /// Channel type.
  @ChannelTypeConverter()
  final ChannelType? channelType;

  /// Channel topic.
  final String? topic;

  /// Whether the channel is archived.
  final bool? isArchived;

  /// Number of members.
  final int? memberCount;

  /// Number of unread messages for the current user.
  final int? unreadCount;

  /// Timestamp of the last message in the channel.
  final DateTime? lastMessageAt;

  /// Creates a [ChannelSummaryResponse] instance.
  const ChannelSummaryResponse({
    this.id,
    this.name,
    this.slug,
    this.channelType,
    this.topic,
    this.isArchived,
    this.memberCount,
    this.unreadCount,
    this.lastMessageAt,
  });

  /// Deserializes a [ChannelSummaryResponse] from a JSON map.
  factory ChannelSummaryResponse.fromJson(Map<String, dynamic> json) =>
      _$ChannelSummaryResponseFromJson(json);

  /// Serializes this [ChannelSummaryResponse] to a JSON map.
  Map<String, dynamic> toJson() => _$ChannelSummaryResponseToJson(this);
}

/// Channel member response.
@JsonSerializable()
class ChannelMemberResponse {
  /// Unique identifier (UUID).
  final String? id;

  /// UUID of the channel.
  final String? channelId;

  /// UUID of the user.
  final String? userId;

  /// Display name of the user.
  final String? userDisplayName;

  /// Member role in the channel.
  @MemberRoleConverter()
  final MemberRole? role;

  /// Whether the member has muted the channel.
  final bool? isMuted;

  /// Timestamp when the member last read the channel.
  final DateTime? lastReadAt;

  /// Timestamp when the member joined the channel.
  final DateTime? joinedAt;

  /// Creates a [ChannelMemberResponse] instance.
  const ChannelMemberResponse({
    this.id,
    this.channelId,
    this.userId,
    this.userDisplayName,
    this.role,
    this.isMuted,
    this.lastReadAt,
    this.joinedAt,
  });

  /// Deserializes a [ChannelMemberResponse] from a JSON map.
  factory ChannelMemberResponse.fromJson(Map<String, dynamic> json) =>
      _$ChannelMemberResponseFromJson(json);

  /// Serializes this [ChannelMemberResponse] to a JSON map.
  Map<String, dynamic> toJson() => _$ChannelMemberResponseToJson(this);
}

/// Channel search result response.
@JsonSerializable()
class ChannelSearchResultResponse {
  /// UUID of the matched message.
  final String? messageId;

  /// UUID of the channel containing the message.
  final String? channelId;

  /// Name of the channel.
  final String? channelName;

  /// UUID of the message sender.
  final String? senderId;

  /// Display name of the sender.
  final String? senderDisplayName;

  /// Snippet of the message content matching the query.
  final String? contentSnippet;

  /// Timestamp when the message was created.
  final DateTime? createdAt;

  /// Creates a [ChannelSearchResultResponse] instance.
  const ChannelSearchResultResponse({
    this.messageId,
    this.channelId,
    this.channelName,
    this.senderId,
    this.senderDisplayName,
    this.contentSnippet,
    this.createdAt,
  });

  /// Deserializes a [ChannelSearchResultResponse] from a JSON map.
  factory ChannelSearchResultResponse.fromJson(Map<String, dynamic> json) =>
      _$ChannelSearchResultResponseFromJson(json);

  /// Serializes this [ChannelSearchResultResponse] to a JSON map.
  Map<String, dynamic> toJson() => _$ChannelSearchResultResponseToJson(this);
}

// ─────────────────────────────────────────────────────────────────────────────
// Messages
// ─────────────────────────────────────────────────────────────────────────────

/// Full message response including reactions and attachments.
@JsonSerializable(explicitToJson: true)
class MessageResponse {
  /// Unique identifier (UUID).
  final String? id;

  /// UUID of the channel.
  final String? channelId;

  /// UUID of the sender.
  final String? senderId;

  /// Display name of the sender.
  final String? senderDisplayName;

  /// Message content.
  final String? content;

  /// Message type.
  @MessageTypeConverter()
  final MessageType? messageType;

  /// UUID of the parent message (for thread replies).
  final String? parentId;

  /// Whether the message has been edited.
  final bool? isEdited;

  /// Timestamp when the message was edited.
  final DateTime? editedAt;

  /// Whether the message has been soft-deleted.
  final bool? isDeleted;

  /// Whether the message mentions everyone.
  final bool? mentionsEveryone;

  /// List of mentioned user UUIDs.
  final List<String>? mentionedUserIds;

  /// UUID of the associated platform event.
  final String? platformEventId;

  /// Aggregated reaction summaries.
  final List<ReactionSummaryResponse>? reactions;

  /// File attachments.
  final List<FileAttachmentResponse>? attachments;

  /// Number of replies in the thread.
  final int? replyCount;

  /// Timestamp of the last reply in the thread.
  final DateTime? lastReplyAt;

  /// Timestamp when the message was created.
  final DateTime? createdAt;

  /// Timestamp when the message was last updated.
  final DateTime? updatedAt;

  /// Creates a [MessageResponse] instance.
  const MessageResponse({
    this.id,
    this.channelId,
    this.senderId,
    this.senderDisplayName,
    this.content,
    this.messageType,
    this.parentId,
    this.isEdited,
    this.editedAt,
    this.isDeleted,
    this.mentionsEveryone,
    this.mentionedUserIds,
    this.platformEventId,
    this.reactions,
    this.attachments,
    this.replyCount,
    this.lastReplyAt,
    this.createdAt,
    this.updatedAt,
  });

  /// Deserializes a [MessageResponse] from a JSON map.
  factory MessageResponse.fromJson(Map<String, dynamic> json) =>
      _$MessageResponseFromJson(json);

  /// Serializes this [MessageResponse] to a JSON map.
  Map<String, dynamic> toJson() => _$MessageResponseToJson(this);
}

/// Message thread response with root message and replies.
@JsonSerializable(explicitToJson: true)
class MessageThreadResponse {
  /// UUID of the root message.
  final String? rootMessageId;

  /// UUID of the channel.
  final String? channelId;

  /// Number of replies in the thread.
  final int? replyCount;

  /// Timestamp of the last reply.
  final DateTime? lastReplyAt;

  /// UUID of the last replier.
  final String? lastReplyBy;

  /// UUIDs of thread participants.
  final List<String>? participantIds;

  /// Replies in the thread.
  final List<MessageResponse>? replies;

  /// Creates a [MessageThreadResponse] instance.
  const MessageThreadResponse({
    this.rootMessageId,
    this.channelId,
    this.replyCount,
    this.lastReplyAt,
    this.lastReplyBy,
    this.participantIds,
    this.replies,
  });

  /// Deserializes a [MessageThreadResponse] from a JSON map.
  factory MessageThreadResponse.fromJson(Map<String, dynamic> json) =>
      _$MessageThreadResponseFromJson(json);

  /// Serializes this [MessageThreadResponse] to a JSON map.
  Map<String, dynamic> toJson() => _$MessageThreadResponseToJson(this);
}

// ─────────────────────────────────────────────────────────────────────────────
// Direct Messages
// ─────────────────────────────────────────────────────────────────────────────

/// Full direct conversation response.
@JsonSerializable()
class DirectConversationResponse {
  /// Unique identifier (UUID).
  final String? id;

  /// UUID of the team.
  final String? teamId;

  /// Conversation type.
  @ConversationTypeConverter()
  final ConversationType? conversationType;

  /// Optional conversation name (for group conversations).
  final String? name;

  /// UUIDs of participants.
  final List<String>? participantIds;

  /// Timestamp of the last message.
  final DateTime? lastMessageAt;

  /// Preview of the last message.
  final String? lastMessagePreview;

  /// Timestamp when the conversation was created.
  final DateTime? createdAt;

  /// Timestamp when the conversation was last updated.
  final DateTime? updatedAt;

  /// Creates a [DirectConversationResponse] instance.
  const DirectConversationResponse({
    this.id,
    this.teamId,
    this.conversationType,
    this.name,
    this.participantIds,
    this.lastMessageAt,
    this.lastMessagePreview,
    this.createdAt,
    this.updatedAt,
  });

  /// Deserializes a [DirectConversationResponse] from a JSON map.
  factory DirectConversationResponse.fromJson(Map<String, dynamic> json) =>
      _$DirectConversationResponseFromJson(json);

  /// Serializes this [DirectConversationResponse] to a JSON map.
  Map<String, dynamic> toJson() => _$DirectConversationResponseToJson(this);
}

/// Summary direct conversation response for list views.
@JsonSerializable()
class DirectConversationSummaryResponse {
  /// Unique identifier (UUID).
  final String? id;

  /// Conversation type.
  @ConversationTypeConverter()
  final ConversationType? conversationType;

  /// Optional conversation name.
  final String? name;

  /// UUIDs of participants.
  final List<String>? participantIds;

  /// Display names of participants.
  final List<String>? participantDisplayNames;

  /// Preview of the last message.
  final String? lastMessagePreview;

  /// Timestamp of the last message.
  final DateTime? lastMessageAt;

  /// Number of unread messages.
  final int? unreadCount;

  /// Creates a [DirectConversationSummaryResponse] instance.
  const DirectConversationSummaryResponse({
    this.id,
    this.conversationType,
    this.name,
    this.participantIds,
    this.participantDisplayNames,
    this.lastMessagePreview,
    this.lastMessageAt,
    this.unreadCount,
  });

  /// Deserializes a [DirectConversationSummaryResponse] from a JSON map.
  factory DirectConversationSummaryResponse.fromJson(
          Map<String, dynamic> json) =>
      _$DirectConversationSummaryResponseFromJson(json);

  /// Serializes this [DirectConversationSummaryResponse] to a JSON map.
  Map<String, dynamic> toJson() =>
      _$DirectConversationSummaryResponseToJson(this);
}

/// Direct message response.
@JsonSerializable(explicitToJson: true)
class DirectMessageResponse {
  /// Unique identifier (UUID).
  final String? id;

  /// UUID of the conversation.
  final String? conversationId;

  /// UUID of the sender.
  final String? senderId;

  /// Display name of the sender.
  final String? senderDisplayName;

  /// Message content.
  final String? content;

  /// Message type.
  @MessageTypeConverter()
  final MessageType? messageType;

  /// Whether the message has been edited.
  final bool? isEdited;

  /// Timestamp when the message was edited.
  final DateTime? editedAt;

  /// Whether the message has been soft-deleted.
  final bool? isDeleted;

  /// Aggregated reaction summaries.
  final List<ReactionSummaryResponse>? reactions;

  /// File attachments.
  final List<FileAttachmentResponse>? attachments;

  /// Timestamp when the message was created.
  final DateTime? createdAt;

  /// Timestamp when the message was last updated.
  final DateTime? updatedAt;

  /// Creates a [DirectMessageResponse] instance.
  const DirectMessageResponse({
    this.id,
    this.conversationId,
    this.senderId,
    this.senderDisplayName,
    this.content,
    this.messageType,
    this.isEdited,
    this.editedAt,
    this.isDeleted,
    this.reactions,
    this.attachments,
    this.createdAt,
    this.updatedAt,
  });

  /// Deserializes a [DirectMessageResponse] from a JSON map.
  factory DirectMessageResponse.fromJson(Map<String, dynamic> json) =>
      _$DirectMessageResponseFromJson(json);

  /// Serializes this [DirectMessageResponse] to a JSON map.
  Map<String, dynamic> toJson() => _$DirectMessageResponseToJson(this);
}

// ─────────────────────────────────────────────────────────────────────────────
// Reactions
// ─────────────────────────────────────────────────────────────────────────────

/// Full reaction response.
@JsonSerializable()
class ReactionResponse {
  /// Unique identifier (UUID).
  final String? id;

  /// UUID of the user who reacted.
  final String? userId;

  /// Display name of the user.
  final String? userDisplayName;

  /// Emoji string.
  final String? emoji;

  /// Reaction type.
  @ReactionTypeConverter()
  final ReactionType? reactionType;

  /// Timestamp when the reaction was created.
  final DateTime? createdAt;

  /// Creates a [ReactionResponse] instance.
  const ReactionResponse({
    this.id,
    this.userId,
    this.userDisplayName,
    this.emoji,
    this.reactionType,
    this.createdAt,
  });

  /// Deserializes a [ReactionResponse] from a JSON map.
  factory ReactionResponse.fromJson(Map<String, dynamic> json) =>
      _$ReactionResponseFromJson(json);

  /// Serializes this [ReactionResponse] to a JSON map.
  Map<String, dynamic> toJson() => _$ReactionResponseToJson(this);
}

/// Aggregated reaction summary grouped by emoji.
@JsonSerializable()
class ReactionSummaryResponse {
  /// Emoji string.
  final String? emoji;

  /// Total number of reactions with this emoji.
  final int? count;

  /// Whether the current user has reacted with this emoji.
  final bool? currentUserReacted;

  /// UUIDs of users who reacted with this emoji.
  final List<String>? userIds;

  /// Creates a [ReactionSummaryResponse] instance.
  const ReactionSummaryResponse({
    this.emoji,
    this.count,
    this.currentUserReacted,
    this.userIds,
  });

  /// Deserializes a [ReactionSummaryResponse] from a JSON map.
  factory ReactionSummaryResponse.fromJson(Map<String, dynamic> json) =>
      _$ReactionSummaryResponseFromJson(json);

  /// Serializes this [ReactionSummaryResponse] to a JSON map.
  Map<String, dynamic> toJson() => _$ReactionSummaryResponseToJson(this);
}

// ─────────────────────────────────────────────────────────────────────────────
// Files
// ─────────────────────────────────────────────────────────────────────────────

/// File attachment response.
@JsonSerializable()
class FileAttachmentResponse {
  /// Unique identifier (UUID).
  final String? id;

  /// Original file name.
  final String? fileName;

  /// MIME content type.
  final String? contentType;

  /// File size in bytes.
  final int? fileSizeBytes;

  /// Download URL.
  final String? downloadUrl;

  /// Thumbnail URL (for images).
  final String? thumbnailUrl;

  /// Upload status.
  @FileUploadStatusConverter()
  final FileUploadStatus? status;

  /// UUID of the user who uploaded the file.
  final String? uploadedBy;

  /// Timestamp when the file was uploaded.
  final DateTime? createdAt;

  /// Creates a [FileAttachmentResponse] instance.
  const FileAttachmentResponse({
    this.id,
    this.fileName,
    this.contentType,
    this.fileSizeBytes,
    this.downloadUrl,
    this.thumbnailUrl,
    this.status,
    this.uploadedBy,
    this.createdAt,
  });

  /// Deserializes a [FileAttachmentResponse] from a JSON map.
  factory FileAttachmentResponse.fromJson(Map<String, dynamic> json) =>
      _$FileAttachmentResponseFromJson(json);

  /// Serializes this [FileAttachmentResponse] to a JSON map.
  Map<String, dynamic> toJson() => _$FileAttachmentResponseToJson(this);
}

// ─────────────────────────────────────────────────────────────────────────────
// Presence
// ─────────────────────────────────────────────────────────────────────────────

/// User presence response.
@JsonSerializable()
class UserPresenceResponse {
  /// UUID of the user.
  final String? userId;

  /// Display name of the user.
  final String? userDisplayName;

  /// UUID of the team.
  final String? teamId;

  /// Current presence status.
  @PresenceStatusConverter()
  final PresenceStatus? status;

  /// Custom status message.
  final String? statusMessage;

  /// Timestamp when the user was last seen.
  final DateTime? lastSeenAt;

  /// Timestamp when the presence was last updated.
  final DateTime? updatedAt;

  /// Creates a [UserPresenceResponse] instance.
  const UserPresenceResponse({
    this.userId,
    this.userDisplayName,
    this.teamId,
    this.status,
    this.statusMessage,
    this.lastSeenAt,
    this.updatedAt,
  });

  /// Deserializes a [UserPresenceResponse] from a JSON map.
  factory UserPresenceResponse.fromJson(Map<String, dynamic> json) =>
      _$UserPresenceResponseFromJson(json);

  /// Serializes this [UserPresenceResponse] to a JSON map.
  Map<String, dynamic> toJson() => _$UserPresenceResponseToJson(this);
}

// ─────────────────────────────────────────────────────────────────────────────
// Pins, Receipts, Unread
// ─────────────────────────────────────────────────────────────────────────────

/// Pinned message response.
@JsonSerializable(explicitToJson: true)
class PinnedMessageResponse {
  /// Unique identifier (UUID).
  final String? id;

  /// UUID of the pinned message.
  final String? messageId;

  /// UUID of the channel.
  final String? channelId;

  /// The full pinned message.
  final MessageResponse? message;

  /// UUID of the user who pinned the message.
  final String? pinnedBy;

  /// Timestamp when the message was pinned.
  final DateTime? createdAt;

  /// Creates a [PinnedMessageResponse] instance.
  const PinnedMessageResponse({
    this.id,
    this.messageId,
    this.channelId,
    this.message,
    this.pinnedBy,
    this.createdAt,
  });

  /// Deserializes a [PinnedMessageResponse] from a JSON map.
  factory PinnedMessageResponse.fromJson(Map<String, dynamic> json) =>
      _$PinnedMessageResponseFromJson(json);

  /// Serializes this [PinnedMessageResponse] to a JSON map.
  Map<String, dynamic> toJson() => _$PinnedMessageResponseToJson(this);
}

/// Read receipt response.
@JsonSerializable()
class ReadReceiptResponse {
  /// UUID of the channel.
  final String? channelId;

  /// UUID of the user.
  final String? userId;

  /// UUID of the last read message.
  final String? lastReadMessageId;

  /// Timestamp when the messages were last read.
  final DateTime? lastReadAt;

  /// Creates a [ReadReceiptResponse] instance.
  const ReadReceiptResponse({
    this.channelId,
    this.userId,
    this.lastReadMessageId,
    this.lastReadAt,
  });

  /// Deserializes a [ReadReceiptResponse] from a JSON map.
  factory ReadReceiptResponse.fromJson(Map<String, dynamic> json) =>
      _$ReadReceiptResponseFromJson(json);

  /// Serializes this [ReadReceiptResponse] to a JSON map.
  Map<String, dynamic> toJson() => _$ReadReceiptResponseToJson(this);
}

/// Unread count response per channel.
@JsonSerializable()
class UnreadCountResponse {
  /// UUID of the channel.
  final String? channelId;

  /// Channel name.
  final String? channelName;

  /// Channel slug.
  final String? channelSlug;

  /// Number of unread messages.
  final int? unreadCount;

  /// Timestamp when the channel was last read.
  final DateTime? lastReadAt;

  /// Creates an [UnreadCountResponse] instance.
  const UnreadCountResponse({
    this.channelId,
    this.channelName,
    this.channelSlug,
    this.unreadCount,
    this.lastReadAt,
  });

  /// Deserializes an [UnreadCountResponse] from a JSON map.
  factory UnreadCountResponse.fromJson(Map<String, dynamic> json) =>
      _$UnreadCountResponseFromJson(json);

  /// Serializes this [UnreadCountResponse] to a JSON map.
  Map<String, dynamic> toJson() => _$UnreadCountResponseToJson(this);
}

// ─────────────────────────────────────────────────────────────────────────────
// Platform Events
// ─────────────────────────────────────────────────────────────────────────────

/// Platform event response.
@JsonSerializable()
class PlatformEventResponse {
  /// Unique identifier (UUID).
  final String? id;

  /// Event type.
  @PlatformEventTypeConverter()
  final PlatformEventType? eventType;

  /// UUID of the team.
  final String? teamId;

  /// Source module that generated the event.
  final String? sourceModule;

  /// UUID of the source entity.
  final String? sourceEntityId;

  /// Event title.
  final String? title;

  /// Event detail message.
  final String? detail;

  /// UUID of the target channel for delivery.
  final String? targetChannelId;

  /// Slug of the target channel.
  final String? targetChannelSlug;

  /// Whether the event has been delivered.
  final bool? isDelivered;

  /// Timestamp when the event was delivered.
  final DateTime? deliveredAt;

  /// Timestamp when the event was created.
  final DateTime? createdAt;

  /// Creates a [PlatformEventResponse] instance.
  const PlatformEventResponse({
    this.id,
    this.eventType,
    this.teamId,
    this.sourceModule,
    this.sourceEntityId,
    this.title,
    this.detail,
    this.targetChannelId,
    this.targetChannelSlug,
    this.isDelivered,
    this.deliveredAt,
    this.createdAt,
  });

  /// Deserializes a [PlatformEventResponse] from a JSON map.
  factory PlatformEventResponse.fromJson(Map<String, dynamic> json) =>
      _$PlatformEventResponseFromJson(json);

  /// Serializes this [PlatformEventResponse] to a JSON map.
  Map<String, dynamic> toJson() => _$PlatformEventResponseToJson(this);
}

// ─────────────────────────────────────────────────────────────────────────────
// Request DTOs
// ─────────────────────────────────────────────────────────────────────────────

/// Request body for creating a channel.
@JsonSerializable()
class CreateChannelRequest {
  /// Channel name.
  final String name;

  /// Optional description.
  final String? description;

  /// Channel type.
  @ChannelTypeConverter()
  final ChannelType channelType;

  /// Optional topic.
  final String? topic;

  /// Creates a [CreateChannelRequest] instance.
  const CreateChannelRequest({
    required this.name,
    this.description,
    required this.channelType,
    this.topic,
  });

  /// Deserializes a [CreateChannelRequest] from a JSON map.
  factory CreateChannelRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateChannelRequestFromJson(json);

  /// Serializes this [CreateChannelRequest] to a JSON map.
  Map<String, dynamic> toJson() => _$CreateChannelRequestToJson(this);
}

/// Request body for updating a channel.
@JsonSerializable()
class UpdateChannelRequest {
  /// Channel name.
  final String? name;

  /// Optional description.
  final String? description;

  /// Whether the channel is archived.
  final bool? isArchived;

  /// Creates an [UpdateChannelRequest] instance.
  const UpdateChannelRequest({this.name, this.description, this.isArchived});

  /// Deserializes an [UpdateChannelRequest] from a JSON map.
  factory UpdateChannelRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateChannelRequestFromJson(json);

  /// Serializes this [UpdateChannelRequest] to a JSON map.
  Map<String, dynamic> toJson() => _$UpdateChannelRequestToJson(this);
}

/// Request body for updating a channel topic.
@JsonSerializable()
class UpdateChannelTopicRequest {
  /// New topic.
  final String? topic;

  /// Creates an [UpdateChannelTopicRequest] instance.
  const UpdateChannelTopicRequest({this.topic});

  /// Deserializes an [UpdateChannelTopicRequest] from a JSON map.
  factory UpdateChannelTopicRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateChannelTopicRequestFromJson(json);

  /// Serializes this [UpdateChannelTopicRequest] to a JSON map.
  Map<String, dynamic> toJson() => _$UpdateChannelTopicRequestToJson(this);
}

/// Request body for sending a message.
@JsonSerializable()
class SendMessageRequest {
  /// Message content.
  final String content;

  /// UUID of the parent message (for thread replies).
  final String? parentId;

  /// UUIDs of mentioned users.
  final List<String>? mentionedUserIds;

  /// Whether the message mentions everyone.
  final bool? mentionsEveryone;

  /// Creates a [SendMessageRequest] instance.
  const SendMessageRequest({
    required this.content,
    this.parentId,
    this.mentionedUserIds,
    this.mentionsEveryone,
  });

  /// Deserializes a [SendMessageRequest] from a JSON map.
  factory SendMessageRequest.fromJson(Map<String, dynamic> json) =>
      _$SendMessageRequestFromJson(json);

  /// Serializes this [SendMessageRequest] to a JSON map.
  Map<String, dynamic> toJson() => _$SendMessageRequestToJson(this);
}

/// Request body for updating a message.
@JsonSerializable()
class UpdateMessageRequest {
  /// Updated message content.
  final String content;

  /// Creates an [UpdateMessageRequest] instance.
  const UpdateMessageRequest({required this.content});

  /// Deserializes an [UpdateMessageRequest] from a JSON map.
  factory UpdateMessageRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateMessageRequestFromJson(json);

  /// Serializes this [UpdateMessageRequest] to a JSON map.
  Map<String, dynamic> toJson() => _$UpdateMessageRequestToJson(this);
}

/// Request body for creating a direct conversation.
@JsonSerializable()
class CreateDirectConversationRequest {
  /// UUIDs of the participants.
  final List<String> participantIds;

  /// Optional conversation name (for group conversations).
  final String? name;

  /// Creates a [CreateDirectConversationRequest] instance.
  const CreateDirectConversationRequest({
    required this.participantIds,
    this.name,
  });

  /// Deserializes a [CreateDirectConversationRequest] from a JSON map.
  factory CreateDirectConversationRequest.fromJson(
          Map<String, dynamic> json) =>
      _$CreateDirectConversationRequestFromJson(json);

  /// Serializes this [CreateDirectConversationRequest] to a JSON map.
  Map<String, dynamic> toJson() =>
      _$CreateDirectConversationRequestToJson(this);
}

/// Request body for sending a direct message.
@JsonSerializable()
class SendDirectMessageRequest {
  /// Message content.
  final String content;

  /// Creates a [SendDirectMessageRequest] instance.
  const SendDirectMessageRequest({required this.content});

  /// Deserializes a [SendDirectMessageRequest] from a JSON map.
  factory SendDirectMessageRequest.fromJson(Map<String, dynamic> json) =>
      _$SendDirectMessageRequestFromJson(json);

  /// Serializes this [SendDirectMessageRequest] to a JSON map.
  Map<String, dynamic> toJson() => _$SendDirectMessageRequestToJson(this);
}

/// Request body for updating a direct message.
@JsonSerializable()
class UpdateDirectMessageRequest {
  /// Updated message content.
  final String content;

  /// Creates an [UpdateDirectMessageRequest] instance.
  const UpdateDirectMessageRequest({required this.content});

  /// Deserializes an [UpdateDirectMessageRequest] from a JSON map.
  factory UpdateDirectMessageRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateDirectMessageRequestFromJson(json);

  /// Serializes this [UpdateDirectMessageRequest] to a JSON map.
  Map<String, dynamic> toJson() => _$UpdateDirectMessageRequestToJson(this);
}

/// Request body for adding a reaction.
@JsonSerializable()
class AddReactionRequest {
  /// Emoji string.
  final String emoji;

  /// Creates an [AddReactionRequest] instance.
  const AddReactionRequest({required this.emoji});

  /// Deserializes an [AddReactionRequest] from a JSON map.
  factory AddReactionRequest.fromJson(Map<String, dynamic> json) =>
      _$AddReactionRequestFromJson(json);

  /// Serializes this [AddReactionRequest] to a JSON map.
  Map<String, dynamic> toJson() => _$AddReactionRequestToJson(this);
}

/// Request body for pinning a message.
@JsonSerializable()
class PinMessageRequest {
  /// UUID of the message to pin.
  final String messageId;

  /// Creates a [PinMessageRequest] instance.
  const PinMessageRequest({required this.messageId});

  /// Deserializes a [PinMessageRequest] from a JSON map.
  factory PinMessageRequest.fromJson(Map<String, dynamic> json) =>
      _$PinMessageRequestFromJson(json);

  /// Serializes this [PinMessageRequest] to a JSON map.
  Map<String, dynamic> toJson() => _$PinMessageRequestToJson(this);
}

/// Request body for updating presence.
@JsonSerializable()
class UpdatePresenceRequest {
  /// Desired presence status.
  @PresenceStatusConverter()
  final PresenceStatus status;

  /// Custom status message.
  final String? statusMessage;

  /// Creates an [UpdatePresenceRequest] instance.
  const UpdatePresenceRequest({required this.status, this.statusMessage});

  /// Deserializes an [UpdatePresenceRequest] from a JSON map.
  factory UpdatePresenceRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdatePresenceRequestFromJson(json);

  /// Serializes this [UpdatePresenceRequest] to a JSON map.
  Map<String, dynamic> toJson() => _$UpdatePresenceRequestToJson(this);
}

/// Request body for inviting a member to a channel.
@JsonSerializable()
class InviteMemberRequest {
  /// UUID of the user to invite.
  final String userId;

  /// Role to assign (defaults to MEMBER on the server).
  @MemberRoleConverter()
  final MemberRole? role;

  /// Creates an [InviteMemberRequest] instance.
  const InviteMemberRequest({required this.userId, this.role});

  /// Deserializes an [InviteMemberRequest] from a JSON map.
  factory InviteMemberRequest.fromJson(Map<String, dynamic> json) =>
      _$InviteMemberRequestFromJson(json);

  /// Serializes this [InviteMemberRequest] to a JSON map.
  Map<String, dynamic> toJson() => _$InviteMemberRequestToJson(this);
}

/// Request body for updating a member's role.
@JsonSerializable()
class UpdateMemberRoleRequest {
  /// New role for the member.
  @MemberRoleConverter()
  final MemberRole role;

  /// Creates an [UpdateMemberRoleRequest] instance.
  const UpdateMemberRoleRequest({required this.role});

  /// Deserializes an [UpdateMemberRoleRequest] from a JSON map.
  factory UpdateMemberRoleRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateMemberRoleRequestFromJson(json);

  /// Serializes this [UpdateMemberRoleRequest] to a JSON map.
  Map<String, dynamic> toJson() => _$UpdateMemberRoleRequestToJson(this);
}

/// Request body for marking messages as read.
@JsonSerializable()
class MarkReadRequest {
  /// UUID of the last read message.
  final String lastReadMessageId;

  /// Creates a [MarkReadRequest] instance.
  const MarkReadRequest({required this.lastReadMessageId});

  /// Deserializes a [MarkReadRequest] from a JSON map.
  factory MarkReadRequest.fromJson(Map<String, dynamic> json) =>
      _$MarkReadRequestFromJson(json);

  /// Serializes this [MarkReadRequest] to a JSON map.
  Map<String, dynamic> toJson() => _$MarkReadRequestToJson(this);
}

// ─────────────────────────────────────────────────────────────────────────────
// WebSocket Models
// ─────────────────────────────────────────────────────────────────────────────

/// WebSocket connection state.
enum RelayWebSocketState {
  /// Not connected.
  disconnected,

  /// Connection in progress.
  connecting,

  /// Connected and ready.
  connected,

  /// Reconnecting after disconnect.
  reconnecting,
}

/// Typing indicator received from WebSocket.
@JsonSerializable()
class TypingIndicator {
  /// UUID of the channel or conversation.
  final String? channelId;

  /// UUID of the typing user.
  final String? userId;

  /// Display name of the typing user.
  final String? displayName;

  /// Whether the user is currently typing.
  final bool? isTyping;

  /// Creates a [TypingIndicator] instance.
  const TypingIndicator({
    this.channelId,
    this.userId,
    this.displayName,
    this.isTyping,
  });

  /// Deserializes a [TypingIndicator] from a JSON map.
  factory TypingIndicator.fromJson(Map<String, dynamic> json) =>
      _$TypingIndicatorFromJson(json);

  /// Serializes this [TypingIndicator] to a JSON map.
  Map<String, dynamic> toJson() => _$TypingIndicatorToJson(this);
}
