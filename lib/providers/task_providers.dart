/// Riverpod providers for remediation task data.
///
/// Exposes the [IntegrationApi] service, [TaskApi] service,
/// task listings for jobs and the current user, and filter/sort/selection
/// providers for the Task Manager and Task List pages.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/enums.dart';
import '../models/remediation_task.dart';
import '../services/cloud/integration_api.dart';
import '../services/cloud/task_api.dart';
import 'auth_providers.dart';

// ---------------------------------------------------------------------------
// API providers
// ---------------------------------------------------------------------------

/// Provides [IntegrationApi] for GitHub/Jira connection endpoints.
final integrationApiProvider = Provider<IntegrationApi>(
  (ref) => IntegrationApi(ref.watch(apiClientProvider)),
);

/// Provides [TaskApi] for dedicated task endpoints.
final taskApiProvider = Provider<TaskApi>(
  (ref) => TaskApi(ref.watch(apiClientProvider)),
);

// ---------------------------------------------------------------------------
// Data providers
// ---------------------------------------------------------------------------

/// Fetches remediation tasks for a job.
final jobTasksProvider =
    FutureProvider.family<List<RemediationTask>, String>((ref, jobId) async {
  final taskApi = ref.watch(taskApiProvider);
  return taskApi.getTasksForJob(jobId);
});

/// Fetches remediation tasks assigned to the current user.
final myTasksProvider = FutureProvider<List<RemediationTask>>((ref) async {
  final taskApi = ref.watch(taskApiProvider);
  return taskApi.getAssignedTasks();
});

/// Fetches a single remediation task by ID.
final taskProvider =
    FutureProvider.family<RemediationTask, String>((ref, taskId) async {
  final taskApi = ref.watch(taskApiProvider);
  return taskApi.getTask(taskId);
});

// ---------------------------------------------------------------------------
// TaskFilter
// ---------------------------------------------------------------------------

/// Filter criteria for task lists.
class TaskFilter {
  /// Filter by task status.
  final TaskStatus? status;

  /// Filter by priority level.
  final Priority? priority;

  /// Free-form search query (matches title).
  final String searchQuery;

  /// Creates a [TaskFilter].
  const TaskFilter({
    this.status,
    this.priority,
    this.searchQuery = '',
  });

  /// Creates a copy with the given fields replaced.
  TaskFilter copyWith({
    TaskStatus? status,
    Priority? priority,
    String? searchQuery,
    bool clearStatus = false,
    bool clearPriority = false,
  }) {
    return TaskFilter(
      status: clearStatus ? null : (status ?? this.status),
      priority: clearPriority ? null : (priority ?? this.priority),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  /// Whether any filter is active.
  bool get hasActiveFilters =>
      status != null || priority != null || searchQuery.isNotEmpty;
}

// ---------------------------------------------------------------------------
// TaskSort
// ---------------------------------------------------------------------------

/// Sort options for task lists.
enum TaskSort {
  /// Sort by priority, highest first.
  priorityDesc('Priority'),

  /// Sort by task number, ascending.
  taskNumberAsc('Task #'),

  /// Sort by creation date, newest first.
  createdAtDesc('Created');

  /// Creates a [TaskSort] with the given display label.
  const TaskSort(this.label);

  /// Human-readable display label.
  final String label;
}

// ---------------------------------------------------------------------------
// Filter / Sort / Selection providers
// ---------------------------------------------------------------------------

/// Provider for task filter state.
final taskFilterProvider = StateProvider<TaskFilter>(
  (ref) => const TaskFilter(),
);

/// Provider for task sort state.
final taskSortProvider = StateProvider<TaskSort>(
  (ref) => TaskSort.priorityDesc,
);

/// Provider for multi-select task IDs.
final selectedTaskIdsProvider = StateProvider<Set<String>>(
  (ref) => {},
);

/// Provider for the currently active (detail-panel) task.
final selectedTaskProvider = StateProvider<RemediationTask?>(
  (ref) => null,
);

// ---------------------------------------------------------------------------
// Filtered / Sorted providers
// ---------------------------------------------------------------------------

/// Applies [TaskFilter] and [TaskSort] to [jobTasksProvider].
final filteredJobTasksProvider =
    Provider.family<AsyncValue<List<RemediationTask>>, String>(
  (ref, jobId) {
    final tasksAsync = ref.watch(jobTasksProvider(jobId));
    final filter = ref.watch(taskFilterProvider);
    final sort = ref.watch(taskSortProvider);

    return tasksAsync.whenData(
      (tasks) => _applySort(sort, _applyFilter(filter, tasks)),
    );
  },
);

/// Applies [TaskFilter] and [TaskSort] to [myTasksProvider].
final filteredMyTasksProvider =
    Provider<AsyncValue<List<RemediationTask>>>((ref) {
  final tasksAsync = ref.watch(myTasksProvider);
  final filter = ref.watch(taskFilterProvider);
  final sort = ref.watch(taskSortProvider);

  return tasksAsync.whenData(
    (tasks) => _applySort(sort, _applyFilter(filter, tasks)),
  );
});

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Filters a task list by the given [filter] criteria.
List<RemediationTask> _applyFilter(
    TaskFilter filter, List<RemediationTask> tasks) {
  var filtered = tasks;

  if (filter.status != null) {
    filtered = filtered.where((t) => t.status == filter.status).toList();
  }

  if (filter.priority != null) {
    filtered = filtered.where((t) => t.priority == filter.priority).toList();
  }

  if (filter.searchQuery.isNotEmpty) {
    final query = filter.searchQuery.toLowerCase();
    filtered =
        filtered.where((t) => t.title.toLowerCase().contains(query)).toList();
  }

  return filtered;
}

/// Sorts a task list by the given [sort] option.
List<RemediationTask> _applySort(
    TaskSort sort, List<RemediationTask> tasks) {
  final sorted = List<RemediationTask>.from(tasks);
  switch (sort) {
    case TaskSort.priorityDesc:
      sorted.sort((a, b) =>
          _priorityRank(a.priority).compareTo(_priorityRank(b.priority)));
    case TaskSort.taskNumberAsc:
      sorted.sort((a, b) => a.taskNumber.compareTo(b.taskNumber));
    case TaskSort.createdAtDesc:
      sorted.sort((a, b) => (b.createdAt ?? DateTime(2000))
          .compareTo(a.createdAt ?? DateTime(2000)));
  }
  return sorted;
}

/// Returns a numeric rank for priority sorting (lower = higher priority).
int _priorityRank(Priority? priority) {
  return switch (priority) {
    Priority.p0 => 0,
    Priority.p1 => 1,
    Priority.p2 => 2,
    Priority.p3 => 3,
    null => 4,
  };
}
