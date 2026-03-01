// Widget tests for DependenciesTab.
//
// Verifies dependencies grid rendering: headers, dependency rows,
// direction indicators (outgoing/incoming), source/target table/column,
// constraint name, empty state, and column sorting.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/datalens_models.dart';
import 'package:codeops/providers/datalens_providers.dart';
import 'package:codeops/widgets/datalens/dependencies_tab.dart';

const _testDependencies = [
  TableDependency(
    sourceTable: 'users',
    sourceColumn: 'team_id',
    targetTable: 'teams',
    targetColumn: 'id',
    constraintName: 'users_team_id_fkey',
    direction: 'outgoing',
  ),
  TableDependency(
    sourceTable: 'orders',
    sourceColumn: 'user_id',
    targetTable: 'users',
    targetColumn: 'id',
    constraintName: 'orders_user_id_fkey',
    direction: 'incoming',
  ),
];

Widget _createWidget({
  List<TableDependency> dependencies = _testDependencies,
}) {
  return ProviderScope(
    overrides: [
      datalensDependenciesProvider.overrideWith(
        (ref) => Future.value(dependencies),
      ),
    ],
    child: const MaterialApp(
      home: Scaffold(body: DependenciesTab()),
    ),
  );
}

void main() {
  group('DependenciesTab', () {
    testWidgets('renders', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.byType(DependenciesTab), findsOneWidget);
    });

    testWidgets('shows column headers', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Direction'), findsOneWidget);
      expect(find.text('Source Table'), findsOneWidget);
      expect(find.text('Source Column'), findsOneWidget);
      expect(find.text('Target Table'), findsOneWidget);
      expect(find.text('Target Column'), findsOneWidget);
      expect(find.text('Constraint'), findsOneWidget);
    });

    testWidgets('shows outgoing direction indicator', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Out'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    });

    testWidgets('shows incoming direction indicator', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.text('In'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('shows source and target tables', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      // 'users' appears twice: as source table in row 1, target table in row 2.
      expect(find.text('users'), findsNWidgets(2));
      expect(find.text('teams'), findsOneWidget);
      expect(find.text('orders'), findsOneWidget);
    });

    testWidgets('shows constraint names', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.text('users_team_id_fkey'), findsOneWidget);
      expect(find.text('orders_user_id_fkey'), findsOneWidget);
    });

    testWidgets('shows empty state when no dependencies', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget(dependencies: const []));
      await tester.pumpAndSettle();

      expect(find.text('No dependencies found'), findsOneWidget);
    });

    testWidgets('clicking header changes sort', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_upward), findsOneWidget);

      await tester.tap(find.text('Direction'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
    });
  });
}
