// Tests for ProjectApi.
//
// Verifies project CRUD, archiving, and team-scoped listing.
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:codeops/services/cloud/api_client.dart';
import 'package:codeops/services/cloud/project_api.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockClient;
  late ProjectApi projectApi;

  final projectJson = {
    'id': 'proj-1',
    'teamId': 'team-1',
    'name': 'Test Project',
    'description': 'A test project',
    'healthScore': 85,
    'isArchived': false,
    'createdAt': '2024-01-01T00:00:00.000Z',
  };

  setUp(() {
    mockClient = MockApiClient();
    projectApi = ProjectApi(mockClient);
  });

  group('ProjectApi', () {
    test('createProject sends correct body', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            '/projects/team-1',
            data: any(named: 'data'),
          )).thenAnswer((_) async => Response(
            data: projectJson,
            requestOptions: RequestOptions(),
            statusCode: 201,
          ));

      final project = await projectApi.createProject(
        'team-1',
        name: 'Test Project',
        description: 'A test project',
      );

      expect(project.name, 'Test Project');
      verify(() => mockClient.post<Map<String, dynamic>>(
            '/projects/team-1',
            data: {
              'name': 'Test Project',
              'description': 'A test project',
            },
          )).called(1);
    });

    test('getTeamProjects fetches with includeArchived', () async {
      when(() => mockClient.get<List<dynamic>>(
            '/projects/team/team-1',
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer((_) async => Response(
            data: [projectJson],
            requestOptions: RequestOptions(),
            statusCode: 200,
          ));

      final projects = await projectApi.getTeamProjects('team-1');

      expect(projects, hasLength(1));
      expect(projects.first.name, 'Test Project');
    });

    test('getProject fetches by ID', () async {
      when(() => mockClient.get<Map<String, dynamic>>('/projects/proj-1'))
          .thenAnswer((_) async => Response(
                data: projectJson,
                requestOptions: RequestOptions(),
                statusCode: 200,
              ));

      final project = await projectApi.getProject('proj-1');

      expect(project.id, 'proj-1');
    });

    test('updateProject sends only provided fields', () async {
      when(() => mockClient.put<Map<String, dynamic>>(
            '/projects/proj-1',
            data: any(named: 'data'),
          )).thenAnswer((_) async => Response(
            data: {...projectJson, 'name': 'Updated'},
            requestOptions: RequestOptions(),
            statusCode: 200,
          ));

      final project = await projectApi.updateProject(
        'proj-1',
        name: 'Updated',
      );

      expect(project.name, 'Updated');
      verify(() => mockClient.put<Map<String, dynamic>>(
            '/projects/proj-1',
            data: {'name': 'Updated'},
          )).called(1);
    });

    test('archiveProject calls correct endpoint', () async {
      when(() => mockClient.put('/projects/proj-1/archive'))
          .thenAnswer((_) async => Response(
                requestOptions: RequestOptions(),
                statusCode: 200,
              ));

      await projectApi.archiveProject('proj-1');

      verify(() => mockClient.put('/projects/proj-1/archive')).called(1);
    });

    test('unarchiveProject calls correct endpoint', () async {
      when(() => mockClient.put('/projects/proj-1/unarchive'))
          .thenAnswer((_) async => Response(
                requestOptions: RequestOptions(),
                statusCode: 200,
              ));

      await projectApi.unarchiveProject('proj-1');

      verify(() => mockClient.put('/projects/proj-1/unarchive')).called(1);
    });

    test('deleteProject calls correct endpoint', () async {
      when(() => mockClient.delete('/projects/proj-1'))
          .thenAnswer((_) async => Response(
                requestOptions: RequestOptions(),
                statusCode: 200,
              ));

      await projectApi.deleteProject('proj-1');

      verify(() => mockClient.delete('/projects/proj-1')).called(1);
    });
  });
}
