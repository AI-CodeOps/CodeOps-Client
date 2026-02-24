// Tests for logger providers.
//
// Verifies singleton provider creation, FutureProvider types,
// StateProvider defaults, and state updates for all Logger providers.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/health_snapshot.dart';
import 'package:codeops/models/logger_enums.dart';
import 'package:codeops/models/logger_models.dart';
import 'package:codeops/providers/logger_providers.dart';
import 'package:codeops/services/cloud/logger_api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ─────────────────────────────────────────────────────────────────────────
  // Core singleton providers
  // ─────────────────────────────────────────────────────────────────────────

  group('Core providers', () {
    test('loggerApiProvider creates LoggerApi', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final api = container.read(loggerApiProvider);

      expect(api, isA<LoggerApi>());
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // FutureProvider types — Sources
  // ─────────────────────────────────────────────────────────────────────────

  group('Source FutureProvider types', () {
    test('loggerSourcesProvider is a FutureProvider', () {
      expect(
        loggerSourcesProvider,
        isA<FutureProvider<List<LogSourceResponse>>>(),
      );
    });

    test('loggerSourcesPagedProvider is a FutureProvider', () {
      expect(
        loggerSourcesPagedProvider,
        isA<FutureProvider<PageResponse<LogSourceResponse>>>(),
      );
    });

    test('loggerSourceDetailProvider is a FutureProvider.family', () {
      expect(
        loggerSourceDetailProvider,
        isA<FutureProviderFamily<LogSourceResponse, String>>(),
      );
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // FutureProvider types — Log Entries
  // ─────────────────────────────────────────────────────────────────────────

  group('Log Entry FutureProvider types', () {
    test('loggerLogsProvider is a FutureProvider', () {
      expect(
        loggerLogsProvider,
        isA<FutureProvider<PageResponse<LogEntryResponse>>>(),
      );
    });

    test('loggerLogDetailProvider is a FutureProvider.family', () {
      expect(
        loggerLogDetailProvider,
        isA<FutureProviderFamily<LogEntryResponse, String>>(),
      );
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // FutureProvider types — Saved Queries
  // ─────────────────────────────────────────────────────────────────────────

  group('Saved Query FutureProvider types', () {
    test('loggerSavedQueriesProvider is a FutureProvider', () {
      expect(
        loggerSavedQueriesProvider,
        isA<FutureProvider<List<SavedQueryResponse>>>(),
      );
    });

    test('loggerSavedQueryDetailProvider is a FutureProvider.family', () {
      expect(
        loggerSavedQueryDetailProvider,
        isA<FutureProviderFamily<SavedQueryResponse, String>>(),
      );
    });

    test('loggerQueryHistoryProvider is a FutureProvider', () {
      expect(
        loggerQueryHistoryProvider,
        isA<FutureProvider<PageResponse<QueryHistoryResponse>>>(),
      );
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // FutureProvider types — Log Traps
  // ─────────────────────────────────────────────────────────────────────────

  group('Trap FutureProvider types', () {
    test('loggerTrapsProvider is a FutureProvider', () {
      expect(
        loggerTrapsProvider,
        isA<FutureProvider<List<LogTrapResponse>>>(),
      );
    });

    test('loggerTrapsPagedProvider is a FutureProvider', () {
      expect(
        loggerTrapsPagedProvider,
        isA<FutureProvider<PageResponse<LogTrapResponse>>>(),
      );
    });

    test('loggerTrapDetailProvider is a FutureProvider.family', () {
      expect(
        loggerTrapDetailProvider,
        isA<FutureProviderFamily<LogTrapResponse, String>>(),
      );
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // FutureProvider types — Alert Channels
  // ─────────────────────────────────────────────────────────────────────────

  group('Alert Channel FutureProvider types', () {
    test('loggerAlertChannelsProvider is a FutureProvider', () {
      expect(
        loggerAlertChannelsProvider,
        isA<FutureProvider<List<AlertChannelResponse>>>(),
      );
    });

    test('loggerAlertChannelsPagedProvider is a FutureProvider', () {
      expect(
        loggerAlertChannelsPagedProvider,
        isA<FutureProvider<PageResponse<AlertChannelResponse>>>(),
      );
    });

    test('loggerAlertChannelDetailProvider is a FutureProvider.family', () {
      expect(
        loggerAlertChannelDetailProvider,
        isA<FutureProviderFamily<AlertChannelResponse, String>>(),
      );
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // FutureProvider types — Alert Rules
  // ─────────────────────────────────────────────────────────────────────────

  group('Alert Rule FutureProvider types', () {
    test('loggerAlertRulesProvider is a FutureProvider', () {
      expect(
        loggerAlertRulesProvider,
        isA<FutureProvider<List<AlertRuleResponse>>>(),
      );
    });

    test('loggerAlertRulesPagedProvider is a FutureProvider', () {
      expect(
        loggerAlertRulesPagedProvider,
        isA<FutureProvider<PageResponse<AlertRuleResponse>>>(),
      );
    });

    test('loggerAlertRuleDetailProvider is a FutureProvider.family', () {
      expect(
        loggerAlertRuleDetailProvider,
        isA<FutureProviderFamily<AlertRuleResponse, String>>(),
      );
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // FutureProvider types — Alert History
  // ─────────────────────────────────────────────────────────────────────────

  group('Alert History FutureProvider types', () {
    test('loggerAlertHistoryProvider is a FutureProvider', () {
      expect(
        loggerAlertHistoryProvider,
        isA<FutureProvider<PageResponse<AlertHistoryResponse>>>(),
      );
    });

    test('loggerActiveAlertCountsProvider is a FutureProvider', () {
      expect(
        loggerActiveAlertCountsProvider,
        isA<FutureProvider<Map<String, int>>>(),
      );
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // FutureProvider types — Metrics
  // ─────────────────────────────────────────────────────────────────────────

  group('Metric FutureProvider types', () {
    test('loggerMetricsProvider is a FutureProvider', () {
      expect(
        loggerMetricsProvider,
        isA<FutureProvider<List<MetricResponse>>>(),
      );
    });

    test('loggerMetricsPagedProvider is a FutureProvider', () {
      expect(
        loggerMetricsPagedProvider,
        isA<FutureProvider<PageResponse<MetricResponse>>>(),
      );
    });

    test('loggerMetricDetailProvider is a FutureProvider.family', () {
      expect(
        loggerMetricDetailProvider,
        isA<FutureProviderFamily<MetricResponse, String>>(),
      );
    });

    test('loggerMetricsByServiceProvider is a FutureProvider.family', () {
      expect(
        loggerMetricsByServiceProvider,
        isA<FutureProviderFamily<List<MetricResponse>, String>>(),
      );
    });

    test('loggerServiceMetricsSummaryProvider is a FutureProvider.family', () {
      expect(
        loggerServiceMetricsSummaryProvider,
        isA<FutureProviderFamily<ServiceMetricsSummaryResponse, String>>(),
      );
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // FutureProvider types — Dashboards
  // ─────────────────────────────────────────────────────────────────────────

  group('Dashboard FutureProvider types', () {
    test('loggerDashboardsProvider is a FutureProvider', () {
      expect(
        loggerDashboardsProvider,
        isA<FutureProvider<List<DashboardResponse>>>(),
      );
    });

    test('loggerDashboardsPagedProvider is a FutureProvider', () {
      expect(
        loggerDashboardsPagedProvider,
        isA<FutureProvider<PageResponse<DashboardResponse>>>(),
      );
    });

    test('loggerDashboardDetailProvider is a FutureProvider.family', () {
      expect(
        loggerDashboardDetailProvider,
        isA<FutureProviderFamily<DashboardResponse, String>>(),
      );
    });

    test('loggerMyDashboardsProvider is a FutureProvider', () {
      expect(
        loggerMyDashboardsProvider,
        isA<FutureProvider<List<DashboardResponse>>>(),
      );
    });

    test('loggerSharedDashboardsProvider is a FutureProvider', () {
      expect(
        loggerSharedDashboardsProvider,
        isA<FutureProvider<List<DashboardResponse>>>(),
      );
    });

    test('loggerDashboardTemplatesProvider is a FutureProvider', () {
      expect(
        loggerDashboardTemplatesProvider,
        isA<FutureProvider<List<DashboardResponse>>>(),
      );
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // FutureProvider types — Traces
  // ─────────────────────────────────────────────────────────────────────────

  group('Trace FutureProvider types', () {
    test('loggerTracesProvider is a FutureProvider', () {
      expect(
        loggerTracesProvider,
        isA<FutureProvider<PageResponse<TraceListResponse>>>(),
      );
    });

    test('loggerTraceFlowProvider is a FutureProvider.family', () {
      expect(
        loggerTraceFlowProvider,
        isA<FutureProviderFamily<TraceFlowResponse, String>>(),
      );
    });

    test('loggerTraceWaterfallProvider is a FutureProvider.family', () {
      expect(
        loggerTraceWaterfallProvider,
        isA<FutureProviderFamily<TraceWaterfallResponse, String>>(),
      );
    });

    test('loggerTraceRootCauseProvider is a FutureProvider.family', () {
      expect(
        loggerTraceRootCauseProvider,
        isA<FutureProviderFamily<RootCauseAnalysisResponse?, String>>(),
      );
    });

    test('loggerErrorTracesProvider is a FutureProvider', () {
      expect(
        loggerErrorTracesProvider,
        isA<FutureProvider<List<TraceListResponse>>>(),
      );
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // FutureProvider types — Retention
  // ─────────────────────────────────────────────────────────────────────────

  group('Retention FutureProvider types', () {
    test('loggerRetentionPoliciesProvider is a FutureProvider', () {
      expect(
        loggerRetentionPoliciesProvider,
        isA<FutureProvider<List<RetentionPolicyResponse>>>(),
      );
    });

    test('loggerRetentionPolicyDetailProvider is a FutureProvider.family', () {
      expect(
        loggerRetentionPolicyDetailProvider,
        isA<FutureProviderFamily<RetentionPolicyResponse, String>>(),
      );
    });

    test('loggerStorageUsageProvider is a FutureProvider', () {
      expect(
        loggerStorageUsageProvider,
        isA<FutureProvider<StorageUsageResponse>>(),
      );
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // FutureProvider types — Anomaly Detection
  // ─────────────────────────────────────────────────────────────────────────

  group('Anomaly FutureProvider types', () {
    test('loggerBaselinesProvider is a FutureProvider', () {
      expect(
        loggerBaselinesProvider,
        isA<FutureProvider<List<AnomalyBaselineResponse>>>(),
      );
    });

    test('loggerBaselinesByServiceProvider is a FutureProvider.family', () {
      expect(
        loggerBaselinesByServiceProvider,
        isA<FutureProviderFamily<List<AnomalyBaselineResponse>, String>>(),
      );
    });

    test('loggerBaselineDetailProvider is a FutureProvider.family', () {
      expect(
        loggerBaselineDetailProvider,
        isA<FutureProviderFamily<AnomalyBaselineResponse, String>>(),
      );
    });

    test('loggerAnomalyReportProvider is a FutureProvider', () {
      expect(
        loggerAnomalyReportProvider,
        isA<FutureProvider<AnomalyReportResponse>>(),
      );
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Source UI state defaults and updates
  // ─────────────────────────────────────────────────────────────────────────

  group('Source UI state', () {
    test('loggerSourcePageProvider defaults to 0', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(loggerSourcePageProvider), 0);
    });

    test('selectedLoggerSourceIdProvider defaults to null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(selectedLoggerSourceIdProvider), isNull);
    });

    test('loggerSourcePageProvider can be updated', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(loggerSourcePageProvider.notifier).state = 3;

      expect(container.read(loggerSourcePageProvider), 3);
    });

    test('selectedLoggerSourceIdProvider can be updated', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(selectedLoggerSourceIdProvider.notifier).state = 'src-1';

      expect(container.read(selectedLoggerSourceIdProvider), 'src-1');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Log Entry UI state defaults and updates
  // ─────────────────────────────────────────────────────────────────────────

  group('Log Entry UI state', () {
    test('loggerLogSearchProvider defaults to empty string', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(loggerLogSearchProvider), '');
    });

    test('loggerLogLevelFilterProvider defaults to null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(loggerLogLevelFilterProvider), isNull);
    });

    test('loggerLogServiceFilterProvider defaults to null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(loggerLogServiceFilterProvider), isNull);
    });

    test('loggerLogStartTimeProvider defaults to null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(loggerLogStartTimeProvider), isNull);
    });

    test('loggerLogEndTimeProvider defaults to null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(loggerLogEndTimeProvider), isNull);
    });

    test('loggerLogPageProvider defaults to 0', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(loggerLogPageProvider), 0);
    });

    test('loggerLogLevelFilterProvider can be updated', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(loggerLogLevelFilterProvider.notifier).state =
          LogLevel.error;

      expect(container.read(loggerLogLevelFilterProvider), LogLevel.error);
    });

    test('loggerLogServiceFilterProvider can be updated', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(loggerLogServiceFilterProvider.notifier).state =
          'api-svc';

      expect(container.read(loggerLogServiceFilterProvider), 'api-svc');
    });

    test('loggerLogPageProvider can be updated', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(loggerLogPageProvider.notifier).state = 5;

      expect(container.read(loggerLogPageProvider), 5);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Saved Query UI state
  // ─────────────────────────────────────────────────────────────────────────

  group('Saved Query UI state', () {
    test('loggerQueryHistoryPageProvider defaults to 0', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(loggerQueryHistoryPageProvider), 0);
    });

    test('loggerQueryHistoryPageProvider can be updated', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(loggerQueryHistoryPageProvider.notifier).state = 2;

      expect(container.read(loggerQueryHistoryPageProvider), 2);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Trap UI state defaults and updates
  // ─────────────────────────────────────────────────────────────────────────

  group('Trap UI state', () {
    test('loggerTrapPageProvider defaults to 0', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(loggerTrapPageProvider), 0);
    });

    test('selectedLoggerTrapIdProvider defaults to null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(selectedLoggerTrapIdProvider), isNull);
    });

    test('selectedLoggerTrapIdProvider can be updated', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(selectedLoggerTrapIdProvider.notifier).state = 'trap-1';

      expect(container.read(selectedLoggerTrapIdProvider), 'trap-1');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Alert Channel UI state
  // ─────────────────────────────────────────────────────────────────────────

  group('Alert Channel UI state', () {
    test('loggerAlertChannelPageProvider defaults to 0', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(loggerAlertChannelPageProvider), 0);
    });

    test('loggerAlertChannelPageProvider can be updated', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(loggerAlertChannelPageProvider.notifier).state = 4;

      expect(container.read(loggerAlertChannelPageProvider), 4);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Alert Rule UI state
  // ─────────────────────────────────────────────────────────────────────────

  group('Alert Rule UI state', () {
    test('loggerAlertRulePageProvider defaults to 0', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(loggerAlertRulePageProvider), 0);
    });

    test('loggerAlertRulePageProvider can be updated', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(loggerAlertRulePageProvider.notifier).state = 2;

      expect(container.read(loggerAlertRulePageProvider), 2);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Alert History UI state defaults and updates
  // ─────────────────────────────────────────────────────────────────────────

  group('Alert History UI state', () {
    test('loggerAlertHistoryPageProvider defaults to 0', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(loggerAlertHistoryPageProvider), 0);
    });

    test('loggerAlertStatusFilterProvider defaults to null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(loggerAlertStatusFilterProvider), isNull);
    });

    test('loggerAlertSeverityFilterProvider defaults to null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(loggerAlertSeverityFilterProvider), isNull);
    });

    test('loggerAlertStatusFilterProvider can be updated', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(loggerAlertStatusFilterProvider.notifier).state =
          AlertStatus.fired;

      expect(
        container.read(loggerAlertStatusFilterProvider),
        AlertStatus.fired,
      );
    });

    test('loggerAlertSeverityFilterProvider can be updated', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(loggerAlertSeverityFilterProvider.notifier).state =
          AlertSeverity.critical;

      expect(
        container.read(loggerAlertSeverityFilterProvider),
        AlertSeverity.critical,
      );
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Metric UI state defaults and updates
  // ─────────────────────────────────────────────────────────────────────────

  group('Metric UI state', () {
    test('loggerMetricPageProvider defaults to 0', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(loggerMetricPageProvider), 0);
    });

    test('selectedLoggerMetricIdProvider defaults to null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(selectedLoggerMetricIdProvider), isNull);
    });

    test('selectedLoggerMetricIdProvider can be updated', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(selectedLoggerMetricIdProvider.notifier).state = 'met-1';

      expect(container.read(selectedLoggerMetricIdProvider), 'met-1');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Dashboard UI state defaults and updates
  // ─────────────────────────────────────────────────────────────────────────

  group('Dashboard UI state', () {
    test('loggerDashboardPageProvider defaults to 0', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(loggerDashboardPageProvider), 0);
    });

    test('selectedLoggerDashboardIdProvider defaults to null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(selectedLoggerDashboardIdProvider), isNull);
    });

    test('selectedLoggerDashboardIdProvider can be updated', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(selectedLoggerDashboardIdProvider.notifier).state =
          'dash-1';

      expect(container.read(selectedLoggerDashboardIdProvider), 'dash-1');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Trace UI state defaults and updates
  // ─────────────────────────────────────────────────────────────────────────

  group('Trace UI state', () {
    test('loggerTracePageProvider defaults to 0', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(loggerTracePageProvider), 0);
    });

    test('loggerTracePageProvider can be updated', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(loggerTracePageProvider.notifier).state = 7;

      expect(container.read(loggerTracePageProvider), 7);
    });
  });
}
