/// Riverpod providers for the Relay module.
///
/// Manages state, exposes API data, handles filtering/sorting, and
/// provides the reactive layer between [RelayApiService] /
/// [RelayWebSocketService] and the UI pages.
/// Follows the same patterns as [courier_providers.dart]:
/// [Provider] for singletons, [FutureProvider] for async data,
/// [FutureProvider.family] for parameterized queries,
/// [StateProvider] for UI state.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/health_snapshot.dart';
import '../models/relay_models.dart';
import '../services/cloud/relay_api.dart';
import '../services/cloud/relay_websocket_service.dart';
import 'auth_providers.dart';
import 'team_providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Core Singleton Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Provides the [RelayApiService] singleton for all Relay API calls.
///
/// Uses [apiClientProvider] from [auth_providers.dart] since Relay
/// is a module within the consolidated CodeOps-Server.
final relayApiProvider = Provider<RelayApiService>((ref) {
  final client = ref.watch(apiClientProvider);
  return RelayApiService(client);
});

/// Provides the [RelayWebSocketService] singleton.
final relayWebSocketProvider = Provider<RelayWebSocketService>((ref) {
  final service = RelayWebSocketService();
  ref.onDispose(() => service.dispose());
  return service;
});

// ─────────────────────────────────────────────────────────────────────────────
// UI State Providers
// ─────────────────────────────────────────────────────────────────────────────

/// ID of the currently selected channel.
final selectedChannelIdProvider = StateProvider<String?>((ref) => null);

/// ID of the currently selected conversation.
final selectedConversationIdProvider = StateProvider<String?>((ref) => null);

/// ID of the currently selected message.
final selectedMessageIdProvider = StateProvider<String?>((ref) => null);

/// Search query for Relay messages.
final relaySearchQueryProvider = StateProvider<String>((ref) => '');

/// Current page index for channel messages.
final channelMessagePageProvider = StateProvider<int>((ref) => 0);

/// Current page index for DM messages.
final dmMessagePageProvider = StateProvider<int>((ref) => 0);

/// Whether the thread side panel is visible.
final showThreadPanelProvider = StateProvider<bool>((ref) => false);

/// UUID of the root message for the active thread panel.
final threadRootMessageIdProvider = StateProvider<String?>((ref) => null);

// ─────────────────────────────────────────────────────────────────────────────
// Channels — Data Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Fetches paginated channels for the selected team.
final teamChannelsProvider =
    FutureProvider.family<PageResponse<ChannelSummaryResponse>, String>(
        (ref, teamId) {
  final api = ref.watch(relayApiProvider);
  return api.getChannels(teamId);
});

/// Fetches a single channel by ID.
final channelDetailProvider = FutureProvider.family<ChannelResponse,
    ({String channelId, String teamId})>((ref, params) {
  final api = ref.watch(relayApiProvider);
  return api.getChannel(params.channelId, params.teamId);
});

/// Fetches members of a channel.
final channelMembersProvider = FutureProvider.family<
    List<ChannelMemberResponse>,
    ({String channelId, String teamId})>((ref, params) {
  final api = ref.watch(relayApiProvider);
  return api.getMembers(params.channelId, params.teamId);
});

/// Fetches pinned messages for a channel.
final channelPinsProvider = FutureProvider.family<List<PinnedMessageResponse>,
    ({String channelId, String teamId})>((ref, params) {
  final api = ref.watch(relayApiProvider);
  return api.getPinnedMessages(params.channelId, params.teamId);
});

// ─────────────────────────────────────────────────────────────────────────────
// Messages — Data Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Fetches paginated messages for a channel.
final channelMessagesProvider = FutureProvider.family<
    PageResponse<MessageResponse>,
    ({String channelId, String teamId, int page})>((ref, params) {
  final api = ref.watch(relayApiProvider);
  return api.getChannelMessages(params.channelId, params.teamId,
      page: params.page);
});

/// Fetches thread replies for a parent message.
final threadRepliesProvider = FutureProvider.family<List<MessageResponse>,
    ({String channelId, String parentId})>((ref, params) {
  final api = ref.watch(relayApiProvider);
  return api.getThreadReplies(params.channelId, params.parentId);
});

/// Fetches active threads in a channel.
final activeThreadsProvider =
    FutureProvider.family<List<MessageThreadResponse>, String>(
        (ref, channelId) {
  final api = ref.watch(relayApiProvider);
  return api.getActiveThreads(channelId);
});

