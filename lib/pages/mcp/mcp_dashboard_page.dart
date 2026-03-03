/// MCP dashboard page.
///
/// Landing page at `/mcp` providing an at-a-glance overview of the MCP
/// AI Development Control Plane: active session metrics, recent sessions,
/// team activity feed, document health, and quick navigation links.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/mcp_enums.dart';
import '../../models/mcp_models.dart';
import '../../providers/mcp_dashboard_providers.dart';
import '../../providers/team_providers.dart' show selectedTeamIdProvider;
import '../../theme/colors.dart';
import '../../widgets/shared/empty_state.dart';
import '../../widgets/shared/error_panel.dart';

/// The MCP dashboard page.
class McpDashboardPage extends ConsumerStatefulWidget {
  /// Creates a [McpDashboardPage].
  const McpDashboardPage({super.key});

  @override
  ConsumerState<McpDashboardPage> createState() => _McpDashboardPageState();
}

class _McpDashboardPageState extends ConsumerState<McpDashboardPage> {
  /// Refreshes all dashboard data.
  void _refresh() {
    ref.invalidate(mcpDashboardSessionsProvider);
    ref.invalidate(mcpRecentActivityProvider);
  }

  @override
  Widget build(BuildContext context) {
    final teamId = ref.watch(selectedTeamIdProvider);

    if (teamId == null) {
      return const EmptyState(
        icon: Icons.group_outlined,
        title: 'No team selected',
        subtitle: 'Select a team to view MCP dashboard.',
      );
    }

    final sessionsAsync = ref.watch(mcpDashboardSessionsProvider);

    return sessionsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: CodeOpsColors.primary),
      ),
      error: (error, _) => ErrorPanel.fromException(
        error,
        onRetry: _refresh,
      ),
      data: (_) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            _HeaderRow(onRefresh: _refresh),
            const SizedBox(height: 20),

            // Stat cards
            const _StatCardsRow(),
            const SizedBox(height: 24),

            // Two-column: Recent Sessions + Activity Feed
            const _TwoColumnSection(),
            const SizedBox(height: 24),

            // Quick actions
            const _QuickActions(),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header Row
// ---------------------------------------------------------------------------

class _HeaderRow extends StatelessWidget {
  final VoidCallback onRefresh;

