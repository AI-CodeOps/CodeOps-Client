/// Trace viewer page — list, search, and filter distributed traces.
///
/// **Layout:** Logger sidebar + main content area with a toolbar, optional
/// search/filter bar, and a paginated [DataTable] of traces. Tapping a
/// trace row navigates to the trace detail page.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/health_snapshot.dart';
import '../../models/logger_models.dart';
import '../../providers/logger_providers.dart';
import '../../providers/team_providers.dart' show selectedTeamIdProvider;
import '../../theme/colors.dart';
import '../../widgets/logger/logger_sidebar.dart';
import '../../widgets/shared/empty_state.dart';
import '../../widgets/shared/error_panel.dart';

/// The trace viewer page.
class TraceViewerPage extends ConsumerStatefulWidget {
  /// Creates a [TraceViewerPage].
  const TraceViewerPage({super.key});

  @override
  ConsumerState<TraceViewerPage> createState() => _TraceViewerPageState();
}

class _TraceViewerPageState extends ConsumerState<TraceViewerPage> {
  String _searchQuery = '';
  bool _errorsOnly = false;

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
              subtitle: 'Select a team to view traces.',
            ),
          ),
        ],
      );
    }

    final tracesAsync = ref.watch(loggerTracesProvider);

    return Row(
      children: [
        const LoggerSidebar(),
        const VerticalDivider(width: 1, color: CodeOpsColors.border),
        Expanded(
          child: Column(
            children: [
              _buildToolbar(),
              _buildFilterBar(),
              Expanded(
                child: tracesAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, _) => ErrorPanel(
                    title: 'Failed to load traces',
                    message: err.toString(),
                  ),
                  data: (pageResponse) =>
                      _buildTraceTable(pageResponse),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Top toolbar.
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
            Icons.account_tree_outlined,
            color: CodeOpsColors.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          const Text(
            'Trace Viewer',
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
            onPressed: () => ref.invalidate(loggerTracesProvider),
          ),
        ],
      ),
    );
  }

  /// Search and filter bar.
  Widget _buildFilterBar() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: CodeOpsColors.border)),
      ),
      child: Row(
        children: [
          // Search field.
          SizedBox(
            width: 260,
            child: TextField(
              style: const TextStyle(
                  fontSize: 12, color: CodeOpsColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Search by service or operation...',
                hintStyle: TextStyle(
                    color: CodeOpsColors.textTertiary, fontSize: 12),
                prefixIcon:
                    Icon(Icons.search, size: 16, color: CodeOpsColors.textTertiary),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          const SizedBox(width: 16),
          // Errors only toggle.
          FilterChip(
            label: const Text('Errors Only'),
            selected: _errorsOnly,
            onSelected: (v) => setState(() => _errorsOnly = v),
            labelStyle: TextStyle(
              fontSize: 11,
              color: _errorsOnly
                  ? CodeOpsColors.textPrimary
                  : CodeOpsColors.textSecondary,
            ),
            backgroundColor: CodeOpsColors.surface,
            selectedColor: CodeOpsColors.error.withValues(alpha: 0.2),
            side: const BorderSide(color: CodeOpsColors.border),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  /// Data table of traces with pagination.
  Widget _buildTraceTable(PageResponse<TraceListResponse> pageResponse) {
    var traces = pageResponse.content;

    // Apply client-side filters.
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      traces = traces
          .where((t) =>
              t.rootService.toLowerCase().contains(q) ||
              t.rootOperation.toLowerCase().contains(q) ||
              t.correlationId.toLowerCase().contains(q))
          .toList();
    }
    if (_errorsOnly) {
      traces = traces.where((t) => t.hasErrors).toList();
    }

    if (traces.isEmpty) {
      return const EmptyState(
        icon: Icons.account_tree_outlined,
        title: 'No traces found',
        subtitle: 'Traces will appear here once your services emit spans.',
      );
    }

    final page = ref.watch(loggerTracePageProvider);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: DataTable(
              headingRowHeight: 36,
              dataRowMinHeight: 36,
              dataRowMaxHeight: 36,
              columnSpacing: 24,
              showCheckboxColumn: false,
              columns: const [
                DataColumn(
                  label: Text(
                    'Service',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: CodeOpsColors.textSecondary,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Operation',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: CodeOpsColors.textSecondary,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Duration',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: CodeOpsColors.textSecondary,
                    ),
                  ),
                  numeric: true,
                ),
                DataColumn(
                  label: Text(
                    'Spans',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: CodeOpsColors.textSecondary,
                    ),
                  ),
                  numeric: true,
                ),
                DataColumn(
                  label: Text(
                    'Services',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: CodeOpsColors.textSecondary,
                    ),
                  ),
                  numeric: true,
                ),
                DataColumn(
                  label: Text(
                    'Status',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: CodeOpsColors.textSecondary,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Time',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: CodeOpsColors.textSecondary,
                    ),
                  ),
                ),
              ],
              rows: traces.map((t) {
                return DataRow(
                  onSelectChanged: (_) {
                    context.go('/logger/traces/${t.correlationId}');
                  },
                  cells: [
                    DataCell(Text(
                      t.rootService,
                      style: const TextStyle(
                        fontSize: 11,
                        color: CodeOpsColors.textPrimary,
                      ),
                    )),
                    DataCell(Text(
                      t.rootOperation,
                      style: const TextStyle(
                        fontSize: 11,
                        color: CodeOpsColors.textPrimary,
                      ),
                    )),
                    DataCell(Text(
                      _formatDuration(t.totalDurationMs),
                      style: const TextStyle(
                        fontSize: 11,
                        color: CodeOpsColors.textPrimary,
                        fontFamily: 'monospace',
                      ),
                    )),
                    DataCell(Text(
                      '${t.spanCount}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: CodeOpsColors.textPrimary,
                      ),
                    )),
                    DataCell(Text(
                      '${t.serviceCount}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: CodeOpsColors.textPrimary,
                      ),
                    )),
                    DataCell(
                      Icon(
                        t.hasErrors ? Icons.error : Icons.check_circle,
                        size: 14,
                        color: t.hasErrors
                            ? CodeOpsColors.error
                            : CodeOpsColors.success,
                      ),
                    ),
                    DataCell(Text(
                      DateFormat('HH:mm:ss').format(t.startTime),
                      style: const TextStyle(
                        fontSize: 11,
                        color: CodeOpsColors.textSecondary,
                        fontFamily: 'monospace',
                      ),
                    )),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
        // Pagination bar.
        Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: CodeOpsColors.border)),
          ),
          child: Row(
            children: [
              Text(
                '${pageResponse.totalElements} traces',
                style: const TextStyle(
                  color: CodeOpsColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 18),
                color: CodeOpsColors.textSecondary,
                onPressed: page > 0
                    ? () => ref
                        .read(loggerTracePageProvider.notifier)
                        .state = page - 1
                    : null,
              ),
              Text(
                'Page ${page + 1} of ${pageResponse.totalPages.clamp(1, 999)}',
                style: const TextStyle(
                  color: CodeOpsColors.textPrimary,
                  fontSize: 11,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 18),
                color: CodeOpsColors.textSecondary,
                onPressed: !pageResponse.isLast
                    ? () => ref
                        .read(loggerTracePageProvider.notifier)
                        .state = page + 1
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Formats duration in milliseconds to a human-readable string.
  String _formatDuration(int ms) {
    if (ms < 1000) return '${ms}ms';
    if (ms < 60000) return '${(ms / 1000).toStringAsFixed(1)}s';
    return '${(ms / 60000).toStringAsFixed(1)}m';
  }
}
