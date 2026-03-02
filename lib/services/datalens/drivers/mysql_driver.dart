/// MySQL / MariaDB driver adapter for DataLens.
///
/// Implements [DatabaseDriverAdapter] using the `mysql_client` package for
/// native TCP connections. All schema introspection queries target
/// `information_schema` views, which are shared between MySQL and MariaDB.
///
/// The driver accepts either [DatabaseDriver.mysql] or [DatabaseDriver.mariadb]
/// and adjusts its [SqlDialect] accordingly, though both engines share
/// identical query syntax for the operations provided here.
library;

import 'package:mysql_client/mysql_client.dart';

import '../../../models/datalens_enums.dart';
import '../../../models/datalens_models.dart';
import '../../logging/log_service.dart';
import 'database_driver.dart';

/// MySQL / MariaDB implementation of [DatabaseDriverAdapter].
///
/// Uses the `mysql_client` package to establish a TCP connection and execute
/// raw SQL. Schema introspection is performed entirely through
/// `information_schema` queries, which are compatible with both MySQL 8+ and
/// MariaDB 10+.
class MysqlDriver implements DatabaseDriverAdapter {
  static const String _tag = 'MysqlDriver';

  /// The active MySQL connection, or `null` if not connected.
  MySQLConnection? _connection;

  /// The database driver type (MySQL or MariaDB).
  final DatabaseDriver _driverType;

  /// Creates a [MysqlDriver].
  ///
  /// [driverType] defaults to [DatabaseDriver.mysql] but may be set to
  /// [DatabaseDriver.mariadb] for MariaDB connections. The driver type
  /// determines which [SqlDialect] is returned by [dialect].
  MysqlDriver({DatabaseDriver driverType = DatabaseDriver.mysql})
      : assert(
          driverType == DatabaseDriver.mysql ||
              driverType == DatabaseDriver.mariadb,
          'MysqlDriver only supports mysql or mariadb driver types',
        ),
        _driverType = driverType;

  @override
  DatabaseDriver get driverType => _driverType;

  @override
  SqlDialect get dialect => _driverType == DatabaseDriver.mariadb
      ? SqlDialect.mariadb
      : SqlDialect.mysql;

  @override
  bool get isOpen => _connection != null && _connection!.connected;

