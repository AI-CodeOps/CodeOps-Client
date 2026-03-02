/// Alerts page with Rules and History tabs.
///
/// **Rules Tab:** Data table of alert rules with name, severity,
/// condition summary, channel, active toggle, last fired, and actions.
///
/// **History Tab:** Data table of fired alerts with timestamp, rule
/// name, severity badge, status badge, message, and ack/resolve
/// actions. Includes filter bar and badge counts.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/health_snapshot.dart';
import '../../models/logger_enums.dart';
import '../../models/logger_models.dart';
import '../../providers/logger_providers.dart';
import '../../providers/team_providers.dart' show selectedTeamIdProvider;
import '../../theme/colors.dart';
import '../../widgets/logger/logger_sidebar.dart';
import '../../widgets/shared/empty_state.dart';
import '../../widgets/shared/error_panel.dart';

/// The alerts page with Rules and History tabs.
class AlertsPage extends ConsumerStatefulWidget {
  /// Creates an [AlertsPage].
  const AlertsPage({super.key});

  @override
  ConsumerState<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends ConsumerState<AlertsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
              icon: Icons.group_off,
              title: 'No team selected',
              subtitle: 'Select a team to manage alerts.',
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        const LoggerSidebar(),
        const VerticalDivider(width: 1, color: CodeOpsColors.border),
        Expanded(
          child: Column(
            children: [
              _buildToolbar(),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _RulesTab(ref: ref),
                    _HistoryTab(ref: ref),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds the top toolbar.
  Widget _buildToolbar() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: CodeOpsColors.surface,
        border: Border(bottom: BorderSide(color: CodeOpsColors.border)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.notifications_active_outlined,
            color: CodeOpsColors.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          const Text(
            'Alerts',
            style: TextStyle(
              color: CodeOpsColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh, size: 18),
            color: CodeOpsColors.textSecondary,
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(loggerAlertRulesProvider);
              ref.invalidate(loggerAlertHistoryProvider);
              ref.invalidate(loggerActiveAlertCountsProvider);
            },
          ),
        ],
      ),
    );
  }

  /// Builds the tab bar.
  Widget _buildTabBar() {
    return Container(
      height: 36,
      decoration: const BoxDecoration(
        color: CodeOpsColors.surface,
        border: Border(bottom: BorderSide(color: CodeOpsColors.border)),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: CodeOpsColors.primary,
        unselectedLabelColor: CodeOpsColors.textSecondary,
        labelStyle:
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        indicatorColor: CodeOpsColors.primary,
        indicatorSize: TabBarIndicatorSize.label,
        tabs: const [
          Tab(text: 'Rules'),
          Tab(text: 'History'),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Rules Tab
// ─────────────────────────────────────────────────────────────────────────────

/// The alert rules tab content.
class _RulesTab extends StatelessWidget {
  final WidgetRef ref;
  const _RulesTab({required this.ref});

  @override
  Widget build(BuildContext context) {
    final rulesAsync = ref.watch(loggerAlertRulesProvider);

    return rulesAsync.when(
      data: (rules) {
        if (rules.isEmpty) {
          return const EmptyState(
            icon: Icons.rule_outlined,
            title: 'No alert rules',
            subtitle: 'Create rules to trigger notifications from traps.',
          );
        }
        return _RulesTable(rules: rules, ref: ref);
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: CodeOpsColors.primary),
      ),
      error: (error, _) => ErrorPanel.fromException(
        error,
        onRetry: () => ref.invalidate(loggerAlertRulesProvider),
      ),
    );
  }
}

/// The rules data table.
class _RulesTable extends StatelessWidget {
  final List<AlertRuleResponse> rules;
  final WidgetRef ref;

  const _RulesTable({required this.rules, required this.ref});

  Future<void> _toggleRule(AlertRuleResponse rule) async {
    final api = ref.read(loggerApiProvider);
    await api.updateAlertRule(rule.id, isActive: !rule.isActive);
    ref.invalidate(loggerAlertRulesProvider);
  }

  Future<void> _deleteRule(
    BuildContext context,
    AlertRuleResponse rule,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CodeOpsColors.surface,
        title: const Text(
          'Delete Rule',
          style: TextStyle(color: CodeOpsColors.textPrimary, fontSize: 16),
        ),
        content: Text(
          'Delete rule "${rule.name}"? This cannot be undone.',
          style: const TextStyle(
            color: CodeOpsColors.textSecondary,
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: CodeOpsColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final api = ref.read(loggerApiProvider);
      await api.deleteAlertRule(rule.id);
      ref.invalidate(loggerAlertRulesProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Column headers.
        Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          color: CodeOpsColors.surfaceVariant,
          child: const Row(
            children: [
              SizedBox(width: 60, child: _HeaderText('Active')),
              Expanded(flex: 2, child: _HeaderText('Name')),
              SizedBox(width: 80, child: _HeaderText('Severity')),
              Expanded(flex: 2, child: _HeaderText('Trap')),
              Expanded(flex: 2, child: _HeaderText('Channel')),
              SizedBox(width: 70, child: _HeaderText('Throttle')),
              SizedBox(width: 80, child: _HeaderText('Actions')),
            ],
          ),
        ),
        const Divider(height: 1, color: CodeOpsColors.border),

        // Data rows.
        Expanded(
          child: ListView.builder(
            itemCount: rules.length,
            itemBuilder: (context, index) {
              final rule = rules[index];
              return Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: index.isEven
                      ? CodeOpsColors.background
                      : CodeOpsColors.surface.withValues(alpha: 0.5),
                  border: const Border(
                    bottom: BorderSide(
                        color: CodeOpsColors.border, width: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    // Active toggle.
                    SizedBox(
                      width: 60,
                      child: Switch(
                        value: rule.isActive,
                        onChanged: (_) => _toggleRule(rule),
                        activeThumbColor: CodeOpsColors.success,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),

                    // Name.
                    Expanded(
                      flex: 2,
                      child: Text(
                        rule.name,
                        style: TextStyle(
                          color: rule.isActive
                              ? CodeOpsColors.textPrimary
                              : CodeOpsColors.textTertiary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // Severity badge.
                    SizedBox(
                      width: 80,
                      child: _SeverityBadge(severity: rule.severity),
                    ),

                    // Trap.
                    Expanded(
                      flex: 2,
                      child: Text(
                        rule.trapName,
                        style: const TextStyle(
                          color: CodeOpsColors.textSecondary,
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // Channel.
                    Expanded(
                      flex: 2,
                      child: Text(
                        rule.channelName,
                        style: const TextStyle(
                          color: CodeOpsColors.textSecondary,
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // Throttle.
                    SizedBox(
                      width: 70,
                      child: Text(
                        '${rule.throttleMinutes}m',
                        style: const TextStyle(
                          color: CodeOpsColors.textTertiary,
                          fontSize: 11,
                        ),
                      ),
                    ),

                    // Actions.
                    SizedBox(
                      width: 80,
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                size: 16),
                            color: CodeOpsColors.textTertiary,
                            tooltip: 'Delete',
                            onPressed: () =>
                                _deleteRule(context, rule),
                            constraints: const BoxConstraints(
                                minWidth: 32, minHeight: 32),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// History Tab
// ─────────────────────────────────────────────────────────────────────────────

/// The alert history tab content.
class _HistoryTab extends StatelessWidget {
  final WidgetRef ref;
  const _HistoryTab({required this.ref});

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(loggerAlertHistoryProvider);
    final countsAsync = ref.watch(loggerActiveAlertCountsProvider);

    return Column(
      children: [
        // Badge counts bar.
        _buildCountsBar(countsAsync),

        // Filter bar.
        _buildFilterBar(),

        // History table.
        Expanded(
          child: historyAsync.when(
            data: (page) {
              if (page.content.isEmpty) {
                return const EmptyState(
                  icon: Icons.history_outlined,
                  title: 'No alert history',
                  subtitle: 'Alerts will appear here when rules fire.',
                );
              }
              return _HistoryTable(page: page, ref: ref);
            },
            loading: () => const Center(
              child: CircularProgressIndicator(
                  color: CodeOpsColors.primary),
            ),
            error: (error, _) => ErrorPanel.fromException(
              error,
              onRetry: () =>
                  ref.invalidate(loggerAlertHistoryProvider),
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the status counts bar.
  Widget _buildCountsBar(AsyncValue<Map<String, int>> countsAsync) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: CodeOpsColors.surface,
        border: Border(bottom: BorderSide(color: CodeOpsColors.border)),
      ),
      child: countsAsync.when(
        data: (counts) {
          final fired = counts['FIRED'] ?? 0;
          final acknowledged = counts['ACKNOWLEDGED'] ?? 0;
          final resolved = counts['RESOLVED'] ?? 0;
          return Row(
            children: [
              _CountBadge(
                label: 'Firing',
                count: fired,
                color: CodeOpsColors.error,
              ),
              const SizedBox(width: 12),
              _CountBadge(
                label: 'Acknowledged',
                count: acknowledged,
                color: CodeOpsColors.warning,
              ),
              const SizedBox(width: 12),
              _CountBadge(
                label: 'Resolved',
                count: resolved,
                color: CodeOpsColors.success,
              ),
            ],
          );
        },
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }

  /// Builds the filter bar.
  Widget _buildFilterBar() {
    final statusFilter = ref.watch(loggerAlertStatusFilterProvider);
    final severityFilter = ref.watch(loggerAlertSeverityFilterProvider);

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: CodeOpsColors.surface,
        border: Border(bottom: BorderSide(color: CodeOpsColors.border)),
      ),
      child: Row(
        children: [
          // Status filter.
          _CompactFilter<AlertStatus?>(
            hint: 'All Status',
            value: statusFilter,
            items: [
              const DropdownMenuItem(
                  value: null, child: Text('All Status')),
              ...AlertStatus.values.map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(s.displayName),
                  )),
            ],
            onChanged: (v) {
              ref.read(loggerAlertStatusFilterProvider.notifier).state = v;
              ref.invalidate(loggerAlertHistoryProvider);
            },
          ),
          const SizedBox(width: 8),

          // Severity filter.
          _CompactFilter<AlertSeverity?>(
            hint: 'All Severity',
            value: severityFilter,
            items: [
              const DropdownMenuItem(
                  value: null, child: Text('All Severity')),
              ...AlertSeverity.values.map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(s.displayName),
                  )),
            ],
            onChanged: (v) {
              ref.read(loggerAlertSeverityFilterProvider.notifier).state =
                  v;
              ref.invalidate(loggerAlertHistoryProvider);
            },
          ),
        ],
      ),
    );
  }
}

/// The alert history data table.
class _HistoryTable extends StatelessWidget {
  final PageResponse<AlertHistoryResponse> page;
  final WidgetRef ref;

  const _HistoryTable({required this.page, required this.ref});

  Future<void> _acknowledge(
    BuildContext context,
    AlertHistoryResponse alert,
  ) async {
    final api = ref.read(loggerApiProvider);
    await api.updateAlertStatus(
      alert.id,
      status: AlertStatus.acknowledged,
    );
    ref.invalidate(loggerAlertHistoryProvider);
    ref.invalidate(loggerActiveAlertCountsProvider);
  }

  Future<void> _resolve(
    BuildContext context,
    AlertHistoryResponse alert,
  ) async {
    final api = ref.read(loggerApiProvider);
    await api.updateAlertStatus(
      alert.id,
      status: AlertStatus.resolved,
    );
    ref.invalidate(loggerAlertHistoryProvider);
    ref.invalidate(loggerActiveAlertCountsProvider);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Column headers.
        Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          color: CodeOpsColors.surfaceVariant,
          child: const Row(
            children: [
              SizedBox(width: 130, child: _HeaderText('Timestamp')),
              Expanded(flex: 2, child: _HeaderText('Rule')),
              SizedBox(width: 80, child: _HeaderText('Severity')),
              SizedBox(width: 110, child: _HeaderText('Status')),
              Expanded(flex: 3, child: _HeaderText('Message')),
              SizedBox(width: 130, child: _HeaderText('Actions')),
            ],
          ),
        ),
        const Divider(height: 1, color: CodeOpsColors.border),

        // Data rows.
        Expanded(
          child: ListView.builder(
            itemCount: page.content.length,
            itemBuilder: (context, index) {
              final alert = page.content[index];
              return Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: index.isEven
                      ? CodeOpsColors.background
                      : CodeOpsColors.surface.withValues(alpha: 0.5),
                  border: const Border(
                    bottom: BorderSide(
                        color: CodeOpsColors.border, width: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    // Timestamp.
                    SizedBox(
                      width: 130,
                      child: Text(
                        alert.createdAt != null
                            ? _formatDateTime(alert.createdAt!)
                            : '',
                        style: const TextStyle(
                          color: CodeOpsColors.textTertiary,
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),

                    // Rule name.
                    Expanded(
                      flex: 2,
                      child: Text(
                        alert.ruleName,
                        style: const TextStyle(
                          color: CodeOpsColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // Severity badge.
                    SizedBox(
                      width: 80,
                      child: _SeverityBadge(severity: alert.severity),
                    ),

                    // Status badge.
                    SizedBox(
                      width: 110,
                      child: _StatusBadge(status: alert.status),
                    ),

                    // Message.
                    Expanded(
                      flex: 3,
                      child: Text(
                        alert.message ?? '',
                        style: const TextStyle(
                          color: CodeOpsColors.textSecondary,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // Actions.
                    SizedBox(
                      width: 130,
                      child: Row(
                        children: [
                          if (alert.status == AlertStatus.fired)
                            TextButton(
                              onPressed: () =>
                                  _acknowledge(context, alert),
                              style: TextButton.styleFrom(
                                foregroundColor: CodeOpsColors.warning,
                                textStyle:
                                    const TextStyle(fontSize: 10),
                                padding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 6),
                                minimumSize: const Size(0, 24),
                              ),
                              child: const Text('Ack'),
                            ),
                          if (alert.status != AlertStatus.resolved)
                            TextButton(
                              onPressed: () =>
                                  _resolve(context, alert),
                              style: TextButton.styleFrom(
                                foregroundColor: CodeOpsColors.success,
                                textStyle:
                                    const TextStyle(fontSize: 10),
                                padding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 6),
                                minimumSize: const Size(0, 24),
                              ),
                              child: const Text('Resolve'),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // Pagination footer.
        _buildPaginationFooter(),
      ],
    );
  }

  /// Builds the pagination footer.
  Widget _buildPaginationFooter() {
    final start = page.page * page.size + 1;
    final end = start + page.content.length - 1;

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: CodeOpsColors.surface,
        border: Border(top: BorderSide(color: CodeOpsColors.border)),
      ),
      child: Row(
        children: [
          Text(
            page.content.isEmpty
                ? '0 results'
                : 'Showing $start\u2013$end of ${page.totalElements}',
            style: const TextStyle(
              color: CodeOpsColors.textTertiary,
              fontSize: 11,
            ),
          ),
          const Spacer(),
          Text(
            'Page ${page.page + 1} of ${page.totalPages == 0 ? 1 : page.totalPages}',
            style: const TextStyle(
              color: CodeOpsColors.textTertiary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  /// Formats a [DateTime] for compact display.
  String _formatDateTime(DateTime dt) {
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$m/$d $h:$min';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared Widgets
// ─────────────────────────────────────────────────────────────────────────────

/// Column header text widget.
class _HeaderText extends StatelessWidget {
  final String text;
  const _HeaderText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: CodeOpsColors.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// A colored severity badge.
class _SeverityBadge extends StatelessWidget {
  final AlertSeverity severity;
  const _SeverityBadge({required this.severity});

  @override
  Widget build(BuildContext context) {
    final color = switch (severity) {
      AlertSeverity.info => CodeOpsColors.primary,
      AlertSeverity.warning => CodeOpsColors.warning,
      AlertSeverity.critical => CodeOpsColors.error,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        severity.displayName,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// A colored alert status badge.
class _StatusBadge extends StatelessWidget {
  final AlertStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      AlertStatus.fired => CodeOpsColors.error,
      AlertStatus.acknowledged => CodeOpsColors.warning,
      AlertStatus.resolved => CodeOpsColors.success,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// A compact count badge for the status bar.
class _CountBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _CountBadge({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$label ($count)',
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// A compact dropdown for the filter bar.
class _CompactFilter<T> extends StatelessWidget {
  final String hint;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _CompactFilter({
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: CodeOpsColors.background,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: CodeOpsColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          dropdownColor: CodeOpsColors.surface,
          style: const TextStyle(
            color: CodeOpsColors.textPrimary,
            fontSize: 11,
          ),
          icon: const Icon(
            Icons.expand_more,
            size: 14,
            color: CodeOpsColors.textTertiary,
          ),
          isDense: true,
        ),
      ),
    );
  }
}
