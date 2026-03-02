// Tests for ErExportService.
//
// Verifies PNG export produces non-empty bytes, SVG export produces valid
// markup, and empty diagrams return appropriate empty results.
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/datalens_er_models.dart';
import 'package:codeops/services/datalens/er_export_service.dart';

ErDiagramState _testState() => ErDiagramState(
      connectionId: 'test',
      schema: 'public',
      tables: [
        ErTableNode(
          schema: 'public',
          tableName: 'users',
          columns: const [
            ErColumn(name: 'id', dataType: 'int4', isPrimaryKey: true),
            ErColumn(name: 'email', dataType: 'text'),
          ],
          position: const Offset(50, 50),
        ),
        ErTableNode(
          schema: 'public',
          tableName: 'orders',
          columns: const [
            ErColumn(name: 'id', dataType: 'int4', isPrimaryKey: true),
            ErColumn(
                name: 'user_id', dataType: 'uuid', isForeignKey: true),
          ],
          position: const Offset(350, 50),
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

void main() {
  const service = ErExportService();

  // ---------------------------------------------------------------------------
  // SVG Export
  // ---------------------------------------------------------------------------
  group('exportSvg', () {
    test('returns minimal SVG for empty diagram', () {
      const empty = ErDiagramState(
        connectionId: 'c',
        schema: 's',
        tables: [],
        relationships: [],
      );
      final svg = service.exportSvg(empty);
      expect(svg, contains('<svg'));
      expect(svg, contains('xmlns'));
    });

    test('produces SVG with table elements', () {
      final svg = service.exportSvg(_testState());
      expect(svg, contains('<svg'));
      expect(svg, contains('users'));
      expect(svg, contains('orders'));
      expect(svg, contains('</svg>'));
    });

    test('includes relationship lines', () {
      final svg = service.exportSvg(_testState());
      expect(svg, contains('<line'));
      expect(svg, contains('N:1'));
    });

    test('includes column badges', () {
      final svg = service.exportSvg(_testState());
      expect(svg, contains('PK'));
      expect(svg, contains('FK'));
    });

    test('escapes special characters in table names', () {
      final state = ErDiagramState(
        connectionId: 'c',
        schema: 's',
        tables: [
          ErTableNode(
            schema: 's',
            tableName: 'a<b&c',
            columns: const [ErColumn(name: 'id', dataType: 'int4')],
            position: const Offset(50, 50),
          ),
        ],
        relationships: const [],
      );
      final svg = service.exportSvg(state);
      expect(svg, contains('a&lt;b&amp;c'));
      expect(svg, isNot(contains('>b&c')));
    });

    test('uses dashed lines for IDEF1X optional relationships', () {
      final state = ErDiagramState(
        connectionId: 'c',
        schema: 's',
        tables: [
          ErTableNode(
            schema: 's',
            tableName: 'a',
            columns: const [
              ErColumn(name: 'id', dataType: 'int4', isPrimaryKey: true),
            ],
            position: const Offset(50, 50),
          ),
          ErTableNode(
            schema: 's',
            tableName: 'b',
            columns: const [
              ErColumn(
                  name: 'a_id', dataType: 'int4', isForeignKey: true),
            ],
            position: const Offset(350, 50),
          ),
        ],
        relationships: const [
          ErRelationship(
            fromTable: 'b',
            fromColumn: 'a_id',
            toTable: 'a',
            toColumn: 'id',
            cardinality: ErCardinality.manyToOne,
            isOptional: true,
          ),
        ],
        notation: ErNotation.idef1x,
      );
      final svg = service.exportSvg(state);
      expect(svg, contains('stroke-dasharray'));
    });
  });

  // ---------------------------------------------------------------------------
  // PNG Export
  // ---------------------------------------------------------------------------
  group('exportPng', () {
    test('returns empty bytes for empty diagram', () async {
      const empty = ErDiagramState(
        connectionId: 'c',
        schema: 's',
        tables: [],
        relationships: [],
      );
      final bytes = await service.exportPng(empty);
      expect(bytes.isEmpty, true);
    });

    test('returns non-empty PNG bytes for valid diagram', () async {
      final bytes = await service.exportPng(_testState());
      expect(bytes.isNotEmpty, true);
      // PNG magic bytes: 137 80 78 71.
      expect(bytes[0], 137);
      expect(bytes[1], 80);
      expect(bytes[2], 78);
      expect(bytes[3], 71);
    });
  });
}
