// Tests for SqlAutocompleteService.
//
// Verifies context-aware completions, fuzzy matching, caching, and
// static SQL knowledge (keywords, functions, data types) without
// requiring a real PostgreSQL connection.
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:codeops/models/datalens_models.dart';
import 'package:codeops/services/datalens/database_connection_service.dart';
import 'package:codeops/services/datalens/schema_introspection_service.dart';
import 'package:codeops/services/datalens/sql_autocomplete_service.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockDatabaseConnectionService extends Mock
    implements DatabaseConnectionService {}

class MockSchemaIntrospectionService extends Mock
    implements SchemaIntrospectionService {}

void main() {
  late MockSchemaIntrospectionService mockSchemaService;
  late SqlAutocompleteService service;

  setUp(() {
    mockSchemaService = MockSchemaIntrospectionService();
    service = SqlAutocompleteService(mockSchemaService);
  });

  /// Stubs schema introspection to return a single schema with tables.
  void stubSchemaWithTables(
    String connectionId, {
    String schemaName = 'public',
    List<String> tableNames = const ['users', 'orders', 'products'],
  }) {
    when(() => mockSchemaService.getSchemas(connectionId))
        .thenAnswer((_) async => [
              SchemaInfo(name: schemaName),
            ]);
    when(() => mockSchemaService.getTables(connectionId, schemaName))
        .thenAnswer((_) async => tableNames
            .map((t) => TableInfo(
                  schemaName: schemaName,
                  tableName: t,
                ))
            .toList());
  }

  /// Stubs column introspection for a specific table.
  void stubColumns(
    String connectionId,
    String schemaName,
    String tableName,
    List<String> columnNames,
  ) {
    when(() => mockSchemaService.getColumns(
          connectionId,
          schemaName,
          tableName,
        )).thenAnswer((_) async => columnNames
        .map((c) => ColumnInfo(
              columnName: c,
              dataType: 'text',
              ordinalPosition: 1,
            ))
        .toList());
  }

  // ---------------------------------------------------------------------------
  // General context — keywords, functions, types
  // ---------------------------------------------------------------------------
  group('General context completions', () {
    test('returns SQL keywords for empty query', () async {
      stubSchemaWithTables('conn-1');

      final completions = await service.getCompletions('', 0, 'conn-1');

      // Should include keywords, functions, data types, and tables.
      expect(completions, isNotEmpty);
      final labels = completions.map((c) => c.label).toSet();
      expect(labels, contains('SELECT'));
      expect(labels, contains('FROM'));
      expect(labels, contains('WHERE'));
    });

    test('filters completions by prefix match', () async {
      stubSchemaWithTables('conn-1');

      final completions =
          await service.getCompletions('SEL', 3, 'conn-1');

      expect(completions, isNotEmpty);
      // SELECT should be first because prefix matches are prioritized.
      expect(completions.first.label, 'SELECT');
      // Verify the list is filtered — unrelated items should be excluded.
      final labels = completions.map((c) => c.label).toSet();
      expect(labels, contains('SELECT'));
      expect(labels.contains('FROM'), isFalse);
    });

    test('includes SQL functions in general context', () async {
      stubSchemaWithTables('conn-1');

      final completions =
          await service.getCompletions('COU', 3, 'conn-1');

      final labels = completions.map((c) => c.label).toSet();
      expect(labels, contains('COUNT'));
    });
  });

  // ---------------------------------------------------------------------------
  // After FROM — table completions
  // ---------------------------------------------------------------------------
  group('After FROM context', () {
    test('suggests tables after FROM keyword', () async {
      stubSchemaWithTables('conn-1');

      final completions = await service.getCompletions(
        'SELECT * FROM ',
        14,
        'conn-1',
      );

      final tableItems = completions
          .where((c) => c.kind == CompletionKind.table)
          .toList();
      expect(tableItems, isNotEmpty);
      final tableLabels = tableItems.map((c) => c.label).toSet();
      expect(tableLabels, contains('users'));
      expect(tableLabels, contains('orders'));
      expect(tableLabels, contains('products'));
    });

    test('filters tables by partial name', () async {
      stubSchemaWithTables('conn-1');

      final completions = await service.getCompletions(
        'SELECT * FROM us',
        16,
        'conn-1',
      );

      final tableItems = completions
          .where((c) => c.kind == CompletionKind.table)
          .toList();
      expect(tableItems.any((c) => c.label == 'users'), isTrue);
      // "orders" should not match "us" prefix.
      expect(tableItems.any((c) => c.label == 'orders'), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // After dot — column completions
  // ---------------------------------------------------------------------------
  group('After dot context', () {
    test('suggests columns after tableName.', () async {
      stubSchemaWithTables('conn-1');
      stubColumns('conn-1', 'public', 'users', ['id', 'name', 'email']);

      final completions = await service.getCompletions(
        'SELECT users. FROM users',
        14,
        'conn-1',
      );

      final columnItems = completions
          .where((c) => c.kind == CompletionKind.column)
          .toList();
      expect(columnItems, hasLength(3));
      final colLabels = columnItems.map((c) => c.label).toSet();
      expect(colLabels, contains('id'));
      expect(colLabels, contains('name'));
      expect(colLabels, contains('email'));
    });
  });

  // ---------------------------------------------------------------------------
  // Caching
  // ---------------------------------------------------------------------------
  group('Caching', () {
    test('clearCache removes cached data for connection', () async {
      stubSchemaWithTables('conn-1');

      // First call loads cache.
      await service.getCompletions('SELECT * FROM ', 14, 'conn-1');

      // Clear cache.
      service.clearCache('conn-1');

      // Second call should re-fetch from schema service.
      await service.getCompletions('SELECT * FROM ', 14, 'conn-1');

      // getSchemas should have been called twice (once per fetch).
      verify(() => mockSchemaService.getSchemas('conn-1')).called(2);
    });

    test('clearAllCaches removes all cached data', () async {
      stubSchemaWithTables('conn-1');
      stubSchemaWithTables('conn-2');

      await service.getCompletions('SELECT * FROM ', 14, 'conn-1');
      await service.getCompletions('SELECT * FROM ', 14, 'conn-2');

      service.clearAllCaches();

      await service.getCompletions('SELECT * FROM ', 14, 'conn-1');
      await service.getCompletions('SELECT * FROM ', 14, 'conn-2');

      verify(() => mockSchemaService.getSchemas('conn-1')).called(2);
      verify(() => mockSchemaService.getSchemas('conn-2')).called(2);
    });
  });

  // ---------------------------------------------------------------------------
  // Fuzzy matching
  // ---------------------------------------------------------------------------
  group('Fuzzy matching', () {
    test('matches by substring', () async {
      stubSchemaWithTables('conn-1');

      final completions =
          await service.getCompletions('IMIT', 4, 'conn-1');

      final labels = completions.map((c) => c.label).toSet();
      expect(labels, contains('LIMIT'));
    });

    test('matches by character-by-character fuzzy', () async {
      stubSchemaWithTables('conn-1');

      // "slct" should fuzzy-match "SELECT".
      final completions =
          await service.getCompletions('slct', 4, 'conn-1');

      final labels = completions.map((c) => c.label).toSet();
      expect(labels, contains('SELECT'));
    });
  });
}
