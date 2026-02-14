import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'package:codeops/widgets/vcs/stash_manager.dart';
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

  group('StashManager', () {
    testWidgets('renders "Stashes" header', (tester) async {
      when(() => mockGitService.stashList(any()))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(wrap(
        const StashManager(repoDir: '/tmp/repo'),
        overrides: [
          gitServiceProvider.overrideWith((ref) => mockGitService),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Stashes'), findsOneWidget);
    });

    testWidgets('renders "Stash Changes" button', (tester) async {
      when(() => mockGitService.stashList(any()))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(wrap(
        const StashManager(repoDir: '/tmp/repo'),
        overrides: [
          gitServiceProvider.overrideWith((ref) => mockGitService),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Stash Changes'), findsOneWidget);
    });

    testWidgets('shows empty state', (tester) async {
      when(() => mockGitService.stashList(any()))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(wrap(
        const StashManager(repoDir: '/tmp/repo'),
        overrides: [
          gitServiceProvider.overrideWith((ref) => mockGitService),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('No Stashes'), findsOneWidget);
      expect(find.text('Your stash list is empty.'), findsOneWidget);
    });
  });
}
