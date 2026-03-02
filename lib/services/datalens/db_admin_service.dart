/// Database administration service for DataLens.
///
/// Provides server-level monitoring and management: active sessions, locks,
/// table statistics, index usage, vacuum status, and server configuration.
/// Uses the driver abstraction to generate database-specific SQL for
/// PostgreSQL, MySQL/MariaDB, SQLite, and SQL Server.
library;

import '../../models/datalens_admin_models.dart';
import '../../models/datalens_enums.dart';
import '../logging/log_service.dart';
import 'database_connection_service.dart';
import 'drivers/database_driver.dart';

/// Service for database administration and monitoring.
///
/// Delegates to the active [DatabaseDriverAdapter] for raw SQL execution
/// and translates [DriverQueryResult] rows into typed admin models.
class DbAdminService {
  static const String _tag = 'DbAdminService';

  final DatabaseConnectionService _connectionService;

  /// Creates a [DbAdminService].
  DbAdminService(this._connectionService);

  // -------------------------------------------------------------------------
  // Active Sessions
  // -------------------------------------------------------------------------

  /// Returns all active sessions / processes on the server.
  Future<List<ActiveSession>> getActiveSessions(String connectionId) async {
    log.d(_tag, 'getActiveSessions($connectionId)');
    final driver = _requireDriver(connectionId);
    final sql = _activeSessionsSql(driver.dialect);
    if (sql == null) return [];

    final result = await driver.execute(sql);
    return result.rows.map((row) {
      final m = _rowMap(result.columnNames, row);
      return ActiveSession(
        pid: _toInt(m['pid']),
        database: _toStr(m['datname']),
        username: _toStr(m['usename']),
        applicationName: _toStr(m['application_name']),
        clientAddr: _toStr(m['client_addr']),
        backendStart: _toDateTime(m['backend_start']),
        queryStart: _toDateTime(m['query_start']),
        state: _toStr(m['state']),
        waitDurationSec: _toDouble(m['wait_duration_sec']),
        query: _toStr(m['query']),
        backendType: _toStr(m['backend_type']),
      );
    }).toList();
  }

  /// Terminates a backend session by PID.
  ///
  /// Returns `true` if the termination signal was sent successfully.
  Future<bool> terminateSession(String connectionId, int pid) async {
    log.i(_tag, 'terminateSession($connectionId, pid=$pid)');
    final driver = _requireDriver(connectionId);
    final sql = _terminateSessionSql(driver.dialect, pid);
    if (sql == null) return false;

    final result = await driver.execute(sql);
    return result.rows.isNotEmpty && result.rows.first.isNotEmpty
        ? result.rows.first.first == true
        : false;
  }

  /// Cancels the current query on a backend session by PID.
  ///
  /// Returns `true` if the cancel signal was sent successfully.
  Future<bool> cancelSessionQuery(String connectionId, int pid) async {
    log.i(_tag, 'cancelSessionQuery($connectionId, pid=$pid)');
    final driver = _requireDriver(connectionId);
    final sql = _cancelQuerySql(driver.dialect, pid);
    if (sql == null) return false;

    final result = await driver.execute(sql);
    return result.rows.isNotEmpty && result.rows.first.isNotEmpty
        ? result.rows.first.first == true
        : false;
  }

  // -------------------------------------------------------------------------
  // Database / Table Sizes
  // -------------------------------------------------------------------------

  /// Returns size information for all databases on the server.
  Future<List<DatabaseSizeInfo>> getDatabaseSizes(String connectionId) async {
    log.d(_tag, 'getDatabaseSizes($connectionId)');
    final driver = _requireDriver(connectionId);
    final sql = _databaseSizesSql(driver.dialect);
    if (sql == null) return [];

    final result = await driver.execute(sql);
    return result.rows.map((row) {
      final m = _rowMap(result.columnNames, row);
      return DatabaseSizeInfo(
        name: _toStr(m['datname']) ?? '',
        totalSize: _toStr(m['total_size']) ?? '0 bytes',
        sizeBytes: _toInt(m['size_bytes']),
      );
    }).toList();
  }

