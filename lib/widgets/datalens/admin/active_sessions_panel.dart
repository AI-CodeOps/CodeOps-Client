/// Active sessions panel for the DataLens database admin module.
///
/// Displays a DataTable of backend sessions with filtering by state,
/// auto-refresh, row expansion for full query text, and a context menu
/// to terminate or cancel sessions.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/datalens_admin_models.dart';
import '../../../providers/datalens_providers.dart';
import '../../../theme/colors.dart';

/// Panel displaying all active database sessions.
///
/// Features: state filter dropdown, auto-refresh toggle (5 s), expandable
/// rows with full query text, and right-click context menu for
/// terminate / cancel-query.
class ActiveSessionsPanel extends ConsumerStatefulWidget {
  /// Connection ID to query sessions for.
  final String connectionId;

  /// Creates an [ActiveSessionsPanel].
  const ActiveSessionsPanel({super.key, required this.connectionId});

  @override
  ConsumerState<ActiveSessionsPanel> createState() =>
      _ActiveSessionsPanelState();
}

class _ActiveSessionsPanelState extends ConsumerState<ActiveSessionsPanel> {
  List<ActiveSession> _sessions = [];
  bool _loading = false;
  String? _error;
  String _stateFilter = 'all';
  bool _autoRefresh = true;
  Timer? _refreshTimer;
  int? _expandedPid;

  @override
  void initState() {
    super.initState();
    _loadSessions();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    if (_autoRefresh) {
      _refreshTimer = Timer.periodic(
        const Duration(seconds: 5),
        (_) => _loadSessions(),
      );
    }
  }

  Future<void> _loadSessions() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final service = ref.read(dbAdminServiceProvider);
      final sessions = await service.getActiveSessions(widget.connectionId);
      if (mounted) {
        setState(() {
          _sessions = sessions;
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

  List<ActiveSession> get _filteredSessions {
    if (_stateFilter == 'all') return _sessions;
    return _sessions.where((s) => s.state == _stateFilter).toList();
  }

  Future<void> _terminateSession(int pid) async {
    try {
      final service = ref.read(dbAdminServiceProvider);
      await service.terminateSession(widget.connectionId, pid);
      _loadSessions();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to terminate: $e')),
        );
      }
    }
  }

  Future<void> _cancelQuery(int pid) async {
    try {
      final service = ref.read(dbAdminServiceProvider);
      await service.cancelSessionQuery(widget.connectionId, pid);
      _loadSessions();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to cancel query: $e')),
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
          const Text(
            'State:',
            style: TextStyle(fontSize: 12, color: CodeOpsColors.textSecondary),
          ),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: _stateFilter,
            dropdownColor: CodeOpsColors.surfaceVariant,
            style: const TextStyle(fontSize: 12, color: CodeOpsColors.textPrimary),
            underline: const SizedBox.shrink(),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('All')),
              DropdownMenuItem(value: 'active', child: Text('Active')),
              DropdownMenuItem(value: 'idle', child: Text('Idle')),
              DropdownMenuItem(
                value: 'idle in transaction',
                child: Text('Idle in Transaction'),
              ),
            ],
            onChanged: (v) => setState(() => _stateFilter = v ?? 'all'),
          ),
          const Spacer(),
          Text(
            '${_filteredSessions.length} session${_filteredSessions.length == 1 ? '' : 's'}',
            style: const TextStyle(
              fontSize: 11,
              color: CodeOpsColors.textTertiary,
            ),
          ),
          const SizedBox(width: 12),
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
            onPressed: _loadSessions,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_loading && _sessions.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: CodeOpsColors.primary),
      );
    }
    if (_error != null && _sessions.isEmpty) {
      return Center(
        child: Text(
          _error!,
          style: const TextStyle(fontSize: 12, color: CodeOpsColors.error),
        ),
      );
    }
    if (_filteredSessions.isEmpty) {
      return const Center(
        child: Text(
          'No active sessions',
          style: TextStyle(fontSize: 12, color: CodeOpsColors.textTertiary),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(CodeOpsColors.surface),
          dataRowColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return CodeOpsColors.primary.withValues(alpha: 0.05);
            }
            return null;
          }),
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
            DataColumn(label: Text('Database')),
            DataColumn(label: Text('User')),
            DataColumn(label: Text('State')),
            DataColumn(label: Text('Duration')),
            DataColumn(label: Text('Query')),
            DataColumn(label: Text('Actions')),
          ],
          rows: _filteredSessions.map((s) => _buildRow(s)).toList(),
        ),
      ),
    );
  }

  DataRow _buildRow(ActiveSession session) {
    final isExpanded = _expandedPid == session.pid;
    final queryText = session.query ?? '';
    final truncatedQuery =
        queryText.length > 60 ? '${queryText.substring(0, 60)}...' : queryText;

    return DataRow(
      cells: [
        DataCell(Text('${session.pid}')),
        DataCell(Text(session.database ?? '')),
        DataCell(Text(session.username ?? '')),
        DataCell(_stateChip(session.state)),
        DataCell(Text(_formatDuration(session.waitDurationSec))),
        DataCell(
          InkWell(
            onTap: queryText.isNotEmpty
                ? () => setState(() =>
                    _expandedPid = isExpanded ? null : session.pid)
                : null,
            child: Text(
              isExpanded ? queryText : truncatedQuery,
              maxLines: isExpanded ? null : 1,
              overflow: isExpanded ? null : TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.cancel, size: 14),
              color: CodeOpsColors.warning,
              tooltip: 'Cancel query',
              onPressed: () => _cancelQuery(session.pid),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.stop_circle, size: 14),
              color: CodeOpsColors.error,
              tooltip: 'Terminate session',
              onPressed: () => _terminateSession(session.pid),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
            ),
          ],
        )),
      ],
    );
  }

  Widget _stateChip(String? state) {
    final color = switch (state) {
      'active' => CodeOpsColors.success,
      'idle' => CodeOpsColors.textTertiary,
      'idle in transaction' => CodeOpsColors.warning,
      _ => CodeOpsColors.textSecondary,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        state ?? 'unknown',
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  String _formatDuration(double? seconds) {
    if (seconds == null) return '-';
    if (seconds < 1) return '<1s';
    if (seconds < 60) return '${seconds.toStringAsFixed(0)}s';
    if (seconds < 3600) return '${(seconds / 60).toStringAsFixed(1)}m';
    return '${(seconds / 3600).toStringAsFixed(1)}h';
  }
}
