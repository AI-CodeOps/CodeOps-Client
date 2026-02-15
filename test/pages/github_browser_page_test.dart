// Widget tests for GitHubBrowserPage.
//
// Verifies unauthenticated view and the master-detail layout when
// authenticated (RepoSidebar on left, RepoDetailPanel on right).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/vcs_models.dart';
import 'package:codeops/pages/github_browser_page.dart';
import 'package:codeops/providers/github_providers.dart';
import 'package:codeops/widgets/vcs/repo_detail_panel.dart';
import 'package:codeops/widgets/vcs/repo_sidebar.dart';

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
  }) {
    return ProviderScope(
      overrides: [
        vcsAuthenticatedProvider.overrideWith((ref) => true),
        githubOrgsProvider
            .overrideWith((ref) async => <VcsOrganization>[]),
        githubReposForOrgProvider
            .overrideWith((ref) async => <VcsRepository>[]),
        selectedGithubRepoProvider.overrideWith((ref) => null),
        githubReadmeProvider.overrideWith((ref) async => null),
        githubRepoBranchesProvider
            .overrideWith((ref) async => <VcsBranch>[]),
        githubRepoPullRequestsProvider
            .overrideWith((ref) async => <VcsPullRequest>[]),
        githubRepoCommitsProvider
            .overrideWith((ref) async => <VcsCommit>[]),
        isRepoClonedProvider.overrideWith((ref) async => false),
        clonedReposProvider
            .overrideWith((ref) async => <String, String>{}),
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
    testWidgets('shows master-detail layout when authenticated',
        (tester) async {
      await tester.pumpWidget(createAuthenticatedWidget());
      await tester.pumpAndSettle();

      // Left panel: RepoSidebar.
      expect(find.byType(RepoSidebar), findsOneWidget);
      // Right panel: RepoDetailPanel.
      expect(find.byType(RepoDetailPanel), findsOneWidget);
      // Vertical divider between panels.
      expect(find.byType(VerticalDivider), findsOneWidget);
    });

    testWidgets('shows search field in sidebar', (tester) async {
      await tester.pumpWidget(createAuthenticatedWidget());
      await tester.pumpAndSettle();

      // Search field is always visible in the sidebar.
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('shows empty state in detail panel when no repo selected',
        (tester) async {
      await tester.pumpWidget(createAuthenticatedWidget());
      await tester.pumpAndSettle();

      expect(find.text('Select a repository'), findsOneWidget);
    });

    testWidgets('sidebar has 300px width', (tester) async {
      await tester.pumpWidget(createAuthenticatedWidget());
      await tester.pumpAndSettle();

      // Find the SizedBox wrapping RepoSidebar.
      final sizedBox = tester.widget<SizedBox>(
        find.ancestor(
          of: find.byType(RepoSidebar),
          matching: find.byType(SizedBox),
        ).first,
      );
      expect(sizedBox.width, 300);
    });
  });
}
