/// Riverpod providers for team-related data.
///
/// Exposes the [TeamApi] service, team lists, selected team state,
/// team members, and team invitations.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/team.dart';
import '../services/cloud/team_api.dart';
import 'auth_providers.dart';

/// Provides [TeamApi] for team endpoints.
final teamApiProvider = Provider<TeamApi>(
  (ref) => TeamApi(ref.watch(apiClientProvider)),
);

/// Fetches all teams for the current user.
final teamsProvider = FutureProvider<List<Team>>((ref) async {
  final teamApi = ref.watch(teamApiProvider);
  return teamApi.getTeams();
});

/// The currently selected team ID.
final selectedTeamIdProvider = StateProvider<String?>((ref) => null);

/// The currently selected team.
final selectedTeamProvider = FutureProvider<Team?>((ref) async {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) return null;
  final teamApi = ref.watch(teamApiProvider);
  return teamApi.getTeam(teamId);
});

/// Members of the currently selected team.
final teamMembersProvider = FutureProvider<List<TeamMember>>((ref) async {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) return [];
  final teamApi = ref.watch(teamApiProvider);
  return teamApi.getTeamMembers(teamId);
});

/// Pending invitations for the currently selected team.
final teamInvitationsProvider =
    FutureProvider<List<Invitation>>((ref) async {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) return [];
  final teamApi = ref.watch(teamApiProvider);
  return teamApi.getTeamInvitations(teamId);
});
