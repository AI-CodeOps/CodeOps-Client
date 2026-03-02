/// SQLite driver adapter for DataLens.
///
/// Implements [DatabaseDriverAdapter] using the `sqlite3` FFI package for
/// direct file-based database access. All schema introspection queries use
/// SQLite PRAGMA statements and the `sqlite_master` catalog table.
///
/// SQLite APIs are synchronous; this driver wraps them in [Future]-returning
/// methods to satisfy the async [DatabaseDriverAdapter] contract.
library;

import 'package:sqlite3/sqlite3.dart' as sqlite;

import '../../../models/datalens_enums.dart';
import '../../../models/datalens_models.dart';
import '../../logging/log_service.dart';
import 'database_driver.dart';

/// SQLite implementation of [DatabaseDriverAdapter].
class SqliteDriver implements DatabaseDriverAdapter {
  static const String _tag = 'SqliteDriver';

  /// The active SQLite database handle, or `null` if not connected.
  sqlite.Database? _database;

  /// Tracks whether the database is currently open.
  ///
  /// The `sqlite3` [sqlite.Database] does not expose an `isOpen` property,
  /// so we maintain this flag manually.
  bool _isOpenFlag = false;

  /// The connection configuration used to open the current database.
  DatabaseConnection? _config;

  @override
  DatabaseDriver get driverType => DatabaseDriver.sqlite;

  @override
  SqlDialect get dialect => SqlDialect.sqlite;

  @override
  bool get isOpen => _isOpenFlag && _database != null;

