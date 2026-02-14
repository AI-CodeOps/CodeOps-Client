/// Directive and project-directive domain models.
///
/// Maps to the server's `DirectiveResponse` and
/// `ProjectDirectiveResponse` DTOs.
library;

import 'package:json_annotation/json_annotation.dart';

import 'enums.dart';

part 'directive.g.dart';

/// A directive providing rules or context for agent execution.
@JsonSerializable()
class Directive {
  /// Unique identifier (UUID).
  final String id;

  /// Directive name.
  final String name;

  /// Short description of the directive's purpose.
  final String? description;

  /// Full directive content in Markdown.
  final String? contentMd;

  /// Category of the directive.
  @DirectiveCategoryConverter()
  final DirectiveCategory? category;

  /// Scope at which this directive applies.
  @DirectiveScopeConverter()
  final DirectiveScope scope;

  /// UUID of the owning team.
  final String? teamId;

  /// UUID of the associated project (for project-scoped directives).
  final String? projectId;

  /// UUID of the user who created this directive.
  final String? createdBy;

  /// Display name of the creator.
  final String? createdByName;

  /// Version number for optimistic concurrency.
  final int? version;

  /// Timestamp when the directive was created.
  final DateTime? createdAt;

  /// Timestamp when the directive was last updated.
  final DateTime? updatedAt;

  /// Creates a [Directive] instance.
  const Directive({
    required this.id,
    required this.name,
    this.description,
    this.contentMd,
    this.category,
    required this.scope,
    this.teamId,
    this.projectId,
    this.createdBy,
    this.createdByName,
    this.version,
    this.createdAt,
    this.updatedAt,
  });

  /// Deserializes a [Directive] from a JSON map.
  factory Directive.fromJson(Map<String, dynamic> json) =>
      _$DirectiveFromJson(json);

  /// Serializes this [Directive] to a JSON map.
  Map<String, dynamic> toJson() => _$DirectiveToJson(this);
}

/// Association between a project and a directive with an enabled flag.
@JsonSerializable()
class ProjectDirective {
  /// UUID of the project.
  final String projectId;

  /// UUID of the directive.
  final String directiveId;

  /// Name of the directive (denormalized for display).
  final String? directiveName;

  /// Category of the directive.
  @DirectiveCategoryConverter()
  final DirectiveCategory? category;

  /// Whether the directive is enabled for this project.
  final bool? enabled;

  /// Creates a [ProjectDirective] instance.
  const ProjectDirective({
    required this.projectId,
    required this.directiveId,
    this.directiveName,
    this.category,
    this.enabled,
  });

  /// Deserializes a [ProjectDirective] from a JSON map.
  factory ProjectDirective.fromJson(Map<String, dynamic> json) =>
      _$ProjectDirectiveFromJson(json);

  /// Serializes this [ProjectDirective] to a JSON map.
  Map<String, dynamic> toJson() => _$ProjectDirectiveToJson(this);
}
