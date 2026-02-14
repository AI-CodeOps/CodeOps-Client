import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:codeops/widgets/vcs/diff_viewer.dart';
import 'package:codeops/models/vcs_models.dart';

void main() {
  Widget wrap(Widget child, {List<Override>? overrides}) {
    return ProviderScope(
      overrides: overrides ?? [],
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }

  group('DiffViewer', () {
    testWidgets('renders empty message for no diffs', (tester) async {
      await tester.pumpWidget(wrap(
        const DiffViewer(diffs: []),
      ));
      await tester.pumpAndSettle();

      expect(find.text('No changes to display'), findsOneWidget);
    });

    testWidgets('renders file path', (tester) async {
      await tester.pumpWidget(wrap(
        const DiffViewer(diffs: [
          DiffResult(
            filePath: 'lib/app.dart',
            additions: 2,
            deletions: 1,
            hunks: [
              DiffHunk(
                header: '@@ -1,3 +1,4 @@',
                oldStart: 1,
                oldCount: 3,
                newStart: 1,
                newCount: 4,
                lines: [
                  DiffLine(
                    content: 'import "dart:io";',
                    type: DiffLineType.context,
                    oldLineNumber: 1,
                    newLineNumber: 1,
                  ),
                  DiffLine(
                    content: 'old line',
                    type: DiffLineType.deletion,
                    oldLineNumber: 2,
                  ),
                  DiffLine(
                    content: 'new line',
                    type: DiffLineType.addition,
                    newLineNumber: 2,
                  ),
                  DiffLine(
                    content: 'another new line',
                    type: DiffLineType.addition,
                    newLineNumber: 3,
                  ),
                ],
              ),
            ],
          ),
        ]),
      ));
      await tester.pumpAndSettle();

      expect(find.text('lib/app.dart'), findsOneWidget);
    });

    testWidgets('renders green additions (line with + prefix)',
        (tester) async {
      await tester.pumpWidget(wrap(
        const DiffViewer(diffs: [
          DiffResult(
            filePath: 'file.dart',
            additions: 1,
            deletions: 0,
            hunks: [
              DiffHunk(
                header: '@@ -1,1 +1,2 @@',
                oldStart: 1,
                oldCount: 1,
                newStart: 1,
                newCount: 2,
                lines: [
                  DiffLine(
                    content: 'added content',
                    type: DiffLineType.addition,
                    newLineNumber: 2,
                  ),
                ],
              ),
            ],
          ),
        ]),
      ));
      await tester.pumpAndSettle();

      // The '+' prefix is rendered.
      expect(find.text('+'), findsOneWidget);
      expect(find.text('added content'), findsOneWidget);
    });

    testWidgets('renders red deletions (line with - prefix)', (tester) async {
      await tester.pumpWidget(wrap(
        const DiffViewer(diffs: [
          DiffResult(
            filePath: 'file.dart',
            additions: 0,
            deletions: 1,
            hunks: [
              DiffHunk(
                header: '@@ -1,2 +1,1 @@',
                oldStart: 1,
                oldCount: 2,
                newStart: 1,
                newCount: 1,
                lines: [
                  DiffLine(
                    content: 'removed content',
                    type: DiffLineType.deletion,
                    oldLineNumber: 2,
                  ),
                ],
              ),
            ],
          ),
        ]),
      ));
      await tester.pumpAndSettle();

      // The '-' prefix is rendered.
      expect(find.text('-'), findsOneWidget);
      expect(find.text('removed content'), findsOneWidget);
    });

    testWidgets('renders line numbers', (tester) async {
      await tester.pumpWidget(wrap(
        const DiffViewer(diffs: [
          DiffResult(
            filePath: 'file.dart',
            additions: 1,
            deletions: 1,
            hunks: [
              DiffHunk(
                header: '@@ -5,1 +5,1 @@',
                oldStart: 5,
                oldCount: 1,
                newStart: 5,
                newCount: 1,
                lines: [
                  DiffLine(
                    content: 'old',
                    type: DiffLineType.deletion,
                    oldLineNumber: 5,
                  ),
                  DiffLine(
                    content: 'new',
                    type: DiffLineType.addition,
                    newLineNumber: 5,
                  ),
                ],
              ),
            ],
          ),
        ]),
      ));
      await tester.pumpAndSettle();

      // Line number '5' should appear for both old and new.
      expect(find.text('5'), findsWidgets);
    });
  });
}
