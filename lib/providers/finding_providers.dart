/// Riverpod providers for finding data.
///
/// Exposes the [FindingApi] service, paginated job findings,
/// and filter state for severity, status, and agent type.
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
