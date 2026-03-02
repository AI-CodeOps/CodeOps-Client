// Tests for DataEditorService.
//
// Verifies pending changes management (stage, revert, apply), SQL generation,
// primary key resolution, and caching. Uses mocked QueryExecutionService and
// SchemaIntrospectionService.
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:codeops/models/datalens_enums.dart';
import 'package:codeops/models/datalens_models.dart';
import 'package:codeops/services/datalens/database_connection_service.dart';
import 'package:codeops/services/datalens/data_editor_service.dart';
import 'package:codeops/services/datalens/query_execution_service.dart';
import 'package:codeops/services/datalens/query_history_service.dart';
import 'package:codeops/services/datalens/schema_introspection_service.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockQueryExecutionService extends Mock
    implements QueryExecutionService {}

class MockSchemaIntrospectionService extends Mock
    implements SchemaIntrospectionService {}

class MockDatabaseConnectionService extends Mock
    implements DatabaseConnectionService {}

class MockQueryHistoryService extends Mock implements QueryHistoryService {}

void main() {
  late MockQueryExecutionService mockQueryService;
  late MockSchemaIntrospectionService mockSchemaService;
  late DataEditorService service;

  setUp(() {
    mockQueryService = MockQueryExecutionService();
    mockSchemaService = MockSchemaIntrospectionService();
    service = DataEditorService(mockQueryService, mockSchemaService);
  });

  // ─────────────────────────────────────────────────────────────────────────
  // RowKey Equality
  // ─────────────────────────────────────────────────────────────────────────
  group('RowKey', () {
    test('equality works for identical keys', () {
      final a = RowKey({'id': 1});
      final b = RowKey({'id': 1});
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('inequality for different keys', () {
      final a = RowKey({'id': 1});
      final b = RowKey({'id': 2});
      expect(a, isNot(equals(b)));
    });

    test('toString includes values', () {
      final key = RowKey({'id': 42});
      expect(key.toString(), contains('42'));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Staging Edits
  // ─────────────────────────────────────────────────────────────────────────
  group('stageEdit', () {
    test('stages a cell edit', () {
      service.stageEdit('c1', 'public', 'users', RowKey({'id': 1}),
          const CellChange(columnName: 'name', originalValue: 'old', newValue: 'new'));

      expect(service.hasPendingChanges('c1', 'public', 'users'), isTrue);
      expect(service.getPendingChangeCount('c1', 'public', 'users'), 1);

      final changes = service.getPendingChanges('c1', 'public', 'users');
      expect(changes.first.type, RowChangeType.update);
      expect(changes.first.cellChanges.first.columnName, 'name');
    });

    test('updates existing cell change for same row and column', () {
      final rowKey = RowKey({'id': 1});
      service.stageEdit('c1', 'public', 'users', rowKey,
          const CellChange(columnName: 'name', originalValue: 'old', newValue: 'mid'));
      service.stageEdit('c1', 'public', 'users', rowKey,
          const CellChange(columnName: 'name', originalValue: 'old', newValue: 'final'));

      expect(service.getPendingChangeCount('c1', 'public', 'users'), 1);
      final changes = service.getPendingChanges('c1', 'public', 'users');
      expect(changes.first.cellChanges.first.newValue, 'final');
    });

    test('removes change when new value equals original', () {
      final rowKey = RowKey({'id': 1});
      service.stageEdit('c1', 'public', 'users', rowKey,
          const CellChange(columnName: 'name', originalValue: 'old', newValue: 'new'));
      service.stageEdit('c1', 'public', 'users', rowKey,
          const CellChange(columnName: 'name', originalValue: 'old', newValue: 'old'));

      expect(service.hasPendingChanges('c1', 'public', 'users'), isFalse);
    });

    test('tracks multiple columns on same row', () {
      final rowKey = RowKey({'id': 1});
      service.stageEdit('c1', 'public', 'users', rowKey,
          const CellChange(columnName: 'name', originalValue: 'a', newValue: 'b'));
      service.stageEdit('c1', 'public', 'users', rowKey,
          const CellChange(columnName: 'email', originalValue: 'x', newValue: 'y'));

      expect(service.getPendingChangeCount('c1', 'public', 'users'), 1);
      final changes = service.getPendingChanges('c1', 'public', 'users');
      expect(changes.first.cellChanges.length, 2);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Staging Inserts, Deletes, Duplicates
  // ─────────────────────────────────────────────────────────────────────────
  group('stageInsert', () {
    test('stages a new row insert', () {
      service.stageInsert('c1', 'public', 'users', {'name': 'Alice', 'age': 30});

      expect(service.getPendingChangeCount('c1', 'public', 'users'), 1);
      final changes = service.getPendingChanges('c1', 'public', 'users');
      expect(changes.first.type, RowChangeType.insert);
      expect(changes.first.rowData?['name'], 'Alice');
    });
  });

  group('stageDelete', () {
    test('stages a row deletion', () {
      service.stageDelete('c1', 'public', 'users', RowKey({'id': 5}));

      expect(service.getPendingChangeCount('c1', 'public', 'users'), 1);
      final changes = service.getPendingChanges('c1', 'public', 'users');
      expect(changes.first.type, RowChangeType.delete);
    });

    test('removes pending update when deleting same row', () {
      final rowKey = RowKey({'id': 5});
      service.stageEdit('c1', 'public', 'users', rowKey,
          const CellChange(columnName: 'name', originalValue: 'a', newValue: 'b'));
      service.stageDelete('c1', 'public', 'users', rowKey);

      final changes = service.getPendingChanges('c1', 'public', 'users');
      expect(changes.length, 1);
      expect(changes.first.type, RowChangeType.delete);
    });
  });

  group('stageDuplicate', () {
    test('stages a row duplication as insert', () {
      service.stageDuplicate('c1', 'public', 'users', {'name': 'Bob'});

      final changes = service.getPendingChanges('c1', 'public', 'users');
      expect(changes.first.type, RowChangeType.duplicate);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Revert
  // ─────────────────────────────────────────────────────────────────────────
  group('revert', () {
    test('revertChange removes a specific change by index', () {
      service.stageInsert('c1', 'public', 'users', {'name': 'A'});
      service.stageInsert('c1', 'public', 'users', {'name': 'B'});

      service.revertChange('c1', 'public', 'users', 0);

      final changes = service.getPendingChanges('c1', 'public', 'users');
      expect(changes.length, 1);
      expect(changes.first.rowData?['name'], 'B');
    });

    test('revertAll removes all changes for a table', () {
      service.stageInsert('c1', 'public', 'users', {'name': 'A'});
      service.stageDelete('c1', 'public', 'users', RowKey({'id': 1}));

      service.revertAll('c1', 'public', 'users');

      expect(service.hasPendingChanges('c1', 'public', 'users'), isFalse);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // SQL Generation
  // ─────────────────────────────────────────────────────────────────────────
  group('generateSql', () {
    test('generates UPDATE for cell edit', () {
      service.stageEdit('c1', 'public', 'users', RowKey({'id': 1}),
          const CellChange(columnName: 'name', originalValue: 'old', newValue: 'new'));

      final sql = service.generateSql('c1', 'public', 'users');

      expect(sql.length, 1);
      expect(sql.first, contains('UPDATE'));
      expect(sql.first, contains('"name" = \'new\''));
      expect(sql.first, contains('"id" = 1'));
    });

    test('generates INSERT for new row', () {
      service.stageInsert('c1', 'public', 'users', {'name': 'Alice', 'age': 30});

      final sql = service.generateSql('c1', 'public', 'users');

      expect(sql.length, 1);
      expect(sql.first, contains('INSERT INTO'));
      expect(sql.first, contains("'Alice'"));
      expect(sql.first, contains('30'));
    });

    test('generates DELETE for removed row', () {
      service.stageDelete('c1', 'public', 'users', RowKey({'id': 5}));

      final sql = service.generateSql('c1', 'public', 'users');

      expect(sql.length, 1);
      expect(sql.first, contains('DELETE FROM'));
      expect(sql.first, contains('"id" = 5'));
    });

    test('handles NULL values in SQL generation', () {
      service.stageEdit('c1', 'public', 'users', RowKey({'id': 1}),
          const CellChange(columnName: 'email', originalValue: 'x', newValue: null));

      final sql = service.generateSql('c1', 'public', 'users');

      expect(sql.first, contains('"email" = NULL'));
    });

    test('handles boolean values in SQL generation', () {
      service.stageEdit('c1', 'public', 'users', RowKey({'id': 1}),
          const CellChange(columnName: 'active', originalValue: false, newValue: true));

      final sql = service.generateSql('c1', 'public', 'users');

      expect(sql.first, contains('"active" = TRUE'));
    });

    test('escapes single quotes in string values', () {
      service.stageEdit('c1', 'public', 'users', RowKey({'id': 1}),
          const CellChange(
              columnName: 'name', originalValue: 'old', newValue: "O'Brien"));

      final sql = service.generateSql('c1', 'public', 'users');

      expect(sql.first, contains("'O''Brien'"));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Apply
  // ─────────────────────────────────────────────────────────────────────────
  group('applyAll', () {
    test('executes generated SQL and clears changes on success', () async {
      service.stageInsert('c1', 'public', 'users', {'name': 'Alice'});

      when(() => mockQueryService.executeQuery('c1', any()))
          .thenAnswer((_) async => const QueryResult(
                status: QueryStatus.completed,
                rowCount: 1,
              ));

      final result = await service.applyAll('c1', 'public', 'users');

      expect(result.isSuccess, isTrue);
      expect(result.successCount, 1);
      expect(result.failureCount, 0);
      expect(service.hasPendingChanges('c1', 'public', 'users'), isFalse);
    });

    test('reports failures and keeps changes', () async {
      service.stageInsert('c1', 'public', 'users', {'name': 'Alice'});

      when(() => mockQueryService.executeQuery('c1', any()))
          .thenAnswer((_) async => const QueryResult(
                status: QueryStatus.failed,
                error: 'duplicate key',
              ));

      final result = await service.applyAll('c1', 'public', 'users');

      expect(result.isSuccess, isFalse);
      expect(result.failureCount, 1);
      expect(result.errors.first, contains('duplicate key'));
      expect(service.hasPendingChanges('c1', 'public', 'users'), isTrue);
    });

    test('returns empty result when no changes', () async {
      final result = await service.applyAll('c1', 'public', 'users');

      expect(result.successCount, 0);
      expect(result.failureCount, 0);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Primary Key Resolution
  // ─────────────────────────────────────────────────────────────────────────
  group('getPrimaryKeyColumns', () {
    test('resolves and caches primary key columns', () async {
      when(() => mockSchemaService.getColumns('c1', 'public', 'users'))
          .thenAnswer((_) async => [
                const ColumnInfo(
                  columnName: 'id',
                  dataType: 'integer',
                  ordinalPosition: 1,
                  category: ColumnCategory.primaryKey,
                ),
                const ColumnInfo(
                  columnName: 'name',
                  dataType: 'text',
                  ordinalPosition: 2,
                  category: ColumnCategory.regular,
                ),
              ]);

      final pkCols =
          await service.getPrimaryKeyColumns('c1', 'public', 'users');
      expect(pkCols, ['id']);

      // Second call should use cache (no additional getColumns call).
      final pkCols2 =
          await service.getPrimaryKeyColumns('c1', 'public', 'users');
      expect(pkCols2, ['id']);
      verify(() => mockSchemaService.getColumns('c1', 'public', 'users'))
          .called(1);
    });
  });

  group('buildRowKey', () {
    test('builds RowKey from result columns and row data', () {
      final pkColumns = ['id'];
      final resultColumns = [
        const QueryColumn(name: 'id'),
        const QueryColumn(name: 'name'),
      ];
      final rowData = [42, 'Alice'];

      final key = service.buildRowKey(pkColumns, resultColumns, rowData);

      expect(key.values, {'id': 42});
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Cache Management
  // ─────────────────────────────────────────────────────────────────────────
  group('clearAll', () {
    test('clears all pending changes and caches', () async {
      service.stageInsert('c1', 'public', 'users', {'name': 'A'});

      when(() => mockSchemaService.getColumns('c1', 'public', 'users'))
          .thenAnswer((_) async => [
                const ColumnInfo(
                  columnName: 'id',
                  dataType: 'integer',
                  ordinalPosition: 1,
                  category: ColumnCategory.primaryKey,
                ),
              ]);
      await service.getPrimaryKeyColumns('c1', 'public', 'users');

      service.clearAll();

      expect(service.hasPendingChanges('c1', 'public', 'users'), isFalse);

      // PK cache should be cleared — next call should re-fetch.
      await service.getPrimaryKeyColumns('c1', 'public', 'users');
      verify(() => mockSchemaService.getColumns('c1', 'public', 'users'))
          .called(2);
    });
  });
}
