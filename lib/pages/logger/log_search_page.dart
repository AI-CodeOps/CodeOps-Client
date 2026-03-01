/// Log search page with query builder and results table.
///
/// Advanced search page at `/logger/search` providing:
/// - [LoggerSidebar] for sub-page navigation
/// - [QueryBuilder] for visual or DSL query construction
/// - [SearchResultsTable] with sortable, paginated results
/// - [SavedQueriesDropdown] and [QueryHistoryDropdown] for query reuse
/// - Save query dialog for bookmarking queries
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/health_snapshot.dart';
import '../../models/logger_enums.dart';
import '../../models/logger_models.dart';
import '../../providers/logger_providers.dart';
import '../../providers/team_providers.dart' show selectedTeamIdProvider;
import '../../theme/colors.dart';
import '../../widgets/logger/logger_sidebar.dart';
import '../../widgets/logger/query_builder.dart';
import '../../widgets/logger/query_history_dropdown.dart';
import '../../widgets/logger/saved_queries_dropdown.dart';
import '../../widgets/logger/search_results_table.dart';
import '../../widgets/shared/empty_state.dart';

/// The log search page with query builder, results, and query management.
class LogSearchPage extends ConsumerStatefulWidget {
  /// Creates a [LogSearchPage].
  const LogSearchPage({super.key});

  @override
  ConsumerState<LogSearchPage> createState() => _LogSearchPageState();
}

class _LogSearchPageState extends ConsumerState<LogSearchPage> {
  final _queryBuilderKey = GlobalKey<QueryBuilderState>();

  PageResponse<LogEntryResponse>? _searchResults;
  bool _isSearching = false;
  String? _sortColumn;
  bool _sortAscending = true;
  int _currentPage = 0;
  Map<String, dynamic> _lastQuery = {};
  String? _lastDsl;

