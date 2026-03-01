// Widget tests for DataExportDialog.
//
// Verifies dialog rendering, format options, and scope options.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/datalens_models.dart';
import 'package:codeops/widgets/datalens/data_export_dialog.dart';

const _testResult = QueryResult(
  columns: [
    QueryColumn(name: 'id', typeName: 'uuid'),
    QueryColumn(name: 'name', typeName: 'varchar'),
  ],
  rows: [
    ['abc-123', 'Alice'],
    ['def-456', 'Bob'],
  ],
  rowCount: 2,
  totalRows: 2,
);

Widget _createWidget() {
  return MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => showDialog(
            context: context,
            builder: (_) => const DataExportDialog(
              result: _testResult,
              tableName: 'users',
            ),
          ),
          child: const Text('Open'),
        ),
      ),
    ),
  );
}

void main() {
  group('DataExportDialog', () {
    testWidgets('renders', (tester) async {
      await tester.pumpWidget(_createWidget());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Export Data'), findsOneWidget);
    });

    testWidgets('shows format options', (tester) async {
      await tester.pumpWidget(_createWidget());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('CSV'), findsOneWidget);
      expect(find.text('JSON'), findsOneWidget);
      expect(find.text('SQL INSERT'), findsOneWidget);
    });

    testWidgets('shows scope options', (tester) async {
      await tester.pumpWidget(_createWidget());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Current Page'), findsOneWidget);
      expect(find.text('All Rows'), findsOneWidget);
    });
  });
}
