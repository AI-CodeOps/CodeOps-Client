/// MCP connection status page.
///
/// Displays at `/mcp/status` with gateway health, connected agents,
/// rate limits, setup instructions, and connection history panels.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/mcp_enums.dart';
import '../../models/mcp_models.dart';
import '../../providers/mcp_connection_providers.dart';
import '../../providers/mcp_providers.dart';
import '../../providers/team_providers.dart' show selectedTeamIdProvider;
import '../../theme/colors.dart';
import '../../widgets/shared/empty_state.dart';

/// The MCP connection status page.
class McpConnectionStatusPage extends ConsumerWidget {
  /// Creates a [McpConnectionStatusPage].
  const McpConnectionStatusPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamId = ref.watch(selectedTeamIdProvider);

    if (teamId == null) {
      return const EmptyState(
        icon: Icons.group_outlined,
        title: 'No team selected',
        subtitle: 'Select a team to view connection status.',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Header(),
          const SizedBox(height: 16),
          const _GatewayHealthPanel(),
          const SizedBox(height: 16),
          const _ConnectedAgentsPanel(),
          const SizedBox(height: 16),
          const _RateLimitsPanel(),
          const SizedBox(height: 16),
          const _SetupInstructionsPanel(),
          const SizedBox(height: 16),
          const _ConnectionHistoryPanel(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

class _Header extends ConsumerWidget {
  const _Header();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => context.go('/mcp'),
                child: const Text(
                  'Dashboard',
                  style: TextStyle(
                    fontSize: 12,
                    color: CodeOpsColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'MCP Connection Status',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: CodeOpsColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {
            ref.invalidate(gatewayHealthProvider);
            ref.invalidate(activeAgentSessionsProvider);
            ref.invalidate(connectionHistoryProvider);
            ref.invalidate(rateLimitProvider);
          },
          icon: const Icon(Icons.refresh, color: CodeOpsColors.textSecondary),
          tooltip: 'Refresh',
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Gateway Health Panel
// ─────────────────────────────────────────────────────────────────────────────

class _GatewayHealthPanel extends ConsumerWidget {
  const _GatewayHealthPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthAsync = ref.watch(gatewayHealthProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CodeOpsColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CodeOpsColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gateway Health',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: CodeOpsColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          healthAsync.when(
            loading: () => const SizedBox(
              height: 60,
              child: Center(
                child:
                    CircularProgressIndicator(color: CodeOpsColors.primary),
              ),
            ),
            error: (_, __) => const Text(
              'Failed to load gateway health',
              style: TextStyle(color: CodeOpsColors.error, fontSize: 12),
            ),
            data: (health) => Wrap(
              spacing: 24,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Health indicator
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: health.isHealthy
                            ? CodeOpsColors.success
                            : CodeOpsColors.error,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      health.isHealthy ? 'Healthy' : 'Unreachable',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: health.isHealthy
                            ? CodeOpsColors.success
                            : CodeOpsColors.error,
                      ),
                    ),
                  ],
                ),
                _HealthMetric(label: 'SSE', value: health.sseStatus),
                _HealthMetric(label: 'HTTP', value: health.httpStatus),
                _HealthMetric(
                    label: 'Protocol', value: health.protocolVersion),
                _HealthMetric(label: 'Uptime', value: health.uptime),
                _HealthMetric(
                  label: 'Active Sessions',
                  value: '${health.activeSessions}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthMetric extends StatelessWidget {
  final String label;
  final String value;

  const _HealthMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: CodeOpsColors.textTertiary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: CodeOpsColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Connected Agents Panel
// ─────────────────────────────────────────────────────────────────────────────

class _ConnectedAgentsPanel extends ConsumerWidget {
  const _ConnectedAgentsPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(activeAgentSessionsProvider);

    return Container(
      decoration: BoxDecoration(
        color: CodeOpsColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CodeOpsColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  'Connected Agents',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: CodeOpsColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                sessionsAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (sessions) => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: CodeOpsColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${sessions.length}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: CodeOpsColors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: CodeOpsColors.border),
          sessionsAsync.when(
            loading: () => const SizedBox(
              height: 100,
              child: Center(
                child:
                    CircularProgressIndicator(color: CodeOpsColors.primary),
              ),
            ),
            error: (_, __) => const SizedBox(
              height: 100,
              child: Center(
                child: Text(
                  'Failed to load agents',
                  style: TextStyle(color: CodeOpsColors.error, fontSize: 12),
                ),
              ),
            ),
            data: (sessions) {
              if (sessions.isEmpty) {
                return const SizedBox(
                  height: 100,
                  child: Center(
                    child: Text(
                      'No active agents',
                      style: TextStyle(
                        color: CodeOpsColors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              }

              return Column(
                children: [
                  // Column headers
                  const Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                            flex: 2,
                            child:
                                Text('Developer', style: _columnHeaderStyle)),
                        Expanded(
                            flex: 1,
                            child:
                                Text('Transport', style: _columnHeaderStyle)),
                        Expanded(
                            flex: 1,
                            child: Text('Status', style: _columnHeaderStyle)),
                        Expanded(
                            flex: 2,
                            child: Text('Connected Since',
                                style: _columnHeaderStyle)),
                        Expanded(
                            flex: 1,
                            child: Text('Tool Calls',
                                style: _columnHeaderStyle)),
                        Expanded(
                            flex: 2,
                            child:
                                Text('Project', style: _columnHeaderStyle)),
                        SizedBox(width: 80),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: CodeOpsColors.border),
                  for (final session in sessions)
                    _AgentRow(session: session),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

const _columnHeaderStyle = TextStyle(
  fontSize: 11,
  fontWeight: FontWeight.w600,
  color: CodeOpsColors.textSecondary,
);

class _AgentRow extends ConsumerWidget {
  final McpSession session;

  const _AgentRow({required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Developer name
          Expanded(
            flex: 2,
            child: Text(
              session.developerName ?? '—',
              style: const TextStyle(
                  fontSize: 11, color: CodeOpsColors.textPrimary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Transport badge
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _TransportBadge(transport: session.transport),
            ),
          ),
          // Status
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _SessionStatusBadge(status: session.status),
            ),
          ),
          // Connected since
          Expanded(
            flex: 2,
            child: Text(
              session.startedAt != null
                  ? DateFormat('MMM d HH:mm').format(session.startedAt!)
                  : '—',
              style: const TextStyle(
                  fontSize: 11, color: CodeOpsColors.textPrimary),
            ),
          ),
          // Tool calls
          Expanded(
            flex: 1,
            child: Text(
              '${session.totalToolCalls ?? 0}',
              style: const TextStyle(
                fontSize: 11,
                color: CodeOpsColors.textPrimary,
                fontFamily: 'monospace',
              ),
            ),
          ),
          // Project
          Expanded(
            flex: 2,
            child: Text(
              session.projectName ?? '—',
              style: const TextStyle(
                  fontSize: 11, color: CodeOpsColors.textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Disconnect button
          SizedBox(
            width: 80,
            child: TextButton(
              onPressed: () => _confirmDisconnect(context, ref, session),
              style: TextButton.styleFrom(
                foregroundColor: CodeOpsColors.error,
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                visualDensity: VisualDensity.compact,
              ),
              child: const Text('Disconnect', style: TextStyle(fontSize: 10)),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDisconnect(
      BuildContext context, WidgetRef ref, McpSession session) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CodeOpsColors.surface,
        title: const Text('Disconnect Agent',
            style: TextStyle(color: CodeOpsColors.textPrimary)),
        content: Text(
          'Cancel session for ${session.developerName ?? "this agent"}?',
          style: const TextStyle(color: CodeOpsColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              if (session.id != null) {
                final api = ref.read(mcpApiProvider);
                await api.cancelSession(session.id!);
                ref.invalidate(activeAgentSessionsProvider);
                ref.invalidate(gatewayHealthProvider);
              }
            },
            style: TextButton.styleFrom(
                foregroundColor: CodeOpsColors.error),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
  }
}

class _TransportBadge extends StatelessWidget {
  final McpTransport? transport;

  const _TransportBadge({this.transport});

  @override
  Widget build(BuildContext context) {
    final color = switch (transport) {
      McpTransport.sse => CodeOpsColors.success,
      McpTransport.http => CodeOpsColors.primary,
      McpTransport.stdio => CodeOpsColors.warning,
      null => CodeOpsColors.textTertiary,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        transport?.displayName ?? '—',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _SessionStatusBadge extends StatelessWidget {
  final SessionStatus? status;

  const _SessionStatusBadge({this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      SessionStatus.active => CodeOpsColors.success,
      SessionStatus.initializing => CodeOpsColors.warning,
      SessionStatus.completing => CodeOpsColors.primary,
      SessionStatus.completed => CodeOpsColors.textTertiary,
      SessionStatus.failed => CodeOpsColors.error,
      SessionStatus.timedOut => CodeOpsColors.warning,
      SessionStatus.cancelled => CodeOpsColors.textTertiary,
      null => CodeOpsColors.textTertiary,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status?.displayName ?? '—',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Rate Limits Panel
// ─────────────────────────────────────────────────────────────────────────────

class _RateLimitsPanel extends ConsumerWidget {
  const _RateLimitsPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final limitsAsync = ref.watch(rateLimitProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CodeOpsColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CodeOpsColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rate Limits',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: CodeOpsColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          limitsAsync.when(
            loading: () => const SizedBox(
              height: 60,
              child: Center(
                child:
                    CircularProgressIndicator(color: CodeOpsColors.primary),
              ),
            ),
            error: (_, __) => const Text(
              'Failed to load rate limits',
              style: TextStyle(color: CodeOpsColors.error, fontSize: 12),
            ),
            data: (limits) => Column(
              children: [
                _RateLimitBar(
                  label: 'Requests / min',
                  current: limits.currentRequestsPerMinute,
                  max: limits.maxRequestsPerMinute,
                ),
                const SizedBox(height: 10),
                _RateLimitBar(
                  label: 'Concurrent Sessions',
                  current: limits.currentConcurrentSessions,
                  max: limits.maxConcurrentSessions,
                ),
                const SizedBox(height: 10),
                _RateLimitBar(
                  label: 'Tool Calls / Session',
                  current: 0,
                  max: limits.maxToolCallsPerSession,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RateLimitBar extends StatelessWidget {
  final String label;
  final int current;
  final int max;

  const _RateLimitBar({
    required this.label,
    required this.current,
    required this.max,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = max > 0 ? (current / max).clamp(0.0, 1.0) : 0.0;
    final color = ratio > 0.9
        ? CodeOpsColors.error
        : ratio > 0.7
            ? CodeOpsColors.warning
            : CodeOpsColors.success;

    return Row(
      children: [
        SizedBox(
          width: 160,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: CodeOpsColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              backgroundColor: CodeOpsColors.border,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 70,
          child: Text(
            '$current / $max',
            style: const TextStyle(
              fontSize: 11,
              color: CodeOpsColors.textPrimary,
              fontFamily: 'monospace',
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Setup Instructions Panel
// ─────────────────────────────────────────────────────────────────────────────

class _SetupInstructionsPanel extends StatefulWidget {
  const _SetupInstructionsPanel();

  @override
  State<_SetupInstructionsPanel> createState() =>
      _SetupInstructionsPanelState();
}

class _SetupInstructionsPanelState extends State<_SetupInstructionsPanel> {
  bool _expanded = false;

  static const _configTemplate = '''{
  "mcpServers": {
    "codeops": {
      "command": "npx",
      "args": ["-y", "@anthropic/mcp-remote"],
      "env": {
        "MCP_REMOTE_URL": "https://your-server.com/api/v1/mcp/sse",
        "MCP_API_TOKEN": "mcp_your_token_here"
      }
    }
  }
}''';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CodeOpsColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CodeOpsColors.border),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Setup Instructions',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: CodeOpsColors.textPrimary,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: CodeOpsColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1, color: CodeOpsColors.border),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step 1
                  _buildStep(
                    '1',
                    'Create an API Token',
                    'Navigate to Developer Profile and generate a new MCP API token with the required scopes.',
                  ),
                  const SizedBox(height: 12),
                  // Step 2
                  _buildStep(
                    '2',
                    'Configure Claude Code',
                    'Add the following to your Claude Code MCP configuration file:',
                  ),
                  const SizedBox(height: 8),
                  // Config template with copy button
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CodeOpsColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: CodeOpsColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              onPressed: () {
                                Clipboard.setData(
                                  const ClipboardData(text: _configTemplate),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('Config copied to clipboard'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.copy, size: 14),
                              color: CodeOpsColors.textSecondary,
                              tooltip: 'Copy',
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                        const SelectableText(
                          _configTemplate,
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                            color: CodeOpsColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Step 3
                  _buildStep(
                    '3',
                    'Verify Connection',
                    'Start a new Claude Code session. The agent should appear in the Connected Agents panel above.',
                  ),
                  const SizedBox(height: 16),
                  // Transport options
                  const Text(
                    'Transport Options',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: CodeOpsColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildTransportOption(
                    'SSE',
                    '/api/v1/mcp/sse',
                    'Recommended for real-time bidirectional communication.',
                  ),
                  const SizedBox(height: 6),
                  _buildTransportOption(
                    'HTTP',
                    '/api/v1/mcp/protocol/message',
                    'Stateless REST transport for simple integrations.',
                  ),
                  const SizedBox(height: 6),
                  _buildTransportOption(
                    'STDIO',
                    'npx @anthropic/mcp-remote',
                    'CLI subprocess transport via remote bridge.',
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStep(String number, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: CodeOpsColors.primary.withValues(alpha: 0.2),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: CodeOpsColors.primary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: CodeOpsColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 11,
                  color: CodeOpsColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTransportOption(
      String name, String endpoint, String description) {
    return Row(
      children: [
        Container(
          width: 48,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: CodeOpsColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            name,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: CodeOpsColors.primary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          endpoint,
          style: const TextStyle(
            fontSize: 11,
            fontFamily: 'monospace',
            color: CodeOpsColors.textPrimary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            description,
            style: const TextStyle(
              fontSize: 10,
              color: CodeOpsColors.textTertiary,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Connection History Panel
// ─────────────────────────────────────────────────────────────────────────────

class _ConnectionHistoryPanel extends ConsumerWidget {
  const _ConnectionHistoryPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(connectionHistoryProvider);

    return Container(
      decoration: BoxDecoration(
        color: CodeOpsColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CodeOpsColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Connection History',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: CodeOpsColors.textPrimary,
              ),
            ),
          ),
          const Divider(height: 1, color: CodeOpsColors.border),
          eventsAsync.when(
            loading: () => const SizedBox(
              height: 100,
              child: Center(
                child:
                    CircularProgressIndicator(color: CodeOpsColors.primary),
              ),
            ),
            error: (_, __) => const SizedBox(
              height: 100,
              child: Center(
                child: Text(
                  'Failed to load history',
                  style: TextStyle(color: CodeOpsColors.error, fontSize: 12),
                ),
              ),
            ),
            data: (events) {
              if (events.isEmpty) {
                return const SizedBox(
                  height: 100,
                  child: Center(
                    child: Text(
                      'No connection events',
                      style: TextStyle(
                        color: CodeOpsColors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              }

              // Show up to 20 most recent events
              final display = events.take(20).toList();

              return SizedBox(
                height: 240,
                child: ListView.builder(
                  itemCount: display.length,
                  padding: EdgeInsets.zero,
                  itemBuilder: (context, index) {
                    final event = display[index];
                    return _ConnectionEventRow(event: event);
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ConnectionEventRow extends StatelessWidget {
  final ConnectionEvent event;

  const _ConnectionEventRow({required this.event});

  @override
  Widget build(BuildContext context) {
    final icon = switch (event.type) {
      ConnectionEventType.connected => Icons.login,
      ConnectionEventType.disconnected => Icons.logout,
      ConnectionEventType.authFailure => Icons.lock_outline,
      ConnectionEventType.rateLimitHit => Icons.speed,
      ConnectionEventType.timeout => Icons.timer_off,
    };

    final color = switch (event.type) {
      ConnectionEventType.connected => CodeOpsColors.success,
      ConnectionEventType.disconnected => CodeOpsColors.textTertiary,
      ConnectionEventType.authFailure => CodeOpsColors.error,
      ConnectionEventType.rateLimitHit => CodeOpsColors.warning,
      ConnectionEventType.timeout => CodeOpsColors.warning,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Text(
            DateFormat('MMM d HH:mm:ss').format(event.timestamp),
            style: const TextStyle(
              fontSize: 10,
              color: CodeOpsColors.textTertiary,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              event.description,
              style: const TextStyle(
                fontSize: 11,
                color: CodeOpsColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
