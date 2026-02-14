/// API service for team management endpoints.
///
/// Covers team CRUD, membership management, and invitations.
library;

import '../../models/enums.dart';
import '../../models/team.dart';
import 'api_client.dart';

/// API service for team management endpoints.
///
/// Provides typed methods for team CRUD, member role management,
/// and invitation workflows.
class TeamApi {
  final ApiClient _client;

  /// Creates a [TeamApi] backed by the given [client].
  TeamApi(this._client);

  /// Fetches all teams the current user belongs to.
  Future<List<Team>> getTeams() async {
    final response = await _client.get<List<dynamic>>('/teams');
    return response.data!
        .map((e) => Team.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Creates a new team. The current user becomes OWNER.
  Future<Team> createTeam({
    required String name,
    String? description,
    String? teamsWebhookUrl,
  }) async {
    final body = <String, dynamic>{'name': name};
    if (description != null) body['description'] = description;
    if (teamsWebhookUrl != null) body['teamsWebhookUrl'] = teamsWebhookUrl;

    final response = await _client.post<Map<String, dynamic>>(
      '/teams',
      data: body,
    );
    return Team.fromJson(response.data!);
  }

  /// Fetches a single team by [teamId].
  Future<Team> getTeam(String teamId) async {
    final response =
        await _client.get<Map<String, dynamic>>('/teams/$teamId');
    return Team.fromJson(response.data!);
  }

  /// Updates a team's name, description, or webhook URL.
  Future<Team> updateTeam(
    String teamId, {
    String? name,
    String? description,
    String? teamsWebhookUrl,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (description != null) body['description'] = description;
    if (teamsWebhookUrl != null) body['teamsWebhookUrl'] = teamsWebhookUrl;

    final response = await _client.put<Map<String, dynamic>>(
      '/teams/$teamId',
      data: body,
    );
    return Team.fromJson(response.data!);
  }

  /// Deletes a team. Only the OWNER can delete.
  Future<void> deleteTeam(String teamId) async {
    await _client.delete('/teams/$teamId');
  }

  /// Fetches all members of a team.
  Future<List<TeamMember>> getTeamMembers(String teamId) async {
    final response =
        await _client.get<List<dynamic>>('/teams/$teamId/members');
    return response.data!
        .map((e) => TeamMember.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Updates a member's role within a team.
  Future<TeamMember> updateMemberRole(
    String teamId,
    String userId,
    TeamRole role,
  ) async {
    final response = await _client.put<Map<String, dynamic>>(
      '/teams/$teamId/members/$userId/role',
      data: {'role': role.toJson()},
    );
    return TeamMember.fromJson(response.data!);
  }

  /// Removes a member from a team.
  Future<void> removeMember(String teamId, String userId) async {
    await _client.delete('/teams/$teamId/members/$userId');
  }

  /// Sends an invitation to join a team.
  Future<Invitation> inviteMember(
    String teamId, {
    required String email,
    required TeamRole role,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/teams/$teamId/invitations',
      data: {'email': email, 'role': role.toJson()},
    );
    return Invitation.fromJson(response.data!);
  }

  /// Fetches all pending invitations for a team.
  Future<List<Invitation>> getTeamInvitations(String teamId) async {
    final response =
        await _client.get<List<dynamic>>('/teams/$teamId/invitations');
    return response.data!
        .map((e) => Invitation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Cancels a pending invitation.
  Future<void> cancelInvitation(String teamId, String invitationId) async {
    await _client.delete('/teams/$teamId/invitations/$invitationId');
  }

  /// Accepts an invitation using its [token].
  Future<Team> acceptInvitation(String token) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/teams/invitations/$token/accept',
    );
    return Team.fromJson(response.data!);
  }
}
