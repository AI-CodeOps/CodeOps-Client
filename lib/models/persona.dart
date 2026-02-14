/// Persona domain model.
///
/// Maps to the server's `PersonaResponse` DTO.
library;

import 'package:json_annotation/json_annotation.dart';

import 'enums.dart';

part 'persona.g.dart';

/// An AI agent persona defining behavior and instructions.
@JsonSerializable()
class Persona {
  /// Unique identifier (UUID).
  final String id;

  /// Persona name.
  final String name;

  /// Agent type this persona is designed for.
  @AgentTypeConverter()
  final AgentType? agentType;

  /// Short description of the persona's purpose.
  final String? description;

  /// Full persona content in Markdown.
  final String? contentMd;

  /// Scope at which this persona is defined.
  @ScopeConverter()
  final Scope scope;

  /// UUID of the owning team (for team-scoped personas).
  final String? teamId;

  /// UUID of the user who created this persona.
  final String? createdBy;

  /// Display name of the creator.
  final String? createdByName;

  /// Whether this is the default persona for its agent type.
  final bool? isDefault;

  /// Version number for optimistic concurrency.
  final int? version;

  /// Timestamp when the persona was created.
  final DateTime? createdAt;

  /// Timestamp when the persona was last updated.
  final DateTime? updatedAt;

  /// Creates a [Persona] instance.
  const Persona({
    required this.id,
    required this.name,
    this.agentType,
    this.description,
    this.contentMd,
    required this.scope,
    this.teamId,
    this.createdBy,
    this.createdByName,
    this.isDefault,
    this.version,
    this.createdAt,
    this.updatedAt,
  });

  /// Deserializes a [Persona] from a JSON map.
  factory Persona.fromJson(Map<String, dynamic> json) =>
      _$PersonaFromJson(json);

  /// Serializes this [Persona] to a JSON map.
  Map<String, dynamic> toJson() => _$PersonaToJson(this);
}
