import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/logger_enums.dart';

void main() {
  // ─────────────────────────────────────────────────────────────────────────
  // LogLevel
  // ─────────────────────────────────────────────────────────────────────────

  group('LogLevel', () {
    test('has 6 values', () {
      expect(LogLevel.values, hasLength(6));
    });

    test('toJson returns correct server strings', () {
      expect(LogLevel.trace.toJson(), 'TRACE');
      expect(LogLevel.debug.toJson(), 'DEBUG');
      expect(LogLevel.info.toJson(), 'INFO');
      expect(LogLevel.warn.toJson(), 'WARN');
      expect(LogLevel.error.toJson(), 'ERROR');
      expect(LogLevel.fatal.toJson(), 'FATAL');
    });

    test('fromJson round-trips all values', () {
      for (final v in LogLevel.values) {
        expect(LogLevel.fromJson(v.toJson()), v);
      }
    });

    test('displayName returns human label', () {
      expect(LogLevel.trace.displayName, 'Trace');
      expect(LogLevel.warn.displayName, 'Warning');
      expect(LogLevel.fatal.displayName, 'Fatal');
    });

    test('fromJson throws on invalid input', () {
      expect(() => LogLevel.fromJson('INVALID'), throwsArgumentError);
    });

    test('LogLevelConverter round-trips all values', () {
      const converter = LogLevelConverter();
      for (final v in LogLevel.values) {
        final json = converter.toJson(v);
        expect(converter.fromJson(json), v);
      }
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // AlertSeverity
  // ─────────────────────────────────────────────────────────────────────────

  group('AlertSeverity', () {
    test('has 3 values', () {
      expect(AlertSeverity.values, hasLength(3));
    });

    test('toJson returns correct server strings', () {
      expect(AlertSeverity.info.toJson(), 'INFO');
      expect(AlertSeverity.warning.toJson(), 'WARNING');
      expect(AlertSeverity.critical.toJson(), 'CRITICAL');
    });

    test('fromJson round-trips all values', () {
      for (final v in AlertSeverity.values) {
        expect(AlertSeverity.fromJson(v.toJson()), v);
      }
    });

    test('displayName returns human label', () {
      expect(AlertSeverity.info.displayName, 'Info');
      expect(AlertSeverity.warning.displayName, 'Warning');
      expect(AlertSeverity.critical.displayName, 'Critical');
    });

    test('fromJson throws on invalid input', () {
      expect(() => AlertSeverity.fromJson('INVALID'), throwsArgumentError);
    });

    test('AlertSeverityConverter round-trips all values', () {
      const converter = AlertSeverityConverter();
      for (final v in AlertSeverity.values) {
        expect(converter.fromJson(converter.toJson(v)), v);
      }
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // AlertStatus
  // ─────────────────────────────────────────────────────────────────────────

  group('AlertStatus', () {
    test('has 3 values', () {
      expect(AlertStatus.values, hasLength(3));
    });

    test('toJson returns correct server strings', () {
      expect(AlertStatus.fired.toJson(), 'FIRED');
      expect(AlertStatus.acknowledged.toJson(), 'ACKNOWLEDGED');
      expect(AlertStatus.resolved.toJson(), 'RESOLVED');
    });

    test('fromJson round-trips all values', () {
      for (final v in AlertStatus.values) {
        expect(AlertStatus.fromJson(v.toJson()), v);
      }
    });

    test('displayName returns human label', () {
      expect(AlertStatus.fired.displayName, 'Fired');
      expect(AlertStatus.acknowledged.displayName, 'Acknowledged');
      expect(AlertStatus.resolved.displayName, 'Resolved');
    });

    test('fromJson throws on invalid input', () {
      expect(() => AlertStatus.fromJson('INVALID'), throwsArgumentError);
    });

    test('AlertStatusConverter round-trips all values', () {
      const converter = AlertStatusConverter();
      for (final v in AlertStatus.values) {
        expect(converter.fromJson(converter.toJson(v)), v);
      }
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // AlertChannelType
  // ─────────────────────────────────────────────────────────────────────────

  group('AlertChannelType', () {
    test('has 4 values', () {
      expect(AlertChannelType.values, hasLength(4));
    });

    test('toJson returns correct server strings', () {
      expect(AlertChannelType.email.toJson(), 'EMAIL');
      expect(AlertChannelType.webhook.toJson(), 'WEBHOOK');
      expect(AlertChannelType.teams.toJson(), 'TEAMS');
      expect(AlertChannelType.slack.toJson(), 'SLACK');
    });

    test('fromJson round-trips all values', () {
      for (final v in AlertChannelType.values) {
        expect(AlertChannelType.fromJson(v.toJson()), v);
      }
    });

    test('displayName returns human label', () {
      expect(AlertChannelType.email.displayName, 'Email');
      expect(AlertChannelType.teams.displayName, 'Teams');
    });

    test('fromJson throws on invalid input', () {
      expect(
          () => AlertChannelType.fromJson('INVALID'), throwsArgumentError);
    });

    test('AlertChannelTypeConverter round-trips all values', () {
      const converter = AlertChannelTypeConverter();
      for (final v in AlertChannelType.values) {
        expect(converter.fromJson(converter.toJson(v)), v);
      }
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // ConditionType
  // ─────────────────────────────────────────────────────────────────────────

  group('ConditionType', () {
    test('has 4 values', () {
      expect(ConditionType.values, hasLength(4));
    });

    test('toJson returns correct server strings', () {
      expect(ConditionType.regex.toJson(), 'REGEX');
      expect(ConditionType.keyword.toJson(), 'KEYWORD');
      expect(ConditionType.frequencyThreshold.toJson(),
          'FREQUENCY_THRESHOLD');
      expect(ConditionType.absence.toJson(), 'ABSENCE');
    });

    test('fromJson round-trips all values', () {
      for (final v in ConditionType.values) {
        expect(ConditionType.fromJson(v.toJson()), v);
      }
    });

    test('displayName returns human label', () {
      expect(ConditionType.regex.displayName, 'Regex');
      expect(ConditionType.frequencyThreshold.displayName,
          'Frequency Threshold');
    });

    test('fromJson throws on invalid input', () {
      expect(
          () => ConditionType.fromJson('INVALID'), throwsArgumentError);
    });

    test('ConditionTypeConverter round-trips all values', () {
      const converter = ConditionTypeConverter();
      for (final v in ConditionType.values) {
        expect(converter.fromJson(converter.toJson(v)), v);
      }
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // MetricType
  // ─────────────────────────────────────────────────────────────────────────

  group('MetricType', () {
    test('has 4 values', () {
      expect(MetricType.values, hasLength(4));
    });

    test('toJson returns correct server strings', () {
      expect(MetricType.counter.toJson(), 'COUNTER');
      expect(MetricType.gauge.toJson(), 'GAUGE');
      expect(MetricType.histogram.toJson(), 'HISTOGRAM');
      expect(MetricType.timer.toJson(), 'TIMER');
    });

    test('fromJson round-trips all values', () {
      for (final v in MetricType.values) {
        expect(MetricType.fromJson(v.toJson()), v);
      }
    });

    test('displayName returns human label', () {
      expect(MetricType.counter.displayName, 'Counter');
      expect(MetricType.histogram.displayName, 'Histogram');
    });

    test('fromJson throws on invalid input', () {
      expect(() => MetricType.fromJson('INVALID'), throwsArgumentError);
    });

    test('MetricTypeConverter round-trips all values', () {
      const converter = MetricTypeConverter();
      for (final v in MetricType.values) {
        expect(converter.fromJson(converter.toJson(v)), v);
      }
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // RetentionAction
  // ─────────────────────────────────────────────────────────────────────────

  group('RetentionAction', () {
    test('has 2 values', () {
      expect(RetentionAction.values, hasLength(2));
    });

    test('toJson returns correct server strings', () {
      expect(RetentionAction.purge.toJson(), 'PURGE');
      expect(RetentionAction.archive.toJson(), 'ARCHIVE');
    });

    test('fromJson round-trips all values', () {
      for (final v in RetentionAction.values) {
        expect(RetentionAction.fromJson(v.toJson()), v);
      }
    });

    test('displayName returns human label', () {
      expect(RetentionAction.purge.displayName, 'Purge');
      expect(RetentionAction.archive.displayName, 'Archive');
    });

    test('fromJson throws on invalid input', () {
      expect(
          () => RetentionAction.fromJson('INVALID'), throwsArgumentError);
    });

    test('RetentionActionConverter round-trips all values', () {
      const converter = RetentionActionConverter();
      for (final v in RetentionAction.values) {
        expect(converter.fromJson(converter.toJson(v)), v);
      }
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // SpanStatus
  // ─────────────────────────────────────────────────────────────────────────

  group('SpanStatus', () {
    test('has 2 values', () {
      expect(SpanStatus.values, hasLength(2));
    });

    test('toJson returns correct server strings', () {
      expect(SpanStatus.ok.toJson(), 'OK');
      expect(SpanStatus.error.toJson(), 'ERROR');
    });

    test('fromJson round-trips all values', () {
      for (final v in SpanStatus.values) {
        expect(SpanStatus.fromJson(v.toJson()), v);
      }
    });

    test('displayName returns human label', () {
      expect(SpanStatus.ok.displayName, 'OK');
      expect(SpanStatus.error.displayName, 'Error');
    });

    test('fromJson throws on invalid input', () {
      expect(() => SpanStatus.fromJson('INVALID'), throwsArgumentError);
    });

    test('SpanStatusConverter round-trips all values', () {
      const converter = SpanStatusConverter();
      for (final v in SpanStatus.values) {
        expect(converter.fromJson(converter.toJson(v)), v);
      }
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // TrapType
  // ─────────────────────────────────────────────────────────────────────────

  group('TrapType', () {
    test('has 3 values', () {
      expect(TrapType.values, hasLength(3));
    });

    test('toJson returns correct server strings', () {
      expect(TrapType.pattern.toJson(), 'PATTERN');
      expect(TrapType.frequency.toJson(), 'FREQUENCY');
      expect(TrapType.absence.toJson(), 'ABSENCE');
    });

    test('fromJson round-trips all values', () {
      for (final v in TrapType.values) {
        expect(TrapType.fromJson(v.toJson()), v);
      }
    });

    test('displayName returns human label', () {
      expect(TrapType.pattern.displayName, 'Pattern');
      expect(TrapType.frequency.displayName, 'Frequency');
      expect(TrapType.absence.displayName, 'Absence');
    });

    test('fromJson throws on invalid input', () {
      expect(() => TrapType.fromJson('INVALID'), throwsArgumentError);
    });

    test('TrapTypeConverter round-trips all values', () {
      const converter = TrapTypeConverter();
      for (final v in TrapType.values) {
        expect(converter.fromJson(converter.toJson(v)), v);
      }
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // WidgetType
  // ─────────────────────────────────────────────────────────────────────────

  group('WidgetType', () {
    test('has 8 values', () {
      expect(WidgetType.values, hasLength(8));
    });

    test('toJson returns correct server strings', () {
      expect(WidgetType.logStream.toJson(), 'LOG_STREAM');
      expect(WidgetType.timeSeriesChart.toJson(), 'TIME_SERIES_CHART');
      expect(WidgetType.counter.toJson(), 'COUNTER');
      expect(WidgetType.gauge.toJson(), 'GAUGE');
      expect(WidgetType.table.toJson(), 'TABLE');
      expect(WidgetType.heatmap.toJson(), 'HEATMAP');
      expect(WidgetType.pieChart.toJson(), 'PIE_CHART');
      expect(WidgetType.barChart.toJson(), 'BAR_CHART');
    });

    test('fromJson round-trips all values', () {
      for (final v in WidgetType.values) {
        expect(WidgetType.fromJson(v.toJson()), v);
      }
    });

    test('displayName returns human label', () {
      expect(WidgetType.logStream.displayName, 'Log Stream');
      expect(WidgetType.timeSeriesChart.displayName, 'Time Series Chart');
      expect(WidgetType.pieChart.displayName, 'Pie Chart');
    });

    test('fromJson throws on invalid input', () {
      expect(() => WidgetType.fromJson('INVALID'), throwsArgumentError);
    });

    test('WidgetTypeConverter round-trips all values', () {
      const converter = WidgetTypeConverter();
      for (final v in WidgetType.values) {
        expect(converter.fromJson(converter.toJson(v)), v);
      }
    });
  });
}
