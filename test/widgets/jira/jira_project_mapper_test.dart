// Tests for JiraProjectMapper widget.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:codeops/models/project.dart';
import 'package:codeops/widgets/jira/jira_project_mapper.dart';

void main() {
  final testProject = Project(
    id: 'p1',
    teamId: 't1',
    name: 'Test Project',
    repoUrl: 'https://github.com/test/repo',
    jiraProjectKey: 'PAY',
    jiraDefaultIssueType: 'Bug',
  );

  Widget wrap(Widget child, {List<Override>? overrides}) {
    return ProviderScope(
      overrides: overrides ?? [],
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }

  group('JiraProjectMapper', () {
    testWidgets('renders title "Jira Project Mapping"', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrap(
        JiraProjectMapper(project: testProject),
      ));
      await tester.pump();

      expect(find.text('Jira Project Mapping'), findsOneWidget);
    });

    testWidgets('shows Save Mapping button', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrap(
        JiraProjectMapper(project: testProject),
      ));
      await tester.pump();

      expect(find.text('Save Mapping'), findsOneWidget);
    });

    testWidgets('pre-fills fields from project', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrap(
        JiraProjectMapper(project: testProject),
      ));
      await tester.pump();

      // The current mapping section should show the project key and issue type.
      expect(find.text('Current Mapping'), findsOneWidget);
      expect(find.text('PAY'), findsWidgets);
      expect(find.text('Bug'), findsWidgets);
    });
  });
}
