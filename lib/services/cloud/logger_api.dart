/// API service for all CodeOps-Logger endpoints.
///
/// Covers log ingestion, structured/DSL queries, sources, traps, alerts,
/// metrics, dashboards, traces, retention policies, anomaly detection,
/// and saved queries.
/// All 104 endpoints from the 10 Logger controllers are represented here.
///
/// Logger endpoints use the `X-Team-Id` request header for team
/// identification, unlike Registry which uses path-based team IDs.
library;

import 'package:dio/dio.dart';

import '../../models/health_snapshot.dart';
import '../../models/logger_enums.dart';
import '../../models/logger_models.dart';
import 'api_client.dart';

/// API service for CodeOps-Logger endpoints.
///
/// Provides typed methods for every Logger endpoint, organized by
/// controller: Ingestion, Query, Sources, Metrics, Alerts, Dashboards,
/// Retention, Traces, Traps, and Anomalies.
class LoggerApi {
  final ApiClient _client;

  /// Creates a [LoggerApi] backed by the given [client].
  LoggerApi(this._client);

  /// Builds [Options] with the `X-Team-Id` header.
  Options _teamOpts(String teamId) =>
      Options(headers: {'X-Team-Id': teamId});

  // ═══════════════════════════════════════════════════════════════════════════
  // Log Ingestion (2 endpoints)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Ingests a single log entry.
  Future<LogEntryResponse> ingestLogEntry(
    String teamId, {
    required LogLevel level,
    required String message,
    required String serviceName,
    DateTime? timestamp,
    String? correlationId,
    String? traceId,
    String? spanId,
    String? loggerName,
    String? threadName,
    String? exceptionClass,
    String? exceptionMessage,
    String? stackTrace,
    String? customFields,
    String? hostName,
    String? ipAddress,
  }) async {
    final body = <String, dynamic>{
      'level': level.toJson(),
      'message': message,
      'serviceName': serviceName,
    };
    if (timestamp != null) body['timestamp'] = timestamp.toUtc().toIso8601String();
    if (correlationId != null) body['correlationId'] = correlationId;
    if (traceId != null) body['traceId'] = traceId;
    if (spanId != null) body['spanId'] = spanId;
    if (loggerName != null) body['loggerName'] = loggerName;
    if (threadName != null) body['threadName'] = threadName;
    if (exceptionClass != null) body['exceptionClass'] = exceptionClass;
    if (exceptionMessage != null) body['exceptionMessage'] = exceptionMessage;
    if (stackTrace != null) body['stackTrace'] = stackTrace;
    if (customFields != null) body['customFields'] = customFields;
    if (hostName != null) body['hostName'] = hostName;
    if (ipAddress != null) body['ipAddress'] = ipAddress;

    final response = await _client.dio.post<Map<String, dynamic>>(
      '/logger/logs',
      data: body,
      options: _teamOpts(teamId),
    );
    return LogEntryResponse.fromJson(response.data!);
  }

