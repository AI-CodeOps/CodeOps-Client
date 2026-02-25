/// WebSocket service for real-time Relay updates.
///
/// Manages WebSocket connection to CodeOps-Server for channel messages,
/// DMs, presence updates, platform events, and typing indicators.
/// Auto-reconnects on disconnect with exponential backoff.
library;

import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../../models/relay_models.dart';
import '../../utils/constants.dart';

/// WebSocket service for real-time Relay updates.
///
/// Manages WebSocket connection to CodeOps-Server.
/// Handles subscriptions to channels, DMs, presence, and events.
/// Auto-reconnects on disconnect with exponential backoff.
class RelayWebSocketService {
  WebSocketChannel? _channel;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  bool _intentionalDisconnect = false;
  String? _accessToken;

  final _connectionStateController =
      StreamController<RelayWebSocketState>.broadcast();
  final _channelMessageControllers =
      <String, StreamController<MessageResponse>>{};
  final _channelTypingControllers =
      <String, StreamController<TypingIndicator>>{};
  final _dmMessageControllers =
      <String, StreamController<DirectMessageResponse>>{};
  final _dmTypingControllers =
      <String, StreamController<TypingIndicator>>{};
  final _presenceControllers =
      <String, StreamController<UserPresenceResponse>>{};
  final _eventControllers =
      <String, StreamController<PlatformEventResponse>>{};
  final _notificationController =
      StreamController<Map<String, dynamic>>.broadcast();

  RelayWebSocketState _state = RelayWebSocketState.disconnected;

  /// Whether the WebSocket is currently connected.
  bool get isConnected => _state == RelayWebSocketState.connected;

  /// Stream of connection state changes.
  Stream<RelayWebSocketState> get connectionState =>
      _connectionStateController.stream;

