/// Service for executing SQL queries against databases in DataLens.
///
/// Handles SELECT, DML, and DDL queries, builds [QueryResult] objects with
/// column metadata and row data, supports pagination, table browsing,
/// EXPLAIN plans, and query cancellation. Every execution is recorded
/// in [QueryHistoryService].
///
/// Uses [DatabaseDriverAdapter] for database-agnostic query execution,
/// supporting PostgreSQL, MySQL, MariaDB, SQLite, and SQL Server.
library;

import '../../models/datalens_enums.dart';
import '../../models/datalens_models.dart';
import '../logging/log_service.dart';
import 'database_connection_service.dart';
import 'drivers/database_driver.dart';
import 'query_history_service.dart';

/// Executes SQL queries and records results in history.
///
/// Obtains active [DatabaseDriverAdapter] instances from
/// [DatabaseConnectionService] and delegates history persistence to
/// [QueryHistoryService]. Supports transaction control: auto-commit
/// mode (default) or manual BEGIN/COMMIT/ROLLBACK.
class QueryExecutionService {
  static const String _tag = 'QueryExecutionService';

  /// The connection service used to obtain active driver adapters.
  final DatabaseConnectionService _connectionService;

  /// The history service used to record query executions.
  final QueryHistoryService _historyService;

  /// Tracks which connections have an active transaction.
  final Map<String, bool> _transactionActive = {};

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
    final driver = _requireDriver(connectionId);
    final stopwatch = Stopwatch()..start();

