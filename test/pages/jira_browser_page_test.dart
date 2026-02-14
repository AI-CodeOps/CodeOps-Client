// Tests for JiraBrowserPage.
//
// Verifies "No Jira Connection" state when not configured,
// and loading indicator when connections are loading.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/health_snapshot.dart';
import 'package:codeops/pages/jira_browser_page.dart';
import 'package:codeops/providers/jira_providers.dart';

void main() {
  Widget wrap(Widget child, {List<Override> overrides = const []}) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }

  group('JiraBrowserPage', () {
    testWidgets('shows "No Jira Connection" when not configured',
        (tester) async {
      await tester.pumpWidget(wrap(
        const JiraBrowserPage(),
        overrides: [
          jiraConnectionsProvider
              .overrideWith((ref) => Future.value(<JiraConnection>[])),
          isJiraConfiguredProvider.overrideWith((ref) => false),
          activeJiraConnectionProvider.overrideWith((ref) => null),
          selectedJiraIssueKeyProvider.overrideWith((ref) => null),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('No Jira Connection'), findsOneWidget);
      expect(
        find.text('Configure a Jira Cloud connection to browse issues.'),
        findsOneWidget,
      );
      expect(find.text('Configure Jira'), findsOneWidget);
    });

    testWidgets('shows loading indicator', (tester) async {
      // Use a Completer to keep the future permanently in loading state.
      final completer = Completer<List<JiraConnection>>();

      await tester.pumpWidget(wrap(
        const JiraBrowserPage(),
        overrides: [
          jiraConnectionsProvider.overrideWith((ref) => completer.future),
          isJiraConfiguredProvider.overrideWith((ref) => false),
          activeJiraConnectionProvider.overrideWith((ref) => null),
          selectedJiraIssueKeyProvider.overrideWith((ref) => null),
        ],
      ));
      // Only pump once to catch the loading state (don't pumpAndSettle).
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
