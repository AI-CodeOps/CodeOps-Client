/// Riverpod providers for finding data.
///
/// Exposes the [FindingApi] service, paginated job findings,
/// filter state for severity, status, and agent type, severity counts,
/// filtered finding queries, selection state, and active finding state.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/enums.dart';
import '../models/finding.dart';
import '../models/health_snapshot.dart';
import '../services/cloud/finding_api.dart';
import 'auth_providers.dart';

/// Provides [FindingApi] for finding endpoints.
final findingApiProvider = Provider<FindingApi>(
  (ref) => FindingApi(ref.watch(apiClientProvider)),
);

/// Fetches paginated findings for a job.
final jobFindingsProvider = FutureProvider.family<PageResponse<Finding>,
    ({String jobId, int page})>((ref, params) async {
  final findingApi = ref.watch(findingApiProvider);
  return findingApi.getJobFindings(params.jobId, page: params.page);
});

/// Currently selected severity filter for findings view.
final findingSeverityFilterProvider = StateProvider<Severity?>((ref) => null);

/// Currently selected status filter for findings view.
final findingStatusFilterProvider =
    StateProvider<FindingStatus?>((ref) => null);

/// Currently selected agent type filter for findings view.
final findingAgentFilterProvider =
    StateProvider<AgentType?>((ref) => null);

/// Fetches finding severity counts for a job.
final findingSeverityCountsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, jobId) async {
  final findingApi = ref.watch(findingApiProvider);
  return findingApi.getFindingCounts(jobId);
});

/// Fetches findings filtered by severity for a job.
final findingsBySeverityProvider = FutureProvider.family<List<Finding>,
    ({String jobId, Severity severity})>((ref, params) async {
  final findingApi = ref.watch(findingApiProvider);
  return findingApi.getFindingsBySeverity(params.jobId, params.severity);
});

/// Fetches findings filtered by agent type for a job.
final findingsByAgentProvider = FutureProvider.family<List<Finding>,
    ({String jobId, AgentType agentType})>((ref, params) async {
  final findingApi = ref.watch(findingApiProvider);
  return findingApi.getFindingsByAgent(params.jobId, params.agentType);
});

/// Fetches findings filtered by status for a job.
final findingsByStatusProvider = FutureProvider.family<List<Finding>,
    ({String jobId, FindingStatus status})>((ref, params) async {
  final findingApi = ref.watch(findingApiProvider);
  return findingApi.getFindingsByStatus(params.jobId, params.status);
});

/// Fetches a single finding by ID.
final findingProvider =
    FutureProvider.family<Finding, String>((ref, findingId) async {
  final findingApi = ref.watch(findingApiProvider);
  return findingApi.getFinding(findingId);
});

/// Composite filter state for the findings explorer.
class FindingFilters {
  /// Severity filter.
  final Severity? severity;

  /// Status filter.
  final FindingStatus? status;

  /// Agent type filter.
  final AgentType? agentType;

  /// Search query.
  final String searchQuery;

  /// Sort field.
  final String sortField;

  /// Sort ascending.
  final bool sortAscending;

  /// Creates [FindingFilters].
  const FindingFilters({
    this.severity,
    this.status,
    this.agentType,
    this.searchQuery = '',
    this.sortField = 'severity',
    this.sortAscending = true,
  });

  /// Creates a copy with modified fields.
  FindingFilters copyWith({
    Severity? severity,
    FindingStatus? status,
    AgentType? agentType,
    String? searchQuery,
    String? sortField,
    bool? sortAscending,
    bool clearSeverity = false,
    bool clearStatus = false,
    bool clearAgentType = false,
  }) =>
      FindingFilters(
        severity: clearSeverity ? null : (severity ?? this.severity),
        status: clearStatus ? null : (status ?? this.status),
        agentType:
            clearAgentType ? null : (agentType ?? this.agentType),
        searchQuery: searchQuery ?? this.searchQuery,
        sortField: sortField ?? this.sortField,
        sortAscending: sortAscending ?? this.sortAscending,
      );

  /// Whether any filter is active.
  bool get hasActiveFilters =>
      severity != null ||
      status != null ||
      agentType != null ||
      searchQuery.isNotEmpty;
}

/// Provides composite filter state for the findings explorer.
final findingFiltersProvider =
    StateProvider<FindingFilters>((ref) => const FindingFilters());

/// Set of selected finding IDs for bulk operations.
final selectedFindingIdsProvider = StateProvider<Set<String>>((ref) => {});

/// Currently active finding for the detail panel.
final activeFindingProvider = StateProvider<Finding?>((ref) => null);
