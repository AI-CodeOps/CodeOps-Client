/// Main SQL editor panel for the DataLens module.
///
/// Provides a DBeaver-style SQL editor experience with multi-tab support,
/// a resizable split view (editor top, results bottom), query execution,
/// cancellation, EXPLAIN plans, and basic SQL formatting.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:split_view/split_view.dart';

import '../../models/datalens_enums.dart';
import '../../models/datalens_models.dart';
import '../../providers/datalens_providers.dart';
import '../../theme/colors.dart';
import 'save_query_dialog.dart';
import 'sql_editor_widget.dart';
import 'sql_results_panel.dart';

/// A SQL editor panel with multi-tab support and results display.
///
/// Layout:
/// ```
/// ┌─────────────────────────────────┐
/// │ Tab Bar: [Script 1] [Script 2] [+]
/// ├─────────────────────────────────┤
/// │ SqlEditorWidget (toolbar + editor)
/// ├─────────────────────── (drag) ──┤
/// │ SqlResultsPanel (results/messages/explain)
/// └─────────────────────────────────┘
/// ```
///
/// Each tab maintains its own SQL content, query result, and EXPLAIN output.
class SqlEditorPanel extends ConsumerStatefulWidget {
  /// Creates a [SqlEditorPanel].
  const SqlEditorPanel({super.key});

  @override
  ConsumerState<SqlEditorPanel> createState() => _SqlEditorPanelState();
}

class _SqlEditorPanelState extends ConsumerState<SqlEditorPanel> {
  final List<_SqlTab> _tabs = [];
  int _activeTabIndex = 0;
  int _nextTabNumber = 1;

  @override
  void initState() {
    super.initState();
    _addTab();
  }

  _SqlTab get _activeTab => _tabs[_activeTabIndex];

