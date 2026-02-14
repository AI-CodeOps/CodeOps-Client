/// Riverpod providers for QA job data.
///
/// Exposes the [JobApi] service, job listings for projects,
/// the current user's jobs, and job detail views.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/health_snapshot.dart';
import '../models/qa_job.dart';
import '../services/cloud/job_api.dart';
import 'auth_providers.dart';

/// Provides [JobApi] for job endpoints.
final jobApiProvider = Provider<JobApi>(
  (ref) => JobApi(ref.watch(apiClientProvider)),
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
