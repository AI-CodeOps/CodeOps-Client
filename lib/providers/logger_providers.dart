/// Riverpod providers for the Logger module.
///
/// Manages state, exposes API data, handles filtering/sorting, and
/// provides the reactive layer between [LoggerApi] and the UI pages.
/// Follows the same patterns as [registry_providers.dart]:
/// [Provider] for singletons, [FutureProvider] for async data,
/// [FutureProvider.family] for parameterized queries,
/// [StateProvider] for UI state.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/health_snapshot.dart';
import '../models/logger_enums.dart';
import '../models/logger_models.dart';
import '../services/cloud/logger_api.dart';
import 'auth_providers.dart';
import 'team_providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Core Singleton Provider
// ─────────────────────────────────────────────────────────────────────────────

/// Provides the [LoggerApi] singleton for all Logger API calls.
///
/// Uses [apiClientProvider] from [auth_providers.dart] since Logger
/// is a module within the consolidated CodeOps-Server.
final loggerApiProvider = Provider<LoggerApi>((ref) {
  final client = ref.watch(apiClientProvider);
  return LoggerApi(client);
});

// ─────────────────────────────────────────────────────────────────────────────
// Log Sources — Data Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Fetches all log sources for the selected team.
final loggerSourcesProvider =
    FutureProvider<List<LogSourceResponse>>((ref) {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) return [];
  final api = ref.watch(loggerApiProvider);
  return api.listLogSources(teamId);
});

/// Fetches paginated log sources for the selected team.
final loggerSourcesPagedProvider =
    FutureProvider<PageResponse<LogSourceResponse>>((ref) {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) return PageResponse.empty();
  final api = ref.watch(loggerApiProvider);
  final page = ref.watch(loggerSourcePageProvider);
  return api.listLogSourcesPaged(teamId, page: page);
});

/// Fetches a single log source by ID.
final loggerSourceDetailProvider =
    FutureProvider.family<LogSourceResponse, String>((ref, sourceId) {
  final api = ref.watch(loggerApiProvider);
  return api.getLogSource(sourceId);
});

// ─────────────────────────────────────────────────────────────────────────────
// Log Sources — UI State Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Current page index for the sources list.
final loggerSourcePageProvider = StateProvider<int>((ref) => 0);

/// ID of the currently selected log source.
final selectedLoggerSourceIdProvider =
    StateProvider<String?>((ref) => null);

// ─────────────────────────────────────────────────────────────────────────────
// Log Entries — Data Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Fetches paginated log entries using current filter state.
final loggerLogsProvider =
    FutureProvider<PageResponse<LogEntryResponse>>((ref) {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) return PageResponse.empty();
  final api = ref.watch(loggerApiProvider);
  final level = ref.watch(loggerLogLevelFilterProvider);
  final service = ref.watch(loggerLogServiceFilterProvider);
  final search = ref.watch(loggerLogSearchProvider);
  final startTime = ref.watch(loggerLogStartTimeProvider);
  final endTime = ref.watch(loggerLogEndTimeProvider);
  final page = ref.watch(loggerLogPageProvider);
  return api.queryLogs(
    teamId,
    level: level,
    serviceName: service,
    query: search.isEmpty ? null : search,
    startTime: startTime,
    endTime: endTime,
    page: page,
  );
});

/// Fetches a single log entry by ID.
final loggerLogDetailProvider =
    FutureProvider.family<LogEntryResponse, String>((ref, logId) {
  final api = ref.watch(loggerApiProvider);
  return api.getLogEntry(logId);
});

// ─────────────────────────────────────────────────────────────────────────────
// Log Entries — UI State Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Full-text search query for logs.
final loggerLogSearchProvider = StateProvider<String>((ref) => '');

/// Log level filter (null = all levels).
final loggerLogLevelFilterProvider =
    StateProvider<LogLevel?>((ref) => null);

/// Service name filter (null = all services).
final loggerLogServiceFilterProvider =
    StateProvider<String?>((ref) => null);

/// Start time filter for log queries.
final loggerLogStartTimeProvider =
    StateProvider<DateTime?>((ref) => null);

/// End time filter for log queries.
final loggerLogEndTimeProvider = StateProvider<DateTime?>((ref) => null);

/// Current page index for the logs list.
final loggerLogPageProvider = StateProvider<int>((ref) => 0);

// ─────────────────────────────────────────────────────────────────────────────
// Saved Queries — Data Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Fetches all saved queries for the selected team.
final loggerSavedQueriesProvider =
    FutureProvider<List<SavedQueryResponse>>((ref) {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) return [];
  final api = ref.watch(loggerApiProvider);
  return api.listSavedQueries(teamId);
});