  @override
  Widget build(BuildContext context) {
    if (_tabs.isEmpty) {
      return const Center(
        child: Text(
          'No editor tabs open',
          style: TextStyle(color: CodeOpsColors.textTertiary, fontSize: 12),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Tab bar
        _buildTabBar(),
        const Divider(height: 1, color: CodeOpsColors.border),

        // Split view: editor (top) + results (bottom)
        Expanded(
          child: SplitView(
            viewMode: SplitViewMode.Vertical,
            gripColor: CodeOpsColors.border,
            gripSize: 4,
            controller: SplitViewController(weights: [0.55, 0.45]),
            children: [
              // Top — editor
              SqlEditorWidget(
                key: ValueKey(_activeTab.id),
                content: _activeTab.content,
                onContentChanged: _onContentChanged,
                onExecute: _executeQuery,
                onCancel: _cancelQuery,
                onSave: _saveQuery,
                onExplain: _explainQuery,
                onFormat: _formatSql,
                isRunning: _activeTab.isRunning,
              ),
              // Bottom — results
              SqlResultsPanel(
                result: _activeTab.lastResult,
                explainOutput: _activeTab.explainOutput,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Tab Bar
  // ─────────────────────────────────────────────────────────────────────────

  /// Builds the horizontal tab bar with close buttons and a [+] button.
  Widget _buildTabBar() {
    return Container(
      height: 36,
      color: CodeOpsColors.surface,
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var i = 0; i < _tabs.length; i++)
                    _buildTabChip(i),
                ],
              ),
            ),
          ),
          // Add tab button
          IconButton(
            icon: const Icon(Icons.add, size: 18),
            onPressed: _addTab,
            color: CodeOpsColors.textSecondary,
            tooltip: 'New SQL tab',
            splashRadius: 16,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  /// Builds a single tab chip.
  Widget _buildTabChip(int index) {
    final tab = _tabs[index];
    final isActive = index == _activeTabIndex;

    return GestureDetector(
      onTap: () => setState(() => _activeTabIndex = index),
      child: Container(
        constraints: const BoxConstraints(minWidth: 80, maxWidth: 200),
        height: 36,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? CodeOpsColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                tab.title,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: isActive
                      ? CodeOpsColors.textPrimary
                      : CodeOpsColors.textSecondary,
                  fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
                ),
              ),
            ),
            if (tab.isDirty) ...[
              const SizedBox(width: 4),
              const Text(
                '\u25CF',
                style: TextStyle(fontSize: 8, color: CodeOpsColors.warning),
              ),
            ],
            const SizedBox(width: 4),
            SizedBox(
              width: 16,
              height: 16,
              child: IconButton(
                icon: const Icon(Icons.close, size: 12),
                onPressed: () => _closeTab(index),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                color: CodeOpsColors.textTertiary,
                tooltip: 'Close tab',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Tab Management
  // ─────────────────────────────────────────────────────────────────────────

  /// Adds a new SQL tab.
  void _addTab() {
    setState(() {
      _tabs.add(_SqlTab(
        id: 'sql-tab-$_nextTabNumber',
        title: 'Script $_nextTabNumber',
      ));
      _activeTabIndex = _tabs.length - 1;
      _nextTabNumber++;
    });
  }

  /// Closes a tab at the given index.
  void _closeTab(int index) {
    if (_tabs.length <= 1) return; // Keep at least one tab.

    setState(() {
      _tabs.removeAt(index);
      if (_activeTabIndex >= _tabs.length) {
        _activeTabIndex = _tabs.length - 1;
      } else if (_activeTabIndex > index) {
        _activeTabIndex--;
      }
    });
  }

  /// Updates the active tab's content on editor change.
  void _onContentChanged(String newContent) {
    _activeTab.content = newContent;
    // Mark dirty if content has changed from initial state.
    setState(() {
      _activeTab.isDirty = true;
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Query Execution
  // ─────────────────────────────────────────────────────────────────────────

  /// Executes the current SQL content.
  Future<void> _executeQuery() async {
    final connectionId = ref.read(selectedConnectionIdProvider);
    if (connectionId == null) return;

    final sql = _activeTab.content.trim();
    if (sql.isEmpty) return;

    setState(() => _activeTab.isRunning = true);

    try {
      final service = ref.read(datalensQueryServiceProvider);
      final result = await service.executeQuery(connectionId, sql);

      if (!mounted) return;

      setState(() {
        _activeTab.lastResult = result;
        _activeTab.isRunning = false;
      });

      // Also publish to the global query result provider.
      ref.read(datalensQueryResultProvider.notifier).state = result;
    } on Object catch (e) {
      if (!mounted) return;

      setState(() {
        _activeTab.lastResult = QueryResult(
          status: QueryStatus.failed,
          error: e.toString(),
          executedSql: sql,
        );
        _activeTab.isRunning = false;
      });
    }
  }

  /// Cancels the running query.
  Future<void> _cancelQuery() async {
    final connectionId = ref.read(selectedConnectionIdProvider);
    if (connectionId == null) return;

    try {
      final service = ref.read(datalensQueryServiceProvider);
      await service.cancelQuery(connectionId);
    } on Object catch (_) {
      // Cancellation is best-effort.
    }

    if (!mounted) return;

    setState(() {
      _activeTab.isRunning = false;
      _activeTab.lastResult = const QueryResult(
        status: QueryStatus.cancelled,
      );
    });
  }

  /// Runs EXPLAIN on the current SQL content.
  Future<void> _explainQuery() async {
    final connectionId = ref.read(selectedConnectionIdProvider);
    if (connectionId == null) return;

    final sql = _activeTab.content.trim();
    if (sql.isEmpty) return;

    setState(() => _activeTab.isRunning = true);

    try {
      final service = ref.read(datalensQueryServiceProvider);
      final output = await service.explainQuery(connectionId, sql);

      if (!mounted) return;

      setState(() {
        _activeTab.explainOutput = output;
        _activeTab.isRunning = false;
      });
    } on Object catch (e) {
      if (!mounted) return;

      setState(() {
        _activeTab.explainOutput = 'EXPLAIN failed: $e';
        _activeTab.isRunning = false;
      });
    }
  }

  /// Opens the save query dialog to persist the current SQL.
  void _saveQuery() {
    final sql = _activeTab.content.trim();
    showDialog<bool>(
      context: context,
      builder: (ctx) => SaveQueryDialog(initialSql: sql),
    ).then((saved) {
      if (saved == true) {
        ref.invalidate(datalensSavedQueriesProvider);
      }
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SQL Formatting
  // ─────────────────────────────────────────────────────────────────────────

  /// Formats the SQL content by uppercasing keywords and adding line breaks.
  void _formatSql() {
    final sql = _activeTab.content;
    if (sql.trim().isEmpty) return;

    final formatted = _basicFormatSql(sql);
    setState(() {
      _activeTab.content = formatted;
      _activeTab.isDirty = true;
    });
  }

  /// Performs basic SQL formatting.
  ///
  /// Uppercases major SQL keywords and inserts newlines before major
  /// clauses for readability.
  static String _basicFormatSql(String sql) {
    var result = sql;

    // Uppercase major keywords.
    const keywords = [
      'SELECT',
      'DISTINCT',
      'FROM',
      'WHERE',
      'AND',
      'OR',
      'NOT',
      'IN',
      'EXISTS',
      'BETWEEN',
      'LIKE',
      'IS',
      'NULL',
      'JOIN',
      'LEFT',
      'RIGHT',
      'INNER',
      'OUTER',
      'CROSS',
      'FULL',
      'ON',
      'AS',
      'ORDER BY',
      'GROUP BY',
      'HAVING',
      'LIMIT',
      'OFFSET',
      'UNION',
      'ALL',
      'INSERT INTO',
      'VALUES',
      'UPDATE',
      'SET',
      'DELETE FROM',
      'CREATE TABLE',
      'ALTER TABLE',
      'DROP TABLE',
      'CASCADE',
      'ASC',
      'DESC',
      'COUNT',
      'SUM',
      'AVG',
      'MIN',
      'MAX',
      'CASE',
      'WHEN',
      'THEN',
      'ELSE',
      'END',
    ];

    for (final kw in keywords) {
      final escaped = kw.replaceAll(' ', r'\s+');
      result = result.replaceAllMapped(
        RegExp('\\b$escaped\\b', caseSensitive: false),
        (m) => kw,
      );
    }

    // Add newlines before major clauses.
    const lineBreakBefore = [
      'SELECT',
      'FROM',
      'WHERE',
      'LEFT JOIN',
      'RIGHT JOIN',
      'INNER JOIN',
      'CROSS JOIN',
      'FULL JOIN',
      'JOIN',
      'ORDER BY',
      'GROUP BY',
      'HAVING',
      'LIMIT',
      'UNION',
    ];

    for (final kw in lineBreakBefore) {
      result = result.replaceAllMapped(
        RegExp('\\s+($kw)\\b'),
        (m) => '\n${m.group(1)}',
      );
    }

    return result.trim();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab State
// ─────────────────────────────────────────────────────────────────────────────

/// Internal state for a single SQL editor tab.
class _SqlTab {
  /// Unique identifier for this tab.
  final String id;

  /// Display title in the tab bar.
  String title;

  /// SQL content being edited.
  String content = '';

  /// Last query result from execution.
  QueryResult? lastResult;

  /// Last EXPLAIN output.
  String? explainOutput;

  /// Whether a query is currently running.
  bool isRunning = false;

  /// Whether the content has unsaved changes.
  bool isDirty = false;

  /// Creates a [_SqlTab].
  _SqlTab({
    required this.id,
    required this.title,
  });
}