  /// Connects to the Relay WebSocket endpoint.
  Future<void> connect(String accessToken) async {
    _accessToken = accessToken;
    _intentionalDisconnect = false;
    _setState(RelayWebSocketState.connecting);

    try {
      final uri = Uri.parse(
        '${AppConstants.relayWebSocketUrl}?token=$accessToken',
      );
      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready;

      _setState(RelayWebSocketState.connected);
      _reconnectAttempts = 0;
      _startHeartbeat();

      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
      );
    } catch (e) {
      _setState(RelayWebSocketState.disconnected);
      _scheduleReconnect();
    }
  }

  /// Disconnects from the WebSocket.
  Future<void> disconnect() async {
    _intentionalDisconnect = true;
    _stopHeartbeat();
    _reconnectTimer?.cancel();
    await _channel?.sink.close();
    _channel = null;
    _setState(RelayWebSocketState.disconnected);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Channel Subscriptions
  // ─────────────────────────────────────────────────────────────────────────

  /// Subscribes to messages in a channel.
  Stream<MessageResponse> subscribeToChannel(
    String teamId,
    String channelId,
  ) {
    final key = 'team.$teamId.channel.$channelId.messages';
    _channelMessageControllers[key] ??=
        StreamController<MessageResponse>.broadcast();
    _sendSubscribe('/topic/$key');
    return _channelMessageControllers[key]!.stream;
  }

  /// Subscribes to typing indicators in a channel.
  Stream<TypingIndicator> subscribeToChannelTyping(
    String teamId,
    String channelId,
  ) {
    final key = 'team.$teamId.channel.$channelId.typing';
    _channelTypingControllers[key] ??=
        StreamController<TypingIndicator>.broadcast();
    _sendSubscribe('/topic/$key');
    return _channelTypingControllers[key]!.stream;
  }

  /// Unsubscribes from a channel's messages and typing.
  void unsubscribeFromChannel(String teamId, String channelId) {
    final msgKey = 'team.$teamId.channel.$channelId.messages';
    final typKey = 'team.$teamId.channel.$channelId.typing';
    _channelMessageControllers.remove(msgKey)?.close();
    _channelTypingControllers.remove(typKey)?.close();
    _sendUnsubscribe('/topic/$msgKey');
    _sendUnsubscribe('/topic/$typKey');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DM Subscriptions
  // ─────────────────────────────────────────────────────────────────────────

  /// Subscribes to messages in a direct conversation.
  Stream<DirectMessageResponse> subscribeToDm(String conversationId) {
    final key = 'dm.$conversationId';
    _dmMessageControllers[key] ??=
        StreamController<DirectMessageResponse>.broadcast();
    _sendSubscribe('/user/queue/$key');
    return _dmMessageControllers[key]!.stream;
  }

  /// Subscribes to typing indicators in a direct conversation.
  Stream<TypingIndicator> subscribeToDmTyping(String conversationId) {
    final key = 'dm.$conversationId.typing';
    _dmTypingControllers[key] ??=
        StreamController<TypingIndicator>.broadcast();
    _sendSubscribe('/user/queue/$key');
    return _dmTypingControllers[key]!.stream;
  }

  /// Unsubscribes from a direct conversation.
  void unsubscribeFromDm(String conversationId) {
    final msgKey = 'dm.$conversationId';
    final typKey = 'dm.$conversationId.typing';
    _dmMessageControllers.remove(msgKey)?.close();
    _dmTypingControllers.remove(typKey)?.close();
    _sendUnsubscribe('/user/queue/$msgKey');
    _sendUnsubscribe('/user/queue/$typKey');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Presence & Events
  // ─────────────────────────────────────────────────────────────────────────

  /// Subscribes to presence updates for a team.
  Stream<UserPresenceResponse> subscribeToPresence(String teamId) {
    final key = 'team.$teamId.presence';
    _presenceControllers[key] ??=
        StreamController<UserPresenceResponse>.broadcast();
    _sendSubscribe('/topic/$key');
    return _presenceControllers[key]!.stream;
  }

  /// Subscribes to platform events for a team.
  Stream<PlatformEventResponse> subscribeToEvents(String teamId) {
    final key = 'team.$teamId.events';
    _eventControllers[key] ??=
        StreamController<PlatformEventResponse>.broadcast();
    _sendSubscribe('/topic/$key');
    return _eventControllers[key]!.stream;
  }

  /// Subscribes to notifications for the current user.
  Stream<Map<String, dynamic>> subscribeToNotifications() {
    _sendSubscribe('/user/queue/notifications');
    return _notificationController.stream;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Outbound Messages
  // ─────────────────────────────────────────────────────────────────────────

  /// Sends a typing indicator for a channel.
  void sendTypingIndicator(
    String teamId,
    String channelId,
    String displayName,
  ) {
    _send(jsonEncode({
      'type': 'TYPING',
      'destination': '/app/relay/channel/$channelId/typing',
      'body': jsonEncode({
        'channelId': channelId,
        'displayName': displayName,
      }),
    }));
  }

  /// Sends a typing indicator for a DM conversation.
  void sendDmTypingIndicator(
    String conversationId,
    String recipientId,
    String displayName,
  ) {
    _send(jsonEncode({
      'type': 'TYPING',
      'destination': '/app/relay/dm/$conversationId/typing',
      'body': jsonEncode({
        'conversationId': conversationId,
        'displayName': displayName,
      }),
    }));
  }

  /// Sends a heartbeat to keep the connection alive.
  void sendHeartbeat(String teamId) {
    _send(jsonEncode({
      'type': 'HEARTBEAT',
      'destination': '/app/relay/heartbeat',
      'body': jsonEncode({'teamId': teamId}),
    }));
  }

  /// Releases all resources.
  void dispose() {
    _intentionalDisconnect = true;
    _stopHeartbeat();
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _connectionStateController.close();
    for (final c in _channelMessageControllers.values) {
      c.close();
    }
    for (final c in _channelTypingControllers.values) {
      c.close();
    }
    for (final c in _dmMessageControllers.values) {
      c.close();
    }
    for (final c in _dmTypingControllers.values) {
      c.close();
    }
    for (final c in _presenceControllers.values) {
      c.close();
    }
    for (final c in _eventControllers.values) {
      c.close();
    }
    _notificationController.close();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Private Helpers
  // ─────────────────────────────────────────────────────────────────────────

  void _setState(RelayWebSocketState state) {
    _state = state;
    if (!_connectionStateController.isClosed) {
      _connectionStateController.add(state);
    }
  }

  void _send(String message) {
    if (_channel != null && isConnected) {
      _channel!.sink.add(message);
    }
  }

  void _sendSubscribe(String destination) {
    _send(jsonEncode({'type': 'SUBSCRIBE', 'destination': destination}));
  }

  void _sendUnsubscribe(String destination) {
    _send(jsonEncode({'type': 'UNSUBSCRIBE', 'destination': destination}));
  }

  void _onMessage(dynamic data) {
    try {
      final json = jsonDecode(data as String) as Map<String, dynamic>;
      final destination = json['destination'] as String? ?? '';
      final body = json['body'];
      final parsed = body is String
          ? jsonDecode(body) as Map<String, dynamic>
          : body as Map<String, dynamic>?;

      if (parsed == null) return;

      // Route to correct controller based on destination
      for (final entry in _channelMessageControllers.entries) {
        if (destination.contains(entry.key)) {
          entry.value.add(MessageResponse.fromJson(parsed));
          return;
        }
      }
      for (final entry in _channelTypingControllers.entries) {
        if (destination.contains(entry.key)) {
          entry.value.add(TypingIndicator.fromJson(parsed));
          return;
        }
      }
      for (final entry in _dmMessageControllers.entries) {
        if (destination.contains(entry.key)) {
          entry.value.add(DirectMessageResponse.fromJson(parsed));
          return;
        }
      }
      for (final entry in _dmTypingControllers.entries) {
        if (destination.contains(entry.key)) {
          entry.value.add(TypingIndicator.fromJson(parsed));
          return;
        }
      }
      for (final entry in _presenceControllers.entries) {
        if (destination.contains(entry.key)) {
          entry.value.add(UserPresenceResponse.fromJson(parsed));
          return;
        }
      }
      for (final entry in _eventControllers.entries) {
        if (destination.contains(entry.key)) {
          entry.value.add(PlatformEventResponse.fromJson(parsed));
          return;
        }
      }
      if (destination.contains('notifications')) {
        _notificationController.add(parsed);
      }
    } catch (_) {
      // Silently ignore malformed messages
    }
  }

  void _onError(Object error) {
    _setState(RelayWebSocketState.disconnected);
    if (!_intentionalDisconnect) {
      _scheduleReconnect();
    }
  }

  void _onDone() {
    _stopHeartbeat();
    _setState(RelayWebSocketState.disconnected);
    if (!_intentionalDisconnect) {
      _scheduleReconnect();
    }
  }

  void _startHeartbeat() {
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: AppConstants.relayHeartbeatIntervalSeconds),
      (_) {
        _send(jsonEncode({
          'type': 'HEARTBEAT',
          'destination': '/app/relay/heartbeat',
        }));
      },
    );
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _scheduleReconnect() {
    if (_intentionalDisconnect || _accessToken == null) return;
    _setState(RelayWebSocketState.reconnecting);

    final delay = _calculateBackoff();
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: delay), () {
      _reconnectAttempts++;
      if (_accessToken != null) {
        connect(_accessToken!);
      }
    });
  }

  int _calculateBackoff() {
    // Exponential backoff: 1, 2, 4, 8, 16, 30 max
    final base = 1 << _reconnectAttempts;
    return base.clamp(1, AppConstants.relayReconnectMaxDelaySeconds);
  }
}
