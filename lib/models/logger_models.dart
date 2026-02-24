/// Model classes for the CodeOps-Logger module.
///
/// Maps to response and request DTOs defined in the Logger controllers.
/// All 65 model classes use [JsonSerializable] with generated
/// `fromJson` / `toJson` methods via build_runner.
///
/// Organized by domain:
/// - Log Sources (3 classes)
/// - Log Entries & Search (5 classes)
/// - Log Traps & Conditions (7 classes)
/// - Saved Queries (4 classes)
/// - Alert Channels (3 classes)
/// - Alert Rules & History (5 classes)
/// - Metrics (11 classes)
/// - Dashboards & Widgets (10 classes)
/// - Traces & Spans (7 classes)
/// - Retention Policies & Storage (4 classes)
/// - Anomaly Detection (5 classes)
/// - Ingestion Stats (1 class)
library;

import 'package:json_annotation/json_annotation.dart';

import 'logger_enums.dart';

part 'logger_models.g.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Log Sources
// ─────────────────────────────────────────────────────────────────────────────

/// Metadata for a registered log source.
@JsonSerializable()
class LogSourceResponse {
  /// Unique identifier (UUID).
  final String id;

  /// Human-readable source name.
  final String name;

  /// UUID of the linked registry service (optional).
  final String? serviceId;

  /// Optional description.
  final String? description;

  /// Deployment environment (e.g., "production", "staging").
  final String? environment;

  /// Whether the source is actively ingesting logs.
  final bool isActive;

  /// UUID of the owning team.
  final String teamId;

  /// Timestamp of the most recent log received.
  final DateTime? lastLogReceivedAt;

  /// Total number of logs ingested from this source.
  final int logCount;

  /// Timestamp when the source was created.
  final DateTime? createdAt;

  /// Timestamp when the source was last updated.
  final DateTime? updatedAt;

  /// Creates a [LogSourceResponse] instance.
  const LogSourceResponse({
    required this.id,
    required this.name,
    this.serviceId,
    this.description,
    this.environment,
    required this.isActive,
    required this.teamId,
    this.lastLogReceivedAt,
    required this.logCount,
    this.createdAt,
    this.updatedAt,
  });

  /// Deserializes a [LogSourceResponse] from a JSON map.
  factory LogSourceResponse.fromJson(Map<String, dynamic> json) =>
      _$LogSourceResponseFromJson(json);

  /// Serializes this [LogSourceResponse] to a JSON map.
  Map<String, dynamic> toJson() => _$LogSourceResponseToJson(this);
}

/// Request body for creating a new log source.
@JsonSerializable()
class CreateLogSourceRequest {
  /// Human-readable source name (max 200 chars).
  final String name;

  /// UUID of the linked registry service.
  final String? serviceId;

  /// Optional description (max 5000 chars).
  final String? description;

  /// Deployment environment (max 50 chars).
  final String? environment;

  /// Creates a [CreateLogSourceRequest] instance.
  const CreateLogSourceRequest({
    required this.name,
    this.serviceId,
    this.description,
    this.environment,
  });

  /// Deserializes a [CreateLogSourceRequest] from a JSON map.
  factory CreateLogSourceRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateLogSourceRequestFromJson(json);

  /// Serializes this [CreateLogSourceRequest] to a JSON map.
  Map<String, dynamic> toJson() => _$CreateLogSourceRequestToJson(this);
}

/// Request body for updating an existing log source.
@JsonSerializable()
class UpdateLogSourceRequest {
  /// Updated source name (max 200 chars).
  final String? name;

  /// Updated description (max 5000 chars).
  final String? description;

  /// Updated environment (max 50 chars).
  final String? environment;

  /// Whether the source is active.
  final bool? isActive;

  /// Creates an [UpdateLogSourceRequest] instance.
  const UpdateLogSourceRequest({
    this.name,
    this.description,
    this.environment,
    this.isActive,
  });

  /// Deserializes an [UpdateLogSourceRequest] from a JSON map.
  factory UpdateLogSourceRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateLogSourceRequestFromJson(json);

  /// Serializes this [UpdateLogSourceRequest] to a JSON map.
  Map<String, dynamic> toJson() => _$UpdateLogSourceRequestToJson(this);
}

// ─────────────────────────────────────────────────────────────────────────────
// Log Entries & Search
// ─────────────────────────────────────────────────────────────────────────────

/// A single log entry returned by queries.
@JsonSerializable()
class LogEntryResponse {
  /// Unique identifier (UUID).
  final String id;

  /// UUID of the source that ingested this entry.
  final String sourceId;

  /// Name of the source.
  final String sourceName;

  /// Log severity level.
  @LogLevelConverter()
  final LogLevel level;

  /// Log message body.
  final String message;

  /// Timestamp when the log event occurred.
  final DateTime timestamp;

  /// Name of the originating service.
  final String serviceName;

  /// Correlation ID for request tracing.
  final String? correlationId;

  /// Distributed trace ID.
  final String? traceId;

  /// Distributed span ID.
  final String? spanId;

  /// Fully qualified logger name.
  final String? loggerName;

  /// Thread that produced the log.
  final String? threadName;

  /// Exception class name (if an error was logged).
  final String? exceptionClass;

  /// Exception message.
  final String? exceptionMessage;

  /// Full stack trace string.
  final String? stackTrace;

  /// JSON-encoded custom fields.
  final String? customFields;

  /// Host name of the originating machine.
  final String? hostName;

  /// IP address of the originating machine.
  final String? ipAddress;

  /// UUID of the owning team.
  final String teamId;

  /// Timestamp when the entry was persisted.
  final DateTime? createdAt;

  /// Creates a [LogEntryResponse] instance.
  const LogEntryResponse({
    required this.id,
    required this.sourceId,
    required this.sourceName,
    required this.level,
    required this.message,
    required this.timestamp,
    required this.serviceName,
    this.correlationId,
    this.traceId,
    this.spanId,
    this.loggerName,
    this.threadName,
    this.exceptionClass,
    this.exceptionMessage,
    this.stackTrace,
    this.customFields,
    this.hostName,
    this.ipAddress,
    required this.teamId,
    this.createdAt,
  });

  /// Deserializes a [LogEntryResponse] from a JSON map.
  factory LogEntryResponse.fromJson(Map<String, dynamic> json) =>
      _$LogEntryResponseFromJson(json);

  /// Serializes this [LogEntryResponse] to a JSON map.
  Map<String, dynamic> toJson() => _$LogEntryResponseToJson(this);
}

/// Request body for ingesting a single log entry.
@JsonSerializable()
class IngestLogEntryRequest {
  /// Log severity level.
  @LogLevelConverter()
  final LogLevel level;

  /// Log message body (max 65536 chars).
  final String message;

  /// Timestamp of the log event (defaults to server time if omitted).
  final DateTime? timestamp;

  /// Name of the originating service (max 200 chars).
  final String serviceName;

  /// Correlation ID for request tracing (max 100 chars).
  final String? correlationId;

  /// Distributed trace ID (max 100 chars).
  final String? traceId;

  /// Distributed span ID (max 100 chars).
  final String? spanId;

  /// Fully qualified logger name (max 500 chars).
  final String? loggerName;

  /// Thread name (max 200 chars).
  final String? threadName;

  /// Exception class name (max 500 chars).
  final String? exceptionClass;

  /// Exception message.
  final String? exceptionMessage;

  /// Full stack trace string.
  final String? stackTrace;

  /// JSON-encoded custom fields.
  final String? customFields;

  /// Host name (max 200 chars).
  final String? hostName;

  /// IP address (max 45 chars).
  final String? ipAddress;

  /// Creates an [IngestLogEntryRequest] instance.
  const IngestLogEntryRequest({
    required this.level,
    required this.message,
    this.timestamp,
    required this.serviceName,
    this.correlationId,
    this.traceId,
    this.spanId,
    this.loggerName,
    this.threadName,
    this.exceptionClass,
    this.exceptionMessage,
    this.stackTrace,
    this.customFields,
    this.hostName,
    this.ipAddress,
  });

  /// Deserializes an [IngestLogEntryRequest] from a JSON map.
  factory IngestLogEntryRequest.fromJson(Map<String, dynamic> json) =>
      _$IngestLogEntryRequestFromJson(json);

  /// Serializes this [IngestLogEntryRequest] to a JSON map.
  Map<String, dynamic> toJson() => _$IngestLogEntryRequestToJson(this);
}

/// Request body for batch log ingestion (1–1000 entries).
@JsonSerializable(explicitToJson: true)
class IngestLogBatchRequest {
  /// Log entries to ingest.
  final List<IngestLogEntryRequest> entries;

  /// Creates an [IngestLogBatchRequest] instance.
  const IngestLogBatchRequest({required this.entries});

  /// Deserializes an [IngestLogBatchRequest] from a JSON map.
  factory IngestLogBatchRequest.fromJson(Map<String, dynamic> json) =>
      _$IngestLogBatchRequestFromJson(json);

  /// Serializes this [IngestLogBatchRequest] to a JSON map.
  Map<String, dynamic> toJson() => _$IngestLogBatchRequestToJson(this);
}

/// Structured log query parameters.
@JsonSerializable()
class LogQueryRequest {
  /// Filter by service name.
  final String? serviceName;

  /// Filter by log level.
  @LogLevelConverter()
  final LogLevel? level;

  /// Start of the time range (inclusive).
  final DateTime? startTime;

  /// End of the time range (inclusive).
  final DateTime? endTime;

  /// Filter by correlation ID.
  final String? correlationId;

  /// Full-text search query.
  final String? query;

  /// Filter by logger name.
  final String? loggerName;

  /// Filter by exception class.
  final String? exceptionClass;

  /// Filter by host name.
  final String? hostName;

  /// Zero-based page index.
  final int? page;

  /// Page size (1–100, default 20).
  final int? size;

