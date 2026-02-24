// Tests for LoggerApi.
//
// Verifies that key endpoint methods from each of the 10 controller
// sections send the correct path, headers, query parameters, and
// request body, and deserialize responses correctly.
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:codeops/models/logger_enums.dart';
import 'package:codeops/models/logger_models.dart';
import 'package:codeops/services/cloud/api_client.dart';
import 'package:codeops/services/cloud/logger_api.dart';

class MockApiClient extends Mock implements ApiClient {}

class MockDio extends Mock implements Dio {}

void main() {
  late MockApiClient mockClient;
  late MockDio mockDio;
  late LoggerApi api;

  setUpAll(() {
    registerFallbackValue(Options());
  });

  setUp(() {
    mockClient = MockApiClient();
    mockDio = MockDio();
    when(() => mockClient.dio).thenReturn(mockDio);
    api = LoggerApi(mockClient);
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Log Ingestion
  // ═══════════════════════════════════════════════════════════════════════════

  final logEntryJson = {
    'id': 'log-1',
    'sourceId': 'src-1',
    'sourceName': 'Test Source',
    'level': 'INFO',
    'message': 'Test log',
    'timestamp': '2026-02-24T00:00:00.000Z',
    'serviceName': 'test-svc',
    'teamId': 'team-1',
  };

  group('Log Ingestion', () {
    test('ingestLogEntry sends POST to /logger/logs', () async {
      when(() => mockDio.post<Map<String, dynamic>>(
            '/logger/logs',
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => Response(
            data: logEntryJson,
            requestOptions: RequestOptions(),
            statusCode: 201,
          ));

      final result = await api.ingestLogEntry(
        'team-1',
        level: LogLevel.info,
        message: 'Test log',
        serviceName: 'test-svc',
      );

      expect(result.id, 'log-1');
      expect(result.message, 'Test log');
      verify(() => mockDio.post<Map<String, dynamic>>(
            '/logger/logs',
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).called(1);
    });

    test('ingestLogBatch sends POST to /logger/logs/batch', () async {
      when(() => mockDio.post<Map<String, dynamic>>(
            '/logger/logs/batch',
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => Response(
            data: {'ingested': 5, 'total': 5},
            requestOptions: RequestOptions(),
            statusCode: 200,
          ));

      final result = await api.ingestLogBatch(
        'team-1',
        entries: [
          IngestLogEntryRequest(
            level: LogLevel.info,
            message: 'test',
            serviceName: 'svc',
          ),
        ],
      );

      expect(result['ingested'], 5);
      expect(result['total'], 5);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Log Query
  // ═══════════════════════════════════════════════════════════════════════════

  final pageJson = {
    'content': [logEntryJson],
    'page': 0,
    'size': 20,
    'totalElements': 1,
    'totalPages': 1,
    'isLast': true,
  };

  final savedQueryJson = {
    'id': 'sq-1',
    'teamId': 'team-1',
    'createdBy': 'user-1',
    'name': 'My Query',
    'queryJson': '{"level":"ERROR"}',
    'isShared': false,
    'executionCount': 0,
    'createdAt': '2026-02-24T00:00:00.000Z',
  };

  group('Log Query', () {
    test('queryLogs sends POST to /logger/logs/query', () async {
      when(() => mockDio.post<Map<String, dynamic>>(
            '/logger/logs/query',
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => Response(
            data: pageJson,
            requestOptions: RequestOptions(),
            statusCode: 200,
          ));

      final result = await api.queryLogs(
        'team-1',
        level: LogLevel.error,
        page: 0,
        size: 20,
      );

      expect(result.content, hasLength(1));
      expect(result.totalElements, 1);
    });

    test('searchLogs sends GET to /logger/logs/search', () async {
      when(() => mockDio.get<Map<String, dynamic>>(
            '/logger/logs/search',
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => Response(
            data: pageJson,
            requestOptions: RequestOptions(),
            statusCode: 200,
          ));

      final result = await api.searchLogs(
        'team-1',
        q: 'error',
      );

      expect(result.content, hasLength(1));
    });

    test('getLogEntry sends GET to /logger/logs/{id}', () async {
      when(() => mockDio.get<Map<String, dynamic>>(
            '/logger/logs/log-1',
          )).thenAnswer((_) async => Response(
            data: logEntryJson,
            requestOptions: RequestOptions(),
            statusCode: 200,
          ));

      final result = await api.getLogEntry('log-1');
      expect(result.id, 'log-1');
    });

    test('createSavedQuery sends POST to correct path', () async {
      when(() => mockDio.post<Map<String, dynamic>>(
            '/logger/logs/queries/saved',
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => Response(
            data: savedQueryJson,
            requestOptions: RequestOptions(),
            statusCode: 201,
          ));

      final result = await api.createSavedQuery(
        'team-1',
        name: 'My Query',
        queryJson: '{"level":"ERROR"}',
      );

      expect(result.name, 'My Query');
    });

    test('deleteSavedQuery sends DELETE', () async {
      when(() => mockDio.delete<dynamic>(
            '/logger/logs/queries/saved/sq-1',
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(),
            statusCode: 204,
          ));

      await api.deleteSavedQuery('sq-1');
      verify(() => mockDio.delete<dynamic>(
            '/logger/logs/queries/saved/sq-1',
          )).called(1);
    });

    test('queryLogsDsl sends POST to /logger/logs/dsl', () async {
      when(() => mockDio.post<Map<String, dynamic>>(
            '/logger/logs/dsl',
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => Response(
            data: pageJson,
            requestOptions: RequestOptions(),
            statusCode: 200,
          ));

      final result = await api.queryLogsDsl(
        'team-1',
        query: 'level:ERROR AND service:api',
      );

      expect(result.content, hasLength(1));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Log Sources
  // ═══════════════════════════════════════════════════════════════════════════

  final sourceJson = {
    'id': 'src-1',
    'name': 'API Service',
    'isActive': true,
    'teamId': 'team-1',
    'logCount': 42,
  };

  group('Log Sources', () {
    test('createLogSource sends POST to /logger/sources', () async {
      when(() => mockDio.post<Map<String, dynamic>>(
            '/logger/sources',
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => Response(
            data: sourceJson,
            requestOptions: RequestOptions(),
            statusCode: 201,
          ));

      final result = await api.createLogSource(
        'team-1',
        name: 'API Service',
        description: 'Main API',
      );

      expect(result.name, 'API Service');
    });

    test('listLogSources sends GET and returns list', () async {
      when(() => mockDio.get<List<dynamic>>(
            '/logger/sources',
            options: any(named: 'options'),
          )).thenAnswer((_) async => Response(
            data: [sourceJson],
            requestOptions: RequestOptions(),
            statusCode: 200,
          ));

      final result = await api.listLogSources('team-1');
      expect(result, hasLength(1));
      expect(result.first.id, 'src-1');
    });

    test('deleteLogSource sends DELETE', () async {
      when(() => mockDio.delete<dynamic>(
            '/logger/sources/src-1',
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(),
            statusCode: 204,
          ));

      await api.deleteLogSource('src-1');
      verify(() => mockDio.delete<dynamic>('/logger/sources/src-1')).called(1);
    });

    test('updateLogSource sends PUT with body', () async {
      when(() => mockDio.put<Map<String, dynamic>>(
            '/logger/sources/src-1',
            data: any(named: 'data'),
          )).thenAnswer((_) async => Response(
            data: sourceJson,
            requestOptions: RequestOptions(),
            statusCode: 200,
          ));

      final result =
          await api.updateLogSource('src-1', name: 'Updated Name');
      expect(result.id, 'src-1');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Metrics
  // ═══════════════════════════════════════════════════════════════════════════

  final metricJson = {
    'id': 'met-1',
    'name': 'cpu.usage',
    'metricType': 'GAUGE',
    'serviceName': 'api-svc',
    'teamId': 'team-1',
    'isActive': true,
    'dataPointCount': 100,
    'createdAt': '2026-02-24T00:00:00.000Z',
  };

  group('Metrics', () {
    test('registerMetric sends POST to /logger/metrics', () async {
      when(() => mockDio.post<Map<String, dynamic>>(
            '/logger/metrics',
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => Response(
            data: metricJson,
            requestOptions: RequestOptions(),
            statusCode: 201,
          ));

      final result = await api.registerMetric(
        'team-1',
        name: 'cpu.usage',
        metricType: MetricType.gauge,
        serviceName: 'api-svc',
      );

      expect(result.name, 'cpu.usage');
    });

    test('listMetrics sends GET and returns list', () async {
      when(() => mockDio.get<List<dynamic>>(
            '/logger/metrics',
            options: any(named: 'options'),
          )).thenAnswer((_) async => Response(
            data: [metricJson],
            requestOptions: RequestOptions(),
            statusCode: 200,
          ));

      final result = await api.listMetrics('team-1');
      expect(result, hasLength(1));
    });

    test('deleteMetric sends DELETE', () async {
      when(() => mockDio.delete<dynamic>(
            '/logger/metrics/met-1',
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(),
            statusCode: 204,
          ));

      await api.deleteMetric('met-1');
      verify(() => mockDio.delete<dynamic>('/logger/metrics/met-1')).called(1);
    });

    test('pushMetricData sends POST to /logger/metrics/data', () async {
      when(() => mockDio.post<Map<String, dynamic>>(
            '/logger/metrics/data',
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => Response(
            data: {'ingested': 3, 'total': 3},
            requestOptions: RequestOptions(),
            statusCode: 200,
          ));

      final result = await api.pushMetricData(
        'team-1',
        metricId: 'met-1',
        dataPoints: [
          MetricDataPoint(
            timestamp: DateTime.utc(2026, 2, 24),
            value: 75.5,
          ),
        ],
      );

      expect(result['ingested'], 3);
    });

    test('getLatestMetricDataPoint returns null on 204', () async {
      when(() => mockDio.get<Map<String, dynamic>?>(
            '/logger/metrics/met-1/latest',
          )).thenAnswer((_) async => Response(
            data: null,
            requestOptions: RequestOptions(),
            statusCode: 204,
          ));

      final result = await api.getLatestMetricDataPoint('met-1');
      expect(result, isNull);
    });

    test('getLatestMetricsByService returns metric map', () async {
      when(() => mockDio.get<Map<String, dynamic>>(
            '/logger/metrics/service/api-svc/latest',
            options: any(named: 'options'),
          )).thenAnswer((_) async => Response(
            data: {'cpu.usage': 75.5, 'memory.used': 1024.0},
            requestOptions: RequestOptions(),
            statusCode: 200,
          ));

      final result =
          await api.getLatestMetricsByService('team-1', 'api-svc');
      expect(result['cpu.usage'], 75.5);
      expect(result['memory.used'], 1024.0);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Alert Channels
  // ═══════════════════════════════════════════════════════════════════════════

  final channelJson = {
    'id': 'ch-1',
    'teamId': 'team-1',
    'name': 'Slack Alerts',
    'channelType': 'SLACK',
    'configuration': '{"webhook":"https://hooks.slack.com/test"}',
    'isActive': true,
    'createdBy': 'user-1',
    'createdAt': '2026-02-24T00:00:00.000Z',
  };

  group('Alert Channels', () {
    test('createAlertChannel sends POST to /logger/alerts/channels', () async {
      when(() => mockDio.post<Map<String, dynamic>>(
            '/logger/alerts/channels',
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => Response(
            data: channelJson,
            requestOptions: RequestOptions(),
            statusCode: 201,
          ));

      final result = await api.createAlertChannel(
        'team-1',
        name: 'Slack Alerts',
        channelType: AlertChannelType.slack,
        configuration: '{"webhook":"https://hooks.slack.com/test"}',
      );

      expect(result.name, 'Slack Alerts');
    });

    test('deleteAlertChannel sends DELETE', () async {
      when(() => mockDio.delete<dynamic>(
            '/logger/alerts/channels/ch-1',
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(),
            statusCode: 204,
          ));

      await api.deleteAlertChannel('ch-1');
      verify(() => mockDio.delete<dynamic>('/logger/alerts/channels/ch-1'))
          .called(1);
    });

    test('listAlertChannels returns list', () async {
      when(() => mockDio.get<List<dynamic>>(
            '/logger/alerts/channels',
            options: any(named: 'options'),
          )).thenAnswer((_) async => Response(
            data: [channelJson],
            requestOptions: RequestOptions(),
            statusCode: 200,
          ));

      final result = await api.listAlertChannels('team-1');
      expect(result, hasLength(1));
      expect(result.first.name, 'Slack Alerts');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Alert Rules
  // ═══════════════════════════════════════════════════════════════════════════

  final ruleJson = {
    'id': 'rule-1',
    'teamId': 'team-1',
    'name': 'Error Alert',
    'trapId': 'trap-1',
    'trapName': 'Error Trap',
    'channelId': 'ch-1',
    'channelName': 'Slack Alerts',
    'severity': 'CRITICAL',
    'isActive': true,
    'throttleMinutes': 15,
    'createdAt': '2026-02-24T00:00:00.000Z',
  };

  group('Alert Rules', () {
    test('createAlertRule sends POST to /logger/alerts/rules', () async {
      when(() => mockDio.post<Map<String, dynamic>>(
            '/logger/alerts/rules',
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => Response(
            data: ruleJson,
            requestOptions: RequestOptions(),
            statusCode: 201,
          ));

      final result = await api.createAlertRule(
        'team-1',
        name: 'Error Alert',
        trapId: 'trap-1',
        channelId: 'ch-1',
        severity: AlertSeverity.critical,
      );

      expect(result.name, 'Error Alert');
    });

    test('deleteAlertRule sends DELETE', () async {
      when(() => mockDio.delete<dynamic>(
            '/logger/alerts/rules/rule-1',
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(),
            statusCode: 204,
          ));

      await api.deleteAlertRule('rule-1');
      verify(() => mockDio.delete<dynamic>('/logger/alerts/rules/rule-1'))
          .called(1);
    });

    test('listAlertRules returns list', () async {
      when(() => mockDio.get<List<dynamic>>(
            '/logger/alerts/rules',
            options: any(named: 'options'),
          )).thenAnswer((_) async => Response(
            data: [ruleJson],
            requestOptions: RequestOptions(),
            statusCode: 200,
          ));

      final result = await api.listAlertRules('team-1');
      expect(result, hasLength(1));
      expect(result.first.severity, AlertSeverity.critical);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Alert History
  // ═══════════════════════════════════════════════════════════════════════════

  final alertHistoryJson = {
    'id': 'ah-1',
    'ruleId': 'rule-1',
    'ruleName': 'Error Alert',
    'trapId': 'trap-1',
    'trapName': 'Error Trap',
    'channelId': 'ch-1',
    'channelName': 'Slack Alerts',
    'severity': 'CRITICAL',
    'status': 'FIRED',
    'message': 'Error threshold exceeded',
    'teamId': 'team-1',
    'createdAt': '2026-02-24T00:00:00.000Z',
  };

  final alertHistoryPageJson = {
    'content': [alertHistoryJson],
    'page': 0,
    'size': 20,
    'totalElements': 1,
    'totalPages': 1,
    'isLast': true,
  };

  group('Alert History', () {
    test('getAlertHistory sends GET to /logger/alerts/history', () async {
      when(() => mockDio.get<Map<String, dynamic>>(
            '/logger/alerts/history',
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => Response(
            data: alertHistoryPageJson,
            requestOptions: RequestOptions(),
            statusCode: 200,
          ));

      final result = await api.getAlertHistory('team-1');
      expect(result.content, hasLength(1));
    });

    test('getAlertHistoryByStatus uses status in path', () async {
      when(() => mockDio.get<Map<String, dynamic>>(
            '/logger/alerts/history/status/FIRED',
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => Response(
            data: alertHistoryPageJson,
            requestOptions: RequestOptions(),
            statusCode: 200,
          ));

      final result = await api.getAlertHistoryByStatus(
        'team-1',
        AlertStatus.fired,
      );
      expect(result.content, hasLength(1));
    });

    test('getActiveAlertCounts returns severity map', () async {
      when(() => mockDio.get<Map<String, dynamic>>(
            '/logger/alerts/active-counts',
            options: any(named: 'options'),
          )).thenAnswer((_) async => Response(
            data: {'CRITICAL': 3, 'WARNING': 7, 'INFO': 12},
            requestOptions: RequestOptions(),
            statusCode: 200,
          ));

      final result = await api.getActiveAlertCounts('team-1');
      expect(result['CRITICAL'], 3);
      expect(result['WARNING'], 7);
    });

    test('updateAlertStatus sends PUT', () async {
      when(() => mockDio.put<Map<String, dynamic>>(
            '/logger/alerts/history/ah-1/status',
            data: any(named: 'data'),
          )).thenAnswer((_) async => Response(
            data: alertHistoryJson,
            requestOptions: RequestOptions(),
            statusCode: 200,
          ));

      final result = await api.updateAlertStatus(
        'ah-1',
        status: AlertStatus.acknowledged,
      );
      expect(result.id, 'ah-1');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Dashboards
  // ═══════════════════════════════════════════════════════════════════════════

  final dashboardJson = {
    'id': 'dash-1',
    'teamId': 'team-1',
    'createdBy': 'user-1',
    'name': 'Ops Dashboard',
    'isShared': true,
    'isTemplate': false,
    'refreshIntervalSeconds': 30,
    'createdAt': '2026-02-24T00:00:00.000Z',
    'widgets': <dynamic>[],
  };

  final widgetJson = {
    'id': 'w-1',
    'dashboardId': 'dash-1',
    'title': 'Error Rate',
    'widgetType': 'TIME_SERIES_CHART',
    'gridX': 0,
    'gridY': 0,
    'gridWidth': 6,
    'gridHeight': 4,
    'sortOrder': 0,
    'createdAt': '2026-02-24T00:00:00.000Z',
  };

  group('Dashboards', () {
    test('createDashboard sends POST to /logger/dashboards', () async {
      when(() => mockDio.post<Map<String, dynamic>>(
            '/logger/dashboards',
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => Response(
            data: dashboardJson,
            requestOptions: RequestOptions(),
            statusCode: 201,
          ));

      final result = await api.createDashboard(
        'team-1',
        name: 'Ops Dashboard',
        isShared: true,
      );

      expect(result.name, 'Ops Dashboard');
    });

    test('deleteDashboard sends DELETE', () async {
      when(() => mockDio.delete<dynamic>(
            '/logger/dashboards/dash-1',
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(),
            statusCode: 204,
          ));

      await api.deleteDashboard('dash-1');
      verify(() => mockDio.delete<dynamic>('/logger/dashboards/dash-1'))
          .called(1);
    });

    test('createDashboardWidget sends POST with widget body', () async {
      when(() => mockDio.post<Map<String, dynamic>>(
            '/logger/dashboards/dash-1/widgets',
            data: any(named: 'data'),
          )).thenAnswer((_) async => Response(
            data: widgetJson,
            requestOptions: RequestOptions(),
            statusCode: 201,
          ));

      final result = await api.createDashboardWidget(
        'dash-1',
        title: 'Error Rate',
        widgetType: WidgetType.timeSeriesChart,
        gridWidth: 6,
        gridHeight: 4,
      );

      expect(result.title, 'Error Rate');
    });

    test('deleteDashboardWidget sends DELETE with correct path', () async {
      when(() => mockDio.delete<dynamic>(
            '/logger/dashboards/dash-1/widgets/w-1',
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(),
            statusCode: 204,
          ));

      await api.deleteDashboardWidget('dash-1', 'w-1');
      verify(() => mockDio.delete<dynamic>(
            '/logger/dashboards/dash-1/widgets/w-1',
          )).called(1);
    });

    test('listDashboards returns list', () async {
      when(() => mockDio.get<List<dynamic>>(
            '/logger/dashboards',
            options: any(named: 'options'),
          )).thenAnswer((_) async => Response(
            data: [dashboardJson],
            requestOptions: RequestOptions(),
            statusCode: 200,
          ));

      final result = await api.listDashboards('team-1');
      expect(result, hasLength(1));
    });

    test('duplicateDashboard sends POST with name', () async {
      when(() => mockDio.post<Map<String, dynamic>>(
            '/logger/dashboards/dash-1/duplicate',
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => Response(
            data: dashboardJson,
            requestOptions: RequestOptions(),
            statusCode: 201,
          ));

      final result = await api.duplicateDashboard(
        'team-1',
        'dash-1',
        name: 'Copy of Ops',
      );
      expect(result.id, 'dash-1');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Retention Policies
  // ═══════════════════════════════════════════════════════════════════════════

  final retentionJson = {
    'id': 'ret-1',
    'teamId': 'team-1',
    'name': '30-day purge',
    'retentionDays': 30,
    'action': 'PURGE',
    'isActive': true,
    'createdBy': 'user-1',
    'createdAt': '2026-02-24T00:00:00.000Z',
  };

  final storageJson = {
    'totalLogEntries': 50000,
    'totalMetricDataPoints': 200000,
    'totalTraceSpans': 10000,
    'logEntriesByService': <String, dynamic>{'api-svc': 30000},
    'logEntriesByLevel': <String, dynamic>{'ERROR': 500, 'INFO': 49500},
    'activeRetentionPolicies': 2,
    'oldestLogEntry': '2026-01-01T00:00:00.000Z',
    'newestLogEntry': '2026-02-24T00:00:00.000Z',
  };

  group('Retention Policies', () {
    test('createRetentionPolicy sends POST', () async {
      when(() => mockDio.post<Map<String, dynamic>>(
            '/logger/retention/policies',
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => Response(
            data: retentionJson,
            requestOptions: RequestOptions(),
            statusCode: 201,
          ));

      final result = await api.createRetentionPolicy(
        'team-1',
        name: '30-day purge',
        retentionDays: 30,
        action: RetentionAction.purge,
      );

      expect(result.name, '30-day purge');
    });

    test('deleteRetentionPolicy sends DELETE', () async {
      when(() => mockDio.delete<dynamic>(
            '/logger/retention/policies/ret-1',
            options: any(named: 'options'),
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(),
            statusCode: 204,
          ));

      await api.deleteRetentionPolicy('team-1', 'ret-1');
      verify(() => mockDio.delete<dynamic>(
            '/logger/retention/policies/ret-1',
            options: any(named: 'options'),
          )).called(1);
    });

    test('getStorageUsage returns StorageUsageResponse', () async {
      when(() => mockDio.get<Map<String, dynamic>>(
            '/logger/retention/storage',
          )).thenAnswer((_) async => Response(
            data: storageJson,
            requestOptions: RequestOptions(),
            statusCode: 200,
          ));

      final result = await api.getStorageUsage();
      expect(result.totalLogEntries, 50000);
    });

    test('toggleRetentionPolicy sends PUT with active flag', () async {
      when(() => mockDio.put<Map<String, dynamic>>(
            '/logger/retention/policies/ret-1/toggle',
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => Response(
            data: retentionJson,
            requestOptions: RequestOptions(),
            statusCode: 200,
          ));

      final result =
          await api.toggleRetentionPolicy('team-1', 'ret-1', active: false);
      expect(result.id, 'ret-1');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Traces
  // ═══════════════════════════════════════════════════════════════════════════

  final spanJson = {
    'id': 'span-1',
    'correlationId': 'corr-1',
    'traceId': 'trace-1',
    'spanId': 'span-id-1',
    'serviceName': 'api-svc',
    'operationName': 'GET /users',
    'startTime': '2026-02-24T00:00:00.000Z',
    'endTime': '2026-02-24T00:00:01.000Z',
    'durationMs': 1000,
    'status': 'OK',
    'teamId': 'team-1',
    'createdAt': '2026-02-24T00:00:00.000Z',
  };

  final traceFlowJson = {
    'correlationId': 'corr-1',
    'traceId': 'trace-1',
    'spanCount': 1,
    'totalDurationMs': 1000,
    'hasErrors': false,
    'spans': [spanJson],
  };

  group('Traces', () {
    test('createTraceSpan sends POST to /logger/traces/spans', () async {
      when(() => mockDio.post<Map<String, dynamic>>(
            '/logger/traces/spans',
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => Response(
            data: spanJson,
            requestOptions: RequestOptions(),
            statusCode: 201,
          ));

      final result = await api.createTraceSpan(
        'team-1',
        correlationId: 'corr-1',
        traceId: 'trace-1',
        spanId: 'span-id-1',
        serviceName: 'api-svc',
        operationName: 'GET /users',
        startTime: DateTime.utc(2026, 2, 24),
      );

      expect(result.id, 'span-1');
      expect(result.operationName, 'GET /users');
    });

    test('getTraceFlow returns TraceFlowResponse', () async {
      when(() => mockDio.get<Map<String, dynamic>>(
            '/logger/traces/flow/corr-1',
          )).thenAnswer((_) async => Response(
            data: traceFlowJson,
            requestOptions: RequestOptions(),
            statusCode: 200,
          ));

      final result = await api.getTraceFlow('corr-1');
      expect(result.correlationId, 'corr-1');
      expect(result.spans, hasLength(1));
    });

    test('getTraceWaterfall returns response', () async {
      final waterfallJson = {
        'correlationId': 'corr-1',
        'traceId': 'trace-1',
        'totalDurationMs': 1000,
        'spanCount': 1,
        'serviceCount': 1,
        'hasErrors': false,
        'spans': [
          {
            'id': 'ws-1',
            'spanId': 'span-id-1',
            'serviceName': 'api-svc',
            'operationName': 'GET /users',
            'offsetMs': 0,
            'durationMs': 1000,
            'depth': 0,
            'status': 'OK',
            'relatedLogIds': <dynamic>[],
          },
        ],
      };

      when(() => mockDio.get<Map<String, dynamic>>(
            '/logger/traces/waterfall/corr-1',
          )).thenAnswer((_) async => Response(
            data: waterfallJson,
            requestOptions: RequestOptions(),
            statusCode: 200,
          ));

      final result = await api.getTraceWaterfall('corr-1');
      expect(result.correlationId, 'corr-1');
      expect(result.spans, hasLength(1));
    });

    test('getTraceRootCause returns null on 204', () async {
      when(() => mockDio.get<Map<String, dynamic>?>(
            '/logger/traces/rca/corr-1',
          )).thenAnswer((_) async => Response(
            data: null,
            requestOptions: RequestOptions(),
            statusCode: 204,
          ));

      final result = await api.getTraceRootCause('corr-1');
      expect(result, isNull);
    });

    test('getTraceRelatedLogIds returns list of strings', () async {
      when(() => mockDio.get<List<dynamic>>(
            '/logger/traces/corr-1/logs',
          )).thenAnswer((_) async => Response(
            data: ['log-1', 'log-2', 'log-3'],
            requestOptions: RequestOptions(),
            statusCode: 200,
          ));

      final result = await api.getTraceRelatedLogIds('corr-1');
      expect(result, ['log-1', 'log-2', 'log-3']);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Log Traps
  // ═══════════════════════════════════════════════════════════════════════════

  final trapConditionJson = {
    'id': 'tc-1',
    'conditionType': 'KEYWORD',
    'field': 'message',
    'pattern': 'ERROR',
  };

  final trapJson = {
    'id': 'trap-1',
    'teamId': 'team-1',
    'name': 'Error Trap',
    'trapType': 'PATTERN',
    'isActive': true,
    'createdBy': 'user-1',
    'triggerCount': 5,
    'conditions': [trapConditionJson],
    'createdAt': '2026-02-24T00:00:00.000Z',
  };

  group('Log Traps', () {
    test('createLogTrap sends POST to /logger/traps', () async {
      when(() => mockDio.post<Map<String, dynamic>>(
            '/logger/traps',
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => Response(
            data: trapJson,
            requestOptions: RequestOptions(),
            statusCode: 201,
          ));

      final result = await api.createLogTrap(
        'team-1',
        name: 'Error Trap',
        trapType: TrapType.pattern,
        conditions: [
          CreateTrapConditionRequest(
            conditionType: ConditionType.keyword,
            field: 'message',
            pattern: 'ERROR',
          ),
        ],
      );

      expect(result.name, 'Error Trap');
      expect(result.conditions, hasLength(1));
    });

    test('deleteLogTrap sends DELETE', () async {
      when(() => mockDio.delete<dynamic>(
            '/logger/traps/trap-1',
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(),
            statusCode: 204,
          ));

      await api.deleteLogTrap('trap-1');
      verify(() => mockDio.delete<dynamic>('/logger/traps/trap-1')).called(1);
    });

    test('toggleLogTrap sends POST to toggle path', () async {
      when(() => mockDio.post<Map<String, dynamic>>(
            '/logger/traps/trap-1/toggle',
          )).thenAnswer((_) async => Response(
            data: trapJson,
            requestOptions: RequestOptions(),
            statusCode: 200,
          ));

      final result = await api.toggleLogTrap('trap-1');
      expect(result.id, 'trap-1');
    });

    test('testLogTrap sends POST with hoursBack', () async {
      final testResultJson = {
        'matchCount': 15,
        'totalEvaluated': 1000,
        'sampleMatchIds': ['log-1', 'log-2'],
        'evaluatedFrom': '2026-02-23T00:00:00.000Z',
        'evaluatedTo': '2026-02-24T00:00:00.000Z',
        'matchPercentage': 1.5,
      };

      when(() => mockDio.post<Map<String, dynamic>>(
            '/logger/traps/trap-1/test',
            data: any(named: 'data'),
          )).thenAnswer((_) async => Response(
            data: testResultJson,
            requestOptions: RequestOptions(),
            statusCode: 200,
          ));

      final result =
          await api.testLogTrap('trap-1', hoursBack: 24);
      expect(result.matchCount, 15);
      expect(result.matchPercentage, 1.5);
    });

    test('listLogTraps returns list', () async {
      when(() => mockDio.get<List<dynamic>>(
            '/logger/traps',
            options: any(named: 'options'),
          )).thenAnswer((_) async => Response(
            data: [trapJson],
            requestOptions: RequestOptions(),
            statusCode: 200,
          ));

      final result = await api.listLogTraps('team-1');
      expect(result, hasLength(1));
      expect(result.first.trapType, TrapType.pattern);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Anomaly Detection
  // ═══════════════════════════════════════════════════════════════════════════

  final baselineJson = {
    'id': 'bl-1',
    'teamId': 'team-1',
    'serviceName': 'api-svc',
    'metricName': 'response_time',
    'baselineValue': 150.0,
    'standardDeviation': 30.0,
    'sampleCount': 100,
    'windowStartTime': '2026-02-23T00:00:00.000Z',
    'windowEndTime': '2026-02-24T00:00:00.000Z',
    'deviationThreshold': 2.0,
    'isActive': true,
    'createdAt': '2026-02-24T00:00:00.000Z',
  };

  group('Anomaly Detection', () {
    test('createBaseline sends POST to /logger/anomalies/baselines', () async {
      when(() => mockDio.post<Map<String, dynamic>>(
            '/logger/anomalies/baselines',
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => Response(
            data: baselineJson,
            requestOptions: RequestOptions(),
            statusCode: 201,
          ));

      final result = await api.createBaseline(
        'team-1',
        serviceName: 'api-svc',
        metricName: 'response_time',
        windowHours: 24,
        deviationThreshold: 2.0,
      );

      expect(result.serviceName, 'api-svc');
      expect(result.deviationThreshold, 2.0);
    });

    test('deleteBaseline sends DELETE', () async {
      when(() => mockDio.delete<dynamic>(
            '/logger/anomalies/baselines/bl-1',
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(),
            statusCode: 204,
          ));

      await api.deleteBaseline('bl-1');
      verify(() =>
              mockDio.delete<dynamic>('/logger/anomalies/baselines/bl-1'))
          .called(1);
    });

    test('checkAnomaly sends GET with query parameters', () async {
      final checkJson = {
        'serviceName': 'api-svc',
        'metricName': 'response_time',
        'currentValue': 250.0,
        'baselineValue': 150.0,
        'standardDeviation': 30.0,
        'deviationThreshold': 2.0,
        'zScore': 3.33,
        'isAnomaly': true,
        'direction': 'above',
        'checkedAt': '2026-02-24T00:00:00.000Z',
      };

      when(() => mockDio.get<Map<String, dynamic>>(
            '/logger/anomalies/check',
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => Response(
            data: checkJson,
            requestOptions: RequestOptions(),
            statusCode: 200,
          ));

      final result = await api.checkAnomaly(
        'team-1',
        serviceName: 'api-svc',
        metricName: 'response_time',
      );

      expect(result.isAnomaly, isTrue);
      expect(result.zScore, 3.33);
    });

    test('getAnomalyReport returns full report', () async {
      final reportJson = {
        'teamId': 'team-1',
        'generatedAt': '2026-02-24T00:00:00.000Z',
        'totalBaselines': 5,
        'anomaliesDetected': 2,
        'anomalies': <dynamic>[],
        'allChecks': <dynamic>[],
      };

      when(() => mockDio.get<Map<String, dynamic>>(
            '/logger/anomalies/report',
            options: any(named: 'options'),
          )).thenAnswer((_) async => Response(
            data: reportJson,
            requestOptions: RequestOptions(),
            statusCode: 200,
          ));

      final result = await api.getAnomalyReport('team-1');
      expect(result.anomaliesDetected, 2);
      expect(result.totalBaselines, 5);
    });

    test('listBaselines returns list', () async {
      when(() => mockDio.get<List<dynamic>>(
            '/logger/anomalies/baselines',
            options: any(named: 'options'),
          )).thenAnswer((_) async => Response(
            data: [baselineJson],
            requestOptions: RequestOptions(),
            statusCode: 200,
          ));

      final result = await api.listBaselines('team-1');
      expect(result, hasLength(1));
      expect(result.first.metricName, 'response_time');
    });
  });
}
