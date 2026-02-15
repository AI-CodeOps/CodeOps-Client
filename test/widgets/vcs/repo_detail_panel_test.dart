// Tests for the RepoDetailPanel widget.
//
// Verifies empty state, repo header, README tab, clone/open button,
// and tab switching with mocked Riverpod providers.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/vcs_models.dart';
import 'package:codeops/providers/github_providers.dart';
import 'package:codeops/widgets/vcs/repo_detail_panel.dart';

const _testRepo = VcsRepository(
  id: 1,
  fullName: 'acme/widget',
  name: 'widget',
  description: 'A widget library',
  language: 'Dart',
  stargazersCount: 100,
  forksCount: 25,
  defaultBranch: 'main',
  isPrivate: false,
  ownerLogin: 'acme',
  htmlUrl: 'https://github.com/acme/widget',
);

Widget _wrap(Widget child, {List<Override>? overrides}) {
  return ProviderScope(
    overrides: overrides ?? [],
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

/// Default overrides that provide data for all detail panel tabs.
List<Override> _defaultOverrides({VcsRepository? repo}) => [
      selectedGithubRepoProvider.overrideWith((ref) => repo),
      githubReadmeProvider.overrideWith((ref) async => '# Hello\n\nWorld'),
      githubRepoBranchesProvider.overrideWith((ref) async => [
            const VcsBranch(name: 'main', sha: 'abc1234', isProtected: true),
            const VcsBranch(name: 'develop', sha: 'def5678'),
          ]),
      githubRepoPullRequestsProvider.overrideWith((ref) async => [
            const VcsPullRequest(
              number: 42,
              title: 'Fix stuff',
              state: 'open',
              headBranch: 'fix',
              baseBranch: 'main',
              authorLogin: 'alice',
            ),
          ]),
      githubRepoCommitsProvider.overrideWith((ref) async => [
            const VcsCommit(
              sha: 'abc1234567890',
              message: 'Initial commit',
              authorName: 'Alice',
            ),
          ]),
      isRepoClonedProvider.overrideWith((ref) async => false),
      clonedReposProvider.overrideWith((ref) async => <String, String>{}),
    ];

void main() {
  group('RepoDetailPanel', () {
    testWidgets('shows empty state when no repo selected', (tester) async {
      await tester.pumpWidget(_wrap(
        const RepoDetailPanel(),
        overrides: _defaultOverrides(repo: null),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Select a repository'), findsOneWidget);
    });

    testWidgets('shows repo header with name, description, metadata',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const RepoDetailPanel(),
        overrides: _defaultOverrides(repo: _testRepo),
      ));
      await tester.pumpAndSettle();

      // Title.
      expect(find.text('acme / widget'), findsOneWidget);
      // Description.
      expect(find.text('A widget library'), findsOneWidget);
      // Metadata chips.
      expect(find.text('Dart'), findsOneWidget);
      expect(find.text('100'), findsOneWidget);
      expect(find.text('25'), findsOneWidget);
      expect(find.text('Public'), findsOneWidget);
      expect(find.text('main'), findsAny);
    });

    testWidgets('README tab renders markdown content', (tester) async {
      await tester.pumpWidget(_wrap(
        const RepoDetailPanel(),
        overrides: _defaultOverrides(repo: _testRepo),
      ));
      await tester.pumpAndSettle();

      // The README tab is visible by default (index 0).
      expect(find.text('Hello'), findsOneWidget);
      expect(find.text('World'), findsOneWidget);
    });

    testWidgets('Clone button shows when repo not cloned', (tester) async {
      await tester.pumpWidget(_wrap(
        const RepoDetailPanel(),
        overrides: _defaultOverrides(repo: _testRepo),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Clone'), findsOneWidget);
    });

    testWidgets('Open button shows when repo is cloned', (tester) async {
      final overrides = [
        selectedGithubRepoProvider.overrideWith((ref) => _testRepo),
        githubReadmeProvider.overrideWith((ref) async => '# Hello'),
        githubRepoBranchesProvider.overrideWith((ref) async => <VcsBranch>[]),
        githubRepoPullRequestsProvider
            .overrideWith((ref) async => <VcsPullRequest>[]),
        githubRepoCommitsProvider.overrideWith((ref) async => <VcsCommit>[]),
        isRepoClonedProvider.overrideWith((ref) async => true),
        clonedReposProvider
            .overrideWith((ref) async => {'acme/widget': '/tmp/widget'}),
      ];

      await tester.pumpWidget(_wrap(
        const RepoDetailPanel(),
        overrides: overrides,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Open in Finder'), findsOneWidget);
    });

    testWidgets('tab switching works — tap Branches tab shows branches',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const RepoDetailPanel(),
        overrides: _defaultOverrides(repo: _testRepo),
      ));
      await tester.pumpAndSettle();

      // Tap Branches tab.
      await tester.tap(find.textContaining('Branches'));
      await tester.pumpAndSettle();

      // Should show branch names.
      expect(find.text('main'), findsAny);
      expect(find.text('develop'), findsOneWidget);
    });
  });
}
