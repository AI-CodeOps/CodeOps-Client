/// Service for querying PostgreSQL system catalogs in DataLens.
///
/// Discovers database structure by introspecting `information_schema`,
/// `pg_catalog`, and `pg_stat_*` views. Every method takes a [connectionId]
/// and obtains the active [pg.Connection] from [DatabaseConnectionService].
///
/// This powers the DBeaver-style navigator tree and table properties panels.
library;

import 'package:postgres/postgres.dart' as pg;

import '../../models/datalens_enums.dart';
import '../../models/datalens_models.dart';
import '../logging/log_service.dart';
import 'database_connection_service.dart';

/// Queries PostgreSQL system catalogs to discover database structure.
///
/// Provides schema, table, column, constraint, index, sequence, and
/// dependency introspection. All queries use parameterized SQL to prevent
/// injection.
class SchemaIntrospectionService {
  static const String _tag = 'SchemaIntrospectionService';

  /// The connection service used to obtain active [pg.Connection] instances.
  final DatabaseConnectionService _connectionService;

  /// Creates a [SchemaIntrospectionService] with the given [connectionService].
  SchemaIntrospectionService(DatabaseConnectionService connectionService)
      : _connectionService = connectionService;

  // ---------------------------------------------------------------------------
  // Schema Discovery
  // ---------------------------------------------------------------------------