/// Fetches a single saved query by ID.
final loggerSavedQueryDetailProvider =
    FutureProvider.family<SavedQueryResponse, String>((ref, queryId) {
  final api = ref.watch(loggerApiProvider);
  return api.getSavedQuery(queryId);
});

/// Fetches paginated query execution history.
final loggerQueryHistoryProvider =
    FutureProvider<PageResponse<QueryHistoryResponse>>((ref) {
  final api = ref.watch(loggerApiProvider);
  final page = ref.watch(loggerQueryHistoryPageProvider);
  return api.getQueryHistory(page: page);
});

// ─────────────────────────────────────────────────────────────────────────────
// Saved Queries — UI State Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Current page index for query history.
final loggerQueryHistoryPageProvider = StateProvider<int>((ref) => 0);

// ─────────────────────────────────────────────────────────────────────────────
// Log Traps — Data Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Fetches all log traps for the selected team.
final loggerTrapsProvider =
    FutureProvider<List<LogTrapResponse>>((ref) {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) return [];
  final api = ref.watch(loggerApiProvider);
  return api.listLogTraps(teamId);
});

/// Fetches paginated log traps for the selected team.
final loggerTrapsPagedProvider =
    FutureProvider<PageResponse<LogTrapResponse>>((ref) {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) return PageResponse.empty();
  final api = ref.watch(loggerApiProvider);
  final page = ref.watch(loggerTrapPageProvider);
  return api.listLogTrapsPaged(teamId, page: page);
});

/// Fetches a single log trap by ID.
final loggerTrapDetailProvider =
    FutureProvider.family<LogTrapResponse, String>((ref, trapId) {
  final api = ref.watch(loggerApiProvider);
  return api.getLogTrap(trapId);
});

// ─────────────────────────────────────────────────────────────────────────────
// Log Traps — UI State Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Current page index for the traps list.
final loggerTrapPageProvider = StateProvider<int>((ref) => 0);

/// ID of the currently selected log trap.
final selectedLoggerTrapIdProvider =
    StateProvider<String?>((ref) => null);

// ─────────────────────────────────────────────────────────────────────────────
// Alert Channels — Data Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Fetches all alert channels for the selected team.
final loggerAlertChannelsProvider =
    FutureProvider<List<AlertChannelResponse>>((ref) {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) return [];
  final api = ref.watch(loggerApiProvider);
  return api.listAlertChannels(teamId);
});

/// Fetches paginated alert channels for the selected team.
final loggerAlertChannelsPagedProvider =
    FutureProvider<PageResponse<AlertChannelResponse>>((ref) {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) return PageResponse.empty();
  final api = ref.watch(loggerApiProvider);
  final page = ref.watch(loggerAlertChannelPageProvider);
  return api.listAlertChannelsPaged(teamId, page: page);
});

/// Fetches a single alert channel by ID.
final loggerAlertChannelDetailProvider =
    FutureProvider.family<AlertChannelResponse, String>((ref, channelId) {
  final api = ref.watch(loggerApiProvider);
  return api.getAlertChannel(channelId);
});

// ─────────────────────────────────────────────────────────────────────────────
// Alert Channels — UI State Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Current page index for the alert channels list.
final loggerAlertChannelPageProvider = StateProvider<int>((ref) => 0);

// ─────────────────────────────────────────────────────────────────────────────
// Alert Rules — Data Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Fetches all alert rules for the selected team.
final loggerAlertRulesProvider =
    FutureProvider<List<AlertRuleResponse>>((ref) {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) return [];
  final api = ref.watch(loggerApiProvider);
  return api.listAlertRules(teamId);
});

/// Fetches paginated alert rules for the selected team.
final loggerAlertRulesPagedProvider =
    FutureProvider<PageResponse<AlertRuleResponse>>((ref) {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) return PageResponse.empty();
  final api = ref.watch(loggerApiProvider);
  final page = ref.watch(loggerAlertRulePageProvider);
  return api.listAlertRulesPaged(teamId, page: page);
});

/// Fetches a single alert rule by ID.
final loggerAlertRuleDetailProvider =
    FutureProvider.family<AlertRuleResponse, String>((ref, ruleId) {
  final api = ref.watch(loggerApiProvider);
  return api.getAlertRule(ruleId);
});

// ─────────────────────────────────────────────────────────────────────────────
// Alert Rules — UI State Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Current page index for the alert rules list.
final loggerAlertRulePageProvider = StateProvider<int>((ref) => 0);

