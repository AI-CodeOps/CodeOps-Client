import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'package:codeops/widgets/vcs/repo_status_bar.dart';
import 'package:codeops/models/vcs_models.dart';
import 'package:codeops/providers/github_providers.dart';
import 'package:codeops/services/vcs/git_service.dart';

class MockGitService extends Mock implements GitService {}

void main() {
  late MockGitService mockGitService;

  setUp(() {
    mockGitService = MockGitService();
  });

  Widget wrap(Widget child, {List<Override>? overrides}) {
    return ProviderScope(
      overrides: overrides ?? [],
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }

  group('RepoStatusBar', () {
    testWidgets('renders branch name', (tester) async {
      await tester.pumpWidget(wrap(
        const RepoStatusBar(
          status: RepoStatus(branch: 'feature/auth'),
          repoDir: '/tmp/repo',
        ),
        overrides: [
          gitServiceProvider.overrideWith((ref) => mockGitService),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('feature/auth'), findsOneWidget);
    });

    testWidgets('shows "Clean" for clean status', (tester) async {
      await tester.pumpWidget(wrap(
        const RepoStatusBar(
          status: RepoStatus(branch: 'main', changes: []),
          repoDir: '/tmp/repo',
        ),
        overrides: [
          gitServiceProvider.overrideWith((ref) => mockGitService),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Clean'), findsOneWidget);
    });

    testWidgets('shows change count for dirty status', (tester) async {
      await tester.pumpWidget(wrap(
        const RepoStatusBar(
          status: RepoStatus(
            branch: 'main',
            changes: [
              FileChange(path: 'a.dart', type: FileChangeType.modified),
              FileChange(path: 'b.dart', type: FileChangeType.added),
              FileChange(path: 'c.dart', type: FileChangeType.deleted),
            ],
          ),
          repoDir: '/tmp/repo',
        ),
        overrides: [
          gitServiceProvider.overrideWith((ref) => mockGitService),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('3 changes'), findsOneWidget);
    });

    testWidgets('shows ahead/behind counts', (tester) async {
      await tester.pumpWidget(wrap(
        const RepoStatusBar(
          status: RepoStatus(
            branch: 'main',
            ahead: 2,
            behind: 5,
          ),
          repoDir: '/tmp/repo',
        ),
        overrides: [
          gitServiceProvider.overrideWith((ref) => mockGitService),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('2'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_upward), findsWidgets);
      expect(find.byIcon(Icons.arrow_downward), findsWidgets);
    });

    testWidgets('has Fetch/Pull/Push buttons', (tester) async {
      await tester.pumpWidget(wrap(
        const RepoStatusBar(
          status: RepoStatus(branch: 'main', ahead: 1),
          repoDir: '/tmp/repo',
        ),
        overrides: [
          gitServiceProvider.overrideWith((ref) => mockGitService),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Fetch'), findsOneWidget);
      expect(find.text('Pull'), findsOneWidget);
      expect(find.text('Push'), findsOneWidget);
    });
  });
}