  /// Returns the underlying [MySQLConnection] for legacy callers.
  ///
  /// Throws [StateError] if not connected.
  MySQLConnection get rawConnection {
    if (_connection == null) {
      throw StateError('MySQL driver is not connected');
    }
    return _connection!;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Connection Lifecycle
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Future<void> connect(DatabaseConnection config) async {
    log.d(_tag, 'connect(${config.host}:${config.port})');
    _connection = await MySQLConnection.createConnection(
      host: config.host ?? 'localhost',
      port: config.port ?? 3306,
      userName: config.username ?? '',
      password: config.password ?? '',
      databaseName: config.database ?? '',
      secure: config.useSsl ?? false,
    );
    await _connection!.connect(
      timeoutMs: ((config.connectionTimeout ?? 10) * 1000),
    );
  }

  @override
  Future<void> close() async {
    await _connection?.close();
    _connection = null;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Query Execution
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Future<DriverQueryResult> execute(String sql) async {
    final conn = _requireConnection();
    final result = await conn.execute(sql);
    return _toDriverResult(result, sql);
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
    final conn = _requireConnection();
    final result = await conn.execute('SELECT VERSION()');
    return result.rows.first.colAt(0) ?? '';
  }

  @override
  Future<String> getCurrentDatabase() async {
    final conn = _requireConnection();
    final result = await conn.execute('SELECT DATABASE()');
    return result.rows.first.colAt(0) ?? '';
  }

  @override
  Future<String> getCurrentUser() async {
    final conn = _requireConnection();
    final result = await conn.execute('SELECT CURRENT_USER()');
    return result.rows.first.colAt(0) ?? '';
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Schema Introspection
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Future<List<SchemaInfo>> getSchemas() async {
    log.d(_tag, 'getSchemas()');
    final conn = _requireConnection();

    final result = await conn.execute('''
      SELECT
        s.SCHEMA_NAME AS schema_name,
        (SELECT COUNT(*) FROM information_schema.TABLES t
         WHERE t.TABLE_SCHEMA = s.SCHEMA_NAME AND t.TABLE_TYPE = 'BASE TABLE') AS table_count,
        (SELECT COUNT(*) FROM information_schema.TABLES t
         WHERE t.TABLE_SCHEMA = s.SCHEMA_NAME AND t.TABLE_TYPE = 'VIEW') AS view_count
      FROM information_schema.SCHEMATA s
      WHERE s.SCHEMA_NAME NOT IN ('information_schema', 'mysql', 'performance_schema', 'sys')
      ORDER BY s.SCHEMA_NAME
    ''');

    return result.rows.map((row) {
      final m = row.assoc();
      return SchemaInfo(
        name: m['schema_name'],
        tableCount: _toInt(m['table_count']),
        viewCount: _toInt(m['view_count']),
        sequenceCount: 0,
      );
    }).toList();
  }

  @override
  Future<List<TableInfo>> getTables(String schemaName) async {
    log.d(_tag, 'getTables($schemaName)');
    final conn = _requireConnection();
    final escaped = _escapeString(schemaName);

    final result = await conn.execute('''
      SELECT
        t.TABLE_NAME AS table_name,
        t.TABLE_COMMENT AS comment,
        t.TABLE_TYPE AS table_type,
        t.TABLE_ROWS AS row_estimate,
        t.DATA_LENGTH AS data_length,
        t.INDEX_LENGTH AS index_length,
        t.ENGINE AS engine
      FROM information_schema.TABLES t
      WHERE t.TABLE_SCHEMA = '$escaped'
      ORDER BY t.TABLE_NAME
    ''');

    return result.rows.map((row) {
      final m = row.assoc();
      final dataLen = _toInt(m['data_length']) ?? 0;
      final idxLen = _toInt(m['index_length']) ?? 0;
      return TableInfo(
        schemaName: schemaName,
        tableName: m['table_name'],
        tableComment: m['comment'],
        objectType: _mapTableType(m['table_type']),
        rowEstimate: _toInt(m['row_estimate']),
        tableSize: _formatBytes(dataLen),
        totalSize: _formatBytes(dataLen + idxLen),
        owner: m['engine'],
      );
    }).toList();
  }

  @override
  Future<List<ColumnInfo>> getColumns(
    String schemaName,
    String tableName,
  ) async {
    log.d(_tag, 'getColumns($schemaName.$tableName)');
    final conn = _requireConnection();
    final escapedSchema = _escapeString(schemaName);
    final escapedTable = _escapeString(tableName);

    // Primary key columns.
    final pkResult = await conn.execute('''
      SELECT kcu.COLUMN_NAME
      FROM information_schema.TABLE_CONSTRAINTS tc
      JOIN information_schema.KEY_COLUMN_USAGE kcu
        ON tc.CONSTRAINT_NAME = kcu.CONSTRAINT_NAME
        AND tc.TABLE_SCHEMA = kcu.TABLE_SCHEMA
        AND tc.TABLE_NAME = kcu.TABLE_NAME
      WHERE tc.CONSTRAINT_TYPE = 'PRIMARY KEY'
        AND tc.TABLE_SCHEMA = '$escapedSchema'
        AND tc.TABLE_NAME = '$escapedTable'
    ''');
    final pkColumns =
        pkResult.rows.map((r) => r.colAt(0) ?? '').toSet();

    // Foreign key columns.
    final fkResult = await conn.execute('''
      SELECT kcu.COLUMN_NAME
      FROM information_schema.TABLE_CONSTRAINTS tc
      JOIN information_schema.KEY_COLUMN_USAGE kcu
        ON tc.CONSTRAINT_NAME = kcu.CONSTRAINT_NAME
        AND tc.TABLE_SCHEMA = kcu.TABLE_SCHEMA
        AND tc.TABLE_NAME = kcu.TABLE_NAME
      WHERE tc.CONSTRAINT_TYPE = 'FOREIGN KEY'
        AND tc.TABLE_SCHEMA = '$escapedSchema'
        AND tc.TABLE_NAME = '$escapedTable'
    ''');
    final fkColumns =
        fkResult.rows.map((r) => r.colAt(0) ?? '').toSet();

    // Full column metadata.
    final result = await conn.execute('''
      SELECT
        c.COLUMN_NAME AS column_name,
        c.ORDINAL_POSITION AS ordinal_position,
        c.DATA_TYPE AS data_type,
        c.COLUMN_TYPE AS column_type,
        c.IS_NULLABLE AS is_nullable,
        c.COLUMN_DEFAULT AS column_default,
        c.EXTRA AS extra,
        c.CHARACTER_MAXIMUM_LENGTH AS char_max_length,
        c.NUMERIC_PRECISION AS numeric_precision,
        c.NUMERIC_SCALE AS numeric_scale,
        c.COLLATION_NAME AS collation_name,
        c.COLUMN_COMMENT AS comment
      FROM information_schema.COLUMNS c
      WHERE c.TABLE_SCHEMA = '$escapedSchema'
        AND c.TABLE_NAME = '$escapedTable'
      ORDER BY c.ORDINAL_POSITION
    ''');

    return result.rows.map((row) {
      final m = row.assoc();
      final colName = m['column_name'];
      final colDefault = m['column_default'];
      final extra = m['extra'] ?? '';
      final isAutoIncrement = extra.contains('auto_increment');

      return ColumnInfo(
        columnName: colName,
        ordinalPosition: _toInt(m['ordinal_position']),
        dataType: m['data_type'],
        udtName: m['column_type'],
        isNullable: m['is_nullable'] == 'YES',
        columnDefault: colDefault,
        isIdentity: isAutoIncrement,
        identityGeneration: isAutoIncrement ? 'AUTO_INCREMENT' : null,
        characterMaxLength: _toInt(m['char_max_length']),
        numericPrecision: _toInt(m['numeric_precision']),
        numericScale: _toInt(m['numeric_scale']),
        collation: m['collation_name'],
        comment: (m['comment']?.isNotEmpty ?? false) ? m['comment'] : null,
        category: _categorizeColumn(
          colName, colDefault, isAutoIncrement, pkColumns, fkColumns,
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
    final conn = _requireConnection();
    final escapedSchema = _escapeString(schemaName);
    final escapedTable = _escapeString(tableName);

    final result = await conn.execute('''
      SELECT
        tc.CONSTRAINT_NAME AS constraint_name,
        tc.CONSTRAINT_TYPE AS constraint_type,
        GROUP_CONCAT(kcu.COLUMN_NAME ORDER BY kcu.ORDINAL_POSITION SEPARATOR ',') AS columns
      FROM information_schema.TABLE_CONSTRAINTS tc
      LEFT JOIN information_schema.KEY_COLUMN_USAGE kcu
        ON tc.CONSTRAINT_NAME = kcu.CONSTRAINT_NAME
        AND tc.TABLE_SCHEMA = kcu.TABLE_SCHEMA
        AND tc.TABLE_NAME = kcu.TABLE_NAME
      WHERE tc.TABLE_SCHEMA = '$escapedSchema'
        AND tc.TABLE_NAME = '$escapedTable'
        AND tc.CONSTRAINT_TYPE != 'FOREIGN KEY'
      GROUP BY tc.CONSTRAINT_NAME, tc.CONSTRAINT_TYPE
      ORDER BY tc.CONSTRAINT_NAME
    ''');

    return result.rows.map((row) {
      final m = row.assoc();
      return ConstraintInfo(
        constraintName: m['constraint_name'],
        constraintType: _mapConstraintType(m['constraint_type']),
        columns: _csvToList(m['columns']),
      );
    }).toList();
  }

  @override
  Future<List<ForeignKeyInfo>> getForeignKeys(
    String schemaName,
    String tableName,
  ) async {
    log.d(_tag, 'getForeignKeys($schemaName.$tableName)');
    final conn = _requireConnection();
    final escapedSchema = _escapeString(schemaName);
    final escapedTable = _escapeString(tableName);

    final result = await conn.execute('''
      SELECT
        tc.CONSTRAINT_NAME AS constraint_name,
        GROUP_CONCAT(DISTINCT kcu.COLUMN_NAME ORDER BY kcu.ORDINAL_POSITION SEPARATOR ',') AS columns,
        kcu.REFERENCED_TABLE_SCHEMA AS ref_schema,
        kcu.REFERENCED_TABLE_NAME AS ref_table,
        GROUP_CONCAT(DISTINCT kcu.REFERENCED_COLUMN_NAME ORDER BY kcu.ORDINAL_POSITION SEPARATOR ',') AS ref_columns,
        rc.UPDATE_RULE AS update_rule,
        rc.DELETE_RULE AS delete_rule
      FROM information_schema.TABLE_CONSTRAINTS tc
      JOIN information_schema.KEY_COLUMN_USAGE kcu
        ON tc.CONSTRAINT_NAME = kcu.CONSTRAINT_NAME
        AND tc.TABLE_SCHEMA = kcu.TABLE_SCHEMA
        AND tc.TABLE_NAME = kcu.TABLE_NAME
      JOIN information_schema.REFERENTIAL_CONSTRAINTS rc
        ON tc.CONSTRAINT_NAME = rc.CONSTRAINT_NAME
        AND tc.CONSTRAINT_SCHEMA = rc.CONSTRAINT_SCHEMA
      WHERE tc.CONSTRAINT_TYPE = 'FOREIGN KEY'
        AND tc.TABLE_SCHEMA = '$escapedSchema'
        AND tc.TABLE_NAME = '$escapedTable'
      GROUP BY tc.CONSTRAINT_NAME, kcu.REFERENCED_TABLE_SCHEMA,
               kcu.REFERENCED_TABLE_NAME, rc.UPDATE_RULE, rc.DELETE_RULE
      ORDER BY tc.CONSTRAINT_NAME
    ''');

    return result.rows.map((row) {
      final m = row.assoc();
      return ForeignKeyInfo(
        constraintName: m['constraint_name'],
        columns: _csvToList(m['columns']),
        referencedSchema: m['ref_schema'],
        referencedTable: m['ref_table'],
        referencedColumns: _csvToList(m['ref_columns']),
        onUpdate: m['update_rule'],
        onDelete: m['delete_rule'],
      );
    }).toList();
  }

  @override
  Future<List<ForeignKeyInfo>> getIncomingReferences(
    String schemaName,
    String tableName,
  ) async {
    log.d(_tag, 'getIncomingReferences($schemaName.$tableName)');
    final conn = _requireConnection();
    final escapedSchema = _escapeString(schemaName);
    final escapedTable = _escapeString(tableName);

    final result = await conn.execute('''
      SELECT
        tc.CONSTRAINT_NAME AS constraint_name,
        GROUP_CONCAT(DISTINCT kcu.COLUMN_NAME ORDER BY kcu.ORDINAL_POSITION SEPARATOR ',') AS columns,
        kcu.TABLE_SCHEMA AS src_schema,
        kcu.TABLE_NAME AS src_table,
        GROUP_CONCAT(DISTINCT kcu.REFERENCED_COLUMN_NAME ORDER BY kcu.ORDINAL_POSITION SEPARATOR ',') AS ref_columns,
        rc.UPDATE_RULE AS update_rule,
        rc.DELETE_RULE AS delete_rule
      FROM information_schema.KEY_COLUMN_USAGE kcu
      JOIN information_schema.TABLE_CONSTRAINTS tc
        ON kcu.CONSTRAINT_NAME = tc.CONSTRAINT_NAME
        AND kcu.TABLE_SCHEMA = tc.TABLE_SCHEMA
        AND kcu.TABLE_NAME = tc.TABLE_NAME
      JOIN information_schema.REFERENTIAL_CONSTRAINTS rc
        ON tc.CONSTRAINT_NAME = rc.CONSTRAINT_NAME
        AND tc.CONSTRAINT_SCHEMA = rc.CONSTRAINT_SCHEMA
      WHERE tc.CONSTRAINT_TYPE = 'FOREIGN KEY'
        AND kcu.REFERENCED_TABLE_SCHEMA = '$escapedSchema'
        AND kcu.REFERENCED_TABLE_NAME = '$escapedTable'
      GROUP BY tc.CONSTRAINT_NAME, kcu.TABLE_SCHEMA, kcu.TABLE_NAME,
               rc.UPDATE_RULE, rc.DELETE_RULE
      ORDER BY tc.CONSTRAINT_NAME
    ''');

    return result.rows.map((row) {
      final m = row.assoc();
      return ForeignKeyInfo(
        constraintName: m['constraint_name'],
        columns: _csvToList(m['columns']),
        referencedSchema: m['src_schema'],
        referencedTable: m['src_table'],
        referencedColumns: _csvToList(m['ref_columns']),
        onUpdate: m['update_rule'],
        onDelete: m['delete_rule'],
      );
    }).toList();
  }

  @override
  Future<List<IndexInfo>> getIndexes(
    String schemaName,
    String tableName,
  ) async {
    log.d(_tag, 'getIndexes($schemaName.$tableName)');
    final conn = _requireConnection();
    final escapedSchema = _escapeString(schemaName);
    final escapedTable = _escapeString(tableName);

    final result = await conn.execute('''
      SELECT
        s.INDEX_NAME AS index_name,
        s.INDEX_TYPE AS index_type,
        GROUP_CONCAT(s.COLUMN_NAME ORDER BY s.SEQ_IN_INDEX SEPARATOR ',') AS columns,
        s.NON_UNIQUE AS non_unique
      FROM information_schema.STATISTICS s
      WHERE s.TABLE_SCHEMA = '$escapedSchema'
        AND s.TABLE_NAME = '$escapedTable'
      GROUP BY s.INDEX_NAME, s.INDEX_TYPE, s.NON_UNIQUE
      ORDER BY s.INDEX_NAME
    ''');

    return result.rows.map((row) {
      final m = row.assoc();
      final indexName = m['index_name'];
      final isPrimary = indexName == 'PRIMARY';
      final isUnique = m['non_unique'] == '0';
      return IndexInfo(
        indexName: indexName,
        indexType: _mapIndexType(m['index_type']),
        columns: _csvToList(m['columns']),
        isUnique: isUnique,
        isPrimary: isPrimary,
      );
    }).toList();
  }

  @override
  Future<List<SequenceInfo>> getSequences(String schemaName) async {
    log.d(_tag, 'getSequences($schemaName)');
    // MySQL / MariaDB does not have standalone sequences — AUTO_INCREMENT
    // columns are used instead. Return an empty list.
    return const [];
  }

  @override
  Future<TableStatistics> getTableStatistics(
    String schemaName,
    String tableName,
  ) async {
    log.d(_tag, 'getTableStatistics($schemaName.$tableName)');
    final conn = _requireConnection();
    final escapedSchema = _escapeString(schemaName);
    final escapedTable = _escapeString(tableName);

    final result = await conn.execute('''
      SELECT
        t.TABLE_ROWS AS live_rows,
        t.DATA_LENGTH AS data_length,
        t.INDEX_LENGTH AS index_length,
        t.AUTO_INCREMENT AS auto_increment,
        t.CREATE_TIME AS create_time,
        t.UPDATE_TIME AS update_time
      FROM information_schema.TABLES t
      WHERE t.TABLE_SCHEMA = '$escapedSchema'
        AND t.TABLE_NAME = '$escapedTable'
    ''');

    if (result.rows.isEmpty) return const TableStatistics();

    final m = result.rows.first.assoc();
    return TableStatistics(
      liveRowCount: _toInt(m['live_rows']),
    );
  }

  @override
  Future<String> getTableDdl(String schemaName, String tableName) async {
    log.d(_tag, 'getTableDdl($schemaName.$tableName)');
    final conn = _requireConnection();
    final escapedSchema = _escapeString(schemaName);
    final escapedTable = _escapeString(tableName);

    final result = await conn.execute(
      'SHOW CREATE TABLE `$escapedSchema`.`$escapedTable`',
    );

    if (result.rows.isEmpty) return '';
    // SHOW CREATE TABLE returns (Table, Create Table) columns.
    return result.rows.first.colAt(1) ?? '';
  }

  @override
  Future<int> getRowCountEstimate(
    String schemaName,
    String tableName,
  ) async {
    log.d(_tag, 'getRowCountEstimate($schemaName.$tableName)');
    final conn = _requireConnection();
    final escapedSchema = _escapeString(schemaName);
    final escapedTable = _escapeString(tableName);

    final result = await conn.execute('''
      SELECT TABLE_ROWS AS estimate
      FROM information_schema.TABLES
      WHERE TABLE_SCHEMA = '$escapedSchema'
        AND TABLE_NAME = '$escapedTable'
    ''');

    if (result.rows.isEmpty) return 0;
    return _toInt(result.rows.first.colAt(0)) ?? 0;
  }

  @override
  Future<String> getDatabaseSize() async {
    log.d(_tag, 'getDatabaseSize()');
    final conn = _requireConnection();

    final result = await conn.execute('''
      SELECT
        SUM(DATA_LENGTH + INDEX_LENGTH) AS total_bytes
      FROM information_schema.TABLES
      WHERE TABLE_SCHEMA = DATABASE()
    ''');

    if (result.rows.isEmpty) return '0 bytes';
    final totalBytes = _toInt(result.rows.first.colAt(0)) ?? 0;
    return _formatBytes(totalBytes);
  }

  @override
  Future<List<TableInfo>> searchObjects(String query) async {
    log.d(_tag, 'searchObjects("$query")');
    final conn = _requireConnection();
    final pattern = '%${_escapeString(query.toLowerCase())}%';

    final result = await conn.execute('''
      SELECT
        t.TABLE_SCHEMA AS schema_name,
        t.TABLE_NAME AS table_name,
        t.TABLE_COMMENT AS comment,
        t.TABLE_TYPE AS table_type,
        t.TABLE_ROWS AS row_estimate,
        t.DATA_LENGTH AS data_length,
        t.INDEX_LENGTH AS index_length,
        t.ENGINE AS engine
      FROM information_schema.TABLES t
      WHERE t.TABLE_SCHEMA NOT IN ('information_schema', 'mysql', 'performance_schema', 'sys')
        AND LOWER(t.TABLE_NAME) LIKE '$pattern'
      ORDER BY t.TABLE_SCHEMA, t.TABLE_NAME
    ''');

    return result.rows.map((row) {
      final m = row.assoc();
      final dataLen = _toInt(m['data_length']) ?? 0;
      final idxLen = _toInt(m['index_length']) ?? 0;
      return TableInfo(
        schemaName: m['schema_name'],
        tableName: m['table_name'],
        tableComment: m['comment'],
        objectType: _mapTableType(m['table_type']),
        rowEstimate: _toInt(m['row_estimate']),
        tableSize: _formatBytes(dataLen),
        totalSize: _formatBytes(dataLen + idxLen),
        owner: m['engine'],
      );
    }).toList();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Engine-Specific Operations
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Future<bool> cancelQuery() async {
    log.i(_tag, 'cancelQuery()');
    final conn = _requireConnection();
    try {
      // Retrieve the current connection thread ID and kill the running query.
      final idResult = await conn.execute('SELECT CONNECTION_ID()');
      final threadId = idResult.rows.first.colAt(0);
      if (threadId == null) return false;
      await conn.execute('KILL QUERY $threadId');
      return true;
    } on Exception catch (e) {
      log.e(_tag, 'Failed to cancel query', e);
      return false;
    }
  }

  @override
  Future<String> explainQuery(String sql, {bool analyze = false}) async {
    log.d(_tag, 'explainQuery(analyze=$analyze)');
    final conn = _requireConnection();
    final prefix = analyze ? 'EXPLAIN ANALYZE' : 'EXPLAIN';
    final result = await conn.execute('$prefix $sql');

    if (analyze) {
      // EXPLAIN ANALYZE returns a single-column result with the tree output.
      return result.rows.map((row) => row.colAt(0) ?? '').join('\n');
    }

    // Standard EXPLAIN returns a tabular result — join column values per row.
    final buf = StringBuffer();
    for (final row in result.rows) {
      final values = <String>[];
      for (var i = 0; i < result.numOfColumns; i++) {
        values.add(row.colAt(i) ?? 'NULL');
      }
      buf.writeln(values.join('\t'));
    }
    return buf.toString();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Internal Helpers
  // ─────────────────────────────────────────────────────────────────────────

  /// Returns the active connection or throws [StateError].
  MySQLConnection _requireConnection() {
    if (_connection == null) {
      throw StateError('MySQL driver is not connected');
    }
    return _connection!;
  }

  /// Converts a `mysql_client` [IResultSet] into a [DriverQueryResult].
  DriverQueryResult _toDriverResult(IResultSet result, String sql) {
    final isSelect = _isSelectQuery(sql);

    if (isSelect) {
      final columnNames = result.cols.map((c) => c.name).toList();
      final columnTypes = result.cols.map((c) => c.type.toString()).toList();
      final rows = result.rows.map((row) {
        final values = <dynamic>[];
        for (var i = 0; i < result.numOfColumns; i++) {
          values.add(row.typedColAt<dynamic>(i));
        }
        return values;
      }).toList();

      return DriverQueryResult(
        columnNames: columnNames,
        columnTypes: columnTypes,
        rows: rows,
        affectedRows: rows.length,
      );
    }

    return DriverQueryResult(affectedRows: result.affectedRows.toInt());
  }

  /// Returns `true` if [sql] appears to be a SELECT-style statement.
  bool _isSelectQuery(String sql) {
    final trimmed = sql.trimLeft().toUpperCase();
    return trimmed.startsWith('SELECT') ||
        trimmed.startsWith('WITH') ||
        trimmed.startsWith('TABLE') ||
        trimmed.startsWith('VALUES') ||
        trimmed.startsWith('SHOW') ||
        trimmed.startsWith('DESCRIBE') ||
        trimmed.startsWith('EXPLAIN');
  }

  /// Maps a MySQL `TABLE_TYPE` string to an [ObjectType].
  ObjectType _mapTableType(String? tableType) {
    return switch (tableType) {
      'BASE TABLE' => ObjectType.table,
      'VIEW' => ObjectType.view,
      'SYSTEM VIEW' => ObjectType.view,
      _ => ObjectType.table,
    };
  }

  /// Maps a MySQL constraint type string to a [ConstraintType].
  ConstraintType _mapConstraintType(String? type) {
    return switch (type) {
      'PRIMARY KEY' => ConstraintType.primaryKey,
      'FOREIGN KEY' => ConstraintType.foreignKey,
      'UNIQUE' => ConstraintType.unique,
      'CHECK' => ConstraintType.check,
      _ => ConstraintType.check,
    };
  }

  /// Maps a MySQL index type string to an [IndexType].
  IndexType _mapIndexType(String? indexType) {
    return switch (indexType) {
      'BTREE' => IndexType.btree,
      'HASH' => IndexType.hash,
      'FULLTEXT' => IndexType.fulltext,
      'RTREE' => IndexType.rtree,
      _ => IndexType.btree,
    };
  }

  /// Categorizes a column based on its PK/FK/auto-increment status.
  ColumnCategory _categorizeColumn(
    String? columnName,
    String? columnDefault,
    bool isAutoIncrement,
    Set<String> pkColumns,
    Set<String> fkColumns,
  ) {
    if (columnName != null && pkColumns.contains(columnName)) {
      return ColumnCategory.primaryKey;
    }
    if (columnName != null && fkColumns.contains(columnName)) {
      return ColumnCategory.foreignKey;
    }
    if (isAutoIncrement) return ColumnCategory.serial;
    return ColumnCategory.regular;
  }

  /// Safely converts a dynamic value to [int], or returns `null`.
  int? _toInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is BigInt) return value.toInt();
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  /// Splits a comma-separated string into a list of strings.
  ///
  /// Returns `null` if [value] is `null` or empty.
  List<String>? _csvToList(String? value) {
    if (value == null || value.isEmpty) return null;
    return value.split(',').map((s) => s.trim()).toList();
  }

  /// Formats [bytes] into a human-readable size string (KB, MB, GB, etc.).
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes bytes';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// Escapes single quotes in a string for safe interpolation into SQL.
  ///
  /// This is used for `information_schema` queries where parameterized
  /// queries are not practical with the `mysql_client` driver.
  String _escapeString(String value) {
    return value.replaceAll("'", "\\'").replaceAll('`', '\\`');
  }
}
