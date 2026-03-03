// Widget tests for Convention Manager propagation status.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/mcp_models.dart';
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
    Project(id: 'proj-2', teamId: teamId, name: 'CodeOps-Client'),
    Project(id: 'proj-3', teamId: teamId, name: 'CodeOps-Analytics'),
  ];

  final propagationEntries = [
    ConventionPropagationEntry(
      project: projects[0],
      document: ProjectDocumentDetail(
        id: 'doc-1',
        isFlagged: false,
        updatedAt: DateTime(2026, 3, 1),
      ),
      status: PropagationStatus.current,
    ),
    ConventionPropagationEntry(
      project: projects[1],
      document: ProjectDocumentDetail(
        id: 'doc-2',
        isFlagged: true,
        updatedAt: DateTime(2026, 1, 15),
      ),
      status: PropagationStatus.behind,
    ),
    ConventionPropagationEntry(
      project: projects[2],
      status: PropagationStatus.missing,
    ),
  ];

  Widget createWidget({bool emptyPropagation = false}) {
    return ProviderScope(
      overrides: [
        selectedTeamIdProvider.overrideWith((ref) => teamId),
        teamProjectsProvider.overrideWith(
          (ref) => Future.value(projects),
        ),
        conventionDocumentProvider.overrideWith(
          (ref) => Future.value(null),
        ),
        conventionPropagationProvider.overrideWith(
          (ref) => Future.value(
            emptyPropagation ? <ConventionPropagationEntry>[] : propagationEntries,
          ),
        ),
      ],
      child: const MaterialApp(
        home: Scaffold(body: ConventionManagerPage()),
      ),
    );
  }

  group('Propagation Status', () {
    testWidgets('renders propagation section header', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Propagation Status'), findsOneWidget);
    });

    testWidgets('renders project names', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('CodeOps-Server'), findsOneWidget);
      expect(find.text('CodeOps-Client'), findsOneWidget);
      expect(find.text('CodeOps-Analytics'), findsOneWidget);
    });

    testWidgets('renders status badges', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Current'), findsOneWidget);
      expect(find.text('Behind'), findsOneWidget);
      expect(find.text('Missing'), findsOneWidget);
    });

    testWidgets('renders column headers', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Project'), findsOneWidget);
      expect(find.text('Status'), findsOneWidget);
      expect(find.text('Last Updated'), findsOneWidget);
    });
  });
}
