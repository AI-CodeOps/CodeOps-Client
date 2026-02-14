import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/providers/wizard_providers.dart';
import 'package:codeops/widgets/wizard/jira_ticket_step.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
        home: Scaffold(
          body: SizedBox(height: 800, child: child),
        ),
      );

  group('JiraTicketStep', () {
    testWidgets('shows title', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrap(
        JiraTicketStep(
          onFetchTicket: (_) {},
          onContextChanged: (_) {},
        ),
      ));

      expect(find.text('Jira Ticket'), findsOneWidget);
    });

    testWidgets('shows subtitle text', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrap(
        JiraTicketStep(
          onFetchTicket: (_) {},
          onContextChanged: (_) {},
        ),
      ));

      expect(find.text('Enter a Jira ticket key to investigate.'),
          findsOneWidget);
    });

    testWidgets('shows Fetch button', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrap(
        JiraTicketStep(
          onFetchTicket: (_) {},
          onContextChanged: (_) {},
        ),
      ));

      expect(find.text('Fetch'), findsOneWidget);
    });

    testWidgets('shows Fetching... when isFetching', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrap(
        JiraTicketStep(
          onFetchTicket: (_) {},
          onContextChanged: (_) {},
          isFetching: true,
        ),
      ));

      expect(find.text('Fetching...'), findsOneWidget);
    });

    testWidgets('shows error message', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrap(
        JiraTicketStep(
          onFetchTicket: (_) {},
          onContextChanged: (_) {},
          fetchError: 'Ticket not found',
        ),
      ));

      expect(find.text('Ticket not found'), findsOneWidget);
    });

    testWidgets('shows ticket detail card when ticket provided',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const ticket = JiraTicketData(
        key: 'PROJ-123',
        summary: 'Fix login bug',
        description: 'Users cannot log in',
        status: 'Open',
        priority: 'High',
        assignee: 'John Doe',
        commentCount: 3,
        attachmentCount: 1,
        linkedIssueCount: 2,
      );

      await tester.pumpWidget(wrap(
        JiraTicketStep(
          ticketData: ticket,
          onFetchTicket: (_) {},
          onContextChanged: (_) {},
        ),
      ));

      expect(find.text('PROJ-123'), findsOneWidget);
      expect(find.text('Fix login bug'), findsOneWidget);
      expect(find.text('Users cannot log in'), findsOneWidget);
      expect(find.text('Open'), findsOneWidget);
      expect(find.text('High'), findsOneWidget);
    });

    testWidgets('shows Additional Context section', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrap(
        JiraTicketStep(
          onFetchTicket: (_) {},
          onContextChanged: (_) {},
        ),
      ));

      expect(find.text('Additional Context'), findsOneWidget);
    });
  });
}