  /// Executes a structured query.
  Future<void> _executeStructuredSearch(Map<String, dynamic> query) async {
    final teamId = ref.read(selectedTeamIdProvider);
    if (teamId == null) return;

    setState(() {
      _isSearching = true;
      _lastQuery = query;
      _lastDsl = null;
      _currentPage = 0;
    });

    try {
      final api = ref.read(loggerApiProvider);
      final results = await api.queryLogs(
        teamId,
        level: query['level'] != null
            ? LogLevel.values.firstWhere(
                (l) => l.toJson() == query['level'],
                orElse: () => LogLevel.info,
              )
            : null,
        serviceName: query['serviceName'] as String?,
        query: query['query'] as String?,
        correlationId: query['correlationId'] as String?,
        loggerName: query['loggerName'] as String?,
        exceptionClass: query['exceptionClass'] as String?,
        hostName: query['hostName'] as String?,
        startTime: query['startTime'] != null
            ? DateTime.parse(query['startTime'] as String)
            : null,
        endTime: query['endTime'] != null
            ? DateTime.parse(query['endTime'] as String)
            : null,
        page: _currentPage,
      );
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search failed: $e')),
        );
      }
    }
  }

  /// Executes a DSL query.
  Future<void> _executeDslSearch(String dsl) async {
    final teamId = ref.read(selectedTeamIdProvider);
    if (teamId == null) return;

    setState(() {
      _isSearching = true;
      _lastDsl = dsl;
      _lastQuery = {};
      _currentPage = 0;
    });

    try {
      final api = ref.read(loggerApiProvider);
      final results = await api.queryLogsDsl(
        teamId,
        query: dsl,
        page: _currentPage,
      );
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('DSL search failed: $e')),
        );
      }
    }
  }

  /// Re-executes the last query at the given page.
  Future<void> _goToPage(int page) async {
    final teamId = ref.read(selectedTeamIdProvider);
    if (teamId == null) return;

    setState(() {
      _isSearching = true;
      _currentPage = page;
    });

    try {
      final api = ref.read(loggerApiProvider);
      PageResponse<LogEntryResponse> results;

      if (_lastDsl != null) {
        results = await api.queryLogsDsl(
          teamId,
          query: _lastDsl!,
          page: page,
        );
      } else {
        results = await api.queryLogs(
          teamId,
          level: _lastQuery['level'] != null
              ? LogLevel.values.firstWhere(
                  (l) => l.toJson() == _lastQuery['level'],
                  orElse: () => LogLevel.info,
                )
              : null,
          serviceName: _lastQuery['serviceName'] as String?,
          query: _lastQuery['query'] as String?,
          startTime: _lastQuery['startTime'] != null
              ? DateTime.parse(_lastQuery['startTime'] as String)
              : null,
          endTime: _lastQuery['endTime'] != null
              ? DateTime.parse(_lastQuery['endTime'] as String)
              : null,
          page: page,
        );
      }

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
    }
  }

  /// Handles column sort toggle.
  void _handleSort(String column) {
    setState(() {
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        _sortAscending = true;
      }
    });
  }

  /// Shows the save query dialog.
  void _showSaveDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CodeOpsColors.surface,
        title: const Text(
          'Save Query',
          style: TextStyle(color: CodeOpsColors.textPrimary, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(
                color: CodeOpsColors.textPrimary,
                fontSize: 13,
              ),
              decoration: const InputDecoration(
                labelText: 'Query Name',
                labelStyle: TextStyle(color: CodeOpsColors.textSecondary),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: CodeOpsColors.border),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descController,
              style: const TextStyle(
                color: CodeOpsColors.textPrimary,
                fontSize: 13,
              ),
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                labelStyle: TextStyle(color: CodeOpsColors.textSecondary),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: CodeOpsColors.border),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;

              final teamId = ref.read(selectedTeamIdProvider);
              if (teamId == null) return;

              final api = ref.read(loggerApiProvider);
              final queryJson = _lastDsl != null
                  ? jsonEncode({'dsl': _lastDsl})
                  : jsonEncode(_lastQuery);

              await api.createSavedQuery(
                teamId,
                name: name,
                queryJson: queryJson,
                description: descController.text.trim().isEmpty
                    ? null
                    : descController.text.trim(),
                queryDsl: _lastDsl,
              );

              ref.invalidate(loggerSavedQueriesProvider);
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: CodeOpsColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  /// Loads a saved query into the builder.
  void _loadSavedQuery(SavedQueryResponse query) {
    final builderState = _queryBuilderKey.currentState;
    if (builderState == null) return;

    if (query.queryDsl != null && query.queryDsl!.isNotEmpty) {
      builderState.setDsl(query.queryDsl!);
    } else {
      // Try to parse queryJson into conditions.
      try {
        final parsed = jsonDecode(query.queryJson) as Map<String, dynamic>;
        final conditions = <QueryCondition>[];

        for (final entry in parsed.entries) {
          if (entry.key == 'startTime' || entry.key == 'endTime' || entry.key == 'page' || entry.key == 'size') {
            continue;
          }
          conditions.add(QueryCondition(
            field: entry.key == 'query' ? 'message' : entry.key,
            operator: 'equals',
            value: entry.value.toString(),
          ));
        }

        if (conditions.isNotEmpty) {
          builderState.setConditions(conditions);
        }
      } catch (_) {
        // Fall back to DSL mode with the raw JSON.
        builderState.setDsl(query.queryJson);
      }
    }
  }

  /// Re-executes a historical query.
  void _reExecuteHistory(QueryHistoryResponse history) {
    if (history.queryDsl != null && history.queryDsl!.isNotEmpty) {
      _executeDslSearch(history.queryDsl!);
    } else {
      try {
        final parsed =
            jsonDecode(history.queryJson) as Map<String, dynamic>;
        _executeStructuredSearch(parsed);
      } catch (_) {
        _executeDslSearch(history.queryJson);
      }
    }
  }

  /// Deletes a saved query.
  Future<void> _deleteSavedQuery(SavedQueryResponse query) async {
    final api = ref.read(loggerApiProvider);
    await api.deleteSavedQuery(query.id);
    ref.invalidate(loggerSavedQueriesProvider);
  }

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
              subtitle: 'Select a team to search logs.',
            ),
          ),
        ],
      );
    }

    final savedQueriesAsync = ref.watch(loggerSavedQueriesProvider);
    final queryHistoryAsync = ref.watch(loggerQueryHistoryProvider);

    return Row(
      children: [
        const LoggerSidebar(),
        const VerticalDivider(width: 1, color: CodeOpsColors.border),
        Expanded(
          child: Column(
            children: [
              // Header.
              _buildHeader(),

              // Query builder.
              QueryBuilder(
                key: _queryBuilderKey,
                onSearch: _executeStructuredSearch,
                onSearchDsl: _executeDslSearch,
                onSave: _searchResults != null ? _showSaveDialog : null,
              ),

              // Results area.
              Expanded(
                child: _isSearching
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: CodeOpsColors.primary,
                        ),
                      )
                    : _searchResults != null
                        ? SearchResultsTable(
                            results: _searchResults!,
                            sortColumn: _sortColumn,
                            sortAscending: _sortAscending,
                            onSort: _handleSort,
                            onNextPage: _searchResults!.isLast
                                ? null
                                : () => _goToPage(_currentPage + 1),
                            onPreviousPage: _currentPage == 0
                                ? null
                                : () => _goToPage(_currentPage - 1),
                          )
                        : const Center(
                            child: EmptyState(
                              icon: Icons.search,
                              title: 'Search Logs',
                              subtitle:
                                  'Build a query above and click Search to find log entries.',
                            ),
                          ),
              ),

              // Bottom bar with saved queries and history.
              _buildBottomBar(savedQueriesAsync, queryHistoryAsync),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds the top header bar.
  Widget _buildHeader() {
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
            Icons.search,
            color: CodeOpsColors.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          const Text(
            'Log Search',
            style: TextStyle(
              color: CodeOpsColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          if (_searchResults != null)
            Text(
              '${_searchResults!.totalElements} matches',
              style: const TextStyle(
                color: CodeOpsColors.textTertiary,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }

  /// Builds the bottom bar with saved queries and history dropdowns.
  Widget _buildBottomBar(
    AsyncValue<List<SavedQueryResponse>> savedQueriesAsync,
    AsyncValue<PageResponse<QueryHistoryResponse>> queryHistoryAsync,
  ) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: CodeOpsColors.surface,
        border: Border(top: BorderSide(color: CodeOpsColors.border)),
      ),
      child: Row(
        children: [
          // Saved queries dropdown.
          savedQueriesAsync.when(
            data: (queries) => SavedQueriesDropdown(
              queries: queries,
              onLoad: _loadSavedQuery,
              onDelete: _deleteSavedQuery,
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(width: 8),

          // Query history dropdown.
          queryHistoryAsync.when(
            data: (historyPage) => QueryHistoryDropdown(
              history: historyPage.content,
              onReExecute: _reExecuteHistory,
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
