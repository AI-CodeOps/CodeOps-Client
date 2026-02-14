// Tests for ProjectApi.
//
// Verifies project CRUD, archiving, team-scoped listing, and pagination.
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:codeops/models/health_snapshot.dart';
import 'package:codeops/models/project.dart';
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

    test('getTeamProjectsPaged returns PageResponse with pagination metadata',
        () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '/projects/team/team-1/paged',
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer((_) async => Response(
            data: {
              'content': [projectJson],
              'page': 0,
              'size': 20,
              'totalElements': 1,
              'totalPages': 1,
              'isLast': true,
            },
            requestOptions: RequestOptions(),
            statusCode: 200,
          ));

      final page = await projectApi.getTeamProjectsPaged('team-1');

      expect(page, isA<PageResponse<Project>>());
      expect(page.content, hasLength(1));
      expect(page.content.first.name, 'Test Project');
      expect(page.page, 0);
      expect(page.totalElements, 1);
      expect(page.isLast, isTrue);
    });

    test('getTeamProjectsPaged passes page and size params', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '/projects/team/team-1/paged',
            queryParameters: {
              'page': 2,
              'size': 10,
              'includeArchived': true,
            },
          )).thenAnswer((_) async => Response(
            data: {
              'content': <dynamic>[],
              'page': 2,
              'size': 10,
              'totalElements': 25,
              'totalPages': 3,
              'isLast': false,
            },
            requestOptions: RequestOptions(),
            statusCode: 200,
          ));

      final page = await projectApi.getTeamProjectsPaged(
        'team-1',
        page: 2,
        size: 10,
        includeArchived: true,
      );

      expect(page.page, 2);
      expect(page.size, 10);
      expect(page.totalElements, 25);
      expect(page.isLast, isFalse);
    });
  });
}
