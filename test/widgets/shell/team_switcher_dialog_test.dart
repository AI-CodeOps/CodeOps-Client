// Widget tests for TeamSwitcherDialog.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/team.dart';
import 'package:codeops/providers/team_providers.dart';
import 'package:codeops/widgets/shell/team_switcher_dialog.dart';

void main() {
  Widget createWidget({
    List<Team> teams = const [],
    String? selectedTeamId,
  }) {
    return ProviderScope(
      overrides: [
        teamsProvider.overrideWith((ref) => Future.value(teams)),
        if (selectedTeamId != null)
          selectedTeamIdProvider.overrideWith((ref) => selectedTeamId),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => const TeamSwitcherDialog(),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
  }

  group('TeamSwitcherDialog', () {
    testWidgets('lists teams', (tester) async {
      final teams = [
        const Team(id: 't1', name: 'Alpha', ownerId: 'o1', ownerName: 'Owner A', memberCount: 3),
        const Team(id: 't2', name: 'Beta', ownerId: 'o2', ownerName: 'Owner B', memberCount: 5),
      ];

      await tester.pumpWidget(createWidget(teams: teams));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Switch Team'), findsOneWidget);
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsOneWidget);
    });

    testWidgets('highlights currently selected team', (tester) async {
      final teams = [
        const Team(id: 't1', name: 'Alpha', ownerId: 'o1', memberCount: 3),
        const Team(id: 't2', name: 'Beta', ownerId: 'o2', memberCount: 5),
      ];

      await tester.pumpWidget(createWidget(teams: teams, selectedTeamId: 't1'));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // The selected team should show a check icon
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('shows create team button', (tester) async {
      await tester.pumpWidget(createWidget(teams: []));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Create Team'), findsOneWidget);
    });

    testWidgets('shows create form on button tap', (tester) async {
      await tester.pumpWidget(createWidget(teams: []));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create Team'));
      await tester.pumpAndSettle();

      expect(find.text('Create'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });
  });
}
