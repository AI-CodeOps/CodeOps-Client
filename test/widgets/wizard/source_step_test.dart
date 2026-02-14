import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/project.dart';
import 'package:codeops/providers/project_providers.dart';
import 'package:codeops/widgets/wizard/source_step.dart';

void main() {
  Widget createWidget({
    Project? selectedProject,
    String? selectedBranch,
    List<Override> overrides = const [],
  }) {
    return ProviderScope(
      overrides: [
        teamProjectsProvider.overrideWith((ref) => Future.value([
              const Project(id: 'p1', teamId: 't1', name: 'Frontend App', techStack: 'React'),
              const Project(id: 'p2', teamId: 't1', name: 'Backend API', techStack: 'Spring Boot'),
            ])),
        ...overrides,
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 800,
            child: SourceStep(
              selectedProject: selectedProject,
              selectedBranch: selectedBranch,
              onProjectSelected: (_) {},
              onBranchSelected: (_) {},
            ),
          ),
        ),
      ),
    );
  }

  group('SourceStep', () {
    testWidgets('shows title', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Select Source'), findsOneWidget);
    });

    testWidgets('shows project list', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Frontend App'), findsOneWidget);
      expect(find.text('Backend API'), findsOneWidget);
    });

    testWidgets('shows search bar', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('shows selected project card', (tester) async {
      await tester.pumpWidget(createWidget(
        selectedProject: const Project(
          id: 'p1',
          teamId: 't1',
          name: 'Frontend App',
          defaultBranch: 'main',
        ),
        selectedBranch: 'main',
      ));
      await tester.pumpAndSettle();

      // The selected project name should appear in both the card and the list
      expect(find.text('Frontend App'), findsWidgets);
    });
  });
}