// ─────────────────────────────────────────────────────────────────────────────
// Alert History — Data Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Fetches paginated alert history for the selected team.
///
/// Automatically applies status and severity filters when set.
final loggerAlertHistoryProvider =
    FutureProvider<PageResponse<AlertHistoryResponse>>((ref) {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) return PageResponse.empty();
  final api = ref.watch(loggerApiProvider);
  final page = ref.watch(loggerAlertHistoryPageProvider);
  final status = ref.watch(loggerAlertStatusFilterProvider);
  final severity = ref.watch(loggerAlertSeverityFilterProvider);

  if (status != null) {
    return api.getAlertHistoryByStatus(teamId, status, page: page);
  }
  if (severity != null) {
    return api.getAlertHistoryBySeverity(teamId, severity, page: page);
  }
  return api.getAlertHistory(teamId, page: page);
});

/// Fetches active alert counts by severity for the selected team.
final loggerActiveAlertCountsProvider =
    FutureProvider<Map<String, int>>((ref) {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) return {};
  final api = ref.watch(loggerApiProvider);
  return api.getActiveAlertCounts(teamId);
});

// ─────────────────────────────────────────────────────────────────────────────
// Alert History — UI State Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Current page index for alert history.
final loggerAlertHistoryPageProvider = StateProvider<int>((ref) => 0);

/// Alert status filter (null = all statuses).
final loggerAlertStatusFilterProvider =
    StateProvider<AlertStatus?>((ref) => null);

/// Alert severity filter (null = all severities).
final loggerAlertSeverityFilterProvider =
    StateProvider<AlertSeverity?>((ref) => null);

// ─────────────────────────────────────────────────────────────────────────────
// Metrics — Data Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Fetches all metrics for the selected team.
final loggerMetricsProvider =
    FutureProvider<List<MetricResponse>>((ref) {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) return [];
  final api = ref.watch(loggerApiProvider);
  return api.listMetrics(teamId);
});

/// Fetches paginated metrics for the selected team.
final loggerMetricsPagedProvider =
    FutureProvider<PageResponse<MetricResponse>>((ref) {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) return PageResponse.empty();
  final api = ref.watch(loggerApiProvider);
  final page = ref.watch(loggerMetricPageProvider);
  return api.listMetricsPaged(teamId, page: page);
});

/// Fetches a single metric by ID.
final loggerMetricDetailProvider =
    FutureProvider.family<MetricResponse, String>((ref, metricId) {
  final api = ref.watch(loggerApiProvider);
  return api.getMetric(metricId);
});

/// Fetches metrics for a specific service.
final loggerMetricsByServiceProvider =
    FutureProvider.family<List<MetricResponse>, String>(
        (ref, serviceName) {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) return [];
  final api = ref.watch(loggerApiProvider);
  return api.listMetricsByService(teamId, serviceName);
});

/// Fetches the metrics summary for a service.
final loggerServiceMetricsSummaryProvider =
    FutureProvider.family<ServiceMetricsSummaryResponse, String>(
        (ref, serviceName) {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) {
    throw StateError('No team selected');
  }
  final api = ref.watch(loggerApiProvider);
  return api.getServiceMetricsSummary(teamId, serviceName);
});

// ─────────────────────────────────────────────────────────────────────────────
// Metrics — UI State Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Current page index for the metrics list.
final loggerMetricPageProvider = StateProvider<int>((ref) => 0);

/// ID of the currently selected metric.
final selectedLoggerMetricIdProvider =
    StateProvider<String?>((ref) => null);

// ─────────────────────────────────────────────────────────────────────────────
// Dashboards — Data Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Fetches all dashboards for the selected team.
final loggerDashboardsProvider =
    FutureProvider<List<DashboardResponse>>((ref) {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) return [];
  final api = ref.watch(loggerApiProvider);
  return api.listDashboards(teamId);
});

/// Fetches paginated dashboards for the selected team.
final loggerDashboardsPagedProvider =
    FutureProvider<PageResponse<DashboardResponse>>((ref) {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) return PageResponse.empty();
  final api = ref.watch(loggerApiProvider);
  final page = ref.watch(loggerDashboardPageProvider);
  return api.listDashboardsPaged(teamId, page: page);
});

/// Fetches a single dashboard by ID (includes widgets).
final loggerDashboardDetailProvider =
    FutureProvider.family<DashboardResponse, String>(
        (ref, dashboardId) {
  final api = ref.watch(loggerApiProvider);
  return api.getDashboard(dashboardId);
});

/// Fetches dashboards created by the current user.
final loggerMyDashboardsProvider =
    FutureProvider<List<DashboardResponse>>((ref) {
  final api = ref.watch(loggerApiProvider);
  return api.listMyDashboards();
});

