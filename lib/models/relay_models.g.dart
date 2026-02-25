// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'relay_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChannelResponse _$ChannelResponseFromJson(Map<String, dynamic> json) =>
    ChannelResponse(
      id: json['id'] as String?,
      name: json['name'] as String?,
      slug: json['slug'] as String?,
      description: json['description'] as String?,
      topic: json['topic'] as String?,
      channelType: _$JsonConverterFromJson<String, ChannelType>(
          json['channelType'], const ChannelTypeConverter().fromJson),
      teamId: json['teamId'] as String?,
      projectId: json['projectId'] as String?,
      serviceId: json['serviceId'] as String?,
      isArchived: json['isArchived'] as bool?,
      createdBy: json['createdBy'] as String?,
      memberCount: (json['memberCount'] as num?)?.toInt(),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$ChannelResponseToJson(ChannelResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'slug': instance.slug,
      'description': instance.description,
      'topic': instance.topic,
      'channelType': _$JsonConverterToJson<String, ChannelType>(
          instance.channelType, const ChannelTypeConverter().toJson),
      'teamId': instance.teamId,
      'projectId': instance.projectId,
      'serviceId': instance.serviceId,
      'isArchived': instance.isArchived,
      'createdBy': instance.createdBy,
      'memberCount': instance.memberCount,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) =>
    json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) =>
    value == null ? null : toJson(value);

ChannelSummaryResponse _$ChannelSummaryResponseFromJson(
        Map<String, dynamic> json) =>
    ChannelSummaryResponse(
      id: json['id'] as String?,
      name: json['name'] as String?,
      slug: json['slug'] as String?,
      channelType: _$JsonConverterFromJson<String, ChannelType>(
          json['channelType'], const ChannelTypeConverter().fromJson),
      topic: json['topic'] as String?,
      isArchived: json['isArchived'] as bool?,
      memberCount: (json['memberCount'] as num?)?.toInt(),
      unreadCount: (json['unreadCount'] as num?)?.toInt(),
      lastMessageAt: json['lastMessageAt'] == null
          ? null
          : DateTime.parse(json['lastMessageAt'] as String),
    );

Map<String, dynamic> _$ChannelSummaryResponseToJson(
        ChannelSummaryResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'slug': instance.slug,
      'channelType': _$JsonConverterToJson<String, ChannelType>(
          instance.channelType, const ChannelTypeConverter().toJson),
      'topic': instance.topic,
      'isArchived': instance.isArchived,
      'memberCount': instance.memberCount,
      'unreadCount': instance.unreadCount,
      'lastMessageAt': instance.lastMessageAt?.toIso8601String(),
    };

ChannelMemberResponse _$ChannelMemberResponseFromJson(
        Map<String, dynamic> json) =>
    ChannelMemberResponse(
      id: json['id'] as String?,
      channelId: json['channelId'] as String?,
      userId: json['userId'] as String?,
      userDisplayName: json['userDisplayName'] as String?,
      role: _$JsonConverterFromJson<String, MemberRole>(
          json['role'], const MemberRoleConverter().fromJson),
      isMuted: json['isMuted'] as bool?,
      lastReadAt: json['lastReadAt'] == null
          ? null
          : DateTime.parse(json['lastReadAt'] as String),
      joinedAt: json['joinedAt'] == null
          ? null
          : DateTime.parse(json['joinedAt'] as String),
    );

Map<String, dynamic> _$ChannelMemberResponseToJson(
        ChannelMemberResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'channelId': instance.channelId,
      'userId': instance.userId,
      'userDisplayName': instance.userDisplayName,
      'role': _$JsonConverterToJson<String, MemberRole>(
          instance.role, const MemberRoleConverter().toJson),
      'isMuted': instance.isMuted,
      'lastReadAt': instance.lastReadAt?.toIso8601String(),
      'joinedAt': instance.joinedAt?.toIso8601String(),
    };

