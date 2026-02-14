// Tests for CreateIssueDialog widget.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:codeops/models/project.dart';
import 'package:codeops/models/remediation_task.dart';
import 'package:codeops/models/enums.dart';
import 'package:codeops/widgets/jira/create_issue_dialog.dart';

void main() {
  final testProject = Project(
    id: 'p1',
    teamId: 't1',
    name: 'Test Project',
    repoUrl: 'https://github.com/test/repo',
    jiraProjectKey: 'PAY',
    jiraDefaultIssueType: 'Bug',
  );

  const testTask = RemediationTask(
    id: 'rt1',
    jobId: 'j1',
    taskNumber: 1,
    title: 'Fix SQL injection',
    priority: Priority.p1,
    status: TaskStatus.pending,
  );

  Widget wrap(Widget child, {List<Override>? overrides}) {
    return ProviderScope(
      overrides: overrides ?? [],
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }

  group('CreateIssueDialog', () {
    testWidgets('renders title "Create Jira Issue"', (tester) async {
      await tester.pumpWidget(wrap(
        CreateIssueDialog(task: testTask, project: testProject),
      ));
      await tester.pump();

      expect(find.text('Create Jira Issue'), findsOneWidget);
    });

    testWidgets('pre-fills summary from task title', (tester) async {
      await tester.pumpWidget(wrap(
        CreateIssueDialog(task: testTask, project: testProject),
      ));
      await tester.pump();

      // The summary field should be pre-filled with the task title.
      expect(find.text('Fix SQL injection'), findsOneWidget);
    });

    testWidgets('shows Cancel and Create Issue buttons', (tester) async {
      await tester.pumpWidget(wrap(
        CreateIssueDialog(task: testTask, project: testProject),
      ));
      await tester.pump();

      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Create Issue'), findsOneWidget);
    });
  });
}
