/// Data models for the DataLens database administration module.
///
/// These are plain Dart classes (no JSON serialization needed) constructed
/// from [DriverQueryResult] rows by [DbAdminService]. They represent
/// server-level metrics, active sessions, locks, table stats, index
/// usage, and vacuum status.
///
/// Organized by domain:
/// - Active sessions (1 class)
/// - Database / table size (2 classes)
/// - Locks (2 classes)
/// - Index usage (1 class)
/// - Table statistics (1 class)
/// - Vacuum info (1 class)
/// - Server info (3 classes)
library;

// ---------------------------------------------------------------------------
// Active Sessions
// ---------------------------------------------------------------------------

/// A currently active backend session / process.
class ActiveSession {
  /// Process ID (pid).
  final int pid;

  /// Database name the session is connected to.
  final String? database;

  /// Username of the connected role.
  final String? username;

  /// Client application name.
  final String? applicationName;

  /// Client IP address.
  final String? clientAddr;

  /// Backend start time.
  final DateTime? backendStart;

  /// Current query start time.
  final DateTime? queryStart;

  /// Current state (active, idle, idle in transaction, etc.).
  final String? state;

  /// Seconds the session has been waiting on the current query.
  final double? waitDurationSec;

  /// The SQL query currently being executed.
  final String? query;

  /// Backend type (client backend, autovacuum worker, etc.).
  final String? backendType;

  /// Creates an [ActiveSession].
  const ActiveSession({
    required this.pid,
    this.database,
    this.username,
    this.applicationName,
    this.clientAddr,
    this.backendStart,
    this.queryStart,
    this.state,
    this.waitDurationSec,
    this.query,
    this.backendType,
  });
}

// ---------------------------------------------------------------------------
// Database / Table Size
// ---------------------------------------------------------------------------

/// Overall database size information.
class DatabaseSizeInfo {
  /// Database name.
  final String name;

  /// Human-readable total size (e.g., "1.2 GB").
  final String totalSize;

  /// Raw size in bytes.
  final int sizeBytes;

  /// Creates a [DatabaseSizeInfo].
  const DatabaseSizeInfo({
    required this.name,
    required this.totalSize,
    required this.sizeBytes,
  });
}

/// Size breakdown for a single table.
class TableSizeInfo {
  /// Schema name.
  final String schema;

  /// Table name.
  final String tableName;

  /// Human-readable table data size.
  final String tableSize;

  /// Human-readable index size.
  final String indexSize;

  /// Human-readable total size (data + indexes + TOAST).
  final String totalSize;

  /// Raw total size in bytes.
  final int totalSizeBytes;

  /// Estimated row count.
  final int rowEstimate;

  /// Creates a [TableSizeInfo].
  const TableSizeInfo({
    required this.schema,
    required this.tableName,
    required this.tableSize,
    required this.indexSize,
    required this.totalSize,
    required this.totalSizeBytes,
    required this.rowEstimate,
  });
}

// ---------------------------------------------------------------------------
// Locks
// ---------------------------------------------------------------------------

/// A currently held or requested database lock.
class LockInfo {
  /// Process ID holding or waiting for this lock.
  final int pid;

  /// Lock mode (AccessShareLock, RowExclusiveLock, etc.).
  final String lockMode;

  /// Lock type (relation, transactionid, advisory, etc.).
  final String lockType;

  /// Schema.table name of the locked relation (if applicable).
  final String? relation;

  /// Whether the lock has been granted or is waiting.
  final bool granted;

  /// Database name.
  final String? database;

  /// Username of the session holding the lock.
  final String? username;

  /// The query running in the session holding the lock.
  final String? query;

  /// Duration the lock has been held or waited for, in seconds.
  final double? durationSec;

  /// Creates a [LockInfo].
  const LockInfo({
    required this.pid,
    required this.lockMode,
    required this.lockType,
    this.relation,
    required this.granted,
    this.database,
    this.username,
    this.query,
    this.durationSec,
  });
}

/// Two sessions in a blocking relationship.
class LockConflict {
  /// PID of the blocked (waiting) session.
  final int blockedPid;

  /// Query of the blocked session.
  final String? blockedQuery;

  /// Username of the blocked session.
  final String? blockedUser;

  /// PID of the blocking session.
  final int blockingPid;

  /// Query of the blocking session.
  final String? blockingQuery;

  /// Username of the blocking session.
  final String? blockingUser;

  /// Lock mode the blocked session is waiting for.
  final String? lockMode;

  /// Creates a [LockConflict].
  const LockConflict({
    required this.blockedPid,
    this.blockedQuery,
    this.blockedUser,
    required this.blockingPid,
    this.blockingQuery,
    this.blockingUser,
    this.lockMode,
  });
}

// ---------------------------------------------------------------------------
// Index Usage
// ---------------------------------------------------------------------------

/// Usage statistics for a single index.
class IndexUsageInfo {
  /// Schema name.
  final String schema;

  /// Table the index belongs to.
  final String tableName;

  /// Index name.
  final String indexName;

  /// Number of index scans performed.
  final int indexScans;

  /// Human-readable index size.
  final String indexSize;

  /// Raw index size in bytes.
  final int indexSizeBytes;

  /// Number of rows returned by index scans.
  final int indexTuplesRead;

  /// Number of live table rows fetched via index.
  final int indexTuplesFetched;

  /// Creates an [IndexUsageInfo].
  const IndexUsageInfo({
    required this.schema,
    required this.tableName,
    required this.indexName,
    required this.indexScans,
    required this.indexSize,
    required this.indexSizeBytes,
    required this.indexTuplesRead,
    required this.indexTuplesFetched,
  });
}

