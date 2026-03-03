// Widget tests for context section health indicators.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/pages/mcp/context_viewer_page.dart';
import 'package:codeops/providers/mcp_context_providers.dart';
import 'package:codeops/providers/mcp_providers.dart';
import 'package:codeops/providers/project_providers.dart';
import 'package:codeops/providers/team_providers.dart'
    show selectedTeamIdProvider;
import 'package:codeops/theme/colors.dart';

void main() {
  Widget createWidget(List<ContextSection> sections) {
    final assembled = AssembledContext(
      sections: sections,
      totalSizeBytes: 100,
      estimatedTokens: 25,
      payload: {},
    );

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

  group('Context health indicators', () {
    testWidgets('renders green dot for healthy section', (tester) async {
      await tester.pumpWidget(createWidget([
        ContextSection(
          title: 'Persona',
          health: ContextSectionHealth.healthy,
          data: {'test': true},
          itemCount: 1,
          sizeBytes: 10,
        ),
      ]));
      await tester.pumpAndSettle();

      // Find the health indicator dot (10x10 circle)
      final dot = tester.widgetList<Container>(
        find.byWidgetPredicate((w) =>
            w is Container &&
            w.decoration is BoxDecoration &&
            (w.decoration as BoxDecoration).shape == BoxShape.circle &&
            (w.decoration as BoxDecoration).color == CodeOpsColors.success),
      );
      expect(dot, isNotEmpty);
    });

    testWidgets('renders amber dot for stale section', (tester) async {
      await tester.pumpWidget(createWidget([
        ContextSection(
          title: 'Conventions',
          health: ContextSectionHealth.stale,
          data: {'test': true},
          itemCount: 1,
          sizeBytes: 10,
        ),
      ]));
      await tester.pumpAndSettle();

      final dot = tester.widgetList<Container>(
        find.byWidgetPredicate((w) =>
            w is Container &&
            w.decoration is BoxDecoration &&
            (w.decoration as BoxDecoration).shape == BoxShape.circle &&
            (w.decoration as BoxDecoration).color == CodeOpsColors.warning),
      );
      expect(dot, isNotEmpty);
    });

    testWidgets('renders red dot for missing section', (tester) async {
      await tester.pumpWidget(createWidget([
        ContextSection(
          title: 'Team Directives',
          health: ContextSectionHealth.missing,
          data: {'test': true},
          itemCount: 0,
          sizeBytes: 10,
        ),
      ]));
      await tester.pumpAndSettle();

      final dot = tester.widgetList<Container>(
        find.byWidgetPredicate((w) =>
            w is Container &&
            w.decoration is BoxDecoration &&
            (w.decoration as BoxDecoration).shape == BoxShape.circle &&
            (w.decoration as BoxDecoration).color == CodeOpsColors.error),
      );
      expect(dot, isNotEmpty);
    });
  });
}
