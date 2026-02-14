// Tests for AssigneePicker widget.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:codeops/models/jira_models.dart';
import 'package:codeops/widgets/jira/assignee_picker.dart';

void main() {
  Widget wrap(Widget child, {List<Override>? overrides}) {
    return ProviderScope(
      overrides: overrides ?? [],
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }

  group('AssigneePicker', () {
    testWidgets('renders "Unassigned" when currentAssignee is null',
        (tester) async {
      await tester.pumpWidget(wrap(
        AssigneePicker(
          currentAssignee: null,
          onUserSelected: (_) {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Unassigned'), findsOneWidget);
    });

    testWidgets('shows search text field', (tester) async {
      await tester.pumpWidget(wrap(
        AssigneePicker(
          currentAssignee: null,
          onUserSelected: (_) {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search users...'), findsOneWidget);
    });

    testWidgets('calls onUserSelected with null for "Unassigned" option',
        (tester) async {
      JiraUser? selectedUser = const JiraUser(accountId: 'placeholder');
      bool wasCalled = false;

      await tester.pumpWidget(wrap(
        AssigneePicker(
          currentAssignee: null,
          onUserSelected: (user) {
            wasCalled = true;
            selectedUser = user;
          },
        ),
      ));
      await tester.pumpAndSettle();

      // Tap the search field to open the dropdown.
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();

      // The dropdown should show an "Unassigned" option.
      // There may be multiple "Unassigned" texts (current display + dropdown).
      final unassignedFinder = find.text('Unassigned');
      expect(unassignedFinder, findsWidgets);

      // Tap the last "Unassigned" text (the one in the dropdown).
      await tester.tap(unassignedFinder.last);
      await tester.pumpAndSettle();

      expect(wasCalled, isTrue);
      expect(selectedUser, isNull);
    });

    testWidgets('AssigneeDisplayMode.compact works', (tester) async {
      await tester.pumpWidget(wrap(
        AssigneePicker(
          currentAssignee: null,
          displayMode: AssigneeDisplayMode.compact,
          onUserSelected: (_) {},
        ),
      ));
      await tester.pumpAndSettle();

      // In compact mode with null assignee, the current assignee display
      // is not shown (only shown in full mode or when assignee is non-null).
      // The search field should still be present.
      expect(find.byType(TextField), findsOneWidget);
    });
  });
}
