// Widget tests for context display sections and toolbar.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/pages/mcp/context_viewer_page.dart';
import 'package:codeops/providers/mcp_context_providers.dart';
import 'package:codeops/providers/mcp_providers.dart';
import 'package:codeops/providers/project_providers.dart';
import 'package:codeops/providers/team_providers.dart'
    show selectedTeamIdProvider;

void main() {
  final sections = [
    ContextSection(
      title: 'Persona',
      health: ContextSectionHealth.healthy,
      data: {'agentType': 'claude', 'developer': 'Adam'},
      itemCount: 1,
      sizeBytes: 48,
    ),
    ContextSection(
      title: 'Conventions',
      health: ContextSectionHealth.stale,
      data: {'present': true, 'isFlagged': true},
      itemCount: 1,
      sizeBytes: 36,
    ),
    ContextSection(
      title: 'Project Documents',
      health: ContextSectionHealth.healthy,
      data: {'totalDocuments': 3},
      itemCount: 3,
      sizeBytes: 120,
    ),
    ContextSection(
      title: 'Ecosystem Context',
      health: ContextSectionHealth.healthy,
      data: {'projectName': 'CodeOps-Server'},
      itemCount: 1,
      sizeBytes: 55,
    ),
    ContextSection(
      title: 'Secret References',
      health: ContextSectionHealth.notApplicable,
      data: {'note': 'Vault paths'},
      itemCount: 0,
      sizeBytes: 20,
    ),
    ContextSection(
      title: 'Team Directives',
      health: ContextSectionHealth.missing,
      data: {'claudeMdPresent': false},
      itemCount: 0,
      sizeBytes: 22,
    ),
    ContextSection(
      title: 'Recent Sessions',
      health: ContextSectionHealth.healthy,
      data: {'count': 2},
      itemCount: 2,
      sizeBytes: 80,
    ),
    ContextSection(
      title: 'Team Discussion',
      health: ContextSectionHealth.notApplicable,
      data: {'available': false},
      itemCount: 0,
      sizeBytes: 18,
    ),
    ContextSection(
      title: 'Container Status',
      health: ContextSectionHealth.notApplicable,
      data: {'note': 'Fleet containers'},
      itemCount: 0,
      sizeBytes: 25,
    ),
  ];

  final assembled = AssembledContext(
    sections: sections,
    totalSizeBytes: 424,
    estimatedTokens: 106,
    payload: {
      'persona': sections[0].data,
      'conventions': sections[1].data,
      'projectDocuments': sections[2].data,
    },
  );

  Widget createWidget() {
    return ProviderScope(
      overrides: [
        selectedTeamIdProvider.overrideWith((ref) => 'team-1'),
        teamProjectsProvider.overrideWith((ref) => Future.value([])),
        mcpTeamProfilesProvider
            .overrideWith((ref, id) => Future.value([])),
        contextSimulatedProvider.overrideWith((ref) => true),
        contextRawJsonProvider.overrideWith((ref) => false),
        contextAssemblyProvider
            .overrideWith((ref) => Future.value(assembled)),
      ],
      child: const MaterialApp(
        home: Scaffold(body: ContextViewerPage()),
      ),
    );
  }

  group('Context display', () {
    testWidgets('renders persona section', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Persona'), findsOneWidget);
    });

    testWidgets('renders conventions section', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Conventions'), findsOneWidget);
    });

    testWidgets('renders project documents section', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Project Documents'), findsOneWidget);
    });

    testWidgets('renders ecosystem context section', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Ecosystem Context'), findsOneWidget);
    });

    testWidgets('renders secret references section', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Secret References'), findsOneWidget);
    });

    testWidgets('renders team directives section', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Team Directives'), findsOneWidget);
    });

    testWidgets('renders recent sessions section', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Recent Sessions'), findsOneWidget);
    });

    testWidgets('renders payload size stats', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('424 B'), findsOneWidget);
      expect(find.text('~106 tokens'), findsOneWidget);
      expect(find.text('9 sections'), findsOneWidget);
    });
  });
}
