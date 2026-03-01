// Tests for SchemaIntrospectionService.
//
// Mocks DatabaseConnectionService and pg.Connection to verify SQL result
// mapping, category assignment, DDL reconstruction, and error handling
// without requiring a real PostgreSQL server.
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:postgres/postgres.dart' as pg;

import 'package:codeops/models/datalens_enums.dart';
import 'package:codeops/services/datalens/database_connection_service.dart';
import 'package:codeops/services/datalens/schema_introspection_service.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockDatabaseConnectionService extends Mock
    implements DatabaseConnectionService {}

class MockPgConnection extends Mock implements pg.Connection {}

// ---------------------------------------------------------------------------
// Fakes for registerFallbackValue
// ---------------------------------------------------------------------------

class FakeSql extends Fake implements pg.Sql {}

// ---------------------------------------------------------------------------
// Test helpers — construct postgres Result objects
// ---------------------------------------------------------------------------

pg.ResultSchema _schema(List<String> columnNames) {
  return pg.ResultSchema(
    columnNames
        .map((name) => pg.ResultSchemaColumn(
              typeOid: 25, // text
              type: pg.Type.text,
              columnName: name,
            ))
        .toList(),
  );
}

pg.ResultRow _row(pg.ResultSchema schema, List<Object?> values) {
  return pg.ResultRow(values: values, schema: schema);
}

pg.Result _result(List<String> columns, List<List<Object?>> rows) {
  final schema = _schema(columns);
  return pg.Result(
    rows: rows.map((vals) => _row(schema, vals)).toList(),
    affectedRows: rows.length,
    schema: schema,
  );
}

pg.Result _emptyResult(List<String> columns) {
  return _result(columns, []);
}

