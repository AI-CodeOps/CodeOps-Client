/// SQL autocomplete service for the DataLens SQL editor.
///
/// Builds context-aware completion lists from database metadata (schemas,
/// tables, columns) and static SQL knowledge (keywords, functions, types).
/// Caches metadata per connection and refreshes on schema change.
library;

import '../../models/datalens_models.dart';
import '../logging/log_service.dart';
import 'schema_introspection_service.dart';

// ---------------------------------------------------------------------------
// CompletionItem
// ---------------------------------------------------------------------------

/// The kind of SQL completion item.
enum CompletionKind {
  /// SQL keyword (SELECT, FROM, WHERE, etc.).
  keyword,

  /// Database table name.
  table,

  /// Table column name.
  column,

  /// SQL function (COUNT, SUM, etc.).
  function_,

  /// Database schema name.
  schema,

  /// SQL data type (INTEGER, VARCHAR, etc.).
  dataType,
}

/// A single autocomplete suggestion for the SQL editor.
class CompletionItem {
  /// Display label shown in the dropdown.
  final String label;

  /// Text inserted when the completion is accepted.
  final String insertText;

  /// Kind of completion (keyword, table, column, etc.).
  final CompletionKind kind;

  /// Optional detail text (e.g., data type for columns).
  final String? detail;

  /// Sort priority (lower = higher priority).
  final int sortPriority;

  /// Creates a [CompletionItem].
  const CompletionItem({
    required this.label,
    required this.insertText,
    required this.kind,
    this.detail,
    this.sortPriority = 100,
  });
}

// ---------------------------------------------------------------------------
// SqlAutocompleteService
// ---------------------------------------------------------------------------

/// Provides context-aware SQL completions from database metadata.
///
/// Caches schema, table, and column metadata per connection. Completions
/// are context-sensitive: after `FROM` or `JOIN`, table names are suggested;
/// after `SELECT` or `WHERE`, column names for tables in the query are
/// suggested; after `.`, columns for the preceding table are suggested.
class SqlAutocompleteService {
  static const String _tag = 'SqlAutocompleteService';

  final SchemaIntrospectionService _schemaService;

  /// Cached schema names per connection.
  final Map<String, List<String>> _schemaCache = {};

  /// Cached table names per connection, keyed as `connectionId`.
  /// Value is a map of `schemaName` -> list of table names.
  final Map<String, Map<String, List<String>>> _tableCache = {};

  /// Cached column info per connection, keyed as `connectionId`.
  /// Value is a map of `schemaName.tableName` -> list of ColumnInfo.
  final Map<String, Map<String, List<ColumnInfo>>> _columnCache = {};

  /// Creates a [SqlAutocompleteService].
  SqlAutocompleteService(SchemaIntrospectionService schemaService)
      : _schemaService = schemaService;

  /// Returns context-aware completions for the given SQL at [cursorOffset].
  ///
  /// Analyzes the text before the cursor to determine context (after FROM,
  /// after SELECT, after dot, etc.) and returns matching completions.
  Future<List<CompletionItem>> getCompletions(
    String sql,
    int cursorOffset,
    String connectionId,
  ) async {
    log.d(_tag, 'getCompletions(offset=$cursorOffset, conn=$connectionId)');

    // Extract the word being typed at cursor position.
    final textBeforeCursor = sql.substring(0, cursorOffset.clamp(0, sql.length));
    final currentWord = _extractCurrentWord(textBeforeCursor);
    final context = _analyzeContext(textBeforeCursor);

    final completions = <CompletionItem>[];

    switch (context) {
      case _SqlContext.afterDot:
        // After `tableName.` — suggest columns for that table.
        final tableName = _extractTableBeforeDot(textBeforeCursor);
        if (tableName != null) {
          final columns = await _getColumnsForTable(
            connectionId,
            tableName,
            _extractTablesFromQuery(sql),
          );
          completions.addAll(columns);
        }

      case _SqlContext.afterFrom || _SqlContext.afterJoin:
        // After FROM or JOIN — suggest table names.
        await _ensureTablesLoaded(connectionId);
        completions.addAll(_getTableCompletions(connectionId));
        completions.addAll(_getSchemaCompletions(connectionId));

      case _SqlContext.afterSelect || _SqlContext.afterWhere:
        // After SELECT or WHERE — suggest columns for tables in query.
        final tablesInQuery = _extractTablesFromQuery(sql);
        for (final table in tablesInQuery) {
          final columns = await _getColumnsForTable(
            connectionId,
            table,
            tablesInQuery,
          );
          completions.addAll(columns);
        }
        completions.addAll(_sqlKeywordCompletions);
        completions.addAll(_sqlFunctionCompletions);

      case _SqlContext.general:
        // General context — suggest everything.
        completions.addAll(_sqlKeywordCompletions);
        completions.addAll(_sqlFunctionCompletions);
        completions.addAll(_sqlDataTypeCompletions);
        await _ensureTablesLoaded(connectionId);
        completions.addAll(_getTableCompletions(connectionId));
        completions.addAll(_getSchemaCompletions(connectionId));
    }

    // Filter by current word (fuzzy match).
    if (currentWord.isEmpty) return completions;

    final filtered = completions
        .where((c) => _fuzzyMatch(c.label, currentWord))
        .toList()
      ..sort((a, b) {
        // Prioritize prefix matches over fuzzy.
        final aPrefix =
            a.label.toLowerCase().startsWith(currentWord.toLowerCase());
        final bPrefix =
            b.label.toLowerCase().startsWith(currentWord.toLowerCase());
        if (aPrefix && !bPrefix) return -1;
        if (!aPrefix && bPrefix) return 1;
        return a.sortPriority.compareTo(b.sortPriority);
      });

    return filtered;
  }