  /// Returns the underlying [sqlite.Database] for legacy callers.
  ///
  /// Throws [StateError] if not connected.
  sqlite.Database get rawDatabase {
    if (_database == null) {
      throw StateError('SQLite driver is not connected');
    }
    return _database!;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Connection Lifecycle
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Future<void> connect(DatabaseConnection config) async {
    final filePath = config.filePath;
    if (filePath == null || filePath.isEmpty) {
      throw StateError(
        'SQLite driver requires a non-null, non-empty filePath in the '
        'connection configuration',
      );
    }
    log.d(_tag, 'connect($filePath)');
    _database = sqlite.sqlite3.open(filePath);
    _isOpenFlag = true;
    _config = config;
  }

  @override
  Future<void> close() async {
    log.d(_tag, 'close()');
    _database?.dispose();
    _database = null;
    _isOpenFlag = false;
    _config = null;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Query Execution
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Future<DriverQueryResult> execute(String sql) async {
    final db = _requireDatabase();

    if (_isSelectQuery(sql)) {
      final resultSet = db.select(sql);
      return _toDriverResult(resultSet);
    }

    db.execute(sql);
    final changes = db.updatedRows;
    return DriverQueryResult(affectedRows: changes);
  }

  @override
  Future<DriverQueryResult> executePaged(
    String sql, {
    required int limit,
    required int offset,
  }) async {
    final pagedSql = '$sql LIMIT $limit OFFSET $offset';
    return execute(pagedSql);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Server Metadata
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Future<String> getServerVersion() async {
    log.d(_tag, 'getServerVersion()');
    final db = _requireDatabase();
    final result = db.select('SELECT sqlite_version()');
    return result.first.values.first as String;
  }

  @override
  Future<String> getCurrentDatabase() async {
    log.d(_tag, 'getCurrentDatabase()');
    return _config?.filePath ?? 'unknown';
  }

  @override
  Future<String> getCurrentUser() async {
    log.d(_tag, 'getCurrentUser()');
    return 'local';
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Schema Introspection
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Future<List<SchemaInfo>> getSchemas() async {
    log.d(_tag, 'getSchemas()');
    final db = _requireDatabase();

    final result = db.select('PRAGMA database_list');

    return result.map((row) {
      final schemaName = row['name'] as String;

      // Count tables in this schema.
      int tableCount = 0;
      int viewCount = 0;
      try {
        final tables = db.select(
          "SELECT type, COUNT(*) AS cnt FROM ${_quoteIdentifier(schemaName)}.sqlite_master "
          "WHERE type IN ('table', 'view') AND name NOT LIKE 'sqlite_%' "
          'GROUP BY type',
        );
        for (final t in tables) {
          final type = t['type'] as String;
          final cnt = t['cnt'] as int;
          if (type == 'table') tableCount = cnt;
          if (type == 'view') viewCount = cnt;
        }
      } on Exception catch (_) {
        // If schema is not accessible, counts remain zero.
      }

      return SchemaInfo(
        name: schemaName,
        owner: 'local',
        tableCount: tableCount,
        viewCount: viewCount,
        sequenceCount: 0,
      );
    }).toList();
  }

  @override
  Future<List<TableInfo>> getTables(String schemaName) async {
    log.d(_tag, 'getTables($schemaName)');
    final db = _requireDatabase();

    final result = db.select(
      "SELECT name, type FROM ${_quoteIdentifier(schemaName)}.sqlite_master "
      "WHERE type IN ('table', 'view') AND name NOT LIKE 'sqlite_%' "
      'ORDER BY name',
    );

    final tables = <TableInfo>[];
    for (final row in result) {
      final name = row['name'] as String;
      final type = row['type'] as String;

      // Get row count for tables.
      int rowEstimate = 0;
      if (type == 'table') {
        try {
          final countResult = db.select(
            'SELECT COUNT(*) AS cnt FROM ${_quoteIdentifier(schemaName)}.${_quoteIdentifier(name)}',
          );
          rowEstimate = countResult.first['cnt'] as int;
        } on Exception catch (_) {
          // Table may not be readable.
        }
      }

      tables.add(TableInfo(
        schemaName: schemaName,
        tableName: name,
        objectType: type == 'view' ? ObjectType.view : ObjectType.table,
        rowEstimate: rowEstimate,
      ));
    }

    return tables;
  }

  @override
  Future<List<ColumnInfo>> getColumns(
    String schemaName,
    String tableName,
  ) async {
    log.d(_tag, 'getColumns($schemaName.$tableName)');
    final db = _requireDatabase();

    final result = db.select(
      'PRAGMA ${_quoteIdentifier(schemaName)}.table_info(${_quoteIdentifier(tableName)})',
    );

    // Collect primary key column names for categorization.
    final pkColumns = <String>{};
    for (final row in result) {
      if ((row['pk'] as int) > 0) {
        pkColumns.add(row['name'] as String);
      }
    }

    // Collect foreign key column names for categorization.
    final fkColumns = <String>{};
    try {
      final fkResult = db.select(
        'PRAGMA ${_quoteIdentifier(schemaName)}.foreign_key_list(${_quoteIdentifier(tableName)})',
      );
      for (final fkRow in fkResult) {
        fkColumns.add(fkRow['from'] as String);
      }
    } on Exception catch (_) {
      // Foreign keys may not be available.
    }

    return result.map((row) {
      final cid = row['cid'] as int;
      final colName = row['name'] as String;
      final colType = row['type'] as String;
      final notNull = (row['notnull'] as int) == 1;
      final dfltValue = row['dflt_value'];
      final pk = (row['pk'] as int) > 0;

      // Determine if this is an INTEGER PRIMARY KEY (auto-increment alias).
      final isAutoIncrement =
          pk && colType.toUpperCase().contains('INTEGER') && pkColumns.length == 1;

      return ColumnInfo(
        columnName: colName,
        ordinalPosition: cid + 1,
        dataType: colType,
        udtName: colType,
        isNullable: !notNull,
        columnDefault: dfltValue?.toString(),
        isIdentity: isAutoIncrement,
        category: _categorizeColumn(
          colName, dfltValue?.toString(), isAutoIncrement, pkColumns, fkColumns,
        ),
      );
    }).toList();
  }

  @override
  Future<List<ConstraintInfo>> getConstraints(
    String schemaName,
    String tableName,
  ) async {
    log.d(_tag, 'getConstraints($schemaName.$tableName)');
    final db = _requireDatabase();

    final constraints = <ConstraintInfo>[];

    // Extract primary key columns from PRAGMA table_info.
    final tableInfo = db.select(
      'PRAGMA ${_quoteIdentifier(schemaName)}.table_info(${_quoteIdentifier(tableName)})',
    );
    final pkColumns = <String>[];
    for (final row in tableInfo) {
      if ((row['pk'] as int) > 0) {
        pkColumns.add(row['name'] as String);
      }
    }
    if (pkColumns.isNotEmpty) {
      constraints.add(ConstraintInfo(
        constraintName: 'pk_$tableName',
        constraintType: ConstraintType.primaryKey,
        columns: pkColumns,
      ));
    }

    return constraints;
  }

  @override
  Future<List<ForeignKeyInfo>> getForeignKeys(
    String schemaName,
    String tableName,
  ) async {
    log.d(_tag, 'getForeignKeys($schemaName.$tableName)');
    final db = _requireDatabase();

    final result = db.select(
      'PRAGMA ${_quoteIdentifier(schemaName)}.foreign_key_list(${_quoteIdentifier(tableName)})',
    );

    // Group by FK id to handle composite foreign keys.
    final fkMap = <int, _ForeignKeyBuilder>{};
    for (final row in result) {
      final id = row['id'] as int;
      final builder = fkMap.putIfAbsent(id, () => _ForeignKeyBuilder());
      builder.referencedTable = row['table'] as String;
      builder.columns.add(row['from'] as String);
      builder.referencedColumns.add(row['to'] as String);
      builder.onUpdate = row['on_update'] as String;
      builder.onDelete = row['on_delete'] as String;
    }

    return fkMap.entries.map((entry) {
      final builder = entry.value;
      return ForeignKeyInfo(
        constraintName: 'fk_${tableName}_${entry.key}',
        columns: builder.columns,
        referencedSchema: schemaName,
        referencedTable: builder.referencedTable,
        referencedColumns: builder.referencedColumns,
        onUpdate: builder.onUpdate,
        onDelete: builder.onDelete,
      );
    }).toList();
  }

  @override
  Future<List<ForeignKeyInfo>> getIncomingReferences(
    String schemaName,
    String tableName,
  ) async {
    log.d(_tag, 'getIncomingReferences($schemaName.$tableName)');
    final db = _requireDatabase();

    final incoming = <ForeignKeyInfo>[];

    // Query all tables in the schema and check their foreign keys.
    final tables = db.select(
      "SELECT name FROM ${_quoteIdentifier(schemaName)}.sqlite_master "
      "WHERE type = 'table' AND name NOT LIKE 'sqlite_%' "
      'ORDER BY name',
    );

    for (final tableRow in tables) {
      final srcTable = tableRow['name'] as String;
      if (srcTable == tableName) continue;

      final fkResult = db.select(
        'PRAGMA ${_quoteIdentifier(schemaName)}.foreign_key_list(${_quoteIdentifier(srcTable)})',
      );

      final fkMap = <int, _ForeignKeyBuilder>{};
      for (final row in fkResult) {
        final refTable = row['table'] as String;
        if (refTable != tableName) continue;

        final id = row['id'] as int;
        final builder = fkMap.putIfAbsent(id, () => _ForeignKeyBuilder());
        builder.referencedTable = refTable;
        builder.columns.add(row['from'] as String);
        builder.referencedColumns.add(row['to'] as String);
        builder.onUpdate = row['on_update'] as String;
        builder.onDelete = row['on_delete'] as String;
      }

      for (final entry in fkMap.entries) {
        final builder = entry.value;
        incoming.add(ForeignKeyInfo(
          constraintName: 'fk_${srcTable}_${entry.key}',
          columns: builder.columns,
          referencedSchema: schemaName,
          referencedTable: srcTable,
          referencedColumns: builder.referencedColumns,
          onUpdate: builder.onUpdate,
          onDelete: builder.onDelete,
        ));
      }
    }

    return incoming;
  }

  @override
  Future<List<IndexInfo>> getIndexes(
    String schemaName,
    String tableName,
  ) async {
    log.d(_tag, 'getIndexes($schemaName.$tableName)');
    final db = _requireDatabase();

    final indexList = db.select(
      'PRAGMA ${_quoteIdentifier(schemaName)}.index_list(${_quoteIdentifier(tableName)})',
    );

    final indexes = <IndexInfo>[];
    for (final row in indexList) {
      final indexName = row['name'] as String;
      final isUnique = (row['unique'] as int) == 1;
      final origin = row['origin'] as String;

      // Get columns for this index.
      final indexInfo = db.select(
        'PRAGMA ${_quoteIdentifier(schemaName)}.index_info(${_quoteIdentifier(indexName)})',
      );
      final columns = indexInfo.map((r) => r['name'] as String).toList();

      indexes.add(IndexInfo(
        indexName: indexName,
        indexType: IndexType.btree,
        columns: columns,
        isUnique: isUnique,
        isPrimary: origin == 'pk',
        isValid: true,
      ));
    }

    return indexes;
  }

  @override
  Future<List<SequenceInfo>> getSequences(String schemaName) async {
    log.d(_tag, 'getSequences($schemaName)');
    // SQLite does not have user-defined sequences. The sqlite_sequence table
    // tracks AUTOINCREMENT counters but is not equivalent to SQL sequences.
    return const [];
  }

  @override
  Future<TableStatistics> getTableStatistics(
    String schemaName,
    String tableName,
  ) async {
    log.d(_tag, 'getTableStatistics($schemaName.$tableName)');
    final db = _requireDatabase();

    int liveRows = 0;
    try {
      final result = db.select(
        'SELECT COUNT(*) AS cnt FROM ${_quoteIdentifier(schemaName)}.${_quoteIdentifier(tableName)}',
      );
      liveRows = result.first['cnt'] as int;
    } on Exception catch (_) {
      // Table may not be readable.
    }

    return TableStatistics(liveRowCount: liveRows);
  }

  @override
  Future<String> getTableDdl(String schemaName, String tableName) async {
    log.d(_tag, 'getTableDdl($schemaName.$tableName)');
    final db = _requireDatabase();

    final result = db.select(
      "SELECT sql FROM ${_quoteIdentifier(schemaName)}.sqlite_master "
      "WHERE type = 'table' AND name = ?",
      [tableName],
    );

    if (result.isEmpty) {
      return '-- Table $tableName not found in schema $schemaName';
    }

    final ddl = result.first['sql'] as String?;
    return ddl != null ? '$ddl;' : '-- DDL not available for $tableName';
  }

  @override
  Future<int> getRowCountEstimate(
    String schemaName,
    String tableName,
  ) async {
    log.d(_tag, 'getRowCountEstimate($schemaName.$tableName)');
    final db = _requireDatabase();

    final result = db.select(
      'SELECT COUNT(*) AS cnt FROM ${_quoteIdentifier(schemaName)}.${_quoteIdentifier(tableName)}',
    );
    return result.first['cnt'] as int;
  }

  @override
  Future<String> getDatabaseSize() async {
    log.d(_tag, 'getDatabaseSize()');
    final db = _requireDatabase();

    final pageCountResult = db.select('PRAGMA page_count');
    final pageSizeResult = db.select('PRAGMA page_size');

    final pageCount = pageCountResult.first.values.first as int;
    final pageSize = pageSizeResult.first.values.first as int;
    final totalBytes = pageCount * pageSize;

    return _formatBytes(totalBytes);
  }

  @override
  Future<List<TableInfo>> searchObjects(String query) async {
    log.d(_tag, 'searchObjects("$query")');
    final db = _requireDatabase();
    final pattern = '%${query.toLowerCase()}%';

    final result = db.select(
      "SELECT name, type FROM sqlite_master "
      "WHERE type IN ('table', 'view') "
      "AND name NOT LIKE 'sqlite_%' "
      'AND LOWER(name) LIKE ? '
      'ORDER BY name',
      [pattern],
    );

    return result.map((row) {
      final name = row['name'] as String;
      final type = row['type'] as String;
      return TableInfo(
        schemaName: 'main',
        tableName: name,
        objectType: type == 'view' ? ObjectType.view : ObjectType.table,
      );
    }).toList();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Engine-Specific Operations
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Future<bool> cancelQuery() async {
    log.i(_tag, 'cancelQuery() — SQLite has limited cancellation support');
    // SQLite does not support async query cancellation in the same way as
    // network-based databases. The sqlite3_interrupt() API can signal a
    // running query to abort, but the Dart sqlite3 FFI package does not
    // expose it directly. Disposing the database would close the connection
    // entirely, which is too destructive for a cancel operation.
    return false;
  }

  @override
  Future<String> explainQuery(String sql, {bool analyze = false}) async {
    log.d(_tag, 'explainQuery(analyze=$analyze)');
    final db = _requireDatabase();
    final prefix = analyze ? 'EXPLAIN QUERY PLAN' : 'EXPLAIN QUERY PLAN';
    final result = db.select('$prefix $sql');

    final lines = <String>[];
    for (final row in result) {
      final values = row.values.map((v) => v.toString()).join(' | ');
      lines.add(values);
    }
    return lines.join('\n');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Internal Helpers
  // ─────────────────────────────────────────────────────────────────────────

  /// Returns the active database or throws [StateError].
  sqlite.Database _requireDatabase() {
    if (_database == null) {
      throw StateError('SQLite driver is not connected');
    }
    return _database!;
  }

  /// Converts a [sqlite.ResultSet] to a [DriverQueryResult].
  DriverQueryResult _toDriverResult(sqlite.ResultSet resultSet) {
    final columnNames = resultSet.columnNames;
    final columnTypes = columnNames.map((_) => 'TEXT').toList();
    final rows = resultSet.map((row) => row.values.toList()).toList();

    return DriverQueryResult(
      columnNames: columnNames,
      columnTypes: columnTypes,
      rows: rows,
      affectedRows: rows.length,
    );
  }

  /// Returns `true` if [sql] is a SELECT-like query that returns rows.
  bool _isSelectQuery(String sql) {
    final trimmed = sql.trimLeft().toUpperCase();
    return trimmed.startsWith('SELECT') ||
        trimmed.startsWith('WITH') ||
        trimmed.startsWith('TABLE') ||
        trimmed.startsWith('VALUES') ||
        trimmed.startsWith('PRAGMA') ||
        trimmed.startsWith('EXPLAIN');
  }

  /// Categorizes a column based on its name, default value, and key membership.
  ColumnCategory _categorizeColumn(
    String? columnName,
    String? columnDefault,
    bool isIdentity,
    Set<String> pkColumns,
    Set<String> fkColumns,
  ) {
    if (columnName != null && pkColumns.contains(columnName)) {
      return ColumnCategory.primaryKey;
    }
    if (columnName != null && fkColumns.contains(columnName)) {
      return ColumnCategory.foreignKey;
    }
    if (isIdentity) return ColumnCategory.serial;
    return ColumnCategory.regular;
  }

  /// Quotes a SQLite identifier with double quotes.
  String _quoteIdentifier(String name) => '"$name"';

  /// Formats a byte count as a human-readable string.
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    if (mb < 1024) return '${mb.toStringAsFixed(1)} MB';
    final gb = mb / 1024;
    return '${gb.toStringAsFixed(2)} GB';
  }
}

/// Internal helper for building composite foreign key info.
class _ForeignKeyBuilder {
  /// The referenced table name.
  String? referencedTable;

  /// Source column names.
  final List<String> columns = [];

  /// Referenced column names.
  final List<String> referencedColumns = [];

  /// ON UPDATE action.
  String? onUpdate;

  /// ON DELETE action.
  String? onDelete;
}
