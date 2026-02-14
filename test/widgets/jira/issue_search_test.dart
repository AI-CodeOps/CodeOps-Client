// Tests for IssueSearch widget.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/providers/jira_providers.dart';
import 'package:codeops/widgets/jira/issue_search.dart';

void main() {
  Widget wrap(Widget child, {List<Override>? overrides}) {
    return ProviderScope(
      overrides: overrides ?? [],
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }

  group('IssueSearch', () {
    testWidgets('renders search text field with hint', (tester) async {
      await tester.pumpWidget(wrap(
        const IssueSearch(),
        overrides: [
          jiraSearchQueryProvider.overrideWith((ref) => ''),
          jiraSearchResultsProvider.overrideWith(
            (ref) async => null,
          ),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Enter JQL query...'), findsOneWidget);
    });

    testWidgets('renders preset filter buttons', (tester) async {
      await tester.pumpWidget(wrap(
        const IssueSearch(),
        overrides: [
          jiraSearchQueryProvider.overrideWith((ref) => ''),
          jiraSearchResultsProvider.overrideWith(
            (ref) async => null,
          ),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('My Open Issues'), findsOneWidget);
      expect(find.text('Unassigned Bugs'), findsOneWidget);
      expect(find.text('High Priority'), findsOneWidget);
      expect(find.text('Sprint Backlog'), findsOneWidget);
      expect(find.text('Recently Updated'), findsOneWidget);
    });

    testWidgets('TextField accepts input', (tester) async {
      await tester.pumpWidget(wrap(
        const IssueSearch(),
        overrides: [
          jiraSearchQueryProvider.overrideWith((ref) => ''),
          jiraSearchResultsProvider.overrideWith(
            (ref) async => null,
          ),
        ],
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'project = PAY');
      await tester.pump();

      expect(find.text('project = PAY'), findsOneWidget);
    });
  });
}