// ---------------------------------------------------------------------------
// Table Statistics (for admin panel — more detail than TableStatistics)
// ---------------------------------------------------------------------------

/// Per-table statistics from the database stats collector.
class TableStatInfo {
  /// Schema name.
  final String schema;

  /// Table name.
  final String tableName;

  /// Number of live rows.
  final int liveRows;

  /// Number of dead (unvacuumed) rows.
  final int deadRows;

  /// Dead-to-live ratio (0.0–1.0+, higher = needs vacuum).
  double get deadRatio => liveRows > 0 ? deadRows / liveRows : 0.0;

  /// Sequential scan count.
  final int seqScans;

  /// Rows read by sequential scans.
  final int seqTuplesRead;

  /// Index scan count.
  final int idxScans;

  /// Rows fetched by index scans.
  final int idxTuplesFetched;

  /// Insert count since last stats reset.
  final int inserts;

  /// Update count since last stats reset.
  final int updates;

  /// Delete count since last stats reset.
  final int deletes;

  /// Last manual VACUUM timestamp.
  final DateTime? lastVacuum;

  /// Last auto-vacuum timestamp.
  final DateTime? lastAutoVacuum;

  /// Last manual ANALYZE timestamp.
  final DateTime? lastAnalyze;

  /// Last auto-analyze timestamp.
  final DateTime? lastAutoAnalyze;

  /// Human-readable table size.
  final String? tableSize;

  /// Creates a [TableStatInfo].
  const TableStatInfo({
    required this.schema,
    required this.tableName,
    required this.liveRows,
    required this.deadRows,
    required this.seqScans,
    required this.seqTuplesRead,
    required this.idxScans,
    required this.idxTuplesFetched,
    required this.inserts,
    required this.updates,
    required this.deletes,
    this.lastVacuum,
    this.lastAutoVacuum,
    this.lastAnalyze,
    this.lastAutoAnalyze,
    this.tableSize,
  });
}

// ---------------------------------------------------------------------------
// Vacuum Info
// ---------------------------------------------------------------------------

/// Vacuum-specific status for a single table.
class VacuumInfo {
  /// Schema name.
  final String schema;

  /// Table name.
  final String tableName;

  /// Last manual VACUUM timestamp.
  final DateTime? lastVacuum;

  /// Last auto-vacuum timestamp.
  final DateTime? lastAutoVacuum;

  /// Last manual ANALYZE timestamp.
  final DateTime? lastAnalyze;

  /// Last auto-analyze timestamp.
  final DateTime? lastAutoAnalyze;

  /// Number of dead tuples.
  final int deadTuples;

  /// Number of live tuples.
  final int liveTuples;

  /// Whether autovacuum is expected to run soon.
  bool get needsVacuum {
    if (liveTuples == 0 && deadTuples == 0) return false;
    return deadTuples > (50 + liveTuples * 0.2);
  }

  /// Creates a [VacuumInfo].
  const VacuumInfo({
    required this.schema,
    required this.tableName,
    this.lastVacuum,
    this.lastAutoVacuum,
    this.lastAnalyze,
    this.lastAutoAnalyze,
    required this.deadTuples,
    required this.liveTuples,
  });
}

// ---------------------------------------------------------------------------
// Server Info
// ---------------------------------------------------------------------------

/// High-level information about the database server.
class ServerInfo {
  /// Server version string (e.g., "PostgreSQL 16.1").
  final String version;

  /// Current database name.
  final String currentDatabase;

  /// Current user/role.
  final String currentUser;

  /// Server uptime as a human-readable string.
  final String? uptime;

  /// Maximum number of connections allowed.
  final int? maxConnections;

  /// Number of currently active connections.
  final int? activeConnections;

  /// Server-reported timezone.
  final String? timezone;

  /// Total database size.
  final String? databaseSize;

  /// Creates a [ServerInfo].
  const ServerInfo({
    required this.version,
    required this.currentDatabase,
    required this.currentUser,
    this.uptime,
    this.maxConnections,
    this.activeConnections,
    this.timezone,
    this.databaseSize,
  });
}

/// A server configuration parameter.
class ServerParameter {
  /// Parameter name (e.g., "max_connections").
  final String name;

  /// Current value.
  final String value;

  /// Unit of the value (e.g., "kB", "ms"), or empty.
  final String? unit;

  /// Category grouping (e.g., "Connections and Authentication").
  final String? category;

  /// Short description of the parameter.
  final String? description;

  /// Source that set this value (configuration file, session, etc.).
  final String? source;

  /// Creates a [ServerParameter].
  const ServerParameter({
    required this.name,
    required this.value,
    this.unit,
    this.category,
    this.description,
    this.source,
  });
}

/// Replication status information.
class ReplicationInfo {
  /// Replication client PID.
  final int pid;

  /// Username of the replication connection.
  final String? username;

  /// Application name of the standby.
  final String? applicationName;

  /// Client address.
  final String? clientAddr;

  /// Replication state (streaming, catchup, etc.).
  final String? state;

  /// Sent LSN position.
  final String? sentLsn;

  /// Written LSN position.
  final String? writeLsn;

  /// Flushed LSN position.
  final String? flushLsn;

  /// Replayed LSN position.
  final String? replayLsn;

  /// Replication lag as a human-readable string.
  final String? replayLag;

  /// Creates a [ReplicationInfo].
  const ReplicationInfo({
    required this.pid,
    this.username,
    this.applicationName,
    this.clientAddr,
    this.state,
    this.sentLsn,
    this.writeLsn,
    this.flushLsn,
    this.replayLsn,
    this.replayLag,
  });
}
