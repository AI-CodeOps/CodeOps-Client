/// Logger dashboard page.
///
/// Landing page at `/logger` providing an at-a-glance overview of the
/// Logger system: stat cards (active sources, traps, alerts, storage),
/// recent log entries, quick actions, and a time range selector.
/// Includes the [LoggerSidebar] on the left for sub-page navigation.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/health_snapshot.dart';
import '../../models/logger_enums.dart';
import '../../models/logger_models.dart';
import '../../providers/logger_providers.dart';
import '../../providers/team_providers.dart' show selectedTeamIdProvider;
import '../../theme/colors.dart';
import '../../widgets/logger/logger_sidebar.dart';
import '../../widgets/shared/empty_state.dart';
import '../../widgets/shared/error_panel.dart';

/// The Logger dashboard page with sidebar and overview content.
class LoggerDashboardPage extends ConsumerStatefulWidget {
  /// Creates a [LoggerDashboardPage].
  const LoggerDashboardPage({super.key});

  @override
  ConsumerState<LoggerDashboardPage> createState() =>
      _LoggerDashboardPageState();
}

class _LoggerDashboardPageState extends ConsumerState<LoggerDashboardPage> {
  /// Refreshes all dashboard data.
  void _refresh() {
    ref.invalidate(loggerSourcesProvider);
    ref.invalidate(loggerTrapsProvider);
    ref.invalidate(loggerActiveAlertCountsProvider);
    ref.invalidate(loggerLogsProvider);
    ref.invalidate(loggerStorageUsageProvider);
  }

