import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'package:codeops/widgets/vcs/clone_dialog.dart';
import 'package:codeops/models/vcs_models.dart';
import 'package:codeops/providers/github_providers.dart';
import 'package:codeops/services/vcs/repo_manager.dart';

class MockRepoManager extends Mock implements RepoManager {}

void main() {
  const testRepo = VcsRepository(
    id: 99,
    fullName: 'acme/rocket',
    name: 'rocket',
    defaultBranch: 'main',
    cloneUrl: 'https://github.com/acme/rocket.git',
  );

  late MockRepoManager mockRepoManager;

  setUp(() {
    mockRepoManager = MockRepoManager();
    when(() => mockRepoManager.getRepoPath(any()))
        .thenReturn('/tmp/repos/acme/rocket');
  });

  Widget wrap(Widget child, {List<Override>? overrides}) {
    return ProviderScope(
      overrides: overrides ?? [],
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }

  group('CloneDialog', () {
    testWidgets('renders repo name in title', (tester) async {
      await tester.pumpWidget(wrap(
        const CloneDialog(repo: testRepo),
        overrides: [
          repoManagerProvider.overrideWith((ref) => mockRepoManager),
          repoBranchesProvider.overrideWith(
            (ref, fullName) async => [
              const VcsBranch(name: 'main'),
              const VcsBranch(name: 'develop'),
            ],
          ),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Clone rocket'), findsOneWidget);
    });

    testWidgets('shows branch selector', (tester) async {
      await tester.pumpWidget(wrap(
        const CloneDialog(repo: testRepo),
        overrides: [
          repoManagerProvider.overrideWith((ref) => mockRepoManager),
          repoBranchesProvider.overrideWith(
            (ref, fullName) async => [
              const VcsBranch(name: 'main'),
              const VcsBranch(name: 'develop'),
            ],
          ),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Branch'), findsOneWidget);
      // The dropdown should show 'main' as the selected value.
      expect(find.text('main'), findsWidgets);
    });

    testWidgets('shows target directory input', (tester) async {
      await tester.pumpWidget(wrap(
        const CloneDialog(repo: testRepo),
        overrides: [
          repoManagerProvider.overrideWith((ref) => mockRepoManager),
          repoBranchesProvider.overrideWith(
            (ref, fullName) async => [const VcsBranch(name: 'main')],
          ),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Target Directory'), findsOneWidget);
      expect(find.text('/tmp/repos/acme/rocket'), findsOneWidget);
    });

    testWidgets('shows Clone button', (tester) async {
      await tester.pumpWidget(wrap(
        const CloneDialog(repo: testRepo),
        overrides: [
          repoManagerProvider.overrideWith((ref) => mockRepoManager),
          repoBranchesProvider.overrideWith(
            (ref, fullName) async => [const VcsBranch(name: 'main')],
          ),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Clone'), findsOneWidget);
    });
  });
}
