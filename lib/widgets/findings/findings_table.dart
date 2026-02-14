/// Paginated findings table widget.
///
/// DataTable with sorting, multi-select, severity badges,
/// and column definitions for the findings explorer.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/enums.dart';
import '../../models/finding.dart';
import '../../providers/finding_providers.dart';
import '../../theme/colors.dart';

/// Paginated table of findings with sorting and multi-select.
class FindingsTable extends ConsumerStatefulWidget {
  /// Findings to display.
  final List<Finding> findings;

  /// Called when a finding row is tapped.
  final ValueChanged<Finding>? onFindingTap;

  /// Current page index.
  final int currentPage;

  /// Total number of pages.
  final int totalPages;

  /// Called when the page changes.
  final ValueChanged<int>? onPageChanged;

  /// Creates a [FindingsTable].
  const FindingsTable({
    super.key,
    required this.findings,
    this.onFindingTap,
    this.currentPage = 0,
    this.totalPages = 1,
    this.onPageChanged,
  });

  @override
  ConsumerState<FindingsTable> createState() => _FindingsTableState();
}

class _FindingsTableState extends ConsumerState<FindingsTable> {
  int _sortColumnIndex = 0;
  bool _sortAscending = true;

  List<Finding> get _sortedFindings {
    final findings = List.of(widget.findings);
    findings.sort((a, b) {
      final result = switch (_sortColumnIndex) {
        0 => a.severity.index.compareTo(b.severity.index),
        1 => a.agentType.displayName.compareTo(b.agentType.displayName),
        2 => a.title.compareTo(b.title),
        3 => (a.filePath ?? '').compareTo(b.filePath ?? ''),
        4 => a.status.index.compareTo(b.status.index),
        _ => 0,
      };
      return _sortAscending ? result : -result;
    });
    return findings;
  }

  @override
  Widget build(BuildContext context) {
    final selectedIds = ref.watch(selectedFindingIdsProvider);
    final sorted = _sortedFindings;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: DataTable(
              sortColumnIndex: _sortColumnIndex,
              sortAscending: _sortAscending,
              showCheckboxColumn: true,
              headingRowColor:
                  WidgetStateProperty.all(CodeOpsColors.surfaceVariant),
              dataRowColor:
                  WidgetStateProperty.all(CodeOpsColors.surface),
              columns: [
                DataColumn(
                  label: const Text('Severity',
                      style: TextStyle(
                          color: CodeOpsColors.textPrimary, fontSize: 12)),
                  onSort: (i, asc) => setState(() {
                    _sortColumnIndex = i;
                    _sortAscending = asc;
                  }),
                ),
                DataColumn(
                  label: const Text('Agent',
                      style: TextStyle(
                          color: CodeOpsColors.textPrimary, fontSize: 12)),
                  onSort: (i, asc) => setState(() {
                    _sortColumnIndex = i;
                    _sortAscending = asc;
                  }),
                ),
                DataColumn(
                  label: const Text('Title',
                      style: TextStyle(
                          color: CodeOpsColors.textPrimary, fontSize: 12)),
                  onSort: (i, asc) => setState(() {
                    _sortColumnIndex = i;
                    _sortAscending = asc;
                  }),
                ),
                DataColumn(
                  label: const Text('File',
                      style: TextStyle(
                          color: CodeOpsColors.textPrimary, fontSize: 12)),
                  onSort: (i, asc) => setState(() {
                    _sortColumnIndex = i;
                    _sortAscending = asc;
                  }),
                ),
                DataColumn(
                  label: const Text('Status',
                      style: TextStyle(
                          color: CodeOpsColors.textPrimary, fontSize: 12)),
                  onSort: (i, asc) => setState(() {
                    _sortColumnIndex = i;
                    _sortAscending = asc;
                  }),
                ),
              ],
              rows: sorted.map((finding) {
                final isSelected = selectedIds.contains(finding.id);
                return DataRow(
                  selected: isSelected,
                  onSelectChanged: (selected) {
                    final ids = Set<String>.from(selectedIds);
                    if (selected == true) {
                      ids.add(finding.id);
                    } else {
                      ids.remove(finding.id);
                    }
                    ref.read(selectedFindingIdsProvider.notifier).state = ids;
                  },
                  onLongPress: () => widget.onFindingTap?.call(finding),
                  cells: [
                    DataCell(
                      InkWell(
                        onTap: () => widget.onFindingTap?.call(finding),
                        child: _SeverityBadge(severity: finding.severity),
                      ),
                    ),
                    DataCell(
                      InkWell(
                        onTap: () => widget.onFindingTap?.call(finding),
                        child: Text(
                          finding.agentType.displayName,
                          style: const TextStyle(
                            color: CodeOpsColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      InkWell(
                        onTap: () => widget.onFindingTap?.call(finding),
                        child: SizedBox(
                          width: 250,
                          child: Text(
                            finding.title,
                            style: const TextStyle(
                              color: CodeOpsColors.textPrimary,
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        finding.filePath != null
                            ? '${finding.filePath}${finding.lineNumber != null ? ':${finding.lineNumber}' : ''}'
                            : 'N/A',
                        style: const TextStyle(
                          color: CodeOpsColors.textTertiary,
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DataCell(_StatusBadge(status: finding.status)),
                  ],
                );
              }).toList(),
            ),
          ),
        ),

        // Pagination
        if (widget.totalPages > 1)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: CodeOpsColors.divider),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left,
                      size: 18, color: CodeOpsColors.textSecondary),
                  onPressed: widget.currentPage > 0
                      ? () =>
                          widget.onPageChanged?.call(widget.currentPage - 1)
                      : null,
                ),
                Text(
                  'Page ${widget.currentPage + 1} of ${widget.totalPages}',
                  style: const TextStyle(
                    color: CodeOpsColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right,
                      size: 18, color: CodeOpsColors.textSecondary),
                  onPressed: widget.currentPage < widget.totalPages - 1
                      ? () =>
                          widget.onPageChanged?.call(widget.currentPage + 1)
                      : null,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _SeverityBadge extends StatelessWidget {
  final Severity severity;

  const _SeverityBadge({required this.severity});

  @override
  Widget build(BuildContext context) {
    final color = CodeOpsColors.severityColors[severity]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        severity.displayName,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final FindingStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      FindingStatus.open => CodeOpsColors.textTertiary,
      FindingStatus.acknowledged => CodeOpsColors.primary,
      FindingStatus.falsePositive => CodeOpsColors.textSecondary,
      FindingStatus.fixed => CodeOpsColors.success,
      FindingStatus.wontFix => CodeOpsColors.warning,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
