/// API service for persona management endpoints.
///
/// Supports CRUD, team scoping, default setting, and search by agent type.
library;

import '../../models/enums.dart';
import '../../models/persona.dart';
import 'api_client.dart';

/// API service for persona management endpoints.
///
/// Provides typed methods for creating, updating, listing, and managing
/// persona configurations used by QA agents.
class PersonaApi {
  final ApiClient _client;

  /// Creates a [PersonaApi] backed by the given [client].
  PersonaApi(this._client);

  /// Creates a new persona.
  Future<Persona> createPersona({
    required String name,
    required String contentMd,
    required Scope scope,
    AgentType? agentType,
    String? description,
    String? teamId,
    bool? isDefault,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'contentMd': contentMd,
      'scope': scope.toJson(),
    };
    if (agentType != null) body['agentType'] = agentType.toJson();
    if (description != null) body['description'] = description;
    if (teamId != null) body['teamId'] = teamId;
    if (isDefault != null) body['isDefault'] = isDefault;

    final response = await _client.post<Map<String, dynamic>>(
      '/personas',
      data: body,
    );
    return Persona.fromJson(response.data!);
  }

  /// Fetches a persona by [personaId].
  Future<Persona> getPersona(String personaId) async {
    final response =
        await _client.get<Map<String, dynamic>>('/personas/$personaId');
    return Persona.fromJson(response.data!);
  }

  /// Updates a persona.
  ///
  /// Per the OpenAPI spec, only [name], [description], [contentMd],
  /// and [isDefault] can be updated.
  Future<Persona> updatePersona(
    String personaId, {
    String? name,
    String? description,
    String? contentMd,
    bool? isDefault,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (description != null) body['description'] = description;
    if (contentMd != null) body['contentMd'] = contentMd;
    if (isDefault != null) body['isDefault'] = isDefault;

    final response = await _client.put<Map<String, dynamic>>(
      '/personas/$personaId',
      data: body,
    );
    return Persona.fromJson(response.data!);
  }

  /// Deletes a persona by [personaId].
  Future<void> deletePersona(String personaId) async {
    await _client.delete('/personas/$personaId');
  }

  /// Fetches all personas for a team.
  Future<List<Persona>> getTeamPersonas(String teamId) async {
    final response =
        await _client.get<List<dynamic>>('/personas/team/$teamId');
    return response.data!
        .map((e) => Persona.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetches personas for a team filtered by [agentType].
  Future<List<Persona>> getTeamPersonasByAgentType(
    String teamId,
    AgentType agentType,
  ) async {
    final response = await _client.get<List<dynamic>>(
      '/personas/team/$teamId/agent/${agentType.toJson()}',
    );
    return response.data!
        .map((e) => Persona.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetches the default persona for a team and agent type.
  Future<Persona> getTeamDefaultPersona(
    String teamId,
    AgentType agentType,
  ) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/personas/team/$teamId/default/${agentType.toJson()}',
    );
    return Persona.fromJson(response.data!);
  }

  /// Sets a persona as the default for its team and agent type.
  Future<Persona> setAsDefault(String personaId) async {
    final response = await _client.put<Map<String, dynamic>>(
      '/personas/$personaId/set-default',
    );
    return Persona.fromJson(response.data!);
  }

  /// Removes the default flag from a persona.
  Future<Persona> removeDefault(String personaId) async {
    final response = await _client.put<Map<String, dynamic>>(
      '/personas/$personaId/remove-default',
    );
    return Persona.fromJson(response.data!);
  }

  /// Fetches all system-scope personas (built-in, read-only).
  Future<List<Persona>> getSystemPersonas() async {
    final response = await _client.get<List<dynamic>>('/personas/system');
    return response.data!
        .map((e) => Persona.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetches personas created by the current user.
  Future<List<Persona>> getMyPersonas() async {
    final response = await _client.get<List<dynamic>>('/personas/mine');
    return response.data!
        .map((e) => Persona.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
