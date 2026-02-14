/// Riverpod providers for agent run data.
///
/// Exposes agent runs for a job and the selected agent types
/// for new job configuration.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/agent_run.dart';
import '../models/enums.dart';
import 'job_providers.dart';

/// Provides agent run data for a specific job.
final agentRunsProvider =
    FutureProvider.family<List<AgentRun>, String>((ref, jobId) async {
  final jobApi = ref.watch(jobApiProvider);
  return jobApi.getAgentRuns(jobId);
});

/// The set of selected agent types for a new job configuration.
///
/// Defaults to all agent types selected.
final selectedAgentTypesProvider = StateProvider<Set<AgentType>>(
  (ref) => AgentType.values.toSet(),
);
