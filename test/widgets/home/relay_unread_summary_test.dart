// Widget tests for RelayUnreadSummary.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/relay_models.dart';
import 'package:codeops/providers/relay_providers.dart';
import 'package:codeops/providers/team_providers.dart';
import 'package:codeops/widgets/home/relay_unread_summary.dart';

void main() {
  Widget createWidget({
    String? teamId = 'team-1',
    List<UnreadCountResponse>? counts,
  }) {
    final defaultCounts = counts ??
        const [
          UnreadCountResponse(
            channelId: 'ch-1',
            channelName: 'general',
            unreadCount: 3,
          ),
          UnreadCountResponse(
            channelId: 'ch-2',
            channelName: 'project-api',
            unreadCount: 12,
          ),
          UnreadCountResponse(
            channelId: 'ch-3',
            channelName: 'announcements',
            unreadCount: 0,
          ),
        ];

    return ProviderScope(
      overrides: [
        selectedTeamIdProvider.overrideWith((ref) => teamId),
        if (teamId != null)
          unreadCountsProvider(teamId).overrideWith(
            (ref) => Future.value(defaultCounts),
          ),
      ],
      child: const MaterialApp(home: Scaffold(body: RelayUnreadSummary())),
    );
  }

  group('RelayUnreadSummary', () {
    testWidgets('renders Relay Unread title', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Relay Unread'), findsOneWidget);
      expect(find.text('Open Relay'), findsOneWidget);
    });

    testWidgets('shows channels with unread counts', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('general'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('project-api'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      // announcements has 0 unread — should NOT appear.
      expect(find.text('announcements'), findsNothing);
    });

    testWidgets('shows total unread badge', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('15 unread messages'), findsOneWidget);
    });

    testWidgets('shows all caught up when no unread', (tester) async {
      await tester.pumpWidget(createWidget(
        counts: const [
          UnreadCountResponse(
            channelId: 'ch-1',
            channelName: 'general',
            unreadCount: 0,
          ),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('All caught up!'), findsOneWidget);
    });

    testWidgets('shows no team selected when teamId is null', (tester) async {
      await tester.pumpWidget(createWidget(teamId: null));
      await tester.pumpAndSettle();

      expect(find.text('No team selected'), findsOneWidget);
    });

    testWidgets('renders channel tag icon', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // One tag icon per unread channel (general + project-api = 2).
      expect(find.byIcon(Icons.tag), findsNWidgets(2));
    });
  });
}
