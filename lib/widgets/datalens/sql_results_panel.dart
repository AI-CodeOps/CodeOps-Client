/// Query results panel for the DataLens SQL editor.
///
/// Displays SQL query output in a tabbed layout with three views:
/// Results (data grid), Messages (text output for DML/DDL/errors),
/// and Explain (EXPLAIN plan output). Includes a status bar showing
/// row count and execution time.
library;

import 'package:flutter/material.dart';

import '../../models/datalens_enums.dart';
import '../../models/datalens_models.dart';
import '../../theme/colors.dart';
import 'data_grid.dart';

/// The results panel below the SQL editor.
///
/// Contains a tab bar for switching between Results, Messages, and Explain
/// views, and a status bar showing row count and execution time.
class SqlResultsPanel extends StatefulWidget {
  /// The query result to display.
  final QueryResult? result;

  /// The EXPLAIN plan output text.
  final String? explainOutput;

  /// Creates a [SqlResultsPanel].
  const SqlResultsPanel({
    super.key,
    this.result,
    this.explainOutput,
  });

  @override
  State<SqlResultsPanel> createState() => _SqlResultsPanelState();
}

class _SqlResultsPanelState extends State<SqlResultsPanel> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Tab bar
        _buildTabBar(),
        const Divider(height: 1, color: CodeOpsColors.border),

        // Tab content
        Expanded(
          child: switch (_selectedTab) {
            0 => _buildResultsTab(),
            1 => _buildMessagesTab(),
            2 => _buildExplainTab(),
            _ => const SizedBox.shrink(),
          },
        ),

        // Status bar
        const Divider(height: 1, color: CodeOpsColors.border),
        _buildStatusBar(),
      ],
    );
  }

  /// Builds the Results | Messages | Explain tab bar.
  Widget _buildTabBar() {
    return Container(
      color: CodeOpsColors.surface,
      padding: const EdgeInsets.only(left: 8),
      child: Row(
        children: [
          _tab('Results', 0),
          _tab('Messages', 1),
          _tab('Explain', 2),
        ],
      ),
    );
  }

  /// Builds a single tab button.
  Widget _tab(String label, int index) {
    final isSelected = _selectedTab == index;
    return InkWell(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? CodeOpsColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected
                ? CodeOpsColors.textPrimary
                : CodeOpsColors.textSecondary,
          ),
        ),
      ),
    );
  }

  /// Builds the Results tab — data grid or empty state.
  Widget _buildResultsTab() {
    final result = widget.result;

    if (result == null) {
      return const Center(
        child: Text(
          'Execute a query to see results',
          style: TextStyle(color: CodeOpsColors.textTertiary, fontSize: 12),
        ),
      );
    }

    final columns = result.columns ?? [];
    if (columns.isEmpty) {
      return const Center(
        child: Text(
          'Query returned no result set',
          style: TextStyle(color: CodeOpsColors.textTertiary, fontSize: 12),
        ),
      );
    }

    return DataGrid(result: result);
  }

  /// Builds the Messages tab — text output for DML/DDL and errors.
  Widget _buildMessagesTab() {
    final result = widget.result;

    if (result == null) {
      return const Center(
        child: Text(
          'No messages',
          style: TextStyle(color: CodeOpsColors.textTertiary, fontSize: 12),
        ),
      );
    }

    return Container(
      color: CodeOpsColors.background,
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        child: SelectableText(
          _buildMessageText(result),
          style: TextStyle(
            fontSize: 12,
            fontFamily: 'monospace',
            color: result.status == QueryStatus.failed
                ? CodeOpsColors.error
                : CodeOpsColors.textPrimary,
          ),
        ),
      ),
    );
  }

  /// Builds the message text from a query result.
  String _buildMessageText(QueryResult result) {
    final buffer = StringBuffer();

    if (result.status == QueryStatus.failed) {
      buffer.writeln('ERROR: ${result.error ?? 'Unknown error'}');
    } else if (result.columns == null || result.columns!.isEmpty) {
      // DML/DDL result — no columns, just affected rows.
      final rowCount = result.rowCount ?? 0;
      final sql = result.executedSql ?? '';
      final verb = _extractVerb(sql);
      buffer.writeln('$verb $rowCount');
    } else {
      final rowCount = result.rowCount ?? 0;
      buffer.writeln('Query returned $rowCount row${rowCount == 1 ? '' : 's'}');
    }

    if (result.executionTimeMs != null && result.executionTimeMs! > 0) {
      buffer.writeln('Execution time: ${result.executionTimeMs}ms');
    }

    if (result.executedSql != null) {
      buffer.writeln();
      buffer.writeln('-- Executed SQL:');
      buffer.writeln(result.executedSql);
    }

    return buffer.toString().trimRight();
  }

  /// Extracts the SQL verb (e.g., "INSERT 0", "CREATE TABLE") from SQL.
  String _extractVerb(String sql) {
    final trimmed = sql.trimLeft().toUpperCase();
    if (trimmed.startsWith('INSERT')) return 'INSERT 0';
    if (trimmed.startsWith('UPDATE')) return 'UPDATE';
    if (trimmed.startsWith('DELETE')) return 'DELETE';
    if (trimmed.startsWith('CREATE')) return 'CREATE TABLE';
    if (trimmed.startsWith('ALTER')) return 'ALTER TABLE';
    if (trimmed.startsWith('DROP')) return 'DROP TABLE';
    return 'OK';
  }

  /// Builds the Explain tab — EXPLAIN plan output.
  Widget _buildExplainTab() {
    final explain = widget.explainOutput;

    if (explain == null || explain.isEmpty) {
      return const Center(
        child: Text(
          'Run EXPLAIN to see the query plan',
          style: TextStyle(color: CodeOpsColors.textTertiary, fontSize: 12),
        ),
      );
    }

    return Container(
      color: CodeOpsColors.background,
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        child: SelectableText(
          explain,
          style: const TextStyle(
            fontSize: 12,
            fontFamily: 'monospace',
            color: CodeOpsColors.textPrimary,
          ),
        ),
      ),
    );
  }

  /// Builds the bottom status bar.
  Widget _buildStatusBar() {
    final result = widget.result;
    final rowCount = result?.rowCount ?? 0;
    final executionTime = result?.executionTimeMs ?? 0;
    final status = result?.status;

    return Container(
      color: CodeOpsColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          if (status != null) ...[
            Icon(
              _statusIcon(status),
              size: 12,
              color: _statusColor(status),
            ),
            const SizedBox(width: 4),
            Text(
              status.displayName,
              style: TextStyle(
                fontSize: 11,
                color: _statusColor(status),
              ),
            ),
            const SizedBox(width: 16),
          ],
          Text(
            '$rowCount row${rowCount == 1 ? '' : 's'}',
            style: const TextStyle(
              fontSize: 11,
              color: CodeOpsColors.textSecondary,
            ),
          ),
          const Spacer(),
          if (executionTime > 0)
            Text(
              '${executionTime}ms',
              style: const TextStyle(
                fontSize: 11,
                color: CodeOpsColors.textTertiary,
              ),
            ),
        ],
      ),
    );
  }

  /// Returns the icon for a query status.
  IconData _statusIcon(QueryStatus status) => switch (status) {
        QueryStatus.running => Icons.hourglass_empty,
        QueryStatus.completed => Icons.check_circle_outline,
        QueryStatus.failed => Icons.error_outline,
        QueryStatus.cancelled => Icons.cancel_outlined,
      };

  /// Returns the color for a query status.
  Color _statusColor(QueryStatus status) => switch (status) {
        QueryStatus.running => CodeOpsColors.primary,
        QueryStatus.completed => CodeOpsColors.success,
        QueryStatus.failed => CodeOpsColors.error,
        QueryStatus.cancelled => CodeOpsColors.warning,
      };
}
