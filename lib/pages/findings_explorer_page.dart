/// Findings Explorer page.
///
/// Master-detail split layout with filter bar, bulk actions toolbar,
/// paginated findings table, and detail side panel.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/enums.dart';
import '../models/finding.dart';
import '../providers/finding_providers.dart';
import '../providers/job_providers.dart'
    hide findingApiProvider, jobFindingsProvider;
import '../theme/colors.dart';
import '../widgets/findings/finding_detail_panel.dart';
import '../widgets/findings/finding_status_actions.dart';
import '../widgets/findings/findings_table.dart';
import '../widgets/findings/severity_filter_bar.dart';
import '../widgets/shared/empty_state.dart';
import '../widgets/shared/error_panel.dart';
import '../widgets/shared/loading_overlay.dart';

/// Findings Explorer with master-detail layout.
class FindingsExplorerPage extends ConsumerStatefulWidget {
  /// The job UUID extracted from the route.
  final String jobId;

  /// Creates a [FindingsExplorerPage].
  const FindingsExplorerPage({super.key, required this.jobId});

  @override
  ConsumerState<FindingsExplorerPage> createState() =>
      _FindingsExplorerPageState();
}

class _FindingsExplorerPageState extends ConsumerState<FindingsExplorerPage> {
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final jobAsync = ref.watch(jobDetailProvider(widget.jobId));
    final findingsAsync = ref.watch(
        jobFindingsProvider((jobId: widget.jobId, page: _currentPage)));
    final countsAsync =
        ref.watch(findingSeverityCountsProvider(widget.jobId));
    final selectedIds = ref.watch(selectedFindingIdsProvider);
    final activeFinding = ref.watch(activeFindingProvider);
    final filters = ref.watch(findingFiltersProvider);
    final findingApi = ref.watch(findingApiProvider);

    return Column(
      children: [
        // Header bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: CodeOpsColors.divider),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back,
                    size: 18, color: CodeOpsColors.textSecondary),
                onPressed: () =>
                    context.go('/jobs/${widget.jobId}/report'),
                tooltip: 'Back to report',
              ),
              const SizedBox(width: 8),
              Expanded(
                child: jobAsync.when(
                  loading: () => const Text(
                    'Findings',
                    style: TextStyle(
                      color: CodeOpsColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  error: (_, __) => const Text(
                    'Findings',
                    style: TextStyle(
                      color: CodeOpsColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  data: (job) => Text(
                    'Findings: ${job.name ?? job.mode.displayName}',
                    style: const TextStyle(
                      color: CodeOpsColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () =>
                    context.go('/jobs/${widget.jobId}/report'),
                icon: const Icon(Icons.description, size: 14),
                label: const Text('View Report'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: CodeOpsColors.textSecondary,
                  side: const BorderSide(color: CodeOpsColors.border),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),

        // Filter bar
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          child: SeverityFilterBar(
            severityCounts: _parseSeverityCounts(countsAsync.valueOrNull),
          ),
        ),

        // Bulk actions toolbar
        if (selectedIds.isNotEmpty)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            color: CodeOpsColors.primary.withValues(alpha: 0.08),
            child: Row(
              children: [
                Text(
                  '${selectedIds.length} selected',
                  style: const TextStyle(
                    color: CodeOpsColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 12),
                FindingStatusActions(
                  selectedIds: selectedIds,
                  findingApi: findingApi,
                  jobId: widget.jobId,
                  onStatusChanged: () {
                    ref.invalidate(jobFindingsProvider);
                    ref.invalidate(
                        findingSeverityCountsProvider(widget.jobId));
                  },
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => ref
                      .read(selectedFindingIdsProvider.notifier)
                      .state = {},
                  child: const Text('Clear selection'),
                ),
              ],
            ),
          ),

        // Main content: table + optional detail panel
        Expanded(
          child: findingsAsync.when(
            loading: () =>
                const LoadingOverlay(message: 'Loading findings...'),
            error: (e, _) => ErrorPanel.fromException(e,
                onRetry: () => ref.invalidate(jobFindingsProvider)),
            data: (pageResponse) {
              if (pageResponse.content.isEmpty) {
                return const EmptyState(
                  icon: Icons.check_circle_outline,
                  title: 'No findings',
                  subtitle: 'No findings match the current filters.',
                );
              }

              final filteredFindings =
                  _applyLocalFilters(pageResponse.content, filters);

              return Row(
                children: [
                  // Findings table
                  Expanded(
                    child: FindingsTable(
                      findings: filteredFindings,
                      currentPage: _currentPage,
                      totalPages: pageResponse.totalPages,
                      onPageChanged: (page) =>
                          setState(() => _currentPage = page),
                      onFindingTap: (finding) {
                        ref
                            .read(activeFindingProvider.notifier)
                            .state = finding;
                      },
                    ),
                  ),

                  // Detail panel
                  if (activeFinding != null)
                    FindingDetailPanel(
                      finding: activeFinding,
                      findingApi: findingApi,
                      jobId: widget.jobId,
                      onClose: () => ref
                          .read(activeFindingProvider.notifier)
                          .state = null,
                      onStatusChanged: () {
                        ref.invalidate(jobFindingsProvider);
                        ref.invalidate(findingSeverityCountsProvider(
                            widget.jobId));
                      },
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Map<Severity, int> _parseSeverityCounts(
      Map<String, dynamic>? countsJson) {
    if (countsJson == null) return {};
    final result = <Severity, int>{};
    for (final severity in Severity.values) {
      final key = severity.toJson();
      if (countsJson.containsKey(key)) {
        result[severity] = (countsJson[key] as num?)?.toInt() ?? 0;
      }
    }
    return result;
  }

  List<Finding> _applyLocalFilters(
      List<Finding> findings, FindingFilters filters) {
    var result = findings;
    if (filters.severity != null) {
      result = result
          .where((f) => f.severity == filters.severity)
          .toList();
    }
    if (filters.status != null) {
      result =
          result.where((f) => f.status == filters.status).toList();
    }
    if (filters.agentType != null) {
      result = result
          .where((f) => f.agentType == filters.agentType)
          .toList();
    }
    if (filters.searchQuery.isNotEmpty) {
      final query = filters.searchQuery.toLowerCase();
      result = result
          .where((f) =>
              f.title.toLowerCase().contains(query) ||
              (f.filePath?.toLowerCase().contains(query) ?? false) ||
              (f.description?.toLowerCase().contains(query) ?? false))
          .toList();
    }
    return result;
  }
}
