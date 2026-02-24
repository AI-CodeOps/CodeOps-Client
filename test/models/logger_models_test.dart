import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/logger_models.dart';

void main() {
  // ═══════════════════════════════════════════════════════════════════════════
  // Log Sources
  // ═══════════════════════════════════════════════════════════════════════════

  group('LogSourceResponse', () {
    final json = <String, dynamic>{
      'id': 'src-1',
      'name': 'my-service',
      'serviceId': 'svc-1',
      'description': 'A log source',
      'environment': 'production',
      'isActive': true,
      'teamId': 'team-1',
      'lastLogReceivedAt': '2026-02-20T10:00:00.000Z',
      'logCount': 42,
      'createdAt': '2026-02-01T00:00:00.000Z',
      'updatedAt': '2026-02-20T10:00:00.000Z',
    };

    test('fromJson deserializes all fields', () {
      final m = LogSourceResponse.fromJson(json);
      expect(m.id, 'src-1');
      expect(m.name, 'my-service');
      expect(m.serviceId, 'svc-1');
      expect(m.isActive, isTrue);
      expect(m.logCount, 42);
    });

    test('toJson round-trip preserves data', () {
      final restored = LogSourceResponse.fromJson(
        LogSourceResponse.fromJson(json).toJson(),
      );
      expect(restored.id, 'src-1');
      expect(restored.name, 'my-service');
    });

    test('handles null optionals', () {
      final m = LogSourceResponse.fromJson(<String, dynamic>{
        'id': 'src-2',
        'name': 'minimal',
        'isActive': false,
        'teamId': 'team-1',
        'logCount': 0,
      });
      expect(m.serviceId, isNull);
      expect(m.description, isNull);
      expect(m.lastLogReceivedAt, isNull);
    });
  });

  group('CreateLogSourceRequest', () {
    test('toJson includes required fields', () {
      const req = CreateLogSourceRequest(name: 'src');
      final json = req.toJson();
      expect(json['name'], 'src');
      expect(json.containsKey('serviceId'), isTrue);
    });

    test('round-trip preserves data', () {
      const req = CreateLogSourceRequest(
        name: 'src',
        serviceId: 'svc-1',
        description: 'desc',
        environment: 'staging',
      );
      final restored = CreateLogSourceRequest.fromJson(req.toJson());
      expect(restored.name, 'src');
      expect(restored.serviceId, 'svc-1');
    });
  });

  group('UpdateLogSourceRequest', () {
    test('round-trip preserves data', () {
      const req = UpdateLogSourceRequest(name: 'new', isActive: false);
      final restored = UpdateLogSourceRequest.fromJson(req.toJson());
      expect(restored.name, 'new');
      expect(restored.isActive, isFalse);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Log Entries & Search
  // ═══════════════════════════════════════════════════════════════════════════

  group('LogEntryResponse', () {
    final json = <String, dynamic>{
      'id': 'log-1',
      'sourceId': 'src-1',
      'sourceName': 'my-service',
      'level': 'ERROR',
      'message': 'Something went wrong',
      'timestamp': '2026-02-20T12:00:00.000Z',
      'serviceName': 'auth-service',
      'correlationId': 'corr-1',
      'traceId': 'trace-1',
      'spanId': 'span-1',
      'loggerName': 'com.example.Auth',
      'threadName': 'main',
      'exceptionClass': 'NullPointerException',
      'exceptionMessage': 'null ref',
      'stackTrace': 'at line 42',
      'customFields': '{"key":"val"}',
      'hostName': 'host-1',
      'ipAddress': '10.0.0.1',
      'teamId': 'team-1',
      'createdAt': '2026-02-20T12:00:00.000Z',
    };

    test('fromJson deserializes all fields', () {
      final m = LogEntryResponse.fromJson(json);
      expect(m.id, 'log-1');
      expect(m.level.toJson(), 'ERROR');
      expect(m.message, 'Something went wrong');
      expect(m.correlationId, 'corr-1');
      expect(m.exceptionClass, 'NullPointerException');
    });

    test('toJson round-trip preserves data', () {
      final restored = LogEntryResponse.fromJson(
        LogEntryResponse.fromJson(json).toJson(),
      );
      expect(restored.id, 'log-1');
      expect(restored.serviceName, 'auth-service');
    });

    test('handles null optionals', () {
      final m = LogEntryResponse.fromJson(<String, dynamic>{
        'id': 'log-2',
        'sourceId': 'src-1',
        'sourceName': 'svc',
        'level': 'INFO',
        'message': 'ok',
        'timestamp': '2026-02-20T12:00:00.000Z',
        'serviceName': 'svc',
        'teamId': 'team-1',
      });
      expect(m.correlationId, isNull);
      expect(m.stackTrace, isNull);
      expect(m.hostName, isNull);
    });
  });

  group('IngestLogEntryRequest', () {
    test('round-trip preserves data', () {
      final req = IngestLogEntryRequest.fromJson(<String, dynamic>{
        'level': 'WARN',
        'message': 'test',
        'serviceName': 'svc',
      });
      expect(req.level.toJson(), 'WARN');
      expect(req.message, 'test');
    });
  });

  group('IngestLogBatchRequest', () {
    test('round-trip preserves entries', () {
      final req = IngestLogBatchRequest.fromJson(<String, dynamic>{
        'entries': [
          {'level': 'INFO', 'message': 'm1', 'serviceName': 'svc'},
          {'level': 'ERROR', 'message': 'm2', 'serviceName': 'svc'},
        ],
      });
      expect(req.entries, hasLength(2));
      final json = req.toJson();
      expect(json['entries'], hasLength(2));
    });
  });

  group('LogQueryRequest', () {
    test('round-trip preserves data', () {
      const req = LogQueryRequest(serviceName: 'svc', page: 1, size: 50);
      final restored = LogQueryRequest.fromJson(req.toJson());
      expect(restored.serviceName, 'svc');
      expect(restored.page, 1);
    });
  });

  group('DslQueryRequest', () {
    test('round-trip preserves data', () {
      const req = DslQueryRequest(query: 'level:ERROR', page: 0, size: 20);
      final restored = DslQueryRequest.fromJson(req.toJson());
      expect(restored.query, 'level:ERROR');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Log Traps & Conditions
  // ═══════════════════════════════════════════════════════════════════════════

  group('TrapConditionResponse', () {
    test('fromJson deserializes all fields', () {
      final m = TrapConditionResponse.fromJson(<String, dynamic>{
        'id': 'cond-1',
        'conditionType': 'REGEX',
        'field': 'message',
        'pattern': '.*error.*',
        'threshold': 5,
        'windowSeconds': 300,
        'serviceName': 'auth',
        'logLevel': 'ERROR',
      });
      expect(m.conditionType.toJson(), 'REGEX');
      expect(m.pattern, '.*error.*');
      expect(m.threshold, 5);
      expect(m.logLevel?.toJson(), 'ERROR');
    });
  });

  group('LogTrapResponse', () {
    final json = <String, dynamic>{
      'id': 'trap-1',
      'name': 'Error Trap',
      'description': 'Catches errors',
      'trapType': 'PATTERN',
      'isActive': true,
      'teamId': 'team-1',
      'createdBy': 'user-1',
      'lastTriggeredAt': '2026-02-20T00:00:00.000Z',
      'triggerCount': 10,
      'conditions': [
        {
          'id': 'cond-1',
          'conditionType': 'KEYWORD',
          'field': 'message',
          'pattern': 'error',
        },
      ],
      'createdAt': '2026-02-01T00:00:00.000Z',
      'updatedAt': '2026-02-20T00:00:00.000Z',
    };

    test('fromJson deserializes nested conditions', () {
      final m = LogTrapResponse.fromJson(json);
      expect(m.name, 'Error Trap');
      expect(m.conditions, hasLength(1));
      expect(m.conditions.first.field, 'message');
      expect(m.triggerCount, 10);
    });

    test('toJson round-trip preserves nested data', () {
      final restored = LogTrapResponse.fromJson(
        LogTrapResponse.fromJson(json).toJson(),
      );
      expect(restored.conditions, hasLength(1));
    });
  });

  group('TrapTestResult', () {
    test('fromJson deserializes all fields', () {
      final m = TrapTestResult.fromJson(<String, dynamic>{
        'matchCount': 5,
        'totalEvaluated': 100,
        'sampleMatchIds': ['id-1', 'id-2'],
        'evaluatedFrom': '2026-02-19T00:00:00.000Z',
        'evaluatedTo': '2026-02-20T00:00:00.000Z',
        'matchPercentage': 5.0,
      });
      expect(m.matchCount, 5);
      expect(m.sampleMatchIds, hasLength(2));
      expect(m.matchPercentage, 5.0);
    });
  });

  group('CreateTrapConditionRequest', () {
    test('round-trip preserves data', () {
      final req = CreateTrapConditionRequest.fromJson(<String, dynamic>{
        'conditionType': 'FREQUENCY_THRESHOLD',
        'field': 'message',
        'threshold': 10,
        'windowSeconds': 60,
      });
      expect(req.conditionType.toJson(), 'FREQUENCY_THRESHOLD');
      expect(req.threshold, 10);
    });
  });

  group('CreateLogTrapRequest', () {
    test('toJson serializes nested conditions', () {
      final req = CreateLogTrapRequest.fromJson(<String, dynamic>{
        'name': 'trap',
        'trapType': 'PATTERN',
        'conditions': [
          {'conditionType': 'REGEX', 'field': 'message', 'pattern': '.*'},
        ],
      });
      final json = req.toJson();
      expect((json['conditions'] as List), hasLength(1));
    });
  });

  group('TestTrapRequest', () {
    test('round-trip preserves data', () {
      const req = TestTrapRequest(hoursBack: 48);
      expect(TestTrapRequest.fromJson(req.toJson()).hoursBack, 48);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Saved Queries
  // ═══════════════════════════════════════════════════════════════════════════

  group('SavedQueryResponse', () {
    test('fromJson deserializes all fields', () {
      final m = SavedQueryResponse.fromJson(<String, dynamic>{
        'id': 'q-1',
        'name': 'Error Query',
        'description': 'Finds errors',
        'queryJson': '{"level":"ERROR"}',
        'queryDsl': 'level:ERROR',
        'teamId': 'team-1',
        'createdBy': 'user-1',
        'isShared': true,
        'lastExecutedAt': '2026-02-20T00:00:00.000Z',
        'executionCount': 42,
        'createdAt': '2026-02-01T00:00:00.000Z',
        'updatedAt': '2026-02-20T00:00:00.000Z',
      });
      expect(m.name, 'Error Query');
      expect(m.isShared, isTrue);
      expect(m.executionCount, 42);
    });
  });

  group('QueryHistoryResponse', () {
    test('fromJson deserializes all fields', () {
      final m = QueryHistoryResponse.fromJson(<String, dynamic>{
        'id': 'qh-1',
        'queryJson': '{"level":"ERROR"}',
        'queryDsl': 'level:ERROR',
        'resultCount': 100,
        'executionTimeMs': 45,
        'createdBy': 'user-1',
        'createdAt': '2026-02-20T00:00:00.000Z',
      });
      expect(m.resultCount, 100);
      expect(m.executionTimeMs, 45);
    });
  });

  group('CreateSavedQueryRequest', () {
    test('round-trip preserves data', () {
      const req = CreateSavedQueryRequest(
        name: 'q',
        queryJson: '{}',
        isShared: true,
      );
      final restored = CreateSavedQueryRequest.fromJson(req.toJson());
      expect(restored.isShared, isTrue);
    });
  });

  group('UpdateSavedQueryRequest', () {
    test('round-trip preserves data', () {
      const req = UpdateSavedQueryRequest(name: 'new name');
      expect(
        UpdateSavedQueryRequest.fromJson(req.toJson()).name,
        'new name',
      );
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Alert Channels
  // ═══════════════════════════════════════════════════════════════════════════

  group('AlertChannelResponse', () {
    test('fromJson deserializes all fields', () {
      final m = AlertChannelResponse.fromJson(<String, dynamic>{
        'id': 'ch-1',
        'name': 'Slack Channel',
        'channelType': 'SLACK',
        'configuration': '{"webhook":"https://..."}',
        'isActive': true,
        'teamId': 'team-1',
        'createdBy': 'user-1',
        'createdAt': '2026-02-01T00:00:00.000Z',
        'updatedAt': '2026-02-20T00:00:00.000Z',
      });
      expect(m.channelType.toJson(), 'SLACK');
      expect(m.configuration, contains('webhook'));
    });
  });

  group('CreateAlertChannelRequest', () {
    test('round-trip preserves data', () {
      final req = CreateAlertChannelRequest.fromJson(<String, dynamic>{
        'name': 'ch',
        'channelType': 'EMAIL',
        'configuration': '{}',
      });
      expect(req.channelType.toJson(), 'EMAIL');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Alert Rules & History
  // ═══════════════════════════════════════════════════════════════════════════

  group('AlertRuleResponse', () {
    test('fromJson deserializes all fields', () {
      final m = AlertRuleResponse.fromJson(<String, dynamic>{
        'id': 'rule-1',
        'name': 'Critical Error Rule',
        'trapId': 'trap-1',
        'trapName': 'Error Trap',
        'channelId': 'ch-1',
        'channelName': 'Slack',
        'severity': 'CRITICAL',
        'isActive': true,
        'throttleMinutes': 30,
        'teamId': 'team-1',
        'createdAt': '2026-02-01T00:00:00.000Z',
        'updatedAt': '2026-02-20T00:00:00.000Z',
      });
      expect(m.severity.toJson(), 'CRITICAL');
      expect(m.throttleMinutes, 30);
      expect(m.trapName, 'Error Trap');
    });
  });

  group('AlertHistoryResponse', () {
    test('fromJson deserializes all fields', () {
      final m = AlertHistoryResponse.fromJson(<String, dynamic>{
        'id': 'alert-1',
        'ruleId': 'rule-1',
        'ruleName': 'Rule',
        'trapId': 'trap-1',
        'trapName': 'Trap',
        'channelId': 'ch-1',
        'channelName': 'Slack',
        'severity': 'WARNING',
        'status': 'FIRED',
        'message': 'Alert fired',
        'acknowledgedBy': 'user-2',
        'acknowledgedAt': '2026-02-20T01:00:00.000Z',
        'resolvedBy': null,
        'resolvedAt': null,
        'teamId': 'team-1',
        'createdAt': '2026-02-20T00:00:00.000Z',
      });
      expect(m.status.toJson(), 'FIRED');
      expect(m.acknowledgedBy, 'user-2');
      expect(m.resolvedBy, isNull);
    });
  });

  group('CreateAlertRuleRequest', () {
    test('round-trip preserves data', () {
      final req = CreateAlertRuleRequest.fromJson(<String, dynamic>{
        'name': 'rule',
        'trapId': 'trap-1',
        'channelId': 'ch-1',
        'severity': 'INFO',
        'throttleMinutes': 15,
      });
      expect(req.severity.toJson(), 'INFO');
      expect(req.throttleMinutes, 15);
    });
  });

  group('UpdateAlertStatusRequest', () {
    test('round-trip preserves data', () {
      final req = UpdateAlertStatusRequest.fromJson(<String, dynamic>{
        'status': 'ACKNOWLEDGED',
      });
      expect(req.status.toJson(), 'ACKNOWLEDGED');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Metrics
  // ═══════════════════════════════════════════════════════════════════════════

  group('MetricResponse', () {
    test('fromJson deserializes all fields', () {
      final m = MetricResponse.fromJson(<String, dynamic>{
        'id': 'met-1',
        'name': 'request_latency',
        'metricType': 'HISTOGRAM',
        'description': 'Request latency',
        'unit': 'ms',
        'serviceName': 'api-gateway',
        'tags': '{"env":"prod"}',
        'teamId': 'team-1',
        'createdAt': '2026-02-01T00:00:00.000Z',
        'updatedAt': '2026-02-20T00:00:00.000Z',
      });
      expect(m.metricType.toJson(), 'HISTOGRAM');
      expect(m.unit, 'ms');
      expect(m.tags, contains('prod'));
    });
  });

  group('MetricDataPointResponse', () {
    test('fromJson deserializes all fields', () {
      final m = MetricDataPointResponse.fromJson(<String, dynamic>{
        'id': 'dp-1',
        'metricId': 'met-1',
        'timestamp': '2026-02-20T12:00:00.000Z',
        'value': 42.5,
        'tags': null,
        'resolution': 60,
      });
      expect(m.value, 42.5);
      expect(m.resolution, 60);
    });
  });

  group('TimeSeriesDataPoint', () {
    test('round-trip preserves data', () {
      final dp = TimeSeriesDataPoint.fromJson(<String, dynamic>{
        'timestamp': '2026-02-20T12:00:00.000Z',
        'value': 99.9,
        'tags': '{"region":"us"}',
      });
      final restored = TimeSeriesDataPoint.fromJson(dp.toJson());
      expect(restored.value, 99.9);
    });
  });

  group('MetricTimeSeriesResponse', () {
    test('fromJson deserializes nested dataPoints', () {
      final m = MetricTimeSeriesResponse.fromJson(<String, dynamic>{
        'metricId': 'met-1',
        'metricName': 'latency',
        'serviceName': 'svc',
        'metricType': 'GAUGE',
        'unit': 'ms',
        'startTime': '2026-02-20T00:00:00.000Z',
        'endTime': '2026-02-20T12:00:00.000Z',
        'resolution': 60,
        'dataPoints': [
          {
            'timestamp': '2026-02-20T00:00:00.000Z',
            'value': 10.0,
          },
          {
            'timestamp': '2026-02-20T01:00:00.000Z',
            'value': 20.0,
          },
        ],
      });
      expect(m.dataPoints, hasLength(2));
      expect(m.dataPoints.first.value, 10.0);
    });
  });

  group('MetricAggregationResponse', () {
    test('fromJson deserializes all stats', () {
      final m = MetricAggregationResponse.fromJson(<String, dynamic>{
        'metricId': 'met-1',
        'metricName': 'latency',
        'serviceName': 'svc',
        'startTime': '2026-02-20T00:00:00.000Z',
        'endTime': '2026-02-20T12:00:00.000Z',
        'dataPointCount': 720,
        'sum': 36000.0,
        'avg': 50.0,
        'min': 5.0,
        'max': 200.0,
        'p50': 45.0,
        'p95': 150.0,
        'p99': 190.0,
        'stddev': 30.0,
      });
      expect(m.avg, 50.0);
      expect(m.p95, 150.0);
      expect(m.stddev, 30.0);
    });
  });

  group('ServiceMetricsSummaryResponse', () {
    test('fromJson deserializes nested metrics', () {
      final m = ServiceMetricsSummaryResponse.fromJson(<String, dynamic>{
        'serviceName': 'svc',
        'metricCount': 2,
        'metricsByType': {'COUNTER': 1, 'GAUGE': 1},
        'metrics': [
          {
            'id': 'met-1',
            'name': 'requests',
            'metricType': 'COUNTER',
            'serviceName': 'svc',
            'teamId': 'team-1',
          },
        ],
      });
      expect(m.metricCount, 2);
      expect(m.metricsByType['COUNTER'], 1);
      expect(m.metrics, hasLength(1));
    });
  });

  group('RegisterMetricRequest', () {
    test('round-trip preserves data', () {
      final req = RegisterMetricRequest.fromJson(<String, dynamic>{
        'name': 'cpu',
        'metricType': 'GAUGE',
        'serviceName': 'svc',
        'unit': '%',
      });
      expect(req.metricType.toJson(), 'GAUGE');
      expect(req.unit, '%');
    });
  });

  group('MetricDataPoint', () {
    test('round-trip preserves data', () {
      final dp = MetricDataPoint.fromJson(<String, dynamic>{
        'timestamp': '2026-02-20T12:00:00.000Z',
        'value': 42.0,
      });
      final restored = MetricDataPoint.fromJson(dp.toJson());
      expect(restored.value, 42.0);
    });
  });

  group('PushMetricDataRequest', () {
    test('toJson serializes nested dataPoints', () {
      final req = PushMetricDataRequest.fromJson(<String, dynamic>{
        'metricId': 'met-1',
        'dataPoints': [
          {
            'timestamp': '2026-02-20T12:00:00.000Z',
            'value': 10.0,
          },
        ],
      });
      final json = req.toJson();
      expect((json['dataPoints'] as List), hasLength(1));
    });
  });

  group('MetricQueryRequest', () {
    test('round-trip preserves data', () {
      final req = MetricQueryRequest.fromJson(<String, dynamic>{
        'metricId': 'met-1',
        'startTime': '2026-02-20T00:00:00.000Z',
        'endTime': '2026-02-20T12:00:00.000Z',
        'resolution': 120,
      });
      expect(req.resolution, 120);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Dashboards & Widgets
  // ═══════════════════════════════════════════════════════════════════════════

  group('DashboardWidgetResponse', () {
    test('fromJson deserializes all fields', () {
      final m = DashboardWidgetResponse.fromJson(<String, dynamic>{
        'id': 'w-1',
        'dashboardId': 'dash-1',
        'title': 'Error Rate',
        'widgetType': 'TIME_SERIES_CHART',
        'queryJson': '{}',
        'configJson': '{}',
        'gridX': 0,
        'gridY': 0,
        'gridWidth': 6,
        'gridHeight': 4,
        'sortOrder': 1,
        'createdAt': '2026-02-01T00:00:00.000Z',
        'updatedAt': '2026-02-20T00:00:00.000Z',
      });
      expect(m.widgetType.toJson(), 'TIME_SERIES_CHART');
      expect(m.gridWidth, 6);
    });
  });

  group('DashboardResponse', () {
    test('fromJson deserializes nested widgets', () {
      final m = DashboardResponse.fromJson(<String, dynamic>{
        'id': 'dash-1',
        'name': 'Main Dashboard',
        'description': 'Overview',
        'teamId': 'team-1',
        'createdBy': 'user-1',
        'isShared': true,
        'isTemplate': false,
        'refreshIntervalSeconds': 30,
        'layoutJson': '{}',
        'widgets': [
          {
            'id': 'w-1',
            'dashboardId': 'dash-1',
            'title': 'Widget 1',
            'widgetType': 'COUNTER',
            'gridX': 0,
            'gridY': 0,
            'gridWidth': 3,
            'gridHeight': 2,
            'sortOrder': 0,
          },
        ],
        'createdAt': '2026-02-01T00:00:00.000Z',
        'updatedAt': '2026-02-20T00:00:00.000Z',
      });
      expect(m.name, 'Main Dashboard');
      expect(m.widgets, hasLength(1));
      expect(m.isShared, isTrue);
      expect(m.isTemplate, isFalse);
    });
  });

  group('CreateDashboardRequest', () {
    test('round-trip preserves data', () {
      const req = CreateDashboardRequest(name: 'new', isShared: true);
      final restored = CreateDashboardRequest.fromJson(req.toJson());
      expect(restored.isShared, isTrue);
    });
  });

  group('CreateDashboardWidgetRequest', () {
    test('round-trip preserves data', () {
      final req = CreateDashboardWidgetRequest.fromJson(<String, dynamic>{
        'title': 'w',
        'widgetType': 'GAUGE',
        'gridX': 0,
        'gridY': 0,
        'gridWidth': 4,
        'gridHeight': 3,
      });
      expect(req.widgetType.toJson(), 'GAUGE');
    });
  });

  group('WidgetPositionUpdate', () {
    test('round-trip preserves data', () {
      const u = WidgetPositionUpdate(
        widgetId: 'w-1',
        gridX: 1,
        gridY: 2,
        gridWidth: 3,
        gridHeight: 4,
      );
      final restored = WidgetPositionUpdate.fromJson(u.toJson());
      expect(restored.gridX, 1);
      expect(restored.gridHeight, 4);
    });
  });

  group('UpdateLayoutRequest', () {
    test('toJson serializes nested positions', () {
      const req = UpdateLayoutRequest(positions: [
        WidgetPositionUpdate(
          widgetId: 'w-1',
          gridX: 0,
          gridY: 0,
          gridWidth: 6,
          gridHeight: 4,
        ),
      ]);
      final json = req.toJson();
      expect((json['positions'] as List), hasLength(1));
    });
  });

  group('ReorderWidgetsRequest', () {
    test('round-trip preserves data', () {
      const req = ReorderWidgetsRequest(widgetIds: ['w-1', 'w-2']);
      final restored = ReorderWidgetsRequest.fromJson(req.toJson());
      expect(restored.widgetIds, ['w-1', 'w-2']);
    });
  });

  group('CreateFromTemplateRequest', () {
    test('round-trip preserves data', () {
      const req = CreateFromTemplateRequest(
        name: 'new',
        templateId: 'tmpl-1',
      );
      final restored = CreateFromTemplateRequest.fromJson(req.toJson());
      expect(restored.templateId, 'tmpl-1');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Traces & Spans
  // ═══════════════════════════════════════════════════════════════════════════

  group('TraceSpanResponse', () {
    final json = <String, dynamic>{
      'id': 'span-uuid-1',
      'correlationId': 'corr-1',
      'traceId': 'trace-1',
      'spanId': 'span-1',
      'parentSpanId': null,
      'serviceName': 'api-gateway',
      'operationName': 'GET /users',
      'startTime': '2026-02-20T12:00:00.000Z',
      'endTime': '2026-02-20T12:00:00.500Z',
      'durationMs': 500,
      'status': 'OK',
      'statusMessage': null,
      'tags': '{"method":"GET"}',
      'teamId': 'team-1',
      'createdAt': '2026-02-20T12:00:01.000Z',
    };

    test('fromJson deserializes all fields', () {
      final m = TraceSpanResponse.fromJson(json);
      expect(m.operationName, 'GET /users');
      expect(m.status.toJson(), 'OK');
      expect(m.durationMs, 500);
      expect(m.parentSpanId, isNull);
    });

    test('toJson round-trip preserves data', () {
      final restored = TraceSpanResponse.fromJson(
        TraceSpanResponse.fromJson(json).toJson(),
      );
      expect(restored.traceId, 'trace-1');
    });
  });

  group('TraceFlowResponse', () {
    test('fromJson deserializes nested spans', () {
      final m = TraceFlowResponse.fromJson(<String, dynamic>{
        'correlationId': 'corr-1',
        'traceId': 'trace-1',
        'spans': [
          {
            'id': 'span-uuid-1',
            'correlationId': 'corr-1',
            'traceId': 'trace-1',
            'spanId': 'span-1',
            'serviceName': 'svc',
            'operationName': 'op',
            'startTime': '2026-02-20T12:00:00.000Z',
            'status': 'OK',
            'teamId': 'team-1',
          },
        ],
        'totalDurationMs': 200,
        'spanCount': 1,
        'hasErrors': false,
      });
      expect(m.spans, hasLength(1));
      expect(m.hasErrors, isFalse);
    });
  });

  group('WaterfallSpan', () {
    test('fromJson deserializes all fields', () {
      final m = WaterfallSpan.fromJson(<String, dynamic>{
        'id': 'span-uuid-1',
        'spanId': 'span-1',
        'parentSpanId': null,
        'serviceName': 'svc',
        'operationName': 'op',
        'offsetMs': 0,
        'durationMs': 100,
        'status': 'ERROR',
        'statusMessage': 'timeout',
        'depth': 0,
        'relatedLogIds': ['log-1'],
      });
      expect(m.status.toJson(), 'ERROR');
      expect(m.depth, 0);
      expect(m.relatedLogIds, ['log-1']);
    });
  });

  group('TraceWaterfallResponse', () {
    test('fromJson deserializes nested spans', () {
      final m = TraceWaterfallResponse.fromJson(<String, dynamic>{
        'correlationId': 'corr-1',
        'traceId': 'trace-1',
        'totalDurationMs': 500,
        'spanCount': 1,
        'serviceCount': 1,
        'hasErrors': true,
        'spans': [
          {
            'id': 'span-uuid-1',
            'spanId': 'span-1',
            'serviceName': 'svc',
            'operationName': 'op',
            'offsetMs': 0,
            'durationMs': 500,
            'status': 'ERROR',
            'depth': 0,
            'relatedLogIds': [],
          },
        ],
      });
      expect(m.hasErrors, isTrue);
      expect(m.spans, hasLength(1));
    });
  });

  group('TraceListResponse', () {
    test('fromJson deserializes all fields', () {
      final m = TraceListResponse.fromJson(<String, dynamic>{
        'correlationId': 'corr-1',
        'traceId': 'trace-1',
        'rootService': 'api-gateway',
        'rootOperation': 'GET /users',
        'spanCount': 5,
        'serviceCount': 3,
        'totalDurationMs': 1200,
        'hasErrors': false,
        'startTime': '2026-02-20T12:00:00.000Z',
        'endTime': '2026-02-20T12:00:01.200Z',
      });
      expect(m.rootService, 'api-gateway');
      expect(m.spanCount, 5);
      expect(m.serviceCount, 3);
    });
  });

  group('RootCauseAnalysisResponse', () {
    test('fromJson deserializes nested data', () {
      final m = RootCauseAnalysisResponse.fromJson(<String, dynamic>{
        'correlationId': 'corr-1',
        'traceId': 'trace-1',
        'rootCauseSpan': {
          'id': 'span-uuid-1',
          'correlationId': 'corr-1',
          'traceId': 'trace-1',
          'spanId': 'span-3',
          'serviceName': 'db-service',
          'operationName': 'query',
          'startTime': '2026-02-20T12:00:00.000Z',
          'status': 'ERROR',
          'statusMessage': 'connection refused',
          'teamId': 'team-1',
        },
        'rootCauseService': 'db-service',
        'rootCauseMessage': 'connection refused',
        'errorChain': [],
        'relatedLogEntryIds': ['log-1', 'log-2'],
        'impactedServiceCount': 2,
        'totalDurationMs': 1200,
      });
      expect(m.rootCauseService, 'db-service');
      expect(m.relatedLogEntryIds, hasLength(2));
      expect(m.impactedServiceCount, 2);
    });
  });

  group('CreateTraceSpanRequest', () {
    test('round-trip preserves data', () {
      final req = CreateTraceSpanRequest.fromJson(<String, dynamic>{
        'correlationId': 'corr-1',
        'traceId': 'trace-1',
        'spanId': 'span-1',
        'serviceName': 'svc',
        'operationName': 'op',
        'startTime': '2026-02-20T12:00:00.000Z',
        'status': 'OK',
      });
      expect(req.status?.toJson(), 'OK');
      expect(req.serviceName, 'svc');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Retention Policies & Storage
  // ═══════════════════════════════════════════════════════════════════════════

  group('RetentionPolicyResponse', () {
    test('fromJson deserializes all fields', () {
      final m = RetentionPolicyResponse.fromJson(<String, dynamic>{
        'id': 'ret-1',
        'name': '30-Day Purge',
        'sourceName': 'auth-service',
        'logLevel': 'DEBUG',
        'retentionDays': 30,
        'action': 'PURGE',
        'archiveDestination': null,
        'isActive': true,
        'teamId': 'team-1',
        'createdBy': 'user-1',
        'lastExecutedAt': '2026-02-20T00:00:00.000Z',
        'createdAt': '2026-02-01T00:00:00.000Z',
        'updatedAt': '2026-02-20T00:00:00.000Z',
      });
      expect(m.retentionDays, 30);
      expect(m.action.toJson(), 'PURGE');
      expect(m.logLevel?.toJson(), 'DEBUG');
    });
  });

  group('StorageUsageResponse', () {
    test('fromJson deserializes all fields', () {
      final m = StorageUsageResponse.fromJson(<String, dynamic>{
        'totalLogEntries': 1000000,
        'totalMetricDataPoints': 500000,
        'totalTraceSpans': 250000,
        'logEntriesByService': {'auth': 600000, 'api': 400000},
        'logEntriesByLevel': {'ERROR': 5000, 'INFO': 900000},
        'activeRetentionPolicies': 3,
        'oldestLogEntry': '2026-01-01T00:00:00.000Z',
        'newestLogEntry': '2026-02-20T12:00:00.000Z',
      });
      expect(m.totalLogEntries, 1000000);
      expect(m.logEntriesByService['auth'], 600000);
      expect(m.activeRetentionPolicies, 3);
    });
  });

  group('CreateRetentionPolicyRequest', () {
    test('round-trip preserves data', () {
      final req = CreateRetentionPolicyRequest.fromJson(<String, dynamic>{
        'name': 'policy',
        'retentionDays': 90,
        'action': 'ARCHIVE',
        'archiveDestination': 's3://backup',
        'logLevel': 'WARN',
      });
      expect(req.action.toJson(), 'ARCHIVE');
      expect(req.logLevel?.toJson(), 'WARN');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Anomaly Detection
  // ═══════════════════════════════════════════════════════════════════════════

  group('AnomalyBaselineResponse', () {
    test('fromJson deserializes all fields', () {
      final m = AnomalyBaselineResponse.fromJson(<String, dynamic>{
        'id': 'bl-1',
        'serviceName': 'api-gateway',
        'metricName': 'latency',
        'baselineValue': 50.0,
        'standardDeviation': 10.0,
        'sampleCount': 1000,
        'windowStartTime': '2026-02-01T00:00:00.000Z',
        'windowEndTime': '2026-02-20T00:00:00.000Z',
        'deviationThreshold': 2.0,
        'isActive': true,
        'teamId': 'team-1',
        'lastComputedAt': '2026-02-20T00:00:00.000Z',
        'createdAt': '2026-02-01T00:00:00.000Z',
        'updatedAt': '2026-02-20T00:00:00.000Z',
      });
      expect(m.baselineValue, 50.0);
      expect(m.standardDeviation, 10.0);
      expect(m.deviationThreshold, 2.0);
    });
  });

  group('AnomalyCheckResponse', () {
    test('fromJson deserializes all fields', () {
      final m = AnomalyCheckResponse.fromJson(<String, dynamic>{
        'serviceName': 'api-gateway',
        'metricName': 'latency',
        'currentValue': 120.0,
        'baselineValue': 50.0,
        'standardDeviation': 10.0,
        'deviationThreshold': 2.0,
        'zScore': 7.0,
        'isAnomaly': true,
        'direction': 'above',
        'checkedAt': '2026-02-20T12:00:00.000Z',
      });
      expect(m.isAnomaly, isTrue);
      expect(m.zScore, 7.0);
      expect(m.direction, 'above');
    });
  });

  group('AnomalyReportResponse', () {
    test('fromJson deserializes nested checks', () {
      final m = AnomalyReportResponse.fromJson(<String, dynamic>{
        'teamId': 'team-1',
        'generatedAt': '2026-02-20T12:00:00.000Z',
        'totalBaselines': 5,
        'anomaliesDetected': 1,
        'anomalies': [
          {
            'serviceName': 'svc',
            'metricName': 'latency',
            'currentValue': 200.0,
            'baselineValue': 50.0,
            'standardDeviation': 10.0,
            'deviationThreshold': 2.0,
            'zScore': 15.0,
            'isAnomaly': true,
            'direction': 'above',
            'checkedAt': '2026-02-20T12:00:00.000Z',
          },
        ],
        'allChecks': [],
      });
      expect(m.anomaliesDetected, 1);
      expect(m.anomalies, hasLength(1));
      expect(m.anomalies.first.isAnomaly, isTrue);
    });
  });

  group('CreateBaselineRequest', () {
    test('round-trip preserves data', () {
      const req = CreateBaselineRequest(
        serviceName: 'svc',
        metricName: 'latency',
        windowHours: 168,
        deviationThreshold: 3.0,
      );
      final restored = CreateBaselineRequest.fromJson(req.toJson());
      expect(restored.windowHours, 168);
      expect(restored.deviationThreshold, 3.0);
    });
  });

  group('UpdateBaselineRequest', () {
    test('round-trip preserves data', () {
      const req = UpdateBaselineRequest(
        windowHours: 720,
        isActive: false,
      );
      final restored = UpdateBaselineRequest.fromJson(req.toJson());
      expect(restored.windowHours, 720);
      expect(restored.isActive, isFalse);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Ingestion Stats
  // ═══════════════════════════════════════════════════════════════════════════

  group('IngestionStatsResponse', () {
    test('fromJson deserializes all fields', () {
      final m = IngestionStatsResponse.fromJson(<String, dynamic>{
        'totalLogsIngested': 5000000,
        'logsPerSecond': 150.5,
        'activeSourceCount': 12,
        'logsByLevel': {'INFO': 4000000, 'ERROR': 50000},
        'logsByService': {'auth': 2000000, 'api': 3000000},
        'since': '2026-02-20T00:00:00.000Z',
      });
      expect(m.totalLogsIngested, 5000000);
      expect(m.logsPerSecond, 150.5);
      expect(m.logsByLevel['INFO'], 4000000);
      expect(m.logsByService['api'], 3000000);
    });
  });
}