  /// Returns size breakdown for all tables in a schema.
  Future<List<TableSizeInfo>> getTableSizes(
    String connectionId,
    String schema,
  ) async {
    log.d(_tag, 'getTableSizes($connectionId, $schema)');
    final driver = _requireDriver(connectionId);
    final sql = _tableSizesSql(driver.dialect, schema);
    if (sql == null) return [];

    final result = await driver.execute(sql);
    return result.rows.map((row) {
      final m = _rowMap(result.columnNames, row);
      return TableSizeInfo(
        schema: _toStr(m['schemaname']) ?? schema,
        tableName: _toStr(m['tablename']) ?? '',
        tableSize: _toStr(m['table_size']) ?? '0 bytes',
        indexSize: _toStr(m['index_size']) ?? '0 bytes',
        totalSize: _toStr(m['total_size']) ?? '0 bytes',
        totalSizeBytes: _toInt(m['total_size_bytes']),
        rowEstimate: _toInt(m['row_estimate']),
      );
    }).toList();
  }

  // -------------------------------------------------------------------------
  // Locks
  // -------------------------------------------------------------------------

  /// Returns all current locks.
  Future<List<LockInfo>> getLocks(String connectionId) async {
    log.d(_tag, 'getLocks($connectionId)');
    final driver = _requireDriver(connectionId);
    final sql = _locksSql(driver.dialect);
    if (sql == null) return [];

    final result = await driver.execute(sql);
    return result.rows.map((row) {
      final m = _rowMap(result.columnNames, row);
      return LockInfo(
        pid: _toInt(m['pid']),
        lockMode: _toStr(m['mode']) ?? '',
        lockType: _toStr(m['locktype']) ?? '',
        relation: _toStr(m['relation']),
        granted: m['granted'] == true || m['granted'] == 'true',
        database: _toStr(m['datname']),
        username: _toStr(m['usename']),
        query: _toStr(m['query']),
        durationSec: _toDouble(m['duration_sec']),
      );
    }).toList();
  }

  /// Returns blocking / blocked session pairs.
  Future<List<LockConflict>> getLockConflicts(String connectionId) async {
    log.d(_tag, 'getLockConflicts($connectionId)');
    final driver = _requireDriver(connectionId);
    final sql = _lockConflictsSql(driver.dialect);
    if (sql == null) return [];

    final result = await driver.execute(sql);
    return result.rows.map((row) {
      final m = _rowMap(result.columnNames, row);
      return LockConflict(
        blockedPid: _toInt(m['blocked_pid']),
        blockedQuery: _toStr(m['blocked_query']),
        blockedUser: _toStr(m['blocked_user']),
        blockingPid: _toInt(m['blocking_pid']),
        blockingQuery: _toStr(m['blocking_query']),
        blockingUser: _toStr(m['blocking_user']),
        lockMode: _toStr(m['lock_mode']),
      );
    }).toList();
  }

  // -------------------------------------------------------------------------
  // Index Usage
  // -------------------------------------------------------------------------

  /// Returns index usage statistics for all indexes in a schema.
  Future<List<IndexUsageInfo>> getIndexUsage(
    String connectionId,
    String schema,
  ) async {
    log.d(_tag, 'getIndexUsage($connectionId, $schema)');
    final driver = _requireDriver(connectionId);
    final sql = _indexUsageSql(driver.dialect, schema);
    if (sql == null) return [];

    final result = await driver.execute(sql);
    return result.rows.map((row) {
      final m = _rowMap(result.columnNames, row);
      return IndexUsageInfo(
        schema: _toStr(m['schemaname']) ?? schema,
        tableName: _toStr(m['tablename']) ?? '',
        indexName: _toStr(m['indexname']) ?? '',
        indexScans: _toInt(m['idx_scan']),
        indexSize: _toStr(m['index_size']) ?? '0 bytes',
        indexSizeBytes: _toInt(m['index_size_bytes']),
        indexTuplesRead: _toInt(m['idx_tup_read']),
        indexTuplesFetched: _toInt(m['idx_tup_fetch']),
      );
    }).toList();
  }

  /// Returns indexes with zero scans (candidates for removal).
  Future<List<IndexUsageInfo>> getUnusedIndexes(
    String connectionId,
    String schema,
  ) async {
    log.d(_tag, 'getUnusedIndexes($connectionId, $schema)');
    final allIndexes = await getIndexUsage(connectionId, schema);
    return allIndexes.where((i) => i.indexScans == 0).toList();
  }

  // -------------------------------------------------------------------------
  // Table Statistics
  // -------------------------------------------------------------------------