  /// Clears all cached metadata for a connection.
  ///
  /// Call when the schema changes or the connection is reset.
  void clearCache(String connectionId) {
    _schemaCache.remove(connectionId);
    _tableCache.remove(connectionId);
    _columnCache.remove(connectionId);
    log.d(_tag, 'Cache cleared for $connectionId');
  }

  /// Clears all caches.
  void clearAllCaches() {
    _schemaCache.clear();
    _tableCache.clear();
    _columnCache.clear();
  }

  // ---------------------------------------------------------------------------
  // Schema / Table / Column loading
  // ---------------------------------------------------------------------------

  /// Ensures schemas and tables are loaded for the connection.
  Future<void> _ensureTablesLoaded(String connectionId) async {
    if (_tableCache.containsKey(connectionId)) return;

    try {
      final schemas = await _schemaService.getSchemas(connectionId);
      _schemaCache[connectionId] =
          schemas.map((s) => s.name).whereType<String>().toList();

      final tableMap = <String, List<String>>{};
      for (final schema in schemas) {
        if (schema.name == null) continue;
        final tables =
            await _schemaService.getTables(connectionId, schema.name!);
        tableMap[schema.name!] = tables
            .map((t) => t.tableName)
            .whereType<String>()
            .toList();
      }
      _tableCache[connectionId] = tableMap;
    } on Object catch (e) {
      log.w(_tag, 'Failed to load tables for $connectionId', e);
    }
  }

  /// Returns column completions for a specific table.
  Future<List<CompletionItem>> _getColumnsForTable(
    String connectionId,
    String tableName,
    Set<String> tablesInQuery,
  ) async {
    // Try to find the table in cache across all schemas.
    final cacheKey = _findTableCacheKey(connectionId, tableName);
    if (cacheKey != null && _columnCache[connectionId]?[cacheKey] != null) {
      return _columnCache[connectionId]![cacheKey]!
          .map((col) => CompletionItem(
                label: col.columnName ?? '',
                insertText: col.columnName ?? '',
                kind: CompletionKind.column,
                detail: col.dataType ?? col.udtName,
                sortPriority: 10,
              ))
          .toList();
    }

    // Load columns from schema service.
    await _ensureTablesLoaded(connectionId);
    final tableMap = _tableCache[connectionId] ?? {};

    for (final entry in tableMap.entries) {
      final schemaName = entry.key;
      if (entry.value.contains(tableName)) {
        try {
          final columns = await _schemaService.getColumns(
            connectionId,
            schemaName,
            tableName,
          );
          final key = '$schemaName.$tableName';
          _columnCache.putIfAbsent(connectionId, () => {});
          _columnCache[connectionId]![key] = columns;

          return columns
              .map((col) => CompletionItem(
                    label: col.columnName ?? '',
                    insertText: col.columnName ?? '',
                    kind: CompletionKind.column,
                    detail: col.dataType ?? col.udtName,
                    sortPriority: 10,
                  ))
              .toList();
        } on Object catch (e) {
          log.w(_tag, 'Failed to load columns for $schemaName.$tableName', e);
        }
      }
    }

    return [];
  }

