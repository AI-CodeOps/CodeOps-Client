/// Finding domain model.
///
/// Maps to the server's `FindingResponse` DTO.
library;

import 'package:json_annotation/json_annotation.dart';

import 'enums.dart';

part 'finding.g.dart';

/// An audit finding produced by an agent run.
@JsonSerializable()
class Finding {
  /// Unique identifier (UUID).
  final String id;

  /// UUID of the parent QA job.
  final String jobId;

  /// The type of agent that produced this finding.
  @AgentTypeConverter()
  final AgentType agentType;

  /// Severity level of the finding.
  @SeverityConverter()
  final Severity severity;

  /// Short title describing the finding.
  final String title;

  /// Detailed description of the finding.
  final String? description;

  /// Source file path where the issue was found.
  final String? filePath;

  /// Line number in the source file.
  final int? lineNumber;

  /// Recommended action to resolve the finding.
  final String? recommendation;

  /// Evidence supporting the finding.
  final String? evidence;

  /// Estimated effort to resolve.
  @EffortConverter()
  final Effort? effortEstimate;

  /// Technical debt category if applicable.
  @DebtCategoryConverter()
  final DebtCategory? debtCategory;

  /// Current status of the finding.
  @FindingStatusConverter()
  final FindingStatus status;

  /// UUID of the user who last changed the status.
  final String? statusChangedBy;

  /// Timestamp when the status was last changed.
  final DateTime? statusChangedAt;

  /// Timestamp when the finding was created.
  final DateTime? createdAt;

  /// Creates a [Finding] instance.
  const Finding({
    required this.id,
    required this.jobId,
    required this.agentType,
    required this.severity,
    required this.title,
    this.description,
    this.filePath,
    this.lineNumber,
    this.recommendation,
    this.evidence,
    this.effortEstimate,
    this.debtCategory,
    required this.status,
    this.statusChangedBy,
    this.statusChangedAt,
    this.createdAt,
  });

  /// Deserializes a [Finding] from a JSON map.
  factory Finding.fromJson(Map<String, dynamic> json) =>
      _$FindingFromJson(json);

  /// Serializes this [Finding] to a JSON map.
  Map<String, dynamic> toJson() => _$FindingToJson(this);
}
