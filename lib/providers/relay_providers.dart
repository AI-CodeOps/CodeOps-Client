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

import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/health_snapshot.dart';
import '../models/relay_enums.dart';
import '../models/relay_models.dart';
import '../services/cloud/relay_api.dart';
import '../services/cloud/relay_websocket_service.dart';
import 'auth_providers.dart';

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

/// Editing state — when non-null, the composer is in edit mode.
///
/// Set to a [MessageResponse] when the user chooses "Edit" from the
/// message context menu. The composer pre-populates its text field
/// with the message content and switches to edit mode.
final editingMessageProvider = StateProvider<MessageResponse?>((ref) => null);

/// Local typing indicator state.
///
/// Set to `true` while the user is actively typing in the composer.
/// Sending typing events to the server is future work.
final isTypingProvider = StateProvider.autoDispose<bool>((ref) => false);

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

/// Fetches a single message by channel ID and message ID.
///
/// Used by [RelayThreadPanel] to load the root message of a thread.
final messageByIdProvider = FutureProvider.family<MessageResponse,
    ({String channelId, String messageId})>((ref, params) {
  final api = ref.watch(relayApiProvider);
  return api.getMessage(params.channelId, params.messageId);
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

/// Optimistic reaction overrides, keyed by message ID.
///
/// When non-null for a message, the bubble renders these reactions
/// instead of the ones from [MessageResponse.reactions]. Cleared
/// after the API call completes (success or failure).
final optimisticReactionsProvider =
    StateProvider.family<List<ReactionSummaryResponse>?, String>(
        (ref, messageId) => null);

/// Manages the list of recently used emojis (most-recent first).
///
/// Capped at [maxRecent] entries. Stored in memory only — resets
/// on app restart.
class RecentEmojisNotifier extends StateNotifier<List<String>> {
  /// Maximum number of recent emojis to retain.
  static const maxRecent = 8;

  /// Creates a [RecentEmojisNotifier] with an empty list.
  RecentEmojisNotifier() : super([]);

  /// Records [emoji] as the most recently used.
  ///
  /// Moves it to the front if already present, otherwise inserts
  /// at position 0 and trims the list to [maxRecent].
  void add(String emoji) {
    final updated = [emoji, ...state.where((e) => e != emoji)];
    state = updated.length > maxRecent
        ? updated.sublist(0, maxRecent)
        : updated;
  }
}

/// Provides the list of recently used emojis.
final recentEmojisProvider =
    StateNotifierProvider<RecentEmojisNotifier, List<String>>(
        (ref) => RecentEmojisNotifier());

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

/// Fetches the current user's own presence for a team.
final myPresenceProvider =
    FutureProvider.family<UserPresenceResponse, String>((ref, teamId) {
  final api = ref.watch(relayApiProvider);
  return api.getPresence(teamId);
});

/// Resolves the [PresenceStatus] for a specific user from cached team
/// presence data.
///
/// Returns `null` if team presence has not loaded or the user is not
/// found. Keyed by `(teamId, userId)`.
final userPresenceProvider = Provider.family<PresenceStatus?,
    ({String teamId, String userId})>((ref, params) {
  final presenceAsync = ref.watch(teamPresenceProvider(params.teamId));
  final presences = presenceAsync.valueOrNull;
  if (presences == null) return null;
  final match = presences.where((p) => p.userId == params.userId);
  if (match.isEmpty) return null;
  return match.first.status;
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

/// Fetches a single platform event by ID.
final platformEventDetailProvider =
    FutureProvider.family<PlatformEventResponse, String>((ref, eventId) {
  final api = ref.watch(relayApiProvider);
  return api.getEvent(eventId);
});

/// Fetches paginated platform events with optional type filter.
///
/// When [eventType] is non-null, only events of that type are returned.
/// Otherwise returns all events for the team.
final platformEventsFilteredProvider = FutureProvider.autoDispose.family<
    PageResponse<PlatformEventResponse>,
    ({String teamId, int page, PlatformEventType? eventType})>((ref, params) {
  final api = ref.watch(relayApiProvider);
  if (params.eventType != null) {
    return api.getEventsForTeamByType(
      params.teamId,
      params.eventType!,
      page: params.page,
    );
  }
  return api.getEventsForTeam(params.teamId, page: params.page);
});

/// Count of undelivered platform events for badge display.
///
/// Derived from [undeliveredEventsProvider] by counting the list length.
final undeliveredEventCountProvider =
    Provider.family<int, String>((ref, teamId) {
  final async = ref.watch(undeliveredEventsProvider(teamId));
  return async.valueOrNull?.length ?? 0;
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

/// A file selected by the user but not yet uploaded.
///
/// Held in [pendingAttachmentsProvider] until the message is sent and
/// the upload flow triggers.
class PendingFile {
  /// Original file name.
  final String name;

  /// Raw file bytes.
  final Uint8List bytes;

  /// MIME content type (e.g. `image/png`).
  final String contentType;

  /// File size in bytes.
  int get size => bytes.length;

  /// Creates a [PendingFile].
  const PendingFile({
    required this.name,
    required this.bytes,
    required this.contentType,
  });
}

/// List of files the user has selected in the composer but not yet sent.
///
/// Cleared after upload completes or the user removes all files.
final pendingAttachmentsProvider =
    StateProvider<List<PendingFile>>((ref) => []);

/// Per-file upload progress, keyed by file name.
///
/// Each value is a [FileUploadProgress] tracking bytes sent, total,
/// and completion/failure state. Cleared after all uploads finish.
class FileUploadProgress {
  /// Original file name.
  final String fileName;

  /// Bytes uploaded so far.
  final int bytesSent;

  /// Total bytes to upload.
  final int totalBytes;

  /// Whether the upload completed successfully.
  final bool isComplete;

  /// Whether the upload failed.
  final bool isFailed;

  /// Fractional progress (0.0 – 1.0).
  double get progress =>
      totalBytes > 0 ? (bytesSent / totalBytes).clamp(0.0, 1.0) : 0.0;

  /// Creates a [FileUploadProgress].
  const FileUploadProgress({
    required this.fileName,
    this.bytesSent = 0,
    this.totalBytes = 0,
    this.isComplete = false,
    this.isFailed = false,
  });

  /// Returns a copy with updated fields.
  FileUploadProgress copyWith({
    int? bytesSent,
    int? totalBytes,
    bool? isComplete,
    bool? isFailed,
  }) =>
      FileUploadProgress(
        fileName: fileName,
        bytesSent: bytesSent ?? this.bytesSent,
        totalBytes: totalBytes ?? this.totalBytes,
        isComplete: isComplete ?? this.isComplete,
        isFailed: isFailed ?? this.isFailed,
      );
}

/// Active upload progress for all files being uploaded.
///
/// Keyed by file name. Entries are added at upload start, updated
/// with progress callbacks, and removed when all uploads complete.
final uploadProgressProvider =
    StateProvider<Map<String, FileUploadProgress>>((ref) => {});

// ─────────────────────────────────────────────────────────────────────────────
// Channel Role — Derived Provider
// ─────────────────────────────────────────────────────────────────────────────

/// Resolves the current user's [MemberRole] for a specific channel.
///
/// Fetches the channel member list and matches the authenticated user's
/// ID to determine their role. Returns null if the user is not a member.
final currentUserChannelRoleProvider = FutureProvider.family<MemberRole?,
    ({String channelId, String teamId})>((ref, params) async {
  final members = await ref.watch(channelMembersProvider(params).future);
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) return null;
  final match = members.where((m) => m.userId == currentUser.id);
  if (match.isEmpty) return null;
  return match.first.role;
});

// ─────────────────────────────────────────────────────────────────────────────
// Health — Data Provider
// ─────────────────────────────────────────────────────────────────────────────

/// Fetches Relay module health status.
final relayHealthProvider = FutureProvider<Map<String, dynamic>>((ref) {
  final api = ref.watch(relayApiProvider);
  return api.health();
});

// ─────────────────────────────────────────────────────────────────────────────
// Accumulated Messages — StateNotifier for Infinite Scroll
// ─────────────────────────────────────────────────────────────────────────────

/// Manages an accumulated list of [MessageResponse] items for a channel,
/// supporting paginated loading (infinite scroll) and refresh.
///
/// The API returns newest-first pages (page 0 = newest messages). This
/// notifier reverses each page so the list is ordered oldest-first for
/// bottom-anchored display. Older pages are prepended to the front.
class AccumulatedMessagesNotifier
    extends StateNotifier<AsyncValue<List<MessageResponse>>> {
  final RelayApiService _api;
  final String _channelId;
  final String _teamId;
  int _currentPage = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  /// Whether there are more pages to load.
  bool get hasMore => _hasMore;

  /// Whether a page load is currently in progress.
  bool get isLoadingMore => _isLoadingMore;

  /// Creates an [AccumulatedMessagesNotifier] and loads the initial page.
  AccumulatedMessagesNotifier(this._api, this._channelId, this._teamId)
      : super(const AsyncValue.loading()) {
    _loadInitial();
  }

  /// Fetches page 0 (newest messages), reverses for oldest-first order.
  Future<void> _loadInitial() async {
    state = const AsyncValue.loading();
    try {
      final page = await _api.getChannelMessages(_channelId, _teamId);
      _currentPage = 0;
      _hasMore = !page.isLast;
      state = AsyncValue.data(page.content.reversed.toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Loads the next older page and prepends it to the accumulated list.
  ///
  /// No-op if already loading or no more pages remain.
  Future<void> loadNextPage() async {
    if (_isLoadingMore || !_hasMore) return;
    final current = state.valueOrNull;
    if (current == null) return;

    _isLoadingMore = true;
    try {
      final page = await _api.getChannelMessages(
        _channelId,
        _teamId,
        page: _currentPage + 1,
      );
      _currentPage++;
      _hasMore = !page.isLast;
      state = AsyncValue.data([
        ...page.content.reversed,
        ...current,
      ]);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    } finally {
      _isLoadingMore = false;
    }
  }

  /// Resets state and reloads from page 0.
  Future<void> refresh() async {
    _currentPage = 0;
    _hasMore = true;
    _isLoadingMore = false;
    await _loadInitial();
  }
}

/// Provides an [AccumulatedMessagesNotifier] for a channel, keyed by
/// channel ID and team ID.
///
/// Automatically loads the first page on creation. Use [loadNextPage]
/// for infinite scroll and [refresh] after sending messages.
final accumulatedMessagesProvider = StateNotifierProvider.family<
    AccumulatedMessagesNotifier,
    AsyncValue<List<MessageResponse>>,
    ({String channelId, String teamId})>((ref, params) {
  final api = ref.watch(relayApiProvider);
  return AccumulatedMessagesNotifier(api, params.channelId, params.teamId);
});

// ─────────────────────────────────────────────────────────────────────────────
// Accumulated DM Messages — StateNotifier for Infinite Scroll
// ─────────────────────────────────────────────────────────────────────────────

/// Manages an accumulated list of [DirectMessageResponse] items for a
/// direct conversation, supporting paginated loading (infinite scroll)
/// and refresh.
///
/// Mirrors [AccumulatedMessagesNotifier] but operates on
/// [DirectMessageResponse] via [RelayApiService.getDirectMessages].
/// Pages are reversed from newest-first to oldest-first for
/// bottom-anchored display.
class AccumulatedDmMessagesNotifier
    extends StateNotifier<AsyncValue<List<DirectMessageResponse>>> {
  final RelayApiService _api;
  final String _conversationId;
  int _currentPage = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  /// Whether there are more pages to load.
  bool get hasMore => _hasMore;

  /// Whether a page load is currently in progress.
  bool get isLoadingMore => _isLoadingMore;

  /// Creates an [AccumulatedDmMessagesNotifier] and loads the initial page.
  AccumulatedDmMessagesNotifier(this._api, this._conversationId)
      : super(const AsyncValue.loading()) {
    _loadInitial();
  }

  /// Fetches page 0 (newest messages), reverses for oldest-first order.
  Future<void> _loadInitial() async {
    state = const AsyncValue.loading();
    try {
      final page = await _api.getDirectMessages(_conversationId);
      _currentPage = 0;
      _hasMore = !page.isLast;
      state = AsyncValue.data(page.content.reversed.toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Loads the next older page and prepends it to the accumulated list.
  ///
  /// No-op if already loading or no more pages remain.
  Future<void> loadNextPage() async {
    if (_isLoadingMore || !_hasMore) return;
    final current = state.valueOrNull;
    if (current == null) return;

    _isLoadingMore = true;
    try {
      final page = await _api.getDirectMessages(
        _conversationId,
        page: _currentPage + 1,
      );
      _currentPage++;
      _hasMore = !page.isLast;
      state = AsyncValue.data([
        ...page.content.reversed,
        ...current,
      ]);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    } finally {
      _isLoadingMore = false;
    }
  }

  /// Resets state and reloads from page 0.
  Future<void> refresh() async {
    _currentPage = 0;
    _hasMore = true;
    _isLoadingMore = false;
    await _loadInitial();
  }
}

/// Provides an [AccumulatedDmMessagesNotifier] for a direct conversation,
/// keyed by conversation ID.
///
/// Automatically loads the first page on creation. Use [loadNextPage]
/// for infinite scroll and [refresh] after sending messages.
final accumulatedDmMessagesProvider = StateNotifierProvider.family<
    AccumulatedDmMessagesNotifier,
    AsyncValue<List<DirectMessageResponse>>,
    String>((ref, conversationId) {
  final api = ref.watch(relayApiProvider);
  return AccumulatedDmMessagesNotifier(api, conversationId);
});