/// Fetches shared dashboards for the selected team.
final loggerSharedDashboardsProvider =
    FutureProvider<List<DashboardResponse>>((ref) {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) return [];
  final api = ref.watch(loggerApiProvider);
  return api.listSharedDashboards(teamId);
});

/// Fetches dashboard templates for the selected team.
final loggerDashboardTemplatesProvider =
    FutureProvider<List<DashboardResponse>>((ref) {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) return [];
  final api = ref.watch(loggerApiProvider);
  return api.listDashboardTemplates(teamId);
});

// ─────────────────────────────────────────────────────────────────────────────
// Dashboards — UI State Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Current page index for the dashboards list.
final loggerDashboardPageProvider = StateProvider<int>((ref) => 0);

/// ID of the currently selected dashboard.
final selectedLoggerDashboardIdProvider =
    StateProvider<String?>((ref) => null);

// ─────────────────────────────────────────────────────────────────────────────
// Traces — Data Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Fetches paginated traces for the selected team.
final loggerTracesProvider =
    FutureProvider<PageResponse<TraceListResponse>>((ref) {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) return PageResponse.empty();
  final api = ref.watch(loggerApiProvider);
  final page = ref.watch(loggerTracePageProvider);
  return api.listTraces(teamId, page: page);
});

/// Fetches the trace flow for a correlation ID.
final loggerTraceFlowProvider =
    FutureProvider.family<TraceFlowResponse, String>(
        (ref, correlationId) {
  final api = ref.watch(loggerApiProvider);
  return api.getTraceFlow(correlationId);
});

/// Fetches the waterfall visualization for a trace.
final loggerTraceWaterfallProvider =
    FutureProvider.family<TraceWaterfallResponse, String>(
        (ref, correlationId) {
  final api = ref.watch(loggerApiProvider);
  return api.getTraceWaterfall(correlationId);
});

/// Fetches root cause analysis for a trace.
final loggerTraceRootCauseProvider =
    FutureProvider.family<RootCauseAnalysisResponse?, String>(
        (ref, correlationId) {
  final api = ref.watch(loggerApiProvider);
  return api.getTraceRootCause(correlationId);
});

/// Fetches traces that contain errors.
final loggerErrorTracesProvider =
    FutureProvider<List<TraceListResponse>>((ref) {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) return [];
  final api = ref.watch(loggerApiProvider);
  return api.listErrorTraces(teamId);
});

// ─────────────────────────────────────────────────────────────────────────────
// Traces — UI State Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Current page index for the traces list.
final loggerTracePageProvider = StateProvider<int>((ref) => 0);

// ─────────────────────────────────────────────────────────────────────────────
// Retention Policies — Data Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Fetches all retention policies for the selected team.
final loggerRetentionPoliciesProvider =
    FutureProvider<List<RetentionPolicyResponse>>((ref) {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) return [];
  final api = ref.watch(loggerApiProvider);
  return api.listRetentionPolicies(teamId);
});

/// Fetches a single retention policy by ID.
final loggerRetentionPolicyDetailProvider =
    FutureProvider.family<RetentionPolicyResponse, String>(
        (ref, policyId) {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) throw StateError('No team selected');
  final api = ref.watch(loggerApiProvider);
  return api.getRetentionPolicy(teamId, policyId);
});

/// Fetches storage usage statistics.
final loggerStorageUsageProvider =
    FutureProvider<StorageUsageResponse>((ref) {
  final api = ref.watch(loggerApiProvider);
  return api.getStorageUsage();
});

// ─────────────────────────────────────────────────────────────────────────────
// Anomaly Detection — Data Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Fetches all anomaly baselines for the selected team.
final loggerBaselinesProvider =
    FutureProvider<List<AnomalyBaselineResponse>>((ref) {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) return [];
  final api = ref.watch(loggerApiProvider);
  return api.listBaselines(teamId);
});

/// Fetches anomaly baselines for a specific service.
final loggerBaselinesByServiceProvider =
    FutureProvider.family<List<AnomalyBaselineResponse>, String>(
        (ref, serviceName) {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) return [];
  final api = ref.watch(loggerApiProvider);
  return api.listBaselinesByService(teamId, serviceName);
});

/// Fetches a single anomaly baseline by ID.
final loggerBaselineDetailProvider =
    FutureProvider.family<AnomalyBaselineResponse, String>(
        (ref, baselineId) {
  final api = ref.watch(loggerApiProvider);
  return api.getBaseline(baselineId);
});

/// Generates a full anomaly report for the selected team.
final loggerAnomalyReportProvider =
    FutureProvider<AnomalyReportResponse>((ref) {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) throw StateError('No team selected');
  final api = ref.watch(loggerApiProvider);
  return api.getAnomalyReport(teamId);
});
