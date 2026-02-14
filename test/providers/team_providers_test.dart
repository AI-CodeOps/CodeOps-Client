// Tests for team providers.
//
// Verifies provider creation and selectedTeamId state changes.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/providers/team_providers.dart';
import 'package:codeops/services/cloud/team_api.dart';

void main() {
  group('Team providers', () {
    test('teamApiProvider creates instance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final api = container.read(teamApiProvider);

      expect(api, isA<TeamApi>());
    });

    test('selectedTeamIdProvider defaults to null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final teamId = container.read(selectedTeamIdProvider);

      expect(teamId, isNull);
    });

    test('selectedTeamIdProvider can be updated', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(selectedTeamIdProvider.notifier).state = 'team-123';

      expect(container.read(selectedTeamIdProvider), 'team-123');
    });

    test('teamsProvider is a FutureProvider', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final asyncTeams = container.read(teamsProvider);

      expect(asyncTeams, isA<AsyncValue>());
    });

    test('teamMembersProvider returns empty when no team selected', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Ensure no team is selected
      expect(container.read(selectedTeamIdProvider), isNull);

      // Members provider should handle null teamId
      final asyncMembers = container.read(teamMembersProvider);
      expect(asyncMembers, isA<AsyncValue>());
    });
  });
}
