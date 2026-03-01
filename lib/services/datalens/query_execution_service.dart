/// Service for executing SQL queries against PostgreSQL in DataLens.
///
/// Handles SELECT, DML, and DDL queries, builds [QueryResult] objects with
/// column metadata and row data, supports pagination, table browsing,
/// EXPLAIN plans, and query cancellation. Every execution is recorded
/// in [QueryHistoryService].
library;

import 'package:postgres/postgres.dart' as pg;

import '../../models/datalens_enums.dart';
import '../../models/datalens_models.dart';
import '../logging/log_service.dart';
import 'database_connection_service.dart';
import 'query_history_service.dart';

/// Executes SQL queries and records results in history.
///
/// Obtains live [pg.Connection] instances from [DatabaseConnectionService]
/// and delegates history persistence to [QueryHistoryService].
class QueryExecutionService {
  static const String _tag = 'QueryExecutionService';

  /// The connection service used to obtain active [pg.Connection] instances.
  final DatabaseConnectionService _connectionService;

  /// The history service used to record query executions.
  final QueryHistoryService _historyService;

  /// Creates a [QueryExecutionService] with the given dependencies.
  QueryExecutionService(
    DatabaseConnectionService connectionService,
    QueryHistoryService historyService,
  )   : _connectionService = connectionService,
        _historyService = historyService;

  // ---------------------------------------------------------------------------
  // Query Execution
  // ---------------------------------------------------------------------------

  /// Executes a raw SQL query and returns a [QueryResult].
  ///
  /// Detects the query type by inspecting the first keyword:
  /// - **SELECT** queries return column metadata and row data.
  /// - **DML** (INSERT/UPDATE/DELETE) queries return affected row count.
  /// - **DDL** and other statements return a success result.
  ///
  /// Every execution is recorded in query history regardless of outcome.
  ///
  /// Throws [StateError] if no active connection exists for [connectionId].
  Future<QueryResult> executeQuery(
    String connectionId,
    String sql,
  ) async {
    log.d(_tag, 'executeQuery($connectionId)');
    final conn = _requireConnection(connectionId);
    final stopwatch = Stopwatch()..start();

    try {
      final result = await conn.execute(sql);
      stopwatch.stop();

      final queryResult = _buildResult(result, sql, stopwatch.elapsedMilliseconds);

      await _historyService.recordExecution(
        connectionId: connectionId,
        sql: sql,
        status: QueryStatus.completed,
        rowCount: queryResult.rowCount,
        executionTimeMs: stopwatch.elapsedMilliseconds.toInt(),
      );

      return queryResult;
    } on Exception catch (e) {
      stopwatch.stop();

      await _historyService.recordExecution(
        connectionId: connectionId,
        sql: sql,
        status: QueryStatus.failed,
        executionTimeMs: stopwatch.elapsedMilliseconds.toInt(),
        error: e.toString(),
      );

      return QueryResult(
        status: QueryStatus.failed,
        error: e.toString(),
        executionTimeMs: stopwatch.elapsedMilliseconds.toInt(),
        executedSql: sql,
      );
    }
  }

  /// Executes a query with LIMIT/OFFSET pagination.
  ///
  /// Wraps the given [sql] in a subquery with `LIMIT` and `OFFSET` clauses,
  /// and issues a parallel `COUNT(*)` to determine total rows.
  ///
  /// Throws [StateError] if no active connection exists for [connectionId].
  Future<QueryResult> executePagedQuery(
    String connectionId,
    String sql, {
    int limit = 100,
    int offset = 0,
  }) async {
    log.d(_tag, 'executePagedQuery($connectionId, limit=$limit, offset=$offset)');
    final conn = _requireConnection(connectionId);
    final stopwatch = Stopwatch()..start();

    try {
      // Count total rows.
      final countResult = await conn.execute(
        'SELECT COUNT(*) FROM ($sql) AS _count_query',
      );
      final totalRows = countResult.first.first as int;

      // Execute the paged query.
      final pagedSql = '$sql LIMIT $limit OFFSET $offset';
      final result = await conn.execute(pagedSql);
      stopwatch.stop();

      final queryResult = _buildResult(
        result,
        pagedSql,
        stopwatch.elapsedMilliseconds,
        totalRows: totalRows,
      );

      await _historyService.recordExecution(
        connectionId: connectionId,
        sql: sql,
        status: QueryStatus.completed,
        rowCount: queryResult.rowCount,
        executionTimeMs: stopwatch.elapsedMilliseconds.toInt(),
      );

      return queryResult;
    } on Exception catch (e) {
      stopwatch.stop();

      await _historyService.recordExecution(
        connectionId: connectionId,
        sql: sql,
        status: QueryStatus.failed,
        executionTimeMs: stopwatch.elapsedMilliseconds.toInt(),
        error: e.toString(),
      );

      return QueryResult(
        status: QueryStatus.failed,
        error: e.toString(),
        executionTimeMs: stopwatch.elapsedMilliseconds.toInt(),
        executedSql: sql,
      );
    }
  }