  /// Creates a [LogQueryRequest] instance.
  const LogQueryRequest({
    this.serviceName,
    this.level,
    this.startTime,
    this.endTime,
    this.correlationId,
    this.query,
    this.loggerName,
    this.exceptionClass,
    this.hostName,
    this.page,
    this.size,
  });

  /// Deserializes a [LogQueryRequest] from a JSON map.
  factory LogQueryRequest.fromJson(Map<String, dynamic> json) =>
      _$LogQueryRequestFromJson(json);

  /// Serializes this [LogQueryRequest] to a JSON map.
  Map<String, dynamic> toJson() => _$LogQueryRequestToJson(this);
}

/// DSL-based log query request.
@JsonSerializable()
class DslQueryRequest {
  /// DSL query string (max 2000 chars).
  final String query;

  /// Zero-based page index.
  final int? page;

  /// Page size (1–100).
  final int? size;

  /// Creates a [DslQueryRequest] instance.
  const DslQueryRequest({
    required this.query,
    this.page,
    this.size,
  });

  /// Deserializes a [DslQueryRequest] from a JSON map.
  factory DslQueryRequest.fromJson(Map<String, dynamic> json) =>
      _$DslQueryRequestFromJson(json);

  /// Serializes this [DslQueryRequest] to a JSON map.
  Map<String, dynamic> toJson() => _$DslQueryRequestToJson(this);
}

// ─────────────────────────────────────────────────────────────────────────────
// Log Traps & Conditions
// ─────────────────────────────────────────────────────────────────────────────

/// A single condition within a log trap.
@JsonSerializable()
class TrapConditionResponse {
  /// Unique identifier (UUID).
  final String id;

  /// Condition evaluation type.
  @ConditionTypeConverter()
  final ConditionType conditionType;

  /// Log field to evaluate.
  final String field;

  /// Regex or keyword pattern.
  final String? pattern;

  /// Frequency threshold count.
  final int? threshold;

  /// Time window in seconds for frequency/absence checks.
  final int? windowSeconds;

  /// Optional service name filter.
  final String? serviceName;

  /// Optional log level filter.
  @LogLevelConverter()
  final LogLevel? logLevel;

  /// Creates a [TrapConditionResponse] instance.
  const TrapConditionResponse({
    required this.id,
    required this.conditionType,
    required this.field,
    this.pattern,
    this.threshold,
    this.windowSeconds,
    this.serviceName,
    this.logLevel,
  });

  /// Deserializes a [TrapConditionResponse] from a JSON map.
  factory TrapConditionResponse.fromJson(Map<String, dynamic> json) =>
      _$TrapConditionResponseFromJson(json);

  /// Serializes this [TrapConditionResponse] to a JSON map.
  Map<String, dynamic> toJson() => _$TrapConditionResponseToJson(this);
}

/// A log trap with its conditions.
@JsonSerializable(explicitToJson: true)
class LogTrapResponse {
  /// Unique identifier (UUID).
  final String id;

  /// Trap name.
  final String name;

  /// Optional description.
  final String? description;

  /// Trap trigger type.
  @TrapTypeConverter()
  final TrapType trapType;

  /// Whether the trap is active.
  final bool isActive;

  /// UUID of the owning team.
  final String teamId;

  /// UUID of the user who created the trap.
  final String createdBy;

  /// Timestamp of the last trigger.
  final DateTime? lastTriggeredAt;

  /// Total number of times the trap has triggered.
  final int triggerCount;

  /// Conditions that must be met for the trap to fire.
  final List<TrapConditionResponse> conditions;

  /// Timestamp when the trap was created.
  final DateTime? createdAt;

  /// Timestamp when the trap was last updated.
  final DateTime? updatedAt;

  /// Creates a [LogTrapResponse] instance.
  const LogTrapResponse({
    required this.id,
    required this.name,
    this.description,
    required this.trapType,
    required this.isActive,
    required this.teamId,
    required this.createdBy,
    this.lastTriggeredAt,
    required this.triggerCount,
    required this.conditions,
    this.createdAt,
    this.updatedAt,
  });

  /// Deserializes a [LogTrapResponse] from a JSON map.
  factory LogTrapResponse.fromJson(Map<String, dynamic> json) =>
      _$LogTrapResponseFromJson(json);

  /// Serializes this [LogTrapResponse] to a JSON map.
  Map<String, dynamic> toJson() => _$LogTrapResponseToJson(this);
}

/// Result of testing a trap against historical log data.
@JsonSerializable()
class TrapTestResult {
  /// Number of log entries that matched.
  final int matchCount;

  /// Total number of log entries evaluated.
  final int totalEvaluated;

  /// Sample UUIDs of matching log entries.
  final List<String> sampleMatchIds;

  /// Start of the evaluation window.
  final DateTime evaluatedFrom;

  /// End of the evaluation window.
  final DateTime evaluatedTo;

  /// Percentage of evaluated entries that matched.
  final double matchPercentage;

  /// Creates a [TrapTestResult] instance.
  const TrapTestResult({
    required this.matchCount,
    required this.totalEvaluated,
    required this.sampleMatchIds,
    required this.evaluatedFrom,
    required this.evaluatedTo,
    required this.matchPercentage,
  });

  /// Deserializes a [TrapTestResult] from a JSON map.
  factory TrapTestResult.fromJson(Map<String, dynamic> json) =>
      _$TrapTestResultFromJson(json);

  /// Serializes this [TrapTestResult] to a JSON map.
  Map<String, dynamic> toJson() => _$TrapTestResultToJson(this);
}

/// Request body for creating a trap condition (nested in trap requests).
@JsonSerializable()
class CreateTrapConditionRequest {
  /// Condition evaluation type.
  @ConditionTypeConverter()
  final ConditionType conditionType;

  /// Log field to evaluate (max 100 chars).
  final String field;

  /// Regex or keyword pattern.
  final String? pattern;

  /// Frequency threshold count (min 1).
  final int? threshold;

  /// Time window in seconds (min 1).
  final int? windowSeconds;

  /// Optional service name filter (max 200 chars).
  final String? serviceName;

  /// Optional log level filter.
  @LogLevelConverter()
  final LogLevel? logLevel;

  /// Creates a [CreateTrapConditionRequest] instance.
  const CreateTrapConditionRequest({
    required this.conditionType,
    required this.field,
    this.pattern,
    this.threshold,
    this.windowSeconds,
    this.serviceName,
    this.logLevel,
  });

  /// Deserializes a [CreateTrapConditionRequest] from a JSON map.
  factory CreateTrapConditionRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateTrapConditionRequestFromJson(json);

  /// Serializes this [CreateTrapConditionRequest] to a JSON map.
  Map<String, dynamic> toJson() => _$CreateTrapConditionRequestToJson(this);
}

/// Request body for creating a new log trap.
@JsonSerializable(explicitToJson: true)
class CreateLogTrapRequest {
  /// Trap name (max 200 chars).
  final String name;

  /// Optional description.
  final String? description;

  /// Trap trigger type.
  @TrapTypeConverter()
  final TrapType trapType;

  /// Conditions (1–10) that must be met.
  final List<CreateTrapConditionRequest> conditions;

  /// Creates a [CreateLogTrapRequest] instance.
  const CreateLogTrapRequest({
    required this.name,
    this.description,
    required this.trapType,
    required this.conditions,
  });

  /// Deserializes a [CreateLogTrapRequest] from a JSON map.
  factory CreateLogTrapRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateLogTrapRequestFromJson(json);

  /// Serializes this [CreateLogTrapRequest] to a JSON map.
  Map<String, dynamic> toJson() => _$CreateLogTrapRequestToJson(this);
}

/// Request body for updating an existing log trap.
@JsonSerializable(explicitToJson: true)
class UpdateLogTrapRequest {
  /// Updated trap name (max 200 chars).
  final String? name;

  /// Updated description.
  final String? description;

  /// Updated trap type.
  @TrapTypeConverter()
  final TrapType? trapType;

  /// Whether the trap is active.
  final bool? isActive;

  /// Updated conditions (max 10).
  final List<CreateTrapConditionRequest>? conditions;

  /// Creates an [UpdateLogTrapRequest] instance.
  const UpdateLogTrapRequest({
    this.name,
    this.description,
    this.trapType,
    this.isActive,
    this.conditions,
  });

  /// Deserializes an [UpdateLogTrapRequest] from a JSON map.
  factory UpdateLogTrapRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateLogTrapRequestFromJson(json);

  /// Serializes this [UpdateLogTrapRequest] to a JSON map.
  Map<String, dynamic> toJson() => _$UpdateLogTrapRequestToJson(this);
}

/// Request body for testing a trap against historical data.
@JsonSerializable()
class TestTrapRequest {
  /// Number of hours of historical data to evaluate (1–168).
  final int hoursBack;

  /// Creates a [TestTrapRequest] instance.
  const TestTrapRequest({required this.hoursBack});

  /// Deserializes a [TestTrapRequest] from a JSON map.
  factory TestTrapRequest.fromJson(Map<String, dynamic> json) =>
      _$TestTrapRequestFromJson(json);

  /// Serializes this [TestTrapRequest] to a JSON map.
  Map<String, dynamic> toJson() => _$TestTrapRequestToJson(this);
}

// ─────────────────────────────────────────────────────────────────────────────
// Saved Queries
// ─────────────────────────────────────────────────────────────────────────────

/// A saved log query.
@JsonSerializable()
class SavedQueryResponse {
  /// Unique identifier (UUID).
  final String id;

  /// Query name.
  final String name;

  /// Optional description.
  final String? description;

  /// JSON-encoded structured query.
  final String queryJson;

  /// Optional DSL query string.
  final String? queryDsl;

  /// UUID of the owning team.
  final String teamId;

  /// UUID of the user who created the query.
  final String createdBy;

  /// Whether the query is shared with the team.
  final bool isShared;

  /// Timestamp of the last execution.
  final DateTime? lastExecutedAt;

  /// Total number of times the query has been executed.
  final int executionCount;

