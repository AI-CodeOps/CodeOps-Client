// Widget tests for Convention Manager templates section.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/project.dart';
import 'package:codeops/pages/mcp/convention_manager_page.dart';
import 'package:codeops/providers/mcp_convention_providers.dart';
import 'package:codeops/providers/project_providers.dart';
import 'package:codeops/providers/team_providers.dart'
    show selectedTeamIdProvider;

void main() {
  const teamId = 'team-1';

  final projects = [
    Project(id: 'proj-1', teamId: teamId, name: 'CodeOps-Server'),
  ];

  Widget createWidget({String? selectedProjectId}) {
    return ProviderScope(
      overrides: [
        selectedTeamIdProvider.overrideWith((ref) => teamId),
        teamProjectsProvider.overrideWith(
          (ref) => Future.value(projects),
        ),
        if (selectedProjectId != null)
          conventionProjectIdProvider.overrideWith(
            (ref) => selectedProjectId,
          ),
        conventionDocumentProvider.overrideWith(
          (ref) => Future.value(null),
        ),
        conventionPropagationProvider.overrideWith(
          (ref) => Future.value(<ConventionPropagationEntry>[]),
        ),
      ],
      child: const MaterialApp(
        home: Scaffold(body: ConventionManagerPage()),
      ),
    );
  }

  group('Convention Templates', () {
    testWidgets('renders templates section header', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Convention Templates'), findsOneWidget);
    });

    testWidgets('renders all four template cards', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('AI-First Development'), findsOneWidget);
      expect(find.text('Spring Boot Backend'), findsOneWidget);
      expect(find.text('Flutter Frontend'), findsOneWidget);
      expect(find.text('Minimal'), findsOneWidget);
    });

    testWidgets('opens confirmation dialog on template tap',
        (tester) async {
      await tester.pumpWidget(
          createWidget(selectedProjectId: 'proj-1'));
      await tester.pumpAndSettle();

      // Scroll down to make templates visible
      await tester.scrollUntilVisible(
        find.text('AI-First Development'),
        200,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('AI-First Development'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Apply'), findsWidgets);
      expect(find.text('Cancel'), findsOneWidget);
    });
  });
}
