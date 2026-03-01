// Widget tests for QueryHistoryPanel.
//
// Verifies panel rendering, search bar, clear button, history entries,
// status icons, timestamps, empty state, and click-to-load callback.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/datalens_enums.dart';
import 'package:codeops/models/datalens_models.dart';
import 'package:codeops/providers/datalens_providers.dart';
import 'package:codeops/widgets/datalens/query_history_panel.dart';

final _historyEntries = [
  QueryHistoryEntry(
    id: '1',
    connectionId: 'conn-1',
    sql: 'SELECT * FROM users',
    status: QueryStatus.completed,
    rowCount: 5,
    executionTimeMs: 42,
    executedAt: DateTime(2026, 3, 1, 14, 30),
  ),
  QueryHistoryEntry(
    id: '2',
    connectionId: 'conn-1',
    sql: 'INSERT INTO users (name) VALUES (\'Alice\')',
    status: QueryStatus.completed,
    rowCount: 1,
    executionTimeMs: 12,
    executedAt: DateTime(2026, 3, 1, 14, 25),
  ),
  QueryHistoryEntry(
    id: '3',
    connectionId: 'conn-1',
    sql: 'SELECT * FROM nonexistent',
    status: QueryStatus.failed,
    error: 'relation does not exist',
    executionTimeMs: 5,
    executedAt: DateTime(2026, 3, 1, 14, 20),
  ),
];

Widget _createWidget({
  List<QueryHistoryEntry> entries = const [],
  ValueChanged<String>? onLoadSql,
}) {
  return ProviderScope(
    overrides: [
      selectedConnectionIdProvider.overrideWith((ref) => 'conn-1'),
      datalensQueryHistoryProvider.overrideWith(
        (ref) => Future.value(entries),
      ),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 400,
          height: 600,
          child: QueryHistoryPanel(onLoadSql: onLoadSql),
        ),
      ),
    ),
  );
}

void main() {
  group('QueryHistoryPanel', () {
    testWidgets('renders', (tester) async {
      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.byType(QueryHistoryPanel), findsOneWidget);
    });

    testWidgets('shows search bar', (tester) async {
      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('shows clear button', (tester) async {
      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Clear'), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });

    testWidgets('shows empty state when no history', (tester) async {
      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.text('No query history'), findsOneWidget);
    });

    testWidgets('shows history entries', (tester) async {
      await tester.pumpWidget(_createWidget(entries: _historyEntries));
      await tester.pumpAndSettle();

      expect(find.textContaining('SELECT * FROM users'), findsOneWidget);
      expect(find.textContaining('INSERT INTO users'), findsOneWidget);
      expect(find.textContaining('SELECT * FROM nonexistent'), findsOneWidget);
    });

    testWidgets('shows execution time', (tester) async {
      await tester.pumpWidget(_createWidget(entries: _historyEntries));
      await tester.pumpAndSettle();

      expect(find.text('42ms'), findsOneWidget);
      expect(find.text('12ms'), findsOneWidget);
    });

    testWidgets('shows row count', (tester) async {
      await tester.pumpWidget(_createWidget(entries: _historyEntries));
      await tester.pumpAndSettle();

      expect(find.text('5 rows'), findsOneWidget);
      expect(find.text('1 row'), findsOneWidget);
    });

    testWidgets('shows Error label for failed entries', (tester) async {
      await tester.pumpWidget(_createWidget(entries: _historyEntries));
      await tester.pumpAndSettle();

      expect(find.text('Error'), findsOneWidget);
    });

    testWidgets('shows status icons', (tester) async {
      await tester.pumpWidget(_createWidget(entries: _historyEntries));
      await tester.pumpAndSettle();

      // 2 completed entries → check_circle, 1 failed → cancel
      expect(find.byIcon(Icons.check_circle), findsNWidgets(2));
      expect(find.byIcon(Icons.cancel), findsOneWidget);
    });

    testWidgets('shows formatted timestamp', (tester) async {
      await tester.pumpWidget(_createWidget(entries: _historyEntries));
      await tester.pumpAndSettle();

      expect(find.text('Mar 1, 2026 2:30 PM'), findsOneWidget);
    });

    testWidgets('fires onLoadSql when entry tapped', (tester) async {
      String? loadedSql;
      await tester.pumpWidget(_createWidget(
        entries: _historyEntries,
        onLoadSql: (sql) => loadedSql = sql,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('SELECT * FROM users'));
      await tester.pumpAndSettle();

      expect(loadedSql, 'SELECT * FROM users');
    });

    testWidgets('search filters entries', (tester) async {
      await tester.pumpWidget(_createWidget(entries: _historyEntries));
      await tester.pumpAndSettle();

      // Type 'INSERT' in the search bar.
      await tester.enterText(find.byType(TextField), 'INSERT');
      await tester.pumpAndSettle();

      expect(find.textContaining('INSERT INTO users'), findsOneWidget);
      expect(find.textContaining('SELECT * FROM users'), findsNothing);
    });
  });
}