  /// Timestamp when the query was created.
  final DateTime? createdAt;

  /// Timestamp when the query was last updated.
  final DateTime? updatedAt;

  /// Creates a [SavedQueryResponse] instance.
  const SavedQueryResponse({
    required this.id,
    required this.name,
    this.description,
    required this.queryJson,
    this.queryDsl,
    required this.teamId,
    required this.createdBy,
    required this.isShared,
    this.lastExecutedAt,
    required this.executionCount,
    this.createdAt,
    this.updatedAt,
  });

  /// Deserializes a [SavedQueryResponse] from a JSON map.
  factory SavedQueryResponse.fromJson(Map<String, dynamic> json) =>
      _$SavedQueryResponseFromJson(json);

  /// Serializes this [SavedQueryResponse] to a JSON map.
  Map<String, dynamic> toJson() => _$SavedQueryResponseToJson(this);
}

/// A single entry in the query execution history.
@JsonSerializable()
class QueryHistoryResponse {
  /// Unique identifier (UUID).
  final String id;

  /// JSON-encoded structured query that was executed.
  final String queryJson;

  /// Optional DSL query string.
  final String? queryDsl;

  /// Number of results returned.
  final int resultCount;

  /// Execution time in milliseconds.
  final int executionTimeMs;

  /// UUID of the user who executed the query.
  final String createdBy;

  /// Timestamp when the query was executed.
  final DateTime? createdAt;

  /// Creates a [QueryHistoryResponse] instance.
  const QueryHistoryResponse({
    required this.id,
    required this.queryJson,
    this.queryDsl,
    required this.resultCount,
    required this.executionTimeMs,
    required this.createdBy,
    this.createdAt,
  });

  /// Deserializes a [QueryHistoryResponse] from a JSON map.
  factory QueryHistoryResponse.fromJson(Map<String, dynamic> json) =>
      _$QueryHistoryResponseFromJson(json);

  /// Serializes this [QueryHistoryResponse] to a JSON map.
  Map<String, dynamic> toJson() => _$QueryHistoryResponseToJson(this);
}

/// Request body for creating a saved query.
@JsonSerializable()
class CreateSavedQueryRequest {
  /// Query name (max 200 chars).
  final String name;

  /// Optional description (max 5000 chars).
  final String? description;

  /// JSON-encoded structured query.
  final String queryJson;

  /// Optional DSL query string.
  final String? queryDsl;

  /// Whether the query is shared with the team.
  final bool? isShared;

  /// Creates a [CreateSavedQueryRequest] instance.
  const CreateSavedQueryRequest({
    required this.name,
    this.description,
    required this.queryJson,
    this.queryDsl,
    this.isShared,
  });

  /// Deserializes a [CreateSavedQueryRequest] from a JSON map.
  factory CreateSavedQueryRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateSavedQueryRequestFromJson(json);

  /// Serializes this [CreateSavedQueryRequest] to a JSON map.
  Map<String, dynamic> toJson() => _$CreateSavedQueryRequestToJson(this);
}

/// Request body for updating an existing saved query.
@JsonSerializable()
class UpdateSavedQueryRequest {
  /// Updated query name (max 200 chars).
  final String? name;

  /// Updated description (max 5000 chars).
  final String? description;

  /// Updated JSON-encoded query.
  final String? queryJson;

  /// Updated DSL query string.
  final String? queryDsl;

  /// Whether the query is shared with the team.
  final bool? isShared;

  /// Creates an [UpdateSavedQueryRequest] instance.
  const UpdateSavedQueryRequest({
    this.name,
    this.description,
    this.queryJson,
    this.queryDsl,
    this.isShared,
  });

  /// Deserializes an [UpdateSavedQueryRequest] from a JSON map.
  factory UpdateSavedQueryRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateSavedQueryRequestFromJson(json);

  /// Serializes this [UpdateSavedQueryRequest] to a JSON map.
  Map<String, dynamic> toJson() => _$UpdateSavedQueryRequestToJson(this);
}

// ─────────────────────────────────────────────────────────────────────────────
// Alert Channels
// ─────────────────────────────────────────────────────────────────────────────

/// An alert notification channel configuration.
@JsonSerializable()
class AlertChannelResponse {
  /// Unique identifier (UUID).
  final String id;

  /// Channel name.
  final String name;

  /// Notification channel type.
  @AlertChannelTypeConverter()
  final AlertChannelType channelType;

  /// JSON-encoded channel configuration.
  final String configuration;

  /// Whether the channel is active.
  final bool isActive;

  /// UUID of the owning team.
  final String teamId;

  /// UUID of the user who created the channel.
  final String createdBy;

  /// Timestamp when the channel was created.
  final DateTime? createdAt;

  /// Timestamp when the channel was last updated.
  final DateTime? updatedAt;

