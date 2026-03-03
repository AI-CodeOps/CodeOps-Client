// Widget tests for Convention Manager version history panel.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/mcp_enums.dart';
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
  ];

  final doc = ProjectDocumentDetail(
    id: 'doc-1',
    currentContent: '# CONVENTIONS.md\n\nContent here.',
    lastUpdatedByName: 'Adam',
    isFlagged: false,
    versions: [
      ProjectDocumentVersion(
        versionNumber: 1,
        changeDescription: 'Initial version',
        authorType: AuthorType.human,
        authorName: 'Adam',
        commitHash: 'abc12345def',
        createdAt: DateTime(2026, 2, 1),
      ),
      ProjectDocumentVersion(
        versionNumber: 2,
        changeDescription: 'Added testing rules',
        authorType: AuthorType.ai,
        authorName: 'Claude',
        createdAt: DateTime(2026, 3, 1),
      ),
    ],
  );

  Widget createWidget({bool historyVisible = true}) {
    return ProviderScope(
      overrides: [
        selectedTeamIdProvider.overrideWith((ref) => teamId),
        teamProjectsProvider.overrideWith(
          (ref) => Future.value(projects),
        ),
        conventionProjectIdProvider.overrideWith((ref) => 'proj-1'),
        conventionHistoryVisibleProvider.overrideWith(
          (ref) => historyVisible,
        ),
        conventionDocumentProvider.overrideWith(
          (ref) => Future.value(doc),
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

  group('Version History Panel', () {
    testWidgets('renders version history header', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Version History'), findsOneWidget);
    });

    testWidgets('renders version entries', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('v1'), findsOneWidget);
      expect(find.text('v2'), findsWidgets); // v2 in header + list
      expect(find.text('Initial version'), findsOneWidget);
      expect(find.text('Added testing rules'), findsOneWidget);
    });

    testWidgets('renders author type badges', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Human'), findsOneWidget);
      expect(find.text('AI'), findsOneWidget);
    });

    testWidgets('renders commit hash prefix', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('abc12345'), findsOneWidget);
    });

    testWidgets('hides panel when not visible', (tester) async {
      await tester.pumpWidget(createWidget(historyVisible: false));
      await tester.pumpAndSettle();

      expect(find.text('Version History'), findsNothing);
    });
  });
}
