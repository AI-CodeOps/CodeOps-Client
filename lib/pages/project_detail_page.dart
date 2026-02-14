/// Project detail page with header, metrics, health trend, jobs,
/// repo info, Jira mapping, directives, and settings.
///
/// Reads `projectId` from GoRouter path parameters.
library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/directive.dart';
import '../models/enums.dart';
import '../models/health_snapshot.dart';
import '../models/project.dart';
import '../models/qa_job.dart';
import '../providers/directive_providers.dart';
import '../providers/github_providers.dart';
import '../providers/health_providers.dart';
import '../providers/project_providers.dart';
import '../theme/colors.dart';
import '../utils/constants.dart';
import '../utils/date_utils.dart';
import '../widgets/shared/confirm_dialog.dart';
import '../widgets/shared/error_panel.dart';
import '../widgets/shared/loading_overlay.dart';
import '../widgets/shared/notification_toast.dart';

/// The project detail page replacing the `/projects/:id` placeholder.
class ProjectDetailPage extends ConsumerWidget {
  /// Creates a [ProjectDetailPage].
  const ProjectDetailPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectId = GoRouterState.of(context).pathParameters['id'];
    if (projectId == null) {
      return const ErrorPanel(
        title: 'Missing Project',
        message: 'No project ID was provided.',
      );
    }

    final projectAsync = ref.watch(projectProvider(projectId));

    return projectAsync.when(
      loading: () => const LoadingOverlay(message: 'Loading project...'),
      error: (error, _) => ErrorPanel.fromException(
        error,
        onRetry: () => ref.invalidate(projectProvider(projectId)),
      ),
      data: (project) => _ProjectDetailBody(project: project),
    );
  }
}

// ---------------------------------------------------------------------------
// Main body
// ---------------------------------------------------------------------------

class _ProjectDetailBody extends ConsumerWidget {
  final Project project;