void main() {
  late MockDatabaseConnectionService mockConnService;
  late MockPgConnection mockConn;
  late SchemaIntrospectionService service;

  setUpAll(() {
    registerFallbackValue(FakeSql());
  });

  setUp(() {
    mockConnService = MockDatabaseConnectionService();
    mockConn = MockPgConnection();
    service = SchemaIntrospectionService(mockConnService);
    when(() => mockConnService.getConnection('conn-1')).thenReturn(mockConn);
  });

  /// Stub for conn.execute — matches any SQL and optional parameters.
  void stubExecute(pg.Result result) {
    when(() => mockConn.execute(
          any(),
          parameters: any(named: 'parameters'),
          ignoreRows: any(named: 'ignoreRows'),
          queryMode: any(named: 'queryMode'),
          timeout: any(named: 'timeout'),
        )).thenAnswer((_) async => result);
  }

  /// Stubs multiple sequential calls to execute.
  void stubExecuteSequence(List<pg.Result> results) {
    var index = 0;
    when(() => mockConn.execute(
          any(),
          parameters: any(named: 'parameters'),
          ignoreRows: any(named: 'ignoreRows'),
          queryMode: any(named: 'queryMode'),
          timeout: any(named: 'timeout'),
        )).thenAnswer((_) async {
      final r = results[index];
      if (index < results.length - 1) index++;
      return r;
    });
  }

  // ---------------------------------------------------------------------------
  // getSchemas
  // ---------------------------------------------------------------------------
  group('getSchemas', () {
    test('excludes system schemas and returns table counts', () async {
      stubExecute(_result(
        ['schema_name', 'schema_owner', 'table_count', 'view_count', 'sequence_count'],
        [
          ['public', 'postgres', 12, 3, 5],
          ['app', 'codeops', 8, 1, 2],
        ],
      ));

      final schemas = await service.getSchemas('conn-1');

      expect(schemas.length, 2);
      expect(schemas[0].name, 'public');
      expect(schemas[0].owner, 'postgres');
      expect(schemas[0].tableCount, 12);
      expect(schemas[0].viewCount, 3);
      expect(schemas[0].sequenceCount, 5);
      expect(schemas[1].name, 'app');
    });

    test('returns empty list when no schemas found', () async {
      stubExecute(_emptyResult(
        ['schema_name', 'schema_owner', 'table_count', 'view_count', 'sequence_count'],
      ));

      final schemas = await service.getSchemas('conn-1');
      expect(schemas, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // getTables
  // ---------------------------------------------------------------------------
  group('getTables', () {
    test('returns all object types and maps relkind', () async {
      stubExecute(_result(
        ['table_name', 'comment', 'rel_kind', 'row_estimate', 'table_size',
         'total_size', 'owner', 'has_rls', 'is_partitioned', 'partition_key', 'tablespace'],
        [
          ['users', 'User accounts', 'r', 1500, '128 kB', '256 kB', 'codeops', false, false, null, null],
          ['active_users_view', null, 'v', 0, '0 bytes', '0 bytes', 'codeops', false, false, null, null],
          ['user_summary', 'Materialized', 'm', 100, '32 kB', '48 kB', 'codeops', false, false, null, null],
        ],
      ));

      final tables = await service.getTables('conn-1', 'public');

      expect(tables.length, 3);
      expect(tables[0].tableName, 'users');
      expect(tables[0].objectType, ObjectType.table);
      expect(tables[0].tableComment, 'User accounts');
      expect(tables[0].rowEstimate, 1500);
      expect(tables[0].tableSize, '128 kB');
      expect(tables[0].totalSize, '256 kB');
      expect(tables[0].schemaName, 'public');
      expect(tables[1].objectType, ObjectType.view);
      expect(tables[2].objectType, ObjectType.materializedView);
    });

    test('includes size strings', () async {
      stubExecute(_result(
        ['table_name', 'comment', 'rel_kind', 'row_estimate', 'table_size',
         'total_size', 'owner', 'has_rls', 'is_partitioned', 'partition_key', 'tablespace'],
        [
          ['big_table', null, 'r', 5000000, '1024 MB', '1536 MB', 'admin', true, false, null, null],
        ],
      ));

      final tables = await service.getTables('conn-1', 'public');
      expect(tables.first.tableSize, '1024 MB');
      expect(tables.first.totalSize, '1536 MB');
      expect(tables.first.hasRls, true);
    });
  });

  // ---------------------------------------------------------------------------
  // getColumns
  // ---------------------------------------------------------------------------
  group('getColumns', () {
    test('maps all fields and assigns categories', () async {
      // Sequence: PK query → FK query → columns query.
      stubExecuteSequence([
        // PK columns.
        _result(['column_name'], [['id']]),
        // FK columns.
        _result(['column_name'], [['team_id']]),
        // Full column metadata.
        _result(
          ['column_name', 'ordinal_position', 'data_type', 'udt_name',
           'is_nullable', 'column_default', 'is_identity', 'identity_generation',
           'character_maximum_length', 'numeric_precision', 'numeric_scale',
           'collation_name', 'comment'],
          [
            ['id', 1, 'uuid', 'uuid', 'NO', null, 'NO', null, null, null, null, null, 'Primary key'],
            ['name', 2, 'character varying', 'varchar', 'NO', null, 'NO', null, 255, null, null, 'en_US', null],
            ['team_id', 3, 'uuid', 'uuid', 'YES', null, 'NO', null, null, null, null, null, null],
            ['counter', 4, 'integer', 'int4', 'NO', "nextval('users_counter_seq'::regclass)", 'NO', null, null, null, null, null, null],
          ],
        ),
      ]);

      final columns = await service.getColumns('conn-1', 'public', 'users');

      expect(columns.length, 4);

      // id → primary key
      expect(columns[0].columnName, 'id');
      expect(columns[0].category, ColumnCategory.primaryKey);
      expect(columns[0].comment, 'Primary key');
      expect(columns[0].isNullable, false);

      // name → regular
      expect(columns[1].columnName, 'name');
      expect(columns[1].category, ColumnCategory.regular);
      expect(columns[1].characterMaxLength, 255);
      expect(columns[1].collation, 'en_US');

      // team_id → foreign key
      expect(columns[2].columnName, 'team_id');
      expect(columns[2].category, ColumnCategory.foreignKey);
      expect(columns[2].isNullable, true);

      // counter → serial
      expect(columns[3].columnName, 'counter');
      expect(columns[3].category, ColumnCategory.serial);
    });

    test('columns ordered by position', () async {
      stubExecuteSequence([
        _emptyResult(['column_name']),
        _emptyResult(['column_name']),
        _result(
          ['column_name', 'ordinal_position', 'data_type', 'udt_name',
           'is_nullable', 'column_default', 'is_identity', 'identity_generation',
           'character_maximum_length', 'numeric_precision', 'numeric_scale',
           'collation_name', 'comment'],
          [
            ['a', 1, 'text', 'text', 'YES', null, 'NO', null, null, null, null, null, null],
            ['b', 2, 'text', 'text', 'YES', null, 'NO', null, null, null, null, null, null],
            ['c', 3, 'text', 'text', 'YES', null, 'NO', null, null, null, null, null, null],
          ],
        ),
      ]);

      final columns = await service.getColumns('conn-1', 'public', 'test');
      expect(columns.map((c) => c.columnName).toList(), ['a', 'b', 'c']);
      expect(columns.map((c) => c.ordinalPosition).toList(), [1, 2, 3]);
    });
  });

  // ---------------------------------------------------------------------------
  // getConstraints
  // ---------------------------------------------------------------------------
  group('getConstraints', () {
    test('maps primary key constraint', () async {
      stubExecute(_result(
        ['constraint_name', 'constraint_type', 'columns', 'check_clause',
         'is_deferrable', 'initially_deferred'],
        [
          ['users_pkey', 'PRIMARY KEY', ['id'], null, 'NO', 'NO'],
        ],
      ));

      final constraints = await service.getConstraints('conn-1', 'public', 'users');
      expect(constraints.length, 1);
      expect(constraints.first.constraintName, 'users_pkey');
      expect(constraints.first.constraintType, ConstraintType.primaryKey);
      expect(constraints.first.columns, ['id']);
      expect(constraints.first.isDeferrable, false);
    });

    test('maps check constraint with expression', () async {
      stubExecute(_result(
        ['constraint_name', 'constraint_type', 'columns', 'check_clause',
         'is_deferrable', 'initially_deferred'],
        [
          ['positive_amount', 'CHECK', ['amount'], '(amount > 0)', 'NO', 'NO'],
        ],
      ));

      final constraints = await service.getConstraints('conn-1', 'public', 'orders');
      expect(constraints.first.constraintType, ConstraintType.check);
      expect(constraints.first.checkExpression, '(amount > 0)');
    });
  });

  // ---------------------------------------------------------------------------
  // getForeignKeys
  // ---------------------------------------------------------------------------
  group('getForeignKeys', () {
    test('maps full foreign key references', () async {
      stubExecute(_result(
        ['constraint_name', 'columns', 'ref_schema', 'ref_table', 'ref_columns',
         'update_rule', 'delete_rule'],
        [
          ['fk_team', ['team_id'], 'public', 'teams', ['id'], 'NO ACTION', 'CASCADE'],
        ],
      ));

      final fks = await service.getForeignKeys('conn-1', 'public', 'users');
      expect(fks.length, 1);
      expect(fks.first.constraintName, 'fk_team');
      expect(fks.first.columns, ['team_id']);
      expect(fks.first.referencedSchema, 'public');
      expect(fks.first.referencedTable, 'teams');
      expect(fks.first.referencedColumns, ['id']);
      expect(fks.first.onUpdate, 'NO ACTION');
      expect(fks.first.onDelete, 'CASCADE');
    });
  });

  // ---------------------------------------------------------------------------
  // getIncomingReferences
  // ---------------------------------------------------------------------------
  group('getIncomingReferences', () {
    test('finds referencing tables', () async {
      stubExecute(_result(
        ['constraint_name', 'columns', 'src_schema', 'src_table', 'ref_columns',
         'update_rule', 'delete_rule'],
        [
          ['fk_project_team', ['team_id'], 'public', 'projects', ['id'], 'NO ACTION', 'SET NULL'],
        ],
      ));

      final refs = await service.getIncomingReferences('conn-1', 'public', 'teams');
      expect(refs.length, 1);
      expect(refs.first.referencedTable, 'projects');
      expect(refs.first.onDelete, 'SET NULL');
    });
  });

  // ---------------------------------------------------------------------------
  // getIndexes
  // ---------------------------------------------------------------------------
  group('getIndexes', () {
    test('maps all index fields', () async {
      stubExecute(_result(
        ['index_name', 'index_type', 'columns', 'is_unique', 'is_primary',
         'index_size', 'condition', 'tablespace', 'is_valid'],
        [
          ['users_pkey', 'btree', ['id'], true, true, '16 kB', null, null, true],
          ['idx_users_email', 'btree', ['email'], true, false, '32 kB', null, null, true],
        ],
      ));

      final indexes = await service.getIndexes('conn-1', 'public', 'users');
      expect(indexes.length, 2);
      expect(indexes[0].indexName, 'users_pkey');
      expect(indexes[0].indexType, IndexType.btree);
      expect(indexes[0].isPrimary, true);
      expect(indexes[0].isUnique, true);
      expect(indexes[1].indexName, 'idx_users_email');
      expect(indexes[1].isPrimary, false);
      expect(indexes[1].indexSize, '32 kB');
      expect(indexes[1].isValid, true);
    });

    test('identifies partial index with condition', () async {
      stubExecute(_result(
        ['index_name', 'index_type', 'columns', 'is_unique', 'is_primary',
         'index_size', 'condition', 'tablespace', 'is_valid'],
        [
          ['idx_active_only', 'btree', ['email'], false, false, '8 kB', '(is_active = true)', null, true],
        ],
      ));

      final indexes = await service.getIndexes('conn-1', 'public', 'users');
      expect(indexes.first.condition, '(is_active = true)');
    });
  });

  // ---------------------------------------------------------------------------
  // getSequences
  // ---------------------------------------------------------------------------
  group('getSequences', () {
    test('returns sequence metadata', () async {
      stubExecute(_result(
        ['sequence_name', 'sequence_schema', 'data_type', 'start_value',
         'minimum_value', 'maximum_value', 'increment', 'current_value',
         'cycle_option', 'owned_by_table', 'owned_by_column'],
        [
          ['users_id_seq', 'public', 'bigint', 1, 1, 9223372036854775807, 1, 42, 'NO', 'users', 'id'],
        ],
      ));

      final seqs = await service.getSequences('conn-1', 'public');
      expect(seqs.length, 1);
      expect(seqs.first.sequenceName, 'users_id_seq');
      expect(seqs.first.dataType, 'bigint');
      expect(seqs.first.startValue, 1);
      expect(seqs.first.currentValue, 42);
      expect(seqs.first.isCycled, false);
      expect(seqs.first.ownedByTable, 'users');
      expect(seqs.first.ownedByColumn, 'id');
    });
  });

  // ---------------------------------------------------------------------------
  // getTableDependencies
  // ---------------------------------------------------------------------------
  group('getTableDependencies', () {
    test('returns both outgoing and incoming dependencies', () async {
      // First call = getForeignKeys (outgoing), second call = getIncomingReferences (incoming).
      stubExecuteSequence([
        _result(
          ['constraint_name', 'columns', 'ref_schema', 'ref_table', 'ref_columns',
           'update_rule', 'delete_rule'],
          [
            ['fk_team', ['team_id'], 'public', 'teams', ['id'], 'NO ACTION', 'CASCADE'],
          ],
        ),
        _result(
          ['constraint_name', 'columns', 'src_schema', 'src_table', 'ref_columns',
           'update_rule', 'delete_rule'],
          [
            ['fk_order_user', ['user_id'], 'public', 'orders', ['id'], 'NO ACTION', 'NO ACTION'],
          ],
        ),
      ]);

      final deps = await service.getTableDependencies('conn-1', 'public', 'users');

      expect(deps.length, 2);

      final outgoing = deps.where((d) => d.direction == 'outgoing').toList();
      expect(outgoing.length, 1);
      expect(outgoing.first.sourceTable, 'users');
      expect(outgoing.first.targetTable, 'teams');

      final incoming = deps.where((d) => d.direction == 'incoming').toList();
      expect(incoming.length, 1);
      expect(incoming.first.targetTable, 'users');
    });
  });

  // ---------------------------------------------------------------------------
  // getTableStatistics
  // ---------------------------------------------------------------------------
  group('getTableStatistics', () {
    test('maps all statistics fields', () async {
      final vacuumTime = DateTime.utc(2026, 1, 15, 10, 0);
      stubExecute(_result(
        ['live_rows', 'dead_rows', 'last_vacuum', 'last_autovacuum',
         'last_analyze', 'last_autoanalyze', 'seq_scans', 'idx_scans',
         'inserts', 'updates', 'deletes'],
        [
          [1500, 23, vacuumTime, null, vacuumTime, null, 100, 5000, 2000, 300, 50],
        ],
      ));

      final stats = await service.getTableStatistics('conn-1', 'public', 'users');
      expect(stats.liveRowCount, 1500);
      expect(stats.deadRowCount, 23);
      expect(stats.lastVacuum, vacuumTime);
      expect(stats.seqScans, 100);
      expect(stats.idxScans, 5000);
      expect(stats.insertCount, 2000);
      expect(stats.updateCount, 300);
      expect(stats.deleteCount, 50);
    });

    test('returns empty statistics when table not found', () async {
      stubExecute(_emptyResult(
        ['live_rows', 'dead_rows', 'last_vacuum', 'last_autovacuum',
         'last_analyze', 'last_autoanalyze', 'seq_scans', 'idx_scans',
         'inserts', 'updates', 'deletes'],
      ));

      final stats = await service.getTableStatistics('conn-1', 'public', 'missing');
      expect(stats.liveRowCount, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // getTableDdl
  // ---------------------------------------------------------------------------
  group('getTableDdl', () {
    test('returns CREATE TABLE statement', () async {
      // getColumns calls: PK query, FK query, columns query.
      // getConstraints call.
      // getForeignKeys call.
      // getIndexes call.
      stubExecuteSequence([
        // PK columns
        _result(['column_name'], [['id']]),
        // FK columns
        _emptyResult(['column_name']),
        // Full columns
        _result(
          ['column_name', 'ordinal_position', 'data_type', 'udt_name',
           'is_nullable', 'column_default', 'is_identity', 'identity_generation',
           'character_maximum_length', 'numeric_precision', 'numeric_scale',
           'collation_name', 'comment'],
          [
            ['id', 1, 'uuid', 'uuid', 'NO', null, 'NO', null, null, null, null, null, null],
            ['name', 2, 'character varying', 'varchar', 'NO', null, 'NO', null, 255, null, null, null, null],
          ],
        ),
        // Constraints
        _result(
          ['constraint_name', 'constraint_type', 'columns', 'check_clause',
           'is_deferrable', 'initially_deferred'],
          [
            ['users_pkey', 'PRIMARY KEY', ['id'], null, 'NO', 'NO'],
          ],
        ),
        // Foreign keys
        _emptyResult(
          ['constraint_name', 'columns', 'ref_schema', 'ref_table', 'ref_columns',
           'update_rule', 'delete_rule'],
        ),
        // Indexes
        _result(
          ['index_name', 'index_type', 'columns', 'is_unique', 'is_primary',
           'index_size', 'condition', 'tablespace', 'is_valid'],
          [
            ['users_pkey', 'btree', ['id'], true, true, '16 kB', null, null, true],
          ],
        ),
      ]);

      final ddl = await service.getTableDdl('conn-1', 'public', 'users');
      expect(ddl, contains('CREATE TABLE public.users'));
      expect(ddl, contains('id uuid'));
      expect(ddl, contains('name character varying'));
      expect(ddl, contains('PRIMARY KEY'));
    });
  });

  // ---------------------------------------------------------------------------
  // getRowCountEstimate
  // ---------------------------------------------------------------------------
  group('getRowCountEstimate', () {
    test('returns estimate from pg_class', () async {
      stubExecute(_result(['estimate'], [[42000]]));

      final count = await service.getRowCountEstimate('conn-1', 'public', 'users');
      expect(count, 42000);
    });

    test('returns zero when table not found', () async {
      stubExecute(_emptyResult(['estimate']));

      final count = await service.getRowCountEstimate('conn-1', 'public', 'missing');
      expect(count, 0);
    });
  });

  // ---------------------------------------------------------------------------
  // getDatabaseSize
  // ---------------------------------------------------------------------------
  group('getDatabaseSize', () {
    test('returns formatted size string', () async {
      stubExecute(_result(['pg_size_pretty'], [['1024 MB']]));

      final size = await service.getDatabaseSize('conn-1');
      expect(size, '1024 MB');
    });
  });

  // ---------------------------------------------------------------------------
  // searchObjects
  // ---------------------------------------------------------------------------
  group('searchObjects', () {
    test('finds tables by name pattern', () async {
      stubExecute(_result(
        ['schema_name', 'table_name', 'comment', 'rel_kind', 'row_estimate',
         'table_size', 'total_size', 'owner'],
        [
          ['public', 'users', null, 'r', 1500, '128 kB', '256 kB', 'codeops'],
          ['public', 'user_roles', null, 'r', 50, '16 kB', '32 kB', 'codeops'],
        ],
      ));

      final results = await service.searchObjects('conn-1', 'user');
      expect(results.length, 2);
      expect(results[0].tableName, 'users');
      expect(results[1].tableName, 'user_roles');
    });
  });

  // ---------------------------------------------------------------------------
  // Error handling
  // ---------------------------------------------------------------------------
  group('error handling', () {
    test('throws StateError when no active connection', () {
      when(() => mockConnService.getConnection('bad-conn')).thenReturn(null);

      expect(
        () => service.getSchemas('bad-conn'),
        throwsA(isA<StateError>()),
      );
    });
  });
}