    try {
      final result = await driver.execute(sql);
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

  /// Executes a query with pagination.
  ///
  /// Delegates pagination syntax to the driver adapter, which applies the
  /// engine-specific pagination (LIMIT/OFFSET for PostgreSQL/MySQL/SQLite,
  /// OFFSET FETCH for SQL Server).
  ///
  /// Throws [StateError] if no active connection exists for [connectionId].
  Future<QueryResult> executePagedQuery(
    String connectionId,
    String sql, {
    int limit = 100,
    int offset = 0,
  }) async {
    log.d(_tag, 'executePagedQuery($connectionId, limit=$limit, offset=$offset)');
    final driver = _requireDriver(connectionId);
    final stopwatch = Stopwatch()..start();

    try {
      // Count total rows.
      final countResult = await driver.execute(
        'SELECT COUNT(*) FROM ($sql) AS _count_query',
      );
      final totalRows =
          countResult.rows.isNotEmpty && countResult.rows.first.isNotEmpty
              ? _toInt(countResult.rows.first.first)
              : 0;

      // Execute the paged query.
      final result = await driver.executePaged(
        sql,
        limit: limit,
        offset: offset,
      );
      stopwatch.stop();

      final queryResult = _buildResult(
        result,
        sql,
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
  /// Uses the driver's dialect to quote identifiers appropriately for the
  /// target database engine.
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
    final driver = _requireDriver(connectionId);

    final qualifiedTable = driver.dialect.qualifyTable(schemaName, tableName);
    final buffer = StringBuffer('SELECT * FROM $qualifiedTable');
    if (whereClause != null && whereClause.isNotEmpty) {
      buffer.write(' WHERE $whereClause');
    }
    if (orderBy != null && orderBy.isNotEmpty) {
      buffer.write(' ORDER BY ${driver.dialect.quoteIdentifier(orderBy)}');
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
  /// Delegates to the driver's engine-specific cancellation mechanism.
  /// Returns `true` if the cancellation was sent successfully.
  ///
  /// Throws [StateError] if no active connection exists for [connectionId].
  Future<bool> cancelQuery(String connectionId) async {
    log.i(_tag, 'cancelQuery($connectionId)');
    final driver = _requireDriver(connectionId);
    return driver.cancelQuery();
  }

  /// Returns the EXPLAIN plan for the given [sql].
  ///
  /// When [analyze] is `true`, prepends `EXPLAIN ANALYZE` (which actually
  /// executes the query); otherwise prepends `EXPLAIN` only.
  /// Returns an empty string if the engine does not support EXPLAIN.
  ///
  /// Throws [StateError] if no active connection exists for [connectionId].
  Future<String> explainQuery(
    String connectionId,
    String sql, {
    bool analyze = false,
  }) async {
    log.d(_tag, 'explainQuery($connectionId, analyze=$analyze)');
    final driver = _requireDriver(connectionId);
    return driver.explainQuery(sql, analyze: analyze);
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
    final driver = _requireDriver(connectionId);

    final qualifiedTable = driver.dialect.qualifyTable(schemaName, tableName);
    final buffer = StringBuffer('SELECT COUNT(*) FROM $qualifiedTable');
    if (whereClause != null && whereClause.isNotEmpty) {
      buffer.write(' WHERE $whereClause');
    }

    final result = await driver.execute(buffer.toString());
    if (result.rows.isNotEmpty && result.rows.first.isNotEmpty) {
      return _toInt(result.rows.first.first) ?? 0;
    }
    return 0;
  }

  // ---------------------------------------------------------------------------
  // Transaction Control
  // ---------------------------------------------------------------------------

  /// Begins a new transaction on the given connection.
  ///
  /// Executes `BEGIN` and marks the connection as having an active
  /// transaction. No-op if a transaction is already active.
  ///
  /// Throws [StateError] if no active connection exists for [connectionId].
  Future<void> beginTransaction(String connectionId) async {
    if (isTransactionActive(connectionId)) return;
    log.i(_tag, 'BEGIN transaction on $connectionId');
    final driver = _requireDriver(connectionId);
    await driver.execute('BEGIN');
    _transactionActive[connectionId] = true;
  }

  /// Commits the active transaction on the given connection.
  ///
  /// Executes `COMMIT` and clears the transaction-active flag.
  ///
  /// Throws [StateError] if no active connection or no active transaction.
  Future<void> commit(String connectionId) async {
    if (!isTransactionActive(connectionId)) {
      throw StateError('No active transaction on $connectionId');
    }
    log.i(_tag, 'COMMIT on $connectionId');
    final driver = _requireDriver(connectionId);
    await driver.execute('COMMIT');
    _transactionActive[connectionId] = false;
  }

  /// Rolls back the active transaction on the given connection.
  ///
  /// Executes `ROLLBACK` and clears the transaction-active flag.
  ///
  /// Throws [StateError] if no active connection or no active transaction.
  Future<void> rollback(String connectionId) async {
    if (!isTransactionActive(connectionId)) {
      throw StateError('No active transaction on $connectionId');
    }
    log.i(_tag, 'ROLLBACK on $connectionId');
    final driver = _requireDriver(connectionId);
    await driver.execute('ROLLBACK');
    _transactionActive[connectionId] = false;
  }

  /// Returns whether a transaction is currently active on [connectionId].
  bool isTransactionActive(String connectionId) {
    return _transactionActive[connectionId] ?? false;
  }

  /// Auto-rollbacks any active transaction on disconnect.
  ///
  /// Should be called when a connection is about to be closed. Issues
  /// a best-effort ROLLBACK if a transaction is active.
  Future<void> autoRollbackOnDisconnect(String connectionId) async {
    if (!isTransactionActive(connectionId)) return;
    log.w(_tag, 'Auto-rollback on disconnect for $connectionId');
    try {
      final driver = _connectionService.getDriver(connectionId);
      if (driver != null) {
        await driver.execute('ROLLBACK');
      }
    } on Object catch (e) {
      log.e(_tag, 'Auto-rollback failed for $connectionId', e);
    }
    _transactionActive.remove(connectionId);
  }

  // ---------------------------------------------------------------------------
  // Internal Helpers
  // ---------------------------------------------------------------------------

  /// Returns the active driver or throws [StateError].
  DatabaseDriverAdapter _requireDriver(String connectionId) {
    final driver = _connectionService.getDriver(connectionId);
    if (driver == null) {
      throw StateError('No active connection for $connectionId');
    }
    return driver;
  }

  /// Builds a [QueryResult] from a [DriverQueryResult].
  QueryResult _buildResult(
    DriverQueryResult result,
    String sql,
    int executionTimeMs, {
    int? totalRows,
  }) {
    final isSelect = _isSelectQuery(sql);

    if (isSelect && result.columnNames.isNotEmpty) {
      final columns = <QueryColumn>[];
      for (var i = 0; i < result.columnNames.length; i++) {
        columns.add(QueryColumn(
          name: result.columnNames[i],
          typeName: i < result.columnTypes.length
              ? result.columnTypes[i]
              : null,
        ));
      }

      return QueryResult(
        columns: columns,
        rows: result.rows,
        rowCount: result.rows.length,
        totalRows: totalRows ?? result.rows.length,
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

  /// Safely converts a value to [int].
  int? _toInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}
