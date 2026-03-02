/// Retention & admin page — retention policies, storage usage, anomaly detection.
///
/// **Layout:** Logger sidebar + tabbed content area with three tabs:
/// Retention Policies, Storage & Ingestion, and Anomaly Detection.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/logger_enums.dart';
import '../../models/logger_models.dart';
import '../../providers/logger_providers.dart';
import '../../providers/team_providers.dart' show selectedTeamIdProvider;
import '../../theme/colors.dart';
import '../../widgets/logger/anomaly_baseline_dialog.dart';
import '../../widgets/logger/anomaly_report_panel.dart';
import '../../widgets/logger/ingestion_chart.dart';
import '../../widgets/logger/logger_sidebar.dart';
import '../../widgets/logger/retention_policy_dialog.dart';
import '../../widgets/logger/storage_chart.dart';
import '../../widgets/shared/empty_state.dart';
import '../../widgets/shared/error_panel.dart';

/// The retention & admin page.
class RetentionAdminPage extends ConsumerStatefulWidget {
  /// Creates a [RetentionAdminPage].
  const RetentionAdminPage({super.key});

  @override
  ConsumerState<RetentionAdminPage> createState() =>
      _RetentionAdminPageState();
}

class _RetentionAdminPageState extends ConsumerState<RetentionAdminPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
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
              subtitle: 'Select a team to manage retention.',
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
              Expanded(
                child: TabBarView(
                  controller: _tabCtrl,
                  children: [
                    _RetentionPoliciesTab(teamId: teamId),
                    _StorageTab(),
                    _AnomalyTab(teamId: teamId),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Top toolbar with tabs.
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
            Icons.storage_outlined,
            color: CodeOpsColors.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          const Text(
            'Retention & Admin',
            style: TextStyle(
              color: CodeOpsColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: TabBar(
              controller: _tabCtrl,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: CodeOpsColors.primary,
              unselectedLabelColor: CodeOpsColors.textSecondary,
              indicatorColor: CodeOpsColors.primary,
              labelStyle: const TextStyle(fontSize: 12),
              tabs: const [
                Tab(text: 'Retention Policies'),
                Tab(text: 'Storage & Ingestion'),
                Tab(text: 'Anomaly Detection'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1: Retention Policies
// ─────────────────────────────────────────────────────────────────────────────

/// Retention policies tab with table and CRUD actions.
class _RetentionPoliciesTab extends ConsumerWidget {
  final String teamId;

  const _RetentionPoliciesTab({required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final policiesAsync = ref.watch(loggerRetentionPoliciesProvider);

    return policiesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => ErrorPanel(
        title: 'Failed to load policies',
        message: err.toString(),
      ),
      data: (policies) => _buildContent(context, ref, policies),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    List<RetentionPolicyResponse> policies,
  ) {
    return Column(
      children: [
        // Action bar.
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: CodeOpsColors.border),
            ),
          ),
          child: Row(
            children: [
              Text(
                '${policies.length} policies',
                style: const TextStyle(
                  color: CodeOpsColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                icon: const Icon(Icons.add, size: 14),
                label: const Text('Create Policy'),
                style: TextButton.styleFrom(
                  textStyle: const TextStyle(fontSize: 12),
                ),
                onPressed: () => _showCreateDialog(context, ref),
              ),
            ],
          ),
        ),

        // Table.
        Expanded(
          child: policies.isEmpty
              ? const EmptyState(
                  icon: Icons.policy_outlined,
                  title: 'No retention policies',
                  subtitle: 'Create a policy to manage data lifecycle.',
                )
              : SingleChildScrollView(
                  child: DataTable(
                    headingRowHeight: 36,
                    dataRowMinHeight: 36,
                    dataRowMaxHeight: 36,
                    columnSpacing: 20,
                    columns: const [
                      DataColumn(
                        label: Text('Name',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: CodeOpsColors.textSecondary)),
                      ),
                      DataColumn(
                        label: Text('Source',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: CodeOpsColors.textSecondary)),
                      ),
                      DataColumn(
                        label: Text('Days',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: CodeOpsColors.textSecondary)),
                        numeric: true,
                      ),
                      DataColumn(
                        label: Text('Action',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: CodeOpsColors.textSecondary)),
                      ),
                      DataColumn(
                        label: Text('Active',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: CodeOpsColors.textSecondary)),
                      ),
                      DataColumn(
                        label: Text('Last Executed',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: CodeOpsColors.textSecondary)),
                      ),
                      DataColumn(
                        label: Text('Actions',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: CodeOpsColors.textSecondary)),
                      ),
                    ],
                    rows: policies.map((p) {
                      return DataRow(cells: [
                        DataCell(Text(p.name,
                            style: const TextStyle(
                                fontSize: 11,
                                color: CodeOpsColors.textPrimary))),
                        DataCell(Text(p.sourceName ?? 'All',
                            style: const TextStyle(
                                fontSize: 11,
                                color: CodeOpsColors.textSecondary))),
                        DataCell(Text('${p.retentionDays}',
                            style: const TextStyle(
                                fontSize: 11,
                                color: CodeOpsColors.textPrimary))),
                        DataCell(Text(p.action.displayName,
                            style: const TextStyle(
                                fontSize: 11,
                                color: CodeOpsColors.textPrimary))),
                        DataCell(
                          Switch(
                            value: p.isActive,
                            onChanged: (v) async {
                              final api = ref.read(loggerApiProvider);
                              await api.toggleRetentionPolicy(
                                teamId,
                                p.id,
                                active: v,
                              );
                              ref.invalidate(
                                  loggerRetentionPoliciesProvider);
                            },
                            activeThumbColor: CodeOpsColors.primary,
                          ),
                        ),
                        DataCell(Text(
                          p.lastExecutedAt != null
                              ? DateFormat('MMM d, HH:mm')
                                  .format(p.lastExecutedAt!)
                              : 'Never',
                          style: const TextStyle(
                              fontSize: 11,
                              color: CodeOpsColors.textSecondary),
                        )),
                        DataCell(Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 14),
                              color: CodeOpsColors.textSecondary,
                              tooltip: 'Edit',
                              onPressed: () => _showEditDialog(
                                  context, ref, p),
                            ),
                            IconButton(
                              icon: const Icon(Icons.play_arrow,
                                  size: 14),
                              color: CodeOpsColors.primary,
                              tooltip: 'Execute Now',
                              onPressed: () async {
                                final api =
                                    ref.read(loggerApiProvider);
                                await api.executeRetentionPolicy(
                                    teamId, p.id);
                                ref.invalidate(
                                    loggerRetentionPoliciesProvider);
                              },
                            ),
                            IconButton(
                              icon:
                                  const Icon(Icons.delete, size: 14),
                              color: CodeOpsColors.error,
                              tooltip: 'Delete',
                              onPressed: () async {
                                final api =
                                    ref.read(loggerApiProvider);
                                await api.deleteRetentionPolicy(
                                    teamId, p.id);
                                ref.invalidate(
                                    loggerRetentionPoliciesProvider);
                              },
                            ),
                          ],
                        )),
                      ]);
                    }).toList(),
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _showCreateDialog(
      BuildContext context, WidgetRef ref) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const RetentionPolicyDialog(),
    );
    if (result == null) return;

    final api = ref.read(loggerApiProvider);
    await api.createRetentionPolicy(
      teamId,
      name: result['name'] as String,
      retentionDays: result['retentionDays'] as int,
      action: result['action'] as RetentionAction,
      sourceName: result['sourceName'] as String?,
      logLevel: result['logLevel'] as LogLevel?,
      archiveDestination: result['archiveDestination'] as String?,
    );
    ref.invalidate(loggerRetentionPoliciesProvider);
  }

  Future<void> _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    RetentionPolicyResponse policy,
  ) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => RetentionPolicyDialog(existing: policy),
    );
    if (result == null) return;

    final api = ref.read(loggerApiProvider);
    await api.updateRetentionPolicy(
      teamId,
      policy.id,
      name: result['name'] as String?,
      retentionDays: result['retentionDays'] as int?,
      action: result['action'] as RetentionAction?,
      sourceName: result['sourceName'] as String?,
      logLevel: result['logLevel'] as LogLevel?,
      archiveDestination: result['archiveDestination'] as String?,
      isActive: result['isActive'] as bool?,
    );
    ref.invalidate(loggerRetentionPoliciesProvider);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2: Storage & Ingestion
