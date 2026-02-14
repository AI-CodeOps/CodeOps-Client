/// Riverpod providers for remediation task data.
///
/// Exposes the [IntegrationApi] service, [TaskApi] service,
/// and task listings for jobs and the current user.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/remediation_task.dart';
import '../services/cloud/integration_api.dart';
import '../services/cloud/task_api.dart';
import 'auth_providers.dart';

/// Provides [IntegrationApi] for integration endpoints.
final integrationApiProvider = Provider<IntegrationApi>(
  (ref) => IntegrationApi(ref.watch(apiClientProvider)),
);

/// Provides [TaskApi] for dedicated task endpoints.
final taskApiProvider = Provider<TaskApi>(
  (ref) => TaskApi(ref.watch(apiClientProvider)),
);

/// Fetches remediation tasks for a job.
final jobTasksProvider =
    FutureProvider.family<List<RemediationTask>, String>((ref, jobId) async {
  final integrationApi = ref.watch(integrationApiProvider);
  return integrationApi.getJobTasks(jobId);
});

/// Fetches remediation tasks assigned to the current user.
final myTasksProvider = FutureProvider<List<RemediationTask>>((ref) async {
  final integrationApi = ref.watch(integrationApiProvider);
  return integrationApi.getMyTasks();
});

/// Fetches a single remediation task by ID.
final taskProvider =
    FutureProvider.family<RemediationTask, String>((ref, taskId) async {
  final taskApi = ref.watch(taskApiProvider);
  return taskApi.getTask(taskId);
});
