/// Riverpod providers for persona data.
///
/// Exposes the [PersonaApi] service, team personas,
/// and system-level personas.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

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
