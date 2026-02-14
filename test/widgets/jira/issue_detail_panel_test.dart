// Tests for IssueDetailPanel widget.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:codeops/models/jira_models.dart';
import 'package:codeops/providers/jira_providers.dart';
import 'package:codeops/widgets/jira/issue_detail_panel.dart';

void main() {
  Widget wrap(
    Widget child, {
    List<Override>? overrides,
  }) {
    return ProviderScope(
      overrides: overrides ?? [],
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }

  group('IssueDetailPanel', () {
    testWidgets('shows loading indicator initially', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrap(
        const IssueDetailPanel(issueKey: 'PAY-456'),
        overrides: [
          jiraIssueProvider('PAY-456').overrideWith(
            (ref) => Completer<JiraIssue?>().future,
          ),
          jiraCommentsProvider('PAY-456').overrideWith(
            (ref) async => <JiraComment>[],
          ),
        ],
      ));
      // Pump once to build, but do not settle — provider is still loading.
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('calls onClose when close button tapped', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      var closeCalled = false;

      final testIssue = JiraIssue(
        id: '10001',
        key: 'PAY-456',
        self: 'https://test.atlassian.net/rest/api/3/issue/10001',
        fields: JiraIssueFields(
          summary: 'Payment gateway timeout',
          issuetype: const JiraIssueType(
            id: '1',
            name: 'Bug',
            subtask: false,
          ),
          status: const JiraStatus(
            id: '3',
            name: 'In Progress',
            statusCategory: JiraStatusCategory(
              id: 4,
              key: 'indeterminate',
              name: 'In Progress',
            ),
          ),
          priority: const JiraPriority(
            id: '2',
            name: 'High',
          ),
        ),
      );

      await tester.pumpWidget(wrap(
        IssueDetailPanel(
          issueKey: 'PAY-456',
          onClose: () => closeCalled = true,
        ),
        overrides: [
          jiraIssueProvider('PAY-456').overrideWith(
            (ref) async => testIssue,
          ),
          jiraCommentsProvider('PAY-456').overrideWith(
            (ref) async => <JiraComment>[],
          ),
        ],
      ));
      await tester.pumpAndSettle();

      // The close button is an IconButton with Icons.close in the header.
      final closeButton = find.byIcon(Icons.close);
      expect(closeButton, findsOneWidget);

      await tester.tap(closeButton);
      expect(closeCalled, isTrue);
    });
  });
}
