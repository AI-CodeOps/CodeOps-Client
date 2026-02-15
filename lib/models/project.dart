/// Project domain model.
///
/// Maps to the server's `ProjectResponse` DTO.
library;

import 'package:json_annotation/json_annotation.dart';

part 'project.g.dart';

/// A CodeOps project linked to a source code repository.
@JsonSerializable()
class Project {
  /// Unique identifier (UUID).
  final String id;

  /// UUID of the owning team.
  final String teamId;

  /// Project name.
  final String name;

  /// Optional project description.
  final String? description;

  /// UUID of the linked GitHub connection.
  final String? githubConnectionId;

  /// Repository clone URL.
  final String? repoUrl;

  /// Full repository name (e.g. 'owner/repo').
  final String? repoFullName;

  /// Default branch name (e.g. 'main').
  final String? defaultBranch;

  /// UUID of the linked Jira connection.
  final String? jiraConnectionId;

  /// Jira project key (e.g. 'PROJ').
  final String? jiraProjectKey;

  /// Default Jira issue type for created tickets.
  final String? jiraDefaultIssueType;

  /// Jira labels applied to created tickets.
  final List<String>? jiraLabels;

  /// Jira component applied to created tickets.
  final String? jiraComponent;

  /// Tech stack description.
  final String? techStack;

  /// Current health score (0-100).
  final int? healthScore;

  /// Timestamp of the last audit.
  final DateTime? lastAuditAt;

  /// Whether the project is archived.
  final bool? isArchived;

  /// Timestamp when the project was created.
  final DateTime? createdAt;

  /// Timestamp when the project was last updated.
  final DateTime? updatedAt;

  /// Creates a [Project] instance.
  const Project({
    required this.id,
    required this.teamId,
    required this.name,
    this.description,
    this.githubConnectionId,
    this.repoUrl,
    this.repoFullName,
    this.defaultBranch,
    this.jiraConnectionId,
    this.jiraProjectKey,
    this.jiraDefaultIssueType,
    this.jiraLabels,
    this.jiraComponent,
    this.techStack,
    this.healthScore,
    this.lastAuditAt,
    this.isArchived,
    this.createdAt,
    this.updatedAt,
  });

  /// Deserializes a [Project] from a JSON map.
  factory Project.fromJson(Map<String, dynamic> json) =>
      _$ProjectFromJson(json);

  /// Serializes this [Project] to a JSON map.
  Map<String, dynamic> toJson() => _$ProjectToJson(this);
}
