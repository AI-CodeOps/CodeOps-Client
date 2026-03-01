// Widget tests for SavedQueriesDropdown.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/logger_models.dart';
import 'package:codeops/widgets/logger/saved_queries_dropdown.dart';

void main() {
  final queries = [
    SavedQueryResponse(
      id: 'sq-1',
      name: 'Error logs',
      description: 'All error-level logs',
      queryJson: '{"level":"ERROR"}',
      teamId: 'team-1',
      createdBy: 'user-1',
      isShared: false,
      executionCount: 5,
    ),
    SavedQueryResponse(
      id: 'sq-2',
      name: 'Auth failures',
      description: 'Login failures from auth service',
      queryJson: '{"serviceName":"auth","level":"ERROR"}',
      teamId: 'team-1',
      createdBy: 'user-1',
      isShared: true,
      executionCount: 12,
    ),
  ];

  Widget createWidget({
    List<SavedQueryResponse>? queryList,
    ValueChanged<SavedQueryResponse>? onLoad,
    ValueChanged<SavedQueryResponse>? onDelete,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SavedQueriesDropdown(
            queries: queryList ?? queries,
            onLoad: onLoad ?? (_) {},
            onDelete: onDelete ?? (_) {},
          ),
        ),
      ),
    );
  }

  group('SavedQueriesDropdown', () {
    testWidgets('renders button with count', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Saved Queries (2)'), findsOneWidget);
      expect(find.byIcon(Icons.bookmark_outline), findsOneWidget);
    });

    testWidgets('shows query names in popup', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Open the dropdown.
      await tester.tap(find.text('Saved Queries (2)'));
      await tester.pumpAndSettle();

      expect(find.text('Error logs'), findsOneWidget);
      expect(find.text('Auth failures'), findsOneWidget);
      expect(find.text('5x'), findsOneWidget);
      expect(find.text('12x'), findsOneWidget);
    });

    testWidgets('calls onLoad when query is selected', (tester) async {
      SavedQueryResponse? loadedQuery;
      await tester.pumpWidget(createWidget(
        onLoad: (q) => loadedQuery = q,
      ));
      await tester.pumpAndSettle();

      // Open and select.
      await tester.tap(find.text('Saved Queries (2)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Error logs'));
      await tester.pumpAndSettle();

      expect(loadedQuery?.id, 'sq-1');
    });

    testWidgets('shows delete button on query items', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Open.
      await tester.tap(find.text('Saved Queries (2)'));
      await tester.pumpAndSettle();

      // Delete icons should be present.
      expect(find.byIcon(Icons.delete_outline), findsNWidgets(2));
    });
  });
}
