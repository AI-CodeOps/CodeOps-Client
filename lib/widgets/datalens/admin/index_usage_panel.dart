/// Index usage panel for the DataLens database admin module.
///
/// Displays index scan statistics with filtering for unused indexes,
/// sorting by scan count, and a drop-index confirmation dialog.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/datalens_admin_models.dart';
import '../../../providers/datalens_providers.dart';
import '../../../theme/colors.dart';

/// Panel displaying index usage statistics for a schema.
///
/// Features: toggle for showing only unused indexes, sortable columns,
/// and a drop-index action with confirmation dialog.
class IndexUsagePanel extends ConsumerStatefulWidget {
  /// Connection ID to query index usage for.
  final String connectionId;

  /// Schema to show indexes for.
  final String schema;

  /// Creates an [IndexUsagePanel].
  const IndexUsagePanel({
    super.key,
    required this.connectionId,
    required this.schema,
  });

  @override
  ConsumerState<IndexUsagePanel> createState() => _IndexUsagePanelState();
}

class _IndexUsagePanelState extends ConsumerState<IndexUsagePanel> {
  List<IndexUsageInfo> _indexes = [];
  bool _loading = false;
  String? _error;
  bool _showUnusedOnly = false;
  int _sortColumnIndex = 3; // scan count
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    _loadIndexes();
  }

  @override
  void didUpdateWidget(covariant IndexUsagePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.connectionId != widget.connectionId ||
        oldWidget.schema != widget.schema) {
      _loadIndexes();
    }
  }

  Future<void> _loadIndexes() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final service = ref.read(dbAdminServiceProvider);
      final indexes =
          await service.getIndexUsage(widget.connectionId, widget.schema);
      if (mounted) {
        setState(() {
          _indexes = indexes;
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

  List<IndexUsageInfo> get _filteredIndexes {
    if (_showUnusedOnly) {
      return _indexes.where((i) => i.indexScans == 0).toList();
    }
    return _indexes;
  }

  void _sort() {
    _indexes.sort((a, b) {
      int cmp;
      switch (_sortColumnIndex) {
        case 0:
          cmp = a.tableName.compareTo(b.tableName);
        case 1:
          cmp = a.indexName.compareTo(b.indexName);
        case 2:
          cmp = a.indexSize.compareTo(b.indexSize);
        case 3:
          cmp = a.indexScans.compareTo(b.indexScans);
        case 4:
          cmp = a.indexTuplesRead.compareTo(b.indexTuplesRead);
        default:
          cmp = 0;
      }
      return _sortAscending ? cmp : -cmp;
    });
  }

  Future<void> _confirmDropIndex(IndexUsageInfo index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CodeOpsColors.surface,
        title: const Text(
          'Drop Index',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: CodeOpsColors.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to drop index "${index.indexName}" '
          'on table "${index.tableName}"?\n\n'
          'This action cannot be undone.',
          style: const TextStyle(
            fontSize: 12,
            color: CodeOpsColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel',
                style: TextStyle(color: CodeOpsColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: CodeOpsColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Drop'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final driver = ref.read(datalensConnectionServiceProvider)
            .getDriver(widget.connectionId);
        if (driver != null) {
          final dialect = driver.dialect;
          await driver.execute(
            'DROP INDEX ${dialect.quoteIdentifier(widget.schema)}.${dialect.quoteIdentifier(index.indexName)}',
          );
          _loadIndexes();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to drop index: $e')),
          );
        }
      }
    }
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
    final unusedCount = _indexes.where((i) => i.indexScans == 0).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: CodeOpsColors.surface,
      child: Row(
        children: [
          Text(
            '${_filteredIndexes.length} index${_filteredIndexes.length == 1 ? '' : 'es'}',
            style: const TextStyle(
              fontSize: 11,
              color: CodeOpsColors.textTertiary,
            ),
          ),
          if (unusedCount > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: CodeOpsColors.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '$unusedCount unused',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: CodeOpsColors.warning,
                ),
              ),
            ),
          ],
          const Spacer(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Unused only',
                style: TextStyle(fontSize: 11, color: CodeOpsColors.textTertiary),
              ),
              const SizedBox(width: 4),
              SizedBox(
                height: 20,
                child: Switch(
                  value: _showUnusedOnly,
                  onChanged: (v) => setState(() => _showUnusedOnly = v),
                  activeColor: CodeOpsColors.primary,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh, size: 16),
            color: CodeOpsColors.textSecondary,
            onPressed: _loadIndexes,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_loading && _indexes.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: CodeOpsColors.primary),
      );
    }
    if (_error != null && _indexes.isEmpty) {
      return Center(
        child: Text(
          _error!,
          style: const TextStyle(fontSize: 12, color: CodeOpsColors.error),
        ),
      );
    }
    if (_filteredIndexes.isEmpty) {
      return Center(
        child: Text(
          _showUnusedOnly ? 'No unused indexes' : 'No index data available',
          style: const TextStyle(fontSize: 12, color: CodeOpsColors.textTertiary),
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
            DataColumn(label: const Text('Table'), onSort: _onSort),
            DataColumn(label: const Text('Index'), onSort: _onSort),
            DataColumn(label: const Text('Size'), onSort: _onSort),
            DataColumn(
              label: const Text('Scans'),
              numeric: true,
              onSort: _onSort,
            ),
            DataColumn(
              label: const Text('Tuples Read'),
              numeric: true,
              onSort: _onSort,
            ),
            const DataColumn(label: Text('Actions')),
          ],
          rows: _filteredIndexes.map((i) => _buildRow(i)).toList(),
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

  DataRow _buildRow(IndexUsageInfo index) {
    final isUnused = index.indexScans == 0;

    return DataRow(
      color: isUnused
          ? WidgetStateProperty.all(
              CodeOpsColors.warning.withValues(alpha: 0.06))
          : null,
      cells: [
        DataCell(Text(index.tableName)),
        DataCell(Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(index.indexName),
            if (isUnused) ...[
              const SizedBox(width: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                decoration: BoxDecoration(
                  color: CodeOpsColors.warning.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: const Text(
                  'UNUSED',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: CodeOpsColors.warning,
                  ),
                ),
              ),
            ],
          ],
        )),
        DataCell(Text(index.indexSize)),
        DataCell(Text(
          index.indexScans.toString(),
          style: TextStyle(
            color: isUnused ? CodeOpsColors.warning : null,
            fontWeight: isUnused ? FontWeight.w600 : null,
          ),
        )),
        DataCell(Text(index.indexTuplesRead.toString())),
        DataCell(
          isUnused
              ? IconButton(
                  icon: const Icon(Icons.delete_outline, size: 14),
                  color: CodeOpsColors.error,
                  tooltip: 'Drop index',
                  onPressed: () => _confirmDropIndex(index),
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 20, minHeight: 20),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
