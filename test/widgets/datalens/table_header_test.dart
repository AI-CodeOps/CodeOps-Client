// Widget tests for TableHeader.
//
// Verifies that table metadata fields are rendered correctly:
// table name, comment, tablespace, owner, object type, RLS, partitioning.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/datalens_enums.dart';
import 'package:codeops/models/datalens_models.dart';
import 'package:codeops/widgets/datalens/table_header.dart';

Widget _createWidget({TableInfo? table}) {
  return MaterialApp(
    home: Scaffold(
      body: TableHeader(
        table: table ??
            const TableInfo(
              tableName: 'users',
              owner: 'codeops',
              tablespace: 'pg_default',
              objectType: ObjectType.table,
              hasRls: false,
              isPartitioned: false,
            ),
      ),
    ),
  );
}

void main() {
  group('TableHeader', () {
    testWidgets('renders', (tester) async {
      await tester.pumpWidget(_createWidget());

      expect(find.byType(TableHeader), findsOneWidget);
    });

    testWidgets('shows table name', (tester) async {
      await tester.pumpWidget(_createWidget());

      expect(find.text('Table Name'), findsOneWidget);
      expect(find.text('users'), findsOneWidget);
    });

    testWidgets('shows owner', (tester) async {
      await tester.pumpWidget(_createWidget());

      expect(find.text('Owner'), findsOneWidget);
      expect(find.text('codeops'), findsOneWidget);
    });

    testWidgets('shows tablespace', (tester) async {
      await tester.pumpWidget(_createWidget());

      expect(find.text('Tablespace'), findsOneWidget);
      expect(find.text('pg_default'), findsOneWidget);
    });

    testWidgets('shows RLS checkbox', (tester) async {
      await tester.pumpWidget(_createWidget());

      expect(find.text('Has Row-Level Security'), findsOneWidget);
      expect(find.byType(Checkbox), findsWidgets);
    });

    testWidgets('shows comment when present', (tester) async {
      await tester.pumpWidget(_createWidget(
        table: const TableInfo(
          tableName: 'orders',
          tableComment: 'Customer order records',
          owner: 'admin',
        ),
      ));

      expect(find.text('Comment'), findsOneWidget);
      expect(find.text('Customer order records'), findsOneWidget);
    });

    testWidgets('shows object type', (tester) async {
      await tester.pumpWidget(_createWidget(
        table: const TableInfo(
          tableName: 'my_view',
          objectType: ObjectType.view,
        ),
      ));

      expect(find.text('Object Type'), findsOneWidget);
      expect(find.text('View'), findsOneWidget);
    });
  });
}
