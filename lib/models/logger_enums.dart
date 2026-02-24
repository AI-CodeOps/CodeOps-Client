/// Enum types for the CodeOps-Logger module.
///
/// Each enum provides SCREAMING_SNAKE_CASE serialization matching the Server's
/// Java enums, plus a companion [JsonConverter] for use with `json_serializable`.
library;

import 'package:json_annotation/json_annotation.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LogLevel
// ─────────────────────────────────────────────────────────────────────────────

/// Log severity levels for log entries.
enum LogLevel {
  /// Finest-grained tracing information.
  trace,

  /// Debugging information.
  debug,

  /// Informational messages.
  info,

  /// Potentially harmful situations.
  warn,

  /// Error events that might still allow the application to continue.
  error,

  /// Very severe error events that will presumably lead to abort.
  fatal;

  /// Serializes to the server's SCREAMING_SNAKE_CASE representation.
  String toJson() => switch (this) {
        LogLevel.trace => 'TRACE',
        LogLevel.debug => 'DEBUG',
        LogLevel.info => 'INFO',
        LogLevel.warn => 'WARN',
        LogLevel.error => 'ERROR',
        LogLevel.fatal => 'FATAL',
      };

  /// Deserializes from the server's SCREAMING_SNAKE_CASE representation.
  static LogLevel fromJson(String json) => switch (json) {
        'TRACE' => LogLevel.trace,
        'DEBUG' => LogLevel.debug,
        'INFO' => LogLevel.info,
        'WARN' => LogLevel.warn,
        'ERROR' => LogLevel.error,
        'FATAL' => LogLevel.fatal,
        _ => throw ArgumentError('Unknown LogLevel: $json'),
      };

  /// Human-readable display label.
  String get displayName => switch (this) {
        LogLevel.trace => 'Trace',
        LogLevel.debug => 'Debug',
        LogLevel.info => 'Info',
        LogLevel.warn => 'Warning',
        LogLevel.error => 'Error',
        LogLevel.fatal => 'Fatal',
      };
}

/// JSON converter for [LogLevel].
class LogLevelConverter extends JsonConverter<LogLevel, String> {
  /// Creates a [LogLevelConverter].
  const LogLevelConverter();

  @override
  LogLevel fromJson(String json) => LogLevel.fromJson(json);

  @override
  String toJson(LogLevel object) => object.toJson();
}

// ─────────────────────────────────────────────────────────────────────────────
// AlertSeverity
// ─────────────────────────────────────────────────────────────────────────────

/// Alert severity classification.
enum AlertSeverity {
  /// Informational alert.
  info,

  /// Warning-level alert.
  warning,

  /// Critical alert requiring immediate attention.
  critical;

  /// Serializes to the server's SCREAMING_SNAKE_CASE representation.
  String toJson() => switch (this) {
        AlertSeverity.info => 'INFO',
        AlertSeverity.warning => 'WARNING',
        AlertSeverity.critical => 'CRITICAL',
      };

  /// Deserializes from the server's SCREAMING_SNAKE_CASE representation.
  static AlertSeverity fromJson(String json) => switch (json) {
        'INFO' => AlertSeverity.info,
        'WARNING' => AlertSeverity.warning,
        'CRITICAL' => AlertSeverity.critical,
        _ => throw ArgumentError('Unknown AlertSeverity: $json'),
      };

  /// Human-readable display label.
  String get displayName => switch (this) {
        AlertSeverity.info => 'Info',
        AlertSeverity.warning => 'Warning',
        AlertSeverity.critical => 'Critical',
      };
}

/// JSON converter for [AlertSeverity].
class AlertSeverityConverter extends JsonConverter<AlertSeverity, String> {
  /// Creates an [AlertSeverityConverter].
  const AlertSeverityConverter();

  @override
  AlertSeverity fromJson(String json) => AlertSeverity.fromJson(json);

  @override
  String toJson(AlertSeverity object) => object.toJson();
}

// ─────────────────────────────────────────────────────────────────────────────
// AlertStatus
// ─────────────────────────────────────────────────────────────────────────────

/// Alert lifecycle status.
enum AlertStatus {
  /// Alert has been triggered.
  fired,

  /// Alert has been acknowledged by an operator.
  acknowledged,

  /// Alert has been resolved.
  resolved;

  /// Serializes to the server's SCREAMING_SNAKE_CASE representation.
  String toJson() => switch (this) {
        AlertStatus.fired => 'FIRED',
        AlertStatus.acknowledged => 'ACKNOWLEDGED',
        AlertStatus.resolved => 'RESOLVED',
      };

