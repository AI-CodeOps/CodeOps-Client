import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:codeops/widgets/vcs/github_auth_dialog.dart';

void main() {
  Widget wrap(Widget child, {List<Override>? overrides}) {
    return ProviderScope(
      overrides: overrides ?? [],
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }

  group('GitHubAuthDialog', () {
    testWidgets('renders title "Connect GitHub"', (tester) async {
      await tester.pumpWidget(wrap(const GitHubAuthDialog()));
      await tester.pumpAndSettle();

      expect(find.text('Connect GitHub'), findsOneWidget);
    });

    testWidgets('shows token input field', (tester) async {
      await tester.pumpWidget(wrap(const GitHubAuthDialog()));
      await tester.pumpAndSettle();

      expect(find.text('Personal Access Token'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('shows "Test & Save" button', (tester) async {
      await tester.pumpWidget(wrap(const GitHubAuthDialog()));
      await tester.pumpAndSettle();

      expect(find.text('Test & Save'), findsOneWidget);
    });

    testWidgets('shows "Cancel" button', (tester) async {
      await tester.pumpWidget(wrap(const GitHubAuthDialog()));
      await tester.pumpAndSettle();

      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('empty token shows error on tap', (tester) async {
      await tester.pumpWidget(wrap(const GitHubAuthDialog()));
      await tester.pumpAndSettle();

      // Tap "Test & Save" with empty field.
      await tester.tap(find.text('Test & Save'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a token'), findsOneWidget);
    });
  });
}