  /// Returns all non-system schemas in the database.
  ///
  /// Excludes `pg_catalog`, `pg_toast`, and `information_schema`. Each
  /// [SchemaInfo] includes table, view, and sequence counts.
  Future<List<SchemaInfo>> getSchemas(String connectionId) async {
    log.d(_tag, 'getSchemas($connectionId)');
    final conn = _requireConnection(connectionId);

    final result = await conn.execute(
      pg.Sql(r'''
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
      '''),
    );

    return result.map((row) {
      final m = row.toColumnMap();
      return SchemaInfo(
        name: m['schema_name'] as String?,
        owner: m['schema_owner'] as String?,
        tableCount: m['table_count'] as int?,
        viewCount: m['view_count'] as int?,
        sequenceCount: m['sequence_count'] as int?,
      );
    }).toList();
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
    final conn = _requireConnection(connectionId);

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
        tableName: m['table_name'] as String?,
        tableComment: m['comment'] as String?,
        objectType: _mapRelKind(m['rel_kind'] as String?),
        rowEstimate: _toInt(m['row_estimate']),
        tableSize: m['table_size'] as String?,
        totalSize: m['total_size'] as String?,
        owner: m['owner'] as String?,
        hasRls: m['has_rls'] as bool?,
        isPartitioned: m['is_partitioned'] as bool?,
        partitionKey: m['partition_key'] as String?,
        tablespace: m['tablespace'] as String?,
      );
    }).toList();
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
    final conn = _requireConnection(connectionId);

    // Fetch primary key columns for category assignment.
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
    final pkColumns = pkResult.map((r) => r.first as String).toSet();

    // Fetch foreign key columns for category assignment.
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
    final fkColumns = fkResult.map((r) => r.first as String).toSet();

    // Fetch full column metadata.
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
      final colName = m['column_name'] as String?;
      final colDefault = m['column_default'] as String?;
      final isIdentity = (m['is_identity'] as String?) == 'YES';

      return ColumnInfo(
        columnName: colName,
        ordinalPosition: m['ordinal_position'] as int?,
        dataType: m['data_type'] as String?,
        udtName: m['udt_name'] as String?,
        isNullable: (m['is_nullable'] as String?) == 'YES',
        columnDefault: colDefault,
        isIdentity: isIdentity,
        identityGeneration: m['identity_generation'] as String?,
        characterMaxLength: m['character_maximum_length'] as int?,
        numericPrecision: m['numeric_precision'] as int?,
        numericScale: m['numeric_scale'] as int?,
        collation: m['collation_name'] as String?,
        comment: m['comment'] as String?,
        category: _categorizeColumn(
          colName,
          colDefault,
          isIdentity,
          pkColumns,
          fkColumns,
        ),
      );
    }).toList();
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
    final conn = _requireConnection(connectionId);

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
        constraintName: m['constraint_name'] as String?,
        constraintType: _mapConstraintType(m['constraint_type'] as String?),
        columns: _toStringList(m['columns']),
        checkExpression: m['check_clause'] as String?,
        isDeferrable: (m['is_deferrable'] as String?) == 'YES',
        isDeferred: (m['initially_deferred'] as String?) == 'YES',
      );
    }).toList();
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
    final conn = _requireConnection(connectionId);

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
        constraintName: m['constraint_name'] as String?,
        columns: _toStringList(m['columns']),
        referencedSchema: m['ref_schema'] as String?,
        referencedTable: m['ref_table'] as String?,
        referencedColumns: _toStringList(m['ref_columns']),
        onUpdate: m['update_rule'] as String?,
        onDelete: m['delete_rule'] as String?,
      );
    }).toList();
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
    final conn = _requireConnection(connectionId);

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
        constraintName: m['constraint_name'] as String?,
        columns: _toStringList(m['columns']),
        referencedSchema: m['src_schema'] as String?,
        referencedTable: m['src_table'] as String?,
        referencedColumns: _toStringList(m['ref_columns']),
        onUpdate: m['update_rule'] as String?,
        onDelete: m['delete_rule'] as String?,
      );
    }).toList();
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
    final conn = _requireConnection(connectionId);

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
        indexName: m['index_name'] as String?,
        indexType: _mapIndexType(m['index_type'] as String?),
        columns: _toStringList(m['columns']),
        isUnique: m['is_unique'] as bool?,
        isPrimary: m['is_primary'] as bool?,
        indexSize: m['index_size'] as String?,
        condition: m['condition'] as String?,
        tablespace: m['tablespace'] as String?,
        isValid: m['is_valid'] as bool?,
      );
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // Sequences
  // ---------------------------------------------------------------------------

  /// Returns sequence metadata for a schema.
  Future<List<SequenceInfo>> getSequences(
    String connectionId,
    String schemaName,
  ) async {
    log.d(_tag, 'getSequences($connectionId, $schemaName)');
    final conn = _requireConnection(connectionId);

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
        sequenceName: m['sequence_name'] as String?,
        schemaName: m['sequence_schema'] as String?,
        dataType: m['data_type'] as String?,
        startValue: _toInt(m['start_value']),
        minValue: _toInt(m['minimum_value']),
        maxValue: _toInt(m['maximum_value']),
        increment: _toInt(m['increment']),
        currentValue: _toInt(m['current_value']),
        isCycled: (m['cycle_option'] as String?) == 'YES',
        ownedByTable: m['owned_by_table'] as String?,
        ownedByColumn: m['owned_by_column'] as String?,
      );
    }).toList();
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

  /// Returns table statistics from `pg_stat_user_tables`.
  Future<TableStatistics> getTableStatistics(
    String connectionId,
    String schemaName,
    String tableName,
  ) async {
    log.d(_tag, 'getTableStatistics($connectionId, $schemaName.$tableName)');
    final conn = _requireConnection(connectionId);

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

    if (result.isEmpty) {
      return const TableStatistics();
    }

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

    final columns = await getColumns(connectionId, schemaName, tableName);
    final constraints =
        await getConstraints(connectionId, schemaName, tableName);
    final foreignKeys =
        await getForeignKeys(connectionId, schemaName, tableName);
    final indexes = await getIndexes(connectionId, schemaName, tableName);

    final buf = StringBuffer();
    buf.writeln('CREATE TABLE $schemaName.$tableName (');

    // Columns.
    final colDefs = <String>[];
    for (final col in columns) {
      final sb = StringBuffer('  ${col.columnName} ${col.dataType ?? col.udtName ?? 'text'}');
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

    // Inline constraints.
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

    // Foreign key constraints.
    for (final fk in foreignKeys) {
      final sb = StringBuffer('  CONSTRAINT ${fk.constraintName}');
      sb.write(' FOREIGN KEY (${fk.columns?.join(', ')})');
      sb.write(' REFERENCES ${fk.referencedTable} (${fk.referencedColumns?.join(', ')})');
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

    // Indexes (not part of CREATE TABLE, but appended for completeness).
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

  // ---------------------------------------------------------------------------
  // Row Count & Database Size
  // ---------------------------------------------------------------------------

  /// Returns the estimated row count for a table (fast — uses pg_class.reltuples).
  Future<int> getRowCountEstimate(
    String connectionId,
    String schemaName,
    String tableName,
  ) async {
    log.d(_tag, 'getRowCountEstimate($connectionId, $schemaName.$tableName)');
    final conn = _requireConnection(connectionId);

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

  /// Returns the total database size as a human-readable string.
  Future<String> getDatabaseSize(String connectionId) async {
    log.d(_tag, 'getDatabaseSize($connectionId)');
    final conn = _requireConnection(connectionId);

    final result = await conn.execute(
      'SELECT pg_size_pretty(pg_database_size(current_database()))',
    );
    return result.first.first as String;
  }

  // ---------------------------------------------------------------------------
  // Search
  // ---------------------------------------------------------------------------

  /// Searches for tables and views whose name matches [query].
  ///
  /// Uses case-insensitive LIKE matching across all non-system schemas.
  Future<List<TableInfo>> searchObjects(
    String connectionId,
    String query,
  ) async {
    log.d(_tag, 'searchObjects($connectionId, "$query")');
    final conn = _requireConnection(connectionId);
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
        schemaName: m['schema_name'] as String?,
        tableName: m['table_name'] as String?,
        tableComment: m['comment'] as String?,
        objectType: _mapRelKind(m['rel_kind'] as String?),
        rowEstimate: _toInt(m['row_estimate']),
        tableSize: m['table_size'] as String?,
        totalSize: m['total_size'] as String?,
        owner: m['owner'] as String?,
      );
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // Internal Helpers
  // ---------------------------------------------------------------------------

  /// Returns the active connection or throws [StateError].
  pg.Connection _requireConnection(String connectionId) {
    final conn = _connectionService.getConnection(connectionId);
    if (conn == null) {
      throw StateError('No active connection for $connectionId');
    }
    return conn;
  }

  /// Maps PostgreSQL `relkind` char to [ObjectType].
  ObjectType _mapRelKind(String? relKind) {
    return switch (relKind) {
      'r' => ObjectType.table,
      'v' => ObjectType.view,
      'm' => ObjectType.materializedView,
      'S' => ObjectType.sequence,
      _ => ObjectType.table,
    };
  }

  /// Maps a constraint type string to [ConstraintType].
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

  /// Maps a PostgreSQL access method name to [IndexType].
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

  /// Determines the [ColumnCategory] for a column.
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
    if (isIdentity) {
      return ColumnCategory.generated;
    }
    if (columnDefault != null && columnDefault.startsWith('nextval(')) {
      return ColumnCategory.serial;
    }
    return ColumnCategory.regular;
  }

  /// Safely converts a value to [int], handling `BigInt` and `num`.
  int? _toInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is BigInt) return value.toInt();
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  /// Converts a PostgreSQL array result to a [List<String>].
  List<String>? _toStringList(Object? value) {
    if (value == null) return null;
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return null;
  }
}
