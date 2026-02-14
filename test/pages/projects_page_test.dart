// Widget tests for ProjectsPage.
//
// Verifies page structure, empty state, project cards, search, sort,
// and favorites behavior.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/health_snapshot.dart';
import 'package:codeops/models/project.dart';
import 'package:codeops/pages/projects_page.dart';
import 'package:codeops/providers/github_providers.dart';
import 'package:codeops/providers/project_providers.dart';

final _testProject = Project(
  id: 'proj-1',
  teamId: 'team-1',
  name: 'Test Project',
  repoFullName: 'owner/test-project',
  techStack: 'Flutter',
  healthScore: 85,
  isArchived: false,
  createdAt: DateTime(2024, 1, 1),
);

final _archivedProject = Project(
  id: 'proj-2',
  teamId: 'team-1',
  name: 'Archived Project',
  healthScore: 40,
  isArchived: true,
  createdAt: DateTime(2024, 1, 2),
);

void main() {
  Widget createWidget({
    List<Project> projects = const [],
    List<Override> overrides = const [],
  }) {
    return ProviderScope(
      overrides: [
        teamProjectsProvider.overrideWith(
          (ref) => Future.value(projects),
        ),
        githubConnectionsProvider.overrideWith(
          (ref) => Future.value(<GitHubConnection>[]),
        ),
        jiraConnectionsProvider.overrideWith(
          (ref) => Future.value(<JiraConnection>[]),
        ),
        ...overrides,
      ],
      child: const MaterialApp(home: Scaffold(body: ProjectsPage())),
    );
  }

  group('ProjectsPage', () {
    testWidgets('shows Projects title', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Projects'), findsOneWidget);
    });

    testWidgets('shows New Project button', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Appears in top bar button and empty state action.
      expect(find.text('New Project'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows empty state when no projects', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('No projects yet'), findsOneWidget);
    });

    testWidgets('shows project card when projects exist', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidget(projects: [_testProject]));
      await tester.pumpAndSettle();

      expect(find.text('Test Project'), findsOneWidget);
      expect(find.text('owner/test-project'), findsOneWidget);
    });

    testWidgets('shows tech stack badge', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidget(projects: [_testProject]));
      await tester.pumpAndSettle();

      expect(find.text('Flutter'), findsOneWidget);
    });

    testWidgets('shows health score in card', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidget(projects: [_testProject]));
      await tester.pumpAndSettle();

      expect(find.text('85'), findsOneWidget);
    });

    testWidgets('hides archived projects by default', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester
          .pumpWidget(createWidget(projects: [_testProject, _archivedProject]));
      await tester.pumpAndSettle();

      expect(find.text('Test Project'), findsOneWidget);
      expect(find.text('Archived Project'), findsNothing);
    });

    testWidgets('shows Archived filter chip', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Archived'), findsOneWidget);
    });

    testWidgets('shows sort dropdown with Name A-Z', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Name A-Z'), findsOneWidget);
    });

    testWidgets('shows search bar', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('shows favorite star on card', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidget(projects: [_testProject]));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.star_border), findsOneWidget);
    });
  });
}
