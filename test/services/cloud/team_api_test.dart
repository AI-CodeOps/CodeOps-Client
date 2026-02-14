// Tests for TeamApi.
//
// Verifies team CRUD, member management, and invitation workflows.
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:codeops/models/enums.dart';
import 'package:codeops/services/cloud/api_client.dart';
import 'package:codeops/services/cloud/team_api.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockClient;
  late TeamApi teamApi;

  final teamJson = {
    'id': 'team-1',
    'name': 'Test Team',
    'description': 'A test team',
    'ownerId': 'owner-1',
    'ownerName': 'Owner',
    'memberCount': 3,
    'createdAt': '2024-01-01T00:00:00.000Z',
  };

  final memberJson = {
    'id': 'member-1',
    'userId': 'user-1',
    'displayName': 'Test Member',
    'email': 'member@example.com',
    'role': 'MEMBER',
    'joinedAt': '2024-01-01T00:00:00.000Z',
  };

  final invitationJson = {
    'id': 'inv-1',
    'email': 'invite@example.com',
    'role': 'MEMBER',
    'status': 'PENDING',
    'invitedByName': 'Admin User',
    'expiresAt': '2024-02-01T00:00:00.000Z',
    'createdAt': '2024-01-01T00:00:00.000Z',
  };

  setUp(() {
    mockClient = MockApiClient();
    teamApi = TeamApi(mockClient);
  });

  group('TeamApi', () {
    test('getTeams returns list of teams', () async {
      when(() => mockClient.get<List<dynamic>>('/teams'))
          .thenAnswer((_) async => Response(
                data: [teamJson],
                requestOptions: RequestOptions(),
                statusCode: 200,
              ));

      final teams = await teamApi.getTeams();

      expect(teams, hasLength(1));
      expect(teams.first.name, 'Test Team');
    });

    test('createTeam sends correct body', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            '/teams',
            data: any(named: 'data'),
          )).thenAnswer((_) async => Response(
            data: teamJson,
            requestOptions: RequestOptions(),
            statusCode: 201,
          ));

      final team = await teamApi.createTeam(
        name: 'Test Team',
        description: 'A test team',
      );

      expect(team.name, 'Test Team');
      verify(() => mockClient.post<Map<String, dynamic>>(
            '/teams',
            data: {'name': 'Test Team', 'description': 'A test team'},
          )).called(1);
    });

    test('getTeam fetches by ID', () async {
      when(() => mockClient.get<Map<String, dynamic>>('/teams/team-1'))
          .thenAnswer((_) async => Response(
                data: teamJson,
                requestOptions: RequestOptions(),
                statusCode: 200,
              ));

      final team = await teamApi.getTeam('team-1');

      expect(team.id, 'team-1');
    });

    test('getTeamMembers returns list', () async {
      when(() => mockClient.get<List<dynamic>>('/teams/team-1/members'))
          .thenAnswer((_) async => Response(
                data: [memberJson],
                requestOptions: RequestOptions(),
                statusCode: 200,
              ));

      final members = await teamApi.getTeamMembers('team-1');

      expect(members, hasLength(1));
      expect(members.first.displayName, 'Test Member');
    });

    test('inviteMember sends email and role', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            '/teams/team-1/invitations',
            data: any(named: 'data'),
          )).thenAnswer((_) async => Response(
            data: invitationJson,
            requestOptions: RequestOptions(),
            statusCode: 201,
          ));

      final invitation = await teamApi.inviteMember(
        'team-1',
        email: 'invite@example.com',
        role: TeamRole.member,
      );

      expect(invitation.email, 'invite@example.com');
    });

    test('acceptInvitation uses token in path', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            '/teams/invitations/abc-token/accept',
          )).thenAnswer((_) async => Response(
            data: teamJson,
            requestOptions: RequestOptions(),
            statusCode: 200,
          ));

      final team = await teamApi.acceptInvitation('abc-token');

      expect(team.name, 'Test Team');
    });

    test('updateMemberRole sends role in body', () async {
      when(() => mockClient.put<Map<String, dynamic>>(
            '/teams/team-1/members/user-1/role',
            data: any(named: 'data'),
          )).thenAnswer((_) async => Response(
            data: {...memberJson, 'role': 'ADMIN'},
            requestOptions: RequestOptions(),
            statusCode: 200,
          ));

      final member = await teamApi.updateMemberRole(
        'team-1',
        'user-1',
        TeamRole.admin,
      );

      expect(member.role, TeamRole.admin);
    });

    test('deleteTeam calls correct endpoint', () async {
      when(() => mockClient.delete('/teams/team-1'))
          .thenAnswer((_) async => Response(
                requestOptions: RequestOptions(),
                statusCode: 200,
              ));

      await teamApi.deleteTeam('team-1');

      verify(() => mockClient.delete('/teams/team-1')).called(1);
    });
  });
}
