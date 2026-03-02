/// Abstract interface for database driver adapters.
///
/// Defines the contract that all database drivers (PostgreSQL, MySQL/MariaDB,
/// SQLite, SQL Server) must implement. Each driver provides connection
/// lifecycle management, query execution, and schema introspection methods
/// tailored to the target database engine.
///
/// The [SqlDialect] helper class captures per-engine SQL syntax differences
/// (identifier quoting, pagination, boolean literals, etc.) so that
/// cross-cutting services can generate valid SQL without database-specific
/// branches.
library;

import '../../../models/datalens_enums.dart';
import '../../../models/datalens_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SQL Dialect — per-engine syntax differences
// ─────────────────────────────────────────────────────────────────────────────

/// Captures SQL syntax differences between database engines.
///
/// Used by services that build SQL strings (query execution, DDL
/// reconstruction) to generate valid syntax for the active connection's
/// database engine.
class SqlDialect {
  /// The database driver this dialect applies to.
  final DatabaseDriver driver;

  /// Character used to quote identifiers (e.g., `"` for PostgreSQL, `` ` ``
  /// for MySQL, `[` for SQL Server).
  final String identifierQuote;

  /// Closing character for identifiers when the open/close differ
  /// (e.g., `]` for SQL Server). Same as [identifierQuote] when symmetric.
  final String identifierQuoteClose;

  /// Whether the engine uses `LIMIT ... OFFSET ...` for pagination.
  ///
  /// `false` indicates `TOP` (SQL Server) or other syntax is needed.
  final bool supportsLimitOffset;

  /// Whether the engine supports `EXPLAIN` plans.
  final bool supportsExplain;

  /// Whether the engine supports `RETURNING` clauses on DML.
  final bool supportsReturning;

  /// Placeholder style for parameterized queries.
  ///
  /// - `$` for PostgreSQL (`$1`, `$2`)
  /// - `?` for MySQL/MariaDB/SQLite
  /// - `@` for SQL Server (`@p1`, `@p2`)
  final String parameterStyle;

  /// Creates a [SqlDialect].
  const SqlDialect({
    required this.driver,
    required this.identifierQuote,
    String? identifierQuoteClose,
    required this.supportsLimitOffset,
    required this.supportsExplain,
    required this.supportsReturning,
    required this.parameterStyle,
  }) : identifierQuoteClose = identifierQuoteClose ?? identifierQuote;

  /// PostgreSQL SQL dialect.
  static const postgresql = SqlDialect(
    driver: DatabaseDriver.postgresql,
    identifierQuote: '"',
    supportsLimitOffset: true,
    supportsExplain: true,
    supportsReturning: true,
    parameterStyle: r'$',
  );

  /// MySQL SQL dialect.
  static const mysql = SqlDialect(
    driver: DatabaseDriver.mysql,
    identifierQuote: '`',
    supportsLimitOffset: true,
    supportsExplain: true,
    supportsReturning: false,
    parameterStyle: '?',
  );

  /// MariaDB SQL dialect (same as MySQL).
  static const mariadb = SqlDialect(
    driver: DatabaseDriver.mariadb,
    identifierQuote: '`',
    supportsLimitOffset: true,
    supportsExplain: true,
    supportsReturning: false,
    parameterStyle: '?',
  );

  /// SQLite SQL dialect.
  static const sqlite = SqlDialect(
    driver: DatabaseDriver.sqlite,
    identifierQuote: '"',
    supportsLimitOffset: true,
    supportsExplain: true,
    supportsReturning: true,
    parameterStyle: '?',
  );

  /// SQL Server SQL dialect.
  static const sqlServer = SqlDialect(
    driver: DatabaseDriver.sqlServer,
    identifierQuote: '[',
    identifierQuoteClose: ']',
    supportsLimitOffset: false,
    supportsExplain: false,
    supportsReturning: false,
    parameterStyle: '@',
  );

  /// Returns the dialect for the given [driver].
  static SqlDialect forDriver(DatabaseDriver driver) => switch (driver) {
        DatabaseDriver.postgresql => postgresql,
        DatabaseDriver.mysql => mysql,
        DatabaseDriver.mariadb => mariadb,
        DatabaseDriver.sqlite => sqlite,
        DatabaseDriver.sqlServer => sqlServer,
      };

  /// Quotes an identifier (table name, column name, schema name).
  String quoteIdentifier(String name) =>
      '$identifierQuote$name$identifierQuoteClose';

  /// Quotes a schema-qualified table name.
  String qualifyTable(String schema, String table) =>
      '${quoteIdentifier(schema)}.${quoteIdentifier(table)}';
}

// ─────────────────────────────────────────────────────────────────────────────
// Query Result — driver-neutral result wrapper
// ─────────────────────────────────────────────────────────────────────────────

/// A driver-neutral representation of a query result row.
///
/// Drivers translate their native result sets into lists of [DriverResultRow].
class DriverResultRow {
  /// Column values keyed by column name.
  final Map<String, dynamic> columns;

