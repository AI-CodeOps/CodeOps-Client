// Tests for IntegrationApi.
//
// Tests a representative sample: GitHub connections, dependency scans,
// remediation tasks, tech debt items, and health schedules.
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

    group('Dependency scans', () {
      final scanJson = {
        'id': 'scan-1',
        'projectId': 'proj-1',
        'totalDependencies': 50,
        'outdatedCount': 5,
        'vulnerableCount': 2,
        'createdAt': '2024-01-01T00:00:00.000Z',
      };

      test('createDependencyScan sends correct body', () async {
        when(() => mockClient.post<Map<String, dynamic>>(
              '/dependencies/scans',
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              data: scanJson,
              requestOptions: RequestOptions(),
              statusCode: 201,
            ));

        final scan = await integrationApi.createDependencyScan(
          projectId: 'proj-1',
          totalDependencies: 50,
        );

        expect(scan.totalDependencies, 50);
      });

      test('getProjectScans returns list', () async {
        when(() => mockClient.get<List<dynamic>>(
              '/dependencies/scans/project/proj-1',
            )).thenAnswer((_) async => Response(
              data: [scanJson],
              requestOptions: RequestOptions(),
              statusCode: 200,
            ));

        final scans = await integrationApi.getProjectScans('proj-1');

        expect(scans, hasLength(1));
      });
    });

    group('Remediation tasks', () {
      final taskJson = {
        'id': 'task-1',
        'jobId': 'job-1',
        'taskNumber': 1,
        'title': 'Fix SQL injection',
        'status': 'PENDING',
        'createdAt': '2024-01-01T00:00:00.000Z',
      };

      test('createTask sends correct body', () async {
        when(() => mockClient.post<Map<String, dynamic>>(
              '/tasks',
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              data: taskJson,
              requestOptions: RequestOptions(),
              statusCode: 201,
            ));

        final task = await integrationApi.createTask(
          jobId: 'job-1',
          taskNumber: 1,
          title: 'Fix SQL injection',
          priority: Priority.p0,
        );

        expect(task.title, 'Fix SQL injection');
      });

      test('getMyTasks returns list', () async {
        when(() => mockClient.get<List<dynamic>>('/tasks/assigned-to-me'))
            .thenAnswer((_) async => Response(
                  data: [taskJson],
                  requestOptions: RequestOptions(),
                  statusCode: 200,
                ));

        final tasks = await integrationApi.getMyTasks();

        expect(tasks, hasLength(1));
      });
    });

    group('Tech debt', () {
      final debtJson = {
        'id': 'debt-1',
        'projectId': 'proj-1',
        'category': 'CODE',
        'title': 'Refactor auth module',
        'status': 'IDENTIFIED',
        'createdAt': '2024-01-01T00:00:00.000Z',
      };

      test('createTechDebtItem sends correct body', () async {
        when(() => mockClient.post<Map<String, dynamic>>(
              '/tech-debt',
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              data: debtJson,
              requestOptions: RequestOptions(),
              statusCode: 201,
            ));

        final item = await integrationApi.createTechDebtItem(
          projectId: 'proj-1',
          category: DebtCategory.code,
          title: 'Refactor auth module',
        );

        expect(item.title, 'Refactor auth module');
      });

      test('updateTechDebtStatus sends status', () async {
        when(() => mockClient.put<Map<String, dynamic>>(
              '/tech-debt/debt-1/status',
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              data: {...debtJson, 'status': 'RESOLVED'},
              requestOptions: RequestOptions(),
              statusCode: 200,
            ));

        final item = await integrationApi.updateTechDebtStatus(
          'debt-1',
          DebtStatus.resolved,
        );

        expect(item.status, DebtStatus.resolved);
      });
    });

    group('Health schedules', () {
      final scheduleJson = {
        'id': 'sched-1',
        'projectId': 'proj-1',
        'scheduleType': 'DAILY',
        'agentTypes': ['SECURITY', 'CODE_QUALITY'],
        'isActive': true,
        'createdAt': '2024-01-01T00:00:00.000Z',
      };

      test('createSchedule sends correct body', () async {
        when(() => mockClient.post<Map<String, dynamic>>(
              '/health-monitor/schedules',
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              data: scheduleJson,
              requestOptions: RequestOptions(),
              statusCode: 201,
            ));

        final schedule = await integrationApi.createSchedule(
          projectId: 'proj-1',
          scheduleType: ScheduleType.daily,
          agentTypes: [AgentType.security, AgentType.codeQuality],
        );

        expect(schedule.scheduleType, ScheduleType.daily);
      });

      test('getProjectSchedules returns list', () async {
        when(() => mockClient.get<List<dynamic>>(
              '/health-monitor/schedules/project/proj-1',
            )).thenAnswer((_) async => Response(
              data: [scheduleJson],
              requestOptions: RequestOptions(),
              statusCode: 200,
            ));

        final schedules =
            await integrationApi.getProjectSchedules('proj-1');

        expect(schedules, hasLength(1));
      });
    });
  });
}
