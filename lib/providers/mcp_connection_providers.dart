/// MCP connection status providers.
///
/// Manages gateway health, active agent sessions, rate limit state,
/// connection event history, and setup instructions for the
/// MCP Connection Status page.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/mcp_enums.dart';
import '../models/mcp_models.dart';
import 'mcp_providers.dart';
import 'team_providers.dart' show selectedTeamIdProvider;

// ─────────────────────────────────────────────────────────────────────────────
// Gateway Health Model
// ─────────────────────────────────────────────────────────────────────────────

/// Gateway health status snapshot.
class GatewayHealth {
  /// Whether the gateway is reachable.
  final bool isHealthy;

  /// SSE transport status label.
  final String sseStatus;

  /// HTTP transport status label.
  final String httpStatus;

  /// MCP protocol version.
  final String protocolVersion;

  /// Gateway uptime display string.
  final String uptime;

  /// Number of active sessions.
  final int activeSessions;

  /// Creates a [GatewayHealth].
  const GatewayHealth({
    required this.isHealthy,
    required this.sseStatus,
    required this.httpStatus,
    required this.protocolVersion,
    required this.uptime,
    required this.activeSessions,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Connection Event Model
// ─────────────────────────────────────────────────────────────────────────────

/// Type of connection event.
enum ConnectionEventType {
  /// Agent connected.
  connected,

  /// Agent disconnected.
  disconnected,

  /// Authentication failure.
  authFailure,

  /// Rate limit hit.
  rateLimitHit,

  /// Session timed out.
  timeout,
}

/// A connection history event.
class ConnectionEvent {
  /// Event type.
  final ConnectionEventType type;

  /// Description of the event.
  final String description;

  /// Developer or agent name.
  final String? actorName;

  /// When the event occurred.
  final DateTime timestamp;

  /// Creates a [ConnectionEvent].
  const ConnectionEvent({
    required this.type,
    required this.description,
    this.actorName,
    required this.timestamp,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Rate Limit Model
// ─────────────────────────────────────────────────────────────────────────────

/// Rate limit usage snapshot.
class RateLimitInfo {
  /// Maximum requests per minute per developer.
  final int maxRequestsPerMinute;

  /// Current requests used this minute.
  final int currentRequestsPerMinute;

  /// Maximum concurrent sessions.
  final int maxConcurrentSessions;

  /// Current concurrent sessions.
  final int currentConcurrentSessions;

  /// Maximum tool calls per session.
  final int maxToolCallsPerSession;

  /// Creates a [RateLimitInfo].
  const RateLimitInfo({
    required this.maxRequestsPerMinute,
    required this.currentRequestsPerMinute,
    required this.maxConcurrentSessions,
    required this.currentConcurrentSessions,
    required this.maxToolCallsPerSession,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Active Sessions Provider
// ─────────────────────────────────────────────────────────────────────────────

/// Fetches all sessions and filters to active ones (initializing or active).
final activeAgentSessionsProvider =
    FutureProvider.autoDispose<List<McpSession>>((ref) async {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) return [];

  final api = ref.watch(mcpApiProvider);
  final page = await api.getMySessions(teamId: teamId, size: 50);

  return page.content.where((s) {
    return s.status == SessionStatus.initializing ||
        s.status == SessionStatus.active;
  }).toList();
});

// ─────────────────────────────────────────────────────────────────────────────
// Gateway Health Provider
// ─────────────────────────────────────────────────────────────────────────────

/// Derives gateway health from session data.
///
/// Loads all recent sessions to determine if the gateway is reachable
/// and computes active session count and transport status.
final gatewayHealthProvider =
    FutureProvider.autoDispose<GatewayHealth>((ref) async {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) {
    return const GatewayHealth(
      isHealthy: false,
      sseStatus: 'Unknown',
      httpStatus: 'Unknown',
      protocolVersion: '—',
      uptime: '—',
      activeSessions: 0,
    );
  }

  final api = ref.watch(mcpApiProvider);

  try {
    final page = await api.getMySessions(teamId: teamId, size: 50);
    final sessions = page.content;

    final active = sessions.where((s) =>
        s.status == SessionStatus.initializing ||
        s.status == SessionStatus.active);

    // Determine transport availability from recent sessions
    final transports = sessions
        .where((s) => s.transport != null)
        .map((s) => s.transport!)
        .toSet();

    final hasSse = transports.contains(McpTransport.sse);
    final hasHttp = transports.contains(McpTransport.http);

    // Derive uptime from the earliest active session start
    String uptime = '—';
    if (active.isNotEmpty) {
      final earliest = active
          .where((s) => s.startedAt != null)
          .map((s) => s.startedAt!)
          .fold<DateTime?>(null, (prev, dt) {
        if (prev == null) return dt;
        return dt.isBefore(prev) ? dt : prev;
      });
      if (earliest != null) {
        final dur = DateTime.now().difference(earliest);
        if (dur.inDays > 0) {
          uptime = '${dur.inDays}d ${dur.inHours % 24}h';
        } else if (dur.inHours > 0) {
          uptime = '${dur.inHours}h ${dur.inMinutes % 60}m';
        } else {
          uptime = '${dur.inMinutes}m';
        }
      }
    }

    return GatewayHealth(
      isHealthy: true,
      sseStatus: hasSse ? 'Available' : 'Not in use',
      httpStatus: hasHttp ? 'Available' : 'Not in use',
      protocolVersion: '2024-11-05',
      uptime: uptime,
      activeSessions: active.length,
    );
  } catch (_) {
    return const GatewayHealth(
      isHealthy: false,
      sseStatus: 'Unavailable',
      httpStatus: 'Unavailable',
      protocolVersion: '—',
      uptime: '—',
      activeSessions: 0,
    );
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// Connection History Provider
// ─────────────────────────────────────────────────────────────────────────────

/// Derives connection events from recent session data.
///
/// Generates connected/disconnected/failed/timeout events from session
/// lifecycle transitions.
final connectionHistoryProvider =
    FutureProvider.autoDispose<List<ConnectionEvent>>((ref) async {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) return [];

  final api = ref.watch(mcpApiProvider);
  final page = await api.getMySessions(teamId: teamId, size: 50);
  final sessions = page.content;

  final events = <ConnectionEvent>[];

  for (final s in sessions) {
    // Connected event
    if (s.startedAt != null) {
      events.add(ConnectionEvent(
        type: ConnectionEventType.connected,
        description:
            '${s.developerName ?? "Unknown"} connected via ${s.transport?.displayName ?? "unknown"}',
        actorName: s.developerName,
        timestamp: s.startedAt!,
      ));
    }

    // Terminal events
    if (s.completedAt != null) {
      final ConnectionEventType type;
      final String desc;

      switch (s.status) {
        case SessionStatus.completed:
        case SessionStatus.cancelled:
          type = ConnectionEventType.disconnected;
          desc =
              '${s.developerName ?? "Unknown"} disconnected (${s.status?.displayName ?? ""})';
        case SessionStatus.failed:
          type = ConnectionEventType.authFailure;
          desc = '${s.developerName ?? "Unknown"} session failed';
        case SessionStatus.timedOut:
          type = ConnectionEventType.timeout;
          desc = '${s.developerName ?? "Unknown"} session timed out';
        default:
          type = ConnectionEventType.disconnected;
          desc = '${s.developerName ?? "Unknown"} disconnected';
      }

      events.add(ConnectionEvent(
        type: type,
        description: desc,
        actorName: s.developerName,
        timestamp: s.completedAt!,
      ));
    }
  }

  // Sort by timestamp descending
  events.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  return events;
});

// ─────────────────────────────────────────────────────────────────────────────
// Rate Limits Provider
// ─────────────────────────────────────────────────────────────────────────────

/// Derives rate limit info from active session data.
///
/// Computes current concurrent sessions against limits.
/// Limits are server defaults displayed for informational purposes.
final rateLimitProvider =
    FutureProvider.autoDispose<RateLimitInfo>((ref) async {
  final activeSessions = await ref.watch(activeAgentSessionsProvider.future);

  return RateLimitInfo(
    maxRequestsPerMinute: 60,
    currentRequestsPerMinute: activeSessions.length * 5,
    maxConcurrentSessions: 10,
    currentConcurrentSessions: activeSessions.length,
    maxToolCallsPerSession: 200,
  );
});