  const _ProjectDetailBody({required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProjectHeader(project: project),
          const SizedBox(height: 24),
          _MetricsCards(projectId: project.id),
          const SizedBox(height: 24),
          _HealthTrendChart(projectId: project.id),
          const SizedBox(height: 24),
          _RecentJobsTable(projectId: project.id),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _RepositoryInfoCard(project: project)),
              const SizedBox(width: 16),
              Expanded(child: _JiraMappingCard(project: project)),
            ],
          ),
          const SizedBox(height: 24),
          _DirectivesCard(projectId: project.id),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _ProjectHeader extends ConsumerWidget {
  final Project project;

  const _ProjectHeader({required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoriteProjectIdsProvider);
    final isFavorite = favorites.contains(project.id);
    final healthScore = project.healthScore;
    final healthColor = _healthColor(healthScore);
    final isArchived = project.isArchived == true;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Health gauge.
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: healthColor, width: 3),
          ),
          alignment: Alignment.center,
          child: Text(
            healthScore != null ? '$healthScore' : '—',
            style: TextStyle(
              color: healthColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Title + subtitle.
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    project.name,
                    style: const TextStyle(
                      color: CodeOpsColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 22,
                    ),
                  ),
                  if (isArchived) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color:
                            CodeOpsColors.textTertiary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Archived',
                        style: TextStyle(
                          color: CodeOpsColors.textTertiary,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (project.repoFullName != null)
                Text(
                  project.repoFullName!,
                  style: const TextStyle(
                    color: CodeOpsColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              const SizedBox(height: 4),
              Row(
                children: [
                  if (project.techStack != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: CodeOpsColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        project.techStack!,
                        style: const TextStyle(
                          color: CodeOpsColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Text(
                    'Last audit: ${formatTimeAgo(project.lastAuditAt)}',
                    style: const TextStyle(
                      color: CodeOpsColors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Actions.
        IconButton(
          icon: Icon(
            isFavorite ? Icons.star : Icons.star_border,
            color: isFavorite ? CodeOpsColors.warning : CodeOpsColors.textTertiary,
          ),
          tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
          onPressed: () => ref
              .read(favoriteProjectIdsProvider.notifier)
              .toggle(project.id),
        ),
        const SizedBox(width: 4),
        _ActionButton(
          icon: Icons.settings,
          label: 'Settings',
          onPressed: () => _showSettingsDialog(context, ref),
        ),
        const SizedBox(width: 4),
        _ActionButton(
          icon: isArchived ? Icons.unarchive : Icons.archive,
          label: isArchived ? 'Unarchive' : 'Archive',
          onPressed: () => _handleArchive(context, ref),
        ),
        const SizedBox(width: 4),
        _ActionButton(
          icon: Icons.delete_outline,
          label: 'Delete',
          color: CodeOpsColors.error,
          onPressed: () => _handleDelete(context, ref),
        ),
      ],
    );
  }

  Future<void> _handleArchive(BuildContext context, WidgetRef ref) async {
    final isArchived = project.isArchived == true;
    final confirmed = await showConfirmDialog(
      context,
      title: isArchived ? 'Unarchive Project' : 'Archive Project',
      message: isArchived
          ? 'This will restore "${project.name}" to active projects.'
          : 'This will archive "${project.name}". It can be restored later.',
      confirmLabel: isArchived ? 'Unarchive' : 'Archive',
    );
    if (confirmed != true) return;

    try {
      final projectApi = ref.read(projectApiProvider);
      if (isArchived) {
        await projectApi.unarchiveProject(project.id);
      } else {
        await projectApi.archiveProject(project.id);
      }
      ref.invalidate(projectProvider(project.id));
      ref.invalidate(teamProjectsProvider);
      if (context.mounted) {
        showToast(
          context,
          message: isArchived
              ? '"${project.name}" unarchived'
              : '"${project.name}" archived',
          type: ToastType.success,
        );
      }
    } catch (e) {
      if (context.mounted) {
        showToast(context, message: 'Failed: $e', type: ToastType.error);
      }
    }
  }

  Future<void> _handleDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete Project',
      message:
          'This will permanently delete "${project.name}" and all its data. This action cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (confirmed != true) return;

    try {
      final projectApi = ref.read(projectApiProvider);
      await projectApi.deleteProject(project.id);
      ref.invalidate(teamProjectsProvider);
      if (context.mounted) {
        showToast(context,
            message: '"${project.name}" deleted', type: ToastType.success);
        context.go('/projects');
      }
    } catch (e) {
      if (context.mounted) {
        showToast(context, message: 'Failed: $e', type: ToastType.error);
      }
    }
  }

  void _showSettingsDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => _SettingsDialog(project: project),
    );
  }
}

// ---------------------------------------------------------------------------
// Metrics cards
// ---------------------------------------------------------------------------

class _MetricsCards extends ConsumerWidget {
  final String projectId;

  const _MetricsCards({required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(projectMetricsProvider(projectId));

    return metricsAsync.when(
      loading: () => const SizedBox(
        height: 80,
        child: Center(
          child: CircularProgressIndicator(color: CodeOpsColors.primary),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (metrics) {
        if (metrics == null) return const SizedBox.shrink();
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _MetricCard(
              label: 'Total Jobs',
              value: '${metrics.totalJobs ?? 0}',
              icon: Icons.work_outline,
            ),
            _MetricCard(
              label: 'Total Findings',
              value: '${metrics.totalFindings ?? 0}',
              icon: Icons.bug_report_outlined,
            ),
            _MetricCard(
              label: 'Open Critical',
              value: '${metrics.openCritical ?? 0}',
              icon: Icons.error_outline,
              color: CodeOpsColors.critical,
            ),
            _MetricCard(
              label: 'Open High',
              value: '${metrics.openHigh ?? 0}',
              icon: Icons.warning_amber,
              color: CodeOpsColors.error,
            ),
            _MetricCard(
              label: 'Tech Debt Items',
              value: '${metrics.techDebtItemCount ?? 0}',
              icon: Icons.account_balance_outlined,
            ),
            _MetricCard(
              label: 'Vulnerabilities',
              value: '${metrics.openVulnerabilities ?? 0}',
              icon: Icons.shield_outlined,
              color: CodeOpsColors.warning,
            ),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? CodeOpsColors.textSecondary;
    return Container(
      width: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CodeOpsColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CodeOpsColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: c),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: CodeOpsColors.textTertiary,
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: c,
              fontWeight: FontWeight.w700,
              fontSize: 22,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Health trend chart
// ---------------------------------------------------------------------------

class _HealthTrendChart extends ConsumerWidget {
  final String projectId;

  const _HealthTrendChart({required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendAsync = ref.watch(projectHealthTrendProvider(projectId));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CodeOpsColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CodeOpsColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Health Trend',
            style: TextStyle(
              color: CodeOpsColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: trendAsync.when(
              loading: () => const Center(
                child:
                    CircularProgressIndicator(color: CodeOpsColors.primary),
              ),
              error: (_, __) => const Center(
                child: Text(
                  'Failed to load health trend',
                  style: TextStyle(color: CodeOpsColors.textTertiary),
                ),
              ),
              data: (snapshots) {
                if (snapshots.isEmpty) {
                  return const Center(
                    child: Text(
                      'No health data yet',
                      style: TextStyle(color: CodeOpsColors.textTertiary),
                    ),
                  );
                }
                return _buildChart(snapshots);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(List<HealthSnapshot> snapshots) {
    final spots = <FlSpot>[];
    for (var i = 0; i < snapshots.length; i++) {
      spots.add(FlSpot(i.toDouble(), snapshots[i].healthScore.toDouble()));
    }

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 100,
        gridData: FlGridData(
          show: true,
          horizontalInterval: 20,
          getDrawingHorizontalLine: (value) => FlLine(
            color: CodeOpsColors.border,
            strokeWidth: 0.5,
          ),
          getDrawingVerticalLine: (_) => const FlLine(strokeWidth: 0),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: 20,
              getTitlesWidget: (value, _) => Text(
                '${value.toInt()}',
                style: const TextStyle(
                  color: CodeOpsColors.textTertiary,
                  fontSize: 10,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: (snapshots.length / 5).ceilToDouble().clamp(1, 30),
              getTitlesWidget: (value, _) {
                final idx = value.toInt();
                if (idx < 0 || idx >= snapshots.length) {
                  return const SizedBox.shrink();
                }
                final dt = snapshots[idx].capturedAt;
                if (dt == null) return const SizedBox.shrink();
                return Text(
                  '${dt.month}/${dt.day}',
                  style: const TextStyle(
                    color: CodeOpsColors.textTertiary,
                    fontSize: 9,
                  ),
                );
              },
            ),
          ),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: CodeOpsColors.primary,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: CodeOpsColors.primary.withValues(alpha: 0.1),
            ),
          ),
        ],
        rangeAnnotations: RangeAnnotations(
          horizontalRangeAnnotations: [
            HorizontalRangeAnnotation(
              y1: 0,
              y2: AppConstants.healthScoreYellowThreshold.toDouble(),
              color: CodeOpsColors.error.withValues(alpha: 0.05),
            ),
            HorizontalRangeAnnotation(
              y1: AppConstants.healthScoreYellowThreshold.toDouble(),
              y2: AppConstants.healthScoreGreenThreshold.toDouble(),
              color: CodeOpsColors.warning.withValues(alpha: 0.05),
            ),
            HorizontalRangeAnnotation(
              y1: AppConstants.healthScoreGreenThreshold.toDouble(),
              y2: 100,
              color: CodeOpsColors.success.withValues(alpha: 0.05),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Recent jobs table
// ---------------------------------------------------------------------------

class _RecentJobsTable extends ConsumerWidget {
  final String projectId;

  const _RecentJobsTable({required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(projectRecentJobsProvider(projectId));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CodeOpsColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CodeOpsColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Jobs',
            style: TextStyle(
              color: CodeOpsColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          jobsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: CodeOpsColors.primary),
            ),
            error: (_, __) => const Text(
              'Failed to load jobs',
              style: TextStyle(color: CodeOpsColors.textTertiary),
            ),
            data: (page) {
              if (page.content.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'No jobs yet',
                      style: TextStyle(color: CodeOpsColors.textTertiary),
                    ),
                  ),
                );
              }
              return _buildTable(context, page.content);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTable(BuildContext context, List<JobSummary> jobs) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStatePropertyAll(
          CodeOpsColors.surfaceVariant.withValues(alpha: 0.5),
        ),
        columns: const [
          DataColumn(label: Text('Mode')),
          DataColumn(label: Text('Name')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Result')),
          DataColumn(label: Text('Health')),
          DataColumn(label: Text('Findings')),
          DataColumn(label: Text('Completed')),
        ],
        rows: jobs.map((job) {
          final statusColor =
              CodeOpsColors.jobStatusColors[job.status] ?? CodeOpsColors.textTertiary;
          final resultColor = switch (job.overallResult) {
            JobResult.pass => CodeOpsColors.success,
            JobResult.warn => CodeOpsColors.warning,
            JobResult.fail => CodeOpsColors.error,
            null => CodeOpsColors.textTertiary,
          };

          return DataRow(
            onSelectChanged: (_) => context.go('/jobs/${job.id}'),
            cells: [
              DataCell(_JobModeIcon(mode: job.mode)),
              DataCell(Text(
                job.name ?? job.mode.displayName,
                style: const TextStyle(color: CodeOpsColors.textPrimary),
              )),
              DataCell(Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  job.status.displayName,
                  style: TextStyle(color: statusColor, fontSize: 12),
                ),
              )),
              DataCell(Text(
                job.overallResult?.displayName ?? '—',
                style: TextStyle(color: resultColor, fontSize: 13),
              )),
              DataCell(Text(
                job.healthScore != null ? '${job.healthScore}' : '—',
                style: const TextStyle(color: CodeOpsColors.textPrimary),
              )),
              DataCell(Text(
                '${job.totalFindings ?? 0}',
                style: const TextStyle(color: CodeOpsColors.textPrimary),
              )),
              DataCell(Text(
                formatTimeAgo(job.completedAt),
                style: const TextStyle(
                  color: CodeOpsColors.textTertiary,
                  fontSize: 12,
                ),
              )),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _JobModeIcon extends StatelessWidget {
  final JobMode mode;

  const _JobModeIcon({required this.mode});

  @override
  Widget build(BuildContext context) {
    final icon = switch (mode) {
      JobMode.audit => Icons.policy_outlined,
      JobMode.compliance => Icons.verified_outlined,
      JobMode.bugInvestigate => Icons.bug_report_outlined,
      JobMode.remediate => Icons.build_outlined,
      JobMode.techDebt => Icons.account_balance_outlined,
      JobMode.dependency => Icons.inventory_2_outlined,
      JobMode.healthMonitor => Icons.monitor_heart_outlined,
    };

    return Icon(icon, size: 18, color: CodeOpsColors.textSecondary);
  }
}

// ---------------------------------------------------------------------------
// Repository info card
// ---------------------------------------------------------------------------

class _RepositoryInfoCard extends StatelessWidget {
  final Project project;

  const _RepositoryInfoCard({required this.project});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CodeOpsColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CodeOpsColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.code, size: 18, color: CodeOpsColors.textSecondary),
              SizedBox(width: 8),
              Text(
                'Repository',
                style: TextStyle(
                  color: CodeOpsColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InfoRow(label: 'URL', value: project.repoUrl ?? '—'),
          _InfoRow(
              label: 'Full Name', value: project.repoFullName ?? '—'),
          _InfoRow(
              label: 'Default Branch', value: project.defaultBranch ?? '—'),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Jira mapping card
// ---------------------------------------------------------------------------

class _JiraMappingCard extends StatelessWidget {
  final Project project;

  const _JiraMappingCard({required this.project});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CodeOpsColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CodeOpsColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.integration_instructions,
                  size: 18, color: CodeOpsColors.textSecondary),
              SizedBox(width: 8),
              Text(
                'Jira Mapping',
                style: TextStyle(
                  color: CodeOpsColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InfoRow(
              label: 'Project Key', value: project.jiraProjectKey ?? '—'),
          _InfoRow(
            label: 'Default Issue Type',
            value: project.jiraDefaultIssueType ?? '—',
          ),
          _InfoRow(
            label: 'Labels',
            value: project.jiraLabels?.join(', ') ?? '—',
          ),
          _InfoRow(
              label: 'Component', value: project.jiraComponent ?? '—'),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Directives card
// ---------------------------------------------------------------------------

class _DirectivesCard extends ConsumerWidget {
  final String projectId;

  const _DirectivesCard({required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final directivesAsync = ref.watch(projectDirectivesProvider(projectId));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CodeOpsColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CodeOpsColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.rule,
                  size: 18, color: CodeOpsColors.textSecondary),
              const SizedBox(width: 8),
              const Text(
                'Directives',
                style: TextStyle(
                  color: CodeOpsColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.go('/directives'),
                child: const Text(
                  'Manage Directives',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          directivesAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: CodeOpsColors.primary),
            ),
            error: (_, __) => const Text(
              'Failed to load directives',
              style: TextStyle(color: CodeOpsColors.textTertiary),
            ),
            data: (directives) {
              if (directives.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      'No directives assigned',
                      style: TextStyle(color: CodeOpsColors.textTertiary),
                    ),
                  ),
                );
              }
              return Column(
                children: directives
                    .map((d) => _DirectiveRow(
                          directive: d,
                          projectId: projectId,
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DirectiveRow extends ConsumerWidget {
  final ProjectDirective directive;
  final String projectId;

  const _DirectiveRow({required this.directive, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              directive.directiveName ?? directive.directiveId,
              style: const TextStyle(
                color: CodeOpsColors.textPrimary,
                fontSize: 13,
              ),
            ),
          ),
          if (directive.category != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: CodeOpsColors.surfaceVariant,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                directive.category!.displayName,
                style: const TextStyle(
                  color: CodeOpsColors.textTertiary,
                  fontSize: 10,
                ),
              ),
            ),
          const SizedBox(width: 8),
          Switch(
            value: directive.enabled ?? false,
            activeThumbColor: CodeOpsColors.primary,
            onChanged: (value) async {
              try {
                final directiveApi = ref.read(directiveApiProvider);
                await directiveApi.toggleDirective(
                    projectId, directive.directiveId, !(directive.enabled ?? false));
                ref.invalidate(projectDirectivesProvider(projectId));
              } catch (e) {
                if (context.mounted) {
                  showToast(context,
                      message: 'Failed to toggle directive',
                      type: ToastType.error);
                }
              }
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Info row helper
// ---------------------------------------------------------------------------

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: CodeOpsColors.textTertiary,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: CodeOpsColors.textPrimary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Action button helper
// ---------------------------------------------------------------------------

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? CodeOpsColors.textSecondary;
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16, color: c),
      label: Text(label, style: TextStyle(color: c, fontSize: 12)),
    );
  }
}

// ---------------------------------------------------------------------------
// Settings dialog
// ---------------------------------------------------------------------------

class _SettingsDialog extends ConsumerStatefulWidget {
  final Project project;

  const _SettingsDialog({required this.project});

  @override
  ConsumerState<_SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends ConsumerState<_SettingsDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _repoUrlController;
  late final TextEditingController _repoFullNameController;
  late final TextEditingController _defaultBranchController;
  late final TextEditingController _jiraProjectKeyController;
  late final TextEditingController _techStackController;
  String? _selectedGitHubConnectionId;
  String? _selectedJiraConnectionId;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.project.name);
    _descriptionController =
        TextEditingController(text: widget.project.description ?? '');
    _repoUrlController =
        TextEditingController(text: widget.project.repoUrl ?? '');
    _repoFullNameController =
        TextEditingController(text: widget.project.repoFullName ?? '');
    _defaultBranchController =
        TextEditingController(text: widget.project.defaultBranch ?? '');
    _jiraProjectKeyController =
        TextEditingController(text: widget.project.jiraProjectKey ?? '');
    _techStackController =
        TextEditingController(text: widget.project.techStack ?? '');
    _selectedGitHubConnectionId = widget.project.githubConnectionId;
    _selectedJiraConnectionId = widget.project.jiraConnectionId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _repoUrlController.dispose();
    _repoFullNameController.dispose();
    _defaultBranchController.dispose();
    _jiraProjectKeyController.dispose();
    _techStackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final githubConnectionsAsync = ref.watch(githubConnectionsProvider);
    final jiraConnectionsAsync = ref.watch(jiraConnectionsProvider);

    return AlertDialog(
      backgroundColor: CodeOpsColors.surface,
      title: const Text('Project Settings'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _techStackController,
                decoration: const InputDecoration(labelText: 'Tech Stack'),
              ),
              const SizedBox(height: 12),
              githubConnectionsAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const SizedBox.shrink(),
                data: (connections) => DropdownButtonFormField<String>(
                  initialValue: _selectedGitHubConnectionId,
                  decoration:
                      const InputDecoration(labelText: 'GitHub Connection'),
                  dropdownColor: CodeOpsColors.surfaceVariant,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('None')),
                    ...connections.map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name),
                        )),
                  ],
                  onChanged: (v) =>
                      setState(() => _selectedGitHubConnectionId = v),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _repoUrlController,
                decoration: const InputDecoration(labelText: 'Repo URL'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _repoFullNameController,
                decoration:
                    const InputDecoration(labelText: 'Repo Full Name'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _defaultBranchController,
                decoration:
                    const InputDecoration(labelText: 'Default Branch'),
              ),
              const SizedBox(height: 12),
              jiraConnectionsAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const SizedBox.shrink(),
                data: (connections) => DropdownButtonFormField<String>(
                  initialValue: _selectedJiraConnectionId,
                  decoration:
                      const InputDecoration(labelText: 'Jira Connection'),
                  dropdownColor: CodeOpsColors.surfaceVariant,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('None')),
                    ...connections.map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name),
                        )),
                  ],
                  onChanged: (v) =>
                      setState(() => _selectedJiraConnectionId = v),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _jiraProjectKeyController,
                decoration:
                    const InputDecoration(labelText: 'Jira Project Key'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel',
              style: TextStyle(color: CodeOpsColors.textSecondary)),
        ),
        FilledButton(
          onPressed: _submitting ? null : _save,
          child: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    setState(() => _submitting = true);

    try {
      final projectApi = ref.read(projectApiProvider);
      await projectApi.updateProject(
        widget.project.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        githubConnectionId: _selectedGitHubConnectionId,
        repoUrl: _repoUrlController.text.trim().isEmpty
            ? null
            : _repoUrlController.text.trim(),
        repoFullName: _repoFullNameController.text.trim().isEmpty
            ? null
            : _repoFullNameController.text.trim(),
        defaultBranch: _defaultBranchController.text.trim().isEmpty
            ? null
            : _defaultBranchController.text.trim(),
        jiraConnectionId: _selectedJiraConnectionId,
        jiraProjectKey: _jiraProjectKeyController.text.trim().isEmpty
            ? null
            : _jiraProjectKeyController.text.trim(),
        techStack: _techStackController.text.trim().isEmpty
            ? null
            : _techStackController.text.trim(),
      );

      ref.invalidate(projectProvider(widget.project.id));
      ref.invalidate(teamProjectsProvider);

      if (mounted) {
        Navigator.of(context).pop();
        showToast(context,
            message: 'Project updated', type: ToastType.success);
      }
    } catch (e) {
      setState(() => _submitting = false);
      if (mounted) {
        showToast(context, message: 'Failed: $e', type: ToastType.error);
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Shared helpers
// ---------------------------------------------------------------------------

Color _healthColor(int? score) {
  if (score == null) return CodeOpsColors.textTertiary;
  if (score >= AppConstants.healthScoreGreenThreshold) {
    return CodeOpsColors.success;
  }
  if (score >= AppConstants.healthScoreYellowThreshold) {
    return CodeOpsColors.warning;
  }
  return CodeOpsColors.error;
}