  /// Deserializes from the server's SCREAMING_SNAKE_CASE representation.
  static AlertStatus fromJson(String json) => switch (json) {
        'FIRED' => AlertStatus.fired,
        'ACKNOWLEDGED' => AlertStatus.acknowledged,
        'RESOLVED' => AlertStatus.resolved,
        _ => throw ArgumentError('Unknown AlertStatus: $json'),
      };

  /// Human-readable display label.
  String get displayName => switch (this) {
        AlertStatus.fired => 'Fired',
        AlertStatus.acknowledged => 'Acknowledged',
        AlertStatus.resolved => 'Resolved',
      };
}

/// JSON converter for [AlertStatus].
class AlertStatusConverter extends JsonConverter<AlertStatus, String> {
  /// Creates an [AlertStatusConverter].
  const AlertStatusConverter();

  @override
  AlertStatus fromJson(String json) => AlertStatus.fromJson(json);

  @override
  String toJson(AlertStatus object) => object.toJson();
}

// ─────────────────────────────────────────────────────────────────────────────
// AlertChannelType
// ─────────────────────────────────────────────────────────────────────────────

/// Alert notification channel types.
enum AlertChannelType {
  /// Email notification channel.
  email,

  /// Generic webhook notification channel.
  webhook,

  /// Microsoft Teams notification channel.
  teams,

  /// Slack notification channel.
  slack;

  /// Serializes to the server's SCREAMING_SNAKE_CASE representation.
  String toJson() => switch (this) {
        AlertChannelType.email => 'EMAIL',
        AlertChannelType.webhook => 'WEBHOOK',
        AlertChannelType.teams => 'TEAMS',
        AlertChannelType.slack => 'SLACK',
      };

  /// Deserializes from the server's SCREAMING_SNAKE_CASE representation.
  static AlertChannelType fromJson(String json) => switch (json) {
        'EMAIL' => AlertChannelType.email,
        'WEBHOOK' => AlertChannelType.webhook,
        'TEAMS' => AlertChannelType.teams,
        'SLACK' => AlertChannelType.slack,
        _ => throw ArgumentError('Unknown AlertChannelType: $json'),
      };

  /// Human-readable display label.
  String get displayName => switch (this) {
        AlertChannelType.email => 'Email',
        AlertChannelType.webhook => 'Webhook',
        AlertChannelType.teams => 'Teams',
        AlertChannelType.slack => 'Slack',
      };
}

/// JSON converter for [AlertChannelType].
class AlertChannelTypeConverter
    extends JsonConverter<AlertChannelType, String> {
  /// Creates an [AlertChannelTypeConverter].
  const AlertChannelTypeConverter();

  @override
  AlertChannelType fromJson(String json) => AlertChannelType.fromJson(json);

  @override
  String toJson(AlertChannelType object) => object.toJson();
}

// ─────────────────────────────────────────────────────────────────────────────
// ConditionType
// ─────────────────────────────────────────────────────────────────────────────

/// Trap condition evaluation types.
enum ConditionType {
  /// Regular expression pattern match.
  regex,

  /// Keyword/substring match.
  keyword,

  /// Frequency threshold (count within time window).
  frequencyThreshold,

  /// Absence detection (no matching logs within time window).
  absence;

  /// Serializes to the server's SCREAMING_SNAKE_CASE representation.
  String toJson() => switch (this) {
        ConditionType.regex => 'REGEX',
        ConditionType.keyword => 'KEYWORD',
        ConditionType.frequencyThreshold => 'FREQUENCY_THRESHOLD',
        ConditionType.absence => 'ABSENCE',
      };

  /// Deserializes from the server's SCREAMING_SNAKE_CASE representation.
  static ConditionType fromJson(String json) => switch (json) {
        'REGEX' => ConditionType.regex,
        'KEYWORD' => ConditionType.keyword,
        'FREQUENCY_THRESHOLD' => ConditionType.frequencyThreshold,
        'ABSENCE' => ConditionType.absence,
        _ => throw ArgumentError('Unknown ConditionType: $json'),
      };

  /// Human-readable display label.
  String get displayName => switch (this) {
        ConditionType.regex => 'Regex',
        ConditionType.keyword => 'Keyword',
        ConditionType.frequencyThreshold => 'Frequency Threshold',
        ConditionType.absence => 'Absence',
      };
}