/// Searches messages within a single channel.
final channelSearchProvider = FutureProvider.family<
    PageResponse<MessageResponse>,
    ({String channelId, String query, String teamId})>((ref, params) {
  final api = ref.watch(relayApiProvider);
  return api.searchMessages(params.channelId, params.query, params.teamId);
});

/// Searches messages across all channels in a team.
final globalSearchProvider = FutureProvider.family<
    PageResponse<ChannelSearchResultResponse>,
    ({String query, String teamId})>((ref, params) {
  final api = ref.watch(relayApiProvider);
  return api.searchMessagesAcrossChannels(params.query, params.teamId);
});

/// Fetches unread counts for all channels in a team.
final unreadCountsProvider =
    FutureProvider.family<List<UnreadCountResponse>, String>((ref, teamId) {
  final api = ref.watch(relayApiProvider);
  return api.getUnreadCounts(teamId);
});

// ─────────────────────────────────────────────────────────────────────────────
// Direct Messages — Data Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Fetches direct conversations for the current user.
final conversationsProvider =
    FutureProvider.family<List<DirectConversationSummaryResponse>, String>(
        (ref, teamId) {
  final api = ref.watch(relayApiProvider);
  return api.getConversations(teamId);
});

/// Fetches a single direct conversation by ID.
final conversationDetailProvider =
    FutureProvider.family<DirectConversationResponse, String>(
        (ref, conversationId) {
  final api = ref.watch(relayApiProvider);
  return api.getConversation(conversationId);
});

/// Fetches paginated messages in a direct conversation.
final dmMessagesProvider = FutureProvider.family<
    PageResponse<DirectMessageResponse>,
    ({String conversationId, int page})>((ref, params) {
  final api = ref.watch(relayApiProvider);
  return api.getDirectMessages(params.conversationId, page: params.page);
});

/// Fetches unread count for a direct conversation.
final dmUnreadCountProvider =
    FutureProvider.family<int, String>((ref, conversationId) {
  final api = ref.watch(relayApiProvider);
  return api.getDirectMessageUnreadCount(conversationId);
});

// ─────────────────────────────────────────────────────────────────────────────
// Reactions — Data Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Fetches reaction summaries for a message.
final messageReactionsProvider =
    FutureProvider.family<List<ReactionSummaryResponse>, String>(
        (ref, messageId) {
  final api = ref.watch(relayApiProvider);
  return api.getReactionsForMessageWithUser(messageId);
});

// ─────────────────────────────────────────────────────────────────────────────
// Presence — Data Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Fetches all team member presences.
final teamPresenceProvider =
    FutureProvider.family<List<UserPresenceResponse>, String>((ref, teamId) {
  final api = ref.watch(relayApiProvider);
  return api.getTeamPresence(teamId);
});

/// Fetches online users for a team.
final onlineUsersProvider =
    FutureProvider.family<List<UserPresenceResponse>, String>((ref, teamId) {
  final api = ref.watch(relayApiProvider);
  return api.getOnlineUsers(teamId);
});

/// Fetches presence counts grouped by status.
final presenceCountProvider =
    FutureProvider.family<Map<String, int>, String>((ref, teamId) {
  final api = ref.watch(relayApiProvider);
  return api.getPresenceCount(teamId);
});

// ─────────────────────────────────────────────────────────────────────────────
// Platform Events — Data Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Fetches paginated platform events for a team.
final teamEventsProvider = FutureProvider.family<
    PageResponse<PlatformEventResponse>,
    ({String teamId, int page})>((ref, params) {
  final api = ref.watch(relayApiProvider);
  return api.getEventsForTeam(params.teamId, page: params.page);
});

/// Fetches undelivered platform events for a team.
final undeliveredEventsProvider =
    FutureProvider.family<List<PlatformEventResponse>, String>((ref, teamId) {
  final api = ref.watch(relayApiProvider);
  return api.getUndeliveredEvents(teamId);
});

// ─────────────────────────────────────────────────────────────────────────────
// Files — Data Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Fetches file attachments for a message.
final messageAttachmentsProvider =
    FutureProvider.family<List<FileAttachmentResponse>, String>(
        (ref, messageId) {
  final api = ref.watch(relayApiProvider);
  return api.getAttachmentsForMessage(messageId);
});

// ─────────────────────────────────────────────────────────────────────────────
// Health — Data Provider
// ─────────────────────────────────────────────────────────────────────────────

/// Fetches Relay module health status.
final relayHealthProvider = FutureProvider<Map<String, dynamic>>((ref) {
  final api = ref.watch(relayApiProvider);
  return api.health();
});
