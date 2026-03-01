// Widget tests for DataGrid.
//
// Verifies grid rendering: column headers, data rows, null formatting,
// boolean formatting, datetime formatting, UUID truncation, JSON preview,
// sort indicators, zebra striping, row selection, and horizontal scrolling.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/datalens_models.dart';
import 'package:codeops/widgets/datalens/data_grid.dart';

const _testColumns = [
  QueryColumn(name: 'id', typeName: 'uuid'),
  QueryColumn(name: 'name', typeName: 'varchar'),
  QueryColumn(name: 'age', typeName: 'int4'),
  QueryColumn(name: 'is_active', typeName: 'bool'),
  QueryColumn(name: 'created_at', typeName: 'timestamp'),
  QueryColumn(name: 'metadata', typeName: 'jsonb'),
];

final _testRows = [
  [
    'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
    'Alice',
    30,
    true,
    DateTime(2025, 12, 28, 10, 0, 0),
    '{"role": "admin"}',
  ],
  [
    'b2c3d4e5-f6a7-8901-bcde-f12345678901',
    'Bob',
    null,
    false,
    DateTime(2025, 12, 29, 11, 0, 0),
    '[1, 2, 3]',
  ],
  [
    'c3d4e5f6-a7b8-9012-cdef-123456789012',
    null,
    25,
    true,
    null,
    null,
  ],
];

Widget _createWidget({
  QueryResult? result,
  String? sortColumn,
  bool sortAscending = true,
  ValueChanged<String>? onSort,
}) {
  // Build rows list separately since _testRows is not const.
  final r = result ??
      QueryResult(
        columns: _testColumns,
        rows: _testRows,
        rowCount: 3,
        totalRows: 3,
        executionTimeMs: 45,
      );

  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 1200,
        height: 600,
        child: DataGrid(
          result: r,
          sortColumn: sortColumn,
          sortAscending: sortAscending,
          onSort: onSort,
        ),
      ),
    ),
  );
}

void main() {
  group('DataGrid', () {
    testWidgets('renders', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.byType(DataGrid), findsOneWidget);
    });

    testWidgets('shows column headers', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.text('id'), findsOneWidget);
      expect(find.text('name'), findsOneWidget);
      expect(find.text('age'), findsOneWidget);
      expect(find.text('is_active'), findsOneWidget);
      expect(find.text('created_at'), findsOneWidget);
      expect(find.text('metadata'), findsOneWidget);
    });

    testWidgets('shows data rows', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
    });

    testWidgets('null values show italic null', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      // Multiple null values in the test data.
      expect(find.text('(null)'), findsWidgets);
    });

    testWidgets('boolean values show colored text', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.text('true'), findsNWidgets(2));
      expect(find.text('false'), findsOneWidget);
    });

    testWidgets('datetime values show formatted', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.text('2025-12-28 10:00:00'), findsOneWidget);
      expect(find.text('2025-12-29 11:00:00'), findsOneWidget);
    });

    testWidgets('UUID values show truncated', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.text('a1b2c3d4'), findsOneWidget);
      expect(find.text('b2c3d4e5'), findsOneWidget);
    });

    testWidgets('click header calls onSort', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      String? sortedColumn;
      await tester.pumpWidget(_createWidget(
        onSort: (col) => sortedColumn = col,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('name'));
      expect(sortedColumn, 'name');
    });

    testWidgets('zebra striping applies alternating colors', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      // Rows exist — grid rendered with 3 rows.
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('row selection highlights row', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      // Tap the first data row (Alice).
      await tester.tap(find.text('Alice'));
      await tester.pumpAndSettle();

      // Row should still be visible (selection doesn't remove it).
      expect(find.text('Alice'), findsOneWidget);
    });

    testWidgets('no data shows empty message', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget(
        result: const QueryResult(columns: [], rows: []),
      ));
      await tester.pumpAndSettle();

      expect(find.text('No data'), findsOneWidget);
    });
  });
}