  /// Creates a [DriverResultRow].
  const DriverResultRow(this.columns);

  /// Returns the value for [key], or `null` if absent.
  dynamic operator [](String key) => columns[key];
}

/// A driver-neutral query result.
class DriverQueryResult {
  /// Column names in order.
  final List<String> columnNames;

  /// Column type names in order.
  final List<String> columnTypes;

  /// Row data as lists (parallel to [columnNames]).
  final List<List<dynamic>> rows;

  /// Number of affected rows (for DML statements).
  final int affectedRows;

  /// Creates a [DriverQueryResult].
  const DriverQueryResult({
    this.columnNames = const [],
    this.columnTypes = const [],
    this.rows = const [],
    this.affectedRows = 0,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Abstract Driver Adapter
// ─────────────────────────────────────────────────────────────────────────────

/// Abstract interface for database driver adapters.
///
/// Each concrete implementation (PostgreSQL, MySQL, MariaDB, SQLite, SQL
/// Server) provides connection management, raw query execution, and schema
/// introspection using the target engine's native protocol and catalog
/// queries.
abstract class DatabaseDriverAdapter {
  /// The database driver type for this adapter.
  DatabaseDriver get driverType;

  /// The SQL dialect for this adapter.
  SqlDialect get dialect;

  /// Whether the underlying connection is currently open.
  bool get isOpen;

  // ───────────────────────────────────────────────────────────────────────
  // Connection Lifecycle
  // ───────────────────────────────────────────────────────────────────────

  /// Opens a connection using the given [config].
  Future<void> connect(DatabaseConnection config);

  /// Closes the active connection.
  Future<void> close();

  // ───────────────────────────────────────────────────────────────────────
  // Query Execution
  // ───────────────────────────────────────────────────────────────────────

  /// Executes a raw SQL statement and returns a driver-neutral result.
  Future<DriverQueryResult> execute(String sql);

  /// Executes a raw SQL statement with a paged wrapper.
  ///
  /// The driver applies its native pagination syntax (LIMIT/OFFSET, TOP,
  /// etc.) around the given [sql].
  Future<DriverQueryResult> executePaged(
    String sql, {
    required int limit,
    required int offset,
  });

  // ───────────────────────────────────────────────────────────────────────
  // Server Metadata
  // ───────────────────────────────────────────────────────────────────────

  /// Returns the database server version string.
  Future<String> getServerVersion();

  /// Returns the current database name.
  Future<String> getCurrentDatabase();

  /// Returns the current connected user.
  Future<String> getCurrentUser();

  // ───────────────────────────────────────────────────────────────────────
  // Schema Introspection
  // ───────────────────────────────────────────────────────────────────────

  /// Returns all non-system schemas (or databases for MySQL/MariaDB).
  Future<List<SchemaInfo>> getSchemas();

  /// Returns tables, views, and materialized views in [schemaName].
  Future<List<TableInfo>> getTables(String schemaName);

  /// Returns column metadata for [tableName] in [schemaName].
  Future<List<ColumnInfo>> getColumns(String schemaName, String tableName);

  /// Returns non-FK constraints for [tableName] in [schemaName].
  Future<List<ConstraintInfo>> getConstraints(
    String schemaName,
    String tableName,
  );

  /// Returns outgoing foreign key references for [tableName].
  Future<List<ForeignKeyInfo>> getForeignKeys(
    String schemaName,
    String tableName,
  );

  /// Returns incoming foreign key references (tables referencing this one).
  Future<List<ForeignKeyInfo>> getIncomingReferences(
    String schemaName,
    String tableName,
  );

  /// Returns index metadata for [tableName].
  Future<List<IndexInfo>> getIndexes(String schemaName, String tableName);

  /// Returns sequence metadata for [schemaName].
  ///
  /// Returns an empty list for engines that do not support sequences.
  Future<List<SequenceInfo>> getSequences(String schemaName);

  /// Returns table statistics (row counts, scan counts, etc.).
  Future<TableStatistics> getTableStatistics(
    String schemaName,
    String tableName,
  );

  /// Reconstructs a `CREATE TABLE` DDL statement.
  Future<String> getTableDdl(String schemaName, String tableName);

  /// Returns the estimated row count for a table (fast path).
  Future<int> getRowCountEstimate(String schemaName, String tableName);

  /// Returns the total database size as a human-readable string.
  Future<String> getDatabaseSize();

  /// Searches for tables/views matching [query] across all schemas.
  Future<List<TableInfo>> searchObjects(String query);

  // ───────────────────────────────────────────────────────────────────────
  // Engine-Specific Operations
  // ───────────────────────────────────────────────────────────────────────

  /// Cancels any running query on this connection.
  ///
  /// Returns `true` if the cancellation was sent successfully.
  Future<bool> cancelQuery();

  /// Returns the EXPLAIN plan for [sql].
  ///
  /// When [analyze] is `true`, the query is actually executed.
  /// Returns an empty string if the engine does not support EXPLAIN.
  Future<String> explainQuery(String sql, {bool analyze = false});
}
