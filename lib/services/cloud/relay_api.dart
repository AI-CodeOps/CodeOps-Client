/// API service for the CodeOps-Relay module.
///
/// Provides access to channels, messages, threads, direct messages,
/// reactions, file attachments, presence, platform events, and health —
/// totaling 59 endpoint methods across 8 controllers.
///
/// All team-scoped endpoints require a `teamId` parameter which is sent
/// as the `X-Team-ID` header.
library;

import 'package:dio/dio.dart';

import '../../models/health_snapshot.dart';
import '../../models/relay_enums.dart';
import '../../models/relay_models.dart';
import 'api_client.dart';

/// API service for CodeOps-Relay.
///
/// Depends on [ApiClient] for HTTP transport with automatic auth and
/// error handling. Uses [ApiClient.dio] directly to attach the
/// `X-Team-ID` header required by Relay endpoints.
class RelayApiService {
  final ApiClient _client;
  static const _base = '/relay';

  /// Creates a [RelayApiService] backed by the given [client].
  RelayApiService(this._client);

  /// Builds [Options] with the `X-Team-ID` header.
  Options _teamOpts(String teamId) =>
      Options(headers: {'X-Team-ID': teamId});

  // ═══════════════════════════════════════════════════════════════════════════
  // Channels
  // ═══════════════════════════════════════════════════════════════════════════

  /// Creates a new channel.
  Future<ChannelResponse> createChannel(
    String teamId,
    CreateChannelRequest request,
  ) async {
    final r = await _client.dio.post<Map<String, dynamic>>(
      '$_base/channels',
      data: request.toJson(),
      queryParameters: {'teamId': teamId},
      options: _teamOpts(teamId),
    );
    return ChannelResponse.fromJson(r.data!);
  }

  /// Lists channels for the team with pagination.
  Future<PageResponse<ChannelSummaryResponse>> getChannels(
    String teamId, {
    int page = 0,
    int size = 50,
  }) async {
    final r = await _client.dio.get<Map<String, dynamic>>(
      '$_base/channels',
      queryParameters: {'teamId': teamId, 'page': page, 'size': size},
      options: _teamOpts(teamId),
    );
    return PageResponse.fromJson(
      r.data!,
      (o) => ChannelSummaryResponse.fromJson(o as Map<String, dynamic>),
    );
  }

  /// Gets a channel by ID.
  Future<ChannelResponse> getChannel(
    String channelId,
    String teamId,
  ) async {
    final r = await _client.dio.get<Map<String, dynamic>>(
      '$_base/channels/$channelId',
      queryParameters: {'teamId': teamId},
      options: _teamOpts(teamId),
    );
    return ChannelResponse.fromJson(r.data!);
  }

  /// Updates a channel.
  Future<ChannelResponse> updateChannel(
    String channelId,
    UpdateChannelRequest request,
    String teamId,
  ) async {
    final r = await _client.dio.put<Map<String, dynamic>>(
      '$_base/channels/$channelId',
      data: request.toJson(),
      queryParameters: {'teamId': teamId},
      options: _teamOpts(teamId),
    );
    return ChannelResponse.fromJson(r.data!);
  }

  /// Deletes a channel.
  Future<void> deleteChannel(String channelId, String teamId) async {
    await _client.dio.delete<dynamic>(
      '$_base/channels/$channelId',
      queryParameters: {'teamId': teamId},
      options: _teamOpts(teamId),
    );
  }

  /// Archives a channel.
  Future<ChannelResponse> archiveChannel(
    String channelId,
    String teamId,
  ) async {
    final r = await _client.dio.post<Map<String, dynamic>>(
      '$_base/channels/$channelId/archive',
      queryParameters: {'teamId': teamId},
      options: _teamOpts(teamId),
    );
    return ChannelResponse.fromJson(r.data!);
  }

  /// Unarchives a channel.
  Future<ChannelResponse> unarchiveChannel(
    String channelId,
    String teamId,
  ) async {
    final r = await _client.dio.post<Map<String, dynamic>>(
      '$_base/channels/$channelId/unarchive',
      queryParameters: {'teamId': teamId},
      options: _teamOpts(teamId),
    );
    return ChannelResponse.fromJson(r.data!);
  }

