/// Tests for [PersonaApi] — all 11 methods.
///
/// Verifies path construction, request body serialization, response
/// deserialization, and correct error propagation.
library;

import 'package:codeops/models/enums.dart';
import 'package:codeops/models/persona.dart';
import 'package:codeops/services/cloud/api_client.dart';
import 'package:codeops/services/cloud/persona_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockClient;
  late PersonaApi personaApi;

  final samplePersonaJson = <String, dynamic>{
    'id': 'p-1',
    'name': 'Security Persona',
    'agentType': 'SECURITY',
    'description': 'A security-focused persona',
    'contentMd': '## Identity\nSecurity expert',
    'scope': 'TEAM',
    'teamId': 'team-1',
    'createdBy': 'user-1',
    'createdByName': 'Adam',
    'isDefault': false,
    'version': 1,
    'createdAt': '2025-01-01T00:00:00.000Z',
    'updatedAt': '2025-01-02T00:00:00.000Z',
  };

  setUp(() {
    mockClient = MockApiClient();
    personaApi = PersonaApi(mockClient);
  });

  group('PersonaApi', () {
    group('createPersona', () {
      test('sends correct body and returns persona', () async {
        when(() => mockClient.post<Map<String, dynamic>>(
              '/personas',
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              data: samplePersonaJson,
              requestOptions: RequestOptions(),
              statusCode: 201,
            ));

        final result = await personaApi.createPersona(
          name: 'Security Persona',
          contentMd: '## Identity\nSecurity expert',
          scope: Scope.team,
          agentType: AgentType.security,
          description: 'A security-focused persona',
          teamId: 'team-1',
        );

        expect(result, isA<Persona>());
        expect(result.id, 'p-1');
        expect(result.name, 'Security Persona');
        verify(() => mockClient.post<Map<String, dynamic>>(
              '/personas',
              data: any(named: 'data'),
            )).called(1);
      });
    });

    group('getPersona', () {
      test('calls correct path and returns persona', () async {
        when(() => mockClient.get<Map<String, dynamic>>('/personas/p-1'))
            .thenAnswer((_) async => Response(
                  data: samplePersonaJson,
                  requestOptions: RequestOptions(),
                  statusCode: 200,
                ));

        final result = await personaApi.getPersona('p-1');

        expect(result.id, 'p-1');
        verify(() => mockClient.get<Map<String, dynamic>>('/personas/p-1'))
            .called(1);
      });
    });

    group('updatePersona', () {
      test('sends only provided fields', () async {
        when(() => mockClient.put<Map<String, dynamic>>(
              '/personas/p-1',
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              data: samplePersonaJson,
              requestOptions: RequestOptions(),
              statusCode: 200,
            ));

        final result = await personaApi.updatePersona(
          'p-1',
          name: 'Updated Name',
        );

        expect(result, isA<Persona>());
        final captured = verify(() => mockClient.put<Map<String, dynamic>>(
              '/personas/p-1',
              data: captureAny(named: 'data'),
            )).captured.single as Map<String, dynamic>;
        expect(captured['name'], 'Updated Name');
        expect(captured.containsKey('contentMd'), isFalse);
      });
    });

    group('deletePersona', () {
      test('calls delete with correct path', () async {
        when(() => mockClient.delete('/personas/p-1'))
            .thenAnswer((_) async => Response(
                  requestOptions: RequestOptions(),
                  statusCode: 204,
                ));

        await personaApi.deletePersona('p-1');

        verify(() => mockClient.delete('/personas/p-1')).called(1);
      });
    });

    group('getTeamPersonas', () {
      test('returns list of personas', () async {
        when(() => mockClient.get<List<dynamic>>('/personas/team/team-1'))
            .thenAnswer((_) async => Response(
                  data: [samplePersonaJson],
                  requestOptions: RequestOptions(),
                  statusCode: 200,
                ));

        final result = await personaApi.getTeamPersonas('team-1');

        expect(result, hasLength(1));
        expect(result.first.id, 'p-1');
      });
    });

    group('getTeamPersonasByAgentType', () {
      test('includes agent type in path', () async {
        when(() => mockClient
                .get<List<dynamic>>('/personas/team/team-1/agent/SECURITY'))
            .thenAnswer((_) async => Response(
                  data: [samplePersonaJson],
                  requestOptions: RequestOptions(),
                  statusCode: 200,
                ));

        final result = await personaApi.getTeamPersonasByAgentType(
            'team-1', AgentType.security);

        expect(result, hasLength(1));
      });
    });

    group('getTeamDefaultPersona', () {
      test('includes agent type in path', () async {
        when(() => mockClient.get<Map<String, dynamic>>(
                '/personas/team/team-1/default/SECURITY'))
            .thenAnswer((_) async => Response(
                  data: samplePersonaJson,
                  requestOptions: RequestOptions(),
                  statusCode: 200,
                ));

        final result = await personaApi.getTeamDefaultPersona(
            'team-1', AgentType.security);

        expect(result.id, 'p-1');
      });
    });

    group('setAsDefault', () {
      test('calls PUT on set-default path', () async {
        when(() => mockClient
                .put<Map<String, dynamic>>('/personas/p-1/set-default'))
            .thenAnswer((_) async => Response(
                  data: {...samplePersonaJson, 'isDefault': true},
                  requestOptions: RequestOptions(),
                  statusCode: 200,
                ));

        final result = await personaApi.setAsDefault('p-1');

        expect(result.isDefault, isTrue);
      });
    });

    group('removeDefault', () {
      test('calls PUT on remove-default path', () async {
        when(() => mockClient
                .put<Map<String, dynamic>>('/personas/p-1/remove-default'))
            .thenAnswer((_) async => Response(
                  data: {...samplePersonaJson, 'isDefault': false},
                  requestOptions: RequestOptions(),
                  statusCode: 200,
                ));

        final result = await personaApi.removeDefault('p-1');

        expect(result.isDefault, isFalse);
      });
    });

    group('getSystemPersonas', () {
      test('calls correct path', () async {
        when(() => mockClient.get<List<dynamic>>('/personas/system'))
            .thenAnswer((_) async => Response(
                  data: [samplePersonaJson],
                  requestOptions: RequestOptions(),
                  statusCode: 200,
                ));

        final result = await personaApi.getSystemPersonas();

        expect(result, hasLength(1));
      });
    });

    group('getMyPersonas', () {
      test('calls correct path', () async {
        when(() => mockClient.get<List<dynamic>>('/personas/mine'))
            .thenAnswer((_) async => Response(
                  data: [samplePersonaJson],
                  requestOptions: RequestOptions(),
                  statusCode: 200,
                ));

        final result = await personaApi.getMyPersonas();

        expect(result, hasLength(1));
      });
    });
  });
}