  /// Returns per-table statistics for all tables in a schema.
  Future<List<TableStatInfo>> getTableStats(
    String connectionId,
    String schema,
  ) async {
    log.d(_tag, 'getTableStats($connectionId, $schema)');
    final driver = _requireDriver(connectionId);
    final sql = _tableStatsSql(driver.dialect, schema);
    if (sql == null) return [];

    final result = await driver.execute(sql);
    return result.rows.map((row) {
      final m = _rowMap(result.columnNames, row);
      return TableStatInfo(
        schema: _toStr(m['schemaname']) ?? schema,
        tableName: _toStr(m['relname']) ?? '',
        liveRows: _toInt(m['n_live_tup']),
        deadRows: _toInt(m['n_dead_tup']),
        seqScans: _toInt(m['seq_scan']),
        seqTuplesRead: _toInt(m['seq_tup_read']),
        idxScans: _toInt(m['idx_scan']),
        idxTuplesFetched: _toInt(m['idx_tup_fetch']),
        inserts: _toInt(m['n_tup_ins']),
        updates: _toInt(m['n_tup_upd']),
        deletes: _toInt(m['n_tup_del']),
        lastVacuum: _toDateTime(m['last_vacuum']),
        lastAutoVacuum: _toDateTime(m['last_autovacuum']),
        lastAnalyze: _toDateTime(m['last_analyze']),
        lastAutoAnalyze: _toDateTime(m['last_autoanalyze']),
        tableSize: _toStr(m['table_size']),
      );
    }).toList();
  }

  // -------------------------------------------------------------------------
  // Vacuum
  // -------------------------------------------------------------------------

  /// Returns vacuum status for all tables in a schema.
  Future<List<VacuumInfo>> getVacuumStatus(
    String connectionId,
    String schema,
  ) async {
    log.d(_tag, 'getVacuumStatus($connectionId, $schema)');
    final driver = _requireDriver(connectionId);
    final sql = _vacuumStatusSql(driver.dialect, schema);
    if (sql == null) return [];

    final result = await driver.execute(sql);
    return result.rows.map((row) {
      final m = _rowMap(result.columnNames, row);
      return VacuumInfo(
        schema: _toStr(m['schemaname']) ?? schema,
        tableName: _toStr(m['relname']) ?? '',
        lastVacuum: _toDateTime(m['last_vacuum']),
        lastAutoVacuum: _toDateTime(m['last_autovacuum']),
        lastAnalyze: _toDateTime(m['last_analyze']),
        lastAutoAnalyze: _toDateTime(m['last_autoanalyze']),
        deadTuples: _toInt(m['n_dead_tup']),
        liveTuples: _toInt(m['n_live_tup']),
      );
    }).toList();
  }

  /// Executes VACUUM on a specific table.
  Future<void> vacuumTable(
    String connectionId,
    String schema,
    String table,
  ) async {
    log.i(_tag, 'vacuumTable($connectionId, $schema.$table)');
    final driver = _requireDriver(connectionId);
    final dialect = driver.dialect;
    final qualifiedTable = dialect.qualifyTable(schema, table);
    await driver.execute('VACUUM $qualifiedTable');
  }

  /// Executes ANALYZE on a specific table.
  Future<void> analyzeTable(
    String connectionId,
    String schema,
    String table,
  ) async {
    log.i(_tag, 'analyzeTable($connectionId, $schema.$table)');
    final driver = _requireDriver(connectionId);
    final dialect = driver.dialect;
    final qualifiedTable = dialect.qualifyTable(schema, table);
    await driver.execute('ANALYZE $qualifiedTable');
  }

  // -------------------------------------------------------------------------
  // Server Info
  // -------------------------------------------------------------------------

