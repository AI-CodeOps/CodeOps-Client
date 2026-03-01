// Widget tests for DatabaseNavigatorTree.
//
// Verifies tree structure, schema rendering, expand/collapse, object folders,
// table selection, search filtering, refresh, and empty states.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/datalens_enums.dart';
import 'package:codeops/models/datalens_models.dart';
import 'package:codeops/providers/datalens_providers.dart';
import 'package:codeops/widgets/datalens/database_navigator_tree.dart';

/// Test schemas.
const _schemas = [
  SchemaInfo(name: 'public', tableCount: 3, viewCount: 1, sequenceCount: 2),
  SchemaInfo(name: 'analytics', tableCount: 1),
];

/// Test tables for the "public" schema.
const _publicTables = [
  TableInfo(
    tableName: 'users',
    objectType: ObjectType.table,
    rowEstimate: 1500,
  ),
  TableInfo(
    tableName: 'orders',
    objectType: ObjectType.table,
    rowEstimate: 42000,
  ),
  TableInfo(
    tableName: 'products',
    objectType: ObjectType.table,
    rowEstimate: 200,
  ),
  TableInfo(
    tableName: 'active_users',
    objectType: ObjectType.view,
  ),
];

/// Test sequences for the "public" schema.
const _publicSequences = [
  SequenceInfo(sequenceName: 'users_id_seq', dataType: 'bigint'),
  SequenceInfo(sequenceName: 'orders_id_seq', dataType: 'bigint'),
];

Widget _createWidget({
  String? selectedConnectionId = 'c1',
  String? selectedSchema,
  List<SchemaInfo> schemas = _schemas,
  List<TableInfo> tables = const [],
  List<SequenceInfo> sequences = const [],
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: [
      selectedConnectionIdProvider.overrideWith((ref) => selectedConnectionId),
      selectedSchemaProvider.overrideWith((ref) => selectedSchema),
      datalensSchemasProvider.overrideWith(
        (ref) => Future.value(schemas),
      ),
      datalensTablesProvider.overrideWith(
        (ref) => Future.value(tables),
      ),
      datalensSequencesProvider.overrideWith(
        (ref) => Future.value(sequences),
      ),
      ...overrides,
    ],
    child: const MaterialApp(
      home: Scaffold(body: DatabaseNavigatorTree()),
    ),
  );
}

void main() {
  group('DatabaseNavigatorTree', () {
    testWidgets('shows header with title', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Database Navigator'), findsOneWidget);
    });

    testWidgets('shows refresh button', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('shows search bar', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('shows "No schemas found" when empty', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget(schemas: const []));
      await tester.pumpAndSettle();

      expect(find.text('No schemas found'), findsOneWidget);
    });

    testWidgets('renders schema names', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.text('public'), findsOneWidget);
      expect(find.text('analytics'), findsOneWidget);
    });

    testWidgets('shows object folders when schema is expanded', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget(
        selectedSchema: 'public',
        tables: _publicTables,
        sequences: _publicSequences,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Tables'), findsOneWidget);
      expect(find.text('Views'), findsOneWidget);
      expect(find.text('Materialized Views'), findsOneWidget);
      expect(find.text('Sequences'), findsOneWidget);
    });

    testWidgets('shows table count badge on Tables folder', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget(
        selectedSchema: 'public',
        tables: _publicTables,
        sequences: _publicSequences,
      ));
      await tester.pumpAndSettle();

      // Schema has tableCount: 3 — displayed as badge.
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('shows tables under Tables folder', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget(
        selectedSchema: 'public',
        tables: _publicTables,
        sequences: _publicSequences,
      ));
      await tester.pumpAndSettle();

      expect(find.text('users'), findsOneWidget);
      expect(find.text('orders'), findsOneWidget);
      expect(find.text('products'), findsOneWidget);
    });

    testWidgets('shows views under Views folder', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget(
        selectedSchema: 'public',
        tables: _publicTables,
        sequences: _publicSequences,
      ));
      await tester.pumpAndSettle();

      expect(find.text('active_users'), findsOneWidget);
    });

    testWidgets('shows sequences under Sequences folder', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget(
        selectedSchema: 'public',
        tables: _publicTables,
        sequences: _publicSequences,
      ));
      await tester.pumpAndSettle();

      expect(find.text('users_id_seq'), findsOneWidget);
      expect(find.text('orders_id_seq'), findsOneWidget);
    });

    testWidgets('shows row estimate on table nodes', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget(
        selectedSchema: 'public',
        tables: _publicTables,
        sequences: _publicSequences,
      ));
      await tester.pumpAndSettle();

      // 42000 → ~42.0k
      expect(find.text('~42.0k'), findsOneWidget);
      // 1500 → ~1.5k
      expect(find.text('~1.5k'), findsOneWidget);
      // 200 → ~200
      expect(find.text('~200'), findsOneWidget);
    });

    testWidgets('search filters schemas by name', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      // Both schemas visible initially.
      expect(find.text('public'), findsOneWidget);
      expect(find.text('analytics'), findsOneWidget);

      // Type in the search bar to filter.
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'pub');
      await tester.pumpAndSettle(const Duration(milliseconds: 400));

      expect(find.text('public'), findsOneWidget);
      expect(find.text('analytics'), findsNothing);
    });

    testWidgets('shows "No matching objects" when search has no results',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'zzzzzzzzz');
      await tester.pumpAndSettle(const Duration(milliseconds: 400));

      expect(find.text('No matching objects'), findsOneWidget);
    });
  });
}
