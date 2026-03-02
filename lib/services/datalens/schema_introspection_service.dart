/// Service for querying database system catalogs in DataLens.
///
/// Discovers database structure by delegating to the active
/// [DatabaseDriverAdapter], which uses the appropriate catalog queries
/// for the target database engine (PostgreSQL, MySQL, MariaDB, SQLite,
/// SQL Server).
///
/// This powers the DBeaver-style navigator tree and table properties panels.
library;

import '../../models/datalens_models.dart';
import '../logging/log_service.dart';
import 'database_connection_service.dart';
import 'drivers/database_driver.dart';

/// Queries database system catalogs to discover database structure.
///
/// Delegates all introspection to the active [DatabaseDriverAdapter] for the
/// given connection. This service is a thin coordination layer that obtains
/// the driver from [DatabaseConnectionService] and forwards calls.
class SchemaIntrospectionService {
  static const String _tag = 'SchemaIntrospectionService';

  /// The connection service used to obtain active driver adapters.
  final DatabaseConnectionService _connectionService;

  /// Creates a [SchemaIntrospectionService] with the given [connectionService].
  SchemaIntrospectionService(DatabaseConnectionService connectionService)
      : _connectionService = connectionService;

  // ---------------------------------------------------------------------------
  // Schema Discovery
  // ---------------------------------------------------------------------------

  /// Returns all non-system schemas in the database.
  ///
  /// Excludes engine-specific system schemas. Each [SchemaInfo] includes
  /// table, view, and sequence counts.
  Future<List<SchemaInfo>> getSchemas(String connectionId) async {
    log.d(_tag, 'getSchemas($connectionId)');
    final driver = _requireDriver(connectionId);
    return driver.getSchemas();
  }

  // ---------------------------------------------------------------------------
  // Table Discovery
  // ---------------------------------------------------------------------------

  /// Returns all tables, views, and materialized views in [schemaName].
  Future<List<TableInfo>> getTables(
    String connectionId,
    String schemaName,
  ) async {
    log.d(_tag, 'getTables($connectionId, $schemaName)');
    final driver = _requireDriver(connectionId);
    return driver.getTables(schemaName);
  }

  // ---------------------------------------------------------------------------
  // Column Metadata
  // ---------------------------------------------------------------------------

  /// Returns column metadata for a specific table.
  ///
  /// Determines each column's [ColumnCategory] by cross-referencing primary
  /// key, foreign key, and serial/identity information.
  Future<List<ColumnInfo>> getColumns(
    String connectionId,
    String schemaName,
    String tableName,
  ) async {
    log.d(_tag, 'getColumns($connectionId, $schemaName.$tableName)');
    final driver = _requireDriver(connectionId);
    return driver.getColumns(schemaName, tableName);
  }

  // ---------------------------------------------------------------------------
  // Constraints
  // ---------------------------------------------------------------------------

  /// Returns constraints for a table (PRIMARY KEY, UNIQUE, CHECK, EXCLUSION).
  ///
  /// Foreign keys are returned separately by [getForeignKeys].
  Future<List<ConstraintInfo>> getConstraints(
    String connectionId,
    String schemaName,
    String tableName,
  ) async {
    log.d(_tag, 'getConstraints($connectionId, $schemaName.$tableName)');
    final driver = _requireDriver(connectionId);
    return driver.getConstraints(schemaName, tableName);
  }

  // ---------------------------------------------------------------------------
  // Foreign Keys
  // ---------------------------------------------------------------------------

  /// Returns outgoing foreign key references for a table.
  Future<List<ForeignKeyInfo>> getForeignKeys(
    String connectionId,
    String schemaName,
    String tableName,
  ) async {
    log.d(_tag, 'getForeignKeys($connectionId, $schemaName.$tableName)');
    final driver = _requireDriver(connectionId);
    return driver.getForeignKeys(schemaName, tableName);
  }

  /// Returns incoming foreign key references (tables that reference this one).
  Future<List<ForeignKeyInfo>> getIncomingReferences(
    String connectionId,
    String schemaName,
    String tableName,
  ) async {
    log.d(
      _tag,
      'getIncomingReferences($connectionId, $schemaName.$tableName)',
    );
    final driver = _requireDriver(connectionId);
    return driver.getIncomingReferences(schemaName, tableName);
  }

  // ---------------------------------------------------------------------------
  // Indexes
  // ---------------------------------------------------------------------------