  /// Returns high-level server information.
  Future<ServerInfo> getServerInfo(String connectionId) async {
    log.d(_tag, 'getServerInfo($connectionId)');
    final driver = _requireDriver(connectionId);

    final version = await driver.getServerVersion();
    final currentDb = await driver.getCurrentDatabase();
    final currentUser = await driver.getCurrentUser();

    String? uptime;
    int? maxConns;
    int? activeConns;
    String? timezone;
    String? dbSize;

    final dialect = driver.dialect;
    if (dialect.driver == DatabaseDriver.postgresql) {
      try {
        final uptimeResult = await driver.execute(
          "SELECT date_trunc('second', current_timestamp - pg_postmaster_start_time()) AS uptime",
        );
        uptime = _firstValue(uptimeResult);
      } catch (_) {}

      try {
        final maxResult = await driver.execute(
          "SELECT setting FROM pg_settings WHERE name = 'max_connections'",
        );
        maxConns = int.tryParse(_firstValue(maxResult) ?? '');
      } catch (_) {}

      try {
        final activeResult = await driver.execute(
          'SELECT count(*) FROM pg_stat_activity',
        );
        activeConns = int.tryParse(_firstValue(activeResult) ?? '');
      } catch (_) {}

      try {
        final tzResult = await driver.execute('SHOW timezone');
        timezone = _firstValue(tzResult);
      } catch (_) {}

      try {
        dbSize = await driver.getDatabaseSize();
      } catch (_) {}
    } else if (dialect.driver == DatabaseDriver.mysql ||
        dialect.driver == DatabaseDriver.mariadb) {
      try {
        final uptimeResult =
            await driver.execute("SHOW GLOBAL STATUS LIKE 'Uptime'");
        if (uptimeResult.rows.isNotEmpty) {
          final secs = int.tryParse(uptimeResult.rows.first.last.toString());
          if (secs != null) {
            uptime = _formatDuration(Duration(seconds: secs));
          }
        }
      } catch (_) {}

      try {
        final maxResult =
            await driver.execute("SHOW VARIABLES LIKE 'max_connections'");
        if (maxResult.rows.isNotEmpty) {
          maxConns = int.tryParse(maxResult.rows.first.last.toString());
        }
      } catch (_) {}

      try {
        final activeResult =
            await driver.execute('SELECT count(*) FROM information_schema.processlist');
        activeConns = int.tryParse(_firstValue(activeResult) ?? '');
      } catch (_) {}

      try {
        dbSize = await driver.getDatabaseSize();
      } catch (_) {}
    }

    return ServerInfo(
      version: version,
      currentDatabase: currentDb,
      currentUser: currentUser,
      uptime: uptime,
      maxConnections: maxConns,
      activeConnections: activeConns,
      timezone: timezone,
      databaseSize: dbSize,
    );
  }

  /// Returns replication status information.
  Future<List<ReplicationInfo>> getReplicationStatus(
    String connectionId,
  ) async {
    log.d(_tag, 'getReplicationStatus($connectionId)');
    final driver = _requireDriver(connectionId);
    final sql = _replicationSql(driver.dialect);
    if (sql == null) return [];

    final result = await driver.execute(sql);
    return result.rows.map((row) {
      final m = _rowMap(result.columnNames, row);
      return ReplicationInfo(
        pid: _toInt(m['pid']),
        username: _toStr(m['usename']),
        applicationName: _toStr(m['application_name']),
        clientAddr: _toStr(m['client_addr']),
        state: _toStr(m['state']),
        sentLsn: _toStr(m['sent_lsn']),
        writeLsn: _toStr(m['write_lsn']),
        flushLsn: _toStr(m['flush_lsn']),
        replayLsn: _toStr(m['replay_lsn']),
        replayLag: _toStr(m['replay_lag']),
      );
    }).toList();
  }

  /// Returns server configuration parameters.
  Future<List<ServerParameter>> getServerParameters(
    String connectionId,
  ) async {
    log.d(_tag, 'getServerParameters($connectionId)');
    final driver = _requireDriver(connectionId);
    final sql = _serverParametersSql(driver.dialect);
    if (sql == null) return [];

    final result = await driver.execute(sql);
    return result.rows.map((row) {
      final m = _rowMap(result.columnNames, row);
      return ServerParameter(
        name: _toStr(m['name']) ?? '',
        value: _toStr(m['setting']) ?? '',
        unit: _toStr(m['unit']),
        category: _toStr(m['category']),
        description: _toStr(m['short_desc']),
        source: _toStr(m['source']),
      );
    }).toList();
  }

  // =========================================================================
  // Database-Specific SQL
  // =========================================================================

