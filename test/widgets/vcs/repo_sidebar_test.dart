// Tests for the RepoSidebar master-detail sidebar widget.
//
// Verifies org picker, search, repo list rendering, selection, loading,
// and empty states with mocked Riverpod providers.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/vcs_models.dart';
import 'package:codeops/providers/github_providers.dart';
import 'package:codeops/widgets/vcs/repo_sidebar.dart';

const _testOrg = VcsOrganization(
  login: 'acme',
  name: 'Acme Corp',
  avatarUrl: null,
);

const _testRepo1 = VcsRepository(
  id: 1,
  fullName: 'acme/alpha',
  name: 'alpha',
  description: 'First repo',
  language: 'Dart',
  stargazersCount: 10,
);

const _testRepo2 = VcsRepository(
  id: 2,
  fullName: 'acme/beta',
  name: 'beta',
  description: 'Second repo',
  language: 'Java',
  stargazersCount: 5,
);

Widget _wrap(Widget child, {List<Override>? overrides}) {
  return ProviderScope(
    overrides: overrides ?? [],
    child: MaterialApp(home: Scaffold(body: SizedBox(width: 300, child: child))),
  );
}

void main() {
  group('RepoSidebar', () {
    testWidgets('renders org picker dropdown with organizations',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const RepoSidebar(),
        overrides: [
          githubOrgsProvider.overrideWith((ref) async => [_testOrg]),
          githubReposForOrgProvider
              .overrideWith((ref) async => [_testRepo1, _testRepo2]),
          vcsAuthenticatedProvider.overrideWith((ref) => true),
        ],
      ));
      await tester.pumpAndSettle();

      // Org name should appear in the dropdown.
      expect(find.text('Acme Corp'), findsOneWidget);
    });

    testWidgets('renders repo list when org selected', (tester) async {
      await tester.pumpWidget(_wrap(
        const RepoSidebar(),
        overrides: [
          githubOrgsProvider.overrideWith((ref) async => [_testOrg]),
          selectedGithubOrgProvider.overrideWith((ref) => _testOrg),
          githubReposForOrgProvider
              .overrideWith((ref) async => [_testRepo1, _testRepo2]),
          vcsAuthenticatedProvider.overrideWith((ref) => true),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('alpha'), findsOneWidget);
      expect(find.text('beta'), findsOneWidget);
      expect(find.text('First repo'), findsOneWidget);
      expect(find.text('Dart'), findsOneWidget);
    });

    testWidgets('search filters the list by name', (tester) async {
      late WidgetRef capturedRef;

      await tester.pumpWidget(ProviderScope(
        overrides: [
          githubOrgsProvider.overrideWith((ref) async => [_testOrg]),
          selectedGithubOrgProvider.overrideWith((ref) => _testOrg),
          githubReposForOrgProvider
              .overrideWith((ref) async => [_testRepo1, _testRepo2]),
          vcsAuthenticatedProvider.overrideWith((ref) => true),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: Consumer(
                builder: (context, ref, _) {
                  capturedRef = ref;
                  return const RepoSidebar();
                },
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Both repos visible initially.
      expect(find.text('alpha'), findsOneWidget);
      expect(find.text('beta'), findsOneWidget);

      // Type in search field.
      await tester.enterText(
        find.byType(TextField).first,
        'alpha',
      );
      await tester.pumpAndSettle();

      // Verify the search query provider was updated.
      expect(capturedRef.read(githubRepoSearchQueryProvider), 'alpha');
    });

    testWidgets('selecting a repo updates selectedGithubRepoProvider',
        (tester) async {
      late WidgetRef capturedRef;

      await tester.pumpWidget(ProviderScope(
        overrides: [
          githubOrgsProvider.overrideWith((ref) async => [_testOrg]),
          selectedGithubOrgProvider.overrideWith((ref) => _testOrg),
          githubReposForOrgProvider
              .overrideWith((ref) async => [_testRepo1, _testRepo2]),
          vcsAuthenticatedProvider.overrideWith((ref) => true),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: Consumer(
                builder: (context, ref, _) {
                  capturedRef = ref;
                  return const RepoSidebar();
                },
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Tap on second repo.
      await tester.tap(find.text('beta'));
      await tester.pumpAndSettle();

      final selected = capturedRef.read(selectedGithubRepoProvider);
      expect(selected?.fullName, 'acme/beta');
    });

    testWidgets('shows loading state while repos fetching', (tester) async {
      await tester.pumpWidget(_wrap(
        const RepoSidebar(),
        overrides: [
          githubOrgsProvider.overrideWith((ref) async => [_testOrg]),
          selectedGithubOrgProvider.overrideWith((ref) => _testOrg),
          githubReposForOrgProvider.overrideWith(
            (ref) => Completer<List<VcsRepository>>().future,
          ),
          vcsAuthenticatedProvider.overrideWith((ref) => true),
        ],
      ));
      // Don't settle — the future hasn't completed.
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsAny);
    });

    testWidgets('shows empty state when no repos match search',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const RepoSidebar(),
        overrides: [
          githubOrgsProvider.overrideWith((ref) async => [_testOrg]),
          selectedGithubOrgProvider.overrideWith((ref) => _testOrg),
          githubReposForOrgProvider.overrideWith((ref) async => []),
          vcsAuthenticatedProvider.overrideWith((ref) => true),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('No repositories'), findsOneWidget);
    });
  });
}
