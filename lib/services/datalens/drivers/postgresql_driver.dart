/// PostgreSQL driver adapter for DataLens.
///
/// Implements [DatabaseDriverAdapter] using the `postgres` package for
/// native TCP connections. All schema introspection queries target
/// `pg_catalog`, `information_schema`, and `pg_stat_*` views.
library;

import 'package:postgres/postgres.dart' as pg;

import '../../../models/datalens_enums.dart';
import '../../../models/datalens_models.dart';
import '../../logging/log_service.dart';
import 'database_driver.dart';

/// PostgreSQL implementation of [DatabaseDriverAdapter].
class PostgresqlDriver implements DatabaseDriverAdapter {
  static const String _tag = 'PostgresqlDriver';

  /// The active PostgreSQL connection, or `null` if not connected.
  pg.Connection? _connection;

  @override
  DatabaseDriver get driverType => DatabaseDriver.postgresql;

  @override
  SqlDialect get dialect => SqlDialect.postgresql;

  @override
  bool get isOpen => _connection != null && _connection!.isOpen;

  /// Returns the underlying `pg.Connection` for legacy callers.
  ///
  /// Throws [StateError] if not connected.
  pg.Connection get rawConnection {
    if (_connection == null) {
      throw StateError('PostgreSQL driver is not connected');
    }
    return _connection!;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Connection Lifecycle
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Future<void> connect(DatabaseConnection config) async {
    log.d(_tag, 'connect(${config.host}:${config.port})');
    final endpoint = pg.Endpoint(
      host: config.host ?? 'localhost',
      port: config.port ?? 5432,
      database: config.database ?? '',
      username: config.username,
      password: config.password,
    );

    final settings = pg.ConnectionSettings(
      sslMode: _mapSslMode(config.sslMode),
      connectTimeout: Duration(seconds: config.connectionTimeout ?? 10),
      applicationName: 'CodeOps DataLens',
    );

    _connection = await pg.Connection.open(endpoint, settings: settings);
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
    final result = await conn.execute('SHOW server_version');
    return result.first.first.toString();
  }

  @override
  Future<String> getCurrentDatabase() async {
    final conn = _requireConnection();
    final result = await conn.execute('SELECT current_database()');
    return result.first.first.toString();
  }

  @override
  Future<String> getCurrentUser() async {
    final conn = _requireConnection();
    final result = await conn.execute('SELECT current_user');
    return result.first.first.toString();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Schema Introspection
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Future<List<SchemaInfo>> getSchemas() async {
    log.d(_tag, 'getSchemas()');
    final conn = _requireConnection();

    final result = await conn.execute(pg.Sql(r'''
      SELECT
        n.nspname AS schema_name,
        pg_get_userbyid(n.nspowner) AS schema_owner,
        (SELECT count(*) FROM pg_class c WHERE c.relnamespace = n.oid AND c.relkind = 'r')::int AS table_count,
        (SELECT count(*) FROM pg_class c WHERE c.relnamespace = n.oid AND c.relkind IN ('v', 'm'))::int AS view_count,
        (SELECT count(*) FROM pg_class c WHERE c.relnamespace = n.oid AND c.relkind = 'S')::int AS sequence_count
      FROM pg_namespace n
      WHERE n.nspname NOT IN ('pg_catalog', 'pg_toast', 'information_schema')
        AND n.nspname NOT LIKE 'pg_temp_%'
        AND n.nspname NOT LIKE 'pg_toast_temp_%'
      ORDER BY n.nspname
    '''));

    return result.map((row) {
      final m = row.toColumnMap();
      return SchemaInfo(
        name: _str(m['schema_name']),
        owner: _str(m['schema_owner']),
        tableCount: m['table_count'] as int?,
        viewCount: m['view_count'] as int?,
        sequenceCount: m['sequence_count'] as int?,
      );
    }).toList();
  }

  @override
  Future<List<TableInfo>> getTables(String schemaName) async {
    log.d(_tag, 'getTables($schemaName)');
    final conn = _requireConnection();

    final result = await conn.execute(
      pg.Sql(r'''
        SELECT
          c.relname AS table_name,
          obj_description(c.oid) AS comment,
          c.relkind AS rel_kind,
          c.reltuples::bigint AS row_estimate,
          pg_size_pretty(pg_relation_size(c.oid)) AS table_size,
          pg_size_pretty(pg_total_relation_size(c.oid)) AS total_size,
          pg_get_userbyid(c.relowner) AS owner,
          c.relrowsecurity AS has_rls,
          c.relispartition AS is_partitioned,
          pg_get_partkeydef(c.oid) AS partition_key,
          (SELECT spcname FROM pg_tablespace WHERE oid = c.reltablespace) AS tablespace
        FROM pg_class c
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE n.nspname = $1
          AND c.relkind IN ('r', 'v', 'm')
        ORDER BY c.relname
      ''', types: [pg.Type.text]),
      parameters: [schemaName],
    );

    return result.map((row) {
      final m = row.toColumnMap();
      return TableInfo(
        schemaName: schemaName,
        tableName: _str(m['table_name']),
        tableComment: _str(m['comment']),
        objectType: _mapRelKind(_str(m['rel_kind'])),
        rowEstimate: _toInt(m['row_estimate']),
        tableSize: _str(m['table_size']),
        totalSize: _str(m['total_size']),
        owner: _str(m['owner']),
        hasRls: m['has_rls'] as bool?,
        isPartitioned: m['is_partitioned'] as bool?,
        partitionKey: _str(m['partition_key']),
        tablespace: _str(m['tablespace']),
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

    // Primary key columns.
    final pkResult = await conn.execute(
      pg.Sql(r'''
        SELECT kcu.column_name
        FROM information_schema.table_constraints tc
        JOIN information_schema.key_column_usage kcu
          ON tc.constraint_name = kcu.constraint_name
          AND tc.table_schema = kcu.table_schema
        WHERE tc.constraint_type = 'PRIMARY KEY'
          AND tc.table_schema = $1
          AND tc.table_name = $2
      ''', types: [pg.Type.text, pg.Type.text]),
      parameters: [schemaName, tableName],
    );
    final pkColumns = pkResult.map((r) => r.first.toString()).toSet();

    // Foreign key columns.
    final fkResult = await conn.execute(
      pg.Sql(r'''
        SELECT kcu.column_name
        FROM information_schema.table_constraints tc
        JOIN information_schema.key_column_usage kcu
          ON tc.constraint_name = kcu.constraint_name
          AND tc.table_schema = kcu.table_schema
        WHERE tc.constraint_type = 'FOREIGN KEY'
          AND tc.table_schema = $1
          AND tc.table_name = $2
      ''', types: [pg.Type.text, pg.Type.text]),
      parameters: [schemaName, tableName],
    );
    final fkColumns = fkResult.map((r) => r.first.toString()).toSet();

    // Full column metadata.
    final result = await conn.execute(
      pg.Sql(r'''
        SELECT
          c.column_name,
          c.ordinal_position::int,
          c.data_type,
          c.udt_name,
          c.is_nullable,
          c.column_default,
          c.is_identity,
          c.identity_generation,
          c.character_maximum_length::int,
          c.numeric_precision::int,
          c.numeric_scale::int,
          c.collation_name,
          pgd.description AS comment
        FROM information_schema.columns c
        LEFT JOIN pg_catalog.pg_statio_all_tables st
          ON st.schemaname = c.table_schema AND st.relname = c.table_name
        LEFT JOIN pg_catalog.pg_description pgd
          ON pgd.objoid = st.relid AND pgd.objsubid = c.ordinal_position
        WHERE c.table_schema = $1 AND c.table_name = $2
        ORDER BY c.ordinal_position
      ''', types: [pg.Type.text, pg.Type.text]),
      parameters: [schemaName, tableName],
    );

    return result.map((row) {
      final m = row.toColumnMap();
      final colName = _str(m['column_name']);
      final colDefault = _str(m['column_default']);
      final isIdentity = (_str(m['is_identity'])) == 'YES';

      return ColumnInfo(
        columnName: colName,
        ordinalPosition: m['ordinal_position'] as int?,
        dataType: _str(m['data_type']),
        udtName: _str(m['udt_name']),
        isNullable: (_str(m['is_nullable'])) == 'YES',
        columnDefault: colDefault,
        isIdentity: isIdentity,
        identityGeneration: _str(m['identity_generation']),
        characterMaxLength: m['character_maximum_length'] as int?,
        numericPrecision: m['numeric_precision'] as int?,
        numericScale: m['numeric_scale'] as int?,
        collation: _str(m['collation_name']),
        comment: _str(m['comment']),
        category: _categorizeColumn(
          colName, colDefault, isIdentity, pkColumns, fkColumns,
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

    final result = await conn.execute(
      pg.Sql(r'''
        SELECT
          tc.constraint_name,
          tc.constraint_type,
          array_agg(kcu.column_name ORDER BY kcu.ordinal_position) AS columns,
          cc.check_clause,
          tc.is_deferrable,
          tc.initially_deferred
        FROM information_schema.table_constraints tc
        LEFT JOIN information_schema.key_column_usage kcu
          ON tc.constraint_name = kcu.constraint_name
          AND tc.table_schema = kcu.table_schema
        LEFT JOIN information_schema.check_constraints cc
          ON tc.constraint_name = cc.constraint_name
          AND tc.constraint_schema = cc.constraint_schema
        WHERE tc.table_schema = $1
          AND tc.table_name = $2
          AND tc.constraint_type != 'FOREIGN KEY'
        GROUP BY tc.constraint_name, tc.constraint_type, cc.check_clause,
                 tc.is_deferrable, tc.initially_deferred
        ORDER BY tc.constraint_name
      ''', types: [pg.Type.text, pg.Type.text]),
      parameters: [schemaName, tableName],
    );

    return result.map((row) {
      final m = row.toColumnMap();
      return ConstraintInfo(
        constraintName: _str(m['constraint_name']),
        constraintType: _mapConstraintType(_str(m['constraint_type'])),
        columns: _toStringList(m['columns']),
        checkExpression: _str(m['check_clause']),
        isDeferrable: (_str(m['is_deferrable'])) == 'YES',
        isDeferred: (_str(m['initially_deferred'])) == 'YES',
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

    final result = await conn.execute(
      pg.Sql(r'''
        SELECT
          tc.constraint_name,
          array_agg(DISTINCT kcu.column_name) AS columns,
          ccu.table_schema AS ref_schema,
          ccu.table_name AS ref_table,
          array_agg(DISTINCT ccu.column_name) AS ref_columns,
          rc.update_rule,
          rc.delete_rule
        FROM information_schema.table_constraints tc
        JOIN information_schema.key_column_usage kcu
          ON tc.constraint_name = kcu.constraint_name
          AND tc.table_schema = kcu.table_schema
        JOIN information_schema.constraint_column_usage ccu
          ON tc.constraint_name = ccu.constraint_name
          AND tc.constraint_schema = ccu.constraint_schema
        JOIN information_schema.referential_constraints rc
          ON tc.constraint_name = rc.constraint_name
          AND tc.constraint_schema = rc.constraint_schema
        WHERE tc.constraint_type = 'FOREIGN KEY'
          AND tc.table_schema = $1
          AND tc.table_name = $2
        GROUP BY tc.constraint_name, ccu.table_schema, ccu.table_name,
                 rc.update_rule, rc.delete_rule
        ORDER BY tc.constraint_name
      ''', types: [pg.Type.text, pg.Type.text]),
      parameters: [schemaName, tableName],
    );

    return result.map((row) {
      final m = row.toColumnMap();
      return ForeignKeyInfo(
        constraintName: _str(m['constraint_name']),
        columns: _toStringList(m['columns']),
        referencedSchema: _str(m['ref_schema']),
        referencedTable: _str(m['ref_table']),
        referencedColumns: _toStringList(m['ref_columns']),
        onUpdate: _str(m['update_rule']),
        onDelete: _str(m['delete_rule']),
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

    final result = await conn.execute(
      pg.Sql(r'''
        SELECT
          tc.constraint_name,
          array_agg(DISTINCT kcu.column_name) AS columns,
          kcu.table_schema AS src_schema,
          kcu.table_name AS src_table,
          array_agg(DISTINCT ccu.column_name) AS ref_columns,
          rc.update_rule,
          rc.delete_rule
        FROM information_schema.constraint_column_usage ccu
        JOIN information_schema.table_constraints tc
          ON ccu.constraint_name = tc.constraint_name
          AND ccu.constraint_schema = tc.constraint_schema
        JOIN information_schema.key_column_usage kcu
          ON tc.constraint_name = kcu.constraint_name
          AND tc.table_schema = kcu.table_schema
        JOIN information_schema.referential_constraints rc
          ON tc.constraint_name = rc.constraint_name
          AND tc.constraint_schema = rc.constraint_schema
        WHERE tc.constraint_type = 'FOREIGN KEY'
          AND ccu.table_schema = $1
          AND ccu.table_name = $2
        GROUP BY tc.constraint_name, kcu.table_schema, kcu.table_name,
                 rc.update_rule, rc.delete_rule
        ORDER BY tc.constraint_name
      ''', types: [pg.Type.text, pg.Type.text]),
      parameters: [schemaName, tableName],
    );

    return result.map((row) {
      final m = row.toColumnMap();
      return ForeignKeyInfo(
        constraintName: _str(m['constraint_name']),
        columns: _toStringList(m['columns']),
        referencedSchema: _str(m['src_schema']),
        referencedTable: _str(m['src_table']),
        referencedColumns: _toStringList(m['ref_columns']),
        onUpdate: _str(m['update_rule']),
        onDelete: _str(m['delete_rule']),
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

    final result = await conn.execute(
      pg.Sql(r'''
        SELECT
          i.relname AS index_name,
          am.amname AS index_type,
          array_agg(a.attname ORDER BY x.ord) AS columns,
          ix.indisunique AS is_unique,
          ix.indisprimary AS is_primary,
          pg_size_pretty(pg_relation_size(i.oid)) AS index_size,
          pg_get_expr(ix.indpred, ix.indrelid) AS condition,
          (SELECT spcname FROM pg_tablespace WHERE oid = i.reltablespace) AS tablespace,
          ix.indisvalid AS is_valid
        FROM pg_index ix
        JOIN pg_class t ON t.oid = ix.indrelid
        JOIN pg_class i ON i.oid = ix.indexrelid
        JOIN pg_namespace n ON n.oid = t.relnamespace
        JOIN pg_am am ON am.oid = i.relam
        CROSS JOIN LATERAL unnest(ix.indkey) WITH ORDINALITY AS x(attnum, ord)
        JOIN pg_attribute a ON a.attrelid = t.oid AND a.attnum = x.attnum
        WHERE n.nspname = $1
          AND t.relname = $2
        GROUP BY i.relname, am.amname, ix.indisunique, ix.indisprimary,
                 i.oid, ix.indpred, ix.indrelid, i.reltablespace, ix.indisvalid
        ORDER BY i.relname
      ''', types: [pg.Type.text, pg.Type.text]),
      parameters: [schemaName, tableName],
    );

    return result.map((row) {
      final m = row.toColumnMap();
      return IndexInfo(
        indexName: _str(m['index_name']),
        indexType: _mapIndexType(_str(m['index_type'])),
        columns: _toStringList(m['columns']),
        isUnique: m['is_unique'] as bool?,
        isPrimary: m['is_primary'] as bool?,
        indexSize: _str(m['index_size']),
        condition: _str(m['condition']),
        tablespace: _str(m['tablespace']),
        isValid: m['is_valid'] as bool?,
      );
    }).toList();
  }

  @override
  Future<List<SequenceInfo>> getSequences(String schemaName) async {
    log.d(_tag, 'getSequences($schemaName)');
    final conn = _requireConnection();

    final result = await conn.execute(
      pg.Sql(r'''
        SELECT
          s.sequence_name,
          s.sequence_schema,
          s.data_type,
          s.start_value::bigint,
          s.minimum_value::bigint,
          s.maximum_value::bigint,
          s.increment::bigint,
          (SELECT last_value FROM pg_sequences ps
           WHERE ps.schemaname = s.sequence_schema
             AND ps.sequencename = s.sequence_name) AS current_value,
          s.cycle_option,
          d.refobjid::regclass::text AS owned_by_table,
          a.attname AS owned_by_column
        FROM information_schema.sequences s
        LEFT JOIN pg_depend d
          ON d.objid = (quote_ident(s.sequence_schema) || '.' || quote_ident(s.sequence_name))::regclass
          AND d.deptype = 'a'
        LEFT JOIN pg_attribute a
          ON a.attrelid = d.refobjid AND a.attnum = d.refobjsubid
        WHERE s.sequence_schema = $1
        ORDER BY s.sequence_name
      ''', types: [pg.Type.text]),
      parameters: [schemaName],
    );

    return result.map((row) {
      final m = row.toColumnMap();
      return SequenceInfo(
        sequenceName: _str(m['sequence_name']),
        schemaName: _str(m['sequence_schema']),
        dataType: _str(m['data_type']),
        startValue: _toInt(m['start_value']),
        minValue: _toInt(m['minimum_value']),
        maxValue: _toInt(m['maximum_value']),
        increment: _toInt(m['increment']),
        currentValue: _toInt(m['current_value']),
        isCycled: (_str(m['cycle_option'])) == 'YES',
        ownedByTable: _str(m['owned_by_table']),
        ownedByColumn: _str(m['owned_by_column']),
      );
    }).toList();
  }

  @override
  Future<TableStatistics> getTableStatistics(
    String schemaName,
    String tableName,
  ) async {
    log.d(_tag, 'getTableStatistics($schemaName.$tableName)');
    final conn = _requireConnection();

    final result = await conn.execute(
      pg.Sql(r'''
        SELECT
          n_live_tup::bigint AS live_rows,
          n_dead_tup::bigint AS dead_rows,
          last_vacuum,
          last_autovacuum,
          last_analyze,
          last_autoanalyze,
          seq_scan::bigint AS seq_scans,
          idx_scan::bigint AS idx_scans,
          n_tup_ins::bigint AS inserts,
          n_tup_upd::bigint AS updates,
          n_tup_del::bigint AS deletes
        FROM pg_stat_user_tables
        WHERE schemaname = $1 AND relname = $2
      ''', types: [pg.Type.text, pg.Type.text]),
      parameters: [schemaName, tableName],
    );

    if (result.isEmpty) return const TableStatistics();

    final m = result.first.toColumnMap();
    return TableStatistics(
      liveRowCount: _toInt(m['live_rows']),
      deadRowCount: _toInt(m['dead_rows']),
      lastVacuum: m['last_vacuum'] as DateTime?,
      lastAutoVacuum: m['last_autovacuum'] as DateTime?,
      lastAnalyze: m['last_analyze'] as DateTime?,
      lastAutoAnalyze: m['last_autoanalyze'] as DateTime?,
      seqScans: _toInt(m['seq_scans']),
      idxScans: _toInt(m['idx_scans']),
      insertCount: _toInt(m['inserts']),
      updateCount: _toInt(m['updates']),
      deleteCount: _toInt(m['deletes']),
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
    buf.writeln('CREATE TABLE $schemaName.$tableName (');

    final colDefs = <String>[];
    for (final col in columns) {
      final sb = StringBuffer(
        '  ${col.columnName} ${col.dataType ?? col.udtName ?? 'text'}',
      );
      if (col.characterMaxLength != null) {
        sb.write('(${col.characterMaxLength})');
      }
      if (col.columnDefault != null) {
        sb.write(' DEFAULT ${col.columnDefault}');
      }
      if (col.isNullable == false) {
        sb.write(' NOT NULL');
      }
      colDefs.add(sb.toString());
    }

    for (final c in constraints) {
      final sb = StringBuffer('  CONSTRAINT ${c.constraintName}');
      switch (c.constraintType) {
        case ConstraintType.primaryKey:
          sb.write(' PRIMARY KEY (${c.columns?.join(', ')})');
        case ConstraintType.unique:
          sb.write(' UNIQUE (${c.columns?.join(', ')})');
        case ConstraintType.check:
          sb.write(' CHECK (${c.checkExpression})');
        case ConstraintType.exclusion:
          sb.write(' EXCLUSION');
        default:
          continue;
      }
      colDefs.add(sb.toString());
    }

    for (final fk in foreignKeys) {
      final sb = StringBuffer('  CONSTRAINT ${fk.constraintName}');
      sb.write(' FOREIGN KEY (${fk.columns?.join(', ')})');
      sb.write(
        ' REFERENCES ${fk.referencedTable} (${fk.referencedColumns?.join(', ')})',
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
      buf.write('INDEX ${idx.indexName} ON $schemaName.$tableName');
      if (idx.indexType != null) {
        buf.write(' USING ${idx.indexType!.displayName.toLowerCase()}');
      }
      buf.write(' (${idx.columns?.join(', ')})');
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
    final conn = _requireConnection();

    final result = await conn.execute(
      pg.Sql(r'''
        SELECT c.reltuples::bigint AS estimate
        FROM pg_class c
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE n.nspname = $1 AND c.relname = $2
      ''', types: [pg.Type.text, pg.Type.text]),
      parameters: [schemaName, tableName],
    );

    if (result.isEmpty) return 0;
    return _toInt(result.first.first) ?? 0;
  }

  @override
  Future<String> getDatabaseSize() async {
    log.d(_tag, 'getDatabaseSize()');
    final conn = _requireConnection();
    final result = await conn.execute(
      'SELECT pg_size_pretty(pg_database_size(current_database()))',
    );
    return result.first.first.toString();
  }

  @override
  Future<List<TableInfo>> searchObjects(String query) async {
    log.d(_tag, 'searchObjects("$query")');
    final conn = _requireConnection();
    final pattern = '%${query.toLowerCase()}%';

    final result = await conn.execute(
      pg.Sql(r'''
        SELECT
          n.nspname AS schema_name,
          c.relname AS table_name,
          obj_description(c.oid) AS comment,
          c.relkind AS rel_kind,
          c.reltuples::bigint AS row_estimate,
          pg_size_pretty(pg_relation_size(c.oid)) AS table_size,
          pg_size_pretty(pg_total_relation_size(c.oid)) AS total_size,
          pg_get_userbyid(c.relowner) AS owner
        FROM pg_class c
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE n.nspname NOT IN ('pg_catalog', 'pg_toast', 'information_schema')
          AND c.relkind IN ('r', 'v', 'm')
          AND lower(c.relname) LIKE $1
        ORDER BY n.nspname, c.relname
      ''', types: [pg.Type.text]),
      parameters: [pattern],
    );

    return result.map((row) {
      final m = row.toColumnMap();
      return TableInfo(
        schemaName: _str(m['schema_name']),
        tableName: _str(m['table_name']),
        tableComment: _str(m['comment']),
        objectType: _mapRelKind(_str(m['rel_kind'])),
        rowEstimate: _toInt(m['row_estimate']),
        tableSize: _str(m['table_size']),
        totalSize: _str(m['total_size']),
        owner: _str(m['owner']),
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
      final pidResult = await conn.execute('SELECT pg_backend_pid()');
      final pid = pidResult.first.first as int;
      final cancelResult = await conn.execute(
        'SELECT pg_cancel_backend($pid)',
      );
      return cancelResult.first.first as bool;
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
    return result.map((row) => row.first.toString()).join('\n');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Internal Helpers
  // ─────────────────────────────────────────────────────────────────────────

  pg.Connection _requireConnection() {
    if (_connection == null) {
      throw StateError('PostgreSQL driver is not connected');
    }
    return _connection!;
  }

  pg.SslMode _mapSslMode(String? sslMode) {
    return switch (sslMode) {
      'require' => pg.SslMode.require,
      'verify-full' || 'verify-ca' => pg.SslMode.verifyFull,
      _ => pg.SslMode.disable,
    };
  }

  ObjectType _mapRelKind(String? relKind) {
    return switch (relKind) {
      'r' => ObjectType.table,
      'v' => ObjectType.view,
      'm' => ObjectType.materializedView,
      'S' => ObjectType.sequence,
      _ => ObjectType.table,
    };
  }

  ConstraintType _mapConstraintType(String? type) {
    return switch (type) {
      'PRIMARY KEY' => ConstraintType.primaryKey,
      'FOREIGN KEY' => ConstraintType.foreignKey,
      'UNIQUE' => ConstraintType.unique,
      'CHECK' => ConstraintType.check,
      'EXCLUDE' => ConstraintType.exclusion,
      _ => ConstraintType.check,
    };
  }

  IndexType _mapIndexType(String? amName) {
    return switch (amName) {
      'btree' => IndexType.btree,
      'hash' => IndexType.hash,
      'gin' => IndexType.gin,
      'gist' => IndexType.gist,
      'spgist' => IndexType.spgist,
      'brin' => IndexType.brin,
      _ => IndexType.btree,
    };
  }

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
    if (isIdentity) return ColumnCategory.generated;
    if (columnDefault != null && columnDefault.startsWith('nextval(')) {
      return ColumnCategory.serial;
    }
    return ColumnCategory.regular;
  }

  DriverQueryResult _toDriverResult(pg.Result result, String sql) {
    final isSelect = _isSelectQuery(sql);

    if (isSelect) {
      final columnNames =
          result.schema.columns.map((c) => c.columnName ?? '').toList();
      final columnTypes =
          result.schema.columns.map((c) => c.type.toString()).toList();
      final rows = result.map((row) => row.toList()).toList();

      return DriverQueryResult(
        columnNames: columnNames,
        columnTypes: columnTypes,
        rows: rows,
        affectedRows: rows.length,
      );
    }

    return DriverQueryResult(affectedRows: result.affectedRows);
  }

  bool _isSelectQuery(String sql) {
    final trimmed = sql.trimLeft().toUpperCase();
    return trimmed.startsWith('SELECT') ||
        trimmed.startsWith('WITH') ||
        trimmed.startsWith('TABLE') ||
        trimmed.startsWith('VALUES');
  }

  /// Safely converts a column value to [String], handling `UndecodedBytes`
  /// from the `postgres` package which cannot be cast directly to [String].
  String? _str(Object? value) {
    if (value == null) return null;
    if (value is String) return value;
    return value.toString();
  }

  int? _toInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is BigInt) return value.toInt();
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  List<String>? _toStringList(Object? value) {
    if (value == null) return null;
    if (value is List) return value.map((e) => e.toString()).toList();
    return null;
  }
}
