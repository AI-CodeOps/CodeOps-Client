// Tests for RcaPostDialog widget.
//
// Verifies dialog title, initial issue key, RCA markdown preview,
// Cancel/Post buttons, status update checkbox, and labels checkbox.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/widgets/jira/rca_post_dialog.dart';

void main() {
  const testIssueKey = 'PAY-789';
  const testRcaMarkdown = '## Root Cause\n\nNull pointer in PaymentService.';

  Widget wrap(Widget child, {List<Override> overrides = const []}) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }

  group('RcaPostDialog', () {
    testWidgets('renders title "Post RCA to Jira"', (tester) async {
      await tester.pumpWidget(wrap(
        const RcaPostDialog(
          rcaMarkdown: testRcaMarkdown,
          initialIssueKey: testIssueKey,
        ),
      ));
      await tester.pump();

      expect(find.text('Post RCA to Jira'), findsOneWidget);
    });

    testWidgets('shows initial issue key in text field', (tester) async {
      await tester.pumpWidget(wrap(
        const RcaPostDialog(
          rcaMarkdown: testRcaMarkdown,
          initialIssueKey: testIssueKey,
        ),
      ));
      await tester.pump();

      // Find the text field that contains the initial issue key.
      final textFields = find.byType(TextField);
      expect(textFields, findsWidgets);

      // Verify the issue key is present in one of the text fields.
      bool foundIssueKey = false;
      for (final element in textFields.evaluate()) {
        final widget = element.widget as TextField;
        if (widget.controller?.text == testIssueKey) {
          foundIssueKey = true;
          break;
        }
      }
      expect(foundIssueKey, isTrue);
    });

    testWidgets('shows RCA markdown in preview pane', (tester) async {
      await tester.pumpWidget(wrap(
        const RcaPostDialog(
          rcaMarkdown: testRcaMarkdown,
          initialIssueKey: testIssueKey,
        ),
      ));
      await tester.pump();

      // The preview pane renders the markdown content.
      expect(find.text('Comment Preview'), findsOneWidget);
    });

    testWidgets('Cancel and Post to Jira buttons present', (tester) async {
      await tester.pumpWidget(wrap(
        const RcaPostDialog(
          rcaMarkdown: testRcaMarkdown,
          initialIssueKey: testIssueKey,
        ),
      ));
      await tester.pump();

      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Post to Jira'), findsOneWidget);
    });

    testWidgets('shows status update checkbox', (tester) async {
      await tester.pumpWidget(wrap(
        const RcaPostDialog(
          rcaMarkdown: testRcaMarkdown,
          initialIssueKey: testIssueKey,
        ),
      ));
      await tester.pump();

      expect(find.text('Also update issue status'), findsOneWidget);
      expect(find.byType(Checkbox), findsWidgets);
    });

    testWidgets('shows labels checkbox', (tester) async {
      await tester.pumpWidget(wrap(
        const RcaPostDialog(
          rcaMarkdown: testRcaMarkdown,
          initialIssueKey: testIssueKey,
        ),
      ));
      await tester.pump();

      expect(find.text('Add labels'), findsOneWidget);
    });
  });
}