/// JSON converter for [ConditionType].
class ConditionTypeConverter extends JsonConverter<ConditionType, String> {
  /// Creates a [ConditionTypeConverter].
  const ConditionTypeConverter();

  @override
  ConditionType fromJson(String json) => ConditionType.fromJson(json);

  @override
  String toJson(ConditionType object) => object.toJson();
}

// ─────────────────────────────────────────────────────────────────────────────
// MetricType
// ─────────────────────────────────────────────────────────────────────────────

/// Metric data types.
enum MetricType {
  /// Monotonically increasing counter.
  counter,

  /// Point-in-time value.
  gauge,

  /// Distribution of values.
  histogram,

  /// Duration measurement.
  timer;

  /// Serializes to the server's SCREAMING_SNAKE_CASE representation.
  String toJson() => switch (this) {
        MetricType.counter => 'COUNTER',
        MetricType.gauge => 'GAUGE',
        MetricType.histogram => 'HISTOGRAM',
        MetricType.timer => 'TIMER',
      };

  /// Deserializes from the server's SCREAMING_SNAKE_CASE representation.
  static MetricType fromJson(String json) => switch (json) {
        'COUNTER' => MetricType.counter,
        'GAUGE' => MetricType.gauge,
        'HISTOGRAM' => MetricType.histogram,
        'TIMER' => MetricType.timer,
        _ => throw ArgumentError('Unknown MetricType: $json'),
      };

  /// Human-readable display label.
  String get displayName => switch (this) {
        MetricType.counter => 'Counter',
        MetricType.gauge => 'Gauge',
        MetricType.histogram => 'Histogram',
        MetricType.timer => 'Timer',
      };
}

/// JSON converter for [MetricType].
class MetricTypeConverter extends JsonConverter<MetricType, String> {
  /// Creates a [MetricTypeConverter].
  const MetricTypeConverter();

  @override
  MetricType fromJson(String json) => MetricType.fromJson(json);

  @override
  String toJson(MetricType object) => object.toJson();
}

// ─────────────────────────────────────────────────────────────────────────────
// RetentionAction
// ─────────────────────────────────────────────────────────────────────────────

/// Data retention actions.
enum RetentionAction {
  /// Permanently delete data.
  purge,

  /// Move data to archive storage.
  archive;

  /// Serializes to the server's SCREAMING_SNAKE_CASE representation.
  String toJson() => switch (this) {
        RetentionAction.purge => 'PURGE',
        RetentionAction.archive => 'ARCHIVE',
      };

  /// Deserializes from the server's SCREAMING_SNAKE_CASE representation.
  static RetentionAction fromJson(String json) => switch (json) {
        'PURGE' => RetentionAction.purge,
        'ARCHIVE' => RetentionAction.archive,
        _ => throw ArgumentError('Unknown RetentionAction: $json'),
      };

  /// Human-readable display label.
  String get displayName => switch (this) {
        RetentionAction.purge => 'Purge',
        RetentionAction.archive => 'Archive',
      };
}

/// JSON converter for [RetentionAction].
class RetentionActionConverter extends JsonConverter<RetentionAction, String> {
  /// Creates a [RetentionActionConverter].
  const RetentionActionConverter();

  @override
  RetentionAction fromJson(String json) => RetentionAction.fromJson(json);

  @override
  String toJson(RetentionAction object) => object.toJson();
}

// ─────────────────────────────────────────────────────────────────────────────
// SpanStatus
// ─────────────────────────────────────────────────────────────────────────────

/// Distributed trace span status.
enum SpanStatus {
  /// Span completed successfully.
  ok,

  /// Span completed with an error.
  error;

  /// Serializes to the server's SCREAMING_SNAKE_CASE representation.
  String toJson() => switch (this) {
        SpanStatus.ok => 'OK',
        SpanStatus.error => 'ERROR',
      };

  /// Deserializes from the server's SCREAMING_SNAKE_CASE representation.
  static SpanStatus fromJson(String json) => switch (json) {
        'OK' => SpanStatus.ok,
        'ERROR' => SpanStatus.error,
        _ => throw ArgumentError('Unknown SpanStatus: $json'),
      };

  /// Human-readable display label.
  String get displayName => switch (this) {
        SpanStatus.ok => 'OK',
        SpanStatus.error => 'Error',
      };
}

/// JSON converter for [SpanStatus].
class SpanStatusConverter extends JsonConverter<SpanStatus, String> {
  /// Creates a [SpanStatusConverter].
  const SpanStatusConverter();

