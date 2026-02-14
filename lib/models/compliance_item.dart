/// Compliance item domain model.
///
/// Maps to the server's `ComplianceItemResponse` DTO.
library;

import 'package:json_annotation/json_annotation.dart';

import 'enums.dart';

part 'compliance_item.g.dart';

/// A single compliance requirement check result.
@JsonSerializable()
class ComplianceItem {
  /// Unique identifier (UUID).
  final String id;

  /// UUID of the parent QA job.
  final String jobId;

  /// The requirement being checked.
  final String requirement;

  /// UUID of the specification this requirement comes from.
  final String? specId;

  /// Name of the specification (denormalized for display).
  final String? specName;

  /// Compliance status of the requirement.
  @ComplianceStatusConverter()
  final ComplianceStatus status;

  /// Evidence supporting the compliance determination.
  final String? evidence;

  /// Agent type that produced this compliance check.
  @AgentTypeConverter()
  final AgentType? agentType;

  /// Additional notes.
  final String? notes;

  /// Timestamp when the compliance item was created.
  final DateTime? createdAt;

  /// Creates a [ComplianceItem] instance.
  const ComplianceItem({
    required this.id,
    required this.jobId,
    required this.requirement,
    this.specId,
    this.specName,
    required this.status,
    this.evidence,
    this.agentType,
    this.notes,
    this.createdAt,
  });

  /// Deserializes a [ComplianceItem] from a JSON map.
  factory ComplianceItem.fromJson(Map<String, dynamic> json) =>
      _$ComplianceItemFromJson(json);

  /// Serializes this [ComplianceItem] to a JSON map.
  Map<String, dynamic> toJson() => _$ComplianceItemToJson(this);
}
