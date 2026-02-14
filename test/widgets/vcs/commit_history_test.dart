import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:codeops/widgets/vcs/commit_history.dart';
import 'package:codeops/providers/github_providers.dart';
import 'package:codeops/models/vcs_models.dart';

void main() {
  Widget wrap(Widget child, {List<Override>? overrides}) {
    return ProviderScope(
      overrides: overrides ?? [],
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }

  group('CommitHistory', () {
    testWidgets('renders loading state', (tester) async {
      await tester.pumpWidget(wrap(
        const CommitHistory(repoFullName: 'acme/rocket'),
        overrides: [
          repoCommitsProvider.overrideWith(
            (ref, fullName) => Completer<List<VcsCommit>>().future,
          ),
        ],
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders commits with short SHA and message', (tester) async {
      await tester.pumpWidget(wrap(
        const CommitHistory(repoFullName: 'acme/rocket'),
        overrides: [
          repoCommitsProvider.overrideWith(
            (ref, fullName) async => [
              const VcsCommit(
                sha: 'abc1234567890def',
                message: 'Fix login bug',
                authorName: 'Alice',
              ),
              const VcsCommit(
                sha: 'def5678901234abc',
                message: 'Add tests',
                authorName: 'Bob',
              ),
            ],
          ),
        ],
      ));
      await tester.pumpAndSettle();

      // Short SHA (first 7 chars).
      expect(find.text('abc1234'), findsOneWidget);
      expect(find.text('def5678'), findsOneWidget);
      // Messages.
      expect(find.text('Fix login bug'), findsOneWidget);
      expect(find.text('Add tests'), findsOneWidget);
    });
  });
}
