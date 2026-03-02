// Tests for ErDiagramService.
//
// Verifies diagram building, cardinality detection, force-directed layout,
// and the autoLayout method. Uses mocked SchemaIntrospectionService.
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:codeops/models/datalens_enums.dart';
import 'package:codeops/models/datalens_er_models.dart';
import 'package:codeops/models/datalens_models.dart';
import 'package:codeops/services/datalens/database_connection_service.dart';
import 'package:codeops/services/datalens/er_diagram_service.dart';
import 'package:codeops/services/datalens/schema_introspection_service.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockSchemaIntrospectionService extends Mock
    implements SchemaIntrospectionService {}

class MockDatabaseConnectionService extends Mock
    implements DatabaseConnectionService {}

void main() {
  late MockSchemaIntrospectionService mockSchema;
  late ErDiagramService service;

  setUp(() {
    mockSchema = MockSchemaIntrospectionService();
    service = ErDiagramService(mockSchema);
  });

  // ---------------------------------------------------------------------------
  // autoLayout
  // ---------------------------------------------------------------------------
  group('autoLayout', () {
    test('repositions tables so they are not all at zero', () {
      final state = ErDiagramState(
        connectionId: 'c1',
        schema: 'public',
        tables: [
          ErTableNode(
            schema: 'public',
            tableName: 'users',
            columns: const [
              ErColumn(name: 'id', dataType: 'int4', isPrimaryKey: true),
            ],
            position: Offset.zero,
          ),
          ErTableNode(
            schema: 'public',
            tableName: 'orders',
            columns: const [
              ErColumn(name: 'id', dataType: 'int4', isPrimaryKey: true),
              ErColumn(
                  name: 'user_id', dataType: 'uuid', isForeignKey: true),
            ],
            position: Offset.zero,
          ),
        ],
        relationships: const [
          ErRelationship(
            fromTable: 'orders',
            fromColumn: 'user_id',
            toTable: 'users',
            toColumn: 'id',
            cardinality: ErCardinality.manyToOne,
          ),
        ],
      );

      final result = service.autoLayout(state);

      // Tables should have been repositioned (not all at zero).
      final allAtZero = result.tables.every((t) => t.position == Offset.zero);
      expect(allAtZero, false);
    });

    test('separates tables so they do not overlap', () {
      final state = ErDiagramState(
        connectionId: 'c1',
        schema: 'public',
        tables: [
          ErTableNode(
            schema: 'public',
            tableName: 't1',
            columns: const [
              ErColumn(name: 'id', dataType: 'int4', isPrimaryKey: true),
            ],
            position: Offset.zero,
          ),
          ErTableNode(
            schema: 'public',
            tableName: 't2',
            columns: const [
              ErColumn(name: 'id', dataType: 'int4', isPrimaryKey: true),
            ],
            position: Offset.zero,
          ),
        ],
        relationships: const [],
      );

      final result = service.autoLayout(state);
      final dist =
          (result.tables[0].position - result.tables[1].position).distance;
      expect(dist, greaterThan(50));
    });

    test('handles single table without error', () {
      final state = ErDiagramState(
        connectionId: 'c1',
        schema: 'public',
        tables: [
          ErTableNode(
            schema: 'public',
            tableName: 'solo',
            columns: const [
              ErColumn(name: 'id', dataType: 'int4', isPrimaryKey: true),
            ],
          ),
        ],
        relationships: const [],
      );

      final result = service.autoLayout(state);
      expect(result.tables.length, 1);
      // Should be positioned at (50, 50) after normalization.
      expect(result.tables.first.position.dx, closeTo(50, 1));
      expect(result.tables.first.position.dy, closeTo(50, 1));
    });

    test('handles empty tables list', () {
      const state = ErDiagramState(
        connectionId: 'c1',
        schema: 'public',
        tables: [],
        relationships: [],
      );

      final result = service.autoLayout(state);
      expect(result.tables, isEmpty);
    });

    test('preserves metadata in returned state', () {
      final state = ErDiagramState(
        connectionId: 'conn-42',
        schema: 'myschema',
        tables: [
          ErTableNode(
            schema: 'myschema',
            tableName: 't1',
            columns: const [],
          ),
        ],
        relationships: const [],
        notation: ErNotation.idef1x,
        zoom: 2.5,
      );

      final result = service.autoLayout(state);
      expect(result.connectionId, 'conn-42');
      expect(result.schema, 'myschema');
      expect(result.notation, ErNotation.idef1x);
      expect(result.zoom, 2.5);
    });
  });

  // ---------------------------------------------------------------------------
  // buildDiagram
  // ---------------------------------------------------------------------------
  group('buildDiagram', () {
    test('builds diagram with tables and relationships', () async {
      when(() => mockSchema.getTables('c1', 'public')).thenAnswer(
        (_) async => [
          TableInfo(schemaName: 'public', tableName: 'users'),
          TableInfo(schemaName: 'public', tableName: 'orders'),
        ],
      );
      when(() => mockSchema.getColumns('c1', 'public', 'users')).thenAnswer(
        (_) async => const [
          ColumnInfo(
            columnName: 'id',
            dataType: 'int4',
            category: ColumnCategory.primaryKey,
            isNullable: false,
          ),
          ColumnInfo(
            columnName: 'email',
            dataType: 'text',
            isNullable: false,
          ),
        ],
      );
      when(() => mockSchema.getColumns('c1', 'public', 'orders')).thenAnswer(
        (_) async => const [
          ColumnInfo(
            columnName: 'id',
            dataType: 'int4',
            category: ColumnCategory.primaryKey,
            isNullable: false,
          ),
          ColumnInfo(
            columnName: 'user_id',
            dataType: 'uuid',
            category: ColumnCategory.foreignKey,
            isNullable: false,
          ),
        ],
      );
      when(() => mockSchema.getForeignKeys('c1', 'public', 'users'))
          .thenAnswer((_) async => const []);
      when(() => mockSchema.getForeignKeys('c1', 'public', 'orders'))
          .thenAnswer(
        (_) async => const [
          ForeignKeyInfo(
            constraintName: 'fk_orders_user',
            columns: ['user_id'],
            referencedTable: 'users',
            referencedColumns: ['id'],
          ),
        ],
      );
      when(() => mockSchema.getConstraints('c1', 'public', 'users'))
          .thenAnswer((_) async => const []);
      when(() => mockSchema.getConstraints('c1', 'public', 'orders'))
          .thenAnswer((_) async => const []);

      final result = await service.buildDiagram('c1', 'public');

      expect(result.tables.length, 2);
      expect(result.relationships.length, 1);
      expect(result.relationships.first.fromTable, 'orders');
      expect(result.relationships.first.toTable, 'users');
      expect(result.relationships.first.cardinality, ErCardinality.manyToOne);
    });

    test('filters tables when tableFilter is provided', () async {
      when(() => mockSchema.getTables('c1', 'public')).thenAnswer(
        (_) async => [
          TableInfo(schemaName: 'public', tableName: 'users'),
          TableInfo(schemaName: 'public', tableName: 'orders'),
          TableInfo(schemaName: 'public', tableName: 'products'),
        ],
      );
      when(() => mockSchema.getColumns('c1', 'public', 'users'))
          .thenAnswer((_) async => const [
                ColumnInfo(
                  columnName: 'id',
                  dataType: 'int4',
                  category: ColumnCategory.primaryKey,
                ),
              ]);
      when(() => mockSchema.getForeignKeys('c1', 'public', 'users'))
          .thenAnswer((_) async => const []);
      when(() => mockSchema.getConstraints('c1', 'public', 'users'))
          .thenAnswer((_) async => const []);

      final result = await service.buildDiagram(
        'c1',
        'public',
        tableFilter: ['users'],
      );

      expect(result.tables.length, 1);
      expect(result.tables.first.tableName, 'users');
    });

    test('detects oneToOne cardinality from unique constraint', () async {
      when(() => mockSchema.getTables('c1', 'public')).thenAnswer(
        (_) async => [
          TableInfo(schemaName: 'public', tableName: 'users'),
          TableInfo(schemaName: 'public', tableName: 'profiles'),
        ],
      );
      when(() => mockSchema.getColumns('c1', 'public', 'users'))
          .thenAnswer((_) async => const [
                ColumnInfo(
                  columnName: 'id',
                  dataType: 'int4',
                  category: ColumnCategory.primaryKey,
                  isNullable: false,
                ),
              ]);
      when(() => mockSchema.getColumns('c1', 'public', 'profiles'))
          .thenAnswer((_) async => const [
                ColumnInfo(
                  columnName: 'id',
                  dataType: 'int4',
                  category: ColumnCategory.primaryKey,
                  isNullable: false,
                ),
                ColumnInfo(
                  columnName: 'user_id',
                  dataType: 'uuid',
                  category: ColumnCategory.foreignKey,
                  isNullable: false,
                ),
              ]);
      when(() => mockSchema.getForeignKeys('c1', 'public', 'users'))
          .thenAnswer((_) async => const []);
      when(() => mockSchema.getForeignKeys('c1', 'public', 'profiles'))
          .thenAnswer(
        (_) async => const [
          ForeignKeyInfo(
            constraintName: 'fk_profile_user',
            columns: ['user_id'],
            referencedTable: 'users',
            referencedColumns: ['id'],
          ),
        ],
      );
      when(() => mockSchema.getConstraints('c1', 'public', 'users'))
          .thenAnswer((_) async => const []);
      when(() => mockSchema.getConstraints('c1', 'public', 'profiles'))
          .thenAnswer(
        (_) async => const [
          ConstraintInfo(
            constraintName: 'uq_profile_user',
            constraintType: ConstraintType.unique,
            columns: ['user_id'],
          ),
        ],
      );

      final result = await service.buildDiagram('c1', 'public');

      expect(result.relationships.length, 1);
      expect(
          result.relationships.first.cardinality, ErCardinality.oneToOne);
    });
  });

  // ---------------------------------------------------------------------------
  // buildSingleTableDiagram
  // ---------------------------------------------------------------------------
  group('buildSingleTableDiagram', () {
    test('includes referenced and referencing tables', () async {
      // Full buildDiagram mocks — set these first (before specific overrides).
      when(() => mockSchema.getTables('c1', 'public')).thenAnswer(
        (_) async => [
          TableInfo(schemaName: 'public', tableName: 'users'),
          TableInfo(schemaName: 'public', tableName: 'orders'),
          TableInfo(schemaName: 'public', tableName: 'order_items'),
        ],
      );
      for (final t in ['users', 'orders', 'order_items']) {
        when(() => mockSchema.getColumns('c1', 'public', t)).thenAnswer(
          (_) async => [
            ColumnInfo(
              columnName: 'id',
              dataType: 'int4',
              category: ColumnCategory.primaryKey,
            ),
          ],
        );
        when(() => mockSchema.getForeignKeys('c1', 'public', t))
            .thenAnswer((_) async => const []);
        when(() => mockSchema.getConstraints('c1', 'public', t))
            .thenAnswer((_) async => const []);
      }

      // Override: orders has FK to users (must come AFTER the loop).
      when(() => mockSchema.getForeignKeys('c1', 'public', 'orders'))
          .thenAnswer(
        (_) async => const [
          ForeignKeyInfo(
            constraintName: 'fk_orders_user',
            columns: ['user_id'],
            referencedTable: 'users',
            referencedColumns: ['id'],
          ),
        ],
      );
      when(() => mockSchema.getIncomingReferences('c1', 'public', 'orders'))
          .thenAnswer(
        (_) async => const [
          ForeignKeyInfo(
            constraintName: 'fk_items_order',
            columns: ['order_id'],
            referencedTable: 'order_items',
            referencedColumns: ['id'],
          ),
        ],
      );

      final result = await service.buildSingleTableDiagram(
        'c1',
        'public',
        'orders',
      );

      final tableNames = result.tables.map((t) => t.tableName).toSet();
      expect(tableNames, contains('orders'));
      expect(tableNames, contains('users'));
      expect(tableNames, contains('order_items'));
    });
  });
}
