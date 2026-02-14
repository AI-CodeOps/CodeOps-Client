// Tests for FindingApi.
//
// Verifies finding creation, paginated queries, filtering, and bulk updates.
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:codeops/models/enums.dart';
import 'package:codeops/services/cloud/api_client.dart';
import 'package:codeops/services/cloud/finding_api.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockClient;
  late FindingApi findingApi;

  final findingJson = {
    'id': 'find-1',
    'jobId': 'job-1',
    'agentType': 'SECURITY',
    'severity': 'HIGH',
    'title': 'SQL Injection Risk',
    'description': 'Potential SQL injection',
    'status': 'OPEN',
    'createdAt': '2024-01-01T00:00:00.000Z',
  };

  setUp(() {
    mockClient = MockApiClient();
    findingApi = FindingApi(mockClient);
  });

  group('FindingApi', () {
    test('createFinding sends correct body', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            '/findings',
            data: any(named: 'data'),
          )).thenAnswer((_) async => Response(
            data: findingJson,
            requestOptions: RequestOptions(),
            statusCode: 201,
          ));

      final finding = await findingApi.createFinding(
        jobId: 'job-1',
        agentType: AgentType.security,
        severity: Severity.high,
        title: 'SQL Injection Risk',
      );

      expect(finding.title, 'SQL Injection Risk');
      expect(finding.severity, Severity.high);
    });

    test('getJobFindings returns paginated response', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '/findings/job/job-1',
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer((_) async => Response(
            data: {
              'content': [findingJson],
              'page': 0,
              'size': 20,
              'totalElements': 1,
              'totalPages': 1,
              'isLast': true,
            },
            requestOptions: RequestOptions(),
            statusCode: 200,
          ));

      final page = await findingApi.getJobFindings('job-1');

      expect(page.content, hasLength(1));
      expect(page.content.first.title, 'SQL Injection Risk');
    });

    test('getFindingsBySeverity uses correct path', () async {
      when(() => mockClient.get<List<dynamic>>(
            '/findings/job/job-1/severity/HIGH',
          )).thenAnswer((_) async => Response(
            data: [findingJson],
            requestOptions: RequestOptions(),
            statusCode: 200,
          ));

      final findings = await findingApi.getFindingsBySeverity(
        'job-1',
        Severity.high,
      );

      expect(findings, hasLength(1));
    });

    test('getFindingsByStatus uses correct path', () async {
      when(() => mockClient.get<List<dynamic>>(
            '/findings/job/job-1/status/OPEN',
          )).thenAnswer((_) async => Response(
            data: [findingJson],
            requestOptions: RequestOptions(),
            statusCode: 200,
          ));

      final findings = await findingApi.getFindingsByStatus(
        'job-1',
        FindingStatus.open,
      );

      expect(findings, hasLength(1));
    });

    test('getFindingsByAgent uses correct path', () async {
      when(() => mockClient.get<List<dynamic>>(
            '/findings/job/job-1/agent/SECURITY',
          )).thenAnswer((_) async => Response(
            data: [findingJson],
            requestOptions: RequestOptions(),
            statusCode: 200,
          ));

      final findings = await findingApi.getFindingsByAgent(
        'job-1',
        AgentType.security,
      );

      expect(findings, hasLength(1));
    });

    test('updateFindingStatus sends correct body', () async {
      when(() => mockClient.put<Map<String, dynamic>>(
            '/findings/find-1/status',
            data: any(named: 'data'),
          )).thenAnswer((_) async => Response(
            data: {...findingJson, 'status': 'FIXED'},
            requestOptions: RequestOptions(),
            statusCode: 200,
          ));

      final finding = await findingApi.updateFindingStatus(
        'find-1',
        FindingStatus.fixed,
      );

      expect(finding.status, FindingStatus.fixed);
    });

    test('bulkUpdateStatus sends findingIds and status', () async {
      when(() => mockClient.put<List<dynamic>>(
            '/findings/bulk-status',
            data: any(named: 'data'),
          )).thenAnswer((_) async => Response(
            data: [
              {...findingJson, 'status': 'ACKNOWLEDGED'},
            ],
            requestOptions: RequestOptions(),
            statusCode: 200,
          ));

      final findings = await findingApi.bulkUpdateStatus(
        ['find-1'],
        FindingStatus.acknowledged,
      );

      expect(findings, hasLength(1));
      verify(() => mockClient.put<List<dynamic>>(
            '/findings/bulk-status',
            data: {
              'findingIds': ['find-1'],
              'status': 'ACKNOWLEDGED',
            },
          )).called(1);
    });

    test('getFindingCounts returns counts map', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '/findings/job/job-1/counts',
          )).thenAnswer((_) async => Response(
            data: {
              'CRITICAL': 2,
              'HIGH': 5,
              'MEDIUM': 10,
              'LOW': 3,
            },
            requestOptions: RequestOptions(),
            statusCode: 200,
          ));

      final counts = await findingApi.getFindingCounts('job-1');

      expect(counts['CRITICAL'], 2);
      expect(counts['HIGH'], 5);
    });
  });
}
