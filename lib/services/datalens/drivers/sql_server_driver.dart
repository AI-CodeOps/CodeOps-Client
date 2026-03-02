/// SQL Server driver adapter for DataLens.
///
/// Implements [DatabaseDriverAdapter] using the `mssql_connection` package for
/// native TCP connections. All schema introspection queries target SQL Server
/// system catalog views (`sys.*`) and dynamic management views (`sys.dm_*`).
library;

import 'dart:convert';

import 'package:mssql_connection/mssql_connection.dart';

import '../../../models/datalens_enums.dart';
import '../../../models/datalens_models.dart';
import '../../logging/log_service.dart';
import 'database_driver.dart';

/// SQL Server implementation of [DatabaseDriverAdapter].
class SqlServerDriver implements DatabaseDriverAdapter {
  static const String _tag = 'SqlServerDriver';

  /// The active SQL Server connection, or `null` if not connected.
  MssqlConnection? _connection;

  /// Whether the connection is currently open.
  bool _isOpen = false;

  @override
  DatabaseDriver get driverType => DatabaseDriver.sqlServer;

  @override
  SqlDialect get dialect => SqlDialect.sqlServer;

  @override
  bool get isOpen => _isOpen;

  /// Returns the underlying [MssqlConnection] for legacy callers.
  ///
  /// Throws [StateError] if not connected.
  MssqlConnection get rawConnection {
    if (_connection == null) {
      throw StateError('SQL Server driver is not connected');
    }
    return _connection!;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Connection Lifecycle
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Future<void> connect(DatabaseConnection config) async {
    log.d(_tag, 'connect(${config.host}:${config.port})');

    _connection = MssqlConnection.getInstance();

    final connected = await _connection!.connect(
      ip: config.host ?? 'localhost',
      port: (config.port ?? 1433).toString(),
      databaseName: config.database ?? '',
      username: config.username ?? '',
      password: config.password ?? '',
      timeoutInSeconds: config.connectionTimeout ?? 10,
    );
    if (!connected) {
      _connection = null;
      throw StateError('Failed to connect to SQL Server');
    }
    _isOpen = true;
  }

  @override
  Future<void> close() async {
    log.d(_tag, 'close()');
    if (_connection != null) {
      await _connection!.disconnect();
      _connection = null;
    }
    _isOpen = false;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Query Execution
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Future<DriverQueryResult> execute(String sql) async {
    final conn = _requireConnection();
    log.d(_tag, 'execute(${sql.length} chars)');

    final jsonResult = await conn.getData(sql);
    return _parseJsonResult(jsonResult);
  }

  @override
  Future<DriverQueryResult> executePaged(
    String sql, {
    required int limit,
    required int offset,
  }) async {
    // SQL Server uses OFFSET ... ROWS FETCH NEXT ... ROWS ONLY syntax.
    // The query must contain an ORDER BY clause; we wrap with a default
    // if the original query does not include one.
    final trimmed = sql.trimRight();
    final upper = trimmed.toUpperCase();

    String pagedSql;
    if (upper.contains('ORDER BY')) {
      pagedSql = '$trimmed OFFSET $offset ROWS FETCH NEXT $limit ROWS ONLY';
    } else {
      pagedSql = '$trimmed ORDER BY (SELECT NULL) '
          'OFFSET $offset ROWS FETCH NEXT $limit ROWS ONLY';
    }
    return execute(pagedSql);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Server Metadata
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Future<String> getServerVersion() async {
    log.d(_tag, 'getServerVersion()');
    final result = await execute('SELECT @@VERSION AS version');
    if (result.rows.isEmpty) return 'Unknown';
    return result.rows.first.first?.toString() ?? 'Unknown';
  }

  @override
  Future<String> getCurrentDatabase() async {
    log.d(_tag, 'getCurrentDatabase()');
    final result = await execute('SELECT DB_NAME() AS db_name');
    if (result.rows.isEmpty) return 'Unknown';
    return result.rows.first.first?.toString() ?? 'Unknown';
  }

  @override
  Future<String> getCurrentUser() async {
    log.d(_tag, 'getCurrentUser()');
    final result = await execute('SELECT SUSER_SNAME() AS user_name');
    if (result.rows.isEmpty) return 'Unknown';
    return result.rows.first.first?.toString() ?? 'Unknown';
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Schema Introspection
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Future<List<SchemaInfo>> getSchemas() async {
    log.d(_tag, 'getSchemas()');

    final result = await execute('''
      SELECT
        s.name AS schema_name,
        dp.name AS schema_owner,
        (SELECT COUNT(*) FROM sys.objects o
         WHERE o.schema_id = s.schema_id AND o.type = 'U') AS table_count,
        (SELECT COUNT(*) FROM sys.objects o
         WHERE o.schema_id = s.schema_id AND o.type = 'V') AS view_count,
        (SELECT COUNT(*) FROM sys.sequences sq
         WHERE sq.schema_id = s.schema_id) AS sequence_count
      FROM sys.schemas s
      LEFT JOIN sys.database_principals dp ON dp.principal_id = s.principal_id
      WHERE s.name NOT IN (
        'guest', 'INFORMATION_SCHEMA', 'sys',
        'db_owner', 'db_accessadmin', 'db_securityadmin',
        'db_ddladmin', 'db_backupoperator', 'db_datareader',
        'db_datawriter', 'db_denydatareader', 'db_denydatawriter'
      )
      ORDER BY s.name
    ''');

    return result.rows.map((row) {
      final m = _rowToMap(result.columnNames, row);
      return SchemaInfo(
        name: m['schema_name'] as String?,
        owner: m['schema_owner'] as String?,
        tableCount: _toInt(m['table_count']),
        viewCount: _toInt(m['view_count']),
        sequenceCount: _toInt(m['sequence_count']),
      );
    }).toList();
  }

  @override
  Future<List<TableInfo>> getTables(String schemaName) async {
    log.d(_tag, 'getTables($schemaName)');

    final result = await execute('''
      SELECT
        o.name AS table_name,
        ep.value AS comment,
        o.type AS obj_type,
        p.row_count AS row_estimate,
        CAST(ROUND(
          (SUM(a.total_pages) * 8.0) / 1024, 2
        ) AS DECIMAL(18,2)) AS table_size_mb,
        CAST(ROUND(
          (SUM(a.used_pages) * 8.0) / 1024, 2
        ) AS DECIMAL(18,2)) AS used_size_mb
      FROM sys.objects o
      INNER JOIN sys.schemas s ON s.schema_id = o.schema_id
      LEFT JOIN sys.extended_properties ep
        ON ep.major_id = o.object_id AND ep.minor_id = 0 AND ep.name = 'MS_Description'
      LEFT JOIN sys.dm_db_partition_stats p
        ON p.object_id = o.object_id AND p.index_id IN (0, 1)
      LEFT JOIN sys.allocation_units a
        ON a.container_id = p.partition_id
      WHERE s.name = '$schemaName'
        AND o.type IN ('U', 'V')
      GROUP BY o.name, ep.value, o.type, p.row_count
      ORDER BY o.name
    ''');

    return result.rows.map((row) {
      final m = _rowToMap(result.columnNames, row);
      final objType = m['obj_type']?.toString().trim();
      final sizeMb = m['table_size_mb'];

      return TableInfo(
        schemaName: schemaName,
        tableName: m['table_name'] as String?,
        tableComment: m['comment'] as String?,
        objectType: _mapObjectType(objType),
        rowEstimate: _toInt(m['row_estimate']),
        tableSize: sizeMb != null ? '$sizeMb MB' : null,
        totalSize: null,
        owner: null,
      );
    }).toList();
  }

  @override
  Future<List<ColumnInfo>> getColumns(
    String schemaName,
    String tableName,
  ) async {
    log.d(_tag, 'getColumns($schemaName.$tableName)');

    // Primary key columns.
    final pkResult = await execute('''
      SELECT ic.column_id
      FROM sys.indexes i
      INNER JOIN sys.index_columns ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id
      INNER JOIN sys.objects o ON o.object_id = i.object_id
      INNER JOIN sys.schemas s ON s.schema_id = o.schema_id
      WHERE i.is_primary_key = 1
        AND s.name = '$schemaName'
        AND o.name = '$tableName'
    ''');
    final pkColumnIds = pkResult.rows
        .map((r) => _toInt(r.isNotEmpty ? r.first : null))
        .whereType<int>()
        .toSet();

    // Foreign key columns.
    final fkResult = await execute('''
      SELECT fkc.parent_column_id
      FROM sys.foreign_key_columns fkc
      INNER JOIN sys.objects o ON o.object_id = fkc.parent_object_id
      INNER JOIN sys.schemas s ON s.schema_id = o.schema_id
      WHERE s.name = '$schemaName'
        AND o.name = '$tableName'
    ''');
    final fkColumnIds = fkResult.rows
        .map((r) => _toInt(r.isNotEmpty ? r.first : null))
        .whereType<int>()
        .toSet();

    // Full column metadata.
    final result = await execute('''
      SELECT
        c.name AS column_name,
        c.column_id AS ordinal_position,
        t.name AS data_type,
        t.name AS udt_name,
        c.is_nullable,
        dc.definition AS column_default,
        c.is_identity,
        c.max_length AS character_max_length,
        c.precision AS numeric_precision,
        c.scale AS numeric_scale,
        c.collation_name,
        ep.value AS comment,
        c.column_id
      FROM sys.columns c
      INNER JOIN sys.types t ON t.user_type_id = c.user_type_id
      INNER JOIN sys.objects o ON o.object_id = c.object_id
      INNER JOIN sys.schemas s ON s.schema_id = o.schema_id
      LEFT JOIN sys.default_constraints dc ON dc.object_id = c.default_object_id
      LEFT JOIN sys.extended_properties ep
        ON ep.major_id = c.object_id AND ep.minor_id = c.column_id AND ep.name = 'MS_Description'
      WHERE s.name = '$schemaName'
        AND o.name = '$tableName'
      ORDER BY c.column_id
    ''');

    return result.rows.map((row) {
      final m = _rowToMap(result.columnNames, row);
      final colName = m['column_name'] as String?;
      final colDefault = m['column_default'] as String?;
      final isIdentity = _toBool(m['is_identity']);
      final columnId = _toInt(m['column_id']);
      final isNullable = _toBool(m['is_nullable']);

      // Build display data type with length/precision.
      final baseType = m['data_type'] as String?;
      final maxLen = _toInt(m['character_max_length']);
      String? displayType = baseType;
      if (baseType != null && _isCharType(baseType) && maxLen != null) {
        displayType = maxLen == -1 ? '$baseType(max)' : '$baseType($maxLen)';
      }

      return ColumnInfo(
        columnName: colName,
        ordinalPosition: _toInt(m['ordinal_position']),
        dataType: displayType,
        udtName: m['udt_name'] as String?,
        isNullable: isNullable,
        columnDefault: colDefault,
        isIdentity: isIdentity,
        identityGeneration: isIdentity ? 'ALWAYS' : null,
        characterMaxLength: maxLen,
        numericPrecision: _toInt(m['numeric_precision']),
        numericScale: _toInt(m['numeric_scale']),
        collation: m['collation_name'] as String?,
        comment: m['comment'] as String?,
        category: _categorizeColumn(
          columnId,
          colDefault,
          isIdentity,
          pkColumnIds,
          fkColumnIds,
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

    final result = await execute('''
      SELECT
        kc.name AS constraint_name,
        kc.type_desc AS constraint_type,
        STUFF((
          SELECT ', ' + col.name
          FROM sys.index_columns ic
          INNER JOIN sys.columns col ON col.object_id = ic.object_id AND col.column_id = ic.column_id
          WHERE ic.object_id = kc.parent_object_id AND ic.index_id = kc.unique_index_id
          ORDER BY ic.key_ordinal
          FOR XML PATH(''), TYPE
        ).value('.', 'NVARCHAR(MAX)'), 1, 2, '') AS columns,
        NULL AS check_expression,
        0 AS is_deferrable,
        0 AS is_deferred
      FROM sys.key_constraints kc
      INNER JOIN sys.objects o ON o.object_id = kc.parent_object_id
      INNER JOIN sys.schemas s ON s.schema_id = o.schema_id
      WHERE s.name = '$schemaName'
        AND o.name = '$tableName'

      UNION ALL

      SELECT
        cc.name AS constraint_name,
        'CHECK_CONSTRAINT' AS constraint_type,
        NULL AS columns,
        cc.definition AS check_expression,
        0 AS is_deferrable,
        0 AS is_deferred
      FROM sys.check_constraints cc
      INNER JOIN sys.objects o ON o.object_id = cc.parent_object_id
      INNER JOIN sys.schemas s ON s.schema_id = o.schema_id
      WHERE s.name = '$schemaName'
        AND o.name = '$tableName'
      ORDER BY constraint_name
    ''');

    return result.rows.map((row) {
      final m = _rowToMap(result.columnNames, row);
      final columnsStr = m['columns'] as String?;
      return ConstraintInfo(
        constraintName: m['constraint_name'] as String?,
        constraintType: _mapConstraintType(m['constraint_type'] as String?),
        columns: columnsStr?.split(', '),
        checkExpression: m['check_expression'] as String?,
        isDeferrable: _toBool(m['is_deferrable']),
        isDeferred: _toBool(m['is_deferred']),
      );
    }).toList();
  }

  @override
  Future<List<ForeignKeyInfo>> getForeignKeys(
    String schemaName,
    String tableName,
  ) async {
    log.d(_tag, 'getForeignKeys($schemaName.$tableName)');

    final result = await execute('''
      SELECT
        fk.name AS constraint_name,
        STUFF((
          SELECT ', ' + pc.name
          FROM sys.foreign_key_columns fkc2
          INNER JOIN sys.columns pc ON pc.object_id = fkc2.parent_object_id AND pc.column_id = fkc2.parent_column_id
          WHERE fkc2.constraint_object_id = fk.object_id
          ORDER BY fkc2.constraint_column_id
          FOR XML PATH(''), TYPE
        ).value('.', 'NVARCHAR(MAX)'), 1, 2, '') AS columns,
        rs.name AS ref_schema,
        rt.name AS ref_table,
        STUFF((
          SELECT ', ' + rc.name
          FROM sys.foreign_key_columns fkc3
          INNER JOIN sys.columns rc ON rc.object_id = fkc3.referenced_object_id AND rc.column_id = fkc3.referenced_column_id
          WHERE fkc3.constraint_object_id = fk.object_id
          ORDER BY fkc3.constraint_column_id
          FOR XML PATH(''), TYPE
        ).value('.', 'NVARCHAR(MAX)'), 1, 2, '') AS ref_columns,
        fk.update_referential_action_desc AS update_rule,
        fk.delete_referential_action_desc AS delete_rule
      FROM sys.foreign_keys fk
      INNER JOIN sys.objects po ON po.object_id = fk.parent_object_id
      INNER JOIN sys.schemas ps ON ps.schema_id = po.schema_id
      INNER JOIN sys.objects rt ON rt.object_id = fk.referenced_object_id
      INNER JOIN sys.schemas rs ON rs.schema_id = rt.schema_id
      WHERE ps.name = '$schemaName'
        AND po.name = '$tableName'
      ORDER BY fk.name
    ''');

    return result.rows.map((row) {
      final m = _rowToMap(result.columnNames, row);
      final columnsStr = m['columns'] as String?;
      final refColumnsStr = m['ref_columns'] as String?;
      return ForeignKeyInfo(
        constraintName: m['constraint_name'] as String?,
        columns: columnsStr?.split(', '),
        referencedSchema: m['ref_schema'] as String?,
        referencedTable: m['ref_table'] as String?,
        referencedColumns: refColumnsStr?.split(', '),
        onUpdate: _formatReferentialAction(m['update_rule'] as String?),
        onDelete: _formatReferentialAction(m['delete_rule'] as String?),
      );
    }).toList();
  }

  @override
  Future<List<ForeignKeyInfo>> getIncomingReferences(
    String schemaName,
    String tableName,
  ) async {
    log.d(_tag, 'getIncomingReferences($schemaName.$tableName)');

    final result = await execute('''
      SELECT
        fk.name AS constraint_name,
        STUFF((
          SELECT ', ' + rc.name
          FROM sys.foreign_key_columns fkc2
          INNER JOIN sys.columns rc ON rc.object_id = fkc2.referenced_object_id AND rc.column_id = fkc2.referenced_column_id
          WHERE fkc2.constraint_object_id = fk.object_id
          ORDER BY fkc2.constraint_column_id
          FOR XML PATH(''), TYPE
        ).value('.', 'NVARCHAR(MAX)'), 1, 2, '') AS columns,
        ps.name AS src_schema,
        po.name AS src_table,
        STUFF((
          SELECT ', ' + pc.name
          FROM sys.foreign_key_columns fkc3
          INNER JOIN sys.columns pc ON pc.object_id = fkc3.parent_object_id AND pc.column_id = fkc3.parent_column_id
          WHERE fkc3.constraint_object_id = fk.object_id
          ORDER BY fkc3.constraint_column_id
          FOR XML PATH(''), TYPE
        ).value('.', 'NVARCHAR(MAX)'), 1, 2, '') AS src_columns,
        fk.update_referential_action_desc AS update_rule,
        fk.delete_referential_action_desc AS delete_rule
      FROM sys.foreign_keys fk
      INNER JOIN sys.objects po ON po.object_id = fk.parent_object_id
      INNER JOIN sys.schemas ps ON ps.schema_id = po.schema_id
      INNER JOIN sys.objects rt ON rt.object_id = fk.referenced_object_id
      INNER JOIN sys.schemas rs ON rs.schema_id = rt.schema_id
      WHERE rs.name = '$schemaName'
        AND rt.name = '$tableName'
      ORDER BY fk.name
    ''');

    return result.rows.map((row) {
      final m = _rowToMap(result.columnNames, row);
      final columnsStr = m['columns'] as String?;
      final srcColumnsStr = m['src_columns'] as String?;
      return ForeignKeyInfo(
        constraintName: m['constraint_name'] as String?,
        columns: columnsStr?.split(', '),
        referencedSchema: m['src_schema'] as String?,
        referencedTable: m['src_table'] as String?,
        referencedColumns: srcColumnsStr?.split(', '),
        onUpdate: _formatReferentialAction(m['update_rule'] as String?),
        onDelete: _formatReferentialAction(m['delete_rule'] as String?),
      );
    }).toList();
  }

  @override
  Future<List<IndexInfo>> getIndexes(
    String schemaName,
    String tableName,
  ) async {
    log.d(_tag, 'getIndexes($schemaName.$tableName)');

    final result = await execute('''
      SELECT
        i.name AS index_name,
        i.type_desc AS index_type,
        STUFF((
          SELECT ', ' + c.name
          FROM sys.index_columns ic
          INNER JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id
          WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.is_included_column = 0
          ORDER BY ic.key_ordinal
          FOR XML PATH(''), TYPE
        ).value('.', 'NVARCHAR(MAX)'), 1, 2, '') AS columns,
        i.is_unique,
        i.is_primary_key AS is_primary,
        i.filter_definition AS condition,
        ds.name AS tablespace,
        CASE WHEN i.is_disabled = 1 THEN 0 ELSE 1 END AS is_valid
      FROM sys.indexes i
      INNER JOIN sys.objects o ON o.object_id = i.object_id
      INNER JOIN sys.schemas s ON s.schema_id = o.schema_id
      LEFT JOIN sys.data_spaces ds ON ds.data_space_id = i.data_space_id
      WHERE s.name = '$schemaName'
        AND o.name = '$tableName'
        AND i.index_id > 0
      ORDER BY i.name
    ''');

    return result.rows.map((row) {
      final m = _rowToMap(result.columnNames, row);
      final columnsStr = m['columns'] as String?;
      return IndexInfo(
        indexName: m['index_name'] as String?,
        indexType: _mapIndexType(m['index_type'] as String?),
        columns: columnsStr?.split(', '),
        isUnique: _toBool(m['is_unique']),
        isPrimary: _toBool(m['is_primary']),
        indexSize: null,
        condition: m['condition'] as String?,
        tablespace: m['tablespace'] as String?,
        isValid: _toBool(m['is_valid']),
      );
    }).toList();
  }

  @override
  Future<List<SequenceInfo>> getSequences(String schemaName) async {
    log.d(_tag, 'getSequences($schemaName)');

    final result = await execute('''
      SELECT
        sq.name AS sequence_name,
        s.name AS schema_name,
        t.name AS data_type,
        CAST(sq.start_value AS BIGINT) AS start_value,
        CAST(sq.minimum_value AS BIGINT) AS min_value,
        CAST(sq.maximum_value AS BIGINT) AS max_value,
        CAST(sq.increment AS BIGINT) AS increment,
        CAST(sq.current_value AS BIGINT) AS current_value,
        sq.is_cycling AS is_cycled
      FROM sys.sequences sq
      INNER JOIN sys.schemas s ON s.schema_id = sq.schema_id
      INNER JOIN sys.types t ON t.user_type_id = sq.user_type_id
      WHERE s.name = '$schemaName'
      ORDER BY sq.name
    ''');

    return result.rows.map((row) {
      final m = _rowToMap(result.columnNames, row);
      return SequenceInfo(
        sequenceName: m['sequence_name'] as String?,
        schemaName: m['schema_name'] as String?,
        dataType: m['data_type'] as String?,
        startValue: _toInt(m['start_value']),
        minValue: _toInt(m['min_value']),
        maxValue: _toInt(m['max_value']),
        increment: _toInt(m['increment']),
        currentValue: _toInt(m['current_value']),
        isCycled: _toBool(m['is_cycled']),
        ownedByTable: null,
        ownedByColumn: null,
      );
    }).toList();
  }

  @override
  Future<TableStatistics> getTableStatistics(
    String schemaName,
    String tableName,
  ) async {
    log.d(_tag, 'getTableStatistics($schemaName.$tableName)');

    final result = await execute('''
      SELECT
        SUM(ps.row_count) AS live_rows,
        (SELECT SUM(ius.user_scans)
         FROM sys.dm_db_index_usage_stats ius
         INNER JOIN sys.objects o2 ON o2.object_id = ius.object_id
         INNER JOIN sys.schemas s2 ON s2.schema_id = o2.schema_id
         WHERE s2.name = '$schemaName' AND o2.name = '$tableName'
           AND ius.index_id IN (0, 1)) AS seq_scans,
        (SELECT SUM(ius.user_seeks + ius.user_lookups)
         FROM sys.dm_db_index_usage_stats ius
         INNER JOIN sys.objects o3 ON o3.object_id = ius.object_id
         INNER JOIN sys.schemas s3 ON s3.schema_id = o3.schema_id
         WHERE s3.name = '$schemaName' AND o3.name = '$tableName'
           AND ius.index_id > 1) AS idx_scans
      FROM sys.dm_db_partition_stats ps
      INNER JOIN sys.objects o ON o.object_id = ps.object_id
      INNER JOIN sys.schemas s ON s.schema_id = o.schema_id
      WHERE s.name = '$schemaName'
        AND o.name = '$tableName'
        AND ps.index_id IN (0, 1)
    ''');

    if (result.rows.isEmpty) return const TableStatistics();

    final m = _rowToMap(result.columnNames, result.rows.first);
    return TableStatistics(
      liveRowCount: _toInt(m['live_rows']),
      seqScans: _toInt(m['seq_scans']),
      idxScans: _toInt(m['idx_scans']),
    );
  }

  @override
  Future<String> getTableDdl(String schemaName, String tableName) async {
    log.d(_tag, 'getTableDdl($schemaName.$tableName)');

    final columns = await getColumns(schemaName, tableName);
    final constraints = await getConstraints(schemaName, tableName);
    final foreignKeys = await getForeignKeys(schemaName, tableName);
    final indexes = await getIndexes(schemaName, tableName);

    final buf = StringBuffer();
    buf.writeln(
      'CREATE TABLE [$schemaName].[$tableName] (',
    );

    final colDefs = <String>[];
    for (final col in columns) {
      final sb = StringBuffer(
        '  [${col.columnName}] ${col.dataType ?? col.udtName ?? 'nvarchar(max)'}',
      );
      if (col.isIdentity == true) {
        sb.write(' IDENTITY(1,1)');
      }
      if (col.columnDefault != null) {
        sb.write(' DEFAULT ${col.columnDefault}');
      }
      if (col.isNullable == false) {
        sb.write(' NOT NULL');
      } else {
        sb.write(' NULL');
      }
      colDefs.add(sb.toString());
    }

    for (final c in constraints) {
      final sb = StringBuffer('  CONSTRAINT [${c.constraintName}]');
      switch (c.constraintType) {
        case ConstraintType.primaryKey:
          sb.write(' PRIMARY KEY (${_bracketColumns(c.columns)})');
        case ConstraintType.unique:
          sb.write(' UNIQUE (${_bracketColumns(c.columns)})');
        case ConstraintType.check:
          sb.write(' CHECK ${c.checkExpression}');
        default:
          continue;
      }
      colDefs.add(sb.toString());
    }

    for (final fk in foreignKeys) {
      final sb = StringBuffer('  CONSTRAINT [${fk.constraintName}]');
      sb.write(' FOREIGN KEY (${_bracketColumns(fk.columns)})');
      sb.write(
        ' REFERENCES [${fk.referencedSchema}].[${fk.referencedTable}] '
        '(${_bracketColumns(fk.referencedColumns)})',
      );
      if (fk.onUpdate != null && fk.onUpdate != 'NO ACTION') {
        sb.write(' ON UPDATE ${fk.onUpdate}');
      }
      if (fk.onDelete != null && fk.onDelete != 'NO ACTION') {
        sb.write(' ON DELETE ${fk.onDelete}');
      }
      colDefs.add(sb.toString());
    }

    buf.writeln(colDefs.join(',\n'));
    buf.writeln(');');

    for (final idx in indexes) {
      if (idx.isPrimary == true) continue;
      buf.write('CREATE ');
      if (idx.isUnique == true) buf.write('UNIQUE ');
      final idxType = idx.indexType;
      if (idxType == IndexType.nonclustered) {
        buf.write('NONCLUSTERED ');
      } else if (idxType == IndexType.clustered) {
        buf.write('CLUSTERED ');
      }
      buf.write(
        'INDEX [${idx.indexName}] ON [$schemaName].[$tableName]',
      );
      buf.write(' (${_bracketColumns(idx.columns)})');
      if (idx.condition != null) {
        buf.write(' WHERE ${idx.condition}');
      }
      buf.writeln(';');
    }

    return buf.toString();
  }

  @override
  Future<int> getRowCountEstimate(
    String schemaName,
    String tableName,
  ) async {
    log.d(_tag, 'getRowCountEstimate($schemaName.$tableName)');

    final result = await execute('''
      SELECT SUM(ps.row_count) AS estimate
      FROM sys.dm_db_partition_stats ps
      INNER JOIN sys.objects o ON o.object_id = ps.object_id
      INNER JOIN sys.schemas s ON s.schema_id = o.schema_id
      WHERE s.name = '$schemaName'
        AND o.name = '$tableName'
        AND ps.index_id IN (0, 1)
    ''');

    if (result.rows.isEmpty) return 0;
    return _toInt(result.rows.first.first) ?? 0;
  }

  @override
  Future<String> getDatabaseSize() async {
    log.d(_tag, 'getDatabaseSize()');

    final result = await execute('''
      SELECT
        CAST(SUM(size * 8.0 / 1024) AS DECIMAL(18,2)) AS size_mb
      FROM sys.database_files
    ''');

    if (result.rows.isEmpty) return 'Unknown';
    final sizeMb = result.rows.first.first;
    return '$sizeMb MB';
  }

  @override
  Future<List<TableInfo>> searchObjects(String query) async {
    log.d(_tag, 'searchObjects("$query")');
    final pattern = '%${query.toLowerCase()}%';

    final result = await execute('''
      SELECT
        s.name AS schema_name,
        o.name AS table_name,
        ep.value AS comment,
        o.type AS obj_type,
        p.row_count AS row_estimate
      FROM sys.objects o
      INNER JOIN sys.schemas s ON s.schema_id = o.schema_id
      LEFT JOIN sys.extended_properties ep
        ON ep.major_id = o.object_id AND ep.minor_id = 0 AND ep.name = 'MS_Description'
      LEFT JOIN sys.dm_db_partition_stats p
        ON p.object_id = o.object_id AND p.index_id IN (0, 1)
      WHERE o.type IN ('U', 'V')
        AND s.name NOT IN ('guest', 'INFORMATION_SCHEMA', 'sys')
        AND LOWER(o.name) LIKE '$pattern'
      ORDER BY s.name, o.name
    ''');

    return result.rows.map((row) {
      final m = _rowToMap(result.columnNames, row);
      final objType = m['obj_type']?.toString().trim();
      return TableInfo(
        schemaName: m['schema_name'] as String?,
        tableName: m['table_name'] as String?,
        tableComment: m['comment'] as String?,
        objectType: _mapObjectType(objType),
        rowEstimate: _toInt(m['row_estimate']),
      );
    }).toList();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Engine-Specific Operations
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Future<bool> cancelQuery() async {
    log.i(_tag, 'cancelQuery()');
    try {
      // Attempt to kill the current session. This is a best-effort
      // operation since killing our own session will drop the connection.
      final spidResult = await execute('SELECT @@SPID AS spid');
      if (spidResult.rows.isEmpty) return false;
      final spid = _toInt(spidResult.rows.first.first);
      if (spid == null) return false;
      await execute('KILL $spid');
      return false;
    } on Exception catch (e) {
      log.e(_tag, 'Failed to cancel query', e);
      return false;
    }
  }

  @override
  Future<String> explainQuery(String sql, {bool analyze = false}) async {
    log.d(_tag, 'explainQuery(analyze=$analyze)');
    // SQL Server does not support a simple EXPLAIN command. SET SHOWPLAN_TEXT
    // requires a separate batch context and the mssql_connection package may
    // not support multi-statement batches reliably. Return an informational
    // message rather than attempting an unreliable workaround.
    return 'EXPLAIN is not supported for SQL Server connections. '
        'Use SQL Server Management Studio or Azure Data Studio to view '
        'execution plans via SET SHOWPLAN_TEXT ON or graphical plans.';
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Internal Helpers
  // ─────────────────────────────────────────────────────────────────────────

  /// Returns the active [MssqlConnection] or throws [StateError].
  MssqlConnection _requireConnection() {
    if (_connection == null || !_isOpen) {
      throw StateError('SQL Server driver is not connected');
    }
    return _connection!;
  }

  /// Parses the JSON string returned by [MssqlConnection.getData] into a
  /// [DriverQueryResult].
  ///
  /// The expected JSON format is:
  /// ```json
  /// {"columns": [...], "rows": [[...], ...], "affected": N}
  /// ```
  DriverQueryResult _parseJsonResult(String jsonStr) {
    if (jsonStr.isEmpty) {
      return const DriverQueryResult();
    }

    try {
      final decoded = jsonDecode(jsonStr);

      if (decoded is Map<String, dynamic>) {
        final columns = (decoded['columns'] as List<dynamic>?)
                ?.map((c) => c.toString())
                .toList() ??
            [];
        final rawRows = decoded['rows'] as List<dynamic>? ?? [];
        final affected = _toInt(decoded['affected']) ?? 0;

        final rows = rawRows.map<List<dynamic>>((row) {
          if (row is List) return row;
          return [row];
        }).toList();

        // Column types are not provided by mssql_connection; use empty names.
        final columnTypes = List.filled(columns.length, '');

        return DriverQueryResult(
          columnNames: columns,
          columnTypes: columnTypes,
          rows: rows,
          affectedRows: rows.isNotEmpty ? rows.length : affected,
        );
      }

      // If the result is a list, treat it as rows with unknown columns.
      if (decoded is List) {
        if (decoded.isEmpty) return const DriverQueryResult();

        if (decoded.first is Map) {
          final firstRow = decoded.first as Map<String, dynamic>;
          final columnNames = firstRow.keys.toList();
          final columnTypes = List.filled(columnNames.length, '');
          final rows = decoded.map<List<dynamic>>((item) {
            final map = item as Map<String, dynamic>;
            return columnNames.map((col) => map[col]).toList();
          }).toList();

          return DriverQueryResult(
            columnNames: columnNames,
            columnTypes: columnTypes,
            rows: rows,
            affectedRows: rows.length,
          );
        }
      }

      return const DriverQueryResult();
    } on FormatException catch (e) {
      log.e(_tag, 'Failed to parse JSON result', e);
      return const DriverQueryResult();
    }
  }

  /// Builds a column name-to-value map from parallel column name and row
  /// value lists.
  Map<String, dynamic> _rowToMap(List<String> columnNames, List<dynamic> row) {
    final map = <String, dynamic>{};
    for (var i = 0; i < columnNames.length && i < row.length; i++) {
      map[columnNames[i]] = row[i];
    }
    return map;
  }

  /// Converts an [ObjectType] from SQL Server `sys.objects.type` codes.
  ObjectType _mapObjectType(String? type) {
    return switch (type) {
      'U' => ObjectType.table,
      'V' => ObjectType.view,
      _ => ObjectType.table,
    };
  }

  /// Maps SQL Server constraint type descriptors to [ConstraintType].
  ConstraintType _mapConstraintType(String? type) {
    return switch (type) {
      'PRIMARY_KEY_CONSTRAINT' || 'PK' => ConstraintType.primaryKey,
      'FOREIGN_KEY_CONSTRAINT' || 'FK' || 'F' => ConstraintType.foreignKey,
      'UNIQUE_CONSTRAINT' || 'UQ' => ConstraintType.unique,
      'CHECK_CONSTRAINT' || 'C' => ConstraintType.check,
      _ => ConstraintType.check,
    };
  }

  /// Maps SQL Server index type descriptors to [IndexType].
  IndexType _mapIndexType(String? type) {
    return switch (type?.toUpperCase()) {
      'CLUSTERED' => IndexType.clustered,
      'NONCLUSTERED' => IndexType.nonclustered,
      'HEAP' => IndexType.other,
      'XML' => IndexType.other,
      'SPATIAL' => IndexType.other,
      _ => IndexType.nonclustered,
    };
  }

  /// Categorizes a column based on its position in PK/FK sets.
  ColumnCategory _categorizeColumn(
    int? columnId,
    String? columnDefault,
    bool isIdentity,
    Set<int> pkColumnIds,
    Set<int> fkColumnIds,
  ) {
    if (columnId != null && pkColumnIds.contains(columnId)) {
      return ColumnCategory.primaryKey;
    }
    if (columnId != null && fkColumnIds.contains(columnId)) {
      return ColumnCategory.foreignKey;
    }
    if (isIdentity) return ColumnCategory.serial;
    return ColumnCategory.regular;
  }

  /// Formats SQL Server referential action descriptors to standard SQL form.
  String? _formatReferentialAction(String? action) {
    return switch (action) {
      'NO_ACTION' => 'NO ACTION',
      'CASCADE' => 'CASCADE',
      'SET_NULL' => 'SET NULL',
      'SET_DEFAULT' => 'SET DEFAULT',
      _ => action,
    };
  }

  /// Returns `true` if the given SQL Server type name is a character type
  /// whose max_length is meaningful for display.
  bool _isCharType(String typeName) {
    final lower = typeName.toLowerCase();
    return lower == 'char' ||
        lower == 'varchar' ||
        lower == 'nchar' ||
        lower == 'nvarchar' ||
        lower == 'binary' ||
        lower == 'varbinary';
  }

  /// Wraps a list of column names in SQL Server bracket-quoted syntax.
  String _bracketColumns(List<String>? columns) {
    if (columns == null || columns.isEmpty) return '';
    return columns.map((c) => '[$c]').join(', ');
  }

  /// Safely converts a value to [int], returning `null` if conversion fails.
  int? _toInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  /// Safely converts a value to [bool].
  ///
  /// SQL Server returns bit columns as `0`/`1` integers or booleans.
  bool _toBool(Object? value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) {
      return value == '1' || value.toLowerCase() == 'true';
    }
    return false;
  }
}
