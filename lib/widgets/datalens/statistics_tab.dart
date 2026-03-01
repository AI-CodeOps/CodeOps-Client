/// DBeaver-style statistics display for the Properties panel.
///
/// Displays table statistics from pg_stat_user_tables in a key-value layout
/// organized into logical sections: Row Counts, Maintenance, Scans, and DML.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/datalens_models.dart';
import '../../providers/datalens_providers.dart';
import '../../theme/colors.dart';

/// The Statistics sub-tab within the Properties panel.
///
/// Shows table statistics from pg_stat_user_tables in a scrollable key-value
/// layout grouped by section: Row Counts, Maintenance, Scans, DML Operations.
class StatisticsTab extends ConsumerWidget {
  /// Creates a [StatisticsTab].
  const StatisticsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(datalensStatisticsProvider);

    return statsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(
          color: CodeOpsColors.primary,
          strokeWidth: 2,
        ),
      ),
      error: (error, _) => Center(
        child: Text(
          'Error loading statistics: $error',
          style: const TextStyle(color: CodeOpsColors.error, fontSize: 12),
        ),
      ),
      data: (stats) {
        if (stats == null) {
          return const Center(
            child: Text(
              'No statistics available',
              style: TextStyle(
                color: CodeOpsColors.textTertiary,
                fontSize: 12,
              ),
            ),
          );
        }

        return _buildStatistics(stats);
      },
    );
  }

  /// Builds the full statistics layout.
  Widget _buildStatistics(TableStatistics stats) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _section('Row Counts', [
            _statRow('Live Rows', _formatInt(stats.liveRowCount)),
            _statRow('Dead Rows', _formatInt(stats.deadRowCount)),
          ]),
          const SizedBox(height: 16),
          _section('Maintenance', [
            _statRow('Last Vacuum', _formatDateTime(stats.lastVacuum)),
            _statRow(
                'Last Auto Vacuum', _formatDateTime(stats.lastAutoVacuum)),
            _statRow('Last Analyze', _formatDateTime(stats.lastAnalyze)),
            _statRow(
                'Last Auto Analyze', _formatDateTime(stats.lastAutoAnalyze)),
          ]),
          const SizedBox(height: 16),
          _section('Scans', [
            _statRow('Sequential Scans', _formatInt(stats.seqScans)),
            _statRow('Index Scans', _formatInt(stats.idxScans)),
          ]),
          const SizedBox(height: 16),
          _section('DML Operations', [
            _statRow('Inserts', _formatInt(stats.insertCount)),
            _statRow('Updates', _formatInt(stats.updateCount)),
            _statRow('Deletes', _formatInt(stats.deleteCount)),
          ]),
        ],
      ),
    );
  }

  /// Builds a section header with its rows.
  Widget _section(String title, List<Widget> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: CodeOpsColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: CodeOpsColors.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: CodeOpsColors.border, width: 0.5),
          ),
          child: Column(children: rows),
        ),
      ],
    );
  }

  /// Builds a single key-value statistic row.
  Widget _statRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: CodeOpsColors.divider, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: CodeOpsColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: CodeOpsColors.textPrimary,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Formats an integer with comma separators, or '—' if null.
  String _formatInt(int? value) {
    if (value == null) return '—';
    if (value < 1000) return '$value';
    // Simple comma formatting.
    final str = value.toString();
    final buf = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write(',');
      buf.write(str[i]);
    }
    return buf.toString();
  }

  /// Formats a DateTime or returns '—' if null.
  String _formatDateTime(DateTime? dt) {
    if (dt == null) return '—';
    return '${dt.year}-${_pad(dt.month)}-${_pad(dt.day)} '
        '${_pad(dt.hour)}:${_pad(dt.minute)}:${_pad(dt.second)}';
  }

  /// Pads a number with a leading zero if needed.
  String _pad(int n) => n.toString().padLeft(2, '0');
}
