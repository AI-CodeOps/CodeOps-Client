/// Riverpod providers for QA job data.
///
/// Exposes the [JobApi], [FindingApi], and [ReportApi] services,
/// job listings for projects, the current user's jobs, job detail views,
/// agent runs, findings, and severity counts.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/agent_run.dart';
import '../models/finding.dart';
import '../models/health_snapshot.dart';
import '../models/qa_job.dart';
import '../services/cloud/finding_api.dart';
import '../services/cloud/job_api.dart';
import '../services/cloud/report_api.dart';
import 'auth_providers.dart';

/// Provides [JobApi] for job endpoints.
final jobApiProvider = Provider<JobApi>(
  (ref) => JobApi(ref.watch(apiClientProvider)),
);

/// Provides [FindingApi] for finding endpoints.
final findingApiProvider = Provider<FindingApi>(
  (ref) => FindingApi(ref.watch(apiClientProvider)),
);

/// Provides [ReportApi] for report upload/download endpoints.
final reportApiProvider = Provider<ReportApi>(
  (ref) => ReportApi(ref.watch(apiClientProvider)),
);

/// Fetches paginated job history for a project.
final projectJobsProvider = FutureProvider.family<PageResponse<JobSummary>,
    ({String projectId, int page})>((ref, params) async {
  final jobApi = ref.watch(jobApiProvider);
  return jobApi.getProjectJobs(params.projectId, page: params.page);
});

/// Fetches recent jobs started by the current user.
final myJobsProvider = FutureProvider<List<JobSummary>>((ref) async {
  final jobApi = ref.watch(jobApiProvider);
  return jobApi.getMyJobs();
});

/// Fetches a specific job by ID.
final jobDetailProvider =
    FutureProvider.family<QaJob, String>((ref, jobId) async {
  final jobApi = ref.watch(jobApiProvider);
  return jobApi.getJob(jobId);
});

/// The currently active/viewed job ID.
final activeJobIdProvider = StateProvider<String?>((ref) => null);

/// Fetches agent runs for a specific job.
final agentRunsByJobProvider =
    FutureProvider.autoDispose.family<List<AgentRun>, String>(
  (ref, jobId) async {
    final jobApi = ref.watch(jobApiProvider);
    return jobApi.getAgentRuns(jobId);
  },
);

/// Fetches paginated findings for a job.
final jobFindingsProvider = FutureProvider.autoDispose
    .family<PageResponse<Finding>, ({String jobId, int page})>(
  (ref, params) async {
    final findingApi = ref.watch(findingApiProvider);
    return findingApi.getJobFindings(params.jobId, page: params.page);
  },
);

/// Fetches finding severity counts for a job.
final jobSeverityCountsProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, String>(
  (ref, jobId) async {
    final findingApi = ref.watch(findingApiProvider);
    return findingApi.getFindingCounts(jobId);
  },
);
