// Widget tests for ColumnsTab.
//
// Verifies column grid rendering: headers, column rows, data types,
// ordinal positions, not-null indicators, defaults, PK/FK icons,
// identity indicators, and column sorting.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/datalens_enums.dart';
import 'package:codeops/models/datalens_models.dart';
import 'package:codeops/providers/datalens_providers.dart';
import 'package:codeops/widgets/datalens/columns_tab.dart';

const _testColumns = [
  ColumnInfo(
    columnName: 'id',
    ordinalPosition: 1,
    dataType: 'uuid',
    udtName: 'uuid',
    isNullable: false,
    isIdentity: true,
    category: ColumnCategory.primaryKey,
  ),
  ColumnInfo(
    columnName: 'name',
    ordinalPosition: 2,
    dataType: 'character varying(255)',
    udtName: 'varchar',
    isNullable: false,
    columnDefault: "''::character varying",
    collation: 'en_US.utf8',
    comment: 'User full name',
    category: ColumnCategory.regular,
  ),
  ColumnInfo(
    columnName: 'team_id',
    ordinalPosition: 3,
    dataType: 'uuid',
    udtName: 'uuid',
    isNullable: true,
    category: ColumnCategory.foreignKey,
  ),
  ColumnInfo(
    columnName: 'created_at',
    ordinalPosition: 4,
    dataType: 'timestamp(6) without time zone',
    udtName: 'timestamp',
    isNullable: true,
    category: ColumnCategory.regular,
  ),
  ColumnInfo(
    columnName: 'is_active',
    ordinalPosition: 5,
    dataType: 'boolean',
    udtName: 'bool',
    isNullable: false,
    columnDefault: 'true',
    category: ColumnCategory.regular,
  ),
];

Widget _createWidget({
  List<ColumnInfo> columns = _testColumns,
}) {
  return ProviderScope(
    overrides: [
      datalensColumnsProvider.overrideWith(
        (ref) => Future.value(columns),
      ),
    ],
    child: const MaterialApp(
      home: Scaffold(body: ColumnsTab()),
    ),
  );
}

void main() {
  group('ColumnsTab', () {
    testWidgets('renders', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.byType(ColumnsTab), findsOneWidget);
    });

    testWidgets('shows column headers', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Column Name'), findsOneWidget);
      expect(find.text('#'), findsOneWidget);
      expect(find.text('Data type'), findsOneWidget);
      expect(find.text('Identity'), findsOneWidget);
      expect(find.text('Collation'), findsOneWidget);
      expect(find.text('Not Null'), findsOneWidget);
      expect(find.text('Default'), findsOneWidget);
      expect(find.text('Comment'), findsOneWidget);
    });

    testWidgets('shows all column names', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.text('id'), findsOneWidget);
      expect(find.text('name'), findsOneWidget);
      expect(find.text('team_id'), findsOneWidget);
      expect(find.text('created_at'), findsOneWidget);
      expect(find.text('is_active'), findsOneWidget);
    });

    testWidgets('shows column name cell', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.text('name'), findsOneWidget);
    });

    testWidgets('shows ordinal position', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      // Position 1 through 5.
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('shows data type', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.text('uuid'), findsWidgets);
      expect(find.text('character varying(255)'), findsOneWidget);
      expect(find.text('boolean'), findsOneWidget);
    });

    testWidgets('shows not null indicator', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      // 3 columns are NOT NULL (id, name, is_active) → 3 check icons for not-null
      // Plus 1 identity check icon for id
      // Check icons appear for not-null and identity.
      expect(find.byIcon(Icons.check), findsWidgets);
    });

    testWidgets('shows default value', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.text("''::character varying"), findsOneWidget);
      expect(find.text('true'), findsOneWidget);
    });

    testWidgets('PK column shows key icon', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.vpn_key), findsOneWidget);
    });

    testWidgets('FK column shows link icon', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.link), findsOneWidget);
    });

    testWidgets('identity column shows check indicator', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      // The identity check icon (green) exists for the "id" column.
      expect(find.byIcon(Icons.check), findsWidgets);
    });

    testWidgets('clicking header changes sort', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      // Default sort is by Column Name (index 1) ascending.
      expect(find.byIcon(Icons.arrow_upward), findsOneWidget);

      // Click "Column Name" header again to toggle to descending.
      await tester.tap(find.text('Column Name'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
    });

    testWidgets('shows comment text', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.text('User full name'), findsOneWidget);
    });
  });
}
