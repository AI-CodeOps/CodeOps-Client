// Tests for BulkCreateDialog widget.
//
// Verifies dialog title, all-tasks-selected default, Create All and Cancel
// buttons, and select-all checkbox functionality.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/enums.dart';
import 'package:codeops/models/project.dart';
import 'package:codeops/models/remediation_task.dart';
import 'package:codeops/widgets/jira/bulk_create_dialog.dart';

void main() {
  final testTasks = [
    const RemediationTask(
      id: 'rt1',
      jobId: 'j1',
      taskNumber: 1,
      title: 'Fix SQL injection',
      priority: Priority.p1,
      status: TaskStatus.pending,
    ),
    const RemediationTask(
      id: 'rt2',
      jobId: 'j1',
      taskNumber: 2,
      title: 'Update dependencies',
      priority: Priority.p2,
      status: TaskStatus.pending,
    ),
  ];

  const testProject = Project(
    id: 'p1',
    teamId: 't1',
    name: 'Test Project',
    repoUrl: 'https://github.com/test/repo',
    jiraProjectKey: 'PAY',
    jiraDefaultIssueType: 'Bug',
  );

  Widget wrap(Widget child, {List<Override> overrides = const []}) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }

  group('BulkCreateDialog', () {
    testWidgets('renders title "Bulk Create Jira Issues"', (tester) async {
      await tester.pumpWidget(wrap(
        BulkCreateDialog(tasks: testTasks, project: testProject),
      ));
      await tester.pump();

      expect(find.text('Bulk Create Jira Issues'), findsOneWidget);
    });

    testWidgets('shows all tasks selected by default', (tester) async {
      await tester.pumpWidget(wrap(
        BulkCreateDialog(tasks: testTasks, project: testProject),
      ));
      await tester.pump();

      // The header should show "2/2 tasks selected".
      expect(find.text('2/2 tasks selected'), findsOneWidget);

      // The badge should show "Creating 2 issues".
      expect(find.text('Creating 2 issues'), findsOneWidget);
    });

    testWidgets('shows Create All and Cancel buttons', (tester) async {
      await tester.pumpWidget(wrap(
        BulkCreateDialog(tasks: testTasks, project: testProject),
      ));
      await tester.pump();

      expect(find.text('Create All'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('select-all checkbox works', (tester) async {
      await tester.pumpWidget(wrap(
        BulkCreateDialog(tasks: testTasks, project: testProject),
      ));
      await tester.pump();

      // Initially all selected: "2/2 tasks selected"
      expect(find.text('2/2 tasks selected'), findsOneWidget);

      // Find all checkboxes. The order is:
      // [0] Sub-task toggle checkbox
      // [1] Select-all header checkbox (tristate)
      // [2..] Per-task checkboxes
      final checkboxes = find.byType(Checkbox);
      expect(checkboxes, findsWidgets);

      // Tap the select-all checkbox (at index 1) to deselect all.
      await tester.tap(checkboxes.at(1));
      await tester.pump();

      // After toggling, should show "0/2 tasks selected".
      expect(find.text('0/2 tasks selected'), findsOneWidget);

      // Tap again to select all.
      await tester.tap(checkboxes.at(1));
      await tester.pump();

      expect(find.text('2/2 tasks selected'), findsOneWidget);
    });
  });
}