  /// Returns index metadata for a table.
  Future<List<IndexInfo>> getIndexes(
    String connectionId,
    String schemaName,
    String tableName,
  ) async {
    log.d(_tag, 'getIndexes($connectionId, $schemaName.$tableName)');
    final driver = _requireDriver(connectionId);
    return driver.getIndexes(schemaName, tableName);
  }

  // ---------------------------------------------------------------------------
  // Sequences
  // ---------------------------------------------------------------------------

  /// Returns sequence metadata for a schema.
  ///
  /// Returns an empty list for engines that do not support sequences
  /// (e.g., MySQL, SQLite).
  Future<List<SequenceInfo>> getSequences(
    String connectionId,
    String schemaName,
  ) async {
    log.d(_tag, 'getSequences($connectionId, $schemaName)');
    final driver = _requireDriver(connectionId);
    return driver.getSequences(schemaName);
  }

  // ---------------------------------------------------------------------------
  // Table Dependencies
  // ---------------------------------------------------------------------------

  /// Returns table dependencies (outgoing + incoming FK relationships).
  Future<List<TableDependency>> getTableDependencies(
    String connectionId,
    String schemaName,
    String tableName,
  ) async {
    log.d(
      _tag,
      'getTableDependencies($connectionId, $schemaName.$tableName)',
    );

    final outgoing = await getForeignKeys(connectionId, schemaName, tableName);
    final incoming =
        await getIncomingReferences(connectionId, schemaName, tableName);

    final deps = <TableDependency>[];

    for (final fk in outgoing) {
      for (var i = 0; i < (fk.columns?.length ?? 0); i++) {
        deps.add(TableDependency(
          sourceTable: tableName,
          sourceColumn: fk.columns![i],
          targetTable: fk.referencedTable,
          targetColumn:
              (fk.referencedColumns != null && i < fk.referencedColumns!.length)
                  ? fk.referencedColumns![i]
                  : null,
          constraintName: fk.constraintName,
          direction: 'outgoing',
        ));
      }
    }

    for (final fk in incoming) {
      for (var i = 0; i < (fk.referencedColumns?.length ?? 0); i++) {
        deps.add(TableDependency(
          sourceTable: fk.referencedTable,
          sourceColumn: (fk.columns != null && i < fk.columns!.length)
              ? fk.columns![i]
              : null,
          targetTable: tableName,
          targetColumn: fk.referencedColumns![i],
          constraintName: fk.constraintName,
          direction: 'incoming',
        ));
      }
    }

    return deps;
  }

  // ---------------------------------------------------------------------------
  // Table Statistics
  // ---------------------------------------------------------------------------

  /// Returns table statistics from engine-specific catalog views.
  Future<TableStatistics> getTableStatistics(
    String connectionId,
    String schemaName,
    String tableName,
  ) async {
    log.d(_tag, 'getTableStatistics($connectionId, $schemaName.$tableName)');
    final driver = _requireDriver(connectionId);
    return driver.getTableStatistics(schemaName, tableName);
  }

  // ---------------------------------------------------------------------------
  // DDL Reconstruction
  // ---------------------------------------------------------------------------

  /// Reconstructs a `CREATE TABLE` DDL statement from catalog data.
  Future<String> getTableDdl(
    String connectionId,
    String schemaName,
    String tableName,
  ) async {
    log.d(_tag, 'getTableDdl($connectionId, $schemaName.$tableName)');
    final driver = _requireDriver(connectionId);
    return driver.getTableDdl(schemaName, tableName);
  }

  // ---------------------------------------------------------------------------
  // Row Count & Database Size
  // ---------------------------------------------------------------------------

  /// Returns the estimated row count for a table (fast path).
  Future<int> getRowCountEstimate(
    String connectionId,
    String schemaName,
    String tableName,
  ) async {
    log.d(_tag, 'getRowCountEstimate($connectionId, $schemaName.$tableName)');
    final driver = _requireDriver(connectionId);
    return driver.getRowCountEstimate(schemaName, tableName);
  }

  /// Returns the total database size as a human-readable string.
  Future<String> getDatabaseSize(String connectionId) async {
    log.d(_tag, 'getDatabaseSize($connectionId)');
    final driver = _requireDriver(connectionId);
    return driver.getDatabaseSize();
  }

  // ---------------------------------------------------------------------------
  // Search
  // ---------------------------------------------------------------------------

  /// Searches for tables and views whose name matches [query].
  ///
  /// Uses case-insensitive matching across all non-system schemas.
  Future<List<TableInfo>> searchObjects(
    String connectionId,
    String query,
  ) async {
    log.d(_tag, 'searchObjects($connectionId, "$query")');
    final driver = _requireDriver(connectionId);
    return driver.searchObjects(query);
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
}
