// Tests for SchemaIntrospectionService.
//
// Mocks DatabaseConnectionService and DatabaseDriverAdapter to verify
// that the service correctly delegates all introspection calls to the
// active driver adapter and handles missing connections gracefully.
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:codeops/models/datalens_enums.dart';
import 'package:codeops/models/datalens_models.dart';
import 'package:codeops/services/datalens/database_connection_service.dart';
import 'package:codeops/services/datalens/drivers/database_driver.dart';
import 'package:codeops/services/datalens/schema_introspection_service.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockDatabaseConnectionService extends Mock
    implements DatabaseConnectionService {}

class MockDatabaseDriverAdapter extends Mock
    implements DatabaseDriverAdapter {}

void main() {
  late MockDatabaseConnectionService mockConnService;
  late MockDatabaseDriverAdapter mockDriver;
  late SchemaIntrospectionService service;

  setUp(() {
    mockConnService = MockDatabaseConnectionService();
    mockDriver = MockDatabaseDriverAdapter();
    service = SchemaIntrospectionService(mockConnService);
    when(() => mockConnService.getDriver('conn-1')).thenReturn(mockDriver);
  });

  // ---------------------------------------------------------------------------
  // getSchemas
  // ---------------------------------------------------------------------------
  group('getSchemas', () {
    test('delegates to driver and returns results', () async {
      final schemas = [
        SchemaInfo(name: 'public', owner: 'postgres', tableCount: 12, viewCount: 3, sequenceCount: 5),
        SchemaInfo(name: 'app', owner: 'codeops', tableCount: 8, viewCount: 1, sequenceCount: 2),
      ];
      when(() => mockDriver.getSchemas()).thenAnswer((_) async => schemas);

      final result = await service.getSchemas('conn-1');

      expect(result.length, 2);
      expect(result[0].name, 'public');
      expect(result[0].tableCount, 12);
      expect(result[1].name, 'app');
      verify(() => mockDriver.getSchemas()).called(1);
    });

    test('returns empty list when driver returns empty', () async {
      when(() => mockDriver.getSchemas()).thenAnswer((_) async => []);

      final result = await service.getSchemas('conn-1');
      expect(result, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // getTables
  // ---------------------------------------------------------------------------
  group('getTables', () {
    test('delegates to driver with schema name', () async {
      final tables = [
        TableInfo(schemaName: 'public', tableName: 'users', objectType: ObjectType.table, rowEstimate: 1500),
        TableInfo(schemaName: 'public', tableName: 'active_users', objectType: ObjectType.view),
      ];
      when(() => mockDriver.getTables('public')).thenAnswer((_) async => tables);

      final result = await service.getTables('conn-1', 'public');

      expect(result.length, 2);
      expect(result[0].tableName, 'users');
      expect(result[0].objectType, ObjectType.table);
      expect(result[1].objectType, ObjectType.view);
      verify(() => mockDriver.getTables('public')).called(1);
    });
  });

  // ---------------------------------------------------------------------------
  // getColumns
  // ---------------------------------------------------------------------------
  group('getColumns', () {
    test('delegates to driver with schema and table', () async {
      final columns = [
        ColumnInfo(columnName: 'id', ordinalPosition: 1, dataType: 'uuid', category: ColumnCategory.primaryKey),
        ColumnInfo(columnName: 'name', ordinalPosition: 2, dataType: 'varchar', category: ColumnCategory.regular),
      ];
      when(() => mockDriver.getColumns('public', 'users'))
          .thenAnswer((_) async => columns);

      final result = await service.getColumns('conn-1', 'public', 'users');

      expect(result.length, 2);
      expect(result[0].columnName, 'id');
      expect(result[0].category, ColumnCategory.primaryKey);
      verify(() => mockDriver.getColumns('public', 'users')).called(1);
    });
  });

  // ---------------------------------------------------------------------------
  // getConstraints
  // ---------------------------------------------------------------------------
  group('getConstraints', () {
    test('delegates to driver', () async {
      final constraints = [
        ConstraintInfo(constraintName: 'users_pkey', constraintType: ConstraintType.primaryKey, columns: ['id']),
      ];
      when(() => mockDriver.getConstraints('public', 'users'))
          .thenAnswer((_) async => constraints);

      final result = await service.getConstraints('conn-1', 'public', 'users');

      expect(result.length, 1);
      expect(result.first.constraintName, 'users_pkey');
      verify(() => mockDriver.getConstraints('public', 'users')).called(1);
    });
  });

  // ---------------------------------------------------------------------------
  // getForeignKeys
  // ---------------------------------------------------------------------------
  group('getForeignKeys', () {
    test('delegates to driver', () async {
      final fks = [
        ForeignKeyInfo(
          constraintName: 'fk_team',
          columns: ['team_id'],
          referencedSchema: 'public',
          referencedTable: 'teams',
          referencedColumns: ['id'],
          onUpdate: 'NO ACTION',
          onDelete: 'CASCADE',
        ),
      ];
      when(() => mockDriver.getForeignKeys('public', 'users'))
          .thenAnswer((_) async => fks);

      final result = await service.getForeignKeys('conn-1', 'public', 'users');

      expect(result.length, 1);
      expect(result.first.constraintName, 'fk_team');
      expect(result.first.referencedTable, 'teams');
      verify(() => mockDriver.getForeignKeys('public', 'users')).called(1);
    });
  });

  // ---------------------------------------------------------------------------
  // getIncomingReferences
  // ---------------------------------------------------------------------------
  group('getIncomingReferences', () {
    test('delegates to driver', () async {
      final refs = [
        ForeignKeyInfo(
          constraintName: 'fk_user_order',
          columns: ['user_id'],
          referencedTable: 'orders',
          referencedColumns: ['id'],
        ),
      ];
      when(() => mockDriver.getIncomingReferences('public', 'users'))
          .thenAnswer((_) async => refs);

      final result = await service.getIncomingReferences('conn-1', 'public', 'users');

      expect(result.length, 1);
      expect(result.first.constraintName, 'fk_user_order');
      verify(() => mockDriver.getIncomingReferences('public', 'users')).called(1);
    });
  });

  // ---------------------------------------------------------------------------
  // getIndexes
  // ---------------------------------------------------------------------------
  group('getIndexes', () {
    test('delegates to driver', () async {
      final indexes = [
        IndexInfo(indexName: 'users_pkey', indexType: IndexType.btree, columns: ['id'], isPrimary: true, isUnique: true),
        IndexInfo(indexName: 'idx_email', indexType: IndexType.btree, columns: ['email'], isPrimary: false, isUnique: true),
      ];
      when(() => mockDriver.getIndexes('public', 'users'))
          .thenAnswer((_) async => indexes);

      final result = await service.getIndexes('conn-1', 'public', 'users');

      expect(result.length, 2);
      expect(result[0].indexName, 'users_pkey');
      expect(result[0].isPrimary, true);
      verify(() => mockDriver.getIndexes('public', 'users')).called(1);
    });
  });

  // ---------------------------------------------------------------------------
  // getSequences
  // ---------------------------------------------------------------------------
  group('getSequences', () {
    test('delegates to driver', () async {
      final seqs = [
        SequenceInfo(sequenceName: 'users_id_seq', schemaName: 'public', currentValue: 42),
      ];
      when(() => mockDriver.getSequences('public'))
          .thenAnswer((_) async => seqs);

      final result = await service.getSequences('conn-1', 'public');

      expect(result.length, 1);
      expect(result.first.sequenceName, 'users_id_seq');
      verify(() => mockDriver.getSequences('public')).called(1);
    });
  });

  // ---------------------------------------------------------------------------
  // getTableDependencies
  // ---------------------------------------------------------------------------
  group('getTableDependencies', () {
    test('combines outgoing and incoming FK relationships', () async {
      when(() => mockDriver.getForeignKeys('public', 'users'))
          .thenAnswer((_) async => [
                ForeignKeyInfo(
                  constraintName: 'fk_team',
                  columns: ['team_id'],
                  referencedTable: 'teams',
                  referencedColumns: ['id'],
                ),
              ]);
      when(() => mockDriver.getIncomingReferences('public', 'users'))
          .thenAnswer((_) async => [
                ForeignKeyInfo(
                  constraintName: 'fk_order_user',
                  columns: ['user_id'],
                  referencedTable: 'orders',
                  referencedColumns: ['id'],
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
    test('delegates to driver', () async {
      const stats = TableStatistics(liveRowCount: 1500, deadRowCount: 23, seqScans: 100);
      when(() => mockDriver.getTableStatistics('public', 'users'))
          .thenAnswer((_) async => stats);

      final result = await service.getTableStatistics('conn-1', 'public', 'users');

      expect(result.liveRowCount, 1500);
      expect(result.deadRowCount, 23);
      expect(result.seqScans, 100);
      verify(() => mockDriver.getTableStatistics('public', 'users')).called(1);
    });
  });

  // ---------------------------------------------------------------------------
  // getTableDdl
  // ---------------------------------------------------------------------------
  group('getTableDdl', () {
    test('delegates to driver', () async {
      when(() => mockDriver.getTableDdl('public', 'users'))
          .thenAnswer((_) async => 'CREATE TABLE public.users (id uuid);');

      final result = await service.getTableDdl('conn-1', 'public', 'users');

      expect(result, contains('CREATE TABLE'));
      verify(() => mockDriver.getTableDdl('public', 'users')).called(1);
    });
  });

  // ---------------------------------------------------------------------------
  // getRowCountEstimate
  // ---------------------------------------------------------------------------
  group('getRowCountEstimate', () {
    test('delegates to driver', () async {
      when(() => mockDriver.getRowCountEstimate('public', 'users'))
          .thenAnswer((_) async => 42000);

      final result = await service.getRowCountEstimate('conn-1', 'public', 'users');

      expect(result, 42000);
      verify(() => mockDriver.getRowCountEstimate('public', 'users')).called(1);
    });
  });

  // ---------------------------------------------------------------------------
  // getDatabaseSize
  // ---------------------------------------------------------------------------
  group('getDatabaseSize', () {
    test('delegates to driver', () async {
      when(() => mockDriver.getDatabaseSize())
          .thenAnswer((_) async => '1024 MB');

      final result = await service.getDatabaseSize('conn-1');

      expect(result, '1024 MB');
      verify(() => mockDriver.getDatabaseSize()).called(1);
    });
  });

  // ---------------------------------------------------------------------------
  // searchObjects
  // ---------------------------------------------------------------------------
  group('searchObjects', () {
    test('delegates to driver', () async {
      final tables = [
        TableInfo(schemaName: 'public', tableName: 'users', objectType: ObjectType.table),
      ];
      when(() => mockDriver.searchObjects('user'))
          .thenAnswer((_) async => tables);

      final result = await service.searchObjects('conn-1', 'user');

      expect(result.length, 1);
      expect(result.first.tableName, 'users');
      verify(() => mockDriver.searchObjects('user')).called(1);
    });
  });

  // ---------------------------------------------------------------------------
  // Error handling
  // ---------------------------------------------------------------------------
  group('error handling', () {
    test('throws StateError when no active driver', () {
      when(() => mockConnService.getDriver('bad-conn')).thenReturn(null);

      expect(
        () => service.getSchemas('bad-conn'),
        throwsA(isA<StateError>()),
      );
    });

    test('throws StateError for all methods when no driver', () {
      when(() => mockConnService.getDriver('bad')).thenReturn(null);

      expect(() => service.getTables('bad', 'public'), throwsA(isA<StateError>()));
      expect(() => service.getColumns('bad', 'public', 'users'), throwsA(isA<StateError>()));
      expect(() => service.getConstraints('bad', 'public', 'users'), throwsA(isA<StateError>()));
      expect(() => service.getForeignKeys('bad', 'public', 'users'), throwsA(isA<StateError>()));
      expect(() => service.getIncomingReferences('bad', 'public', 'users'), throwsA(isA<StateError>()));
      expect(() => service.getIndexes('bad', 'public', 'users'), throwsA(isA<StateError>()));
      expect(() => service.getSequences('bad', 'public'), throwsA(isA<StateError>()));
      expect(() => service.getTableStatistics('bad', 'public', 'users'), throwsA(isA<StateError>()));
      expect(() => service.getTableDdl('bad', 'public', 'users'), throwsA(isA<StateError>()));
      expect(() => service.getRowCountEstimate('bad', 'public', 'users'), throwsA(isA<StateError>()));
      expect(() => service.getDatabaseSize('bad'), throwsA(isA<StateError>()));
      expect(() => service.searchObjects('bad', 'query'), throwsA(isA<StateError>()));
    });
  });
}
