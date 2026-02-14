// Tests for IssueBrowser widget.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:codeops/models/jira_models.dart';
import 'package:codeops/providers/jira_providers.dart';
import 'package:codeops/widgets/jira/issue_browser.dart';

void main() {
  Widget wrap(Widget child, {List<Override>? overrides}) {
    return ProviderScope(
      overrides: overrides ?? [],
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }

  group('IssueBrowser', () {
    testWidgets('shows search prompt empty state when no results',
        (tester) async {
      await tester.pumpWidget(wrap(
        IssueBrowser(onIssueSelected: (_) {}),
        overrides: [
          jiraSearchResultsProvider.overrideWith(
            (ref) async => null,
          ),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Search Jira Issues'), findsOneWidget);
      expect(
        find.text(
            'Enter a JQL query or select a preset filter to browse issues.'),
        findsOneWidget,
      );
    });

    testWidgets('calls onIssueSelected when issue tapped', (tester) async {
      JiraIssueDisplayModel? selectedIssue;

      final searchResult = JiraSearchResult(
        startAt: 0,
        maxResults: 50,
        total: 1,
        issues: [
          JiraIssue(
            id: '10001',
            key: 'PAY-789',
            self: 'https://test.atlassian.net/rest/api/3/issue/10001',
            fields: JiraIssueFields(
              summary: 'Test issue summary',
              issuetype: const JiraIssueType(
                id: '1',
                name: 'Bug',
                subtask: false,
              ),
              status: const JiraStatus(
                id: '1',
                name: 'Open',
                statusCategory: JiraStatusCategory(
                  id: 2,
                  key: 'new',
                  name: 'To Do',
                ),
              ),
              priority: const JiraPriority(
                id: '2',
                name: 'High',
              ),
            ),
          ),
        ],
      );

      await tester.pumpWidget(wrap(
        IssueBrowser(
          onIssueSelected: (issue) => selectedIssue = issue,
        ),
        overrides: [
          jiraSearchResultsProvider.overrideWith(
            (ref) async => searchResult,
          ),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('PAY-789'), findsOneWidget);
      expect(find.text('Test issue summary'), findsOneWidget);

      await tester.tap(find.text('Test issue summary'));
      expect(selectedIssue, isNotNull);
      expect(selectedIssue!.key, equals('PAY-789'));
    });
  });
}
