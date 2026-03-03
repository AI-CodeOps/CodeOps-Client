// Widget tests for ConventionManagerPage.
import 'dart:async';

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
  ];

  Widget createWidget({
    String? selectedTeamId = teamId,
    String? selectedProjectId,
    bool loading = false,
    bool hasDoc = true,
  }) {
    final doc = ProjectDocumentDetail(
      id: 'doc-1',
      documentType: null,
      currentContent: '# CONVENTIONS.md\n\n## Code Style\n\nFollow standards.',
      lastUpdatedByName: 'Adam',
      isFlagged: false,
      versions: [
        ProjectDocumentVersion(
          versionNumber: 1,
          changeDescription: 'Initial version',
          authorName: 'Adam',
          createdAt: DateTime(2026, 2, 1),
        ),
        ProjectDocumentVersion(
          versionNumber: 2,
          changeDescription: 'Added testing section',
          authorName: 'Claude',
          createdAt: DateTime(2026, 3, 1),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        selectedTeamIdProvider.overrideWith((ref) => selectedTeamId),
        teamProjectsProvider.overrideWith(
          (ref) => Future.value(projects),
        ),
        if (selectedProjectId != null)
          conventionProjectIdProvider.overrideWith(
            (ref) => selectedProjectId,
          ),
        conventionDocumentProvider.overrideWith((ref) {
          if (loading) return Completer<ProjectDocumentDetail?>().future;
          if (!hasDoc) return Future.value(null);
          return Future.value(doc);
        }),
        conventionPropagationProvider.overrideWith(
          (ref) => Future.value(<ConventionPropagationEntry>[]),
        ),
      ],
      child: const MaterialApp(
        home: Scaffold(body: ConventionManagerPage()),
      ),
    );
  }

  group('ConventionManagerPage', () {
    testWidgets('renders header with breadcrumb', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Convention Manager'), findsOneWidget);
    });

    testWidgets('renders no team state', (tester) async {
      await tester.pumpWidget(createWidget(selectedTeamId: null));
      await tester.pumpAndSettle();

      expect(find.text('No team selected'), findsOneWidget);
    });

    testWidgets('renders project selector in toolbar', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Select Project'), findsOneWidget);
    });

    testWidgets('renders select prompt when no project selected',
        (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(
          find.text('Select a project to view conventions'), findsOneWidget);
    });

    testWidgets('renders editor when project selected', (tester) async {
      await tester.pumpWidget(
          createWidget(selectedProjectId: 'proj-1'));
      await tester.pumpAndSettle();

      expect(find.text('CONVENTIONS.md'), findsOneWidget);
      expect(find.text('Last updated by Adam'), findsOneWidget);
    });

    testWidgets('renders version indicator', (tester) async {
      await tester.pumpWidget(
          createWidget(selectedProjectId: 'proj-1'));
      await tester.pumpAndSettle();

      expect(find.text('v2'), findsOneWidget);
    });

    testWidgets('renders word count', (tester) async {
      await tester.pumpWidget(
          createWidget(selectedProjectId: 'proj-1'));
      await tester.pumpAndSettle();

      expect(find.textContaining('words'), findsOneWidget);
    });

    testWidgets('renders no-doc state when document missing',
        (tester) async {
      await tester.pumpWidget(
          createWidget(selectedProjectId: 'proj-1', hasDoc: false));
      await tester.pumpAndSettle();

      expect(find.text('No conventions document found'), findsOneWidget);
    });
  });
}
