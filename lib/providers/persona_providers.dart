/// Riverpod providers for persona data.
///
/// Exposes the [PersonaApi] service, team personas,
/// and system-level personas.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/enums.dart';
import '../models/persona.dart';
import '../services/cloud/persona_api.dart';
import 'auth_providers.dart';
import 'team_providers.dart';

/// Provides [PersonaApi] for persona endpoints.
final personaApiProvider = Provider<PersonaApi>(
  (ref) => PersonaApi(ref.watch(apiClientProvider)),
);

/// Fetches all personas for the selected team.
final teamPersonasProvider = FutureProvider<List<Persona>>((ref) async {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) return [];
  final personaApi = ref.watch(personaApiProvider);
  return personaApi.getTeamPersonas(teamId);
});

/// Fetches system-level personas (built-in, read-only).
final systemPersonasProvider = FutureProvider<List<Persona>>((ref) async {
  final personaApi = ref.watch(personaApiProvider);
  return personaApi.getSystemPersonas();
});

// ---------------------------------------------------------------------------
// New providers for persona pages
// ---------------------------------------------------------------------------

/// Fetches personas created by the current user.
final myPersonasProvider = FutureProvider<List<Persona>>((ref) async {
  final personaApi = ref.watch(personaApiProvider);
  return personaApi.getMyPersonas();
});

/// Fetches personas for a team filtered by agent type.
final personasByAgentTypeProvider = FutureProvider.family<List<Persona>,
    ({String teamId, AgentType agentType})>((ref, params) async {
  final personaApi = ref.watch(personaApiProvider);
  return personaApi.getTeamPersonasByAgentType(params.teamId, params.agentType);
});

/// Fetches the default persona for a team and agent type. Returns null if none.
final defaultPersonaProvider = FutureProvider.family<Persona?,
    ({String teamId, AgentType agentType})>((ref, params) async {
  final personaApi = ref.watch(personaApiProvider);
  try {
    return await personaApi.getTeamDefaultPersona(
        params.teamId, params.agentType);
  } catch (_) {
    return null;
  }
});

/// The currently selected persona in the list view.
final selectedPersonaProvider = StateProvider<Persona?>((ref) => null);

/// Search query for filtering the personas list.
final personaSearchQueryProvider = StateProvider<String>((ref) => '');

/// Scope filter for the personas list.
final personaScopeFilterProvider = StateProvider<Scope?>((ref) => null);

/// Agent type filter for the personas list.
final personaAgentTypeFilterProvider = StateProvider<AgentType?>((ref) => null);

/// Personas filtered by search query, scope, and agent type.
///
/// Combines system, team, and user personas, deduplicates by id,
/// then applies search/scope/agentType filters.
final filteredPersonasProvider = Provider<AsyncValue<List<Persona>>>((ref) {
  final systemAsync = ref.watch(systemPersonasProvider);
  final teamAsync = ref.watch(teamPersonasProvider);
  final query = ref.watch(personaSearchQueryProvider).toLowerCase();
  final scopeFilter = ref.watch(personaScopeFilterProvider);
  final agentTypeFilter = ref.watch(personaAgentTypeFilterProvider);

  // If either is loading, show loading.
  if (systemAsync is AsyncLoading || teamAsync is AsyncLoading) {
    return const AsyncValue.loading();
  }

  // If either has an error, propagate it.
  if (systemAsync is AsyncError) {
    return AsyncValue.error(
        systemAsync.error!, systemAsync.stackTrace ?? StackTrace.current);
  }
  if (teamAsync is AsyncError) {
    return AsyncValue.error(
        teamAsync.error!, teamAsync.stackTrace ?? StackTrace.current);
  }

  final systemPersonas = systemAsync.valueOrNull ?? [];
  final teamPersonas = teamAsync.valueOrNull ?? [];

  // Combine and deduplicate by id.
  final seen = <String>{};
  final all = <Persona>[];
  for (final p in [...systemPersonas, ...teamPersonas]) {
    if (seen.add(p.id)) {
      all.add(p);
    }
  }

  return AsyncValue.data(_applyPersonaFilters(all, query, scopeFilter, agentTypeFilter));
});

List<Persona> _applyPersonaFilters(
  List<Persona> personas,
  String query,
  Scope? scopeFilter,
  AgentType? agentTypeFilter,
) {
  var filtered = personas;

  // Filter by scope.
  if (scopeFilter != null) {
    filtered = filtered.where((p) => p.scope == scopeFilter).toList();
  }

  // Filter by agent type.
  if (agentTypeFilter != null) {
    filtered = filtered.where((p) => p.agentType == agentTypeFilter).toList();
  }

  // Filter by search query.
  if (query.isNotEmpty) {
    filtered = filtered.where((p) {
      return p.name.toLowerCase().contains(query) ||
          (p.description?.toLowerCase().contains(query) ?? false) ||
          (p.agentType?.displayName.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  // Sort: system first, then team, then user; alphabetical within each.
  filtered.sort((a, b) {
    final scopeOrder = a.scope.index.compareTo(b.scope.index);
    if (scopeOrder != 0) return scopeOrder;
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  });

  return filtered;
}
