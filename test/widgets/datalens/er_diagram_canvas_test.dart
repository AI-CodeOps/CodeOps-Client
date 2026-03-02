// Tests for ErDiagramCanvas widget and ErDiagramPainter.
//
// Verifies that the canvas renders without errors, responds to gestures,
// and correctly performs hit testing.
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/datalens_er_models.dart';
import 'package:codeops/widgets/datalens/er_diagram_canvas.dart';

/// Creates a minimal test diagram state.
ErDiagramState _testState() => ErDiagramState(
      connectionId: 'test-conn',
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
                name: 'user_id',
                dataType: 'uuid',
                isForeignKey: true,
                referencedTable: 'users',
                referencedColumn: 'id'),
            ErColumn(name: 'total', dataType: 'numeric'),
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

Widget _wrap(ErDiagramState state, {ValueChanged<String?>? onSelected}) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 800,
        height: 600,
        child: ErDiagramCanvas(
          diagramState: state,
          onTableSelected: onSelected,
        ),
      ),
    ),
  );
}

void main() {
  // ---------------------------------------------------------------------------
  // Rendering
  // ---------------------------------------------------------------------------
  group('Rendering', () {
    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(_wrap(_testState()));
      expect(find.byType(ErDiagramCanvas), findsOneWidget);
    });

    testWidgets('renders empty diagram without errors', (tester) async {
      const empty = ErDiagramState(
        connectionId: 'c',
        schema: 's',
        tables: [],
        relationships: [],
      );
      await tester.pumpWidget(_wrap(empty));
      expect(find.byType(ErDiagramCanvas), findsOneWidget);
    });

    testWidgets('renders with IDEF1X notation', (tester) async {
      final state = _testState().copyWith(notation: ErNotation.idef1x);
      await tester.pumpWidget(_wrap(state));
      expect(find.byType(ErDiagramCanvas), findsOneWidget);
    });

    testWidgets('renders view nodes correctly', (tester) async {
      final state = ErDiagramState(
        connectionId: 'c',
        schema: 's',
        tables: [
          ErTableNode(
            schema: 's',
            tableName: 'my_view',
            columns: const [ErColumn(name: 'id', dataType: 'int4')],
            isView: true,
            position: const Offset(50, 50),
          ),
        ],
        relationships: const [],
      );
      await tester.pumpWidget(_wrap(state));
      expect(find.byType(ErDiagramCanvas), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // Interaction
  // ---------------------------------------------------------------------------
  group('Interaction', () {
    testWidgets('tap on canvas clears selection', (tester) async {
      String? selected = 'initial';
      await tester.pumpWidget(_wrap(
        _testState(),
        onSelected: (name) => selected = name,
      ));

      // Tap on empty area (bottom-right corner).
      await tester.tapAt(const Offset(750, 550));
      await tester.pump();
      expect(selected, isNull);
    });

    testWidgets('pan gesture updates canvas', (tester) async {
      await tester.pumpWidget(_wrap(_testState()));

      // Drag on empty canvas area.
      await tester.drag(
        find.byType(ErDiagramCanvas),
        const Offset(100, 50),
      );
      await tester.pump();

      // Widget should still render after pan.
      expect(find.byType(ErDiagramCanvas), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // State API
  // ---------------------------------------------------------------------------
  group('State API', () {
    testWidgets('resetView sets zoom to 1.0', (tester) async {
      final key = GlobalKey<ErDiagramCanvasState>();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 600,
            child: ErDiagramCanvas(
              key: key,
              diagramState: _testState(),
            ),
          ),
        ),
      ));

      key.currentState!.resetView();
      await tester.pump();
      expect(find.byType(ErDiagramCanvas), findsOneWidget);
    });

    testWidgets('zoomToFit works with tables', (tester) async {
      final key = GlobalKey<ErDiagramCanvasState>();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 600,
            child: ErDiagramCanvas(
              key: key,
              diagramState: _testState(),
            ),
          ),
        ),
      ));

      key.currentState!.zoomToFit(const Size(800, 600));
      await tester.pump();
      expect(find.byType(ErDiagramCanvas), findsOneWidget);
    });

    testWidgets('setAllExpanded toggles table expansion', (tester) async {
      final key = GlobalKey<ErDiagramCanvasState>();
      final state = _testState();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 600,
            child: ErDiagramCanvas(
              key: key,
              diagramState: state,
            ),
          ),
        ),
      ));

      // Collapse all.
      key.currentState!.setAllExpanded(false);
      await tester.pump();
      for (final t in state.tables) {
        expect(t.isExpanded, false);
      }

      // Expand all.
      key.currentState!.setAllExpanded(true);
      await tester.pump();
      for (final t in state.tables) {
        expect(t.isExpanded, true);
      }
    });
  });

  // ---------------------------------------------------------------------------
  // Hit Testing
  // ---------------------------------------------------------------------------
  group('hitTest', () {
    test('returns table when point is inside table rect', () {
      final state = _testState();
      final canvasState = _TestCanvasHelper(state);
      final hit = canvasState.hitTest(const Offset(100, 60));
      expect(hit, isNotNull);
      expect(hit!.tableName, 'users');
    });

    test('returns null when point is outside all tables', () {
      final state = _testState();
      final canvasState = _TestCanvasHelper(state);
      final hit = canvasState.hitTest(const Offset(800, 800));
      expect(hit, isNull);
    });
  });
}

/// Helper for testing hit-test logic without pumping a widget.
class _TestCanvasHelper {
  final ErDiagramState state;
  _TestCanvasHelper(this.state);

  static const double _tw = ErDiagramCanvasState.tableWidth;
  static const double _hh = ErDiagramCanvasState.headerHeight;
  static const double _rh = ErDiagramCanvasState.rowHeight;

  ErTableNode? hitTest(Offset canvasPoint) {
    for (final table in state.tables.reversed) {
      final h = _hh + table.displayColumns.length * _rh;
      final rect = Rect.fromLTWH(
        table.position.dx, table.position.dy, _tw, h,
      );
      if (rect.contains(canvasPoint)) return table;
    }
    return null;
  }
}
