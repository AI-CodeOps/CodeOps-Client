// Widget tests for IndexesTab.
//
// Verifies index grid rendering: headers, index rows, type display,
// columns, unique/primary flags, size, condition, valid indicator,
// empty state, and column sorting.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/datalens_enums.dart';
import 'package:codeops/models/datalens_models.dart';
import 'package:codeops/providers/datalens_providers.dart';
import 'package:codeops/widgets/datalens/indexes_tab.dart';

const _testIndexes = [
  IndexInfo(
    indexName: 'users_pkey',
    indexType: IndexType.btree,
    columns: ['id'],
    isUnique: true,
    isPrimary: true,
    indexSize: '16 kB',
    isValid: true,
  ),
  IndexInfo(
    indexName: 'users_email_idx',
    indexType: IndexType.btree,
    columns: ['email'],
    isUnique: true,
    isPrimary: false,
    indexSize: '32 kB',
    isValid: true,
  ),
  IndexInfo(
    indexName: 'users_name_gin_idx',
    indexType: IndexType.gin,
    columns: ['name'],
    isUnique: false,
    isPrimary: false,
    indexSize: '24 kB',
    condition: "name IS NOT NULL",
    isValid: true,
  ),
];

Widget _createWidget({
  List<IndexInfo> indexes = _testIndexes,
}) {
  return ProviderScope(
    overrides: [
      datalensIndexesProvider.overrideWith(
        (ref) => Future.value(indexes),
      ),
    ],
    child: const MaterialApp(
      home: Scaffold(body: IndexesTab()),
    ),
  );
}

void main() {
  group('IndexesTab', () {
    testWidgets('renders', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.byType(IndexesTab), findsOneWidget);
    });

    testWidgets('shows column headers', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Index Name'), findsOneWidget);
      expect(find.text('Type'), findsOneWidget);
      expect(find.text('Columns'), findsOneWidget);
      expect(find.text('Unique'), findsOneWidget);
      expect(find.text('Primary'), findsOneWidget);
      expect(find.text('Size'), findsOneWidget);
      expect(find.text('Condition'), findsOneWidget);
      expect(find.text('Tablespace'), findsOneWidget);
      expect(find.text('Valid'), findsOneWidget);
    });

    testWidgets('shows all index names', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.text('users_pkey'), findsOneWidget);
      expect(find.text('users_email_idx'), findsOneWidget);
      expect(find.text('users_name_gin_idx'), findsOneWidget);
    });

    testWidgets('shows index type', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.text('B-Tree'), findsNWidgets(2));
      expect(find.text('GIN'), findsOneWidget);
    });

    testWidgets('shows unique and primary check icons', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      // users_pkey: unique + primary + valid = 3 checks
      // users_email_idx: unique + valid = 2 checks
      // users_name_gin_idx: valid = 1 check
      expect(find.byIcon(Icons.check), findsNWidgets(6));
    });

    testWidgets('shows index size', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.text('16 kB'), findsOneWidget);
      expect(find.text('32 kB'), findsOneWidget);
    });

    testWidgets('shows partial index condition', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.text('name IS NOT NULL'), findsOneWidget);
    });

    testWidgets('shows empty state when no indexes', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget(indexes: const []));
      await tester.pumpAndSettle();

      expect(find.text('No indexes found'), findsOneWidget);
    });

    testWidgets('clicking header changes sort', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_upward), findsOneWidget);

      await tester.tap(find.text('Index Name'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
    });
  });
}
