/// Lock monitor panel for the DataLens database admin module.
///
/// Displays current database locks in two sub-tabs: a flat list of all
/// locks and a blocking-relationships view showing blocked/blocking
/// session pairs. Color-codes lock modes and provides a terminate button
/// for blocking sessions.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/datalens_admin_models.dart';
import '../../../providers/datalens_providers.dart';
import '../../../theme/colors.dart';

/// Panel displaying database locks and blocking relationships.
///
/// Two sub-tabs:
/// - **All Locks**: flat DataTable of every lock (granted + waiting).
/// - **Blocking**: pairs of blocking ↔ blocked sessions.
class LockMonitorPanel extends ConsumerStatefulWidget {
  /// Connection ID to query locks for.
  final String connectionId;

  /// Creates a [LockMonitorPanel].
  const LockMonitorPanel({super.key, required this.connectionId});

  @override
  ConsumerState<LockMonitorPanel> createState() => _LockMonitorPanelState();
}

class _LockMonitorPanelState extends ConsumerState<LockMonitorPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<LockInfo> _locks = [];
  List<LockConflict> _conflicts = [];
  bool _loading = false;
  String? _error;
  bool _autoRefresh = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadLocks();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    if (_autoRefresh) {
      _refreshTimer = Timer.periodic(
        const Duration(seconds: 5),
        (_) => _loadLocks(),
      );
    }
  }

  Future<void> _loadLocks() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final service = ref.read(dbAdminServiceProvider);
      final locks = await service.getLocks(widget.connectionId);
      final conflicts = await service.getLockConflicts(widget.connectionId);
      if (mounted) {
        setState(() {
          _locks = locks;
          _conflicts = conflicts;
          _error = null;
          _loading = false;
        });
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

  Future<void> _terminateSession(int pid) async {
    try {
      final service = ref.read(dbAdminServiceProvider);
      await service.terminateSession(widget.connectionId, pid);
      _loadLocks();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to terminate: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildToolbar(),
        const Divider(height: 1, color: CodeOpsColors.border),
        TabBar(
          controller: _tabController,
          labelColor: CodeOpsColors.primary,
          unselectedLabelColor: CodeOpsColors.textTertiary,
          indicatorColor: CodeOpsColors.primary,
          labelStyle: const TextStyle(fontSize: 12),
          tabs: [
            Tab(text: 'All Locks (${_locks.length})'),
            Tab(text: 'Blocking (${_conflicts.length})'),
          ],
        ),
        const Divider(height: 1, color: CodeOpsColors.border),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildLocksTab(),
              _buildConflictsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: CodeOpsColors.surface,
      child: Row(
        children: [
          if (_conflicts.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: CodeOpsColors.error.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${_conflicts.length} blocking',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: CodeOpsColors.error,
                ),
              ),
            ),
          const Spacer(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Auto-refresh',
                style: TextStyle(fontSize: 11, color: CodeOpsColors.textTertiary),
              ),
              const SizedBox(width: 4),
              SizedBox(
                height: 20,
                child: Switch(
                  value: _autoRefresh,
                  onChanged: (v) {
                    setState(() => _autoRefresh = v);
                    _startAutoRefresh();
                  },
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
            onPressed: _loadLocks,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }

  Widget _buildLocksTab() {
    if (_loading && _locks.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: CodeOpsColors.primary),
      );
    }
    if (_error != null && _locks.isEmpty) {
      return Center(
        child: Text(
          _error!,
          style: const TextStyle(fontSize: 12, color: CodeOpsColors.error),
        ),
      );
    }
    if (_locks.isEmpty) {
      return const Center(
        child: Text(
          'No locks held',
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
          headingTextStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: CodeOpsColors.textSecondary,
          ),
          dataTextStyle: const TextStyle(
            fontSize: 11,
            color: CodeOpsColors.textPrimary,
          ),
          columns: const [
            DataColumn(label: Text('PID')),
            DataColumn(label: Text('Type')),
            DataColumn(label: Text('Mode')),
            DataColumn(label: Text('Relation')),
            DataColumn(label: Text('Granted')),
            DataColumn(label: Text('User')),
            DataColumn(label: Text('Query')),
          ],
          rows: _locks.map((l) => _buildLockRow(l)).toList(),
        ),
      ),
    );
  }

  DataRow _buildLockRow(LockInfo lock) {
    return DataRow(
      color: !lock.granted
          ? WidgetStateProperty.all(
              CodeOpsColors.error.withValues(alpha: 0.06))
          : null,
      cells: [
        DataCell(Text('${lock.pid}')),
        DataCell(Text(lock.lockType)),
        DataCell(_lockModeChip(lock.lockMode)),
        DataCell(Text(lock.relation ?? '-')),
        DataCell(Icon(
          lock.granted ? Icons.check_circle : Icons.hourglass_empty,
          size: 14,
          color: lock.granted ? CodeOpsColors.success : CodeOpsColors.warning,
        )),
        DataCell(Text(lock.username ?? '')),
        DataCell(Text(
          _truncate(lock.query ?? '', 50),
          overflow: TextOverflow.ellipsis,
        )),
      ],
    );
  }

  Widget _lockModeChip(String mode) {
    final isExclusive = mode.toLowerCase().contains('exclusive');
    final color = isExclusive ? CodeOpsColors.error : CodeOpsColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        mode.replaceAll('Lock', ''),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildConflictsTab() {
    if (_loading && _conflicts.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: CodeOpsColors.primary),
      );
    }
    if (_conflicts.isEmpty) {
      return const Center(
        child: Text(
          'No blocking relationships detected',
          style: TextStyle(fontSize: 12, color: CodeOpsColors.textTertiary),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _conflicts.length,
      itemBuilder: (context, index) => _buildConflictCard(_conflicts[index]),
    );
  }

  Widget _buildConflictCard(LockConflict conflict) {
    return Card(
      color: CodeOpsColors.surfaceVariant,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.block, size: 14, color: CodeOpsColors.error),
                const SizedBox(width: 4),
                Text(
                  'PID ${conflict.blockingPid} blocks PID ${conflict.blockedPid}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: CodeOpsColors.textPrimary,
                  ),
                ),
                if (conflict.lockMode != null) ...[
                  const SizedBox(width: 8),
                  _lockModeChip(conflict.lockMode!),
                ],
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.stop_circle, size: 14),
                  color: CodeOpsColors.error,
                  tooltip: 'Terminate blocking session',
                  onPressed: () => _terminateSession(conflict.blockingPid),
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 20, minHeight: 20),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _conflictRow('Blocking', conflict.blockingUser,
                conflict.blockingQuery),
            const SizedBox(height: 4),
            _conflictRow(
                'Blocked', conflict.blockedUser, conflict.blockedQuery),
          ],
        ),
      ),
    );
  }

  Widget _conflictRow(String label, String? user, String? query) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: CodeOpsColors.textSecondary,
            ),
          ),
        ),
        if (user != null) ...[
          Text(
            '$user: ',
            style: const TextStyle(
              fontSize: 10,
              color: CodeOpsColors.textSecondary,
            ),
          ),
        ],
        Expanded(
          child: Text(
            _truncate(query ?? '-', 80),
            style: const TextStyle(
              fontSize: 10,
              fontFamily: 'JetBrains Mono',
              color: CodeOpsColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  String _truncate(String text, int maxLen) {
    if (text.length <= maxLen) return text;
    return '${text.substring(0, maxLen)}...';
  }
}