  @override
  Widget build(BuildContext context) {
    final teamId = ref.watch(selectedTeamIdProvider);

    if (teamId == null) {
      return Row(
        children: [
          const LoggerSidebar(),
          const VerticalDivider(width: 1, color: CodeOpsColors.border),
          const Expanded(
            child: EmptyState(
              icon: Icons.group_outlined,
              title: 'No team selected',
              subtitle: 'Select a team to view Logger dashboard.',
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        const LoggerSidebar(),
        const VerticalDivider(width: 1, color: CodeOpsColors.border),
        Expanded(child: _DashboardContent(onRefresh: _refresh)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Dashboard Content
// ---------------------------------------------------------------------------

class _DashboardContent extends ConsumerWidget {
  final VoidCallback onRefresh;

  const _DashboardContent({required this.onRefresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sourcesAsync = ref.watch(loggerSourcesProvider);
    final trapsAsync = ref.watch(loggerTrapsProvider);
    final alertCountsAsync = ref.watch(loggerActiveAlertCountsProvider);
    final logsAsync = ref.watch(loggerLogsProvider);
    final timeRange = ref.watch(loggerDashboardTimeRangeProvider);

    return sourcesAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: CodeOpsColors.primary),
      ),
      error: (error, _) => ErrorPanel.fromException(error, onRetry: onRefresh),
      data: (sources) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with time range selector
            _HeaderRow(onRefresh: onRefresh, timeRange: timeRange),
            const SizedBox(height: 20),

            // Stat cards
            _StatCardsRow(
              sourceCount: sources.length,
              trapsAsync: trapsAsync,
              alertCountsAsync: alertCountsAsync,
              logsAsync: logsAsync,
            ),
            const SizedBox(height: 24),

            // Recent activity
            _RecentActivity(logsAsync: logsAsync),
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

class _HeaderRow extends ConsumerWidget {
  final VoidCallback onRefresh;
  final int timeRange;

  const _HeaderRow({required this.onRefresh, required this.timeRange});

  static const _timeRangeOptions = <int, String>{
    0: 'Last 15 min',
    1: 'Last 1 hour',
    6: 'Last 6 hours',
    24: 'Last 24 hours',
    168: 'Last 7 days',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Text(
          'Logger Dashboard',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const Spacer(),
        // Time range selector
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: CodeOpsColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: CodeOpsColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _timeRangeOptions.containsKey(timeRange) ? timeRange : 1,
              dropdownColor: CodeOpsColors.surface,
              style: const TextStyle(
                fontSize: 13,
                color: CodeOpsColors.textPrimary,
              ),
              icon: const Icon(
                Icons.arrow_drop_down,
                color: CodeOpsColors.textSecondary,
              ),
              items: _timeRangeOptions.entries
                  .map((e) => DropdownMenuItem(
                        value: e.key,
                        child: Text(e.value),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  ref.read(loggerDashboardTimeRangeProvider.notifier).state =
                      value;
                }
              },
            ),
          ),
        ),
        const SizedBox(width: 8),
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

class _StatCardsRow extends StatelessWidget {
  final int sourceCount;
  final AsyncValue<List<LogTrapResponse>> trapsAsync;
  final AsyncValue<Map<String, int>> alertCountsAsync;
  final AsyncValue<PageResponse<LogEntryResponse>> logsAsync;

  const _StatCardsRow({
    required this.sourceCount,
    required this.trapsAsync,
    required this.alertCountsAsync,
    required this.logsAsync,
  });

  @override
  Widget build(BuildContext context) {
    final trapCount = trapsAsync.whenOrNull(data: (t) => t.length) ?? 0;
    final alertTotal = alertCountsAsync.whenOrNull(
          data: (c) => c.values.fold<int>(0, (a, b) => a + b),
        ) ??
        0;
    final totalLogs =
        logsAsync.whenOrNull(data: (p) => p.totalElements) ?? 0;

    // Compute error rate from logs
    final errorCount = logsAsync.whenOrNull(
          data: (p) => p.content
              .where((e) =>
                  e.level == LogLevel.error || e.level == LogLevel.fatal)
              .length,
        ) ??
        0;
    final pageSize =
        logsAsync.whenOrNull(data: (p) => p.content.length) ?? 0;
    final errorPct =
        pageSize > 0 ? ((errorCount / pageSize) * 100).toStringAsFixed(1) : '0';

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _StatCard(
          icon: Icons.source_outlined,
          label: 'Active Sources',
          value: '$sourceCount',
          color: CodeOpsColors.secondary,
        ),
        _StatCard(
          icon: Icons.filter_alt_outlined,
          label: 'Active Traps',
          value: '$trapCount',
          color: CodeOpsColors.warning,
        ),
        _StatCard(
          icon: Icons.notifications_active_outlined,
          label: 'Active Alerts',
          value: '$alertTotal',
          color: alertTotal > 0 ? CodeOpsColors.error : CodeOpsColors.success,
        ),
        _StatCard(
          icon: Icons.article_outlined,
          label: 'Total Logs',
          value: _formatCount(totalLogs),
          color: CodeOpsColors.primary,
        ),
        _StatCard(
          icon: Icons.error_outline,
          label: 'Error Rate',
          value: '$errorPct%',
          color: double.parse(errorPct) > 5
              ? CodeOpsColors.error
              : CodeOpsColors.success,
        ),
      ],
    );
  }

  /// Formats a count with K/M suffixes.
  static String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '$count';
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
// Recent Activity
// ---------------------------------------------------------------------------

class _RecentActivity extends StatelessWidget {
  final AsyncValue<PageResponse<LogEntryResponse>> logsAsync;

  const _RecentActivity({required this.logsAsync});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: CodeOpsColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: CodeOpsColors.border),
          ),
          child: logsAsync.when(
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
                'Failed to load recent logs',
                style: TextStyle(color: CodeOpsColors.error),
              ),
            ),
            data: (page) {
              final entries = page.content.take(20).toList();
              if (entries.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      'No log entries found',
                      style: TextStyle(color: CodeOpsColors.textTertiary),
                    ),
                  ),
                );
              }
              return Column(
                children: [
                  for (var i = 0; i < entries.length; i++) ...[
                    if (i > 0)
                      const Divider(height: 1, color: CodeOpsColors.border),
                    _LogEntryTile(entry: entries[i]),
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
// Log Entry Tile
// ---------------------------------------------------------------------------

class _LogEntryTile extends StatelessWidget {
  final LogEntryResponse entry;

  const _LogEntryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go('/logger/viewer'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Level indicator
            Icon(
              _levelIcon(entry.level),
              size: 14,
              color: _levelColor(entry.level),
            ),
            const SizedBox(width: 10),
            // Timestamp
            Text(
              _formatTimestamp(entry.timestamp),
              style: const TextStyle(
                fontSize: 11,
                color: CodeOpsColors.textTertiary,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(width: 12),
            // Service name
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: CodeOpsColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                entry.serviceName,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: CodeOpsColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Message (truncated)
            Expanded(
              child: Text(
                entry.message,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: CodeOpsColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Returns an icon for the given log level.
  static IconData _levelIcon(LogLevel level) {
    return switch (level) {
      LogLevel.fatal => Icons.dangerous,
      LogLevel.error => Icons.error,
      LogLevel.warn => Icons.warning_amber,
      LogLevel.info => Icons.info_outline,
      LogLevel.debug => Icons.bug_report_outlined,
      LogLevel.trace => Icons.radio_button_unchecked,
    };
  }

  /// Returns a color for the given log level.
  static Color _levelColor(LogLevel level) {
    return switch (level) {
      LogLevel.fatal => CodeOpsColors.critical,
      LogLevel.error => CodeOpsColors.error,
      LogLevel.warn => CodeOpsColors.warning,
      LogLevel.info => CodeOpsColors.secondary,
      LogLevel.debug => CodeOpsColors.textSecondary,
      LogLevel.trace => CodeOpsColors.textTertiary,
    };
  }

  /// Formats a timestamp for display.
  static String _formatTimestamp(DateTime ts) {
    final h = ts.hour.toString().padLeft(2, '0');
    final m = ts.minute.toString().padLeft(2, '0');
    final s = ts.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

// ---------------------------------------------------------------------------
// Quick Actions
// ---------------------------------------------------------------------------

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  static const _actions = <({IconData icon, String label, String path})>[
    (icon: Icons.list_alt_outlined, label: 'Open Log Viewer', path: '/logger/viewer'),
    (icon: Icons.search, label: 'Search Logs', path: '/logger/search'),
    (icon: Icons.filter_alt_outlined, label: 'Manage Traps', path: '/logger/traps'),
    (icon: Icons.bar_chart_outlined, label: 'View Metrics', path: '/logger/metrics'),
    (icon: Icons.timeline_outlined, label: 'Trace Explorer', path: '/logger/traces'),
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
