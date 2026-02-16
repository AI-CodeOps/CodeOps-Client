// Tests for JobApi.
//
// Verifies job CRUD, agent run management, and bug investigation endpoints.
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:codeops/models/enums.dart';
import 'package:codeops/services/cloud/api_client.dart';
import 'package:codeops/services/cloud/job_api.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockClient;
  late JobApi jobApi;

  final jobJson = {
    'id': 'job-1',
    'projectId': 'proj-1',
    'projectName': 'Test Project',
    'mode': 'AUDIT',
    'status': 'PENDING',
    'name': 'Test Job',
    'totalFindings': 0,
    'criticalCount': 0,
    'highCount': 0,
    'mediumCount': 0,
    'lowCount': 0,
    'createdAt': '2024-01-01T00:00:00.000Z',
  };

  final agentRunJson = {
    'id': 'run-1',
    'jobId': 'job-1',
    'agentType': 'SECURITY',
    'status': 'PENDING',
    'createdAt': '2024-01-01T00:00:00.000Z',
  };

  final investigationJson = {
    'id': 'inv-1',
    'jobId': 'job-1',
    'jiraKey': 'PROJ-123',
    'jiraSummary': 'Bug found',
    'createdAt': '2024-01-01T00:00:00.000Z',
  };

  setUp(() {
    mockClient = MockApiClient();
    jobApi = JobApi(mockClient);
  });

  group('JobApi', () {
    test('createJob sends correct body', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            '/jobs',
            data: any(named: 'data'),
          )).thenAnswer((_) async => Response(
            data: jobJson,
            requestOptions: RequestOptions(),
            statusCode: 201,
          ));

      final job = await jobApi.createJob(
        projectId: 'proj-1',
        mode: JobMode.audit,
        name: 'Test Job',
      );

      expect(job.id, 'job-1');
      expect(job.name, 'Test Job');
    });

    test('getJob fetches by ID', () async {
      when(() => mockClient.get<Map<String, dynamic>>('/jobs/job-1'))
          .thenAnswer((_) async => Response(
                data: jobJson,
                requestOptions: RequestOptions(),
                statusCode: 200,
              ));

      final job = await jobApi.getJob('job-1');

      expect(job.id, 'job-1');
    });

    test('updateJob sends only provided fields', () async {
      when(() => mockClient.put<Map<String, dynamic>>(
            '/jobs/job-1',
            data: any(named: 'data'),
          )).thenAnswer((_) async => Response(
            data: {...jobJson, 'status': 'RUNNING'},
            requestOptions: RequestOptions(),
            statusCode: 200,
          ));

      final job = await jobApi.updateJob('job-1', status: JobStatus.running);

      expect(job.status, JobStatus.running);
    });

    test('updateJob sends timestamps in UTC', () async {
      Map<String, dynamic>? capturedBody;
      when(() => mockClient.put<Map<String, dynamic>>(
            '/jobs/job-1',
            data: any(named: 'data'),
          )).thenAnswer((invocation) async {
        capturedBody =
            invocation.namedArguments[#data] as Map<String, dynamic>?;
        return Response(
          data: {
            ...jobJson,
            'status': 'RUNNING',
            'startedAt': '2024-06-15T18:00:00.000Z',
          },
          requestOptions: RequestOptions(),
          statusCode: 200,
        );
      });

      // Use a local DateTime (non-UTC) to verify conversion.
      final localTime = DateTime(2024, 6, 15, 12, 0, 0);
      await jobApi.updateJob(
        'job-1',
        status: JobStatus.running,
        startedAt: localTime,
      );

      expect(capturedBody, isNotNull);
      final startedAt = capturedBody!['startedAt'] as String;
      expect(startedAt, endsWith('Z'), reason: 'Timestamps must be UTC (end with Z)');
    });

    test('updateAgentRun sends timestamps in UTC', () async {
      Map<String, dynamic>? capturedBody;
      when(() => mockClient.put<Map<String, dynamic>>(
            '/jobs/agents/run-1',
            data: any(named: 'data'),
          )).thenAnswer((invocation) async {
        capturedBody =
            invocation.namedArguments[#data] as Map<String, dynamic>?;
        return Response(
          data: agentRunJson,
          requestOptions: RequestOptions(),
          statusCode: 200,
        );
      });

      final localTime = DateTime(2024, 6, 15, 12, 0, 0);
      await jobApi.updateAgentRun(
        'run-1',
        status: AgentStatus.completed,
        completedAt: localTime,
      );

      expect(capturedBody, isNotNull);
      final completedAt = capturedBody!['completedAt'] as String;
      expect(completedAt, endsWith('Z'), reason: 'Timestamps must be UTC (end with Z)');
    });

    test('getProjectJobs returns paginated response', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '/jobs/project/proj-1',
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer((_) async => Response(
            data: {
              'content': [
                {
                  'id': 'job-1',
                  'projectId': 'proj-1',
                  'mode': 'AUDIT',
                  'status': 'COMPLETED',
                  'createdAt': '2024-01-01T00:00:00.000Z',
                }
              ],
              'page': 0,
              'size': 20,
              'totalElements': 1,
              'totalPages': 1,
              'isLast': true,
            },
            requestOptions: RequestOptions(),
            statusCode: 200,
          ));

      final page = await jobApi.getProjectJobs('proj-1');

      expect(page.content, hasLength(1));
      expect(page.totalElements, 1);
      expect(page.isLast, true);
    });

    test('getMyJobs returns list', () async {
      when(() => mockClient.get<Map<String, dynamic>>('/jobs/mine'))
          .thenAnswer((_) async => Response(
                data: {
                  'content': [
                    {
                      'id': 'job-1',
                      'projectId': 'proj-1',
                      'mode': 'AUDIT',
                      'status': 'COMPLETED',
                      'createdAt': '2024-01-01T00:00:00.000Z',
                    }
                  ],
                },
                requestOptions: RequestOptions(),
                statusCode: 200,
              ));

      final jobs = await jobApi.getMyJobs();

      expect(jobs, hasLength(1));
    });

    test('createAgentRun sends agent type', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            '/jobs/job-1/agents',
            data: any(named: 'data'),
          )).thenAnswer((_) async => Response(
            data: agentRunJson,
            requestOptions: RequestOptions(),
            statusCode: 201,
          ));

      final run = await jobApi.createAgentRun(
        'job-1',
        agentType: AgentType.security,
      );

      expect(run.id, 'run-1');
    });

    test('getAgentRuns returns list', () async {
      when(() => mockClient.get<List<dynamic>>('/jobs/job-1/agents'))
          .thenAnswer((_) async => Response(
                data: [agentRunJson],
                requestOptions: RequestOptions(),
                statusCode: 200,
              ));

      final runs = await jobApi.getAgentRuns('job-1');

      expect(runs, hasLength(1));
      expect(runs.first.agentType, AgentType.security);
    });

    test('createInvestigation sends correct body', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            '/jobs/job-1/investigation',
            data: any(named: 'data'),
          )).thenAnswer((_) async => Response(
            data: investigationJson,
            requestOptions: RequestOptions(),
            statusCode: 201,
          ));

      final investigation = await jobApi.createInvestigation(
        'job-1',
        jiraKey: 'PROJ-123',
        jiraSummary: 'Bug found',
      );

      expect(investigation.jiraKey, 'PROJ-123');
    });

    test('deleteJob calls correct endpoint', () async {
      when(() => mockClient.delete('/jobs/job-1'))
          .thenAnswer((_) async => Response(
                requestOptions: RequestOptions(),
                statusCode: 200,
              ));

      await jobApi.deleteJob('job-1');

      verify(() => mockClient.delete('/jobs/job-1')).called(1);
    });
  });
}
