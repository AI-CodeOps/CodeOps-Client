import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:codeops/widgets/vcs/pull_request_list.dart';
import 'package:codeops/providers/github_providers.dart';
import 'package:codeops/models/vcs_models.dart';

void main() {
  Widget wrap(Widget child, {List<Override>? overrides}) {
    return ProviderScope(
      overrides: overrides ?? [],
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }

  group('PullRequestList', () {
    testWidgets('renders "Pull Requests" header', (tester) async {
      await tester.pumpWidget(wrap(
        const PullRequestList(repoFullName: 'acme/rocket'),
        overrides: [
          repoPullRequestsProvider.overrideWith(
            (ref, fullName) async => <VcsPullRequest>[],
          ),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Pull Requests'), findsOneWidget);
    });

    testWidgets('shows "Create PR" button', (tester) async {
      await tester.pumpWidget(wrap(
        const PullRequestList(repoFullName: 'acme/rocket'),
        overrides: [
          repoPullRequestsProvider.overrideWith(
            (ref, fullName) async => <VcsPullRequest>[],
          ),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Create PR'), findsOneWidget);
    });

    testWidgets('renders PR entries with number and title', (tester) async {
      await tester.pumpWidget(wrap(
        const PullRequestList(repoFullName: 'acme/rocket'),
        overrides: [
          repoPullRequestsProvider.overrideWith(
            (ref, fullName) async => [
              const VcsPullRequest(
                number: 42,
                title: 'Add login feature',
                state: 'open',
                headBranch: 'feature/login',
                baseBranch: 'main',
              ),
              const VcsPullRequest(
                number: 43,
                title: 'Fix tests',
                state: 'open',
                headBranch: 'fix/tests',
                baseBranch: 'main',
              ),
            ],
          ),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('#42 Add login feature'), findsOneWidget);
      expect(find.text('#43 Fix tests'), findsOneWidget);
    });
  });
}
