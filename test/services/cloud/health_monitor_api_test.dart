// Tests for HealthMonitorApi.
//
// Verifies schedule CRUD, snapshot creation, pagination, trend retrieval,
// and error handling for health monitor endpoints.
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:codeops/models/enums.dart';
import 'package:codeops/services/cloud/health_monitor_api.dart';
import 'package:codeops/services/cloud/api_client.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockClient;
  late HealthMonitorApi healthMonitorApi;

  final scheduleJson = {
    'id': 'sched-1',
    'projectId': 'proj-1',
    'scheduleType': 'DAILY',
    'cronExpression': '0 0 * * *',
    'agentTypes': ['SECURITY', 'CODE_QUALITY'],
    'isActive': true,
    'lastRunAt': '2024-01-01T00:00:00.000Z',
    'nextRunAt': '2024-01-02T00:00:00.000Z',
    'createdAt': '2024-01-01T00:00:00.000Z',
  };

  final snapshotJson = {
    'id': 'snap-1',
    'projectId': 'proj-1',
    'healthScore': 85,
    'techDebtScore': 80,
    'dependencyScore': 90,
    'testCoveragePercent': 75.5,
    'capturedAt': '2024-01-01T00:00:00.000Z',
  };

  final pageJson = {
    'content': [snapshotJson],
    'page': 0,
    'size': 20,
    'totalElements': 1,
    'totalPages': 1,
    'isLast': true,
  };

  setUp(() {
    mockClient = MockApiClient();
    healthMonitorApi = HealthMonitorApi(mockClient);
  });

  group('HealthMonitorApi', () {
    test('createSchedule sends correct body', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            '/health-monitor/schedules',
            data: any(named: 'data'),
          )).thenAnswer((_) async => Response(
            data: scheduleJson,
            requestOptions: RequestOptions(),
            statusCode: 201,
          ));

      final schedule = await healthMonitorApi.createSchedule(
        projectId: 'proj-1',
        scheduleType: ScheduleType.daily,
        agentTypes: [AgentType.security, AgentType.codeQuality],
        cronExpression: '0 0 * * *',
      );

      expect(schedule.id, 'sched-1');
      expect(schedule.projectId, 'proj-1');
      verify(() => mockClient.post<Map<String, dynamic>>(
            '/health-monitor/schedules',
            data: {
              'projectId': 'proj-1',
              'scheduleType': 'DAILY',
              'agentTypes': ['SECURITY', 'CODE_QUALITY'],
              'cronExpression': '0 0 * * *',
            },
          )).called(1);
    });

    test('getSchedulesForProject returns list', () async {
      when(() => mockClient.get<List<dynamic>>(
            '/health-monitor/schedules/project/proj-1',
          )).thenAnswer((_) async => Response(
                data: [scheduleJson],
                requestOptions: RequestOptions(),
                statusCode: 200,
              ));

      final schedules =
          await healthMonitorApi.getSchedulesForProject('proj-1');

      expect(schedules, hasLength(1));
      expect(schedules.first.scheduleType, ScheduleType.daily);
    });

    test('updateSchedule sends active as query param', () async {
      when(() => mockClient.put<Map<String, dynamic>>(
            '/health-monitor/schedules/sched-1',
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer((_) async => Response(
            data: {...scheduleJson, 'isActive': false},
            requestOptions: RequestOptions(),
            statusCode: 200,
          ));

      final schedule =
          await healthMonitorApi.updateSchedule('sched-1', false);

      expect(schedule.id, 'sched-1');
      verify(() => mockClient.put<Map<String, dynamic>>(
            '/health-monitor/schedules/sched-1',
            queryParameters: {'active': false},
          )).called(1);
    });

    test('deleteSchedule calls correct endpoint', () async {
      when(() => mockClient.delete('/health-monitor/schedules/sched-1'))
          .thenAnswer((_) async => Response(
                requestOptions: RequestOptions(),
                statusCode: 200,
              ));

      await healthMonitorApi.deleteSchedule('sched-1');

      verify(() => mockClient.delete('/health-monitor/schedules/sched-1'))
          .called(1);
    });

    test('createSnapshot sends correct body', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            '/health-monitor/snapshots',
            data: any(named: 'data'),
          )).thenAnswer((_) async => Response(
            data: snapshotJson,
            requestOptions: RequestOptions(),
            statusCode: 201,
          ));

      final snapshot = await healthMonitorApi.createSnapshot(
        projectId: 'proj-1',
        healthScore: 85,
        techDebtScore: 80,
        dependencyScore: 90,
        testCoveragePercent: 75.5,
      );

      expect(snapshot.healthScore, 85);
      expect(snapshot.techDebtScore, 80);
      verify(() => mockClient.post<Map<String, dynamic>>(
            '/health-monitor/snapshots',
            data: {
              'projectId': 'proj-1',
              'healthScore': 85,
              'techDebtScore': 80,
              'dependencyScore': 90,
              'testCoveragePercent': 75.5,
            },
          )).called(1);
    });

    test('getSnapshots returns paginated response', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '/health-monitor/snapshots/project/proj-1',
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer((_) async => Response(
                data: pageJson,
                requestOptions: RequestOptions(),
                statusCode: 200,
              ));

      final page = await healthMonitorApi.getSnapshots('proj-1');

      expect(page.content, hasLength(1));
      expect(page.totalElements, 1);
      expect(page.content.first.healthScore, 85);
      verify(() => mockClient.get<Map<String, dynamic>>(
            '/health-monitor/snapshots/project/proj-1',
            queryParameters: {'page': 0, 'size': 20},
          )).called(1);
    });

    test('getLatestSnapshot returns snapshot', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '/health-monitor/snapshots/project/proj-1/latest',
          )).thenAnswer((_) async => Response(
                data: snapshotJson,
                requestOptions: RequestOptions(),
                statusCode: 200,
              ));

      final snapshot =
          await healthMonitorApi.getLatestSnapshot('proj-1');

      expect(snapshot, isNotNull);
      expect(snapshot!.id, 'snap-1');
    });

    test('getHealthTrend returns list of snapshots', () async {
      when(() => mockClient.get<List<dynamic>>(
            '/health-monitor/snapshots/project/proj-1/trend',
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer((_) async => Response(
                data: [snapshotJson],
                requestOptions: RequestOptions(),
                statusCode: 200,
              ));

      final trend = await healthMonitorApi.getHealthTrend('proj-1', days: 7);

      expect(trend, hasLength(1));
      expect(trend.first.healthScore, 85);
      verify(() => mockClient.get<List<dynamic>>(
            '/health-monitor/snapshots/project/proj-1/trend',
            queryParameters: {'limit': 7},
          )).called(1);
    });

    test('getSchedulesForProject throws on DioException', () async {
      when(() => mockClient.get<List<dynamic>>(
            '/health-monitor/schedules/project/proj-1',
          )).thenThrow(DioException(
            requestOptions: RequestOptions(),
            type: DioExceptionType.connectionTimeout,
          ));

      expect(
        () => healthMonitorApi.getSchedulesForProject('proj-1'),
        throwsA(isA<DioException>()),
      );
    });

    test('getLatestSnapshot returns null when data is null', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '/health-monitor/snapshots/project/proj-1/latest',
          )).thenAnswer((_) async => Response(
                data: null,
                requestOptions: RequestOptions(),
                statusCode: 200,
              ));

      final snapshot =
          await healthMonitorApi.getLatestSnapshot('proj-1');

      expect(snapshot, isNull);
    });
  });
}
