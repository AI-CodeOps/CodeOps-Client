import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:codeops/widgets/vcs/branch_picker.dart';
import 'package:codeops/providers/github_providers.dart';
import 'package:codeops/models/vcs_models.dart';

void main() {
  Widget wrap(Widget child, {List<Override>? overrides}) {
    return ProviderScope(
      overrides: overrides ?? [],
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }

  group('BranchPicker', () {
    testWidgets('renders current branch chip', (tester) async {
      await tester.pumpWidget(wrap(
        BranchPicker(
          repoFullName: 'acme/rocket',
          currentBranch: 'feature/login',
          onBranchSelected: (_) {},
        ),
        overrides: [
          repoBranchesProvider.overrideWith(
            (ref, fullName) async => [
              const VcsBranch(name: 'main'),
              const VcsBranch(name: 'feature/login'),
            ],
          ),
        ],
      ));
      await tester.pumpAndSettle();

      // The chip should display the current branch name.
      expect(find.text('feature/login'), findsOneWidget);
      expect(find.byType(Chip), findsOneWidget);
    });
  });
}