  String? _activeSessionsSql(SqlDialect dialect) {
    return switch (dialect.driver) {
      DatabaseDriver.postgresql => '''
SELECT pid, datname, usename, application_name,
       client_addr::text, backend_start, query_start,
       state,
       EXTRACT(EPOCH FROM (now() - query_start)) AS wait_duration_sec,
       query, backend_type
FROM pg_stat_activity
ORDER BY query_start NULLS LAST''',
      DatabaseDriver.mysql || DatabaseDriver.mariadb => '''
SELECT id AS pid, db AS datname, user AS usename,
       '' AS application_name, host AS client_addr,
       NULL AS backend_start, NULL AS query_start,
       command AS state, time AS wait_duration_sec,
       info AS query, '' AS backend_type
FROM information_schema.processlist
ORDER BY time DESC''',
      DatabaseDriver.sqlServer => '''
SELECT s.session_id AS pid, s.database_id AS datname,
       s.login_name AS usename, s.program_name AS application_name,
       s.host_name AS client_addr, s.login_time AS backend_start,
       r.start_time AS query_start, s.status AS state,
       r.total_elapsed_time / 1000.0 AS wait_duration_sec,
       r.command AS query, '' AS backend_type
FROM sys.dm_exec_sessions s
LEFT JOIN sys.dm_exec_requests r ON s.session_id = r.session_id
ORDER BY r.start_time''',
      DatabaseDriver.sqlite => null,
    };
  }

  String? _terminateSessionSql(SqlDialect dialect, int pid) {
    return switch (dialect.driver) {
      DatabaseDriver.postgresql => 'SELECT pg_terminate_backend($pid)',
      DatabaseDriver.mysql ||
      DatabaseDriver.mariadb =>
        'KILL $pid',
      DatabaseDriver.sqlServer => 'KILL $pid',
      DatabaseDriver.sqlite => null,
    };
  }

  String? _cancelQuerySql(SqlDialect dialect, int pid) {
    return switch (dialect.driver) {
      DatabaseDriver.postgresql => 'SELECT pg_cancel_backend($pid)',
      DatabaseDriver.mysql ||
      DatabaseDriver.mariadb =>
        'KILL QUERY $pid',
      DatabaseDriver.sqlServer => 'KILL $pid',
      DatabaseDriver.sqlite => null,
    };
  }

  String? _databaseSizesSql(SqlDialect dialect) {
    return switch (dialect.driver) {
      DatabaseDriver.postgresql => '''
SELECT datname,
       pg_size_pretty(pg_database_size(datname)) AS total_size,
       pg_database_size(datname) AS size_bytes
FROM pg_database
WHERE datistemplate = false
ORDER BY pg_database_size(datname) DESC''',
      DatabaseDriver.mysql || DatabaseDriver.mariadb => '''
SELECT table_schema AS datname,
       CONCAT(ROUND(SUM(data_length + index_length) / 1024 / 1024, 2), ' MB') AS total_size,
       SUM(data_length + index_length) AS size_bytes
FROM information_schema.tables
GROUP BY table_schema
ORDER BY size_bytes DESC''',
      DatabaseDriver.sqlite => null,
      DatabaseDriver.sqlServer => '''
SELECT name AS datname,
       CAST(ROUND(SUM(size) * 8.0 / 1024, 2) AS VARCHAR) + ' MB' AS total_size,
       SUM(CAST(size AS BIGINT)) * 8192 AS size_bytes
FROM sys.master_files
GROUP BY name
ORDER BY size_bytes DESC''',
    };
  }

