// Widget tests for ContextViewerPage.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/mcp_models.dart';
import 'package:codeops/models/project.dart';
import 'package:codeops/pages/mcp/context_viewer_page.dart';
import 'package:codeops/providers/mcp_providers.dart';
import 'package:codeops/providers/project_providers.dart';
import 'package:codeops/providers/team_providers.dart'
    show selectedTeamIdProvider;

void main() {
  const teamId = 'team-1';

  final projects = [
    Project(id: 'proj-1', teamId: teamId, name: 'CodeOps-Server'),
    Project(id: 'proj-2', teamId: teamId, name: 'CodeOps-Client'),
  ];

  final profiles = [
    DeveloperProfile(
      id: 'dev-1',
      displayName: 'Adam',
      userId: 'user-1',
    ),
    DeveloperProfile(
      id: 'dev-2',
      displayName: 'Claude',
      userId: 'user-2',
    ),
  ];

  Widget createWidget({
    bool hasTeam = true,
    bool projectsLoading = false,
    bool profilesLoading = false,
  }) {
    return ProviderScope(
      overrides: [
        if (hasTeam)
          selectedTeamIdProvider.overrideWith((ref) => teamId),
        if (!hasTeam)
          selectedTeamIdProvider.overrideWith((ref) => null),
        teamProjectsProvider.overrideWith((ref) {
          if (projectsLoading) {
            return Completer<List<Project>>().future;
          }
          return Future.value(projects);
        }),
        mcpTeamProfilesProvider.overrideWith((ref, id) {
          if (profilesLoading) {
            return Completer<List<DeveloperProfile>>().future;
          }
          return Future.value(profiles);
        }),
      ],
      child: const MaterialApp(
        home: Scaffold(body: ContextViewerPage()),
      ),
    );
  }

  group('ContextViewerPage', () {
    testWidgets('renders header with breadcrumb', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Context Viewer'), findsOneWidget);
      expect(
        find.text('Preview what an AI agent receives on session init'),
        findsOneWidget,
      );
    });

    testWidgets('renders no team state', (tester) async {
      await tester.pumpWidget(createWidget(hasTeam: false));
      await tester.pumpAndSettle();

      expect(find.text('No team selected'), findsOneWidget);
    });

    testWidgets('renders project selector with options', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Project'), findsOneWidget);
      expect(find.text('Select Project'), findsOneWidget);
    });

    testWidgets('renders developer selector with options', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Developer Profile'), findsOneWidget);
      expect(find.text('Select Developer'), findsOneWidget);
    });

    testWidgets('renders environment selector', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Environment'), findsOneWidget);
      expect(find.text('Local'), findsOneWidget);
    });

    testWidgets('renders simulate button disabled initially', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Simulate Session Init'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('renders pre-simulation prompt', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Select a project and click "Simulate Session Init" to preview context',
        ),
        findsOneWidget,
      );
    });
  });
}
