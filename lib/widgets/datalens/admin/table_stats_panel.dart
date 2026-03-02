/// Table statistics panel for the DataLens database admin module.
///
/// Displays a sortable DataTable of per-table statistics including live/dead
/// rows, scan counts, DML counts, VACUUM/ANALYZE timestamps, and sizes.
/// Highlights tables with high dead-tuple ratios and shows VACUUM badges.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/datalens_admin_models.dart';
import '../../../providers/datalens_providers.dart';
import '../../../theme/colors.dart';

/// Panel displaying per-table statistics for a schema.
///
/// Features: sortable columns, dead-tuple ratio highlighting, VACUUM
/// badges, and schema selector.
class TableStatsPanel extends ConsumerStatefulWidget {
  /// Connection ID to query stats for.
  final String connectionId;

  /// Schema to show stats for.
  final String schema;

  /// Creates a [TableStatsPanel].
  const TableStatsPanel({
    super.key,
    required this.connectionId,
    required this.schema,
  });

  @override
  ConsumerState<TableStatsPanel> createState() => _TableStatsPanelState();
}

class _TableStatsPanelState extends ConsumerState<TableStatsPanel> {
  List<TableStatInfo> _stats = [];
  bool _loading = false;
  String? _error;
  int _sortColumnIndex = 2; // live rows
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  @override
  void didUpdateWidget(covariant TableStatsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.connectionId != widget.connectionId ||
        oldWidget.schema != widget.schema) {
      _loadStats();
    }
  }

  Future<void> _loadStats() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final service = ref.read(dbAdminServiceProvider);
      final stats =
          await service.getTableStats(widget.connectionId, widget.schema);
      if (mounted) {
        setState(() {
          _stats = stats;
          _error = null;
          _loading = false;
        });
        _sort();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  void _sort() {
    _stats.sort((a, b) {
      int cmp;
      switch (_sortColumnIndex) {
        case 0:
          cmp = a.tableName.compareTo(b.tableName);
        case 1:
          cmp = (a.tableSize ?? '').compareTo(b.tableSize ?? '');
        case 2:
          cmp = a.liveRows.compareTo(b.liveRows);
        case 3:
          cmp = a.deadRows.compareTo(b.deadRows);
        case 4:
          cmp = a.seqScans.compareTo(b.seqScans);
        case 5:
          cmp = a.idxScans.compareTo(b.idxScans);
        case 6:
          cmp = a.inserts.compareTo(b.inserts);
        default:
          cmp = 0;
      }
      return _sortAscending ? cmp : -cmp;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildToolbar(),
        const Divider(height: 1, color: CodeOpsColors.border),
        Expanded(child: _buildContent()),
      ],
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: CodeOpsColors.surface,
      child: Row(
        children: [
          Text(
            '${_stats.length} table${_stats.length == 1 ? '' : 's'}',
            style: const TextStyle(
              fontSize: 11,
              color: CodeOpsColors.textTertiary,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh, size: 16),
            color: CodeOpsColors.textSecondary,
            onPressed: _loadStats,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_loading && _stats.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: CodeOpsColors.primary),
      );
    }
    if (_error != null && _stats.isEmpty) {
      return Center(
        child: Text(
          _error!,
          style: const TextStyle(fontSize: 12, color: CodeOpsColors.error),
        ),
      );
    }
    if (_stats.isEmpty) {
      return const Center(
        child: Text(
          'No table statistics available',
          style: TextStyle(fontSize: 12, color: CodeOpsColors.textTertiary),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(CodeOpsColors.surface),
          columnSpacing: 16,
          sortColumnIndex: _sortColumnIndex,
          sortAscending: _sortAscending,
          headingTextStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: CodeOpsColors.textSecondary,
          ),
          dataTextStyle: const TextStyle(
            fontSize: 11,
            color: CodeOpsColors.textPrimary,
          ),
          columns: [
            DataColumn(
              label: const Text('Table'),
              onSort: _onSort,
            ),
            DataColumn(
              label: const Text('Size'),
              onSort: _onSort,
            ),
            DataColumn(
              label: const Text('Live Rows'),
              numeric: true,
              onSort: _onSort,
            ),
            DataColumn(
              label: const Text('Dead Rows'),
              numeric: true,
              onSort: _onSort,
            ),
            DataColumn(
              label: const Text('Seq Scans'),
              numeric: true,
              onSort: _onSort,
            ),
            DataColumn(
              label: const Text('Idx Scans'),
              numeric: true,
              onSort: _onSort,
            ),
            DataColumn(
              label: const Text('Inserts'),
              numeric: true,
              onSort: _onSort,
            ),
            const DataColumn(label: Text('Last Vacuum')),
          ],
          rows: _stats.map((s) => _buildRow(s)).toList(),
        ),
      ),
    );
  }

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
      _sort();
    });
  }

  DataRow _buildRow(TableStatInfo stat) {
    final highDeadRatio = stat.deadRatio > 0.1;

    return DataRow(
      color: highDeadRatio
          ? WidgetStateProperty.all(
              CodeOpsColors.warning.withValues(alpha: 0.08))
          : null,
      cells: [
        DataCell(Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(stat.tableName),
            if (stat.deadRatio > 0.2) ...[
              const SizedBox(width: 4),
              _vacuumBadge(),
            ],
          ],
        )),
        DataCell(Text(stat.tableSize ?? '-')),
        DataCell(Text(_formatNumber(stat.liveRows))),
        DataCell(Text(
          _formatNumber(stat.deadRows),
          style: TextStyle(
            color: highDeadRatio ? CodeOpsColors.warning : null,
            fontWeight: highDeadRatio ? FontWeight.w600 : null,
          ),
        )),
        DataCell(Text(_formatNumber(stat.seqScans))),
        DataCell(Text(_formatNumber(stat.idxScans))),
        DataCell(Text(_formatNumber(stat.inserts))),
        DataCell(Text(_formatDateTime(stat.lastVacuum ?? stat.lastAutoVacuum))),
      ],
    );
  }

  Widget _vacuumBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: CodeOpsColors.warning.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(3),
      ),
      child: const Text(
        'VACUUM',
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w700,
          color: CodeOpsColors.warning,
        ),
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return 'Never';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