ChannelSearchResultResponse _$ChannelSearchResultResponseFromJson(
        Map<String, dynamic> json) =>
    ChannelSearchResultResponse(
      messageId: json['messageId'] as String?,
      channelId: json['channelId'] as String?,
      channelName: json['channelName'] as String?,
      senderId: json['senderId'] as String?,
      senderDisplayName: json['senderDisplayName'] as String?,
      contentSnippet: json['contentSnippet'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$ChannelSearchResultResponseToJson(
        ChannelSearchResultResponse instance) =>
    <String, dynamic>{
      'messageId': instance.messageId,
      'channelId': instance.channelId,
      'channelName': instance.channelName,
      'senderId': instance.senderId,
      'senderDisplayName': instance.senderDisplayName,
      'contentSnippet': instance.contentSnippet,
      'createdAt': instance.createdAt?.toIso8601String(),
    };

MessageResponse _$MessageResponseFromJson(Map<String, dynamic> json) =>
    MessageResponse(
      id: json['id'] as String?,
      channelId: json['channelId'] as String?,
      senderId: json['senderId'] as String?,
      senderDisplayName: json['senderDisplayName'] as String?,
      content: json['content'] as String?,
      messageType: _$JsonConverterFromJson<String, MessageType>(
          json['messageType'], const MessageTypeConverter().fromJson),
      parentId: json['parentId'] as String?,
      isEdited: json['isEdited'] as bool?,
      editedAt: json['editedAt'] == null
          ? null
          : DateTime.parse(json['editedAt'] as String),
      isDeleted: json['isDeleted'] as bool?,
      mentionsEveryone: json['mentionsEveryone'] as bool?,
      mentionedUserIds: (json['mentionedUserIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      platformEventId: json['platformEventId'] as String?,
      reactions: (json['reactions'] as List<dynamic>?)
          ?.map((e) =>
              ReactionSummaryResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
      attachments: (json['attachments'] as List<dynamic>?)
          ?.map(
              (e) => FileAttachmentResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
      replyCount: (json['replyCount'] as num?)?.toInt(),
      lastReplyAt: json['lastReplyAt'] == null
          ? null
          : DateTime.parse(json['lastReplyAt'] as String),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$MessageResponseToJson(MessageResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'channelId': instance.channelId,
      'senderId': instance.senderId,
      'senderDisplayName': instance.senderDisplayName,
      'content': instance.content,
      'messageType': _$JsonConverterToJson<String, MessageType>(
          instance.messageType, const MessageTypeConverter().toJson),
      'parentId': instance.parentId,
      'isEdited': instance.isEdited,
      'editedAt': instance.editedAt?.toIso8601String(),
      'isDeleted': instance.isDeleted,
      'mentionsEveryone': instance.mentionsEveryone,
      'mentionedUserIds': instance.mentionedUserIds,
      'platformEventId': instance.platformEventId,
      'reactions': instance.reactions?.map((e) => e.toJson()).toList(),
      'attachments': instance.attachments?.map((e) => e.toJson()).toList(),
      'replyCount': instance.replyCount,
      'lastReplyAt': instance.lastReplyAt?.toIso8601String(),
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

MessageThreadResponse _$MessageThreadResponseFromJson(
        Map<String, dynamic> json) =>
    MessageThreadResponse(
      rootMessageId: json['rootMessageId'] as String?,
      channelId: json['channelId'] as String?,
      replyCount: (json['replyCount'] as num?)?.toInt(),
      lastReplyAt: json['lastReplyAt'] == null
          ? null
          : DateTime.parse(json['lastReplyAt'] as String),
      lastReplyBy: json['lastReplyBy'] as String?,
      participantIds: (json['participantIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      replies: (json['replies'] as List<dynamic>?)
          ?.map((e) => MessageResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$MessageThreadResponseToJson(
        MessageThreadResponse instance) =>
    <String, dynamic>{
      'rootMessageId': instance.rootMessageId,
      'channelId': instance.channelId,
      'replyCount': instance.replyCount,
      'lastReplyAt': instance.lastReplyAt?.toIso8601String(),
      'lastReplyBy': instance.lastReplyBy,
      'participantIds': instance.participantIds,
      'replies': instance.replies?.map((e) => e.toJson()).toList(),
    };

DirectConversationResponse _$DirectConversationResponseFromJson(
        Map<String, dynamic> json) =>
    DirectConversationResponse(
      id: json['id'] as String?,
      teamId: json['teamId'] as String?,
      conversationType: _$JsonConverterFromJson<String, ConversationType>(
          json['conversationType'], const ConversationTypeConverter().fromJson),
      name: json['name'] as String?,
      participantIds: (json['participantIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      lastMessageAt: json['lastMessageAt'] == null
          ? null
          : DateTime.parse(json['lastMessageAt'] as String),
      lastMessagePreview: json['lastMessagePreview'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$DirectConversationResponseToJson(
        DirectConversationResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'teamId': instance.teamId,
      'conversationType': _$JsonConverterToJson<String, ConversationType>(
          instance.conversationType, const ConversationTypeConverter().toJson),
      'name': instance.name,
      'participantIds': instance.participantIds,
      'lastMessageAt': instance.lastMessageAt?.toIso8601String(),
      'lastMessagePreview': instance.lastMessagePreview,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

DirectConversationSummaryResponse _$DirectConversationSummaryResponseFromJson(
        Map<String, dynamic> json) =>
    DirectConversationSummaryResponse(
      id: json['id'] as String?,
      conversationType: _$JsonConverterFromJson<String, ConversationType>(
          json['conversationType'], const ConversationTypeConverter().fromJson),
      name: json['name'] as String?,
      participantIds: (json['participantIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      participantDisplayNames:
          (json['participantDisplayNames'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList(),
      lastMessagePreview: json['lastMessagePreview'] as String?,
      lastMessageAt: json['lastMessageAt'] == null
          ? null
          : DateTime.parse(json['lastMessageAt'] as String),
      unreadCount: (json['unreadCount'] as num?)?.toInt(),
    );

Map<String, dynamic> _$DirectConversationSummaryResponseToJson(
        DirectConversationSummaryResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'conversationType': _$JsonConverterToJson<String, ConversationType>(
          instance.conversationType, const ConversationTypeConverter().toJson),
      'name': instance.name,
      'participantIds': instance.participantIds,
      'participantDisplayNames': instance.participantDisplayNames,
      'lastMessagePreview': instance.lastMessagePreview,
      'lastMessageAt': instance.lastMessageAt?.toIso8601String(),
      'unreadCount': instance.unreadCount,
    };

DirectMessageResponse _$DirectMessageResponseFromJson(
        Map<String, dynamic> json) =>
    DirectMessageResponse(
      id: json['id'] as String?,
      conversationId: json['conversationId'] as String?,
      senderId: json['senderId'] as String?,
      senderDisplayName: json['senderDisplayName'] as String?,
      content: json['content'] as String?,
      messageType: _$JsonConverterFromJson<String, MessageType>(
          json['messageType'], const MessageTypeConverter().fromJson),
      isEdited: json['isEdited'] as bool?,
      editedAt: json['editedAt'] == null
          ? null
          : DateTime.parse(json['editedAt'] as String),
      isDeleted: json['isDeleted'] as bool?,
      reactions: (json['reactions'] as List<dynamic>?)
          ?.map((e) =>
              ReactionSummaryResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
      attachments: (json['attachments'] as List<dynamic>?)
          ?.map(
              (e) => FileAttachmentResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$DirectMessageResponseToJson(
        DirectMessageResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'conversationId': instance.conversationId,
      'senderId': instance.senderId,
      'senderDisplayName': instance.senderDisplayName,
      'content': instance.content,
      'messageType': _$JsonConverterToJson<String, MessageType>(
          instance.messageType, const MessageTypeConverter().toJson),
      'isEdited': instance.isEdited,
      'editedAt': instance.editedAt?.toIso8601String(),
      'isDeleted': instance.isDeleted,
      'reactions': instance.reactions?.map((e) => e.toJson()).toList(),
      'attachments': instance.attachments?.map((e) => e.toJson()).toList(),
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

ReactionResponse _$ReactionResponseFromJson(Map<String, dynamic> json) =>
    ReactionResponse(
      id: json['id'] as String?,
      userId: json['userId'] as String?,
      userDisplayName: json['userDisplayName'] as String?,
      emoji: json['emoji'] as String?,
      reactionType: _$JsonConverterFromJson<String, ReactionType>(
          json['reactionType'], const ReactionTypeConverter().fromJson),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$ReactionResponseToJson(ReactionResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'userDisplayName': instance.userDisplayName,
      'emoji': instance.emoji,
      'reactionType': _$JsonConverterToJson<String, ReactionType>(
          instance.reactionType, const ReactionTypeConverter().toJson),
      'createdAt': instance.createdAt?.toIso8601String(),
    };

ReactionSummaryResponse _$ReactionSummaryResponseFromJson(
        Map<String, dynamic> json) =>
    ReactionSummaryResponse(
      emoji: json['emoji'] as String?,
      count: (json['count'] as num?)?.toInt(),
      currentUserReacted: json['currentUserReacted'] as bool?,
      userIds:
          (json['userIds'] as List<dynamic>?)?.map((e) => e as String).toList(),
    );

Map<String, dynamic> _$ReactionSummaryResponseToJson(
        ReactionSummaryResponse instance) =>
    <String, dynamic>{
      'emoji': instance.emoji,
      'count': instance.count,
      'currentUserReacted': instance.currentUserReacted,
      'userIds': instance.userIds,
    };

FileAttachmentResponse _$FileAttachmentResponseFromJson(
        Map<String, dynamic> json) =>
    FileAttachmentResponse(
      id: json['id'] as String?,
      fileName: json['fileName'] as String?,
      contentType: json['contentType'] as String?,
      fileSizeBytes: (json['fileSizeBytes'] as num?)?.toInt(),
      downloadUrl: json['downloadUrl'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      status: _$JsonConverterFromJson<String, FileUploadStatus>(
          json['status'], const FileUploadStatusConverter().fromJson),
      uploadedBy: json['uploadedBy'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$FileAttachmentResponseToJson(
        FileAttachmentResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fileName': instance.fileName,
      'contentType': instance.contentType,
      'fileSizeBytes': instance.fileSizeBytes,
      'downloadUrl': instance.downloadUrl,
      'thumbnailUrl': instance.thumbnailUrl,
      'status': _$JsonConverterToJson<String, FileUploadStatus>(
          instance.status, const FileUploadStatusConverter().toJson),
      'uploadedBy': instance.uploadedBy,
      'createdAt': instance.createdAt?.toIso8601String(),
    };

UserPresenceResponse _$UserPresenceResponseFromJson(
        Map<String, dynamic> json) =>
    UserPresenceResponse(
      userId: json['userId'] as String?,
      userDisplayName: json['userDisplayName'] as String?,
      teamId: json['teamId'] as String?,
      status: _$JsonConverterFromJson<String, PresenceStatus>(
          json['status'], const PresenceStatusConverter().fromJson),
      statusMessage: json['statusMessage'] as String?,
      lastSeenAt: json['lastSeenAt'] == null
          ? null
          : DateTime.parse(json['lastSeenAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$UserPresenceResponseToJson(
        UserPresenceResponse instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'userDisplayName': instance.userDisplayName,
      'teamId': instance.teamId,
      'status': _$JsonConverterToJson<String, PresenceStatus>(
          instance.status, const PresenceStatusConverter().toJson),
      'statusMessage': instance.statusMessage,
      'lastSeenAt': instance.lastSeenAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

PinnedMessageResponse _$PinnedMessageResponseFromJson(
        Map<String, dynamic> json) =>
    PinnedMessageResponse(
      id: json['id'] as String?,
      messageId: json['messageId'] as String?,
      channelId: json['channelId'] as String?,
      message: json['message'] == null
          ? null
          : MessageResponse.fromJson(json['message'] as Map<String, dynamic>),
      pinnedBy: json['pinnedBy'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$PinnedMessageResponseToJson(
        PinnedMessageResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'messageId': instance.messageId,
      'channelId': instance.channelId,
      'message': instance.message?.toJson(),
      'pinnedBy': instance.pinnedBy,
      'createdAt': instance.createdAt?.toIso8601String(),
    };

ReadReceiptResponse _$ReadReceiptResponseFromJson(Map<String, dynamic> json) =>
    ReadReceiptResponse(
      channelId: json['channelId'] as String?,
      userId: json['userId'] as String?,
      lastReadMessageId: json['lastReadMessageId'] as String?,
      lastReadAt: json['lastReadAt'] == null
          ? null
          : DateTime.parse(json['lastReadAt'] as String),
    );

Map<String, dynamic> _$ReadReceiptResponseToJson(
        ReadReceiptResponse instance) =>
    <String, dynamic>{
      'channelId': instance.channelId,
      'userId': instance.userId,
      'lastReadMessageId': instance.lastReadMessageId,
      'lastReadAt': instance.lastReadAt?.toIso8601String(),
    };

UnreadCountResponse _$UnreadCountResponseFromJson(Map<String, dynamic> json) =>
    UnreadCountResponse(
      channelId: json['channelId'] as String?,
      channelName: json['channelName'] as String?,
      channelSlug: json['channelSlug'] as String?,
      unreadCount: (json['unreadCount'] as num?)?.toInt(),
      lastReadAt: json['lastReadAt'] == null
          ? null
          : DateTime.parse(json['lastReadAt'] as String),
    );

Map<String, dynamic> _$UnreadCountResponseToJson(
        UnreadCountResponse instance) =>
    <String, dynamic>{
      'channelId': instance.channelId,
      'channelName': instance.channelName,
      'channelSlug': instance.channelSlug,
      'unreadCount': instance.unreadCount,
      'lastReadAt': instance.lastReadAt?.toIso8601String(),
    };

PlatformEventResponse _$PlatformEventResponseFromJson(
        Map<String, dynamic> json) =>
    PlatformEventResponse(
      id: json['id'] as String?,
      eventType: _$JsonConverterFromJson<String, PlatformEventType>(
          json['eventType'], const PlatformEventTypeConverter().fromJson),
      teamId: json['teamId'] as String?,
      sourceModule: json['sourceModule'] as String?,
      sourceEntityId: json['sourceEntityId'] as String?,
      title: json['title'] as String?,
      detail: json['detail'] as String?,
      targetChannelId: json['targetChannelId'] as String?,
      targetChannelSlug: json['targetChannelSlug'] as String?,
      isDelivered: json['isDelivered'] as bool?,
      deliveredAt: json['deliveredAt'] == null
          ? null
          : DateTime.parse(json['deliveredAt'] as String),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$PlatformEventResponseToJson(
        PlatformEventResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'eventType': _$JsonConverterToJson<String, PlatformEventType>(
          instance.eventType, const PlatformEventTypeConverter().toJson),
      'teamId': instance.teamId,
      'sourceModule': instance.sourceModule,
      'sourceEntityId': instance.sourceEntityId,
      'title': instance.title,
      'detail': instance.detail,
      'targetChannelId': instance.targetChannelId,
      'targetChannelSlug': instance.targetChannelSlug,
      'isDelivered': instance.isDelivered,
      'deliveredAt': instance.deliveredAt?.toIso8601String(),
      'createdAt': instance.createdAt?.toIso8601String(),
    };

CreateChannelRequest _$CreateChannelRequestFromJson(
        Map<String, dynamic> json) =>
    CreateChannelRequest(
      name: json['name'] as String,
      description: json['description'] as String?,
      channelType:
          const ChannelTypeConverter().fromJson(json['channelType'] as String),
      topic: json['topic'] as String?,
    );

Map<String, dynamic> _$CreateChannelRequestToJson(
        CreateChannelRequest instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'channelType': const ChannelTypeConverter().toJson(instance.channelType),
      'topic': instance.topic,
    };

UpdateChannelRequest _$UpdateChannelRequestFromJson(
        Map<String, dynamic> json) =>
    UpdateChannelRequest(
      name: json['name'] as String?,
      description: json['description'] as String?,
      isArchived: json['isArchived'] as bool?,
    );

Map<String, dynamic> _$UpdateChannelRequestToJson(
        UpdateChannelRequest instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'isArchived': instance.isArchived,
    };

UpdateChannelTopicRequest _$UpdateChannelTopicRequestFromJson(
        Map<String, dynamic> json) =>
    UpdateChannelTopicRequest(
      topic: json['topic'] as String?,
    );

Map<String, dynamic> _$UpdateChannelTopicRequestToJson(
        UpdateChannelTopicRequest instance) =>
    <String, dynamic>{
      'topic': instance.topic,
    };

SendMessageRequest _$SendMessageRequestFromJson(Map<String, dynamic> json) =>
    SendMessageRequest(
      content: json['content'] as String,
      parentId: json['parentId'] as String?,
      mentionedUserIds: (json['mentionedUserIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      mentionsEveryone: json['mentionsEveryone'] as bool?,
    );

Map<String, dynamic> _$SendMessageRequestToJson(SendMessageRequest instance) =>
    <String, dynamic>{
      'content': instance.content,
      'parentId': instance.parentId,
      'mentionedUserIds': instance.mentionedUserIds,
      'mentionsEveryone': instance.mentionsEveryone,
    };

UpdateMessageRequest _$UpdateMessageRequestFromJson(
        Map<String, dynamic> json) =>
    UpdateMessageRequest(
      content: json['content'] as String,
    );

Map<String, dynamic> _$UpdateMessageRequestToJson(
        UpdateMessageRequest instance) =>
    <String, dynamic>{
      'content': instance.content,
    };

CreateDirectConversationRequest _$CreateDirectConversationRequestFromJson(
        Map<String, dynamic> json) =>
    CreateDirectConversationRequest(
      participantIds: (json['participantIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      name: json['name'] as String?,
    );

Map<String, dynamic> _$CreateDirectConversationRequestToJson(
        CreateDirectConversationRequest instance) =>
    <String, dynamic>{
      'participantIds': instance.participantIds,
      'name': instance.name,
    };

SendDirectMessageRequest _$SendDirectMessageRequestFromJson(
        Map<String, dynamic> json) =>
    SendDirectMessageRequest(
      content: json['content'] as String,
    );

Map<String, dynamic> _$SendDirectMessageRequestToJson(
        SendDirectMessageRequest instance) =>
    <String, dynamic>{
      'content': instance.content,
    };

UpdateDirectMessageRequest _$UpdateDirectMessageRequestFromJson(
        Map<String, dynamic> json) =>
    UpdateDirectMessageRequest(
      content: json['content'] as String,
    );

Map<String, dynamic> _$UpdateDirectMessageRequestToJson(
        UpdateDirectMessageRequest instance) =>
    <String, dynamic>{
      'content': instance.content,
    };

AddReactionRequest _$AddReactionRequestFromJson(Map<String, dynamic> json) =>
    AddReactionRequest(
      emoji: json['emoji'] as String,
    );

Map<String, dynamic> _$AddReactionRequestToJson(AddReactionRequest instance) =>
    <String, dynamic>{
      'emoji': instance.emoji,
    };

PinMessageRequest _$PinMessageRequestFromJson(Map<String, dynamic> json) =>
    PinMessageRequest(
      messageId: json['messageId'] as String,
    );

Map<String, dynamic> _$PinMessageRequestToJson(PinMessageRequest instance) =>
    <String, dynamic>{
      'messageId': instance.messageId,
    };

UpdatePresenceRequest _$UpdatePresenceRequestFromJson(
        Map<String, dynamic> json) =>
    UpdatePresenceRequest(
      status:
          const PresenceStatusConverter().fromJson(json['status'] as String),
      statusMessage: json['statusMessage'] as String?,
    );

Map<String, dynamic> _$UpdatePresenceRequestToJson(
        UpdatePresenceRequest instance) =>
    <String, dynamic>{
      'status': const PresenceStatusConverter().toJson(instance.status),
      'statusMessage': instance.statusMessage,
    };

InviteMemberRequest _$InviteMemberRequestFromJson(Map<String, dynamic> json) =>
    InviteMemberRequest(
      userId: json['userId'] as String,
      role: _$JsonConverterFromJson<String, MemberRole>(
          json['role'], const MemberRoleConverter().fromJson),
    );

Map<String, dynamic> _$InviteMemberRequestToJson(
        InviteMemberRequest instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'role': _$JsonConverterToJson<String, MemberRole>(
          instance.role, const MemberRoleConverter().toJson),
    };

UpdateMemberRoleRequest _$UpdateMemberRoleRequestFromJson(
        Map<String, dynamic> json) =>
    UpdateMemberRoleRequest(
      role: const MemberRoleConverter().fromJson(json['role'] as String),
    );

Map<String, dynamic> _$UpdateMemberRoleRequestToJson(
        UpdateMemberRoleRequest instance) =>
    <String, dynamic>{
      'role': const MemberRoleConverter().toJson(instance.role),
    };

MarkReadRequest _$MarkReadRequestFromJson(Map<String, dynamic> json) =>
    MarkReadRequest(
      lastReadMessageId: json['lastReadMessageId'] as String,
    );

Map<String, dynamic> _$MarkReadRequestToJson(MarkReadRequest instance) =>
    <String, dynamic>{
      'lastReadMessageId': instance.lastReadMessageId,
    };

TypingIndicator _$TypingIndicatorFromJson(Map<String, dynamic> json) =>
    TypingIndicator(
      channelId: json['channelId'] as String?,
      userId: json['userId'] as String?,
      displayName: json['displayName'] as String?,
      isTyping: json['isTyping'] as bool?,
    );

Map<String, dynamic> _$TypingIndicatorToJson(TypingIndicator instance) =>
    <String, dynamic>{
      'channelId': instance.channelId,
      'userId': instance.userId,
      'displayName': instance.displayName,
      'isTyping': instance.isTyping,
    };
