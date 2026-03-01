// Widget tests for NavigatorBottomPanel.
//
// Verifies panel rendering, tab bar with Bookmarks/History/Scripts,
// tab switching, and Scripts placeholder.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/providers/datalens_providers.dart';
import 'package:codeops/widgets/datalens/navigator_bottom_panel.dart';
import 'package:codeops/widgets/datalens/query_history_panel.dart';
import 'package:codeops/widgets/datalens/saved_queries_panel.dart';

Widget _createWidget({ValueChanged<String>? onLoadSql}) {
  return ProviderScope(
    overrides: [
      selectedConnectionIdProvider.overrideWith((ref) => 'conn-1'),
      datalensQueryHistoryProvider.overrideWith(
        (ref) => Future.value([]),
      ),
      datalensSavedQueriesProvider.overrideWith(
        (ref) => Future.value([]),
      ),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 400,
          height: 400,
          child: NavigatorBottomPanel(onLoadSql: onLoadSql),
        ),
      ),
    ),
  );
}

void main() {
  group('NavigatorBottomPanel', () {
    testWidgets('renders', (tester) async {
      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.byType(NavigatorBottomPanel), findsOneWidget);
    });

    testWidgets('shows Bookmarks tab', (tester) async {
      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Bookmarks'), findsOneWidget);
    });

    testWidgets('shows History tab', (tester) async {
      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.text('History'), findsOneWidget);
    });

    testWidgets('shows Scripts tab', (tester) async {
      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Scripts'), findsOneWidget);
    });

    testWidgets('default tab shows SavedQueriesPanel', (tester) async {
      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.byType(SavedQueriesPanel), findsOneWidget);
    });

    testWidgets('switching to History shows QueryHistoryPanel',
        (tester) async {
      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      expect(find.byType(QueryHistoryPanel), findsOneWidget);
    });

    testWidgets('switching to Scripts shows placeholder', (tester) async {
      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Scripts'));
      await tester.pumpAndSettle();

      expect(find.textContaining('coming soon'), findsOneWidget);
    });
  });
}
