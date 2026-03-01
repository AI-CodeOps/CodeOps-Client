// Widget tests for SqlResultsPanel.
//
// Verifies panel rendering, tab bar with Results/Messages/Explain,
// grid display with results, DML message display, error display,
// status bar row count and execution time.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/datalens_enums.dart';
import 'package:codeops/models/datalens_models.dart';
import 'package:codeops/widgets/datalens/data_grid.dart';
import 'package:codeops/widgets/datalens/sql_results_panel.dart';

const _selectResult = QueryResult(
  columns: [
    QueryColumn(name: 'id', typeName: 'int4'),
    QueryColumn(name: 'name', typeName: 'varchar'),
  ],
  rows: [
    [1, 'Alice'],
    [2, 'Bob'],
    [3, 'Charlie'],
  ],
  rowCount: 3,
  totalRows: 3,
  executionTimeMs: 45,
  status: QueryStatus.completed,
  executedSql: 'SELECT id, name FROM users',
);

const _dmlResult = QueryResult(
  rowCount: 3,
  executionTimeMs: 12,
  status: QueryStatus.completed,
  executedSql: 'INSERT INTO users (name) VALUES (\'Alice\')',
);

const _errorResult = QueryResult(
  status: QueryStatus.failed,
  error: 'relation "nonexistent" does not exist',
  executionTimeMs: 5,
  executedSql: 'SELECT * FROM nonexistent',
);

Widget _createWidget({
  QueryResult? result,
  String? explainOutput,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 1200,
        height: 600,
        child: SqlResultsPanel(
          result: result,
          explainOutput: explainOutput,
        ),
      ),
    ),
  );
}

void main() {
  group('SqlResultsPanel', () {
    testWidgets('renders', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.byType(SqlResultsPanel), findsOneWidget);
    });

    testWidgets('shows Results tab', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Results'), findsOneWidget);
    });

    testWidgets('shows Messages tab', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Messages'), findsOneWidget);
    });

    testWidgets('shows Explain tab', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Explain'), findsOneWidget);
    });

    testWidgets('shows data grid when result has columns', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget(result: _selectResult));
      await tester.pumpAndSettle();

      expect(find.byType(DataGrid), findsOneWidget);
    });

    testWidgets('DML result shows message in Messages tab', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget(result: _dmlResult));
      await tester.pumpAndSettle();

      // Switch to Messages tab.
      await tester.tap(find.text('Messages'));
      await tester.pumpAndSettle();

      expect(find.textContaining('INSERT 0'), findsOneWidget);
    });

    testWidgets('error result shows red message in Messages tab',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget(result: _errorResult));
      await tester.pumpAndSettle();

      // Switch to Messages tab.
      await tester.tap(find.text('Messages'));
      await tester.pumpAndSettle();

      expect(find.textContaining('does not exist'), findsOneWidget);
    });

    testWidgets('status bar shows row count', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget(result: _selectResult));
      await tester.pumpAndSettle();

      expect(find.text('3 rows'), findsOneWidget);
    });

    testWidgets('status bar shows execution time', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget(result: _selectResult));
      await tester.pumpAndSettle();

      expect(find.text('45ms'), findsOneWidget);
    });
  });
}
