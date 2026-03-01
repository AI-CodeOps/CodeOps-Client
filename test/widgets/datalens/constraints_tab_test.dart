// Widget tests for ConstraintsTab.
//
// Verifies constraint grid rendering: headers, constraint rows, type display,
// columns, expression, referenced table, on update/delete, deferrable/deferred
// indicators, empty state, and column sorting.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/datalens_enums.dart';
import 'package:codeops/models/datalens_models.dart';
import 'package:codeops/providers/datalens_providers.dart';
import 'package:codeops/widgets/datalens/constraints_tab.dart';

const _testConstraints = [
  ConstraintInfo(
    constraintName: 'users_pkey',
    constraintType: ConstraintType.primaryKey,
    columns: ['id'],
  ),
  ConstraintInfo(
    constraintName: 'users_email_unique',
    constraintType: ConstraintType.unique,
    columns: ['email'],
  ),
  ConstraintInfo(
    constraintName: 'users_team_id_fkey',
    constraintType: ConstraintType.foreignKey,
    columns: ['team_id'],
    referencedTable: 'teams',
    referencedColumns: ['id'],
    onUpdate: 'NO ACTION',
    onDelete: 'CASCADE',
  ),
  ConstraintInfo(
    constraintName: 'users_age_check',
    constraintType: ConstraintType.check,
    columns: ['age'],
    checkExpression: 'age > 0',
    isDeferrable: true,
    isDeferred: true,
  ),
];

Widget _createWidget({
  List<ConstraintInfo> constraints = _testConstraints,
}) {
  return ProviderScope(
    overrides: [
      datalensConstraintsProvider.overrideWith(
        (ref) => Future.value(constraints),
      ),
    ],
    child: const MaterialApp(
      home: Scaffold(body: ConstraintsTab()),
    ),
  );
}

void main() {
  group('ConstraintsTab', () {
    testWidgets('renders', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.byType(ConstraintsTab), findsOneWidget);
    });

    testWidgets('shows column headers', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Constraint Name'), findsOneWidget);
      expect(find.text('Type'), findsOneWidget);
      expect(find.text('Columns'), findsOneWidget);
      expect(find.text('Expression'), findsOneWidget);
      expect(find.text('Ref Table'), findsOneWidget);
      expect(find.text('On Update'), findsOneWidget);
      expect(find.text('On Delete'), findsOneWidget);
      expect(find.text('Deferrable'), findsOneWidget);
      expect(find.text('Deferred'), findsOneWidget);
    });

    testWidgets('shows all constraint names', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.text('users_pkey'), findsOneWidget);
      expect(find.text('users_email_unique'), findsOneWidget);
      expect(find.text('users_team_id_fkey'), findsOneWidget);
      expect(find.text('users_age_check'), findsOneWidget);
    });

    testWidgets('shows constraint type', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Primary Key'), findsOneWidget);
      expect(find.text('Unique'), findsOneWidget);
      expect(find.text('Foreign Key'), findsOneWidget);
      expect(find.text('Check'), findsOneWidget);
    });

    testWidgets('shows referenced table for FK', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.text('teams'), findsOneWidget);
    });

    testWidgets('shows check expression', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.text('age > 0'), findsOneWidget);
    });

    testWidgets('shows on update/delete actions', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.text('NO ACTION'), findsOneWidget);
      expect(find.text('CASCADE'), findsOneWidget);
    });

    testWidgets('shows deferrable and deferred check icons', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      // The check constraint has both deferrable and deferred = true.
      expect(find.byIcon(Icons.check), findsWidgets);
    });

    testWidgets('shows empty state when no constraints', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget(constraints: const []));
      await tester.pumpAndSettle();

      expect(find.text('No constraints found'), findsOneWidget);
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