  @override
  SpanStatus fromJson(String json) => SpanStatus.fromJson(json);

  @override
  String toJson(SpanStatus object) => object.toJson();
}

// ─────────────────────────────────────────────────────────────────────────────
// TrapType
// ─────────────────────────────────────────────────────────────────────────────

/// Log trap trigger types.
enum TrapType {
  /// Pattern-based trap (regex/keyword matching).
  pattern,

  /// Frequency-based trap (threshold exceeded in time window).
  frequency,

  /// Absence-based trap (expected logs missing in time window).
  absence;

  /// Serializes to the server's SCREAMING_SNAKE_CASE representation.
  String toJson() => switch (this) {
        TrapType.pattern => 'PATTERN',
        TrapType.frequency => 'FREQUENCY',
        TrapType.absence => 'ABSENCE',
      };

  /// Deserializes from the server's SCREAMING_SNAKE_CASE representation.
  static TrapType fromJson(String json) => switch (json) {
        'PATTERN' => TrapType.pattern,
        'FREQUENCY' => TrapType.frequency,
        'ABSENCE' => TrapType.absence,
        _ => throw ArgumentError('Unknown TrapType: $json'),
      };

  /// Human-readable display label.
  String get displayName => switch (this) {
        TrapType.pattern => 'Pattern',
        TrapType.frequency => 'Frequency',
        TrapType.absence => 'Absence',
      };
}

/// JSON converter for [TrapType].
class TrapTypeConverter extends JsonConverter<TrapType, String> {
  /// Creates a [TrapTypeConverter].
  const TrapTypeConverter();

  @override
  TrapType fromJson(String json) => TrapType.fromJson(json);

  @override
  String toJson(TrapType object) => object.toJson();
}

// ─────────────────────────────────────────────────────────────────────────────
// WidgetType
// ─────────────────────────────────────────────────────────────────────────────

/// Dashboard widget visualization types.
enum WidgetType {
  /// Live log stream widget.
  logStream,

  /// Time-series chart widget.
  timeSeriesChart,

  /// Single counter value widget.
  counter,

  /// Gauge visualization widget.
  gauge,

  /// Tabular data widget.
  table,

  /// Heatmap visualization widget.
  heatmap,

  /// Pie chart widget.
  pieChart,

  /// Bar chart widget.
  barChart;

  /// Serializes to the server's SCREAMING_SNAKE_CASE representation.
  String toJson() => switch (this) {
        WidgetType.logStream => 'LOG_STREAM',
        WidgetType.timeSeriesChart => 'TIME_SERIES_CHART',
        WidgetType.counter => 'COUNTER',
        WidgetType.gauge => 'GAUGE',
        WidgetType.table => 'TABLE',
        WidgetType.heatmap => 'HEATMAP',
        WidgetType.pieChart => 'PIE_CHART',
        WidgetType.barChart => 'BAR_CHART',
      };

  /// Deserializes from the server's SCREAMING_SNAKE_CASE representation.
  static WidgetType fromJson(String json) => switch (json) {
        'LOG_STREAM' => WidgetType.logStream,
        'TIME_SERIES_CHART' => WidgetType.timeSeriesChart,
        'COUNTER' => WidgetType.counter,
        'GAUGE' => WidgetType.gauge,
        'TABLE' => WidgetType.table,
        'HEATMAP' => WidgetType.heatmap,
        'PIE_CHART' => WidgetType.pieChart,
        'BAR_CHART' => WidgetType.barChart,
        _ => throw ArgumentError('Unknown WidgetType: $json'),
      };

  /// Human-readable display label.
  String get displayName => switch (this) {
        WidgetType.logStream => 'Log Stream',
        WidgetType.timeSeriesChart => 'Time Series Chart',
        WidgetType.counter => 'Counter',
        WidgetType.gauge => 'Gauge',
        WidgetType.table => 'Table',
        WidgetType.heatmap => 'Heatmap',
        WidgetType.pieChart => 'Pie Chart',
        WidgetType.barChart => 'Bar Chart',
      };
}

/// JSON converter for [WidgetType].
class WidgetTypeConverter extends JsonConverter<WidgetType, String> {
  /// Creates a [WidgetTypeConverter].
  const WidgetTypeConverter();

  @override
  WidgetType fromJson(String json) => WidgetType.fromJson(json);

  @override
  String toJson(WidgetType object) => object.toJson();
}