  String? _tableSizesSql(SqlDialect dialect, String schema) {
    return switch (dialect.driver) {
      DatabaseDriver.postgresql => '''
SELECT schemaname, relname AS tablename,
       pg_size_pretty(pg_table_size(schemaname || '.' || relname)) AS table_size,
       pg_size_pretty(pg_indexes_size(schemaname || '.' || relname)) AS index_size,
       pg_size_pretty(pg_total_relation_size(schemaname || '.' || relname)) AS total_size,
       pg_total_relation_size(schemaname || '.' || relname) AS total_size_bytes,
       n_live_tup AS row_estimate
FROM pg_stat_user_tables
WHERE schemaname = '$schema'
ORDER BY pg_total_relation_size(schemaname || '.' || relname) DESC''',
      DatabaseDriver.mysql || DatabaseDriver.mariadb => '''
SELECT table_schema AS schemaname, table_name AS tablename,
       CONCAT(ROUND(data_length / 1024 / 1024, 2), ' MB') AS table_size,
       CONCAT(ROUND(index_length / 1024 / 1024, 2), ' MB') AS index_size,
       CONCAT(ROUND((data_length + index_length) / 1024 / 1024, 2), ' MB') AS total_size,
       (data_length + index_length) AS total_size_bytes,
       table_rows AS row_estimate
FROM information_schema.tables
WHERE table_schema = '$schema'
ORDER BY (data_length + index_length) DESC''',
      DatabaseDriver.sqlite => null,
      DatabaseDriver.sqlServer => '''
SELECT s.name AS schemaname, t.name AS tablename,
       CAST(ROUND(SUM(CASE WHEN au.type = 1 THEN au.total_pages END) * 8.0 / 1024, 2) AS VARCHAR) + ' MB' AS table_size,
       CAST(ROUND(SUM(CASE WHEN au.type = 2 THEN au.total_pages END) * 8.0 / 1024, 2) AS VARCHAR) + ' MB' AS index_size,
       CAST(ROUND(SUM(au.total_pages) * 8.0 / 1024, 2) AS VARCHAR) + ' MB' AS total_size,
       SUM(CAST(au.total_pages AS BIGINT)) * 8192 AS total_size_bytes,
       p.rows AS row_estimate
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
JOIN sys.indexes i ON t.object_id = i.object_id
JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
JOIN sys.allocation_units au ON p.partition_id = au.container_id
WHERE s.name = '$schema'
GROUP BY s.name, t.name, p.rows
ORDER BY SUM(au.total_pages) DESC''',
    };
  }

  String? _locksSql(SqlDialect dialect) {
    return switch (dialect.driver) {
      DatabaseDriver.postgresql => '''
SELECT l.pid, l.mode, l.locktype,
       COALESCE(c.relname, l.locktype) AS relation,
       l.granted, d.datname, a.usename, a.query,
       EXTRACT(EPOCH FROM (now() - a.query_start)) AS duration_sec
FROM pg_locks l
LEFT JOIN pg_class c ON l.relation = c.oid
LEFT JOIN pg_database d ON l.database = d.oid
LEFT JOIN pg_stat_activity a ON l.pid = a.pid
ORDER BY l.granted, l.pid''',
      DatabaseDriver.mysql || DatabaseDriver.mariadb => '''
SELECT trx_mysql_thread_id AS pid,
       lock_mode AS mode, lock_type AS locktype,
       lock_table AS relation, 'true' AS granted,
       lock_data AS datname, '' AS usename, '' AS query,
       trx_wait_started AS duration_sec
FROM information_schema.innodb_locks
ORDER BY trx_mysql_thread_id''',
      DatabaseDriver.sqlServer => '''
SELECT request_session_id AS pid,
       request_mode AS mode, resource_type AS locktype,
       resource_description AS relation,
       CASE request_status WHEN 'GRANT' THEN 'true' ELSE 'false' END AS granted,
       '' AS datname, '' AS usename, '' AS query,
       0 AS duration_sec
FROM sys.dm_tran_locks
ORDER BY request_session_id''',
      DatabaseDriver.sqlite => null,
    };
  }

  String? _lockConflictsSql(SqlDialect dialect) {
    return switch (dialect.driver) {
      DatabaseDriver.postgresql => '''
SELECT blocked.pid AS blocked_pid,
       blocked_activity.query AS blocked_query,
       blocked_activity.usename AS blocked_user,
       blocking.pid AS blocking_pid,
       blocking_activity.query AS blocking_query,
       blocking_activity.usename AS blocking_user,
       blocked.mode AS lock_mode
FROM pg_locks blocked
JOIN pg_locks blocking
  ON blocking.locktype = blocked.locktype
  AND blocking.database IS NOT DISTINCT FROM blocked.database
  AND blocking.relation IS NOT DISTINCT FROM blocked.relation
  AND blocking.page IS NOT DISTINCT FROM blocked.page
  AND blocking.tuple IS NOT DISTINCT FROM blocked.tuple
  AND blocking.transactionid IS NOT DISTINCT FROM blocked.transactionid
  AND blocking.classid IS NOT DISTINCT FROM blocked.classid
  AND blocking.objid IS NOT DISTINCT FROM blocked.objid
  AND blocking.objsubid IS NOT DISTINCT FROM blocked.objsubid
  AND blocking.pid != blocked.pid
JOIN pg_stat_activity blocked_activity ON blocked.pid = blocked_activity.pid
JOIN pg_stat_activity blocking_activity ON blocking.pid = blocking_activity.pid
WHERE NOT blocked.granted AND blocking.granted''',
      _ => null,
    };
  }