  /// Updates a channel's topic.
  Future<ChannelResponse> updateTopic(
    String channelId,
    UpdateChannelTopicRequest request,
    String teamId,
  ) async {
    final r = await _client.dio.patch<Map<String, dynamic>>(
      '$_base/channels/$channelId/topic',
      data: request.toJson(),
      queryParameters: {'teamId': teamId},
      options: _teamOpts(teamId),
    );
    return ChannelResponse.fromJson(r.data!);
  }

  /// Joins a public/project/service channel.
  Future<ChannelMemberResponse> joinChannel(
    String channelId,
    String teamId,
  ) async {
    final r = await _client.dio.post<Map<String, dynamic>>(
      '$_base/channels/$channelId/join',
      queryParameters: {'teamId': teamId},
      options: _teamOpts(teamId),
    );
    return ChannelMemberResponse.fromJson(r.data!);
  }

  /// Leaves a channel.
  Future<void> leaveChannel(String channelId, String teamId) async {
    await _client.dio.post<dynamic>(
      '$_base/channels/$channelId/leave',
      queryParameters: {'teamId': teamId},
      options: _teamOpts(teamId),
    );
  }

  /// Invites a member to a channel.
  Future<ChannelMemberResponse> inviteMember(
    String channelId,
    InviteMemberRequest request,
    String teamId,
  ) async {
    final r = await _client.dio.post<Map<String, dynamic>>(
      '$_base/channels/$channelId/members/invite',
      data: request.toJson(),
      queryParameters: {'teamId': teamId},
      options: _teamOpts(teamId),
    );
    return ChannelMemberResponse.fromJson(r.data!);
  }

  /// Removes a member from a channel.
  Future<void> removeMember(
    String channelId,
    String targetUserId,
    String teamId,
  ) async {
    await _client.dio.delete<dynamic>(
      '$_base/channels/$channelId/members/$targetUserId',
      queryParameters: {'teamId': teamId},
      options: _teamOpts(teamId),
    );
  }

  /// Updates a member's role in a channel.
  Future<ChannelMemberResponse> updateMemberRole(
    String channelId,
    String targetUserId,
    UpdateMemberRoleRequest request,
    String teamId,
  ) async {
    final r = await _client.dio.put<Map<String, dynamic>>(
      '$_base/channels/$channelId/members/$targetUserId/role',
      data: request.toJson(),
      queryParameters: {'teamId': teamId},
      options: _teamOpts(teamId),
    );
    return ChannelMemberResponse.fromJson(r.data!);
  }

  /// Gets all members of a channel.
  Future<List<ChannelMemberResponse>> getMembers(
    String channelId,
    String teamId,
  ) async {
    final r = await _client.dio.get<List<dynamic>>(
      '$_base/channels/$channelId/members',
      queryParameters: {'teamId': teamId},
      options: _teamOpts(teamId),
    );
    return r.data!
        .cast<Map<String, dynamic>>()
        .map(ChannelMemberResponse.fromJson)
        .toList();
  }

  /// Pins a message in a channel.
  Future<PinnedMessageResponse> pinMessage(
    String channelId,
    PinMessageRequest request,
    String teamId,
  ) async {
    final r = await _client.dio.post<Map<String, dynamic>>(
      '$_base/channels/$channelId/pins',
      data: request.toJson(),
      queryParameters: {'teamId': teamId},
      options: _teamOpts(teamId),
    );
    return PinnedMessageResponse.fromJson(r.data!);
  }

  /// Unpins a message from a channel.
  Future<void> unpinMessage(
    String channelId,
    String messageId,
    String teamId,
  ) async {
    await _client.dio.delete<dynamic>(
      '$_base/channels/$channelId/pins/$messageId',
      queryParameters: {'teamId': teamId},
      options: _teamOpts(teamId),
    );
  }

