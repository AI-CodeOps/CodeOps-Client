/// Remediation task domain model.
///
/// Maps to the server's `TaskResponse` DTO.
library;

import 'package:json_annotation/json_annotation.dart';

import 'enums.dart';

part 'remediation_task.g.dart';

/// A remediation task generated from audit findings.
@JsonSerializable()
class RemediationTask {
  /// Unique identifier (UUID).
  final String id;

  /// UUID of the parent QA job.
  final String jobId;

  /// Sequential task number within the job.
  final int taskNumber;

  /// Short title describing the task.
  final String title;

  /// Detailed description of what to fix.
  final String? description;

  /// Markdown prompt for AI-assisted remediation.
  final String? promptMd;

  /// S3 key for the prompt file.
  final String? promptS3Key;

  /// UUIDs of findings this task addresses.
  final List<String>? findingIds;

  /// Task priority level.
  @PriorityConverter()
  final Priority? priority;

  /// Current lifecycle status.
  @TaskStatusConverter()
  final TaskStatus status;

  /// UUID of the user assigned to this task.
  final String? assignedTo;

  /// Display name of the assignee.
  final String? assignedToName;

  /// Jira ticket key if exported.
  final String? jiraKey;

  /// Timestamp when the task was created.
  final DateTime? createdAt;

  /// Creates a [RemediationTask] instance.
  const RemediationTask({
    required this.id,
    required this.jobId,
    required this.taskNumber,
    required this.title,
    this.description,
    this.promptMd,
    this.promptS3Key,
    this.findingIds,
    this.priority,
    required this.status,
    this.assignedTo,
    this.assignedToName,
    this.jiraKey,
    this.createdAt,
  });

  /// Deserializes a [RemediationTask] from a JSON map.
  factory RemediationTask.fromJson(Map<String, dynamic> json) =>
      _$RemediationTaskFromJson(json);

  /// Serializes this [RemediationTask] to a JSON map.
  Map<String, dynamic> toJson() => _$RemediationTaskToJson(this);
}
