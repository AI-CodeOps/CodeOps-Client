// Widget tests for SavedQueriesPanel.
//
// Verifies panel rendering, search bar, new query button, empty state,
// folder grouping, query entries, and click-to-load callback.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/datalens_models.dart';
import 'package:codeops/providers/datalens_providers.dart';
import 'package:codeops/widgets/datalens/saved_queries_panel.dart';

final _savedQueries = [
  SavedQuery(
    id: '1',
    connectionId: 'conn-1',
    name: 'All Users',
    description: 'Fetch all users from the table',
    sql: 'SELECT * FROM users',
    folder: 'Reports',
    createdAt: DateTime(2026, 2, 28),
  ),
  SavedQuery(
    id: '2',
    connectionId: 'conn-1',
    name: 'Active Users',
    sql: 'SELECT * FROM users WHERE active = true',
    folder: 'Reports',
    createdAt: DateTime(2026, 2, 28),
  ),
  SavedQuery(
    id: '3',
    connectionId: 'conn-1',
    name: 'Drop Temp',
    sql: 'DROP TABLE IF EXISTS temp_data',
    createdAt: DateTime(2026, 2, 28),
  ),
];

Widget _createWidget({
  List<SavedQuery> queries = const [],
  ValueChanged<String>? onLoadSql,
}) {
  return ProviderScope(
    overrides: [
      selectedConnectionIdProvider.overrideWith((ref) => 'conn-1'),
      datalensSavedQueriesProvider.overrideWith(
        (ref) => Future.value(queries),
      ),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 400,
          height: 600,
          child: SavedQueriesPanel(onLoadSql: onLoadSql),
        ),
      ),
    ),
  );
}

void main() {
  group('SavedQueriesPanel', () {
    testWidgets('renders', (tester) async {
      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.byType(SavedQueriesPanel), findsOneWidget);
    });

    testWidgets('shows search bar', (tester) async {
      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('shows new query button', (tester) async {
      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.text('New'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('shows empty state when no saved queries', (tester) async {
      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.text('No saved queries'), findsOneWidget);
    });

    testWidgets('shows folder headers', (tester) async {
      await tester.pumpWidget(_createWidget(queries: _savedQueries));
      await tester.pumpAndSettle();

      expect(find.text('Reports'), findsOneWidget);
      expect(find.text('Ungrouped'), findsOneWidget);
    });

    testWidgets('shows folder query count', (tester) async {
      await tester.pumpWidget(_createWidget(queries: _savedQueries));
      await tester.pumpAndSettle();

      // Reports has 2 queries, Ungrouped has 1.
      expect(find.text('2'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('expanding folder shows queries', (tester) async {
      await tester.pumpWidget(_createWidget(queries: _savedQueries));
      await tester.pumpAndSettle();

      // Queries not visible initially (folders collapsed).
      expect(find.text('All Users'), findsNothing);

      // Expand the Reports folder.
      await tester.tap(find.text('Reports'));
      await tester.pumpAndSettle();

      expect(find.text('All Users'), findsOneWidget);
      expect(find.text('Active Users'), findsOneWidget);
    });

    testWidgets('fires onLoadSql when query tapped', (tester) async {
      String? loadedSql;
      await tester.pumpWidget(_createWidget(
        queries: _savedQueries,
        onLoadSql: (sql) => loadedSql = sql,
      ));
      await tester.pumpAndSettle();

      // Expand Reports folder.
      await tester.tap(find.text('Reports'));
      await tester.pumpAndSettle();

      // Tap the 'All Users' entry.
      await tester.tap(find.text('All Users'));
      await tester.pumpAndSettle();

      expect(loadedSql, 'SELECT * FROM users');
    });

    testWidgets('search filters queries', (tester) async {
      await tester.pumpWidget(_createWidget(queries: _savedQueries));
      await tester.pumpAndSettle();

      // Type 'Drop' in the search bar.
      await tester.enterText(find.byType(TextField), 'Drop');
      await tester.pumpAndSettle();

      // Only the Ungrouped folder with 'Drop Temp' should remain.
      expect(find.text('Ungrouped'), findsOneWidget);
      expect(find.text('Reports'), findsNothing);
    });
  });
}