  /// Gets pinned messages for a channel.
  Future<List<PinnedMessageResponse>> getPinnedMessages(
    String channelId,
    String teamId,
  ) async {
    final r = await _client.dio.get<List<dynamic>>(
      '$_base/channels/$channelId/pins',
      queryParameters: {'teamId': teamId},
      options: _teamOpts(teamId),
    );
    return r.data!
        .cast<Map<String, dynamic>>()
        .map(PinnedMessageResponse.fromJson)
        .toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Messages
  // ═══════════════════════════════════════════════════════════════════════════

  /// Sends a message to a channel.
  Future<MessageResponse> sendMessage(
    String channelId,
    SendMessageRequest request,
    String teamId,
  ) async {
    final r = await _client.dio.post<Map<String, dynamic>>(
      '$_base/channels/$channelId/messages',
      data: request.toJson(),
      queryParameters: {'teamId': teamId},
      options: _teamOpts(teamId),
    );
    return MessageResponse.fromJson(r.data!);
  }

  /// Gets paginated messages for a channel.
  Future<PageResponse<MessageResponse>> getChannelMessages(
    String channelId,
    String teamId, {
    int page = 0,
    int size = 50,
  }) async {
    final r = await _client.dio.get<Map<String, dynamic>>(
      '$_base/channels/$channelId/messages',
      queryParameters: {
        'teamId': teamId,
        'page': page,
        'size': size,
      },
      options: _teamOpts(teamId),
    );
    return PageResponse.fromJson(
      r.data!,
      (o) => MessageResponse.fromJson(o as Map<String, dynamic>),
    );
  }

  /// Gets a single message by ID.
  Future<MessageResponse> getMessage(
    String channelId,
    String messageId,
  ) async {
    final r = await _client.dio.get<Map<String, dynamic>>(
      '$_base/channels/$channelId/messages/$messageId',
    );
    return MessageResponse.fromJson(r.data!);
  }

  /// Edits a message.
  Future<MessageResponse> editMessage(
    String channelId,
    String messageId,
    UpdateMessageRequest request,
  ) async {
    final r = await _client.dio.put<Map<String, dynamic>>(
      '$_base/channels/$channelId/messages/$messageId',
      data: request.toJson(),
    );
    return MessageResponse.fromJson(r.data!);
  }

  /// Deletes a message.
  Future<void> deleteMessage(
    String channelId,
    String messageId,
    String teamId,
  ) async {
    await _client.dio.delete<dynamic>(
      '$_base/channels/$channelId/messages/$messageId',
      queryParameters: {'teamId': teamId},
      options: _teamOpts(teamId),
    );
  }

  /// Gets thread replies for a parent message.
  Future<List<MessageResponse>> getThreadReplies(
    String channelId,
    String parentMessageId,
  ) async {
    final r = await _client.dio.get<List<dynamic>>(
      '$_base/channels/$channelId/messages/$parentMessageId/thread',
    );
    return r.data!
        .cast<Map<String, dynamic>>()
        .map(MessageResponse.fromJson)
        .toList();
  }

  /// Gets active threads in a channel.
  Future<List<MessageThreadResponse>> getActiveThreads(
    String channelId,
  ) async {
    final r = await _client.dio.get<List<dynamic>>(
      '$_base/channels/$channelId/threads/active',
    );
    return r.data!
        .cast<Map<String, dynamic>>()
        .map(MessageThreadResponse.fromJson)
        .toList();
  }

  /// Searches messages within a channel.
  Future<PageResponse<MessageResponse>> searchMessages(
    String channelId,
    String query,
    String teamId, {
    int page = 0,
    int size = 50,
  }) async {
    final r = await _client.dio.get<Map<String, dynamic>>(
      '$_base/channels/$channelId/messages/search',
      queryParameters: {
        'query': query,
        'teamId': teamId,
        'page': page,
        'size': size,
      },
      options: _teamOpts(teamId),
    );
    return PageResponse.fromJson(
      r.data!,
      (o) => MessageResponse.fromJson(o as Map<String, dynamic>),
    );
  }

  /// Searches messages across all channels.
  Future<PageResponse<ChannelSearchResultResponse>>
      searchMessagesAcrossChannels(
    String query,
    String teamId, {
    int page = 0,
    int size = 50,
  }) async {
    final r = await _client.dio.get<Map<String, dynamic>>(
      '$_base/messages/search-all',
      queryParameters: {
        'query': query,
        'teamId': teamId,
        'page': page,
        'size': size,
      },
      options: _teamOpts(teamId),
    );
    return PageResponse.fromJson(
      r.data!,
      (o) => ChannelSearchResultResponse.fromJson(o as Map<String, dynamic>),
    );
  }

  /// Marks messages as read in a channel.
  Future<ReadReceiptResponse> markRead(
    String channelId,
    MarkReadRequest request,
  ) async {
    final r = await _client.dio.post<Map<String, dynamic>>(
      '$_base/channels/$channelId/messages/read',
      data: request.toJson(),
    );
    return ReadReceiptResponse.fromJson(r.data!);
  }

  /// Gets unread counts for all channels in a team.
  Future<List<UnreadCountResponse>> getUnreadCounts(String teamId) async {
    final r = await _client.dio.get<List<dynamic>>(
      '$_base/messages/unread-counts',
      queryParameters: {'teamId': teamId},
      options: _teamOpts(teamId),
    );
    return r.data!
        .cast<Map<String, dynamic>>()
        .map(UnreadCountResponse.fromJson)
        .toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Direct Messages
  // ═══════════════════════════════════════════════════════════════════════════

  /// Gets or creates a direct conversation.
  Future<DirectConversationResponse> getOrCreateConversation(
    CreateDirectConversationRequest request,
    String teamId,
  ) async {
    final r = await _client.dio.post<Map<String, dynamic>>(
      '$_base/dm/conversations',
      data: request.toJson(),
      queryParameters: {'teamId': teamId},
      options: _teamOpts(teamId),
    );
    return DirectConversationResponse.fromJson(r.data!);
  }

  /// Lists direct conversations for the current user.
  Future<List<DirectConversationSummaryResponse>> getConversations(
    String teamId,
  ) async {
    final r = await _client.dio.get<List<dynamic>>(
      '$_base/dm/conversations',
      queryParameters: {'teamId': teamId},
      options: _teamOpts(teamId),
    );
    return r.data!
        .cast<Map<String, dynamic>>()
        .map(DirectConversationSummaryResponse.fromJson)
        .toList();
  }

  /// Gets a direct conversation by ID.
  Future<DirectConversationResponse> getConversation(
    String conversationId,
  ) async {
    final r = await _client.dio.get<Map<String, dynamic>>(
      '$_base/dm/conversations/$conversationId',
    );
    return DirectConversationResponse.fromJson(r.data!);
  }

  /// Deletes a direct conversation.
  Future<void> deleteConversation(String conversationId) async {
    await _client.dio.delete<dynamic>(
      '$_base/dm/conversations/$conversationId',
    );
  }

  /// Sends a direct message.
  Future<DirectMessageResponse> sendDirectMessage(
    String conversationId,
    SendDirectMessageRequest request,
  ) async {
    final r = await _client.dio.post<Map<String, dynamic>>(
      '$_base/dm/conversations/$conversationId/messages',
      data: request.toJson(),
    );
    return DirectMessageResponse.fromJson(r.data!);
  }

  /// Gets paginated messages in a direct conversation.
  Future<PageResponse<DirectMessageResponse>> getDirectMessages(
    String conversationId, {
    int page = 0,
    int size = 50,
  }) async {
    final r = await _client.dio.get<Map<String, dynamic>>(
      '$_base/dm/conversations/$conversationId/messages',
      queryParameters: {'page': page, 'size': size},
    );
    return PageResponse.fromJson(
      r.data!,
      (o) => DirectMessageResponse.fromJson(o as Map<String, dynamic>),
    );
  }

  /// Edits a direct message.
  Future<DirectMessageResponse> editDirectMessage(
    String messageId,
    UpdateDirectMessageRequest request,
  ) async {
    final r = await _client.dio.put<Map<String, dynamic>>(
      '$_base/dm/messages/$messageId',
      data: request.toJson(),
    );
    return DirectMessageResponse.fromJson(r.data!);
  }

  /// Deletes a direct message.
  Future<void> deleteDirectMessage(String messageId) async {
    await _client.dio.delete<dynamic>(
      '$_base/dm/messages/$messageId',
    );
  }

  /// Marks a direct conversation as read.
  Future<void> markConversationRead(String conversationId) async {
    await _client.dio.post<dynamic>(
      '$_base/dm/conversations/$conversationId/read',
    );
  }

  /// Gets the unread count for a direct conversation.
  Future<int> getDirectMessageUnreadCount(String conversationId) async {
    final r = await _client.dio.get<Map<String, dynamic>>(
      '$_base/dm/conversations/$conversationId/unread',
    );
    return (r.data!['unreadCount'] as num).toInt();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Reactions
  // ═══════════════════════════════════════════════════════════════════════════

  /// Toggles a reaction on a message (add if absent, remove if present).
  Future<ReactionResponse?> toggleReaction(
    String messageId,
    AddReactionRequest request,
  ) async {
    final r = await _client.dio.post<Map<String, dynamic>?>(
      '$_base/reactions/messages/$messageId/toggle',
      data: request.toJson(),
    );
    if (r.data == null) return null;
    return ReactionResponse.fromJson(r.data!);
  }

  /// Gets reaction summaries for a message.
  Future<List<ReactionSummaryResponse>> getReactionsForMessage(
    String messageId,
  ) async {
    final r = await _client.dio.get<List<dynamic>>(
      '$_base/reactions/messages/$messageId',
    );
    return r.data!
        .cast<Map<String, dynamic>>()
        .map(ReactionSummaryResponse.fromJson)
        .toList();
  }

  /// Gets reaction summaries with current user flag for a message.
  Future<List<ReactionSummaryResponse>> getReactionsForMessageWithUser(
    String messageId,
  ) async {
    final r = await _client.dio.get<List<dynamic>>(
      '$_base/reactions/messages/$messageId/mine',
    );
    return r.data!
        .cast<Map<String, dynamic>>()
        .map(ReactionSummaryResponse.fromJson)
        .toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Files
  // ═══════════════════════════════════════════════════════════════════════════

  /// Uploads a file attachment to a message.
  Future<FileAttachmentResponse> uploadFile(
    String messageId,
    List<int> fileBytes,
    String fileName,
    String contentType,
  ) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        fileBytes,
        filename: fileName,
        contentType: DioMediaType.parse(contentType),
      ),
    });
    final r = await _client.dio.post<Map<String, dynamic>>(
      '$_base/files/upload',
      data: formData,
      queryParameters: {'messageId': messageId},
    );
    return FileAttachmentResponse.fromJson(r.data!);
  }