  String? _indexUsageSql(SqlDialect dialect, String schema) {
    return switch (dialect.driver) {
      DatabaseDriver.postgresql => '''
SELECT schemaname, relname AS tablename, indexrelname AS indexname,
       idx_scan, pg_size_pretty(pg_relation_size(indexrelid)) AS index_size,
       pg_relation_size(indexrelid) AS index_size_bytes,
       idx_tup_read, idx_tup_fetch
FROM pg_stat_user_indexes
WHERE schemaname = '$schema'
ORDER BY idx_scan DESC''',
      DatabaseDriver.mysql || DatabaseDriver.mariadb => '''
SELECT table_schema AS schemaname, table_name AS tablename,
       index_name AS indexname,
       0 AS idx_scan,
       CONCAT(ROUND(stat_value * @@innodb_page_size / 1024 / 1024, 2), ' MB') AS index_size,
       stat_value * @@innodb_page_size AS index_size_bytes,
       0 AS idx_tup_read, 0 AS idx_tup_fetch
FROM mysql.innodb_index_stats
WHERE stat_name = 'size' AND table_schema = '$schema'
ORDER BY stat_value DESC''',
      DatabaseDriver.sqlite => null,
      DatabaseDriver.sqlServer => '''
SELECT s.name AS schemaname, t.name AS tablename,
       i.name AS indexname,
       ius.user_seeks + ius.user_scans + ius.user_lookups AS idx_scan,
       CAST(ROUND(SUM(au.total_pages) * 8.0 / 1024, 2) AS VARCHAR) + ' MB' AS index_size,
       SUM(CAST(au.total_pages AS BIGINT)) * 8192 AS index_size_bytes,
       ius.user_seeks AS idx_tup_read,
       ius.user_lookups AS idx_tup_fetch
FROM sys.indexes i
JOIN sys.tables t ON i.object_id = t.object_id
JOIN sys.schemas s ON t.schema_id = s.schema_id
LEFT JOIN sys.dm_db_index_usage_stats ius
  ON i.object_id = ius.object_id AND i.index_id = ius.index_id
LEFT JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
LEFT JOIN sys.allocation_units au ON p.partition_id = au.container_id
WHERE s.name = '$schema' AND i.name IS NOT NULL
GROUP BY s.name, t.name, i.name, ius.user_seeks, ius.user_scans, ius.user_lookups
ORDER BY idx_scan DESC''',
    };
  }

  String? _tableStatsSql(SqlDialect dialect, String schema) {
    return switch (dialect.driver) {
      DatabaseDriver.postgresql => '''
SELECT schemaname, relname, n_live_tup, n_dead_tup,
       seq_scan, seq_tup_read, idx_scan, idx_tup_fetch,
       n_tup_ins, n_tup_upd, n_tup_del,
       last_vacuum, last_autovacuum, last_analyze, last_autoanalyze,
       pg_size_pretty(pg_total_relation_size(schemaname || '.' || relname)) AS table_size
FROM pg_stat_user_tables
WHERE schemaname = '$schema'
ORDER BY n_live_tup DESC''',
      DatabaseDriver.mysql || DatabaseDriver.mariadb => '''
SELECT table_schema AS schemaname, table_name AS relname,
       table_rows AS n_live_tup, 0 AS n_dead_tup,
       0 AS seq_scan, 0 AS seq_tup_read, 0 AS idx_scan, 0 AS idx_tup_fetch,
       0 AS n_tup_ins, 0 AS n_tup_upd, 0 AS n_tup_del,
       NULL AS last_vacuum, NULL AS last_autovacuum,
       NULL AS last_analyze, NULL AS last_autoanalyze,
       CONCAT(ROUND((data_length + index_length) / 1024 / 1024, 2), ' MB') AS table_size
FROM information_schema.tables
WHERE table_schema = '$schema' AND table_type = 'BASE TABLE'
ORDER BY table_rows DESC''',
      DatabaseDriver.sqlite => null,
      DatabaseDriver.sqlServer => '''
SELECT s.name AS schemaname, t.name AS relname,
       p.rows AS n_live_tup, 0 AS n_dead_tup,
       ius.user_scans AS seq_scan, 0 AS seq_tup_read,
       ius.user_seeks AS idx_scan, ius.user_lookups AS idx_tup_fetch,
       0 AS n_tup_ins, 0 AS n_tup_upd, 0 AS n_tup_del,
       NULL AS last_vacuum, NULL AS last_autovacuum,
       NULL AS last_analyze, NULL AS last_autoanalyze,
       CAST(ROUND(SUM(au.total_pages) * 8.0 / 1024, 2) AS VARCHAR) + ' MB' AS table_size
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
JOIN sys.partitions p ON t.object_id = p.object_id AND p.index_id IN (0, 1)
LEFT JOIN sys.dm_db_index_usage_stats ius ON t.object_id = ius.object_id AND ius.index_id IN (0, 1)
LEFT JOIN sys.allocation_units au ON p.partition_id = au.container_id
WHERE s.name = '$schema'
GROUP BY s.name, t.name, p.rows, ius.user_scans, ius.user_seeks, ius.user_lookups
ORDER BY p.rows DESC''',
    };
  }

