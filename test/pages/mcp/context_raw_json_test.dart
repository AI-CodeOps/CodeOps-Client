// Widget tests for context viewer raw JSON toggle.
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
  final assembled = AssembledContext(
    sections: [
      ContextSection(
        title: 'Persona',
        health: ContextSectionHealth.healthy,
        data: {'agentType': 'claude', 'developer': 'Adam'},
        itemCount: 1,
        sizeBytes: 48,
      ),
    ],
    totalSizeBytes: 48,
    estimatedTokens: 12,
    payload: {
      'persona': {'agentType': 'claude', 'developer': 'Adam'},
    },
  );

  Widget createWidget({bool rawJson = false}) {
    return ProviderScope(
      overrides: [
        selectedTeamIdProvider.overrideWith((ref) => 'team-1'),
        teamProjectsProvider.overrideWith((ref) => Future.value([])),
        mcpTeamProfilesProvider
            .overrideWith((ref, id) => Future.value([])),
        contextSimulatedProvider.overrideWith((ref) => true),
        contextRawJsonProvider.overrideWith((ref) => rawJson),
        contextAssemblyProvider
            .overrideWith((ref) => Future.value(assembled)),
      ],
      child: const MaterialApp(
        home: Scaffold(body: ContextViewerPage()),
      ),
    );
  }

  group('Raw JSON view', () {
    testWidgets('renders Raw JSON toggle chip', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Raw JSON'), findsOneWidget);
    });

    testWidgets('renders structured view by default', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Should show accordion sections, not raw JSON
      expect(find.text('Persona'), findsOneWidget);
    });

    testWidgets('renders copy button', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.copy), findsOneWidget);
    });

    testWidgets('shows Structured label when raw JSON enabled',
        (tester) async {
      await tester.pumpWidget(createWidget(rawJson: true));
      await tester.pumpAndSettle();

      // When rawJson is true, chip label shows "Structured"
      expect(find.text('Structured'), findsOneWidget);
    });
  });
}
