/// Riverpod providers for agent configuration state.
///
/// Exposes Anthropic API key management, model caching, agent definitions,
/// file attachments, and UI state for the agent config settings tabs.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import '../models/anthropic_model_info.dart';
import '../services/agent/agent_config_service.dart';
import '../services/cloud/anthropic_api_service.dart';
import 'auth_providers.dart';

/// Provides the [AnthropicApiService] singleton.
final anthropicApiServiceProvider = Provider<AnthropicApiService>(
  (ref) => AnthropicApiService(),
);

/// Provides the [AgentConfigService] with all dependencies.
final agentConfigServiceProvider = Provider<AgentConfigService>(
  (ref) => AgentConfigService(
    db: ref.watch(databaseProvider),
    anthropicApi: ref.watch(anthropicApiServiceProvider),
    secureStorage: ref.watch(secureStorageProvider),
  ),
);

/// Reads the stored Anthropic API key from secure storage.
final anthropicApiKeyProvider = FutureProvider<String?>((ref) async {
  final storage = ref.watch(secureStorageProvider);
  return storage.getAnthropicApiKey();
});

/// Tracks API key validation state.
///
/// `null` = untested, `true` = valid, `false` = invalid.
final apiKeyValidatedProvider = StateProvider<bool?>((ref) => null);

/// Provides cached Anthropic models from the local database.
final anthropicModelsProvider =
    FutureProvider<List<AnthropicModelInfo>>((ref) async {
  final service = ref.watch(agentConfigServiceProvider);
  return service.getCachedModels();
});

/// Tracks whether the last model fetch from the Anthropic API failed.
final modelFetchFailedProvider = StateProvider<bool>((ref) => false);

/// Provides all agent definitions ordered by sort order.
final agentDefinitionsProvider =
    FutureProvider<List<AgentDefinition>>((ref) async {
  final service = ref.watch(agentConfigServiceProvider);
  return service.getAllAgents();
});

/// Tracks the currently selected agent ID in the agents tab.
final selectedAgentIdProvider = StateProvider<String?>((ref) => null);

/// Derives the selected [AgentDefinition] from [selectedAgentIdProvider]
/// and [agentDefinitionsProvider].
final selectedAgentProvider = Provider<AgentDefinition?>((ref) {
  final selectedId = ref.watch(selectedAgentIdProvider);
  if (selectedId == null) return null;

  final agentsAsync = ref.watch(agentDefinitionsProvider);
  return agentsAsync.whenOrNull(
    data: (agents) {
      for (final agent in agents) {
        if (agent.id == selectedId) return agent;
      }
      return null;
    },
  );
});

/// Provides files attached to the currently selected agent.
final selectedAgentFilesProvider =
    FutureProvider<List<AgentFile>>((ref) async {
  final selectedId = ref.watch(selectedAgentIdProvider);
  if (selectedId == null) return [];

  final service = ref.watch(agentConfigServiceProvider);
  return service.getAgentFiles(selectedId);
});

/// Tracks the currently selected tab in the agent config section.
///
/// 0 = API Key, 1 = Agents, 2 = General.
final agentConfigTabProvider = StateProvider<int>((ref) => 0);

/// Search query for filtering agents in the agents tab.
final agentSearchQueryProvider = StateProvider<String>((ref) => '');
