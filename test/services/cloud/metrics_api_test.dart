// Tests for MetricsApi.
//
// Verifies team metrics, project metrics, project trend retrieval,
// and error handling for metrics endpoints.
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:codeops/services/cloud/api_client.dart';
import 'package:codeops/services/cloud/metrics_api.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockClient;
  late MetricsApi metricsApi;

  final teamMetricsJson = {
    'teamId': 'team-1',
    'totalProjects': 5,
    'totalJobs': 20,
    'totalFindings': 100,
    'averageHealthScore': 82.5,
    'projectsBelowThreshold': 1,
    'openCriticalFindings': 3,
  };

  final projectMetricsJson = {
    'projectId': 'proj-1',
    'projectName': 'My Project',
    'currentHealthScore': 85,
    'previousHealthScore': 80,
    'totalJobs': 10,
    'totalFindings': 50,
    'openCritical': 1,
    'openHigh': 5,
    'techDebtItemCount': 8,
    'openVulnerabilities': 2,
    'lastAuditAt': '2024-01-01T00:00:00.000Z',
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

  setUp(() {
    mockClient = MockApiClient();
    metricsApi = MetricsApi(mockClient);
  });

  group('MetricsApi', () {
    test('getTeamMetrics returns team metrics', () async {
      when(() => mockClient.get<Map<String, dynamic>>('/metrics/team/team-1'))
          .thenAnswer((_) async => Response(
                data: teamMetricsJson,
                requestOptions: RequestOptions(),
                statusCode: 200,
              ));

      final metrics = await metricsApi.getTeamMetrics('team-1');

      expect(metrics.teamId, 'team-1');
      expect(metrics.totalProjects, 5);
      expect(metrics.averageHealthScore, 82.5);
      expect(metrics.openCriticalFindings, 3);
    });

    test('getProjectMetrics returns project metrics', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '/metrics/project/proj-1',
          )).thenAnswer((_) async => Response(
                data: projectMetricsJson,
                requestOptions: RequestOptions(),
                statusCode: 200,
              ));

      final metrics = await metricsApi.getProjectMetrics('proj-1');

      expect(metrics.projectId, 'proj-1');
      expect(metrics.projectName, 'My Project');
      expect(metrics.currentHealthScore, 85);
      expect(metrics.previousHealthScore, 80);
      expect(metrics.openCritical, 1);
    });

    test('getProjectTrend returns list of snapshots', () async {
      when(() => mockClient.get<List<dynamic>>(
            '/metrics/project/proj-1/trend',
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer((_) async => Response(
                data: [snapshotJson],
                requestOptions: RequestOptions(),
                statusCode: 200,
              ));

      final trend = await metricsApi.getProjectTrend('proj-1', days: 14);

      expect(trend, hasLength(1));
      expect(trend.first.healthScore, 85);
      verify(() => mockClient.get<List<dynamic>>(
            '/metrics/project/proj-1/trend',
            queryParameters: {'days': 14},
          )).called(1);
    });

    test('getTeamMetrics throws on DioException', () async {
      when(() => mockClient.get<Map<String, dynamic>>('/metrics/team/team-1'))
          .thenThrow(DioException(
            requestOptions: RequestOptions(),
            type: DioExceptionType.connectionTimeout,
          ));

      expect(
        () => metricsApi.getTeamMetrics('team-1'),
        throwsA(isA<DioException>()),
      );
    });
  });
}
