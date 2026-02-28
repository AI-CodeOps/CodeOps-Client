/// Sortable data table for fleet containers with checkbox selection.
///
/// Displays containers in a table with columns for name, image, status,
/// CPU, memory, and age. Supports ascending/descending sort on each column,
/// per-row checkbox selection, and per-row contextual action buttons.
library;

import 'package:flutter/material.dart';

import '../../models/fleet_enums.dart';
import '../../models/fleet_models.dart';
import '../../theme/colors.dart';
import '../../utils/date_utils.dart';
import '../../utils/file_utils.dart';
import 'container_row_actions.dart';
import 'container_status_badge.dart';

/// Sortable column identifiers for the container list table.
enum ContainerSortColumn {
  /// Sort by container name.
  name,

  /// Sort by Docker image.
  image,

  /// Sort by container status.
  status,

  /// Sort by CPU usage percentage.
  cpu,

  /// Sort by memory usage in bytes.
  memory,

  /// Sort by container age (startedAt).
  age;

  /// Human-readable column header label.
  String get label => switch (this) {
        ContainerSortColumn.name => 'Name',
        ContainerSortColumn.image => 'Image',
        ContainerSortColumn.status => 'Status',
        ContainerSortColumn.cpu => 'CPU',
        ContainerSortColumn.memory => 'Memory',
        ContainerSortColumn.age => 'Age',
      };
}

/// Sortable table with checkbox selection for fleet containers.
class ContainerListTable extends StatelessWidget {
  /// The containers to display in the table.
  final List<FleetContainerInstance> containers;

  /// The currently active sort column.
  final ContainerSortColumn sortColumn;

  /// Whether the sort is ascending (`true`) or descending (`false`).
  final bool sortAscending;

  /// Called when a column header is tapped to change the sort.
  final ValueChanged<ContainerSortColumn> onSort;

  /// The set of selected container IDs.
  final Set<String> selectedIds;

  /// Called when the select-all checkbox is toggled.
  final ValueChanged<bool> onSelectAll;

  /// Called when a single row's checkbox is toggled.
  final void Function(String containerId, bool selected) onSelectRow;

  /// Called when a row is tapped to navigate to the detail page.
  final ValueChanged<FleetContainerInstance> onRowTap;

  /// Called when the Stop action is tapped for a container.
  final ValueChanged<FleetContainerInstance> onStop;

  /// Called when the Start action is tapped for a container.
  final ValueChanged<FleetContainerInstance> onStart;

  /// Called when the Restart action is tapped for a container.
  final ValueChanged<FleetContainerInstance> onRestart;

  /// Called when the Remove action is tapped for a container.
  final ValueChanged<FleetContainerInstance> onRemove;

  /// Called when the View Logs action is tapped for a container.
  final ValueChanged<FleetContainerInstance> onViewLogs;

  /// Creates a [ContainerListTable].
  const ContainerListTable({
    super.key,
    required this.containers,
    required this.sortColumn,
    required this.sortAscending,
    required this.onSort,
    required this.selectedIds,
    required this.onSelectAll,
    required this.onSelectRow,
    required this.onRowTap,
    required this.onStop,
    required this.onStart,
    required this.onRestart,
    required this.onRemove,
    required this.onViewLogs,
  });

