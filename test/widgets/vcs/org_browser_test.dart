import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:codeops/widgets/vcs/org_browser.dart';
import 'package:codeops/providers/github_providers.dart';
import 'package:codeops/models/vcs_models.dart';

void main() {
  Widget wrap(Widget child, {List<Override>? overrides}) {
    return ProviderScope(
      overrides: overrides ?? [],
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }

  group('OrgBrowser', () {
    testWidgets('renders loading state', (tester) async {
      await tester.pumpWidget(wrap(
        const OrgBrowser(),
        overrides: [
          githubOrgsProvider.overrideWith(
            (ref) => Completer<List<VcsOrganization>>().future,
          ),
        ],
      ));

      // Should show a loading indicator while the future is incomplete.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders org list with mock data', (tester) async {
      await tester.pumpWidget(wrap(
        const OrgBrowser(),
        overrides: [
          githubOrgsProvider.overrideWith(
            (ref) async => [
              const VcsOrganization(login: 'acme', name: 'Acme Corp'),
              const VcsOrganization(login: 'globex', name: 'Globex Inc'),
            ],
          ),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Acme Corp'), findsOneWidget);
      expect(find.text('Globex Inc'), findsOneWidget);
    });

    testWidgets('selection updates provider', (tester) async {
      late WidgetRef capturedRef;

      await tester.pumpWidget(ProviderScope(
        overrides: [
          githubOrgsProvider.overrideWith(
            (ref) async => [
              const VcsOrganization(login: 'acme', name: 'Acme Corp'),
            ],
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) {
                capturedRef = ref;
                return const OrgBrowser();
              },
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Tap on the org tile.
      await tester.tap(find.text('Acme Corp'));
      await tester.pumpAndSettle();

      expect(capturedRef.read(selectedOrgProvider), equals('acme'));
    });
  });
}