  /// Ingests a batch of log entries (1–1000).
  ///
  /// Returns a map with `ingested` (count) and `total` (submitted) keys.
  Future<Map<String, dynamic>> ingestLogBatch(
    String teamId, {
    required List<IngestLogEntryRequest> entries,
  }) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/logger/logs/batch',
      data: {'entries': entries.map((e) => e.toJson()).toList()},
      options: _teamOpts(teamId),
    );
    return response.data!;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Log Query (11 endpoints)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Executes a structured log query.
  Future<PageResponse<LogEntryResponse>> queryLogs(
    String teamId, {
    String? serviceName,
    LogLevel? level,
    DateTime? startTime,
    DateTime? endTime,
    String? correlationId,
    String? query,
    String? loggerName,
    String? exceptionClass,
    String? hostName,
    int page = 0,
    int size = 20,
  }) async {
    final body = <String, dynamic>{'page': page, 'size': size};
    if (serviceName != null) body['serviceName'] = serviceName;
    if (level != null) body['level'] = level.toJson();
    if (startTime != null) body['startTime'] = startTime.toUtc().toIso8601String();
    if (endTime != null) body['endTime'] = endTime.toUtc().toIso8601String();
    if (correlationId != null) body['correlationId'] = correlationId;
    if (query != null) body['query'] = query;
    if (loggerName != null) body['loggerName'] = loggerName;
    if (exceptionClass != null) body['exceptionClass'] = exceptionClass;
    if (hostName != null) body['hostName'] = hostName;

    final response = await _client.dio.post<Map<String, dynamic>>(
      '/logger/logs/query',
      data: body,
      options: _teamOpts(teamId),
    );
    return PageResponse.fromJson(
      response.data!,
      (json) => LogEntryResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Searches logs by full-text query string.
  Future<PageResponse<LogEntryResponse>> searchLogs(
    String teamId, {
    required String q,
    DateTime? startTime,
    DateTime? endTime,
    int page = 0,
    int size = 20,
  }) async {
    final params = <String, dynamic>{
      'q': q,
      'page': page,
      'size': size,
    };
    if (startTime != null) params['startTime'] = startTime.toUtc().toIso8601String();
    if (endTime != null) params['endTime'] = endTime.toUtc().toIso8601String();

    final response = await _client.dio.get<Map<String, dynamic>>(
      '/logger/logs/search',
      queryParameters: params,
      options: _teamOpts(teamId),
    );
    return PageResponse.fromJson(
      response.data!,
      (json) => LogEntryResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Executes a DSL log query.
  Future<PageResponse<LogEntryResponse>> queryLogsDsl(
    String teamId, {
    required String query,
    int? page,
    int? size,
  }) async {
    final body = <String, dynamic>{'query': query};
    if (page != null) body['page'] = page;
    if (size != null) body['size'] = size;

    final response = await _client.dio.post<Map<String, dynamic>>(
      '/logger/logs/dsl',
      data: body,
      options: _teamOpts(teamId),
    );
    return PageResponse.fromJson(
      response.data!,
      (json) => LogEntryResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Retrieves a single log entry by ID.
  Future<LogEntryResponse> getLogEntry(String id) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/logger/logs/$id',
    );
    return LogEntryResponse.fromJson(response.data!);
  }

  /// Creates a saved query.
  Future<SavedQueryResponse> createSavedQuery(
    String teamId, {
    required String name,
    required String queryJson,
    String? description,
    String? queryDsl,
    bool? isShared,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'queryJson': queryJson,
    };
    if (description != null) body['description'] = description;
    if (queryDsl != null) body['queryDsl'] = queryDsl;
    if (isShared != null) body['isShared'] = isShared;

    final response = await _client.dio.post<Map<String, dynamic>>(
      '/logger/logs/queries/saved',
      data: body,
      options: _teamOpts(teamId),
    );
    return SavedQueryResponse.fromJson(response.data!);
  }

  /// Lists all saved queries for the team.
  Future<List<SavedQueryResponse>> listSavedQueries(String teamId) async {
    final response = await _client.dio.get<List<dynamic>>(
      '/logger/logs/queries/saved',
      options: _teamOpts(teamId),
    );
    return response.data!
        .map((e) => SavedQueryResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Retrieves a saved query by ID.
  Future<SavedQueryResponse> getSavedQuery(String queryId) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/logger/logs/queries/saved/$queryId',
    );
    return SavedQueryResponse.fromJson(response.data!);
  }

  /// Updates an existing saved query.
  Future<SavedQueryResponse> updateSavedQuery(
    String queryId, {
    String? name,
    String? description,
    String? queryJson,
    String? queryDsl,
    bool? isShared,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (description != null) body['description'] = description;
    if (queryJson != null) body['queryJson'] = queryJson;
    if (queryDsl != null) body['queryDsl'] = queryDsl;
    if (isShared != null) body['isShared'] = isShared;

    final response = await _client.dio.put<Map<String, dynamic>>(
      '/logger/logs/queries/saved/$queryId',
      data: body,
    );
    return SavedQueryResponse.fromJson(response.data!);
  }

  /// Deletes a saved query.
  Future<void> deleteSavedQuery(String queryId) async {
    await _client.dio.delete('/logger/logs/queries/saved/$queryId');
  }

  /// Executes a saved query and returns paginated results.
  Future<PageResponse<LogEntryResponse>> executeSavedQuery(
    String teamId,
    String queryId, {
    int page = 0,
    int size = 20,
  }) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/logger/logs/queries/saved/$queryId/execute',
      queryParameters: {'page': page, 'size': size},
      options: _teamOpts(teamId),
    );
    return PageResponse.fromJson(
      response.data!,
      (json) => LogEntryResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Retrieves paginated query execution history.
  Future<PageResponse<QueryHistoryResponse>> getQueryHistory({
    int page = 0,
    int size = 20,
  }) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/logger/logs/queries/history',
      queryParameters: {'page': page, 'size': size},
    );
    return PageResponse.fromJson(
      response.data!,
      (json) => QueryHistoryResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Log Sources (6 endpoints)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Creates a new log source.
  Future<LogSourceResponse> createLogSource(
    String teamId, {
    required String name,
    String? serviceId,
    String? description,
    String? environment,
  }) async {
    final body = <String, dynamic>{'name': name};
    if (serviceId != null) body['serviceId'] = serviceId;
    if (description != null) body['description'] = description;
    if (environment != null) body['environment'] = environment;

    final response = await _client.dio.post<Map<String, dynamic>>(
      '/logger/sources',
      data: body,
      options: _teamOpts(teamId),
    );
    return LogSourceResponse.fromJson(response.data!);
  }

  /// Lists all log sources for the team.
  Future<List<LogSourceResponse>> listLogSources(String teamId) async {
    final response = await _client.dio.get<List<dynamic>>(
      '/logger/sources',
      options: _teamOpts(teamId),
    );
    return response.data!
        .map((e) => LogSourceResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Lists log sources with pagination.
  Future<PageResponse<LogSourceResponse>> listLogSourcesPaged(
    String teamId, {
    int page = 0,
    int size = 20,
  }) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/logger/sources/paged',
      queryParameters: {'page': page, 'size': size},
      options: _teamOpts(teamId),
    );
    return PageResponse.fromJson(
      response.data!,
      (json) => LogSourceResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Retrieves a log source by ID.
  Future<LogSourceResponse> getLogSource(String sourceId) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/logger/sources/$sourceId',
    );
    return LogSourceResponse.fromJson(response.data!);
  }

  /// Updates an existing log source.
  Future<LogSourceResponse> updateLogSource(
    String sourceId, {
    String? name,
    String? description,
    String? environment,
    bool? isActive,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (description != null) body['description'] = description;
    if (environment != null) body['environment'] = environment;
    if (isActive != null) body['isActive'] = isActive;

    final response = await _client.dio.put<Map<String, dynamic>>(
      '/logger/sources/$sourceId',
      data: body,
    );
    return LogSourceResponse.fromJson(response.data!);
  }

  /// Deletes a log source.
  Future<void> deleteLogSource(String sourceId) async {
    await _client.dio.delete('/logger/sources/$sourceId');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Metrics (14 endpoints)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Registers a new metric.
  Future<MetricResponse> registerMetric(
    String teamId, {
    required String name,
    required MetricType metricType,
    required String serviceName,
    String? description,
    String? unit,
    String? tags,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'metricType': metricType.toJson(),
      'serviceName': serviceName,
    };
    if (description != null) body['description'] = description;
    if (unit != null) body['unit'] = unit;
    if (tags != null) body['tags'] = tags;

    final response = await _client.dio.post<Map<String, dynamic>>(
      '/logger/metrics',
      data: body,
      options: _teamOpts(teamId),
    );
    return MetricResponse.fromJson(response.data!);
  }

  /// Lists all metrics for the team.
  Future<List<MetricResponse>> listMetrics(String teamId) async {
    final response = await _client.dio.get<List<dynamic>>(
      '/logger/metrics',
      options: _teamOpts(teamId),
    );
    return response.data!
        .map((e) => MetricResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Lists metrics with pagination.
  Future<PageResponse<MetricResponse>> listMetricsPaged(
    String teamId, {
    int page = 0,
    int size = 20,
  }) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/logger/metrics/paged',
      queryParameters: {'page': page, 'size': size},
      options: _teamOpts(teamId),
    );
    return PageResponse.fromJson(
      response.data!,
      (json) => MetricResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Lists metrics for a specific service.
  Future<List<MetricResponse>> listMetricsByService(
    String teamId,
    String serviceName,
  ) async {
    final response = await _client.dio.get<List<dynamic>>(
      '/logger/metrics/service/$serviceName',
      options: _teamOpts(teamId),
    );
    return response.data!
        .map((e) => MetricResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Gets a summary of metrics for a service.
  Future<ServiceMetricsSummaryResponse> getServiceMetricsSummary(
    String teamId,
    String serviceName,
  ) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/logger/metrics/service/$serviceName/summary',
      options: _teamOpts(teamId),
    );
    return ServiceMetricsSummaryResponse.fromJson(response.data!);
  }

  /// Retrieves a metric by ID.
  Future<MetricResponse> getMetric(String metricId) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/logger/metrics/$metricId',
    );
    return MetricResponse.fromJson(response.data!);
  }

  /// Updates an existing metric.
  Future<MetricResponse> updateMetric(
    String metricId, {
    String? description,
    String? unit,
    String? tags,
  }) async {
    final body = <String, dynamic>{};
    if (description != null) body['description'] = description;
    if (unit != null) body['unit'] = unit;
    if (tags != null) body['tags'] = tags;

    final response = await _client.dio.put<Map<String, dynamic>>(
      '/logger/metrics/$metricId',
      data: body,
    );
    return MetricResponse.fromJson(response.data!);
  }

  /// Deletes a metric.
  Future<void> deleteMetric(String metricId) async {
    await _client.dio.delete('/logger/metrics/$metricId');
  }

  /// Pushes metric data points (1–1000).
  ///
  /// Returns a map with `ingested` and `total` keys.
  Future<Map<String, dynamic>> pushMetricData(
    String teamId, {
    required String metricId,
    required List<MetricDataPoint> dataPoints,
  }) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/logger/metrics/data',
      data: {
        'metricId': metricId,
        'dataPoints': dataPoints.map((e) => e.toJson()).toList(),
      },
      options: _teamOpts(teamId),
    );
    return response.data!;
  }

  /// Gets time-series data for a metric.
  Future<MetricTimeSeriesResponse> getMetricTimeSeries(
    String metricId, {
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/logger/metrics/$metricId/timeseries',
      queryParameters: {
        'startTime': startTime.toUtc().toIso8601String(),
        'endTime': endTime.toUtc().toIso8601String(),
      },
    );
    return MetricTimeSeriesResponse.fromJson(response.data!);
  }

  /// Gets aggregated time-series data for a metric.
  Future<MetricTimeSeriesResponse> getMetricTimeSeriesAggregated(
    String metricId, {
    required DateTime startTime,
    required DateTime endTime,
    int resolution = 60,
  }) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/logger/metrics/$metricId/timeseries/aggregated',
      queryParameters: {
        'startTime': startTime.toUtc().toIso8601String(),
        'endTime': endTime.toUtc().toIso8601String(),
        'resolution': resolution,
      },
    );
    return MetricTimeSeriesResponse.fromJson(response.data!);
  }

  /// Gets statistical aggregation for a metric over a time range.
  Future<MetricAggregationResponse> getMetricAggregation(
    String metricId, {
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/logger/metrics/$metricId/aggregation',
      queryParameters: {
        'startTime': startTime.toUtc().toIso8601String(),
        'endTime': endTime.toUtc().toIso8601String(),
      },
    );
    return MetricAggregationResponse.fromJson(response.data!);
  }

  /// Gets the latest data point for a metric.
  ///
  /// Returns `null` if no data points exist.
  Future<MetricDataPointResponse?> getLatestMetricDataPoint(
    String metricId,
  ) async {
    final response = await _client.dio.get<Map<String, dynamic>?>(
      '/logger/metrics/$metricId/latest',
    );
    if (response.statusCode == 204 || response.data == null) return null;
    return MetricDataPointResponse.fromJson(response.data!);
  }

  /// Gets the latest metric values for all metrics of a service.
  ///
  /// Returns a map of metric name to latest value.
  Future<Map<String, double>> getLatestMetricsByService(
    String teamId,
    String serviceName,
  ) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/logger/metrics/service/$serviceName/latest',
      options: _teamOpts(teamId),
    );
    return response.data!.map((k, v) => MapEntry(k, (v as num).toDouble()));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Alert Channels (6 endpoints)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Creates a new alert channel.
  Future<AlertChannelResponse> createAlertChannel(
    String teamId, {
    required String name,
    required AlertChannelType channelType,
    required String configuration,
  }) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/logger/alerts/channels',
      data: {
        'name': name,
        'channelType': channelType.toJson(),
        'configuration': configuration,
      },
      options: _teamOpts(teamId),
    );
    return AlertChannelResponse.fromJson(response.data!);
  }

  /// Lists all alert channels for the team.
  Future<List<AlertChannelResponse>> listAlertChannels(
    String teamId,
  ) async {
    final response = await _client.dio.get<List<dynamic>>(
      '/logger/alerts/channels',
      options: _teamOpts(teamId),
    );
    return response.data!
        .map((e) => AlertChannelResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Lists alert channels with pagination.
  Future<PageResponse<AlertChannelResponse>> listAlertChannelsPaged(
    String teamId, {
    int page = 0,
    int size = 20,
  }) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/logger/alerts/channels/paged',
      queryParameters: {'page': page, 'size': size},
      options: _teamOpts(teamId),
    );
    return PageResponse.fromJson(
      response.data!,
      (json) =>
          AlertChannelResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Retrieves an alert channel by ID.
  Future<AlertChannelResponse> getAlertChannel(String channelId) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/logger/alerts/channels/$channelId',
    );
    return AlertChannelResponse.fromJson(response.data!);
  }

  /// Updates an existing alert channel.
  Future<AlertChannelResponse> updateAlertChannel(
    String channelId, {
    String? name,
    String? configuration,
    bool? isActive,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (configuration != null) body['configuration'] = configuration;
    if (isActive != null) body['isActive'] = isActive;

    final response = await _client.dio.put<Map<String, dynamic>>(
      '/logger/alerts/channels/$channelId',
      data: body,
    );
    return AlertChannelResponse.fromJson(response.data!);
  }

  /// Deletes an alert channel.
  Future<void> deleteAlertChannel(String channelId) async {
    await _client.dio.delete('/logger/alerts/channels/$channelId');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Alert Rules (6 endpoints)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Creates a new alert rule.
  Future<AlertRuleResponse> createAlertRule(
    String teamId, {
    required String name,
    required String trapId,
    required String channelId,
    required AlertSeverity severity,
    int? throttleMinutes,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'trapId': trapId,
      'channelId': channelId,
      'severity': severity.toJson(),
    };
    if (throttleMinutes != null) body['throttleMinutes'] = throttleMinutes;

    final response = await _client.dio.post<Map<String, dynamic>>(
      '/logger/alerts/rules',
      data: body,
      options: _teamOpts(teamId),
    );
    return AlertRuleResponse.fromJson(response.data!);
  }

  /// Lists all alert rules for the team.
  Future<List<AlertRuleResponse>> listAlertRules(String teamId) async {
    final response = await _client.dio.get<List<dynamic>>(
      '/logger/alerts/rules',
      options: _teamOpts(teamId),
    );
    return response.data!
        .map((e) => AlertRuleResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Lists alert rules with pagination.
  Future<PageResponse<AlertRuleResponse>> listAlertRulesPaged(
    String teamId, {
    int page = 0,
    int size = 20,
  }) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/logger/alerts/rules/paged',
      queryParameters: {'page': page, 'size': size},
      options: _teamOpts(teamId),
    );
    return PageResponse.fromJson(
      response.data!,
      (json) => AlertRuleResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Retrieves an alert rule by ID.
  Future<AlertRuleResponse> getAlertRule(String ruleId) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/logger/alerts/rules/$ruleId',
    );
    return AlertRuleResponse.fromJson(response.data!);
  }

  /// Updates an existing alert rule.
  Future<AlertRuleResponse> updateAlertRule(
    String ruleId, {
    String? name,
    String? trapId,
    String? channelId,
    AlertSeverity? severity,
    bool? isActive,
    int? throttleMinutes,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (trapId != null) body['trapId'] = trapId;
    if (channelId != null) body['channelId'] = channelId;
    if (severity != null) body['severity'] = severity.toJson();
    if (isActive != null) body['isActive'] = isActive;
    if (throttleMinutes != null) body['throttleMinutes'] = throttleMinutes;

    final response = await _client.dio.put<Map<String, dynamic>>(
      '/logger/alerts/rules/$ruleId',
      data: body,
    );
    return AlertRuleResponse.fromJson(response.data!);
  }

  /// Deletes an alert rule.
  Future<void> deleteAlertRule(String ruleId) async {
    await _client.dio.delete('/logger/alerts/rules/$ruleId');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Alert History (5 endpoints)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Retrieves paginated alert history.
  Future<PageResponse<AlertHistoryResponse>> getAlertHistory(
    String teamId, {
    int page = 0,
    int size = 20,
  }) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/logger/alerts/history',
      queryParameters: {'page': page, 'size': size},
      options: _teamOpts(teamId),
    );
    return PageResponse.fromJson(
      response.data!,
      (json) =>
          AlertHistoryResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Retrieves alert history filtered by status.
  Future<PageResponse<AlertHistoryResponse>> getAlertHistoryByStatus(
    String teamId,
    AlertStatus status, {
    int page = 0,
    int size = 20,
  }) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/logger/alerts/history/status/${status.toJson()}',
      queryParameters: {'page': page, 'size': size},
      options: _teamOpts(teamId),
    );
    return PageResponse.fromJson(
      response.data!,
      (json) =>
          AlertHistoryResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Retrieves alert history filtered by severity.
  Future<PageResponse<AlertHistoryResponse>> getAlertHistoryBySeverity(
    String teamId,
    AlertSeverity severity, {
    int page = 0,
    int size = 20,
  }) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/logger/alerts/history/severity/${severity.toJson()}',
      queryParameters: {'page': page, 'size': size},
      options: _teamOpts(teamId),
    );
    return PageResponse.fromJson(
      response.data!,
      (json) =>
          AlertHistoryResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Updates the status of an alert (acknowledge/resolve).
  Future<AlertHistoryResponse> updateAlertStatus(
    String alertId, {
    required AlertStatus status,
  }) async {
    final response = await _client.dio.put<Map<String, dynamic>>(
      '/logger/alerts/history/$alertId/status',
      data: {'status': status.toJson()},
    );
    return AlertHistoryResponse.fromJson(response.data!);
  }

  /// Gets active alert counts by severity.
  Future<Map<String, int>> getActiveAlertCounts(String teamId) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/logger/alerts/active-counts',
      options: _teamOpts(teamId),
    );
    return response.data!.map((k, v) => MapEntry(k, (v as num).toInt()));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Dashboards (18 endpoints)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Creates a new dashboard.
  Future<DashboardResponse> createDashboard(
    String teamId, {
    required String name,
    String? description,
    bool? isShared,
    int? refreshIntervalSeconds,
    String? layoutJson,
  }) async {
    final body = <String, dynamic>{'name': name};
    if (description != null) body['description'] = description;
    if (isShared != null) body['isShared'] = isShared;
    if (refreshIntervalSeconds != null) {
      body['refreshIntervalSeconds'] = refreshIntervalSeconds;
    }
    if (layoutJson != null) body['layoutJson'] = layoutJson;

    final response = await _client.dio.post<Map<String, dynamic>>(
      '/logger/dashboards',
      data: body,
      options: _teamOpts(teamId),
    );
    return DashboardResponse.fromJson(response.data!);
  }

  /// Lists all dashboards for the team.
  Future<List<DashboardResponse>> listDashboards(String teamId) async {
    final response = await _client.dio.get<List<dynamic>>(
      '/logger/dashboards',
      options: _teamOpts(teamId),
    );
    return response.data!
        .map((e) => DashboardResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Lists dashboards with pagination.
  Future<PageResponse<DashboardResponse>> listDashboardsPaged(
    String teamId, {
    int page = 0,
    int size = 20,
  }) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/logger/dashboards/paged',
      queryParameters: {'page': page, 'size': size},
      options: _teamOpts(teamId),
    );
    return PageResponse.fromJson(
      response.data!,
      (json) => DashboardResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Lists shared dashboards for the team.
  Future<List<DashboardResponse>> listSharedDashboards(
    String teamId,
  ) async {
    final response = await _client.dio.get<List<dynamic>>(
      '/logger/dashboards/shared',
      options: _teamOpts(teamId),
    );
    return response.data!
        .map((e) => DashboardResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Lists dashboards created by the current user.
  Future<List<DashboardResponse>> listMyDashboards() async {
    final response = await _client.dio.get<List<dynamic>>(
      '/logger/dashboards/mine',
    );
    return response.data!
        .map((e) => DashboardResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Retrieves a dashboard by ID (includes widgets).
  Future<DashboardResponse> getDashboard(String dashboardId) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/logger/dashboards/$dashboardId',
    );
    return DashboardResponse.fromJson(response.data!);
  }

  /// Updates an existing dashboard.
  Future<DashboardResponse> updateDashboard(
    String dashboardId, {
    String? name,
    String? description,
    bool? isShared,
    bool? isTemplate,
    int? refreshIntervalSeconds,
    String? layoutJson,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (description != null) body['description'] = description;
    if (isShared != null) body['isShared'] = isShared;
    if (isTemplate != null) body['isTemplate'] = isTemplate;
    if (refreshIntervalSeconds != null) {
      body['refreshIntervalSeconds'] = refreshIntervalSeconds;
    }
    if (layoutJson != null) body['layoutJson'] = layoutJson;

    final response = await _client.dio.put<Map<String, dynamic>>(
      '/logger/dashboards/$dashboardId',
      data: body,
    );
    return DashboardResponse.fromJson(response.data!);
  }

  /// Deletes a dashboard.
  Future<void> deleteDashboard(String dashboardId) async {
    await _client.dio.delete('/logger/dashboards/$dashboardId');
  }

  /// Creates a widget on a dashboard.
  Future<DashboardWidgetResponse> createDashboardWidget(
    String dashboardId, {
    required String title,
    required WidgetType widgetType,
    String? queryJson,
    String? configJson,
    int? gridX,
    int? gridY,
    int? gridWidth,
    int? gridHeight,
    int? sortOrder,
  }) async {
    final body = <String, dynamic>{
      'title': title,
      'widgetType': widgetType.toJson(),
    };
    if (queryJson != null) body['queryJson'] = queryJson;
    if (configJson != null) body['configJson'] = configJson;
    if (gridX != null) body['gridX'] = gridX;
    if (gridY != null) body['gridY'] = gridY;
    if (gridWidth != null) body['gridWidth'] = gridWidth;
    if (gridHeight != null) body['gridHeight'] = gridHeight;
    if (sortOrder != null) body['sortOrder'] = sortOrder;

    final response = await _client.dio.post<Map<String, dynamic>>(
      '/logger/dashboards/$dashboardId/widgets',
      data: body,
    );
    return DashboardWidgetResponse.fromJson(response.data!);
  }

  /// Updates a widget on a dashboard.
  Future<DashboardWidgetResponse> updateDashboardWidget(
    String dashboardId,
    String widgetId, {
    String? title,
    WidgetType? widgetType,
    String? queryJson,
    String? configJson,
    int? gridX,
    int? gridY,
    int? gridWidth,
    int? gridHeight,
    int? sortOrder,
  }) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (widgetType != null) body['widgetType'] = widgetType.toJson();
    if (queryJson != null) body['queryJson'] = queryJson;
    if (configJson != null) body['configJson'] = configJson;
    if (gridX != null) body['gridX'] = gridX;
    if (gridY != null) body['gridY'] = gridY;
    if (gridWidth != null) body['gridWidth'] = gridWidth;
    if (gridHeight != null) body['gridHeight'] = gridHeight;
    if (sortOrder != null) body['sortOrder'] = sortOrder;

    final response = await _client.dio.put<Map<String, dynamic>>(
      '/logger/dashboards/$dashboardId/widgets/$widgetId',
      data: body,
    );
    return DashboardWidgetResponse.fromJson(response.data!);
  }

  /// Deletes a widget from a dashboard.
  Future<void> deleteDashboardWidget(
    String dashboardId,
    String widgetId,
  ) async {
    await _client.dio
        .delete('/logger/dashboards/$dashboardId/widgets/$widgetId');
  }

  /// Reorders widgets within a dashboard.
  Future<DashboardResponse> reorderDashboardWidgets(
    String dashboardId, {
    required List<String> widgetIds,
  }) async {
    final response = await _client.dio.put<Map<String, dynamic>>(
      '/logger/dashboards/$dashboardId/widgets/reorder',
      data: {'widgetIds': widgetIds},
    );
    return DashboardResponse.fromJson(response.data!);
  }

  /// Batch-updates widget positions in a dashboard.
  Future<DashboardResponse> updateDashboardLayout(
    String dashboardId, {
    required List<WidgetPositionUpdate> positions,
  }) async {
    final response = await _client.dio.put<Map<String, dynamic>>(
      '/logger/dashboards/$dashboardId/layout',
      data: {
        'positions': positions.map((e) => e.toJson()).toList(),
      },
    );
    return DashboardResponse.fromJson(response.data!);
  }

  /// Marks a dashboard as a template.
  Future<DashboardResponse> markDashboardAsTemplate(
    String dashboardId,
  ) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/logger/dashboards/$dashboardId/template',
    );
    return DashboardResponse.fromJson(response.data!);
  }

  /// Removes the template flag from a dashboard.
  Future<DashboardResponse> unmarkDashboardAsTemplate(
    String dashboardId,
  ) async {
    final response = await _client.dio.delete<Map<String, dynamic>>(
      '/logger/dashboards/$dashboardId/template',
    );
    return DashboardResponse.fromJson(response.data!);
  }

  /// Lists all dashboard templates for the team.
  Future<List<DashboardResponse>> listDashboardTemplates(
    String teamId,
  ) async {
    final response = await _client.dio.get<List<dynamic>>(
      '/logger/dashboards/templates',
      options: _teamOpts(teamId),
    );
    return response.data!
        .map((e) => DashboardResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Creates a new dashboard from a template.
  Future<DashboardResponse> createDashboardFromTemplate(
    String teamId, {
    required String name,
    required String templateId,
  }) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/logger/dashboards/from-template',
      data: {'name': name, 'templateId': templateId},
      options: _teamOpts(teamId),
    );
    return DashboardResponse.fromJson(response.data!);
  }

  /// Duplicates an existing dashboard with a new name.
  Future<DashboardResponse> duplicateDashboard(
    String teamId,
    String dashboardId, {
    required String name,
  }) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/logger/dashboards/$dashboardId/duplicate',
      data: {'name': name},
      options: _teamOpts(teamId),
    );
    return DashboardResponse.fromJson(response.data!);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Retention Policies (8 endpoints)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Creates a new retention policy.
  Future<RetentionPolicyResponse> createRetentionPolicy(
    String teamId, {
    required String name,
    required int retentionDays,
    required RetentionAction action,
    String? sourceName,
    LogLevel? logLevel,
    String? archiveDestination,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'retentionDays': retentionDays,
      'action': action.toJson(),
    };
    if (sourceName != null) body['sourceName'] = sourceName;
    if (logLevel != null) body['logLevel'] = logLevel.toJson();
    if (archiveDestination != null) {
      body['archiveDestination'] = archiveDestination;
    }

    final response = await _client.dio.post<Map<String, dynamic>>(
      '/logger/retention/policies',
      data: body,
      options: _teamOpts(teamId),
    );
    return RetentionPolicyResponse.fromJson(response.data!);
  }

  /// Lists all retention policies for the team.
  Future<List<RetentionPolicyResponse>> listRetentionPolicies(
    String teamId,
  ) async {
    final response = await _client.dio.get<List<dynamic>>(
      '/logger/retention/policies',
      options: _teamOpts(teamId),
    );
    return response.data!
        .map((e) =>
            RetentionPolicyResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Retrieves a retention policy by ID.
  Future<RetentionPolicyResponse> getRetentionPolicy(
    String teamId,
    String policyId,
  ) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/logger/retention/policies/$policyId',
      options: _teamOpts(teamId),
    );
    return RetentionPolicyResponse.fromJson(response.data!);
  }

  /// Updates an existing retention policy.
  Future<RetentionPolicyResponse> updateRetentionPolicy(
    String teamId,
    String policyId, {
    String? name,
    String? sourceName,
    LogLevel? logLevel,
    int? retentionDays,
    RetentionAction? action,
    String? archiveDestination,
    bool? isActive,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (sourceName != null) body['sourceName'] = sourceName;
    if (logLevel != null) body['logLevel'] = logLevel.toJson();
    if (retentionDays != null) body['retentionDays'] = retentionDays;
    if (action != null) body['action'] = action.toJson();
    if (archiveDestination != null) {
      body['archiveDestination'] = archiveDestination;
    }
    if (isActive != null) body['isActive'] = isActive;

    final response = await _client.dio.put<Map<String, dynamic>>(
      '/logger/retention/policies/$policyId',
      data: body,
      options: _teamOpts(teamId),
    );
    return RetentionPolicyResponse.fromJson(response.data!);
  }

  /// Deletes a retention policy.
  Future<void> deleteRetentionPolicy(
    String teamId,
    String policyId,
  ) async {
    await _client.dio.delete(
      '/logger/retention/policies/$policyId',
      options: _teamOpts(teamId),
    );
  }

  /// Toggles a retention policy active/inactive.
  Future<RetentionPolicyResponse> toggleRetentionPolicy(
    String teamId,
    String policyId, {
    required bool active,
  }) async {
    final response = await _client.dio.put<Map<String, dynamic>>(
      '/logger/retention/policies/$policyId/toggle',
      data: {'active': active},
      options: _teamOpts(teamId),
    );
    return RetentionPolicyResponse.fromJson(response.data!);
  }

  /// Manually executes a retention policy.
  ///
  /// Returns a map with `status` and `policyId` keys.
  Future<Map<String, dynamic>> executeRetentionPolicy(
    String teamId,
    String policyId,
  ) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/logger/retention/policies/$policyId/execute',
      options: _teamOpts(teamId),
    );
    return response.data!;
  }

  /// Gets storage usage statistics.
  Future<StorageUsageResponse> getStorageUsage() async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/logger/retention/storage',
    );
    return StorageUsageResponse.fromJson(response.data!);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Traces (11 endpoints)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Creates a single trace span.
  Future<TraceSpanResponse> createTraceSpan(
    String teamId, {
    required String correlationId,
    required String traceId,
    required String spanId,
    required String serviceName,
    required String operationName,
    required DateTime startTime,
    String? parentSpanId,
    DateTime? endTime,
    int? durationMs,
    SpanStatus? status,
    String? statusMessage,
    String? tags,
  }) async {
    final body = <String, dynamic>{
      'correlationId': correlationId,
      'traceId': traceId,
      'spanId': spanId,
      'serviceName': serviceName,
      'operationName': operationName,
      'startTime': startTime.toUtc().toIso8601String(),
    };
    if (parentSpanId != null) body['parentSpanId'] = parentSpanId;
    if (endTime != null) body['endTime'] = endTime.toUtc().toIso8601String();
    if (durationMs != null) body['durationMs'] = durationMs;
    if (status != null) body['status'] = status.toJson();
    if (statusMessage != null) body['statusMessage'] = statusMessage;
    if (tags != null) body['tags'] = tags;

    final response = await _client.dio.post<Map<String, dynamic>>(
      '/logger/traces/spans',
      data: body,
      options: _teamOpts(teamId),
    );
    return TraceSpanResponse.fromJson(response.data!);
  }

  /// Creates trace spans in batch.
  ///
  /// Returns a map with `created` and `total` keys.
  Future<Map<String, dynamic>> createTraceSpanBatch(
    String teamId, {
    required List<CreateTraceSpanRequest> spans,
  }) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/logger/traces/spans/batch',
      data: spans.map((e) => e.toJson()).toList(),
      options: _teamOpts(teamId),
    );
    return response.data!;
  }

  /// Retrieves a trace span by ID.
  Future<TraceSpanResponse> getTraceSpan(String spanId) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/logger/traces/spans/$spanId',
    );
    return TraceSpanResponse.fromJson(response.data!);
  }

  /// Gets the full trace flow for a correlation ID.
  Future<TraceFlowResponse> getTraceFlow(String correlationId) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/logger/traces/flow/$correlationId',
    );
    return TraceFlowResponse.fromJson(response.data!);
  }

  /// Gets the full trace flow by trace ID.
  Future<TraceFlowResponse> getTraceFlowByTraceId(String traceId) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/logger/traces/flow/by-trace-id/$traceId',
    );
    return TraceFlowResponse.fromJson(response.data!);
  }

  /// Gets the waterfall visualization for a trace.
  Future<TraceWaterfallResponse> getTraceWaterfall(
    String correlationId,
  ) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/logger/traces/waterfall/$correlationId',
    );
    return TraceWaterfallResponse.fromJson(response.data!);
  }

  /// Performs root cause analysis on a trace.
  ///
  /// Returns `null` if no root cause could be determined.
  Future<RootCauseAnalysisResponse?> getTraceRootCause(
    String correlationId,
  ) async {
    final response = await _client.dio.get<Map<String, dynamic>?>(
      '/logger/traces/rca/$correlationId',
    );
    if (response.statusCode == 204 || response.data == null) return null;
    return RootCauseAnalysisResponse.fromJson(response.data!);
  }

  /// Lists traces with pagination.
  Future<PageResponse<TraceListResponse>> listTraces(
    String teamId, {
    int page = 0,
    int size = 20,
  }) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/logger/traces',
      queryParameters: {'page': page, 'size': size},
      options: _teamOpts(teamId),
    );
    return PageResponse.fromJson(
      response.data!,
      (json) => TraceListResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Lists traces for a specific service.
  Future<PageResponse<TraceListResponse>> listTracesByService(
    String teamId,
    String serviceName, {
    int page = 0,
    int size = 20,
  }) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/logger/traces/service/$serviceName',
      queryParameters: {'page': page, 'size': size},
      options: _teamOpts(teamId),
    );
    return PageResponse.fromJson(
      response.data!,
      (json) => TraceListResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Lists traces that contain errors.
  Future<List<TraceListResponse>> listErrorTraces(
    String teamId, {
    int limit = 20,
  }) async {
    final response = await _client.dio.get<List<dynamic>>(
      '/logger/traces/errors',
      queryParameters: {'limit': limit},
      options: _teamOpts(teamId),
    );
    return response.data!
        .map((e) => TraceListResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Gets log entry IDs related to a trace.
  Future<List<String>> getTraceRelatedLogIds(
    String correlationId,
  ) async {
    final response = await _client.dio.get<List<dynamic>>(
      '/logger/traces/$correlationId/logs',
    );
    return response.data!.map((e) => e as String).toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Log Traps (9 endpoints)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Creates a new log trap.
  Future<LogTrapResponse> createLogTrap(
    String teamId, {
    required String name,
    required TrapType trapType,
    required List<CreateTrapConditionRequest> conditions,
    String? description,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'trapType': trapType.toJson(),
      'conditions': conditions.map((e) => e.toJson()).toList(),
    };
    if (description != null) body['description'] = description;

    final response = await _client.dio.post<Map<String, dynamic>>(
      '/logger/traps',
      data: body,
      options: _teamOpts(teamId),
    );
    return LogTrapResponse.fromJson(response.data!);
  }

  /// Lists all log traps for the team.
  Future<List<LogTrapResponse>> listLogTraps(String teamId) async {
    final response = await _client.dio.get<List<dynamic>>(
      '/logger/traps',
      options: _teamOpts(teamId),
    );
    return response.data!
        .map((e) => LogTrapResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Lists log traps with pagination.
  Future<PageResponse<LogTrapResponse>> listLogTrapsPaged(
    String teamId, {
    int page = 0,
    int size = 20,
  }) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/logger/traps/paged',
      queryParameters: {'page': page, 'size': size},
      options: _teamOpts(teamId),
    );
    return PageResponse.fromJson(
      response.data!,
      (json) => LogTrapResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Retrieves a log trap by ID.
  Future<LogTrapResponse> getLogTrap(String trapId) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/logger/traps/$trapId',
    );
    return LogTrapResponse.fromJson(response.data!);
  }

  /// Updates an existing log trap.
  Future<LogTrapResponse> updateLogTrap(
    String trapId, {
    String? name,
    String? description,
    TrapType? trapType,
    bool? isActive,
    List<CreateTrapConditionRequest>? conditions,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (description != null) body['description'] = description;
    if (trapType != null) body['trapType'] = trapType.toJson();
    if (isActive != null) body['isActive'] = isActive;
    if (conditions != null) {
      body['conditions'] = conditions.map((e) => e.toJson()).toList();
    }

    final response = await _client.dio.put<Map<String, dynamic>>(
      '/logger/traps/$trapId',
      data: body,
    );
    return LogTrapResponse.fromJson(response.data!);
  }

  /// Deletes a log trap.
  Future<void> deleteLogTrap(String trapId) async {
    await _client.dio.delete('/logger/traps/$trapId');
  }

  /// Toggles a log trap active/inactive.
  Future<LogTrapResponse> toggleLogTrap(String trapId) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/logger/traps/$trapId/toggle',
    );
    return LogTrapResponse.fromJson(response.data!);
  }

  /// Tests an existing trap against historical data.
  Future<TrapTestResult> testLogTrap(
    String trapId, {
    required int hoursBack,
  }) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/logger/traps/$trapId/test',
      data: {'hoursBack': hoursBack},
    );
    return TrapTestResult.fromJson(response.data!);
  }

  /// Tests a trap definition (not yet saved) against historical data.
  Future<TrapTestResult> testLogTrapDefinition(
    String teamId, {
    required String name,
    required TrapType trapType,
    required List<CreateTrapConditionRequest> conditions,
    String? description,
    int hoursBack = 24,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'trapType': trapType.toJson(),
      'conditions': conditions.map((e) => e.toJson()).toList(),
    };
    if (description != null) body['description'] = description;

    final response = await _client.dio.post<Map<String, dynamic>>(
      '/logger/traps/test',
      data: body,
      queryParameters: {'hoursBack': hoursBack},
      options: _teamOpts(teamId),
    );
    return TrapTestResult.fromJson(response.data!);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Anomaly Detection (8 endpoints)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Creates an anomaly detection baseline.
  Future<AnomalyBaselineResponse> createBaseline(
    String teamId, {
    required String serviceName,
    required String metricName,
    required int windowHours,
    required double deviationThreshold,
  }) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/logger/anomalies/baselines',
      data: {
        'serviceName': serviceName,
        'metricName': metricName,
        'windowHours': windowHours,
        'deviationThreshold': deviationThreshold,
      },
      options: _teamOpts(teamId),
    );
    return AnomalyBaselineResponse.fromJson(response.data!);
  }

  /// Lists all anomaly baselines for the team.
  Future<List<AnomalyBaselineResponse>> listBaselines(
    String teamId,
  ) async {
    final response = await _client.dio.get<List<dynamic>>(
      '/logger/anomalies/baselines',
      options: _teamOpts(teamId),
    );
    return response.data!
        .map((e) =>
            AnomalyBaselineResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Lists anomaly baselines for a specific service.
  Future<List<AnomalyBaselineResponse>> listBaselinesByService(
    String teamId,
    String serviceName,
  ) async {
    final response = await _client.dio.get<List<dynamic>>(
      '/logger/anomalies/baselines/service/$serviceName',
      options: _teamOpts(teamId),
    );
    return response.data!
        .map((e) =>
            AnomalyBaselineResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Retrieves an anomaly baseline by ID.
  Future<AnomalyBaselineResponse> getBaseline(String baselineId) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/logger/anomalies/baselines/$baselineId',
    );
    return AnomalyBaselineResponse.fromJson(response.data!);
  }

  /// Updates an existing anomaly baseline.
  Future<AnomalyBaselineResponse> updateBaseline(
    String baselineId, {
    int? windowHours,
    double? deviationThreshold,
    bool? isActive,
  }) async {
    final body = <String, dynamic>{};
    if (windowHours != null) body['windowHours'] = windowHours;
    if (deviationThreshold != null) {
      body['deviationThreshold'] = deviationThreshold;
    }
    if (isActive != null) body['isActive'] = isActive;

    final response = await _client.dio.put<Map<String, dynamic>>(
      '/logger/anomalies/baselines/$baselineId',
      data: body,
    );
    return AnomalyBaselineResponse.fromJson(response.data!);
  }

  /// Deletes an anomaly baseline.
  Future<void> deleteBaseline(String baselineId) async {
    await _client.dio.delete('/logger/anomalies/baselines/$baselineId');
  }

  /// Checks for an anomaly on a specific service/metric combination.
  Future<AnomalyCheckResponse> checkAnomaly(
    String teamId, {
    required String serviceName,
    required String metricName,
  }) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/logger/anomalies/check',
      queryParameters: {
        'serviceName': serviceName,
        'metricName': metricName,
      },
      options: _teamOpts(teamId),
    );
    return AnomalyCheckResponse.fromJson(response.data!);
  }

  /// Generates a full anomaly report for the team.
  Future<AnomalyReportResponse> getAnomalyReport(String teamId) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/logger/anomalies/report',
      options: _teamOpts(teamId),
    );
    return AnomalyReportResponse.fromJson(response.data!);
  }
}