  const _HeaderRow({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'MCP Dashboard',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh',
          onPressed: onRefresh,
          color: CodeOpsColors.textSecondary,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Stat Cards Row
// ---------------------------------------------------------------------------

class _StatCardsRow extends ConsumerWidget {
  const _StatCardsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSessions = ref.watch(mcpActiveSessionCountProvider);
    final sessionsToday = ref.watch(mcpSessionsTodayProvider);
    final toolCallsToday = ref.watch(mcpToolCallsTodayProvider);
    final connectedAgents = ref.watch(mcpConnectedAgentsCountProvider);

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _StatCard(
          icon: Icons.play_circle_outline,
          label: 'Active Sessions',
          value: '$activeSessions',
          color: activeSessions > 0
              ? CodeOpsColors.success
              : CodeOpsColors.textTertiary,
        ),
        _StatCard(
          icon: Icons.today_outlined,
          label: 'Sessions Today',
          value: '${sessionsToday.length}',
          color: CodeOpsColors.primary,
        ),
        _StatCard(
          icon: Icons.build_outlined,
          label: 'Tool Calls Today',
          value: '$toolCallsToday',
          color: CodeOpsColors.secondary,
        ),
        _StatCard(
          icon: Icons.people_outline,
          label: 'Connected Agents',
          value: '$connectedAgents',
          color: CodeOpsColors.warning,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Stat Card
// ---------------------------------------------------------------------------

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CodeOpsColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CodeOpsColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: CodeOpsColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Two-Column Section (Recent Sessions + Activity Feed)
// ---------------------------------------------------------------------------

class _TwoColumnSection extends StatelessWidget {
  const _TwoColumnSection();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 800) {
          return const Column(
            children: [
              _RecentSessions(),
              SizedBox(height: 16),
              _RecentActivity(),
            ],
          );
        }
        return const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _RecentSessions()),
            SizedBox(width: 16),
            Expanded(child: _RecentActivity()),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Recent Sessions
// ---------------------------------------------------------------------------

class _RecentSessions extends ConsumerWidget {
  const _RecentSessions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(mcpRecentSessionsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Recent Sessions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            TextButton(
              onPressed: () => context.go('/mcp/sessions'),
              child: const Text(
                'View All \u2192',
                style: TextStyle(fontSize: 12, color: CodeOpsColors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: CodeOpsColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: CodeOpsColors.border),
          ),
          child: sessions.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      'No sessions found',
                      style: TextStyle(color: CodeOpsColors.textTertiary),
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < sessions.length; i++) ...[
                      if (i > 0)
                        const Divider(
                          height: 1,
                          color: CodeOpsColors.border,
                        ),
                      _SessionTile(session: sessions[i]),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Session Tile
// ---------------------------------------------------------------------------

class _SessionTile extends StatelessWidget {
  final McpSession session;

  const _SessionTile({required this.session});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: session.id != null
          ? () => context.go('/mcp/sessions/${session.id}')
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Developer name
            Expanded(
              flex: 2,
              child: Text(
                session.developerName ?? 'Unknown',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: CodeOpsColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            // Project name
            Expanded(
              flex: 2,
              child: Text(
                session.projectName ?? '',
                style: const TextStyle(
                  fontSize: 12,
                  color: CodeOpsColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            // Status badge
            _StatusBadge(status: session.status),
            const SizedBox(width: 8),
            // Duration / started time
            Text(
              _formatTime(session.startedAt),
              style: const TextStyle(
                fontSize: 11,
                color: CodeOpsColors.textTertiary,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Formats a timestamp for display.
  static String _formatTime(DateTime? ts) {
    if (ts == null) return '--:--';
    return DateFormat.Hm().format(ts.toLocal());
  }
}

// ---------------------------------------------------------------------------
// Status Badge
// ---------------------------------------------------------------------------

class _StatusBadge extends StatelessWidget {
  final SessionStatus? status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    final label = status?.displayName ?? 'Unknown';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  /// Returns a color for the given session status.
  static Color _statusColor(SessionStatus? status) {
    return switch (status) {
      SessionStatus.active => CodeOpsColors.success,
      SessionStatus.initializing => CodeOpsColors.success,
      SessionStatus.completing => CodeOpsColors.secondary,
      SessionStatus.completed => const Color(0xFF3B82F6),
      SessionStatus.failed => CodeOpsColors.error,
      SessionStatus.timedOut => CodeOpsColors.warning,
      SessionStatus.cancelled => CodeOpsColors.textTertiary,
      null => CodeOpsColors.textTertiary,
    };
  }
}

// ---------------------------------------------------------------------------
// Recent Activity
// ---------------------------------------------------------------------------

class _RecentActivity extends ConsumerWidget {
  const _RecentActivity();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(mcpRecentActivityProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            TextButton(
              onPressed: () => context.go('/mcp/activity'),
              child: const Text(
                'View All \u2192',
                style: TextStyle(fontSize: 12, color: CodeOpsColors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: CodeOpsColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: CodeOpsColors.border),
          ),
          child: activityAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child:
                    CircularProgressIndicator(color: CodeOpsColors.primary),
              ),
            ),
            error: (error, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Failed to load activity',
                style: TextStyle(color: CodeOpsColors.error),
              ),
            ),
            data: (entries) {
              if (entries.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      'No activity found',
                      style: TextStyle(color: CodeOpsColors.textTertiary),
                    ),
                  ),
                );
              }
              return Column(
                children: [
                  for (var i = 0; i < entries.length; i++) ...[
                    if (i > 0)
                      const Divider(
                        height: 1,
                        color: CodeOpsColors.border,
                      ),
                    _ActivityTile(entry: entries[i]),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Activity Tile
// ---------------------------------------------------------------------------

class _ActivityTile extends StatelessWidget {
  final ActivityFeedEntry entry;

  const _ActivityTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(
            _activityIcon(entry.activityType),
            size: 16,
            color: _activityColor(entry.activityType),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title ?? '',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: CodeOpsColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (entry.detail != null)
                  Text(
                    entry.detail!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: CodeOpsColors.textTertiary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatTimestamp(entry.createdAt),
            style: const TextStyle(
              fontSize: 10,
              color: CodeOpsColors.textTertiary,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  /// Returns an icon for the given activity type.
  static IconData _activityIcon(ActivityType? type) {
    return switch (type) {
      ActivityType.sessionCompleted => Icons.check_circle_outline,
      ActivityType.sessionFailed => Icons.error_outline,
      ActivityType.documentUpdated => Icons.description_outlined,
      ActivityType.conventionChanged => Icons.rule,
      ActivityType.directiveChanged => Icons.tune,
      ActivityType.impactDetected => Icons.warning_amber,
      null => Icons.circle_outlined,
    };
  }

  /// Returns a color for the given activity type.
  static Color _activityColor(ActivityType? type) {
    return switch (type) {
      ActivityType.sessionCompleted => CodeOpsColors.success,
      ActivityType.sessionFailed => CodeOpsColors.error,
      ActivityType.documentUpdated => CodeOpsColors.secondary,
      ActivityType.conventionChanged => CodeOpsColors.primary,
      ActivityType.directiveChanged => CodeOpsColors.warning,
      ActivityType.impactDetected => CodeOpsColors.error,
      null => CodeOpsColors.textTertiary,
    };
  }

  /// Formats a timestamp for display.
  static String _formatTimestamp(DateTime? ts) {
    if (ts == null) return '';
    return DateFormat.Hm().format(ts.toLocal());
  }
}

// ---------------------------------------------------------------------------
// Quick Actions
// ---------------------------------------------------------------------------

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  static const _actions = <({IconData icon, String label, String path})>[
    (icon: Icons.list_alt_outlined, label: 'Sessions', path: '/mcp/sessions'),
    (
      icon: Icons.rss_feed_outlined,
      label: 'Activity Feed',
      path: '/mcp/activity',
    ),
    (
      icon: Icons.description_outlined,
      label: 'Documents',
      path: '/mcp/documents',
    ),
    (icon: Icons.people_outline, label: 'Profiles', path: '/mcp/profiles'),
    (
      icon: Icons.gavel_outlined,
      label: 'Conventions',
      path: '/mcp/conventions',
    ),
    (
      icon: Icons.receipt_long_outlined,
      label: 'Audit Log',
      path: '/mcp/audit-log',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final action in _actions)
              _QuickActionCard(
                icon: action.icon,
                label: action.label,
                onTap: () => context.go(action.path),
              ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CodeOpsColors.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          width: 160,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: CodeOpsColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: CodeOpsColors.primary),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: CodeOpsColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
