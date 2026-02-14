import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:codeops/widgets/vcs/repo_browser.dart';
import 'package:codeops/providers/github_providers.dart';
import 'package:codeops/models/vcs_models.dart';

void main() {
  Widget wrap(Widget child, {List<Override>? overrides}) {
    return ProviderScope(
      overrides: overrides ?? [],
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }

  group('RepoBrowser', () {
    testWidgets('shows "Select an Organization" when no org selected',
        (tester) async {
      await tester.pumpWidget(wrap(
        const RepoBrowser(),
        overrides: [
          selectedOrgProvider.overrideWith((ref) => null),
          clonedReposProvider.overrideWith((ref) async => <String, String>{}),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Select an Organization'), findsOneWidget);
    });

    testWidgets('renders repo cards when org selected with mock data',
        (tester) async {
      await tester.pumpWidget(wrap(
        const RepoBrowser(),
        overrides: [
          selectedOrgProvider.overrideWith((ref) => 'acme'),
          orgReposProvider.overrideWith(
            (ref, org) async => [
              const VcsRepository(
                id: 1,
                fullName: 'acme/widget',
                name: 'widget',
                description: 'A widget library',
                language: 'Dart',
                stargazersCount: 42,
                forksCount: 5,
              ),
              const VcsRepository(
                id: 2,
                fullName: 'acme/server',
                name: 'server',
                language: 'Java',
              ),
            ],
          ),
          clonedReposProvider.overrideWith((ref) async => <String, String>{}),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('widget'), findsOneWidget);
      expect(find.text('server'), findsOneWidget);
      expect(find.text('A widget library'), findsOneWidget);
      expect(find.text('Dart'), findsOneWidget);
    });
  });
}
