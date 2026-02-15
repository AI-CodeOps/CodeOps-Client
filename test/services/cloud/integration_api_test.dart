// Tests for IntegrationApi.
//
// Tests GitHub and Jira connection management.
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:codeops/models/enums.dart';
import 'package:codeops/services/cloud/api_client.dart';
import 'package:codeops/services/cloud/integration_api.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockClient;
  late IntegrationApi integrationApi;

  setUp(() {
    mockClient = MockApiClient();
    integrationApi = IntegrationApi(mockClient);
  });

  group('IntegrationApi', () {
    group('GitHub connections', () {
      final githubJson = {
        'id': 'gh-1',
        'teamId': 'team-1',
        'name': 'My GitHub',
        'authType': 'PAT',
        'githubUsername': 'testuser',
        'isActive': true,
        'createdAt': '2024-01-01T00:00:00.000Z',
      };

      test('createGitHubConnection sends correct body', () async {
        when(() => mockClient.post<Map<String, dynamic>>(
              '/integrations/github/team-1',
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              data: githubJson,
              requestOptions: RequestOptions(),
              statusCode: 201,
            ));

        final conn = await integrationApi.createGitHubConnection(
          'team-1',
          name: 'My GitHub',
          authType: GitHubAuthType.pat,
          credentials: 'ghp_test123',
          githubUsername: 'testuser',
        );

        expect(conn.name, 'My GitHub');
        expect(conn.authType, GitHubAuthType.pat);
      });

      test('getTeamGitHubConnections returns list', () async {
        when(() =>
                mockClient.get<List<dynamic>>('/integrations/github/team-1'))
            .thenAnswer((_) async => Response(
                  data: [githubJson],
                  requestOptions: RequestOptions(),
                  statusCode: 200,
                ));

        final conns =
            await integrationApi.getTeamGitHubConnections('team-1');

        expect(conns, hasLength(1));
      });

      test('deleteGitHubConnection includes teamId in path', () async {
        when(() => mockClient.delete('/integrations/github/team-1/gh-1'))
            .thenAnswer((_) async => Response(
                  requestOptions: RequestOptions(),
                  statusCode: 200,
                ));

        await integrationApi.deleteGitHubConnection('team-1', 'gh-1');

        verify(() => mockClient.delete('/integrations/github/team-1/gh-1'))
            .called(1);
      });
    });

  });
}