  /// Browses a table with optional filtering, sorting, and pagination.
  ///
  /// Builds a `SELECT * FROM schema.table` query with optional `WHERE`,
  /// `ORDER BY`, `LIMIT`, and `OFFSET` clauses.
  ///
  /// Throws [StateError] if no active connection exists for [connectionId].
  Future<QueryResult> browseTable(
    String connectionId,
    String schemaName,
    String tableName, {
    int limit = 100,
    int offset = 0,
    String? orderBy,
    SortDirection? sortDirection,
    String? whereClause,
  }) async {
    log.d(_tag, 'browseTable($connectionId, $schemaName.$tableName)');

    final qualifiedTable = '"$schemaName"."$tableName"';
    final buffer = StringBuffer('SELECT * FROM $qualifiedTable');
    if (whereClause != null && whereClause.isNotEmpty) {
      buffer.write(' WHERE $whereClause');
    }
    if (orderBy != null && orderBy.isNotEmpty) {
      buffer.write(' ORDER BY "$orderBy"');
      if (sortDirection != null) {
        buffer.write(' ${sortDirection.toJson()}');
      }
    }

    final baseSql = buffer.toString();
    return executePagedQuery(
      connectionId,
      baseSql,
      limit: limit,
      offset: offset,
    );
  }

  /// Cancels any running query on the connection identified by [connectionId].
  ///
  /// Uses `pg_cancel_backend()` with the backend PID obtained from the
  /// active connection. Returns `true` if the cancellation was sent
  /// successfully, `false` otherwise.
  ///
  /// Throws [StateError] if no active connection exists for [connectionId].
  Future<bool> cancelQuery(String connectionId) async {
    log.i(_tag, 'cancelQuery($connectionId)');
    final conn = _requireConnection(connectionId);

    try {
      final pidResult = await conn.execute('SELECT pg_backend_pid()');
      final pid = pidResult.first.first as int;
      final cancelResult = await conn.execute(
        'SELECT pg_cancel_backend($pid)',
      );
      return cancelResult.first.first as bool;
    } on Exception catch (e) {
      log.e(_tag, 'Failed to cancel query on $connectionId', e);
      return false;
    }
  }

  /// Returns the EXPLAIN plan for the given [sql].
  ///
  /// When [analyze] is `true`, prepends `EXPLAIN ANALYZE` (which actually
  /// executes the query); otherwise prepends `EXPLAIN` only.
  ///
  /// Throws [StateError] if no active connection exists for [connectionId].
  Future<String> explainQuery(
    String connectionId,
    String sql, {
    bool analyze = false,
  }) async {
    log.d(_tag, 'explainQuery($connectionId, analyze=$analyze)');
    final conn = _requireConnection(connectionId);

    final prefix = analyze ? 'EXPLAIN ANALYZE' : 'EXPLAIN';
    final result = await conn.execute('$prefix $sql');

    return result.map((row) => row.first as String).join('\n');
  }

  /// Returns the exact row count for a table, with an optional WHERE clause.
  ///
  /// Throws [StateError] if no active connection exists for [connectionId].
  Future<int> countRows(
    String connectionId,
    String schemaName,
    String tableName, {
    String? whereClause,
  }) async {
    log.d(_tag, 'countRows($connectionId, $schemaName.$tableName)');
    final conn = _requireConnection(connectionId);

    final qualifiedTable = '"$schemaName"."$tableName"';
    final buffer = StringBuffer('SELECT COUNT(*) FROM $qualifiedTable');
    if (whereClause != null && whereClause.isNotEmpty) {
      buffer.write(' WHERE $whereClause');
    }

    final result = await conn.execute(buffer.toString());
    return result.first.first as int;
  }

  // ---------------------------------------------------------------------------
  // Internal Helpers
  // ---------------------------------------------------------------------------

  /// Returns the active connection or throws [StateError].
  pg.Connection _requireConnection(String connectionId) {
    final connection = _connectionService.getConnection(connectionId);
    if (connection == null) {
      throw StateError('No active connection for $connectionId');
    }
    return connection;
  }

  /// Builds a [QueryResult] from a [pg.Result].
  ///
  /// For SELECT queries the result contains column metadata and row data.
  /// For DML queries, [affectedRows] is used as the row count.
  QueryResult _buildResult(
    pg.Result result,
    String sql,
    int executionTimeMs, {
    int? totalRows,
  }) {
    final isSelect = _isSelectQuery(sql);

    if (isSelect) {
      final columns = result.schema.columns
          .map((col) => QueryColumn(
                name: col.columnName,
                typeName: col.type.toString(),
                typeOid: col.typeOid,
              ))
          .toList();

      final rows = result.map((row) => row.toList()).toList();

      return QueryResult(
        columns: columns,
        rows: rows,
        rowCount: rows.length,
        totalRows: totalRows ?? rows.length,
        executionTimeMs: executionTimeMs,
        status: QueryStatus.completed,
        executedSql: sql,
      );
    }

    // DML / DDL — no column metadata.
    return QueryResult(
      rowCount: result.affectedRows,
      executionTimeMs: executionTimeMs,
      status: QueryStatus.completed,
      executedSql: sql,
    );
  }

  /// Returns `true` if the SQL statement is a SELECT query.
  bool _isSelectQuery(String sql) {
    final trimmed = sql.trimLeft().toUpperCase();
    return trimmed.startsWith('SELECT') ||
        trimmed.startsWith('WITH') ||
        trimmed.startsWith('TABLE') ||
        trimmed.startsWith('VALUES');
  }
}
