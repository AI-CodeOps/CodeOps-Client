// Tests for IssueCard widget.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/jira_models.dart';
import 'package:codeops/widgets/jira/issue_card.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  JiraIssueDisplayModel createIssue({
    String key = 'PAY-123',
    String summary = 'Fix bug',
    String statusName = 'In Progress',
    String? statusCategoryKey = 'indeterminate',
    String? priorityName = 'High',
    String? issuetypeName = 'Bug',
    String? assigneeName,
    String? assigneeAvatarUrl,
    int commentCount = 3,
    int attachmentCount = 1,
    int linkCount = 0,
  }) {
    return JiraIssueDisplayModel(
      key: key,
      summary: summary,
      statusName: statusName,
      statusCategoryKey: statusCategoryKey,
      priorityName: priorityName,
      issuetypeName: issuetypeName,
      assigneeName: assigneeName,
      assigneeAvatarUrl: assigneeAvatarUrl,
      commentCount: commentCount,
      attachmentCount: attachmentCount,
      linkCount: linkCount,
    );
  }

  group('IssueCard', () {
    testWidgets('renders issue key, summary, and status badge', (tester) async {
      final issue = createIssue();

      await tester.pumpWidget(wrap(
        IssueCard(issue: issue, onTap: () {}),
      ));

      expect(find.text('PAY-123'), findsOneWidget);
      expect(find.text('Fix bug'), findsOneWidget);
      expect(find.text('In Progress'), findsOneWidget);
    });

    testWidgets('shows priority when present', (tester) async {
      final issue = createIssue(priorityName: 'High');

      await tester.pumpWidget(wrap(
        IssueCard(issue: issue, onTap: () {}),
      ));

      expect(find.text('High'), findsOneWidget);
    });

    testWidgets('shows "Unassigned" when assigneeName is null', (tester) async {
      final issue = createIssue(assigneeName: null);

      await tester.pumpWidget(wrap(
        IssueCard(issue: issue, onTap: () {}),
      ));

      expect(find.text('Unassigned'), findsOneWidget);
    });

    testWidgets('shows assignee name when present', (tester) async {
      final issue = createIssue(assigneeName: 'Alice Smith');

      await tester.pumpWidget(wrap(
        IssueCard(issue: issue, onTap: () {}),
      ));

      expect(find.text('Alice Smith'), findsOneWidget);
      expect(find.text('Unassigned'), findsNothing);
    });

    testWidgets('shows comment and attachment counts', (tester) async {
      final issue = createIssue(commentCount: 3, attachmentCount: 1);

      await tester.pumpWidget(wrap(
        IssueCard(issue: issue, onTap: () {}),
      ));

      expect(find.text('3'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
      expect(find.byIcon(Icons.attach_file), findsOneWidget);
    });

    testWidgets('calls onTap callback', (tester) async {
      var tapped = false;
      final issue = createIssue();

      await tester.pumpWidget(wrap(
        IssueCard(issue: issue, onTap: () => tapped = true),
      ));

      await tester.tap(find.text('Fix bug'));
      expect(tapped, isTrue);
    });
  });
}
