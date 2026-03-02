// Tests for DataLens ER diagram data models.
//
// Verifies enum display names, ErColumn construction, ErTableNode
// expansion/collapse, ErRelationship toString, and ErDiagramState
// copyWith behavior.
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/datalens_er_models.dart';

void main() {
  // ---------------------------------------------------------------------------
  // ErCardinality
  // ---------------------------------------------------------------------------
  group('ErCardinality', () {
    test('displayName returns correct labels', () {
      expect(ErCardinality.oneToOne.displayName, '1:1');
      expect(ErCardinality.oneToMany.displayName, '1:N');
      expect(ErCardinality.manyToOne.displayName, 'N:1');
      expect(ErCardinality.manyToMany.displayName, 'M:N');
    });
  });

  // ---------------------------------------------------------------------------
  // ErNotation
  // ---------------------------------------------------------------------------
  group('ErNotation', () {
    test('displayName returns correct labels', () {
      expect(ErNotation.crowsFoot.displayName, "Crow's Foot");
      expect(ErNotation.idef1x.displayName, 'IDEF1X');
    });
  });

  // ---------------------------------------------------------------------------
  // ErDiagramScope
  // ---------------------------------------------------------------------------
  group('ErDiagramScope', () {
    test('displayName returns correct labels', () {
      expect(ErDiagramScope.fullSchema.displayName, 'Full Schema');
      expect(ErDiagramScope.singleTableRelated.displayName, 'Table + Related');
      expect(ErDiagramScope.customSelection.displayName, 'Custom Selection');
    });
  });

  // ---------------------------------------------------------------------------
  // ErColumn
  // ---------------------------------------------------------------------------
  group('ErColumn', () {
    test('toString includes name, type, and badges', () {
      const col = ErColumn(
        name: 'id',
        dataType: 'int4',
        isPrimaryKey: true,
        isForeignKey: false,
      );
      expect(col.toString(), contains('id'));
      expect(col.toString(), contains('int4'));
      expect(col.toString(), contains('PK'));
      expect(col.toString(), isNot(contains('FK')));
    });

    test('toString shows FK badge when foreign key', () {
      const col = ErColumn(
        name: 'user_id',
        dataType: 'uuid',
        isForeignKey: true,
      );
      expect(col.toString(), contains('FK'));
    });

    test('defaults are correct', () {
      const col = ErColumn(name: 'name', dataType: 'text');
      expect(col.isPrimaryKey, false);
      expect(col.isForeignKey, false);
      expect(col.isNullable, true);
      expect(col.isUnique, false);
      expect(col.referencedTable, isNull);
      expect(col.referencedColumn, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // ErTableNode
  // ---------------------------------------------------------------------------
  group('ErTableNode', () {
    test('keyColumns returns only PK and FK columns', () {
      final table = ErTableNode(
        schema: 'public',
        tableName: 'orders',
        columns: const [
          ErColumn(name: 'id', dataType: 'int4', isPrimaryKey: true),
          ErColumn(name: 'user_id', dataType: 'uuid', isForeignKey: true),
          ErColumn(name: 'total', dataType: 'numeric'),
          ErColumn(name: 'notes', dataType: 'text'),
        ],
      );
      expect(table.keyColumns.length, 2);
      expect(table.keyColumns.map((c) => c.name), containsAll(['id', 'user_id']));
    });

    test('displayColumns returns all columns when expanded', () {
      final table = ErTableNode(
        schema: 'public',
        tableName: 'users',
        columns: const [
          ErColumn(name: 'id', dataType: 'int4', isPrimaryKey: true),
          ErColumn(name: 'email', dataType: 'text'),
        ],
      );
      expect(table.isExpanded, true);
      expect(table.displayColumns.length, 2);
    });

    test('displayColumns returns only key columns when collapsed', () {
      final table = ErTableNode(
        schema: 'public',
        tableName: 'users',
        columns: const [
          ErColumn(name: 'id', dataType: 'int4', isPrimaryKey: true),
          ErColumn(name: 'email', dataType: 'text'),
          ErColumn(name: 'name', dataType: 'text'),
        ],
        isExpanded: false,
      );
      expect(table.displayColumns.length, 1);
      expect(table.displayColumns.first.name, 'id');
    });

    test('position is mutable', () {
      final table = ErTableNode(
        schema: 'public',
        tableName: 't',
        columns: const [],
      );
      expect(table.position, Offset.zero);
      table.position = const Offset(100, 200);
      expect(table.position, const Offset(100, 200));
    });

    test('toString includes table info', () {
      final table = ErTableNode(
        schema: 'public',
        tableName: 'users',
        columns: const [
          ErColumn(name: 'id', dataType: 'int4'),
        ],
      );
      expect(table.toString(), contains('public.users'));
      expect(table.toString(), contains('1 cols'));
    });
  });

  // ---------------------------------------------------------------------------
  // ErRelationship
  // ---------------------------------------------------------------------------
  group('ErRelationship', () {
    test('toString includes table.column and cardinality', () {
      const rel = ErRelationship(
        fromTable: 'orders',
        fromColumn: 'user_id',
        toTable: 'users',
        toColumn: 'id',
        cardinality: ErCardinality.manyToOne,
      );
      expect(rel.toString(), contains('orders.user_id'));
      expect(rel.toString(), contains('users.id'));
      expect(rel.toString(), contains('N:1'));
    });

    test('isOptional defaults to false', () {
      const rel = ErRelationship(
        fromTable: 'a',
        fromColumn: 'b',
        toTable: 'c',
        toColumn: 'd',
        cardinality: ErCardinality.oneToOne,
      );
      expect(rel.isOptional, false);
    });
  });

  // ---------------------------------------------------------------------------
  // ErDiagramState
  // ---------------------------------------------------------------------------
  group('ErDiagramState', () {
    test('copyWith overrides selected fields', () {
      const state = ErDiagramState(
        connectionId: 'c1',
        schema: 'public',
        tables: [],
        relationships: [],
      );
      final updated = state.copyWith(zoom: 2.0, notation: ErNotation.idef1x);
      expect(updated.zoom, 2.0);
      expect(updated.notation, ErNotation.idef1x);
      expect(updated.connectionId, 'c1');
      expect(updated.schema, 'public');
    });

    test('defaults are correct', () {
      const state = ErDiagramState(
        connectionId: 'c',
        schema: 's',
        tables: [],
        relationships: [],
      );
      expect(state.notation, ErNotation.crowsFoot);
      expect(state.zoom, 1.0);
      expect(state.pan, Offset.zero);
    });

    test('toString includes table and relationship counts', () {
      const state = ErDiagramState(
        connectionId: 'c',
        schema: 'public',
        tables: [],
        relationships: [],
      );
      expect(state.toString(), contains('public'));
      expect(state.toString(), contains('0 tables'));
      expect(state.toString(), contains('0 rels'));
    });
  });
}
