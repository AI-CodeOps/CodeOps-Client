/// Job History page.
///
/// Lists all past and current jobs with filtering by mode, status,
/// project, date range, and search. Table shows status dot, name,
/// project, mode badge, result badge, health score, findings,
/// duration, and date. Click navigates to `/jobs/{id}`.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/enums.dart';
import '../models/qa_job.dart';
import '../providers/wizard_providers.dart';
import '../theme/colors.dart';
import '../utils/date_utils.dart';
import '../widgets/shared/empty_state.dart';
import '../widgets/shared/error_panel.dart';
import '../widgets/shared/search_bar.dart';

/// Displays a filterable list of all job history.
class JobHistoryPage extends ConsumerStatefulWidget {
  /// Creates a [JobHistoryPage].
  const JobHistoryPage({super.key});

  @override
  ConsumerState<JobHistoryPage> createState() => _JobHistoryPageState();
}

class _JobHistoryPageState extends ConsumerState<JobHistoryPage> {
  String _sortColumn = 'date';
  bool _sortAscending = false;

  @override
  Widget build(BuildContext context) {
    final filteredAsync = ref.watch(filteredJobHistoryProvider);
    final filters = ref.watch(jobHistoryFiltersProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Text(
                'Job History',
                style: TextStyle(
                  color: CodeOpsColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => context.go('/audit'),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('New Audit'),
                style: FilledButton.styleFrom(
                  backgroundColor: CodeOpsColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Filter bar
          _FilterBar(
            filters: filters,
            onFiltersChanged: (f) =>
                ref.read(jobHistoryFiltersProvider.notifier).state = f,
          ),
          const SizedBox(height: 16),

          // Table
          Expanded(
            child: filteredAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorPanel.fromException(e,
                  onRetry: () =>
                      ref.invalidate(jobHistoryProvider)),
              data: (jobs) {
                if (jobs.isEmpty) {
                  return EmptyState(
                    icon: Icons.history,
                    title: filters.hasActiveFilters
                        ? 'No jobs match filters'
                        : 'No jobs yet',
                    subtitle: filters.hasActiveFilters
                        ? 'Try adjusting your filters.'
                        : 'Run your first audit to see results here.',
                    actionLabel:
                        filters.hasActiveFilters ? null : 'Run Audit',
                    onAction: filters.hasActiveFilters
                        ? null
                        : () => context.go('/audit'),
                  );
                }

                final sorted = _sortJobs(jobs);

                return _JobTable(
                  jobs: sorted,
                  sortColumn: _sortColumn,
                  sortAscending: _sortAscending,
                  onSort: (column) {
                    setState(() {
                      if (_sortColumn == column) {
                        _sortAscending = !_sortAscending;
                      } else {
                        _sortColumn = column;
                        _sortAscending = false;
                      }
                    });
                  },
                  onJobTap: (job) => context.go('/jobs/${job.id}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<JobSummary> _sortJobs(List<JobSummary> jobs) {
    final sorted = List<JobSummary>.from(jobs);
    sorted.sort((a, b) {
      final cmp = switch (_sortColumn) {
        'date' => (a.createdAt ?? DateTime(2000))
            .compareTo(b.createdAt ?? DateTime(2000)),
        'health' =>
          (a.healthScore ?? 0).compareTo(b.healthScore ?? 0),
        'findings' =>
          (a.totalFindings ?? 0).compareTo(b.totalFindings ?? 0),
        _ => 0,
      };
      return _sortAscending ? cmp : -cmp;
    });
    return sorted;
  }
}

class _FilterBar extends StatelessWidget {
  final JobHistoryFilters filters;
  final ValueChanged<JobHistoryFilters> onFiltersChanged;

  const _FilterBar({
    required this.filters,
    required this.onFiltersChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Search
        SizedBox(
          width: 220,
          child: CodeOpsSearchBar(
            hint: 'Search jobs...',
            onChanged: (q) =>
                onFiltersChanged(filters.copyWith(searchQuery: q)),
          ),
        ),

        // Mode filter
        _FilterChipDropdown<JobMode>(
          label: 'Mode',
          value: filters.mode,
          items: JobMode.values,
          itemLabel: (m) => m.displayName,
          onChanged: (v) => onFiltersChanged(
              v == null
                  ? filters.copyWith(clearMode: true)
                  : filters.copyWith(mode: v)),
        ),

        // Status filter
        _FilterChipDropdown<JobStatus>(
          label: 'Status',
          value: filters.status,
          items: JobStatus.values,
          itemLabel: (s) => s.displayName,
          onChanged: (v) => onFiltersChanged(
              v == null
                  ? filters.copyWith(clearStatus: true)
                  : filters.copyWith(status: v)),
        ),

        // Result filter
        _FilterChipDropdown<JobResult>(
          label: 'Result',
          value: filters.result,
          items: JobResult.values,
          itemLabel: (r) => r.displayName,
          onChanged: (v) => onFiltersChanged(
              v == null
                  ? filters.copyWith(clearResult: true)
                  : filters.copyWith(result: v)),
        ),

        // Clear all
        if (filters.hasActiveFilters)
          TextButton(
            onPressed: () =>
                onFiltersChanged(const JobHistoryFilters()),
            child: const Text('Clear filters'),
          ),
      ],
    );
  }
}

class _FilterChipDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T?> onChanged;

  const _FilterChipDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T?>(
      tooltip: label,
      offset: const Offset(0, 36),
      color: CodeOpsColors.surface,
      onSelected: onChanged,
      itemBuilder: (_) => [
        PopupMenuItem<T?>(
          value: null,
          child: Text('All',
              style: TextStyle(
                color: value == null
                    ? CodeOpsColors.primary
                    : CodeOpsColors.textPrimary,
                fontSize: 13,
              )),
        ),
        ...items.map((item) => PopupMenuItem<T?>(
              value: item,
              child: Text(
                itemLabel(item),
                style: TextStyle(
                  color: value == item
                      ? CodeOpsColors.primary
                      : CodeOpsColors.textPrimary,
                  fontSize: 13,
                ),
              ),
            )),
      ],
      child: Chip(
        label: Text(
          value != null ? itemLabel(value as T) : label,
          style: TextStyle(
            color: value != null
                ? CodeOpsColors.primary
                : CodeOpsColors.textSecondary,
            fontSize: 12,
          ),
        ),
        backgroundColor: value != null
            ? CodeOpsColors.primary.withValues(alpha: 0.08)
            : CodeOpsColors.surfaceVariant,
        side: BorderSide(
          color: value != null
              ? CodeOpsColors.primary.withValues(alpha: 0.3)
              : CodeOpsColors.border,
        ),
        deleteIcon: value != null
            ? const Icon(Icons.close, size: 14)
            : null,
        onDeleted:
            value != null ? () => onChanged(null) : null,
      ),
    );
  }
}

class _JobTable extends StatelessWidget {
  final List<JobSummary> jobs;
  final String sortColumn;
  final bool sortAscending;
  final ValueChanged<String> onSort;
  final ValueChanged<JobSummary> onJobTap;

  const _JobTable({
    required this.jobs,
    required this.sortColumn,
    required this.sortAscending,
    required this.onSort,
    required this.onJobTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Table header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: const BoxDecoration(
            color: CodeOpsColors.surface,
            border: Border(
              bottom: BorderSide(color: CodeOpsColors.border),
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 24), // Status dot space
              const Expanded(flex: 3, child: _HeaderCell(label: 'Name')),
              const Expanded(flex: 2, child: _HeaderCell(label: 'Project')),
              const Expanded(child: _HeaderCell(label: 'Mode')),
              const Expanded(child: _HeaderCell(label: 'Result')),
              _SortableHeader(
                label: 'Health',
                column: 'health',
                currentSort: sortColumn,
                ascending: sortAscending,
                onSort: onSort,
              ),
              _SortableHeader(
                label: 'Findings',
                column: 'findings',
                currentSort: sortColumn,
                ascending: sortAscending,
                onSort: onSort,
              ),
              _SortableHeader(
                label: 'Date',
                column: 'date',
                currentSort: sortColumn,
                ascending: sortAscending,
                onSort: onSort,
              ),
            ],
          ),
        ),

        // Table body
        Expanded(
          child: ListView.separated(
            itemCount: jobs.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: CodeOpsColors.divider),
            itemBuilder: (context, index) {
              final job = jobs[index];
              return _JobRow(
                job: job,
                onTap: () => onJobTap(job),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String label;

  const _HeaderCell({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: CodeOpsColors.textTertiary,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _SortableHeader extends StatelessWidget {
  final String label;
  final String column;
  final String currentSort;
  final bool ascending;
  final ValueChanged<String> onSort;

  const _SortableHeader({
    required this.label,
    required this.column,
    required this.currentSort,
    required this.ascending,
    required this.onSort,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = currentSort == column;
    return Expanded(
      child: InkWell(
        onTap: () => onSort(column),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isActive
                    ? CodeOpsColors.primary
                    : CodeOpsColors.textTertiary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (isActive)
              Icon(
                ascending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 12,
                color: CodeOpsColors.primary,
              ),
          ],
        ),
      ),
    );
  }
}

class _JobRow extends StatelessWidget {
  final JobSummary job;
  final VoidCallback onTap;

  const _JobRow({required this.job, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor =
        CodeOpsColors.jobStatusColors[job.status] ?? CodeOpsColors.textTertiary;

    final resultColor = switch (job.overallResult) {
      JobResult.pass => CodeOpsColors.success,
      JobResult.warn => CodeOpsColors.warning,
      JobResult.fail => CodeOpsColors.error,
      null => CodeOpsColors.textTertiary,
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Status dot
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor,
                ),
              ),

              // Name
              Expanded(
                flex: 3,
                child: Text(
                  job.name ?? 'Job ${job.id.substring(0, 8)}',
                  style: const TextStyle(
                    color: CodeOpsColors.textPrimary,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Project
              Expanded(
                flex: 2,
                child: Text(
                  job.projectName ?? '\u2014',
                  style: const TextStyle(
                    color: CodeOpsColors.textSecondary,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Mode badge
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: CodeOpsColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    job.mode.displayName,
                    style: const TextStyle(
                      color: CodeOpsColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

              // Result badge
              Expanded(
                child: job.overallResult != null
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: resultColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          job.overallResult!.displayName,
                          style: TextStyle(
                            color: resultColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : Text(
                        '\u2014',
                        style: TextStyle(
                          color: CodeOpsColors.textTertiary,
                          fontSize: 12,
                        ),
                      ),
              ),

              // Health score
              Expanded(
                child: Text(
                  job.healthScore?.toString() ?? '\u2014',
                  style: TextStyle(
                    color: job.healthScore != null
                        ? _healthColor(job.healthScore!)
                        : CodeOpsColors.textTertiary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              // Findings count
              Expanded(
                child: Text(
                  job.totalFindings?.toString() ?? '\u2014',
                  style: const TextStyle(
                    color: CodeOpsColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),

              // Date
              Expanded(
                child: Text(
                  formatTimeAgo(job.createdAt),
                  style: const TextStyle(
                    color: CodeOpsColors.textTertiary,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _healthColor(int score) {
    if (score >= 80) return CodeOpsColors.success;
    if (score >= 60) return CodeOpsColors.warning;
    return CodeOpsColors.error;
  }
}
