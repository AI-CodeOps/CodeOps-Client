import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:codeops/widgets/vcs/commit_dialog.dart';
import 'package:codeops/models/vcs_models.dart';

void main() {
  final testChanges = [
    const FileChange(
      path: 'lib/main.dart',
      type: FileChangeType.modified,
      isStaged: false,
    ),
    const FileChange(
      path: 'lib/new_file.dart',
      type: FileChangeType.added,
      isStaged: false,
    ),
    const FileChange(
      path: 'test/old_test.dart',
      type: FileChangeType.deleted,
      isStaged: false,
    ),
  ];

  Widget wrap(Widget child, {List<Override>? overrides}) {
    return ProviderScope(
      overrides: overrides ?? [],
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }

  group('CommitDialog', () {
    testWidgets('renders file list with checkboxes', (tester) async {
      await tester.pumpWidget(wrap(
        CommitDialog(repoDir: '/tmp/repo', changes: testChanges),
      ));
      await tester.pumpAndSettle();

      expect(find.text('lib/main.dart'), findsOneWidget);
      expect(find.text('lib/new_file.dart'), findsOneWidget);
      expect(find.text('test/old_test.dart'), findsOneWidget);
      // 3 file checkboxes + 1 select-all checkbox + 1 push-after-commit checkbox = 5.
      expect(find.byType(Checkbox), findsNWidgets(5));
    });

    testWidgets('shows commit message input', (tester) async {
      await tester.pumpWidget(wrap(
        CommitDialog(repoDir: '/tmp/repo', changes: testChanges),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Commit message'), findsOneWidget);
      expect(find.text('Describe your changes...'), findsOneWidget);
    });

    testWidgets('empty message shows error', (tester) async {
      await tester.pumpWidget(wrap(
        CommitDialog(repoDir: '/tmp/repo', changes: testChanges),
      ));
      await tester.pumpAndSettle();

      // Tap Commit with empty message.
      await tester.tap(find.text('Commit'));
      await tester.pumpAndSettle();

      expect(find.text('Commit message is required'), findsOneWidget);
    });

    testWidgets('has "Commit" button', (tester) async {
      await tester.pumpWidget(wrap(
        CommitDialog(repoDir: '/tmp/repo', changes: testChanges),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Commit'), findsOneWidget);
    });
  });
}
