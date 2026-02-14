// Widget tests for GitHubBrowserPage.
//
// Verifies unauthenticated view, authenticated layout, connection
// selector, and "Create Project from Repo" dialog.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/enums.dart';
import 'package:codeops/models/health_snapshot.dart';
import 'package:codeops/pages/github_browser_page.dart';
import 'package:codeops/providers/github_providers.dart';
import 'package:codeops/providers/project_providers.dart';

void main() {
  Widget createUnauthenticatedWidget() {
    return ProviderScope(
      overrides: [
        vcsAuthenticatedProvider.overrideWith((ref) => false),
      ],
      child: const MaterialApp(home: Scaffold(body: GitHubBrowserPage())),
    );
  }

  Widget createAuthenticatedWidget({
    List<Override> overrides = const [],
    List<GitHubConnection> connections = const [],
  }) {
    return ProviderScope(
      overrides: [
        vcsAuthenticatedProvider.overrideWith((ref) => true),
        selectedRepoProvider.overrideWith((ref) => null),
        clonedReposProvider
            .overrideWith((ref) => Future.value(<String, String>{})),
        selectedRepoStatusProvider
            .overrideWith((ref) => Future.value(null)),
        githubConnectionsProvider
            .overrideWith((ref) => Future.value(connections)),
        jiraConnectionsProvider
            .overrideWith((ref) => Future.value(<JiraConnection>[])),
        ...overrides,
      ],
      child: const MaterialApp(home: Scaffold(body: GitHubBrowserPage())),
    );
  }

  group('GitHubBrowserPage - unauthenticated', () {
    testWidgets('shows Connect GitHub button', (tester) async {
      await tester.pumpWidget(createUnauthenticatedWidget());
      await tester.pumpAndSettle();

      expect(find.text('Connect GitHub'), findsAtLeastNWidgets(1));
    });
  });

  group('GitHubBrowserPage - authenticated', () {
    testWidgets('shows GitHub sidebar header', (tester) async {
      await tester.pumpWidget(createAuthenticatedWidget());
      await tester.pumpAndSettle();

      expect(find.text('GitHub'), findsOneWidget);
    });

    testWidgets('shows search toggle icon', (tester) async {
      await tester.pumpWidget(createAuthenticatedWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('hides connection selector when single connection',
        (tester) async {
      await tester.pumpWidget(createAuthenticatedWidget(
        connections: [
          const GitHubConnection(
            id: 'conn-1',
            name: 'My GitHub',
            teamId: 'team-1',
            authType: GitHubAuthType.pat,
          ),
        ],
      ));
      await tester.pumpAndSettle();

      // Single connection = no dropdown
      expect(find.byType(DropdownButton<String>), findsNothing);
    });

    testWidgets('shows connection selector when multiple connections',
        (tester) async {
      await tester.pumpWidget(createAuthenticatedWidget(
        connections: [
          const GitHubConnection(
            id: 'conn-1',
            name: 'Personal',
            teamId: 'team-1',
            authType: GitHubAuthType.pat,
          ),
          const GitHubConnection(
            id: 'conn-2',
            name: 'Work',
            teamId: 'team-1',
            authType: GitHubAuthType.oauth,
          ),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.byType(DropdownButton<String>), findsOneWidget);
    });
  });
}