  /// Creates an [AlertChannelResponse] instance.
  const AlertChannelResponse({
    required this.id,
    required this.name,
    required this.channelType,
    required this.configuration,
    required this.isActive,
    required this.teamId,
    required this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  /// Deserializes an [AlertChannelResponse] from a JSON map.
  factory AlertChannelResponse.fromJson(Map<String, dynamic> json) =>
      _$AlertChannelResponseFromJson(json);

  /// Serializes this [AlertChannelResponse] to a JSON map.
  Map<String, dynamic> toJson() => _$AlertChannelResponseToJson(this);
}

/// Request body for creating an alert channel.
@JsonSerializable()
class CreateAlertChannelRequest {
  /// Channel name (max 200 chars).
  final String name;

  /// Notification channel type.
  @AlertChannelTypeConverter()
  final AlertChannelType channelType;

  /// JSON-encoded channel configuration.
  final String configuration;

  /// Creates a [CreateAlertChannelRequest] instance.
  const CreateAlertChannelRequest({
    required this.name,
    required this.channelType,
    required this.configuration,
  });

  /// Deserializes a [CreateAlertChannelRequest] from a JSON map.
  factory CreateAlertChannelRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateAlertChannelRequestFromJson(json);

  /// Serializes this [CreateAlertChannelRequest] to a JSON map.
  Map<String, dynamic> toJson() => _$CreateAlertChannelRequestToJson(this);
}

/// Request body for updating an existing alert channel.
@JsonSerializable()
class UpdateAlertChannelRequest {
  /// Updated channel name (max 200 chars).
  final String? name;

  /// Updated JSON-encoded configuration.
  final String? configuration;

  /// Whether the channel is active.
  final bool? isActive;

  /// Creates an [UpdateAlertChannelRequest] instance.
  const UpdateAlertChannelRequest({
    this.name,
    this.configuration,
    this.isActive,
  });

  /// Deserializes an [UpdateAlertChannelRequest] from a JSON map.
  factory UpdateAlertChannelRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateAlertChannelRequestFromJson(json);

  /// Serializes this [UpdateAlertChannelRequest] to a JSON map.
  Map<String, dynamic> toJson() => _$UpdateAlertChannelRequestToJson(this);
}

// ─────────────────────────────────────────────────────────────────────────────
// Alert Rules & History
// ─────────────────────────────────────────────────────────────────────────────

/// An alert rule linking a trap to a notification channel.
@JsonSerializable()
class AlertRuleResponse {
  /// Unique identifier (UUID).
  final String id;

  /// Rule name.
  final String name;

  /// UUID of the linked trap.
  final String trapId;

  /// Denormalized name of the linked trap.
  final String trapName;

  /// UUID of the linked notification channel.
  final String channelId;

  /// Denormalized name of the linked channel.
  final String channelName;

  /// Alert severity.
  @AlertSeverityConverter()
  final AlertSeverity severity;

  /// Whether the rule is active.
  final bool isActive;

  /// Minimum minutes between repeated alerts.
  final int throttleMinutes;

  /// UUID of the owning team.
  final String teamId;

  /// Timestamp when the rule was created.
  final DateTime? createdAt;

  /// Timestamp when the rule was last updated.
  final DateTime? updatedAt;

  /// Creates an [AlertRuleResponse] instance.
  const AlertRuleResponse({
    required this.id,
    required this.name,
    required this.trapId,
    required this.trapName,
    required this.channelId,
    required this.channelName,
    required this.severity,
    required this.isActive,
    required this.throttleMinutes,
    required this.teamId,
    this.createdAt,
    this.updatedAt,
  });

  /// Deserializes an [AlertRuleResponse] from a JSON map.
  factory AlertRuleResponse.fromJson(Map<String, dynamic> json) =>
      _$AlertRuleResponseFromJson(json);

  /// Serializes this [AlertRuleResponse] to a JSON map.
  Map<String, dynamic> toJson() => _$AlertRuleResponseToJson(this);
}

/// A single alert history entry.
@JsonSerializable()
class AlertHistoryResponse {
  /// Unique identifier (UUID).
  final String id;

  /// UUID of the rule that fired.
  final String ruleId;

  /// Denormalized rule name.
  final String ruleName;

  /// UUID of the trap that triggered.
  final String trapId;

  /// Denormalized trap name.
  final String trapName;

  /// UUID of the notification channel used.
  final String channelId;

  /// Denormalized channel name.
  final String channelName;

  /// Alert severity at time of firing.
  @AlertSeverityConverter()
  final AlertSeverity severity;

  /// Current alert lifecycle status.
  @AlertStatusConverter()
  final AlertStatus status;

  /// Optional message or context for the alert.
  final String? message;

  /// UUID of the user who acknowledged the alert.
  final String? acknowledgedBy;

  /// Timestamp when the alert was acknowledged.
  final DateTime? acknowledgedAt;

  /// UUID of the user who resolved the alert.
  final String? resolvedBy;

  /// Timestamp when the alert was resolved.
  final DateTime? resolvedAt;

  /// UUID of the owning team.
  final String teamId;

  /// Timestamp when the alert was fired.
  final DateTime? createdAt;

  /// Creates an [AlertHistoryResponse] instance.
  const AlertHistoryResponse({
    required this.id,
    required this.ruleId,
    required this.ruleName,
    required this.trapId,
    required this.trapName,
    required this.channelId,
    required this.channelName,
    required this.severity,
    required this.status,
    this.message,
    this.acknowledgedBy,
    this.acknowledgedAt,
    this.resolvedBy,
    this.resolvedAt,
    required this.teamId,
    this.createdAt,
  });

  /// Deserializes an [AlertHistoryResponse] from a JSON map.
  factory AlertHistoryResponse.fromJson(Map<String, dynamic> json) =>
      _$AlertHistoryResponseFromJson(json);

  /// Serializes this [AlertHistoryResponse] to a JSON map.
  Map<String, dynamic> toJson() => _$AlertHistoryResponseToJson(this);
}

/// Request body for creating an alert rule.
@JsonSerializable()
class CreateAlertRuleRequest {
  /// Rule name (max 200 chars).
  final String name;

  /// UUID of the trap to link.
  final String trapId;

  /// UUID of the notification channel.
  final String channelId;

  /// Alert severity.
  @AlertSeverityConverter()
  final AlertSeverity severity;

  /// Minimum minutes between repeated alerts (1–1440).
  final int? throttleMinutes;

  /// Creates a [CreateAlertRuleRequest] instance.
  const CreateAlertRuleRequest({
    required this.name,
    required this.trapId,
    required this.channelId,
    required this.severity,
    this.throttleMinutes,
  });

  /// Deserializes a [CreateAlertRuleRequest] from a JSON map.
  factory CreateAlertRuleRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateAlertRuleRequestFromJson(json);

  /// Serializes this [CreateAlertRuleRequest] to a JSON map.
  Map<String, dynamic> toJson() => _$CreateAlertRuleRequestToJson(this);
}

/// Request body for updating an existing alert rule.
@JsonSerializable()
class UpdateAlertRuleRequest {
  /// Updated rule name (max 200 chars).
  final String? name;

  /// Updated trap UUID.
  final String? trapId;

  /// Updated channel UUID.
  final String? channelId;

  /// Updated severity.
  @AlertSeverityConverter()
  final AlertSeverity? severity;

  /// Whether the rule is active.
  final bool? isActive;

  /// Updated throttle minutes (1–1440).
  final int? throttleMinutes;

  /// Creates an [UpdateAlertRuleRequest] instance.
  const UpdateAlertRuleRequest({
    this.name,
    this.trapId,
    this.channelId,
    this.severity,
    this.isActive,
    this.throttleMinutes,
  });

  /// Deserializes an [UpdateAlertRuleRequest] from a JSON map.
  factory UpdateAlertRuleRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateAlertRuleRequestFromJson(json);

  /// Serializes this [UpdateAlertRuleRequest] to a JSON map.
  Map<String, dynamic> toJson() => _$UpdateAlertRuleRequestToJson(this);
}

/// Request body for updating an alert's lifecycle status.
@JsonSerializable()
class UpdateAlertStatusRequest {
  /// New alert status.
  @AlertStatusConverter()
  final AlertStatus status;

  /// Creates an [UpdateAlertStatusRequest] instance.
  const UpdateAlertStatusRequest({required this.status});

  /// Deserializes an [UpdateAlertStatusRequest] from a JSON map.
  factory UpdateAlertStatusRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateAlertStatusRequestFromJson(json);

  /// Serializes this [UpdateAlertStatusRequest] to a JSON map.
  Map<String, dynamic> toJson() => _$UpdateAlertStatusRequestToJson(this);
}

// ─────────────────────────────────────────────────────────────────────────────
// Metrics
// ─────────────────────────────────────────────────────────────────────────────

/// A registered metric definition.
@JsonSerializable()
class MetricResponse {
  /// Unique identifier (UUID).
  final String id;

  /// Metric name.
  final String name;

  /// Metric data type.
  @MetricTypeConverter()
  final MetricType metricType;

  /// Optional description.
  final String? description;

  /// Measurement unit (e.g., "ms", "bytes").
  final String? unit;

  /// Name of the service that owns this metric.
  final String serviceName;

  /// JSON-encoded metric tags.
  final String? tags;

  /// UUID of the owning team.
  final String teamId;

  /// Timestamp when the metric was registered.
  final DateTime? createdAt;

  /// Timestamp when the metric was last updated.
  final DateTime? updatedAt;

  /// Creates a [MetricResponse] instance.
  const MetricResponse({
    required this.id,
    required this.name,
    required this.metricType,
    this.description,
    this.unit,
    required this.serviceName,
    this.tags,
    required this.teamId,
    this.createdAt,
    this.updatedAt,
  });

  /// Deserializes a [MetricResponse] from a JSON map.
  factory MetricResponse.fromJson(Map<String, dynamic> json) =>
      _$MetricResponseFromJson(json);

  /// Serializes this [MetricResponse] to a JSON map.
  Map<String, dynamic> toJson() => _$MetricResponseToJson(this);
}

/// A persisted metric data point with resolution metadata.
@JsonSerializable()
class MetricDataPointResponse {
  /// Unique identifier (UUID).
  final String id;

  /// UUID of the parent metric.
  final String metricId;

  /// Timestamp of the data point.
  final DateTime timestamp;

  /// Numeric value.
  final double value;

  /// JSON-encoded tags.
  final String? tags;

  /// Resolution bucket in seconds.
  final int resolution;

  /// Creates a [MetricDataPointResponse] instance.
  const MetricDataPointResponse({
    required this.id,
    required this.metricId,
    required this.timestamp,
    required this.value,
    this.tags,
    required this.resolution,
  });

  /// Deserializes a [MetricDataPointResponse] from a JSON map.
  factory MetricDataPointResponse.fromJson(Map<String, dynamic> json) =>
      _$MetricDataPointResponseFromJson(json);

  /// Serializes this [MetricDataPointResponse] to a JSON map.
  Map<String, dynamic> toJson() => _$MetricDataPointResponseToJson(this);
}

/// A single data point in a time-series response.
@JsonSerializable()
class TimeSeriesDataPoint {
  /// Timestamp of the data point.
  final DateTime timestamp;

  /// Numeric value.
  final double value;

  /// JSON-encoded tags.
  final String? tags;

  /// Creates a [TimeSeriesDataPoint] instance.
  const TimeSeriesDataPoint({
    required this.timestamp,
    required this.value,
    this.tags,
  });

  /// Deserializes a [TimeSeriesDataPoint] from a JSON map.
  factory TimeSeriesDataPoint.fromJson(Map<String, dynamic> json) =>
      _$TimeSeriesDataPointFromJson(json);

  /// Serializes this [TimeSeriesDataPoint] to a JSON map.
  Map<String, dynamic> toJson() => _$TimeSeriesDataPointToJson(this);
}

/// Time-series data for a metric over a requested range.
@JsonSerializable(explicitToJson: true)
class MetricTimeSeriesResponse {
  /// UUID of the metric.
  final String metricId;

  /// Name of the metric.
  final String metricName;

  /// Name of the owning service.
  final String serviceName;

  /// Metric data type.
  final String metricType;

  /// Measurement unit.
  final String? unit;

  /// Start of the queried range.
  final DateTime startTime;

  /// End of the queried range.
  final DateTime endTime;

  /// Resolution bucket in seconds.
  final int resolution;

  /// Ordered data points.
  final List<TimeSeriesDataPoint> dataPoints;

  /// Creates a [MetricTimeSeriesResponse] instance.
  const MetricTimeSeriesResponse({
    required this.metricId,
    required this.metricName,
    required this.serviceName,
    required this.metricType,
    this.unit,
    required this.startTime,
    required this.endTime,
    required this.resolution,
    required this.dataPoints,
  });

  /// Deserializes a [MetricTimeSeriesResponse] from a JSON map.
  factory MetricTimeSeriesResponse.fromJson(Map<String, dynamic> json) =>
      _$MetricTimeSeriesResponseFromJson(json);

  /// Serializes this [MetricTimeSeriesResponse] to a JSON map.
  Map<String, dynamic> toJson() => _$MetricTimeSeriesResponseToJson(this);
}

/// Statistical aggregation of metric data over a range.
@JsonSerializable()
class MetricAggregationResponse {
  /// UUID of the metric.
  final String metricId;

  /// Name of the metric.
  final String metricName;

  /// Name of the owning service.
  final String serviceName;

  /// Start of the aggregation range.
  final DateTime startTime;

  /// End of the aggregation range.
  final DateTime endTime;

  /// Total number of data points aggregated.
  final int dataPointCount;

  /// Sum of all values.
  final double sum;

  /// Arithmetic mean.
  final double avg;

  /// Minimum value.
  final double min;

  /// Maximum value.
  final double max;

  /// 50th percentile (median).
  final double p50;

  /// 95th percentile.
  final double p95;

  /// 99th percentile.
  final double p99;

  /// Standard deviation.
  final double stddev;

  /// Creates a [MetricAggregationResponse] instance.
  const MetricAggregationResponse({
    required this.metricId,
    required this.metricName,
    required this.serviceName,
    required this.startTime,
    required this.endTime,
    required this.dataPointCount,
    required this.sum,
    required this.avg,
    required this.min,
    required this.max,
    required this.p50,
    required this.p95,
    required this.p99,
    required this.stddev,
  });

  /// Deserializes a [MetricAggregationResponse] from a JSON map.
  factory MetricAggregationResponse.fromJson(Map<String, dynamic> json) =>
      _$MetricAggregationResponseFromJson(json);

  /// Serializes this [MetricAggregationResponse] to a JSON map.
  Map<String, dynamic> toJson() => _$MetricAggregationResponseToJson(this);
}

/// Summary of all metrics for a given service.
@JsonSerializable(explicitToJson: true)
class ServiceMetricsSummaryResponse {
  /// Name of the service.
  final String serviceName;

  /// Total number of registered metrics.
  final int metricCount;

  /// Count of metrics by type.
  final Map<String, int> metricsByType;

  /// Full list of metric definitions.
  final List<MetricResponse> metrics;

  /// Creates a [ServiceMetricsSummaryResponse] instance.
  const ServiceMetricsSummaryResponse({
    required this.serviceName,
    required this.metricCount,
    required this.metricsByType,
    required this.metrics,
  });

  /// Deserializes a [ServiceMetricsSummaryResponse] from a JSON map.
  factory ServiceMetricsSummaryResponse.fromJson(Map<String, dynamic> json) =>
      _$ServiceMetricsSummaryResponseFromJson(json);

  /// Serializes this [ServiceMetricsSummaryResponse] to a JSON map.
  Map<String, dynamic> toJson() =>
      _$ServiceMetricsSummaryResponseToJson(this);
}

/// Request body for registering a new metric.
@JsonSerializable()
class RegisterMetricRequest {
  /// Metric name (max 200 chars).
  final String name;

  /// Metric data type.
  @MetricTypeConverter()
  final MetricType metricType;

  /// Optional description (max 5000 chars).
  final String? description;

  /// Measurement unit (max 50 chars).
  final String? unit;

  /// Name of the owning service (max 200 chars).
  final String serviceName;

  /// JSON-encoded metric tags.
  final String? tags;

  /// Creates a [RegisterMetricRequest] instance.
  const RegisterMetricRequest({
    required this.name,
    required this.metricType,
    this.description,
    this.unit,
    required this.serviceName,
    this.tags,
  });

  /// Deserializes a [RegisterMetricRequest] from a JSON map.
  factory RegisterMetricRequest.fromJson(Map<String, dynamic> json) =>
      _$RegisterMetricRequestFromJson(json);

  /// Serializes this [RegisterMetricRequest] to a JSON map.
  Map<String, dynamic> toJson() => _$RegisterMetricRequestToJson(this);
}

/// Request body for updating an existing metric.
@JsonSerializable()
class UpdateMetricRequest {
  /// Updated description (max 5000 chars).
  final String? description;

  /// Updated measurement unit (max 50 chars).
  final String? unit;

  /// Updated JSON-encoded tags.
  final String? tags;

  /// Creates an [UpdateMetricRequest] instance.
  const UpdateMetricRequest({
    this.description,
    this.unit,
    this.tags,
  });

  /// Deserializes an [UpdateMetricRequest] from a JSON map.
  factory UpdateMetricRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateMetricRequestFromJson(json);

  /// Serializes this [UpdateMetricRequest] to a JSON map.
  Map<String, dynamic> toJson() => _$UpdateMetricRequestToJson(this);
}

/// A single data point for metric ingestion.
@JsonSerializable()
class MetricDataPoint {
  /// Timestamp of the data point.
  final DateTime timestamp;

  /// Numeric value.
  final double value;

  /// JSON-encoded tags.
  final String? tags;

  /// Creates a [MetricDataPoint] instance.
  const MetricDataPoint({
    required this.timestamp,
    required this.value,
    this.tags,
  });

  /// Deserializes a [MetricDataPoint] from a JSON map.
  factory MetricDataPoint.fromJson(Map<String, dynamic> json) =>
      _$MetricDataPointFromJson(json);

  /// Serializes this [MetricDataPoint] to a JSON map.
  Map<String, dynamic> toJson() => _$MetricDataPointToJson(this);
}

/// Request body for pushing metric data points.
@JsonSerializable(explicitToJson: true)
class PushMetricDataRequest {
  /// UUID of the target metric.
  final String metricId;

  /// Data points to push (1–1000).
  final List<MetricDataPoint> dataPoints;

  /// Creates a [PushMetricDataRequest] instance.
  const PushMetricDataRequest({
    required this.metricId,
    required this.dataPoints,
  });

  /// Deserializes a [PushMetricDataRequest] from a JSON map.
  factory PushMetricDataRequest.fromJson(Map<String, dynamic> json) =>
      _$PushMetricDataRequestFromJson(json);

  /// Serializes this [PushMetricDataRequest] to a JSON map.
  Map<String, dynamic> toJson() => _$PushMetricDataRequestToJson(this);
}

/// Request body for querying metric time-series data.
@JsonSerializable()
class MetricQueryRequest {
  /// UUID of the metric to query.
  final String metricId;

  /// Start of the time range.
  final DateTime startTime;

  /// End of the time range.
  final DateTime endTime;

  /// Resolution bucket in seconds (10–3600).
  final int? resolution;

  /// Creates a [MetricQueryRequest] instance.
  const MetricQueryRequest({
    required this.metricId,
    required this.startTime,
    required this.endTime,
    this.resolution,
  });

  /// Deserializes a [MetricQueryRequest] from a JSON map.
  factory MetricQueryRequest.fromJson(Map<String, dynamic> json) =>
      _$MetricQueryRequestFromJson(json);

  /// Serializes this [MetricQueryRequest] to a JSON map.
  Map<String, dynamic> toJson() => _$MetricQueryRequestToJson(this);
}

// ─────────────────────────────────────────────────────────────────────────────
// Dashboards & Widgets
// ─────────────────────────────────────────────────────────────────────────────

/// A single widget within a dashboard.
@JsonSerializable()
class DashboardWidgetResponse {
  /// Unique identifier (UUID).
  final String id;

  /// UUID of the parent dashboard.
  final String dashboardId;

  /// Widget title.
  final String title;

  /// Widget visualization type.
  @WidgetTypeConverter()
  final WidgetType widgetType;

  /// JSON-encoded query configuration.
  final String? queryJson;

  /// JSON-encoded display configuration.
  final String? configJson;

  /// Grid X position.
  final int gridX;

  /// Grid Y position.
  final int gridY;

  /// Grid width (1–12).
  final int gridWidth;

  /// Grid height (1–12).
  final int gridHeight;

  /// Display sort order.
  final int sortOrder;

  /// Timestamp when the widget was created.
  final DateTime? createdAt;

  /// Timestamp when the widget was last updated.
  final DateTime? updatedAt;

  /// Creates a [DashboardWidgetResponse] instance.
  const DashboardWidgetResponse({
    required this.id,
    required this.dashboardId,
    required this.title,
    required this.widgetType,
    this.queryJson,
    this.configJson,
    required this.gridX,
    required this.gridY,
    required this.gridWidth,
    required this.gridHeight,
    required this.sortOrder,
    this.createdAt,
    this.updatedAt,
  });

  /// Deserializes a [DashboardWidgetResponse] from a JSON map.
  factory DashboardWidgetResponse.fromJson(Map<String, dynamic> json) =>
      _$DashboardWidgetResponseFromJson(json);

  /// Serializes this [DashboardWidgetResponse] to a JSON map.
  Map<String, dynamic> toJson() => _$DashboardWidgetResponseToJson(this);
}

/// A dashboard with its widgets.
@JsonSerializable(explicitToJson: true)
class DashboardResponse {
  /// Unique identifier (UUID).
  final String id;

  /// Dashboard name.
  final String name;

  /// Optional description.
  final String? description;

  /// UUID of the owning team.
  final String teamId;

  /// UUID of the user who created the dashboard.
  final String createdBy;

  /// Whether the dashboard is shared with the team.
  final bool isShared;

  /// Whether this dashboard is a reusable template.
  final bool isTemplate;

  /// Auto-refresh interval in seconds.
  final int refreshIntervalSeconds;

  /// JSON-encoded grid layout configuration.
  final String? layoutJson;

  /// Widgets contained in this dashboard.
  final List<DashboardWidgetResponse> widgets;

  /// Timestamp when the dashboard was created.
  final DateTime? createdAt;

  /// Timestamp when the dashboard was last updated.
  final DateTime? updatedAt;

  /// Creates a [DashboardResponse] instance.
  const DashboardResponse({
    required this.id,
    required this.name,
    this.description,
    required this.teamId,
    required this.createdBy,
    required this.isShared,
    required this.isTemplate,
    required this.refreshIntervalSeconds,
    this.layoutJson,
    required this.widgets,
    this.createdAt,
    this.updatedAt,
  });

  /// Deserializes a [DashboardResponse] from a JSON map.
  factory DashboardResponse.fromJson(Map<String, dynamic> json) =>
      _$DashboardResponseFromJson(json);

  /// Serializes this [DashboardResponse] to a JSON map.
  Map<String, dynamic> toJson() => _$DashboardResponseToJson(this);
}

/// Request body for creating a new dashboard.
@JsonSerializable()
class CreateDashboardRequest {
  /// Dashboard name (max 200 chars).
  final String name;

  /// Optional description (max 5000 chars).
  final String? description;

  /// Whether the dashboard is shared with the team.
  final bool? isShared;

  /// Auto-refresh interval in seconds (5–3600).
  final int? refreshIntervalSeconds;

  /// JSON-encoded grid layout configuration.
  final String? layoutJson;

  /// Creates a [CreateDashboardRequest] instance.
  const CreateDashboardRequest({
    required this.name,
    this.description,
    this.isShared,
    this.refreshIntervalSeconds,
    this.layoutJson,
  });

  /// Deserializes a [CreateDashboardRequest] from a JSON map.
  factory CreateDashboardRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateDashboardRequestFromJson(json);

  /// Serializes this [CreateDashboardRequest] to a JSON map.
  Map<String, dynamic> toJson() => _$CreateDashboardRequestToJson(this);
}

/// Request body for updating an existing dashboard.
@JsonSerializable()
class UpdateDashboardRequest {
  /// Updated dashboard name (max 200 chars).
  final String? name;

  /// Updated description (max 5000 chars).
  final String? description;

  /// Whether the dashboard is shared with the team.
  final bool? isShared;

  /// Whether the dashboard is a reusable template.
  final bool? isTemplate;

  /// Updated auto-refresh interval (5–3600).
  final int? refreshIntervalSeconds;

  /// Updated JSON-encoded layout.
  final String? layoutJson;

  /// Creates an [UpdateDashboardRequest] instance.
  const UpdateDashboardRequest({
    this.name,
    this.description,
    this.isShared,
    this.isTemplate,
    this.refreshIntervalSeconds,
    this.layoutJson,
  });

  /// Deserializes an [UpdateDashboardRequest] from a JSON map.
  factory UpdateDashboardRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateDashboardRequestFromJson(json);

  /// Serializes this [UpdateDashboardRequest] to a JSON map.
  Map<String, dynamic> toJson() => _$UpdateDashboardRequestToJson(this);
}

/// Request body for creating a widget on a dashboard.
@JsonSerializable()
class CreateDashboardWidgetRequest {
  /// Widget title (max 200 chars).
  final String title;

  /// Widget visualization type.
  @WidgetTypeConverter()
  final WidgetType widgetType;

  /// JSON-encoded query configuration.
  final String? queryJson;

  /// JSON-encoded display configuration.
  final String? configJson;

  /// Grid X position.
  final int? gridX;

  /// Grid Y position.
  final int? gridY;

  /// Grid width (1–12).
  final int? gridWidth;

  /// Grid height (1–12).
  final int? gridHeight;

  /// Display sort order.
  final int? sortOrder;

  /// Creates a [CreateDashboardWidgetRequest] instance.
  const CreateDashboardWidgetRequest({
    required this.title,
    required this.widgetType,
    this.queryJson,
    this.configJson,
    this.gridX,
    this.gridY,
    this.gridWidth,
    this.gridHeight,
    this.sortOrder,
  });

  /// Deserializes a [CreateDashboardWidgetRequest] from a JSON map.
  factory CreateDashboardWidgetRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateDashboardWidgetRequestFromJson(json);

  /// Serializes this [CreateDashboardWidgetRequest] to a JSON map.
  Map<String, dynamic> toJson() =>
      _$CreateDashboardWidgetRequestToJson(this);
}

/// Request body for updating an existing widget.
@JsonSerializable()
class UpdateDashboardWidgetRequest {
  /// Updated widget title (max 200 chars).
  final String? title;

  /// Updated widget type.
  @WidgetTypeConverter()
  final WidgetType? widgetType;

  /// Updated JSON-encoded query configuration.
  final String? queryJson;

  /// Updated JSON-encoded display configuration.
  final String? configJson;

  /// Updated grid X position.
  final int? gridX;

  /// Updated grid Y position.
  final int? gridY;

  /// Updated grid width (1–12).
  final int? gridWidth;

  /// Updated grid height (1–12).
  final int? gridHeight;

  /// Updated display sort order.
  final int? sortOrder;

  /// Creates an [UpdateDashboardWidgetRequest] instance.
  const UpdateDashboardWidgetRequest({
    this.title,
    this.widgetType,
    this.queryJson,
    this.configJson,
    this.gridX,
    this.gridY,
    this.gridWidth,
    this.gridHeight,
    this.sortOrder,
  });

  /// Deserializes an [UpdateDashboardWidgetRequest] from a JSON map.
  factory UpdateDashboardWidgetRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateDashboardWidgetRequestFromJson(json);

  /// Serializes this [UpdateDashboardWidgetRequest] to a JSON map.
  Map<String, dynamic> toJson() =>
      _$UpdateDashboardWidgetRequestToJson(this);
}

/// Request body for reordering widgets within a dashboard.
@JsonSerializable()
class ReorderWidgetsRequest {
  /// Ordered list of widget UUIDs.
  final List<String> widgetIds;

  /// Creates a [ReorderWidgetsRequest] instance.
  const ReorderWidgetsRequest({required this.widgetIds});

  /// Deserializes a [ReorderWidgetsRequest] from a JSON map.
  factory ReorderWidgetsRequest.fromJson(Map<String, dynamic> json) =>
      _$ReorderWidgetsRequestFromJson(json);

  /// Serializes this [ReorderWidgetsRequest] to a JSON map.
  Map<String, dynamic> toJson() => _$ReorderWidgetsRequestToJson(this);
}

/// Position update for a single widget in a layout change.
@JsonSerializable()
class WidgetPositionUpdate {
  /// UUID of the widget to reposition.
  final String widgetId;

  /// New grid X position.
  final int gridX;

  /// New grid Y position.
  final int gridY;

  /// New grid width (1–12).
  final int gridWidth;

  /// New grid height (1–12).
  final int gridHeight;

  /// Creates a [WidgetPositionUpdate] instance.
  const WidgetPositionUpdate({
    required this.widgetId,
    required this.gridX,
    required this.gridY,
    required this.gridWidth,
    required this.gridHeight,
  });

  /// Deserializes a [WidgetPositionUpdate] from a JSON map.
  factory WidgetPositionUpdate.fromJson(Map<String, dynamic> json) =>
      _$WidgetPositionUpdateFromJson(json);

  /// Serializes this [WidgetPositionUpdate] to a JSON map.
  Map<String, dynamic> toJson() => _$WidgetPositionUpdateToJson(this);
}

/// Request body for batch-updating widget positions.
@JsonSerializable(explicitToJson: true)
class UpdateLayoutRequest {
  /// Position updates for each widget.
  final List<WidgetPositionUpdate> positions;

  /// Creates an [UpdateLayoutRequest] instance.
  const UpdateLayoutRequest({required this.positions});

  /// Deserializes an [UpdateLayoutRequest] from a JSON map.
  factory UpdateLayoutRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateLayoutRequestFromJson(json);

  /// Serializes this [UpdateLayoutRequest] to a JSON map.
  Map<String, dynamic> toJson() => _$UpdateLayoutRequestToJson(this);
}

/// Request body for creating a dashboard from a template.
@JsonSerializable()
class CreateFromTemplateRequest {
  /// Name for the new dashboard (max 200 chars).
  final String name;

  /// UUID of the template dashboard.
  final String templateId;

  /// Creates a [CreateFromTemplateRequest] instance.
  const CreateFromTemplateRequest({
    required this.name,
    required this.templateId,
  });

  /// Deserializes a [CreateFromTemplateRequest] from a JSON map.
  factory CreateFromTemplateRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateFromTemplateRequestFromJson(json);

  /// Serializes this [CreateFromTemplateRequest] to a JSON map.
  Map<String, dynamic> toJson() => _$CreateFromTemplateRequestToJson(this);
}

// ─────────────────────────────────────────────────────────────────────────────
// Traces & Spans
// ─────────────────────────────────────────────────────────────────────────────

/// A distributed trace span.
@JsonSerializable()
class TraceSpanResponse {
  /// Unique identifier (UUID).
  final String id;

  /// Correlation ID linking related operations.
  final String correlationId;

  /// Trace ID for the distributed trace.
  final String traceId;

  /// Span ID within the trace.
  final String spanId;

  /// Parent span ID (null for root spans).
  final String? parentSpanId;

  /// Name of the service that produced the span.
  final String serviceName;

  /// Name of the operation.
  final String operationName;

  /// Timestamp when the span started.
  final DateTime startTime;

  /// Timestamp when the span ended.
  final DateTime? endTime;

  /// Duration in milliseconds.
  final int? durationMs;

  /// Span completion status.
  @SpanStatusConverter()
  final SpanStatus status;

  /// Status message or error details.
  final String? statusMessage;

  /// JSON-encoded span tags.
  final String? tags;

  /// UUID of the owning team.
  final String teamId;

  /// Timestamp when the span was persisted.
  final DateTime? createdAt;

  /// Creates a [TraceSpanResponse] instance.
  const TraceSpanResponse({
    required this.id,
    required this.correlationId,
    required this.traceId,
    required this.spanId,
    this.parentSpanId,
    required this.serviceName,
    required this.operationName,
    required this.startTime,
    this.endTime,
    this.durationMs,
    required this.status,
    this.statusMessage,
    this.tags,
    required this.teamId,
    this.createdAt,
  });

  /// Deserializes a [TraceSpanResponse] from a JSON map.
  factory TraceSpanResponse.fromJson(Map<String, dynamic> json) =>
      _$TraceSpanResponseFromJson(json);

  /// Serializes this [TraceSpanResponse] to a JSON map.
  Map<String, dynamic> toJson() => _$TraceSpanResponseToJson(this);
}

/// A complete trace flow with all its spans.
@JsonSerializable(explicitToJson: true)
class TraceFlowResponse {
  /// Correlation ID.
  final String correlationId;

  /// Trace ID.
  final String traceId;

  /// All spans in the trace.
  final List<TraceSpanResponse> spans;

  /// Total duration in milliseconds.
  final int totalDurationMs;

  /// Number of spans.
  final int spanCount;

  /// Whether any span has an error status.
  final bool hasErrors;

  /// Creates a [TraceFlowResponse] instance.
  const TraceFlowResponse({
    required this.correlationId,
    required this.traceId,
    required this.spans,
    required this.totalDurationMs,
    required this.spanCount,
    required this.hasErrors,
  });

  /// Deserializes a [TraceFlowResponse] from a JSON map.
  factory TraceFlowResponse.fromJson(Map<String, dynamic> json) =>
      _$TraceFlowResponseFromJson(json);

  /// Serializes this [TraceFlowResponse] to a JSON map.
  Map<String, dynamic> toJson() => _$TraceFlowResponseToJson(this);
}

/// A span in waterfall view with depth and offset metadata.
@JsonSerializable()
class WaterfallSpan {
  /// Unique identifier (UUID).
  final String id;

  /// Span ID.
  final String spanId;

  /// Parent span ID (null for root).
  final String? parentSpanId;

  /// Name of the service.
  final String serviceName;

  /// Name of the operation.
  final String operationName;

  /// Offset from trace start in milliseconds.
  final int offsetMs;

  /// Duration in milliseconds.
  final int durationMs;

  /// Span completion status.
  @SpanStatusConverter()
  final SpanStatus status;

  /// Status message or error details.
  final String? statusMessage;

  /// Nesting depth in the trace tree.
  final int depth;

  /// UUIDs of related log entries.
  final List<String> relatedLogIds;

  /// Creates a [WaterfallSpan] instance.
  const WaterfallSpan({
    required this.id,
    required this.spanId,
    this.parentSpanId,
    required this.serviceName,
    required this.operationName,
    required this.offsetMs,
    required this.durationMs,
    required this.status,
    this.statusMessage,
    required this.depth,
    required this.relatedLogIds,
  });

  /// Deserializes a [WaterfallSpan] from a JSON map.
  factory WaterfallSpan.fromJson(Map<String, dynamic> json) =>
      _$WaterfallSpanFromJson(json);

  /// Serializes this [WaterfallSpan] to a JSON map.
  Map<String, dynamic> toJson() => _$WaterfallSpanToJson(this);
}

/// Waterfall visualization of a trace with timing offsets.
@JsonSerializable(explicitToJson: true)
class TraceWaterfallResponse {
  /// Correlation ID.
  final String correlationId;

  /// Trace ID.
  final String traceId;

  /// Total duration in milliseconds.
  final int totalDurationMs;

  /// Number of spans.
  final int spanCount;

  /// Number of distinct services.
  final int serviceCount;

  /// Whether any span has an error status.
  final bool hasErrors;

  /// Spans in waterfall order.
  final List<WaterfallSpan> spans;

  /// Creates a [TraceWaterfallResponse] instance.
  const TraceWaterfallResponse({
    required this.correlationId,
    required this.traceId,
    required this.totalDurationMs,
    required this.spanCount,
    required this.serviceCount,
    required this.hasErrors,
    required this.spans,
  });

  /// Deserializes a [TraceWaterfallResponse] from a JSON map.
  factory TraceWaterfallResponse.fromJson(Map<String, dynamic> json) =>
      _$TraceWaterfallResponseFromJson(json);

  /// Serializes this [TraceWaterfallResponse] to a JSON map.
  Map<String, dynamic> toJson() => _$TraceWaterfallResponseToJson(this);
}

/// Summary of a trace for list views.
@JsonSerializable()
class TraceListResponse {
  /// Correlation ID.
  final String correlationId;

  /// Trace ID.
  final String traceId;

  /// Service name of the root span.
  final String rootService;

  /// Operation name of the root span.
  final String rootOperation;

  /// Number of spans.
  final int spanCount;

  /// Number of distinct services.
  final int serviceCount;

  /// Total duration in milliseconds.
  final int totalDurationMs;

  /// Whether any span has an error status.
  final bool hasErrors;

  /// Start time of the earliest span.
  final DateTime startTime;

  /// End time of the latest span.
  final DateTime endTime;

  /// Creates a [TraceListResponse] instance.
  const TraceListResponse({
    required this.correlationId,
    required this.traceId,
    required this.rootService,
    required this.rootOperation,
    required this.spanCount,
    required this.serviceCount,
    required this.totalDurationMs,
    required this.hasErrors,
    required this.startTime,
    required this.endTime,
  });

  /// Deserializes a [TraceListResponse] from a JSON map.
  factory TraceListResponse.fromJson(Map<String, dynamic> json) =>
      _$TraceListResponseFromJson(json);

  /// Serializes this [TraceListResponse] to a JSON map.
  Map<String, dynamic> toJson() => _$TraceListResponseToJson(this);
}

/// Root cause analysis result for a failed trace.
@JsonSerializable(explicitToJson: true)
class RootCauseAnalysisResponse {
  /// Correlation ID.
  final String correlationId;

  /// Trace ID.
  final String traceId;

  /// The span identified as the root cause.
  final TraceSpanResponse rootCauseSpan;

  /// Name of the service where the root cause originated.
  final String rootCauseService;

  /// Human-readable root cause message.
  final String rootCauseMessage;

  /// Chain of error spans from root cause to symptom.
  final List<TraceSpanResponse> errorChain;

  /// UUIDs of related log entries.
  final List<String> relatedLogEntryIds;

  /// Number of services impacted by the failure.
  final int impactedServiceCount;

  /// Total trace duration in milliseconds.
  final int totalDurationMs;

  /// Creates a [RootCauseAnalysisResponse] instance.
  const RootCauseAnalysisResponse({
    required this.correlationId,
    required this.traceId,
    required this.rootCauseSpan,
    required this.rootCauseService,
    required this.rootCauseMessage,
    required this.errorChain,
    required this.relatedLogEntryIds,
    required this.impactedServiceCount,
    required this.totalDurationMs,
  });

  /// Deserializes a [RootCauseAnalysisResponse] from a JSON map.
  factory RootCauseAnalysisResponse.fromJson(Map<String, dynamic> json) =>
      _$RootCauseAnalysisResponseFromJson(json);

  /// Serializes this [RootCauseAnalysisResponse] to a JSON map.
  Map<String, dynamic> toJson() => _$RootCauseAnalysisResponseToJson(this);
}

/// Request body for creating a trace span.
@JsonSerializable()
class CreateTraceSpanRequest {
  /// Correlation ID (max 100 chars).
  final String correlationId;

  /// Trace ID (max 100 chars).
  final String traceId;

  /// Span ID (max 100 chars).
  final String spanId;

  /// Parent span ID (max 100 chars).
  final String? parentSpanId;

  /// Service name (max 200 chars).
  final String serviceName;

  /// Operation name (max 500 chars).
  final String operationName;

  /// Span start time.
  final DateTime startTime;

  /// Span end time.
  final DateTime? endTime;

  /// Duration in milliseconds.
  final int? durationMs;

  /// Span completion status.
  @SpanStatusConverter()
  final SpanStatus? status;

  /// Status message or error details.
  final String? statusMessage;

  /// JSON-encoded span tags.
  final String? tags;

  /// Creates a [CreateTraceSpanRequest] instance.
  const CreateTraceSpanRequest({
    required this.correlationId,
    required this.traceId,
    required this.spanId,
    this.parentSpanId,
    required this.serviceName,
    required this.operationName,
    required this.startTime,
    this.endTime,
    this.durationMs,
    this.status,
    this.statusMessage,
    this.tags,
  });

  /// Deserializes a [CreateTraceSpanRequest] from a JSON map.
  factory CreateTraceSpanRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateTraceSpanRequestFromJson(json);

  /// Serializes this [CreateTraceSpanRequest] to a JSON map.
  Map<String, dynamic> toJson() => _$CreateTraceSpanRequestToJson(this);
}

// ─────────────────────────────────────────────────────────────────────────────
// Retention Policies & Storage
// ─────────────────────────────────────────────────────────────────────────────

/// A data retention policy.
@JsonSerializable()
class RetentionPolicyResponse {
  /// Unique identifier (UUID).
  final String id;

  /// Policy name.
  final String name;

  /// Optional source name filter.
  final String? sourceName;

  /// Optional log level filter.
  @LogLevelConverter()
  final LogLevel? logLevel;

  /// Number of days to retain matching data.
  final int retentionDays;

  /// Action to take when data expires.
  @RetentionActionConverter()
  final RetentionAction action;

  /// Destination for archived data (ARCHIVE action only).
  final String? archiveDestination;

  /// Whether the policy is active.
  final bool isActive;

  /// UUID of the owning team.
  final String teamId;

  /// UUID of the user who created the policy.
  final String createdBy;

  /// Timestamp of the last policy execution.
  final DateTime? lastExecutedAt;

  /// Timestamp when the policy was created.
  final DateTime? createdAt;

  /// Timestamp when the policy was last updated.
  final DateTime? updatedAt;

  /// Creates a [RetentionPolicyResponse] instance.
  const RetentionPolicyResponse({
    required this.id,
    required this.name,
    this.sourceName,
    this.logLevel,
    required this.retentionDays,
    required this.action,
    this.archiveDestination,
    required this.isActive,
    required this.teamId,
    required this.createdBy,
    this.lastExecutedAt,
    this.createdAt,
    this.updatedAt,
  });

  /// Deserializes a [RetentionPolicyResponse] from a JSON map.
  factory RetentionPolicyResponse.fromJson(Map<String, dynamic> json) =>
      _$RetentionPolicyResponseFromJson(json);

  /// Serializes this [RetentionPolicyResponse] to a JSON map.
  Map<String, dynamic> toJson() => _$RetentionPolicyResponseToJson(this);
}

/// Storage usage statistics for a team.
@JsonSerializable()
class StorageUsageResponse {
  /// Total number of stored log entries.
  final int totalLogEntries;

  /// Total number of stored metric data points.
  final int totalMetricDataPoints;

  /// Total number of stored trace spans.
  final int totalTraceSpans;

  /// Log entry counts by service name.
  final Map<String, int> logEntriesByService;

  /// Log entry counts by log level.
  final Map<String, int> logEntriesByLevel;

  /// Number of active retention policies.
  final int activeRetentionPolicies;

  /// Timestamp of the oldest stored log entry.
  final DateTime? oldestLogEntry;

  /// Timestamp of the newest stored log entry.
  final DateTime? newestLogEntry;

  /// Creates a [StorageUsageResponse] instance.
  const StorageUsageResponse({
    required this.totalLogEntries,
    required this.totalMetricDataPoints,
    required this.totalTraceSpans,
    required this.logEntriesByService,
    required this.logEntriesByLevel,
    required this.activeRetentionPolicies,
    this.oldestLogEntry,
    this.newestLogEntry,
  });

  /// Deserializes a [StorageUsageResponse] from a JSON map.
  factory StorageUsageResponse.fromJson(Map<String, dynamic> json) =>
      _$StorageUsageResponseFromJson(json);

  /// Serializes this [StorageUsageResponse] to a JSON map.
  Map<String, dynamic> toJson() => _$StorageUsageResponseToJson(this);
}

/// Request body for creating a retention policy.
@JsonSerializable()
class CreateRetentionPolicyRequest {
  /// Policy name (max 200 chars).
  final String name;

  /// Optional source name filter (max 200 chars).
  final String? sourceName;

  /// Optional log level filter.
  @LogLevelConverter()
  final LogLevel? logLevel;

  /// Number of days to retain matching data (1–365).
  final int retentionDays;

  /// Action to take when data expires.
  @RetentionActionConverter()
  final RetentionAction action;

  /// Destination for archived data (max 500 chars).
  final String? archiveDestination;

  /// Creates a [CreateRetentionPolicyRequest] instance.
  const CreateRetentionPolicyRequest({
    required this.name,
    this.sourceName,
    this.logLevel,
    required this.retentionDays,
    required this.action,
    this.archiveDestination,
  });

  /// Deserializes a [CreateRetentionPolicyRequest] from a JSON map.
  factory CreateRetentionPolicyRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateRetentionPolicyRequestFromJson(json);

  /// Serializes this [CreateRetentionPolicyRequest] to a JSON map.
  Map<String, dynamic> toJson() =>
      _$CreateRetentionPolicyRequestToJson(this);
}

/// Request body for updating an existing retention policy.
@JsonSerializable()
class UpdateRetentionPolicyRequest {
  /// Updated policy name (max 200 chars).
  final String? name;

  /// Updated source name filter (max 200 chars).
  final String? sourceName;

  /// Updated log level filter.
  @LogLevelConverter()
  final LogLevel? logLevel;

  /// Updated retention days (1–365).
  final int? retentionDays;

  /// Updated action.
  @RetentionActionConverter()
  final RetentionAction? action;

  /// Updated archive destination (max 500 chars).
  final String? archiveDestination;

  /// Whether the policy is active.
  final bool? isActive;

  /// Creates an [UpdateRetentionPolicyRequest] instance.
  const UpdateRetentionPolicyRequest({
    this.name,
    this.sourceName,
    this.logLevel,
    this.retentionDays,
    this.action,
    this.archiveDestination,
    this.isActive,
  });

  /// Deserializes an [UpdateRetentionPolicyRequest] from a JSON map.
  factory UpdateRetentionPolicyRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateRetentionPolicyRequestFromJson(json);

  /// Serializes this [UpdateRetentionPolicyRequest] to a JSON map.
  Map<String, dynamic> toJson() =>
      _$UpdateRetentionPolicyRequestToJson(this);
}

// ─────────────────────────────────────────────────────────────────────────────
// Anomaly Detection
// ─────────────────────────────────────────────────────────────────────────────

/// An anomaly detection baseline for a metric.
@JsonSerializable()
class AnomalyBaselineResponse {
  /// Unique identifier (UUID).
  final String id;

  /// Name of the monitored service.
  final String serviceName;

  /// Name of the monitored metric.
  final String metricName;

  /// Computed baseline value.
  final double baselineValue;

  /// Standard deviation of the baseline.
  final double standardDeviation;

  /// Number of data points used to compute the baseline.
  final int sampleCount;

  /// Start of the baseline computation window.
  final DateTime windowStartTime;

  /// End of the baseline computation window.
  final DateTime windowEndTime;

  /// Number of standard deviations for anomaly threshold.
  final double deviationThreshold;

  /// Whether the baseline is active.
  final bool isActive;

  /// UUID of the owning team.
  final String teamId;

  /// Timestamp of the last baseline recomputation.
  final DateTime? lastComputedAt;

  /// Timestamp when the baseline was created.
  final DateTime? createdAt;

  /// Timestamp when the baseline was last updated.
  final DateTime? updatedAt;

  /// Creates an [AnomalyBaselineResponse] instance.
  const AnomalyBaselineResponse({
    required this.id,
    required this.serviceName,
    required this.metricName,
    required this.baselineValue,
    required this.standardDeviation,
    required this.sampleCount,
    required this.windowStartTime,
    required this.windowEndTime,
    required this.deviationThreshold,
    required this.isActive,
    required this.teamId,
    this.lastComputedAt,
    this.createdAt,
    this.updatedAt,
  });

  /// Deserializes an [AnomalyBaselineResponse] from a JSON map.
  factory AnomalyBaselineResponse.fromJson(Map<String, dynamic> json) =>
      _$AnomalyBaselineResponseFromJson(json);

  /// Serializes this [AnomalyBaselineResponse] to a JSON map.
  Map<String, dynamic> toJson() => _$AnomalyBaselineResponseToJson(this);
}

/// Result of an anomaly check against a baseline.
@JsonSerializable()
class AnomalyCheckResponse {
  /// Name of the monitored service.
  final String serviceName;

  /// Name of the monitored metric.
  final String metricName;

  /// Current metric value.
  final double currentValue;

  /// Baseline value.
  final double baselineValue;

  /// Standard deviation of the baseline.
  final double standardDeviation;

  /// Configured deviation threshold.
  final double deviationThreshold;

  /// Z-score of the current value.
  final double zScore;

  /// Whether the current value is anomalous.
  final bool isAnomaly;

  /// Direction of deviation ("above" or "below").
  final String direction;

  /// Timestamp when the check was performed.
  final DateTime checkedAt;

  /// Creates an [AnomalyCheckResponse] instance.
  const AnomalyCheckResponse({
    required this.serviceName,
    required this.metricName,
    required this.currentValue,
    required this.baselineValue,
    required this.standardDeviation,
    required this.deviationThreshold,
    required this.zScore,
    required this.isAnomaly,
    required this.direction,
    required this.checkedAt,
  });

  /// Deserializes an [AnomalyCheckResponse] from a JSON map.
  factory AnomalyCheckResponse.fromJson(Map<String, dynamic> json) =>
      _$AnomalyCheckResponseFromJson(json);

  /// Serializes this [AnomalyCheckResponse] to a JSON map.
  Map<String, dynamic> toJson() => _$AnomalyCheckResponseToJson(this);
}

/// Full anomaly report with all baseline checks.
@JsonSerializable(explicitToJson: true)
class AnomalyReportResponse {
  /// UUID of the team.
  final String teamId;

  /// Timestamp when the report was generated.
  final DateTime generatedAt;

  /// Total number of active baselines.
  final int totalBaselines;

  /// Number of anomalies detected.
  final int anomaliesDetected;

  /// Checks that flagged anomalies.
  final List<AnomalyCheckResponse> anomalies;

  /// All checks performed (including non-anomalous).
  final List<AnomalyCheckResponse> allChecks;

  /// Creates an [AnomalyReportResponse] instance.
  const AnomalyReportResponse({
    required this.teamId,
    required this.generatedAt,
    required this.totalBaselines,
    required this.anomaliesDetected,
    required this.anomalies,
    required this.allChecks,
  });

  /// Deserializes an [AnomalyReportResponse] from a JSON map.
  factory AnomalyReportResponse.fromJson(Map<String, dynamic> json) =>
      _$AnomalyReportResponseFromJson(json);

  /// Serializes this [AnomalyReportResponse] to a JSON map.
  Map<String, dynamic> toJson() => _$AnomalyReportResponseToJson(this);
}

/// Request body for creating an anomaly detection baseline.
@JsonSerializable()
class CreateBaselineRequest {
  /// Service name to monitor (max 200 chars).
  final String serviceName;

  /// Metric name to monitor (max 200 chars).
  final String metricName;

  /// Baseline computation window in hours (1–720).
  final int windowHours;

  /// Number of standard deviations for anomaly threshold (1–5).
  final double deviationThreshold;

  /// Creates a [CreateBaselineRequest] instance.
  const CreateBaselineRequest({
    required this.serviceName,
    required this.metricName,
    required this.windowHours,
    required this.deviationThreshold,
  });

  /// Deserializes a [CreateBaselineRequest] from a JSON map.
  factory CreateBaselineRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateBaselineRequestFromJson(json);

  /// Serializes this [CreateBaselineRequest] to a JSON map.
  Map<String, dynamic> toJson() => _$CreateBaselineRequestToJson(this);
}

/// Request body for updating an existing anomaly baseline.
@JsonSerializable()
class UpdateBaselineRequest {
  /// Updated window in hours (1–720).
  final int? windowHours;

  /// Updated deviation threshold (1–5).
  final double? deviationThreshold;

  /// Whether the baseline is active.
  final bool? isActive;

  /// Creates an [UpdateBaselineRequest] instance.
  const UpdateBaselineRequest({
    this.windowHours,
    this.deviationThreshold,
    this.isActive,
  });

  /// Deserializes an [UpdateBaselineRequest] from a JSON map.
  factory UpdateBaselineRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateBaselineRequestFromJson(json);

  /// Serializes this [UpdateBaselineRequest] to a JSON map.
  Map<String, dynamic> toJson() => _$UpdateBaselineRequestToJson(this);
}

// ─────────────────────────────────────────────────────────────────────────────
// Ingestion Stats
// ─────────────────────────────────────────────────────────────────────────────

/// Real-time log ingestion statistics.
@JsonSerializable()
class IngestionStatsResponse {
  /// Total number of logs ingested.
  final int totalLogsIngested;

  /// Current ingestion rate (logs per second).
  final double logsPerSecond;

  /// Number of active log sources.
  final int activeSourceCount;

  /// Log counts by severity level.
  final Map<String, int> logsByLevel;

  /// Log counts by service name.
  final Map<String, int> logsByService;

  /// Start of the statistics window.
  final DateTime since;

  /// Creates an [IngestionStatsResponse] instance.
  const IngestionStatsResponse({
    required this.totalLogsIngested,
    required this.logsPerSecond,
    required this.activeSourceCount,
    required this.logsByLevel,
    required this.logsByService,
    required this.since,
  });

  /// Deserializes an [IngestionStatsResponse] from a JSON map.
  factory IngestionStatsResponse.fromJson(Map<String, dynamic> json) =>
      _$IngestionStatsResponseFromJson(json);

  /// Serializes this [IngestionStatsResponse] to a JSON map.
  Map<String, dynamic> toJson() => _$IngestionStatsResponseToJson(this);
}
