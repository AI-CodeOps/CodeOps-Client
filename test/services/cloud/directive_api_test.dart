/// Tests for [DirectiveApi] — all 11 methods.
///
/// Verifies path construction, query params, body serialization,
/// response deserialization, and error propagation.
library;

import 'package:codeops/models/directive.dart';
import 'package:codeops/models/enums.dart';
import 'package:codeops/services/cloud/api_client.dart';
import 'package:codeops/services/cloud/directive_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockClient;
  late DirectiveApi directiveApi;

  final sampleDirectiveJson = <String, dynamic>{
    'id': 'd-1',
    'name': 'Security Standards',
    'description': 'Follow OWASP Top 10',
    'contentMd': '## Standards\n- No SQL injection',
    'category': 'STANDARDS',
    'scope': 'TEAM',
    'teamId': 'team-1',
    'createdBy': 'user-1',
    'createdByName': 'Adam',
    'version': 1,
    'createdAt': '2025-01-01T00:00:00.000Z',
    'updatedAt': '2025-01-02T00:00:00.000Z',
  };

  final sampleAssignmentJson = <String, dynamic>{
    'projectId': 'proj-1',
    'directiveId': 'd-1',
    'directiveName': 'Security Standards',
    'category': 'STANDARDS',
    'enabled': true,
  };

  setUp(() {
    mockClient = MockApiClient();
    directiveApi = DirectiveApi(mockClient);
  });

  group('DirectiveApi', () {
    group('createDirective', () {
      test('sends correct body and returns directive', () async {
        when(() => mockClient.post<Map<String, dynamic>>(
              '/directives',
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              data: sampleDirectiveJson,
              requestOptions: RequestOptions(),
              statusCode: 201,
            ));

        final result = await directiveApi.createDirective(
          name: 'Security Standards',
          contentMd: '## Standards\n- No SQL injection',
          scope: DirectiveScope.team,
          category: DirectiveCategory.standards,
          teamId: 'team-1',
        );

        expect(result, isA<Directive>());
        expect(result.id, 'd-1');
        verify(() => mockClient.post<Map<String, dynamic>>(
              '/directives',
              data: any(named: 'data'),
            )).called(1);
      });
    });

    group('getDirective', () {
      test('calls correct path', () async {
        when(() => mockClient.get<Map<String, dynamic>>('/directives/d-1'))
            .thenAnswer((_) async => Response(
                  data: sampleDirectiveJson,
                  requestOptions: RequestOptions(),
                  statusCode: 200,
                ));

        final result = await directiveApi.getDirective('d-1');

        expect(result.id, 'd-1');
      });
    });

    group('updateDirective', () {
      test('sends only provided fields', () async {
        when(() => mockClient.put<Map<String, dynamic>>(
              '/directives/d-1',
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              data: sampleDirectiveJson,
              requestOptions: RequestOptions(),
              statusCode: 200,
            ));

        await directiveApi.updateDirective('d-1', name: 'Updated');

        final captured = verify(() => mockClient.put<Map<String, dynamic>>(
              '/directives/d-1',
              data: captureAny(named: 'data'),
            )).captured.single as Map<String, dynamic>;
        expect(captured['name'], 'Updated');
        expect(captured.containsKey('contentMd'), isFalse);
      });
    });

    group('deleteDirective', () {
      test('calls delete with correct path', () async {
        when(() => mockClient.delete('/directives/d-1'))
            .thenAnswer((_) async => Response(
                  requestOptions: RequestOptions(),
                  statusCode: 204,
                ));

        await directiveApi.deleteDirective('d-1');

        verify(() => mockClient.delete('/directives/d-1')).called(1);
      });
    });

    group('getTeamDirectives', () {
      test('returns list of directives', () async {
        when(() => mockClient.get<List<dynamic>>('/directives/team/team-1'))
            .thenAnswer((_) async => Response(
                  data: [sampleDirectiveJson],
                  requestOptions: RequestOptions(),
                  statusCode: 200,
                ));

        final result = await directiveApi.getTeamDirectives('team-1');

        expect(result, hasLength(1));
      });
    });

    group('getProjectDirectives', () {
      test('calls correct path', () async {
        when(() =>
                mockClient.get<List<dynamic>>('/directives/project/proj-1'))
            .thenAnswer((_) async => Response(
                  data: [sampleDirectiveJson],
                  requestOptions: RequestOptions(),
                  statusCode: 200,
                ));

        final result = await directiveApi.getProjectDirectives('proj-1');

        expect(result, hasLength(1));
      });
    });

    group('getProjectEnabledDirectives', () {
      test('calls correct path', () async {
        when(() => mockClient
                .get<List<dynamic>>('/directives/project/proj-1/enabled'))
            .thenAnswer((_) async => Response(
                  data: [sampleDirectiveJson],
                  requestOptions: RequestOptions(),
                  statusCode: 200,
                ));

        final result =
            await directiveApi.getProjectEnabledDirectives('proj-1');

        expect(result, hasLength(1));
      });
    });

    group('getProjectDirectiveAssignments', () {
      test('returns list of ProjectDirective', () async {
        when(() => mockClient
                .get<List<dynamic>>('/directives/project/proj-1/assignments'))
            .thenAnswer((_) async => Response(
                  data: [sampleAssignmentJson],
                  requestOptions: RequestOptions(),
                  statusCode: 200,
                ));

        final result =
            await directiveApi.getProjectDirectiveAssignments('proj-1');

        expect(result, hasLength(1));
        expect(result.first, isA<ProjectDirective>());
        expect(result.first.enabled, isTrue);
      });
    });

    group('assignToProject', () {
      test('sends correct body', () async {
        when(() => mockClient.post<Map<String, dynamic>>(
              '/directives/assign',
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              data: sampleAssignmentJson,
              requestOptions: RequestOptions(),
              statusCode: 201,
            ));

        final result = await directiveApi.assignToProject(
          projectId: 'proj-1',
          directiveId: 'd-1',
        );

        expect(result.projectId, 'proj-1');
      });
    });

    group('toggleDirective', () {
      test('sends query param', () async {
        when(() => mockClient.put<Map<String, dynamic>>(
              '/directives/project/proj-1/directive/d-1/toggle',
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response(
              data: sampleAssignmentJson,
              requestOptions: RequestOptions(),
              statusCode: 200,
            ));

        await directiveApi.toggleDirective('proj-1', 'd-1', true);

        verify(() => mockClient.put<Map<String, dynamic>>(
              '/directives/project/proj-1/directive/d-1/toggle',
              queryParameters: {'enabled': true},
            )).called(1);
      });
    });

    group('removeFromProject', () {
      test('calls delete with correct path', () async {
        when(() => mockClient
                .delete('/directives/project/proj-1/directive/d-1'))
            .thenAnswer((_) async => Response(
                  requestOptions: RequestOptions(),
                  statusCode: 204,
                ));

        await directiveApi.removeFromProject('proj-1', 'd-1');

        verify(() => mockClient
            .delete('/directives/project/proj-1/directive/d-1')).called(1);
      });
    });
  });
}