  String? _vacuumStatusSql(SqlDialect dialect, String schema) {
    return switch (dialect.driver) {
      DatabaseDriver.postgresql => '''
SELECT schemaname, relname,
       last_vacuum, last_autovacuum, last_analyze, last_autoanalyze,
       n_dead_tup, n_live_tup
FROM pg_stat_user_tables
WHERE schemaname = '$schema'
ORDER BY n_dead_tup DESC''',
      _ => null,
    };
  }

  String? _replicationSql(SqlDialect dialect) {
    return switch (dialect.driver) {
      DatabaseDriver.postgresql => '''
SELECT pid, usename, application_name, client_addr::text,
       state, sent_lsn::text, write_lsn::text, flush_lsn::text,
       replay_lsn::text, replay_lag::text
FROM pg_stat_replication
ORDER BY application_name''',
      _ => null,
    };
  }

  String? _serverParametersSql(SqlDialect dialect) {
    return switch (dialect.driver) {
      DatabaseDriver.postgresql => '''
SELECT name, setting, unit, category, short_desc, source
FROM pg_settings
ORDER BY category, name''',
      DatabaseDriver.mysql || DatabaseDriver.mariadb => '''
SELECT variable_name AS name, variable_value AS setting,
       '' AS unit, '' AS category, '' AS short_desc, '' AS source
FROM performance_schema.global_variables
ORDER BY variable_name''',
      DatabaseDriver.sqlServer => '''
SELECT name, CAST(value AS VARCHAR) AS setting,
       '' AS unit, '' AS category, description AS short_desc, '' AS source
FROM sys.configurations
ORDER BY name''',
      DatabaseDriver.sqlite => null,
    };
  }

  // =========================================================================
  // Internal Helpers
  // =========================================================================

  /// Returns the active [DatabaseDriverAdapter] or throws.
  DatabaseDriverAdapter _requireDriver(String connectionId) {
    final driver = _connectionService.getDriver(connectionId);
    if (driver == null) {
      throw StateError('No active connection for $connectionId');
    }
    return driver;
  }

  /// Converts a result row + column names into a keyed map.
  Map<String, dynamic> _rowMap(List<String> cols, List<dynamic> row) {
    final map = <String, dynamic>{};
    for (var i = 0; i < cols.length && i < row.length; i++) {
      map[cols[i]] = row[i];
    }
    return map;
  }

  /// Extracts the first value from a single-row, single-column result.
  String? _firstValue(DriverQueryResult result) {
    if (result.rows.isEmpty || result.rows.first.isEmpty) return null;
    return result.rows.first.first?.toString();
  }

  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  String? _toStr(dynamic v) {
    if (v == null) return null;
    return v.toString();
  }

  DateTime? _toDateTime(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }

  String _formatDuration(Duration d) {
    final days = d.inDays;
    final hours = d.inHours % 24;
    final mins = d.inMinutes % 60;
    final secs = d.inSeconds % 60;
    final parts = <String>[];
    if (days > 0) parts.add('$days day${days == 1 ? '' : 's'}');
    if (hours > 0) parts.add('$hours hour${hours == 1 ? '' : 's'}');
    if (mins > 0) parts.add('$mins min${mins == 1 ? '' : 's'}');
    if (secs > 0 || parts.isEmpty) parts.add('$secs sec${secs == 1 ? '' : 's'}');
    return parts.join(', ');
  }
}