  @override
  Widget build(BuildContext context) {
    final allSelected =
        containers.isNotEmpty &&
        containers.every((c) => c.id != null && selectedIds.contains(c.id));

    return Container(
      decoration: BoxDecoration(
        color: CodeOpsColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CodeOpsColors.border),
      ),
      child: Column(
        children: [
          // Header row
          _buildHeader(allSelected),
          const Divider(height: 1, color: CodeOpsColors.border),
          // Data rows
          ...containers.map(_buildRow),
        ],
      ),
    );
  }

  /// Builds the header row with sort controls and select-all checkbox.
  Widget _buildHeader(bool allSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: CodeOpsColors.surfaceVariant,
      child: Row(
        children: [
          // Select-all checkbox
          SizedBox(
            width: 40,
            child: Checkbox(
              value: allSelected,
              onChanged: (v) => onSelectAll(v ?? false),
              activeColor: CodeOpsColors.primary,
              side: const BorderSide(color: CodeOpsColors.textTertiary),
            ),
          ),
          // Sortable column headers
          _sortableHeader(ContainerSortColumn.name, flex: 3),
          _sortableHeader(ContainerSortColumn.image, flex: 3),
          _sortableHeader(ContainerSortColumn.status, flex: 2),
          _sortableHeader(ContainerSortColumn.cpu, flex: 1),
          _sortableHeader(ContainerSortColumn.memory, flex: 2),
          _sortableHeader(ContainerSortColumn.age, flex: 2),
          // Actions spacer
          const SizedBox(width: 160),
        ],
      ),
    );
  }

  /// Builds a single sortable column header.
  Widget _sortableHeader(ContainerSortColumn column, {int flex = 1}) {
    final isActive = sortColumn == column;
    return Expanded(
      flex: flex,
      child: InkWell(
        onTap: () => onSort(column),
        child: Row(
          children: [
            Text(
              column.label,
              style: TextStyle(
                color: isActive
                    ? CodeOpsColors.textPrimary
                    : CodeOpsColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (isActive)
              Icon(
                sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 14,
                color: CodeOpsColors.textPrimary,
              ),
          ],
        ),
      ),
    );
  }

  /// Builds a single data row for a container.
  Widget _buildRow(FleetContainerInstance container) {
    final id = container.id ?? '';
    final isSelected = selectedIds.contains(id);
    final status = container.status ?? ContainerStatus.created;
    final isRunning = status == ContainerStatus.running;
    final isStopped = status == ContainerStatus.stopped ||
        status == ContainerStatus.exited ||
        status == ContainerStatus.created;

    return InkWell(
      onTap: () => onRowTap(container),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? CodeOpsColors.primary.withValues(alpha: 0.08)
              : Colors.transparent,
          border: const Border(
            bottom: BorderSide(color: CodeOpsColors.border, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            // Row checkbox
            SizedBox(
              width: 40,
              child: Checkbox(
                value: isSelected,
                onChanged: (v) => onSelectRow(id, v ?? false),
                activeColor: CodeOpsColors.primary,
                side: const BorderSide(color: CodeOpsColors.textTertiary),
              ),
            ),
            // Name
            Expanded(
              flex: 3,
              child: Text(
                container.containerName ?? '—',
                style: const TextStyle(
                  color: CodeOpsColors.textPrimary,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Image
            Expanded(
              flex: 3,
              child: Text(
                _formatImage(container),
                style: const TextStyle(
                  color: CodeOpsColors.textSecondary,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Status
            Expanded(
              flex: 2,
              child: ContainerStatusBadge(status: status),
            ),
            // CPU
            Expanded(
              flex: 1,
              child: Text(
                container.cpuPercent != null
                    ? '${container.cpuPercent!.toStringAsFixed(1)}%'
                    : '—',
                style: const TextStyle(
                  color: CodeOpsColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
            // Memory
            Expanded(
              flex: 2,
              child: Text(
                container.memoryBytes != null
                    ? formatFileSize(container.memoryBytes!)
                    : '—',
                style: const TextStyle(
                  color: CodeOpsColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
            // Age
            Expanded(
              flex: 2,
              child: Text(
                formatTimeAgo(container.startedAt),
                style: const TextStyle(
                  color: CodeOpsColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
            // Per-row actions
            SizedBox(
              width: 160,
              child: ContainerRowActions(
                status: status,
                callbacks: (
                  onStop: isRunning ? () => onStop(container) : null,
                  onStart: isStopped ? () => onStart(container) : null,
                  onRestart: () => onRestart(container),
                  onRemove: () => onRemove(container),
                  onViewLogs: () => onViewLogs(container),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Formats the image name and tag for display.
  String _formatImage(FleetContainerInstance c) {
    final name = c.imageName ?? '—';
    final tag = c.imageTag;
    if (tag != null && tag.isNotEmpty) return '$name:$tag';
    return name;
  }
}