// ─────────────────────────────────────────────────────────────────────────────

/// Storage usage and ingestion statistics tab.
class _StorageTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storageAsync = ref.watch(loggerStorageUsageProvider);

    return storageAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => ErrorPanel(
        title: 'Failed to load storage usage',
        message: err.toString(),
      ),
      data: (usage) => Column(
        children: [
          Expanded(child: StorageChart(usage: usage)),
          const Divider(height: 1, color: CodeOpsColors.border),
          Expanded(child: IngestionChart(usage: usage)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 3: Anomaly Detection
// ─────────────────────────────────────────────────────────────────────────────

/// Anomaly detection baselines and report tab.
class _AnomalyTab extends ConsumerWidget {
  final String teamId;

  const _AnomalyTab({required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final baselinesAsync = ref.watch(loggerBaselinesProvider);

    return baselinesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => ErrorPanel(
        title: 'Failed to load baselines',
        message: err.toString(),
      ),
      data: (baselines) => Column(
        children: [
          // Action bar.
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: CodeOpsColors.border),
              ),
            ),
            child: Row(
              children: [
                Text(
                  '${baselines.length} baselines',
                  style: const TextStyle(
                    color: CodeOpsColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.assessment, size: 14),
                  label: const Text('Run Report'),
                  style: TextButton.styleFrom(
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                  onPressed: () => _showReport(context, ref),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text('Create Baseline'),
                  style: TextButton.styleFrom(
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                  onPressed: () =>
                      _showCreateBaselineDialog(context, ref),
                ),
              ],
            ),
          ),

          // Baselines table.
          Expanded(
            child: baselines.isEmpty
                ? const EmptyState(
                    icon: Icons.analytics_outlined,
                    title: 'No baselines configured',
                    subtitle:
                        'Create a baseline to detect anomalies.',
                  )
                : SingleChildScrollView(
                    child: DataTable(
                      headingRowHeight: 36,
                      dataRowMinHeight: 36,
                      dataRowMaxHeight: 36,
                      columnSpacing: 20,
                      columns: const [
                        DataColumn(
                          label: Text('Service',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      CodeOpsColors.textSecondary)),
                        ),
                        DataColumn(
                          label: Text('Metric',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      CodeOpsColors.textSecondary)),
                        ),
                        DataColumn(
                          label: Text('Baseline',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      CodeOpsColors.textSecondary)),
                          numeric: true,
                        ),
                        DataColumn(
                          label: Text('Threshold',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      CodeOpsColors.textSecondary)),
                          numeric: true,
                        ),
                        DataColumn(
                          label: Text('Active',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      CodeOpsColors.textSecondary)),
                        ),
                        DataColumn(
                          label: Text('Actions',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      CodeOpsColors.textSecondary)),
                        ),
                      ],
                      rows: baselines.map((b) {
                        return DataRow(cells: [
                          DataCell(Text(b.serviceName,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color:
                                      CodeOpsColors.textPrimary))),
                          DataCell(Text(b.metricName,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color:
                                      CodeOpsColors.textPrimary))),
                          DataCell(Text(
                              b.baselineValue.toStringAsFixed(2),
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                  color:
                                      CodeOpsColors.textPrimary))),
                          DataCell(Text(
                              '${b.deviationThreshold.toStringAsFixed(1)}σ',
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                  color:
                                      CodeOpsColors.textPrimary))),
                          DataCell(Icon(
                            b.isActive
                                ? Icons.check_circle
                                : Icons.cancel,
                            size: 14,
                            color: b.isActive
                                ? CodeOpsColors.success
                                : CodeOpsColors.textTertiary,
                          )),
                          DataCell(Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit,
                                    size: 14),
                                color: CodeOpsColors.textSecondary,
                                tooltip: 'Edit',
                                onPressed: () =>
                                    _showEditBaselineDialog(
                                        context, ref, b),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    size: 14),
                                color: CodeOpsColors.error,
                                tooltip: 'Delete',
                                onPressed: () async {
                                  final api = ref
                                      .read(loggerApiProvider);
                                  await api.deleteBaseline(b.id);
                                  ref.invalidate(
                                      loggerBaselinesProvider);
                                },
                              ),
                            ],
                          )),
                        ]);
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateBaselineDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const AnomalyBaselineDialog(),
    );
    if (result == null) return;

    final api = ref.read(loggerApiProvider);
    await api.createBaseline(
      teamId,
      serviceName: result['serviceName'] as String,
      metricName: result['metricName'] as String,
      windowHours: result['windowHours'] as int,
      deviationThreshold: result['deviationThreshold'] as double,
    );
    ref.invalidate(loggerBaselinesProvider);
  }

  Future<void> _showEditBaselineDialog(
    BuildContext context,
    WidgetRef ref,
    AnomalyBaselineResponse baseline,
  ) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => AnomalyBaselineDialog(existing: baseline),
    );
    if (result == null) return;

    final api = ref.read(loggerApiProvider);
    await api.updateBaseline(
      baseline.id,
      windowHours: result['windowHours'] as int?,
      deviationThreshold: result['deviationThreshold'] as double?,
    );
    ref.invalidate(loggerBaselinesProvider);
  }

  Future<void> _showReport(BuildContext context, WidgetRef ref) async {
    final api = ref.read(loggerApiProvider);
    final report = await api.getAnomalyReport(teamId);

    if (!context.mounted) return;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: CodeOpsColors.surface,
        title: const Text(
          'Anomaly Report',
          style:
              TextStyle(color: CodeOpsColors.textPrimary, fontSize: 16),
        ),
        content: SizedBox(
          width: 500,
          height: 400,
          child: AnomalyReportPanel(report: report),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