  /// Finds the cache key for a table name across schemas.
  String? _findTableCacheKey(String connectionId, String tableName) {
    final colCache = _columnCache[connectionId];
    if (colCache == null) return null;

    for (final key in colCache.keys) {
      if (key.endsWith('.$tableName')) return key;
    }
    return null;
  }

  /// Returns table completion items from cache.
  List<CompletionItem> _getTableCompletions(String connectionId) {
    final tableMap = _tableCache[connectionId] ?? {};
    final items = <CompletionItem>[];
    for (final entry in tableMap.entries) {
      for (final table in entry.value) {
        items.add(CompletionItem(
          label: table,
          insertText: table,
          kind: CompletionKind.table,
          detail: entry.key,
          sortPriority: 20,
        ));
      }
    }
    return items;
  }

  /// Returns schema completion items from cache.
  List<CompletionItem> _getSchemaCompletions(String connectionId) {
    final schemas = _schemaCache[connectionId] ?? [];
    return schemas
        .map((s) => CompletionItem(
              label: s,
              insertText: s,
              kind: CompletionKind.schema,
              sortPriority: 30,
            ))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // SQL Context Analysis
  // ---------------------------------------------------------------------------

  /// Analyzes the SQL text before the cursor to determine completion context.
  _SqlContext _analyzeContext(String textBeforeCursor) {
    final trimmed = textBeforeCursor.trimRight();

    // After dot: `tableName.`
    if (trimmed.endsWith('.')) return _SqlContext.afterDot;

    // Find the last major keyword before cursor.
    final upper = trimmed.toUpperCase();
    final lastFrom = upper.lastIndexOf(RegExp(r'\bFROM\b'));
    final lastJoin = upper.lastIndexOf(RegExp(r'\bJOIN\b'));
    final lastSelect = upper.lastIndexOf(RegExp(r'\bSELECT\b'));
    final lastWhere = upper.lastIndexOf(RegExp(r'\bWHERE\b'));

    final maxKeyword = [lastFrom, lastJoin, lastSelect, lastWhere]
        .reduce((a, b) => a > b ? a : b);

    if (maxKeyword < 0) return _SqlContext.general;

    if (maxKeyword == lastFrom) return _SqlContext.afterFrom;
    if (maxKeyword == lastJoin) return _SqlContext.afterJoin;
    if (maxKeyword == lastWhere) return _SqlContext.afterWhere;
    if (maxKeyword == lastSelect) return _SqlContext.afterSelect;

    return _SqlContext.general;
  }

  /// Extracts the current word being typed at the cursor position.
  String _extractCurrentWord(String textBeforeCursor) {
    final match =
        RegExp(r'[\w]+$').firstMatch(textBeforeCursor);
    return match?.group(0) ?? '';
  }

  /// Extracts the table name before a dot (e.g., `users.` → `users`).
  String? _extractTableBeforeDot(String textBeforeCursor) {
    final match =
        RegExp(r'(\w+)\.\s*$').firstMatch(textBeforeCursor);
    return match?.group(1);
  }

  /// Extracts table names referenced in FROM/JOIN clauses.
  Set<String> _extractTablesFromQuery(String sql) {
    final tables = <String>{};

    // Match FROM tableName and JOIN tableName patterns.
    final fromPattern =
        RegExp(r'\b(?:FROM|JOIN)\s+(\w+)', caseSensitive: false);
    for (final match in fromPattern.allMatches(sql)) {
      final table = match.group(1);
      if (table != null) tables.add(table);
    }

    return tables;
  }

  /// Returns true if [text] fuzzy-matches [query].
  bool _fuzzyMatch(String text, String query) {
    final lower = text.toLowerCase();
    final queryLower = query.toLowerCase();

    // Prefix match.
    if (lower.startsWith(queryLower)) return true;

    // Substring match.
    if (lower.contains(queryLower)) return true;

    // Character-by-character fuzzy match.
    var qi = 0;
    for (var i = 0; i < lower.length && qi < queryLower.length; i++) {
      if (lower[i] == queryLower[qi]) qi++;
    }
    return qi == queryLower.length;
  }

  // ---------------------------------------------------------------------------
  // Static Completion Data
  // ---------------------------------------------------------------------------

  /// SQL keyword completions.
  static const List<CompletionItem> _sqlKeywordCompletions = [
    CompletionItem(label: 'SELECT', insertText: 'SELECT', kind: CompletionKind.keyword, sortPriority: 50),
    CompletionItem(label: 'FROM', insertText: 'FROM', kind: CompletionKind.keyword, sortPriority: 50),
    CompletionItem(label: 'WHERE', insertText: 'WHERE', kind: CompletionKind.keyword, sortPriority: 50),
    CompletionItem(label: 'AND', insertText: 'AND', kind: CompletionKind.keyword, sortPriority: 50),
    CompletionItem(label: 'OR', insertText: 'OR', kind: CompletionKind.keyword, sortPriority: 50),
    CompletionItem(label: 'INSERT INTO', insertText: 'INSERT INTO', kind: CompletionKind.keyword, sortPriority: 50),
    CompletionItem(label: 'UPDATE', insertText: 'UPDATE', kind: CompletionKind.keyword, sortPriority: 50),
    CompletionItem(label: 'DELETE FROM', insertText: 'DELETE FROM', kind: CompletionKind.keyword, sortPriority: 50),
    CompletionItem(label: 'JOIN', insertText: 'JOIN', kind: CompletionKind.keyword, sortPriority: 50),
    CompletionItem(label: 'LEFT JOIN', insertText: 'LEFT JOIN', kind: CompletionKind.keyword, sortPriority: 50),
    CompletionItem(label: 'RIGHT JOIN', insertText: 'RIGHT JOIN', kind: CompletionKind.keyword, sortPriority: 50),
    CompletionItem(label: 'INNER JOIN', insertText: 'INNER JOIN', kind: CompletionKind.keyword, sortPriority: 50),
    CompletionItem(label: 'FULL JOIN', insertText: 'FULL JOIN', kind: CompletionKind.keyword, sortPriority: 50),
    CompletionItem(label: 'CROSS JOIN', insertText: 'CROSS JOIN', kind: CompletionKind.keyword, sortPriority: 50),
    CompletionItem(label: 'ON', insertText: 'ON', kind: CompletionKind.keyword, sortPriority: 50),
    CompletionItem(label: 'AS', insertText: 'AS', kind: CompletionKind.keyword, sortPriority: 50),
    CompletionItem(label: 'ORDER BY', insertText: 'ORDER BY', kind: CompletionKind.keyword, sortPriority: 50),
    CompletionItem(label: 'GROUP BY', insertText: 'GROUP BY', kind: CompletionKind.keyword, sortPriority: 50),
    CompletionItem(label: 'HAVING', insertText: 'HAVING', kind: CompletionKind.keyword, sortPriority: 50),
    CompletionItem(label: 'LIMIT', insertText: 'LIMIT', kind: CompletionKind.keyword, sortPriority: 50),
    CompletionItem(label: 'OFFSET', insertText: 'OFFSET', kind: CompletionKind.keyword, sortPriority: 50),
    CompletionItem(label: 'DISTINCT', insertText: 'DISTINCT', kind: CompletionKind.keyword, sortPriority: 50),
    CompletionItem(label: 'UNION', insertText: 'UNION', kind: CompletionKind.keyword, sortPriority: 50),
    CompletionItem(label: 'UNION ALL', insertText: 'UNION ALL', kind: CompletionKind.keyword, sortPriority: 50),
    CompletionItem(label: 'IN', insertText: 'IN', kind: CompletionKind.keyword, sortPriority: 50),
    CompletionItem(label: 'NOT', insertText: 'NOT', kind: CompletionKind.keyword, sortPriority: 50),
    CompletionItem(label: 'NULL', insertText: 'NULL', kind: CompletionKind.keyword, sortPriority: 50),
    CompletionItem(label: 'IS NULL', insertText: 'IS NULL', kind: CompletionKind.keyword, sortPriority: 50),
    CompletionItem(label: 'IS NOT NULL', insertText: 'IS NOT NULL', kind: CompletionKind.keyword, sortPriority: 50),
    CompletionItem(label: 'BETWEEN', insertText: 'BETWEEN', kind: CompletionKind.keyword, sortPriority: 50),
    CompletionItem(label: 'LIKE', insertText: 'LIKE', kind: CompletionKind.keyword, sortPriority: 50),
    CompletionItem(label: 'EXISTS', insertText: 'EXISTS', kind: CompletionKind.keyword, sortPriority: 50),
    CompletionItem(label: 'CASE', insertText: 'CASE', kind: CompletionKind.keyword, sortPriority: 50),
    CompletionItem(label: 'WHEN', insertText: 'WHEN', kind: CompletionKind.keyword, sortPriority: 50),
    CompletionItem(label: 'THEN', insertText: 'THEN', kind: CompletionKind.keyword, sortPriority: 50),
    CompletionItem(label: 'ELSE', insertText: 'ELSE', kind: CompletionKind.keyword, sortPriority: 50),
    CompletionItem(label: 'END', insertText: 'END', kind: CompletionKind.keyword, sortPriority: 50),
    CompletionItem(label: 'ASC', insertText: 'ASC', kind: CompletionKind.keyword, sortPriority: 50),
    CompletionItem(label: 'DESC', insertText: 'DESC', kind: CompletionKind.keyword, sortPriority: 50),
    CompletionItem(label: 'CREATE TABLE', insertText: 'CREATE TABLE', kind: CompletionKind.keyword, sortPriority: 50),
    CompletionItem(label: 'ALTER TABLE', insertText: 'ALTER TABLE', kind: CompletionKind.keyword, sortPriority: 50),
    CompletionItem(label: 'DROP TABLE', insertText: 'DROP TABLE', kind: CompletionKind.keyword, sortPriority: 50),
    CompletionItem(label: 'SET', insertText: 'SET', kind: CompletionKind.keyword, sortPriority: 50),
    CompletionItem(label: 'VALUES', insertText: 'VALUES', kind: CompletionKind.keyword, sortPriority: 50),
    CompletionItem(label: 'CASCADE', insertText: 'CASCADE', kind: CompletionKind.keyword, sortPriority: 50),
    CompletionItem(label: 'BEGIN', insertText: 'BEGIN', kind: CompletionKind.keyword, sortPriority: 50),
    CompletionItem(label: 'COMMIT', insertText: 'COMMIT', kind: CompletionKind.keyword, sortPriority: 50),
    CompletionItem(label: 'ROLLBACK', insertText: 'ROLLBACK', kind: CompletionKind.keyword, sortPriority: 50),
  ];

  /// SQL function completions.
  static const List<CompletionItem> _sqlFunctionCompletions = [
    CompletionItem(label: 'COUNT', insertText: 'COUNT()', kind: CompletionKind.function_, detail: 'Aggregate', sortPriority: 40),
    CompletionItem(label: 'SUM', insertText: 'SUM()', kind: CompletionKind.function_, detail: 'Aggregate', sortPriority: 40),
    CompletionItem(label: 'AVG', insertText: 'AVG()', kind: CompletionKind.function_, detail: 'Aggregate', sortPriority: 40),
    CompletionItem(label: 'MIN', insertText: 'MIN()', kind: CompletionKind.function_, detail: 'Aggregate', sortPriority: 40),
    CompletionItem(label: 'MAX', insertText: 'MAX()', kind: CompletionKind.function_, detail: 'Aggregate', sortPriority: 40),
    CompletionItem(label: 'COALESCE', insertText: 'COALESCE()', kind: CompletionKind.function_, detail: 'Conditional', sortPriority: 40),
    CompletionItem(label: 'NULLIF', insertText: 'NULLIF()', kind: CompletionKind.function_, detail: 'Conditional', sortPriority: 40),
    CompletionItem(label: 'CAST', insertText: 'CAST( AS )', kind: CompletionKind.function_, detail: 'Type cast', sortPriority: 40),
    CompletionItem(label: 'UPPER', insertText: 'UPPER()', kind: CompletionKind.function_, detail: 'String', sortPriority: 40),
    CompletionItem(label: 'LOWER', insertText: 'LOWER()', kind: CompletionKind.function_, detail: 'String', sortPriority: 40),
    CompletionItem(label: 'TRIM', insertText: 'TRIM()', kind: CompletionKind.function_, detail: 'String', sortPriority: 40),
    CompletionItem(label: 'LENGTH', insertText: 'LENGTH()', kind: CompletionKind.function_, detail: 'String', sortPriority: 40),
    CompletionItem(label: 'SUBSTRING', insertText: 'SUBSTRING()', kind: CompletionKind.function_, detail: 'String', sortPriority: 40),
    CompletionItem(label: 'NOW', insertText: 'NOW()', kind: CompletionKind.function_, detail: 'Date/Time', sortPriority: 40),
    CompletionItem(label: 'CURRENT_TIMESTAMP', insertText: 'CURRENT_TIMESTAMP', kind: CompletionKind.function_, detail: 'Date/Time', sortPriority: 40),
    CompletionItem(label: 'CURRENT_DATE', insertText: 'CURRENT_DATE', kind: CompletionKind.function_, detail: 'Date/Time', sortPriority: 40),
    CompletionItem(label: 'EXTRACT', insertText: 'EXTRACT( FROM )', kind: CompletionKind.function_, detail: 'Date/Time', sortPriority: 40),
    CompletionItem(label: 'ARRAY_AGG', insertText: 'ARRAY_AGG()', kind: CompletionKind.function_, detail: 'Aggregate', sortPriority: 40),
    CompletionItem(label: 'STRING_AGG', insertText: 'STRING_AGG()', kind: CompletionKind.function_, detail: 'Aggregate', sortPriority: 40),
    CompletionItem(label: 'ROW_NUMBER', insertText: 'ROW_NUMBER() OVER ()', kind: CompletionKind.function_, detail: 'Window', sortPriority: 40),
    CompletionItem(label: 'RANK', insertText: 'RANK() OVER ()', kind: CompletionKind.function_, detail: 'Window', sortPriority: 40),
  ];

  /// SQL data type completions.
  static const List<CompletionItem> _sqlDataTypeCompletions = [
    CompletionItem(label: 'INTEGER', insertText: 'INTEGER', kind: CompletionKind.dataType, sortPriority: 60),
    CompletionItem(label: 'BIGINT', insertText: 'BIGINT', kind: CompletionKind.dataType, sortPriority: 60),
    CompletionItem(label: 'SMALLINT', insertText: 'SMALLINT', kind: CompletionKind.dataType, sortPriority: 60),
    CompletionItem(label: 'SERIAL', insertText: 'SERIAL', kind: CompletionKind.dataType, sortPriority: 60),
    CompletionItem(label: 'BIGSERIAL', insertText: 'BIGSERIAL', kind: CompletionKind.dataType, sortPriority: 60),
    CompletionItem(label: 'VARCHAR', insertText: 'VARCHAR', kind: CompletionKind.dataType, sortPriority: 60),
    CompletionItem(label: 'TEXT', insertText: 'TEXT', kind: CompletionKind.dataType, sortPriority: 60),
    CompletionItem(label: 'BOOLEAN', insertText: 'BOOLEAN', kind: CompletionKind.dataType, sortPriority: 60),
    CompletionItem(label: 'TIMESTAMP', insertText: 'TIMESTAMP', kind: CompletionKind.dataType, sortPriority: 60),
    CompletionItem(label: 'TIMESTAMPTZ', insertText: 'TIMESTAMPTZ', kind: CompletionKind.dataType, sortPriority: 60),
    CompletionItem(label: 'DATE', insertText: 'DATE', kind: CompletionKind.dataType, sortPriority: 60),
    CompletionItem(label: 'NUMERIC', insertText: 'NUMERIC', kind: CompletionKind.dataType, sortPriority: 60),
    CompletionItem(label: 'DECIMAL', insertText: 'DECIMAL', kind: CompletionKind.dataType, sortPriority: 60),
    CompletionItem(label: 'FLOAT', insertText: 'FLOAT', kind: CompletionKind.dataType, sortPriority: 60),
    CompletionItem(label: 'DOUBLE PRECISION', insertText: 'DOUBLE PRECISION', kind: CompletionKind.dataType, sortPriority: 60),
    CompletionItem(label: 'UUID', insertText: 'UUID', kind: CompletionKind.dataType, sortPriority: 60),
    CompletionItem(label: 'JSONB', insertText: 'JSONB', kind: CompletionKind.dataType, sortPriority: 60),
    CompletionItem(label: 'JSON', insertText: 'JSON', kind: CompletionKind.dataType, sortPriority: 60),
    CompletionItem(label: 'BYTEA', insertText: 'BYTEA', kind: CompletionKind.dataType, sortPriority: 60),
  ];
}

/// Internal context classification for SQL completion.
enum _SqlContext {
  /// After a dot — suggest columns for the preceding table.
  afterDot,

  /// After FROM keyword — suggest tables and schemas.
  afterFrom,

  /// After JOIN keyword — suggest tables and schemas.
  afterJoin,

  /// After SELECT keyword — suggest columns and functions.
  afterSelect,

  /// After WHERE keyword — suggest columns and operators.
  afterWhere,

  /// No specific context — suggest everything.
  general,
}
