// Widget tests for ForeignKeysTab.
//
// Verifies FK grid rendering: headers, FK rows, referenced schema/table,
// on update/delete actions, empty state, and column sorting.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/datalens_models.dart';
import 'package:codeops/providers/datalens_providers.dart';
import 'package:codeops/widgets/datalens/foreign_keys_tab.dart';

const _testForeignKeys = [
  ForeignKeyInfo(
    constraintName: 'users_team_id_fkey',
    columns: ['team_id'],
    referencedSchema: 'public',
    referencedTable: 'teams',
    referencedColumns: ['id'],
    onUpdate: 'NO ACTION',
    onDelete: 'CASCADE',
  ),
  ForeignKeyInfo(
    constraintName: 'users_org_id_fkey',
    columns: ['org_id'],
    referencedSchema: 'public',
    referencedTable: 'organizations',
    referencedColumns: ['id'],
    onUpdate: 'NO ACTION',
    onDelete: 'SET NULL',
  ),
];

Widget _createWidget({
  List<ForeignKeyInfo> foreignKeys = _testForeignKeys,
}) {
  return ProviderScope(
    overrides: [
      datalensForeignKeysProvider.overrideWith(
        (ref) => Future.value(foreignKeys),
      ),
    ],
    child: const MaterialApp(
      home: Scaffold(body: ForeignKeysTab()),
    ),
  );
}

void main() {
  group('ForeignKeysTab', () {
    testWidgets('renders', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.byType(ForeignKeysTab), findsOneWidget);
    });

    testWidgets('shows column headers', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Constraint Name'), findsOneWidget);
      expect(find.text('Columns'), findsOneWidget);
      expect(find.text('Ref Schema'), findsOneWidget);
      expect(find.text('Ref Table'), findsOneWidget);
      expect(find.text('Ref Columns'), findsOneWidget);
      expect(find.text('On Update'), findsOneWidget);
      expect(find.text('On Delete'), findsOneWidget);
    });

    testWidgets('shows all FK constraint names', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.text('users_team_id_fkey'), findsOneWidget);
      expect(find.text('users_org_id_fkey'), findsOneWidget);
    });

    testWidgets('shows referenced tables', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.text('teams'), findsOneWidget);
      expect(find.text('organizations'), findsOneWidget);
    });

    testWidgets('shows on delete actions', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.text('CASCADE'), findsOneWidget);
      expect(find.text('SET NULL'), findsOneWidget);
    });

    testWidgets('shows empty state when no foreign keys', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget(foreignKeys: const []));
      await tester.pumpAndSettle();

      expect(find.text('No foreign keys found'), findsOneWidget);
    });

    testWidgets('clicking header changes sort', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_upward), findsOneWidget);

      await tester.tap(find.text('Constraint Name'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
    });
  });
}