  /// Downloads a file attachment as raw bytes.
  Future<List<int>> downloadFile(String attachmentId) async {
    final r = await _client.dio.get<List<int>>(
      '$_base/files/$attachmentId/download',
      options: Options(responseType: ResponseType.bytes),
    );
    return r.data!;
  }

  /// Gets file attachments for a message.
  Future<List<FileAttachmentResponse>> getAttachmentsForMessage(
    String messageId,
  ) async {
    final r = await _client.dio.get<List<dynamic>>(
      '$_base/files/messages/$messageId',
    );
    return r.data!
        .cast<Map<String, dynamic>>()
        .map(FileAttachmentResponse.fromJson)
        .toList();
  }

  /// Deletes a file attachment.
  Future<void> deleteAttachment(String attachmentId) async {
    await _client.dio.delete<dynamic>(
      '$_base/files/$attachmentId',
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Presence
  // ═══════════════════════════════════════════════════════════════════════════

  /// Updates the current user's presence.
  Future<UserPresenceResponse> updatePresence(
    UpdatePresenceRequest request,
    String teamId,
  ) async {
    final r = await _client.dio.put<Map<String, dynamic>>(
      '$_base/presence',
      data: request.toJson(),
      queryParameters: {'teamId': teamId},
      options: _teamOpts(teamId),
    );
    return UserPresenceResponse.fromJson(r.data!);
  }

  /// Gets the current user's presence.
  Future<UserPresenceResponse> getPresence(String teamId) async {
    final r = await _client.dio.get<Map<String, dynamic>>(
      '$_base/presence',
      queryParameters: {'teamId': teamId},
      options: _teamOpts(teamId),
    );
    return UserPresenceResponse.fromJson(r.data!);
  }

  /// Gets presence for all team members.
  Future<List<UserPresenceResponse>> getTeamPresence(String teamId) async {
    final r = await _client.dio.get<List<dynamic>>(
      '$_base/presence/team',
      queryParameters: {'teamId': teamId},
      options: _teamOpts(teamId),
    );
    return r.data!
        .cast<Map<String, dynamic>>()
        .map(UserPresenceResponse.fromJson)
        .toList();
  }

  /// Gets online users for a team.
  Future<List<UserPresenceResponse>> getOnlineUsers(String teamId) async {
    final r = await _client.dio.get<List<dynamic>>(
      '$_base/presence/online',
      queryParameters: {'teamId': teamId},
      options: _teamOpts(teamId),
    );
    return r.data!
        .cast<Map<String, dynamic>>()
        .map(UserPresenceResponse.fromJson)
        .toList();
  }

  /// Sets Do Not Disturb status.
  Future<UserPresenceResponse> setDoNotDisturb(
    String teamId, {
    String? statusMessage,
  }) async {
    final r = await _client.dio.post<Map<String, dynamic>>(
      '$_base/presence/dnd',
      queryParameters: {
        'teamId': teamId,
        if (statusMessage != null) 'statusMessage': statusMessage,
      },
      options: _teamOpts(teamId),
    );
    return UserPresenceResponse.fromJson(r.data!);
  }

  /// Clears Do Not Disturb status.
  Future<UserPresenceResponse> clearDoNotDisturb(String teamId) async {
    final r = await _client.dio.delete<Map<String, dynamic>>(
      '$_base/presence/dnd',
      queryParameters: {'teamId': teamId},
      options: _teamOpts(teamId),
    );
    return UserPresenceResponse.fromJson(r.data!);
  }

  /// Sets the user offline.
  Future<void> goOffline(String teamId) async {
    await _client.dio.post<dynamic>(
      '$_base/presence/offline',
      queryParameters: {'teamId': teamId},
      options: _teamOpts(teamId),
    );
  }

  /// Gets presence counts grouped by status.
  Future<Map<String, int>> getPresenceCount(String teamId) async {
    final r = await _client.dio.get<Map<String, dynamic>>(
      '$_base/presence/count',
      queryParameters: {'teamId': teamId},
      options: _teamOpts(teamId),
    );
    return r.data!.map((k, v) => MapEntry(k, (v as num).toInt()));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Platform Events
  // ═══════════════════════════════════════════════════════════════════════════

  /// Gets paginated platform events for a team.
  Future<PageResponse<PlatformEventResponse>> getEventsForTeam(
    String teamId, {
    int page = 0,
    int size = 50,
  }) async {
    final r = await _client.dio.get<Map<String, dynamic>>(
      '$_base/events',
      queryParameters: {'teamId': teamId, 'page': page, 'size': size},
      options: _teamOpts(teamId),
    );
    return PageResponse.fromJson(
      r.data!,
      (o) => PlatformEventResponse.fromJson(o as Map<String, dynamic>),
    );
  }

  /// Gets a single platform event by ID.
  Future<PlatformEventResponse> getEvent(String eventId) async {
    final r = await _client.dio.get<Map<String, dynamic>>(
      '$_base/events/$eventId',
    );
    return PlatformEventResponse.fromJson(r.data!);
  }

  /// Gets paginated events filtered by type.
  Future<PageResponse<PlatformEventResponse>> getEventsForTeamByType(
    String teamId,
    PlatformEventType eventType, {
    int page = 0,
    int size = 50,
  }) async {
    final r = await _client.dio.get<Map<String, dynamic>>(
      '$_base/events/type/${eventType.toJson()}',
      queryParameters: {'teamId': teamId, 'page': page, 'size': size},
      options: _teamOpts(teamId),
    );
    return PageResponse.fromJson(
      r.data!,
      (o) => PlatformEventResponse.fromJson(o as Map<String, dynamic>),
    );
  }

  /// Gets events for a specific source entity.
  Future<List<PlatformEventResponse>> getEventsForEntity(
    String sourceEntityId,
  ) async {
    final r = await _client.dio.get<List<dynamic>>(
      '$_base/events/entity/$sourceEntityId',
    );
    return r.data!
        .cast<Map<String, dynamic>>()
        .map(PlatformEventResponse.fromJson)
        .toList();
  }

  /// Gets undelivered events for a team.
  Future<List<PlatformEventResponse>> getUndeliveredEvents(
    String teamId,
  ) async {
    final r = await _client.dio.get<List<dynamic>>(
      '$_base/events/undelivered',
      queryParameters: {'teamId': teamId},
      options: _teamOpts(teamId),
    );
    return r.data!
        .cast<Map<String, dynamic>>()
        .map(PlatformEventResponse.fromJson)
        .toList();
  }

  /// Retries delivery of a single event.
  Future<PlatformEventResponse> retryDelivery(String eventId) async {
    final r = await _client.dio.post<Map<String, dynamic>>(
      '$_base/events/$eventId/retry',
    );
    return PlatformEventResponse.fromJson(r.data!);
  }

  /// Retries all undelivered events for a team.
  Future<Map<String, int>> retryAllUndelivered(String teamId) async {
    final r = await _client.dio.post<Map<String, dynamic>>(
      '$_base/events/retry-all',
      queryParameters: {'teamId': teamId},
      options: _teamOpts(teamId),
    );
    return r.data!.map((k, v) => MapEntry(k, (v as num).toInt()));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Health
  // ═══════════════════════════════════════════════════════════════════════════

  /// Checks Relay module health.
  Future<Map<String, dynamic>> health() async {
    final r = await _client.dio.get<Map<String, dynamic>>(
      '$_base/health',
    );
    return r.data!;
  }
}
